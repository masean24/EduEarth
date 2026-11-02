import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common/empty_view.dart';
import '../../../../core/widgets/common/error_view.dart';
import '../../../../core/widgets/common/loading_view.dart';
import '../../../../core/widgets/common/material_card.dart';
import '../../../../routes/route_names.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../bookmark/presentation/providers/bookmark_providers.dart';
import '../../../quiz/presentation/providers/quiz_providers.dart';

/// Halaman Progres Belajar Saya (My Learning) Fase 5.
///
/// Menampilkan ringkasan statistik belajar pengguna:
/// - Jumlah kuis unik yang diselesaikan, rata-rata skor, dan daftar riwayat kuis.
/// - Daftar materi pembelajaran yang disimpan di Bookmark.
class MyLearningPage extends ConsumerWidget {
  const MyLearningPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    final attemptsAsync = ref.watch(userQuizAttemptsProvider);
    final bookmarksAsync = ref.watch(userBookmarksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progres Belajar Saya'),
      ),
      body: SafeArea(
        child: !isAuthenticated
            ? EmptyView(
                icon: Icons.school_outlined,
                title: 'Masuk untuk Melihat Progres Belajar',
                description:
                    'Riwayat skor kuis dan materi pembelajaran yang Anda simpan akan tercatat di halaman ini.',
                actionLabel: 'Masuk (Login)',
                onAction: () => context.push(RouteNames.loginPath),
              )
            : RefreshIndicator(
                color: AppColors.freshGreen,
                onRefresh: () async {
                  ref.invalidate(userQuizAttemptsProvider);
                  ref.invalidate(userBookmarksProvider);
                },
                child: attemptsAsync.when(
                  loading: () => const LoadingView(
                    message: 'Memuat progres belajar dan riwayat kuis Anda...',
                  ),
                  error: (error, _) => ErrorView(
                    message: error.toString(),
                    onRetry: () {
                      ref.invalidate(userQuizAttemptsProvider);
                      ref.invalidate(userBookmarksProvider);
                    },
                  ),
                  data: (attempts) {
                    return bookmarksAsync.when(
                      loading: () => const LoadingView(
                        message: 'Memuat daftar materi tersimpan...',
                      ),
                      error: (error, _) => ErrorView(
                        message: error.toString(),
                        onRetry: () => ref.invalidate(userBookmarksProvider),
                      ),
                      data: (bookmarks) {
                        final materialBookmarks = bookmarks
                            .where((b) => b.material != null)
                            .toList();

                        if (attempts.isEmpty && materialBookmarks.isEmpty) {
                          return EmptyView(
                            icon: Icons.auto_stories_outlined,
                            title: 'Belum Ada Aktivitas Belajar',
                            description:
                                'Mulai baca materi energi terbarukan atau kerjakan kuis untuk melihat progres Anda di sini.',
                            actionLabel: 'Mulai Belajar',
                            onAction: () => context.go(RouteNames.learningPath),
                          );
                        }

                        final uniqueQuizzesCount = attempts
                            .map((a) => a.quizId)
                            .toSet()
                            .length;
                        final avgScore = attempts.isEmpty
                            ? 0
                            : (attempts
                                        .map((a) => a.score)
                                        .reduce((a, b) => a + b) /
                                    attempts.length)
                                .round();

                        return ListView(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                          children: [
                            _buildSummaryBanner(
                              uniqueQuizzesCount: uniqueQuizzesCount,
                              totalAttempts: attempts.length,
                              averageScore: avgScore,
                              savedMaterialsCount: materialBookmarks.length,
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Materi Tersimpan (${materialBookmarks.length})',
                              style: AppTextStyles.title,
                            ),
                            const SizedBox(height: 12),
                            if (materialBookmarks.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceWhite,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.divider),
                                ),
                                child: Text(
                                  'Belum ada materi pembelajaran yang disimpan ke Bookmark.',
                                  style: AppTextStyles.caption,
                                ),
                              )
                            else
                              ...materialBookmarks.map((b) {
                                final mat = b.material!;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: MaterialCard(
                                    material: mat,
                                    onTap: () => context.push(
                                      '/learning/material/${mat.slug}',
                                    ),
                                  ),
                                );
                              }),
                            const SizedBox(height: 24),
                            Text(
                              'Riwayat Kuis (${attempts.length})',
                              style: AppTextStyles.title,
                            ),
                            const SizedBox(height: 12),
                            if (attempts.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceWhite,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.divider),
                                ),
                                child: Text(
                                  'Anda belum mengerjakan kuis.',
                                  style: AppTextStyles.caption,
                                ),
                              )
                            else
                              ...attempts.map((attempt) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceWhite,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: AppColors.divider,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            color: attempt.score >= 70
                                                ? AppColors.mintGreen
                                                : AppColors.warmYellow
                                                      .withValues(alpha: 0.25),
                                            shape: BoxShape.circle,
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            '${attempt.score}',
                                            style: AppTextStyles.subtitle
                                                .copyWith(
                                                  color: AppColors.forestGreen,
                                                ),
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                attempt.quizTitle ??
                                                    'Kuis Energi Terbarukan',
                                                style: AppTextStyles.bodyMedium
                                                    .copyWith(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'Benar ${attempt.correctCount} dari ${attempt.totalQuestions} soal',
                                                style: AppTextStyles.caption,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
      ),
    );
  }

  Widget _buildSummaryBanner({
    required int uniqueQuizzesCount,
    required int totalAttempts,
    required int averageScore,
    required int savedMaterialsCount,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.mintGreen,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppColors.sageGreen),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SummaryMetric(
            label: 'Kuis Selesai',
            value: '$uniqueQuizzesCount',
          ),
          _SummaryMetric(
            label: 'Total Percobaan',
            value: '${totalAttempts}x',
          ),
          _SummaryMetric(
            label: 'Rata-rata Skor',
            value: '$averageScore',
          ),
          _SummaryMetric(
            label: 'Materi Disimpan',
            value: '$savedMaterialsCount',
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.title.copyWith(color: AppColors.forestGreen),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(fontSize: 11),
        ),
      ],
    );
  }
}

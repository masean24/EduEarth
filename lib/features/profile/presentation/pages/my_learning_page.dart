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
import '../../../../core/widgets/common/screen_header.dart';
import '../../../../routes/route_names.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../bookmark/presentation/providers/bookmark_providers.dart';
import '../../../learning/presentation/providers/learning_providers.dart';
import '../../../learning/presentation/providers/reading_progress_provider.dart';
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
    final materialsAsync = ref.watch(allLearningMaterialsProvider);
    final readingState = ref.watch(readingProgressProvider);

    return Scaffold(
      appBar: ScreenHeaderBar(
        title: 'Progres Belajar Saya',
        subtitle: 'Statistik skor kuis dan materi tersimpan',
        actions: [
          ScreenHeaderAction(
            tooltip: 'Bookmark Saya',
            icon: Icons.bookmark_outline_rounded,
            onTap: () => context.push(RouteNames.bookmarksPath),
          ),
        ],
      ),
      body: SafeArea(
        child: !isAuthenticated
            ? EmptyView(
                icon: Icons.school_outlined,
                assetPath: 'assets/images/mascot/eco_wave.png',
                title: 'Masuk untuk Menyimpan Progres',
                description:
                    'Mode tamu tidak menyimpan progres baca atau skor kuis. Masuk ke akun EduEarth untuk mencatat perkembangan skor dan materi belajarmu.',
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
                        final plantBookmarksCount = bookmarks
                            .where((b) => b.plant != null)
                            .length;
                        final allMaterials =
                            materialsAsync.asData?.value ?? const [];
                        final readMaterials = allMaterials
                            .where(
                              (m) => readingState.progressFor(m.slug) > 0.02,
                            )
                            .toList();

                        if (attempts.isEmpty &&
                            materialBookmarks.isEmpty &&
                            readMaterials.isEmpty) {
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
                        final quizSummaries = summarizeQuizAttempts(attempts);
                        final quizTitleById = <String, String>{};
                        for (final a in attempts) {
                          if (a.quizTitle != null &&
                              a.quizTitle!.trim().isNotEmpty) {
                            quizTitleById.putIfAbsent(
                              a.quizId,
                              () => a.quizTitle!.trim(),
                            );
                          }
                        }
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
                            if (quizSummaries.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              _buildScoreProgressionCard(
                                summaries: quizSummaries.values.toList(),
                                titleById: quizTitleById,
                              ),
                            ],
                            const SizedBox(height: 16),
                            _buildFourPillarMasteryCard(
                              context: context,
                              savedPlantsCount: plantBookmarksCount,
                              startedMaterialsCount:
                                  readingState.startedCount(),
                              completedMaterialsCount:
                                  readingState.completedCount(),
                              uniqueQuizzesCount: uniqueQuizzesCount,
                            ),
                            if (readMaterials.isNotEmpty) ...[
                              const SizedBox(height: 24),
                              Text(
                                'Progres Baca Materi (${readMaterials.length})',
                                style: AppTextStyles.title,
                              ),
                              const SizedBox(height: 12),
                              ...readMaterials.map((mat) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: MaterialCard(
                                    material: mat,
                                    readingProgress: readingState.progressFor(
                                      mat.slug,
                                    ),
                                    onTap: () => context.push(
                                      '/learning/material/${mat.slug}',
                                    ),
                                  ),
                                );
                              }),
                            ],
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
                                    readingProgress: readingState.progressFor(
                                      mat.slug,
                                    ),
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

  Widget _buildScoreProgressionCard({
    required List<QuizAttemptSummary> summaries,
    required Map<String, String> titleById,
  }) {
    final avgInitial = (summaries
                .map((s) => s.initialScore)
                .reduce((a, b) => a + b) /
            summaries.length)
        .round();
    final avgLatest = (summaries
                .map((s) => s.latestScore)
                .reduce((a, b) => a + b) /
            summaries.length)
        .round();
    final avgDelta = avgLatest - avgInitial;
    final avgDeltaText = avgDelta > 0
        ? '+$avgDelta poin'
        : avgDelta == 0
        ? 'Tetap'
        : '$avgDelta poin';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.trending_up_rounded,
                size: 19,
                color: AppColors.forestGreen,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Perkembangan Skor (Pre-Check → Terbaru)',
                  style: AppTextStyles.subtitle.copyWith(fontSize: 15),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: avgDelta > 0
                      ? AppColors.mintGreen
                      : AppColors.offWhite,
                  borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                  border: Border.all(
                    color: avgDelta > 0
                        ? AppColors.sageGreen
                        : AppColors.divider,
                  ),
                ),
                child: Text(
                  avgDeltaText,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.forestGreen,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Rata-rata skor awal: $avgInitial → terbaru: $avgLatest',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          ...summaries.map((summary) {
            final title = titleById[summary.quizId] ?? 'Kuis Energi Terbarukan';
            final delta = summary.scoreDelta;
            final deltaLabel = delta > 0
                ? '+$delta'
                : delta == 0
                ? '0'
                : '$delta';
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: AppColors.offWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            summary.hasMultipleAttempts
                                ? 'Awal: ${summary.initialScore} → Terbaru: ${summary.latestScore} (${summary.attemptCount}x percobaan)'
                                : 'Skor Awal (Pre-Check): ${summary.initialScore} • Kerjakan ulang setelah belajar',
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (summary.hasMultipleAttempts) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: delta > 0
                              ? AppColors.mintGreen
                              : AppColors.surfaceWhite,
                          borderRadius: BorderRadius.circular(
                            AppTheme.pillRadius,
                          ),
                          border: Border.all(
                            color: delta > 0
                                ? AppColors.sageGreen
                                : AppColors.divider,
                          ),
                        ),
                        child: Text(
                          deltaLabel,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.forestGreen,
                            fontWeight: FontWeight.w800,
                            fontSize: 11.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFourPillarMasteryCard({
    required BuildContext context,
    required int savedPlantsCount,
    required int startedMaterialsCount,
    required int completedMaterialsCount,
    required int uniqueQuizzesCount,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_graph_rounded,
                size: 19,
                color: AppColors.forestGreen,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Jejak Belajar 4 Pilar EduEarth',
                  style: AppTextStyles.subtitle.copyWith(fontSize: 15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Explore: $savedPlantsCount pembangkit disimpan dari peta\n'
            '• Learn: $startedMaterialsCount modul mulai dibaca ($completedMaterialsCount selesai ≥85%)\n'
            '• Understand Impact: Bandingkan 5 kategori EBT & trade-off lingkungan\n'
            '• Evaluate: $uniqueQuizzesCount dari 6 topik kuis telah dikerjakan',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
              fontSize: 12.2,
            ),
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


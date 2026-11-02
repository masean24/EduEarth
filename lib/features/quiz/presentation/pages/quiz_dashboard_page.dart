import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common/category_chip.dart';
import '../../../../core/widgets/common/empty_view.dart';
import '../../../../core/widgets/common/error_view.dart';
import '../../../../core/widgets/common/loading_view.dart';
import '../../../../core/widgets/common/primary_button.dart';
import '../../../../models/quiz.dart';
import '../../../../models/quiz_attempt.dart';
import '../../../../routes/route_names.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/quiz_providers.dart';

/// Halaman Utama Kuis (Quiz Dashboard) Fase 4.
///
/// Menampilkan daftar kuis terpublikasi, informasi tingkat kesulitan & batas waktu,
/// serta riwayat skor percobaan kuis milik pengguna yang sedang login.
class QuizDashboardPage extends ConsumerWidget {
  const QuizDashboardPage({super.key});

  void _startQuiz(BuildContext context, WidgetRef ref, Quiz quiz) {
    final isAuthenticated = ref.read(isAuthenticatedProvider);
    if (!isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Silakan masuk (login) terlebih dahulu untuk mengerjakan kuis.',
          ),
        ),
      );
      context.push(RouteNames.loginPath);
      return;
    }

    context.push('/quiz/${quiz.id}/play');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quizzesAsync = ref.watch(publishedQuizzesProvider);
    final attemptsAsync = ref.watch(userQuizAttemptsProvider);
    final isAuthenticated = ref.watch(isAuthenticatedProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kuis Energi Terbarukan'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.freshGreen,
          onRefresh: () async {
            ref.invalidate(publishedQuizzesProvider);
            ref.invalidate(userQuizAttemptsProvider);
          },
          child: quizzesAsync.when(
            loading: () => const LoadingView(
              message: 'Memuat daftar kuis energi terbarukan...',
            ),
            error: (error, _) => ErrorView(
              message: error.toString(),
              onRetry: () {
                ref.invalidate(publishedQuizzesProvider);
                ref.invalidate(userQuizAttemptsProvider);
              },
            ),
            data: (quizzes) {
              if (quizzes.isEmpty) {
                return EmptyView(
                  icon: Icons.quiz_outlined,
                  title: 'Belum Ada Kuis Tersedia',
                  description:
                      'Jalankan file migrasi seed kuis & kunci jawaban di Supabase SQL Editor untuk mulai berlatih.',
                  actionLabel: 'Muat Ulang',
                  onAction: () => ref.invalidate(publishedQuizzesProvider),
                );
              }

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
                children: [
                  _buildSecurityInfoBanner(),
                  const SizedBox(height: 24),
                  Text('Pilih Kuis untuk Dimulai', style: AppTextStyles.title),
                  const SizedBox(height: 6),
                  Text(
                    'Setiap jawaban dinilai di server dan dilengkapi pembahasan konsep setelah selesai.',
                    style: AppTextStyles.caption,
                  ),
                  const SizedBox(height: 12),
                  ...quizzes.map((quiz) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _QuizCard(
                        quiz: quiz,
                        onStart: () => _startQuiz(context, ref, quiz),
                      ),
                    );
                  }),
                  const SizedBox(height: 20),
                  Text('Riwayat Percobaan Saya', style: AppTextStyles.title),
                  const SizedBox(height: 12),
                  _buildAttemptsSection(
                    context: context,
                    ref: ref,
                    isAuthenticated: isAuthenticated,
                    attemptsAsync: attemptsAsync,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.mintGreen,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppColors.sageGreen),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppColors.surfaceWhite,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified_user_outlined,
              color: AppColors.forestGreen,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Uji Wawasan Transisi Energi',
                  style: AppTextStyles.subtitle,
                ),
                const SizedBox(height: 4),
                Text(
                  'Skor dan kunci jawaban dievaluasi secara aman setelah Anda menyelesaikan seluruh soal.',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttemptsSection({
    required BuildContext context,
    required WidgetRef ref,
    required bool isAuthenticated,
    required AsyncValue<List<QuizAttempt>> attemptsAsync,
  }) {
    if (!isAuthenticated) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          children: [
            Text(
              'Masuk ke akun Anda untuk menyimpan dan melihat riwayat skor kuis.',
              style: AppTextStyles.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              label: 'Masuk (Login)',
              icon: Icons.login_rounded,
              isExpanded: false,
              onPressed: () => context.push(RouteNames.loginPath),
            ),
          ],
        ),
      );
    }

    return attemptsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: LoadingView(message: 'Memuat riwayat kuis...'),
      ),
      error: (error, _) => ErrorView(
        message: error.toString(),
        onRetry: () => ref.invalidate(userQuizAttemptsProvider),
      ),
      data: (attempts) {
        if (attempts.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              border: Border.all(color: AppColors.divider),
            ),
            child: Text(
              'Anda belum memiliki riwayat pengerjaan kuis. Pilih salah satu kuis di atas untuk mulai!',
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
          );
        }

        return Column(
          children: attempts.take(8).map((attempt) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: attempt.score >= 70
                            ? AppColors.mintGreen
                            : AppColors.warmYellow.withValues(alpha: 0.25),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${attempt.score}',
                        style: AppTextStyles.subtitle.copyWith(
                          color: AppColors.forestGreen,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            attempt.quizTitle ?? 'Kuis Energi Terbarukan',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
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
          }).toList(),
        );
      },
    );
  }
}

class _QuizCard extends StatelessWidget {
  const _QuizCard({
    required this.quiz,
    required this.onStart,
  });

  final Quiz quiz;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final categoryColor = quiz.categorySlug != null
        ? AppColors.colorForCategorySlug(quiz.categorySlug!)
        : AppColors.freshGreen;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: categoryColor.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                    border: Border.all(color: categoryColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        iconForCategorySlug(quiz.categorySlug),
                        size: 14,
                        color: AppColors.forestGreen,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        quiz.categoryName ?? 'Umum • Lintas Kategori',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.forestGreen,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (quiz.isDraft)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warmYellow.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                      border: Border.all(color: AppColors.warmYellow),
                    ),
                    child: Text(
                      'DRAF REVIEW',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.forestGreen,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(quiz.title, style: AppTextStyles.title),
            const SizedBox(height: 6),
            Text(
              quiz.description,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(
                  Icons.bar_chart_rounded,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  'Tingkat: ${quiz.difficultyLabel}',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(width: 16),
                const Icon(
                  Icons.timer_outlined,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  quiz.timeLimitLabel,
                  style: AppTextStyles.caption,
                ),
              ],
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Mulai Kerjakan Kuis',
              icon: Icons.play_arrow_rounded,
              onPressed: onStart,
            ),
          ],
        ),
      ),
    );
  }
}

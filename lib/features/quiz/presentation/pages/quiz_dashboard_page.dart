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
import '../../../../core/widgets/common/screen_header.dart';
import '../../../../core/widgets/common/secondary_button.dart';
import '../../../../models/quiz.dart';
import '../../../../models/quiz_attempt.dart';
import '../../../../routes/route_names.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/quiz_providers.dart';

/// Halaman Utama Kuis (Quiz Dashboard).
///
/// Menampilkan daftar kuis dengan pembeda visual antara kuis yang belum dikerjakan
/// ("Mulai Kuis" — `PrimaryButton`) dan kuis yang sudah dikerjakan (badge "Selesai",
/// skor terbaik, skor terakhir, jumlah percobaan, serta tombol "Ulangi Kuis" — `SecondaryButton`).
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
    final groupedSummariesAsync = ref.watch(quizAttemptsByQuizIdProvider);
    final isAuthenticated = ref.watch(isAuthenticatedProvider);

    final summariesMap = isAuthenticated
        ? (groupedSummariesAsync.asData?.value ??
            const <String, QuizAttemptSummary>{})
        : const <String, QuizAttemptSummary>{};

    return Scaffold(
      body: SafeArea(
        bottom: false,
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

              final bottomSafe = MediaQuery.viewPaddingOf(context).bottom;

              return ListView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  16,
                  20,
                  AppTheme.bottomNavScrollPadding + bottomSafe,
                ),
                children: [
                  ScreenHeader(
                    title: 'Kuis Energi Terbarukan',
                    subtitle:
                        'Uji pemahaman konsep pembangkit energi bersih Anda',
                    actions: [
                      ScreenHeaderAction(
                        tooltip: 'Pencarian Global',
                        icon: Icons.search_rounded,
                        onTap: () => context.push(RouteNames.searchPath),
                      ),
                      ScreenHeaderAction(
                        tooltip: 'Progres Belajar Saya',
                        icon: Icons.school_outlined,
                        onTap: () => context.push(RouteNames.myLearningPath),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSecurityInfoBanner(),
                  const SizedBox(height: 24),
                  Text('Pilih Kuis untuk Dimulai', style: AppTextStyles.title),
                  const SizedBox(height: 6),
                  Text(
                    'Setiap jawaban dinilai di server dan dilengkapi pembahasan konsep tepat setelah selesai.',
                    style: AppTextStyles.caption,
                  ),
                  const SizedBox(height: 12),
                  ...quizzes.map((quiz) {
                    final summary = summariesMap[quiz.id];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _QuizCard(
                        quiz: quiz,
                        attemptSummary: summary,
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
                  'Skor dan kunci jawaban dievaluasi secara aman di sisi server setelah Anda menyelesaikan soal.',
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
        child: LoadingView(message: 'Memuat riwayat percobaan kuis...'),
      ),
      error: (error, _) => ErrorView(
        title: 'Gagal Memuat Riwayat Kuis',
        message: error.toString(),
        onRetry: () => ref.invalidate(userQuizAttemptsProvider),
      ),
      data: (attempts) {
        if (attempts.isEmpty) {
          return EmptyView(
            icon: Icons.history_edu_rounded,
            title: 'Belum Ada Riwayat Percobaan',
            description:
                'Anda belum pernah menyelesaikan kuis. Pilih salah satu kuis di atas untuk mulai berlatih!',
          );
        }

        return Column(
          children: attempts.take(10).map((attempt) {
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
    this.attemptSummary,
  });

  final Quiz quiz;
  final QuizAttemptSummary? attemptSummary;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final categoryColor = quiz.categorySlug != null
        ? AppColors.colorForCategorySlug(quiz.categorySlug!)
        : AppColors.freshGreen;
    final isCompleted = attemptSummary != null;
    final categoryLabel = quiz.categorySlug != null
        ? shortDisplayLabelForSlug(
            quiz.categorySlug,
            quiz.categoryName ?? 'Umum',
          )
        : (quiz.categoryName ?? 'Lintas Kategori');

    return Container(
      padding: AppTheme.cardPadding,
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Maksimal 2 chip: (1) Kategori, dan (2) Status "Selesai" ATAU "DRAF REVIEW"
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: AppTheme.badgePadding,
                decoration: AppTheme.badgeDecoration(
                  backgroundColor: categoryColor.withValues(alpha: 0.16),
                  borderColor: categoryColor.withValues(alpha: 0.55),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      iconForCategorySlug(quiz.categorySlug),
                      size: 14,
                      color: AppColors.forestGreen,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      categoryLabel,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.forestGreen,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (isCompleted)
                Container(
                  padding: AppTheme.badgePadding,
                  decoration: AppTheme.badgeDecoration(
                    backgroundColor: AppColors.mintGreen,
                    borderColor: AppColors.sageGreen,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 14,
                        color: AppColors.forestGreen,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Selesai',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.forestGreen,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                )
              else if (quiz.isDraft)
                Container(
                  padding: AppTheme.badgePadding,
                  decoration: AppTheme.badgeDecoration(
                    backgroundColor: AppColors.warmYellow.withValues(
                      alpha: 0.25,
                    ),
                    borderColor: AppColors.warmYellow,
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
          // Baris info metadata (tingkat kesulitan, batas waktu, dan status draf bila sudah selesai)
          Wrap(
            spacing: 14,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.bar_chart_rounded,
                    size: 15,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Tingkat: ${quiz.difficultyLabel}',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.timer_outlined,
                    size: 15,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    quiz.timeLimitLabel,
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
              if (isCompleted && quiz.isDraft)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.edit_note_rounded,
                      size: 15,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Draf review',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
            ],
          ),
            if (attemptSummary != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.mintGreen.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.sageGreen),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _AttemptMetricItem(
                      label: 'Skor Terbaik',
                      value: '${attemptSummary!.bestScore}',
                      icon: Icons.emoji_events_outlined,
                    ),
                    Container(
                      width: 1,
                      height: 28,
                      color: AppColors.sageGreen,
                    ),
                    _AttemptMetricItem(
                      label: 'Skor Terakhir',
                      value: '${attemptSummary!.latestScore}',
                      icon: Icons.history_rounded,
                    ),
                    Container(
                      width: 1,
                      height: 28,
                      color: AppColors.sageGreen,
                    ),
                    _AttemptMetricItem(
                      label: 'Percobaan',
                      value: '${attemptSummary!.attemptCount}x',
                      icon: Icons.repeat_rounded,
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (isCompleted)
              SecondaryButton(
                label: 'Ulangi Kuis',
                icon: Icons.replay_rounded,
                onPressed: onStart,
              )
            else
              PrimaryButton(
                label: 'Mulai Kuis',
                icon: Icons.play_arrow_rounded,
                onPressed: onStart,
              ),
          ],
        ),
    );
  }
}

class _AttemptMetricItem extends StatelessWidget {
  const _AttemptMetricItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.forestGreen),
            const SizedBox(width: 4),
            Text(
              value,
              style: AppTextStyles.subtitle.copyWith(
                color: AppColors.forestGreen,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(fontSize: 11),
        ),
      ],
    );
  }
}

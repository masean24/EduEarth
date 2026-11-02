import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common/empty_view.dart';
import '../../../../core/widgets/common/error_view.dart';
import '../../../../core/widgets/common/loading_view.dart';
import '../../../../core/widgets/common/primary_button.dart';
import '../../../../core/widgets/common/screen_header.dart';
import '../../../../core/widgets/common/secondary_button.dart';
import '../../../../core/widgets/common/soft_image_placeholder.dart';
import '../../../../models/quiz_attempt.dart';
import '../../../../routes/route_names.dart';
import '../providers/quiz_providers.dart';

/// Halaman Hasil Kuis (Quiz Result) sesuai gaya `docs/design/moodboard.png`.
///
/// Menampilkan skor akhir, jumlah benar, serta ulasan jawaban benar/salah +
/// penjelasan per soal yang dikembalikan oleh RPC `submit_quiz_attempt`
/// (HANYA setelah submit).
class QuizResultPage extends ConsumerWidget {
  const QuizResultPage({
    super.key,
    required this.quizId,
    this.initialResult,
  });

  final String quizId;
  final QuizSubmissionResult? initialResult;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quizAsync = ref.watch(quizDetailProvider(quizId));
    final storedResult = ref.watch(latestQuizResultProvider)[quizId];
    final result = initialResult ?? storedResult;

    return Scaffold(
      appBar: const ScreenHeaderBar(
        title: 'Hasil & Pembahasan',
        subtitle: 'Skor dan ulasan jawaban dari server',
      ),
      body: SafeArea(
        child: quizAsync.when(
          loading: () => const LoadingView(
            message: 'Memuat ringkasan hasil kuis...',
          ),
          error: (error, _) => ErrorView(
            message: error.toString(),
            onRetry: () => ref.invalidate(quizDetailProvider(quizId)),
          ),
          data: (quiz) {
            if (result == null) {
              return EmptyView(
                icon: Icons.assignment_late_outlined,
                title: 'Hasil Kuis Belum Tersedia',
                description:
                    'Silakan kerjakan dan kirim jawaban kuis terlebih dahulu untuk melihat skor dan pembahasan.',
                actionLabel: 'Mulai Kuis Sekarang',
                onAction: () =>
                    context.pushReplacement('/quiz/$quizId/play'),
              );
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
              children: [
                _buildScoreHeaderCard(quiz.title, result),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: PrimaryButton(
                        label: 'Ulangi Kuis',
                        icon: Icons.replay_rounded,
                        onPressed: () =>
                            context.pushReplacement('/quiz/$quizId/play'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SecondaryButton(
                        label: 'Daftar Kuis',
                        icon: Icons.list_alt_rounded,
                        onPressed: () => context.go(RouteNames.quizPath),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Text(
                  'Ulasan Jawaban (${result.reviews.length} Soal)',
                  style: AppTextStyles.title,
                ),
                const SizedBox(height: 12),
                ...List.generate(result.reviews.length, (index) {
                  final review = result.reviews[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _QuestionReviewCard(
                      questionNumber: index + 1,
                      review: review,
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildScoreHeaderCard(
    String quizTitle,
    QuizSubmissionResult result,
  ) {
    final isPassed = result.score >= 70;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          SoftImagePlaceholder(
            width: 88,
            height: 88,
            borderRadius: 44,
            assetPath: isPassed
                ? 'assets/images/mascot/eco_congrats.png'
                : 'assets/images/mascot/eco_thinking.png',
            backgroundColor: isPassed
                ? const Color(0xFFFEF9C3)
                : AppColors.mintGreen,
            fallbackIcon: isPassed
                ? Icons.emoji_events_rounded
                : Icons.psychology_alt_rounded,
            iconColor: isPassed
                ? const Color(0xFFD97706)
                : AppColors.forestGreen,
            iconSize: 44,
          ),
          const SizedBox(height: 14),
          Text(
            isPassed ? 'Kerja Bagus!' : 'Terus Semangat Belajar!',
            style: AppTextStyles.display.copyWith(fontSize: 22),
          ),
          const SizedBox(height: 4),
          Text(
            quizTitle,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.mintGreen,
                  borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                ),
                child: Text(
                  'Skor: ${result.score}',
                  style: AppTextStyles.subtitle.copyWith(
                    color: AppColors.forestGreen,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.offWhite,
                  borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Text(
                  'Benar: ${result.correctCount}/${result.totalQuestions}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.forestGreen,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuestionReviewCard extends StatelessWidget {
  const _QuestionReviewCard({
    required this.questionNumber,
    required this.review,
  });

  final int questionNumber;
  final QuizQuestionReview review;

  String _findOptionText(String? optionId) {
    if (optionId == null || optionId.isEmpty) {
      return 'Tidak dijawab';
    }
    final match = review.options
        .where((o) => o.id.toLowerCase() == optionId.toLowerCase())
        .firstOrNull;
    if (match == null) return optionId.toUpperCase();
    return match.text;
  }

  @override
  Widget build(BuildContext context) {
    final isCorrect = review.isCorrect;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Soal $questionNumber',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(review.question, style: AppTextStyles.subtitle),
          const SizedBox(height: 12),
          // Pilihan jawaban Anda
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isCorrect ? AppColors.mintGreen : AppColors.errorLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isCorrect ? AppColors.freshGreen : AppColors.errorRed,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isCorrect
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  size: 20,
                  color: isCorrect ? AppColors.freshGreen : AppColors.errorRed,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Jawaban Anda: ${_findOptionText(review.selectedOptionId)}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isCorrect
                          ? AppColors.forestGreen
                          : AppColors.errorRed,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!isCorrect) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.mintGreen,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline_rounded,
                    size: 20,
                    color: AppColors.forestGreen,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Jawaban Benar: ${_findOptionText(review.correctOptionId)}',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.forestGreen,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          // Kotak penjelasan bergaya kartu "Benar!" di moodboard (dengan slot maskot Eco)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isCorrect
                  ? AppColors.mintGreen.withValues(alpha: 0.65)
                  : AppColors.offWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isCorrect ? AppColors.sageGreen : AppColors.divider,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SoftImagePlaceholder(
                  width: 40,
                  height: 40,
                  borderRadius: 20,
                  assetPath: isCorrect
                      ? 'assets/images/mascot/eco_happy.png'
                      : 'assets/images/mascot/eco_thinking.png',
                  backgroundColor: AppColors.surfaceWhite,
                  fallbackIcon: isCorrect
                      ? Icons.sentiment_very_satisfied_rounded
                      : Icons.lightbulb_outline_rounded,
                  iconColor: AppColors.forestGreen,
                  iconSize: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isCorrect ? 'Benar!' : 'Pembahasan:',
                        style: AppTextStyles.subtitle.copyWith(
                          fontSize: 14,
                          color: AppColors.forestGreen,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        review.explanation,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.forestGreen,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

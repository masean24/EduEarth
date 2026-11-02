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
import '../../../../core/widgets/common/secondary_button.dart';
import '../../../../models/quiz_attempt.dart';
import '../../../../routes/route_names.dart';
import '../providers/quiz_providers.dart';

/// Halaman Hasil Kuis (Quiz Result) yang menampilkan skor akhir, jumlah benar,
/// serta ulasan jawaban benar/salah + penjelasan per soal yang dikembalikan
/// oleh RPC `submit_quiz_attempt`.
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
      appBar: AppBar(
        title: const Text('Hasil & Pembahasan Kuis'),
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
                const SizedBox(height: 20),
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
                        label: 'Ke Daftar Kuis',
                        icon: Icons.list_alt_rounded,
                        onPressed: () => context.go(RouteNames.quizPath),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Text(
                  'Pembahasan Jawaban (${result.reviews.length} Soal)',
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
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        gradient: LinearGradient(
          colors: isPassed
              ? [AppColors.forestGreen, const Color(0xFF1E7A44)]
              : [AppColors.forestGreen, AppColors.skyBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(
              color: AppColors.mintGreen,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '${result.score}',
              style: AppTextStyles.display.copyWith(
                fontSize: 32,
                color: AppColors.forestGreen,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isPassed ? 'Kerja Bagus!' : 'Terus Semangat Belajar!',
            style: AppTextStyles.title.copyWith(
              color: AppColors.surfaceWhite,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            quizTitle,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.mintGreen,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(AppTheme.pillRadius),
            ),
            child: Text(
              'Jawaban Benar: ${result.correctCount} dari ${result.totalQuestions} Soal',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.surfaceWhite,
                fontWeight: FontWeight.w700,
              ),
            ),
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
    return '${match.id.toUpperCase()}. ${match.text}';
  }

  @override
  Widget build(BuildContext context) {
    final statusColor =
        review.isCorrect ? AppColors.freshGreen : AppColors.errorRed;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.45),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: review.isCorrect
                      ? AppColors.mintGreen
                      : AppColors.errorLight,
                  borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      review.isCorrect
                          ? Icons.check_circle_rounded
                          : Icons.cancel_rounded,
                      size: 15,
                      color: review.isCorrect
                          ? AppColors.forestGreen
                          : AppColors.errorRed,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      review.isCorrect
                          ? 'Soal #$questionNumber • Benar'
                          : 'Soal #$questionNumber • Kurang Tepat',
                      style: AppTextStyles.caption.copyWith(
                        color: review.isCorrect
                            ? AppColors.forestGreen
                            : AppColors.errorRed,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(review.question, style: AppTextStyles.subtitle),
          const SizedBox(height: 12),
          Text(
            'Jawaban Anda: ${_findOptionText(review.selectedOptionId)}',
            style: AppTextStyles.body.copyWith(
              color: review.isCorrect
                  ? AppColors.forestGreen
                  : AppColors.errorRed,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (!review.isCorrect) ...[
            const SizedBox(height: 6),
            Text(
              'Jawaban Benar: ${_findOptionText(review.correctOptionId)}',
              style: AppTextStyles.body.copyWith(
                color: AppColors.forestGreen,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.offWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.lightbulb_outline_rounded,
                  size: 18,
                  color: AppColors.forestGreen,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    review.explanation,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textPrimary,
                    ),
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


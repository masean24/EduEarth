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
import '../../../achievement/presentation/providers/achievement_providers.dart';
import '../../../achievement/presentation/widgets/achievement_unlock_dialog.dart';
import '../providers/quiz_providers.dart';

/// Halaman Hasil Kuis (Quiz Result) dengan animasi penghitung skor melingkar,
/// gelar apresiasi, serta ulasan jawaban benar/salah + pembahasan ilmiah per soal.
class QuizResultPage extends ConsumerStatefulWidget {
  const QuizResultPage({
    super.key,
    required this.quizId,
    this.initialResult,
  });

  final String quizId;
  final QuizSubmissionResult? initialResult;

  @override
  ConsumerState<QuizResultPage> createState() => _QuizResultPageState();
}

class _QuizResultPageState extends ConsumerState<QuizResultPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkNewlyUnlockedBadges();
    });
  }

  Future<void> _checkNewlyUnlockedBadges() async {
    try {
      final award = await ref
          .read(achievementRepositoryProvider)
          .evaluateAchievements();
      ref.invalidate(achievementsListProvider);
      if (!mounted) return;
      if (award.newlyAwardedTitles.isNotEmpty) {
        await showAchievementUnlockDialog(
          context,
          badgeTitles: award.newlyAwardedTitles,
        );
      }
    } catch (_) {
      // Abaikan bila evaluasi latar gagal agar hasil kuis tetap tampil lancar
    }
  }

  @override
  Widget build(BuildContext context) {
    final quizId = widget.quizId;
    final initialResult = widget.initialResult;
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
    final isExcellent = result.score >= 90;
    final isPassed = result.score >= 70;
    final wrongCount =
        (result.totalQuestions - result.correctCount).clamp(0, 999);

    final rankTitle = isExcellent
        ? '🏆 Master Energi Nusantara!'
        : isPassed
            ? '🌿 Penjelajah Hijau Andal!'
            : '🌱 Terus Semangat Belajar!';

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surfaceWhite,
            AppColors.mintGreen.withValues(alpha: 0.45),
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppColors.sageGreen),
        boxShadow: AppTheme.softCardShadow,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SoftImagePlaceholder(
                width: 82,
                height: 82,
                borderRadius: 41,
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
                iconSize: 40,
              ),
              const SizedBox(width: 18),
              // Lingkaran Skor Beranimasi (0 -> Skor Akhir)
              TweenAnimationBuilder<double>(
                tween: Tween<double>(
                  begin: 0,
                  end: result.score.toDouble(),
                ),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (context, animatedScore, _) {
                  final normalized = (animatedScore / 100).clamp(0.0, 1.0);
                  return SizedBox(
                    width: 86,
                    height: 86,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 86,
                          height: 86,
                          child: CircularProgressIndicator(
                            value: normalized,
                            strokeWidth: 8,
                            backgroundColor: AppColors.surfaceWhite,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isPassed
                                  ? AppColors.freshGreen
                                  : const Color(0xFFD97706),
                            ),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${animatedScore.round()}',
                              style: AppTextStyles.display.copyWith(
                                fontSize: 24,
                                color: AppColors.forestGreen,
                                height: 1.0,
                              ),
                            ),
                            Text(
                              'POIN',
                              style: AppTextStyles.caption.copyWith(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            rankTitle,
            style: AppTextStyles.display.copyWith(fontSize: 20),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            quizTitle,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                  border: Border.all(color: AppColors.freshGreen),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 15,
                      color: AppColors.freshGreen,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Benar: ${result.correctCount}/${result.totalQuestions}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.forestGreen,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              if (wrongCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWhite,
                    borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 15,
                        color: Color(0xFFD97706),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Perlu Ulasan: $wrongCount',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
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

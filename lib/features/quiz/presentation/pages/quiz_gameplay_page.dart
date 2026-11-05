import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common/empty_view.dart';
import '../../../../core/widgets/common/error_view.dart';
import '../../../../core/widgets/common/loading_view.dart';
import '../../../../core/widgets/common/secondary_button.dart';
import '../../../../core/widgets/common/soft_image_placeholder.dart';
import '../../../../models/quiz.dart';
import '../../../../models/quiz_question.dart';
import '../../../../routes/route_names.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/quiz_providers.dart';

/// Halaman Pengerjaan Kuis (Quiz Gameplay) yang interaktif & modern:
/// - Wajib login & penilaian tetap dilakukan 100% di server via RPC `submit_quiz_attempt`.
/// - Dilengkapi strip navigasi nomor soal (`1..N`) yang bisa diklik langsung.
/// - Sapaan penyemangat dinamis dari maskot Eco sesuai progres pengerjaan.
/// - Animasi pergantian soal (`AnimatedSwitcher`) dan badge pilihan `A/B/C/D`.
class QuizGameplayPage extends ConsumerStatefulWidget {
  const QuizGameplayPage({
    super.key,
    required this.quizId,
  });

  final String quizId;

  @override
  ConsumerState<QuizGameplayPage> createState() => _QuizGameplayPageState();
}

class _QuizGameplayPageState extends ConsumerState<QuizGameplayPage> {
  final Map<String, String> _selectedAnswers = <String, String>{};
  int _currentQuestionIndex = 0;
  Timer? _countdownTimer;
  int? _remainingSeconds;
  bool _timerInitialized = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _initTimerIfNeeded(Quiz quiz) {
    if (_timerInitialized) return;
    _timerInitialized = true;

    final limit = quiz.timeLimitSeconds;
    if (limit == null || limit <= 0) return;

    _remainingSeconds = limit;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final current = _remainingSeconds ?? 0;
      if (current <= 1) {
        timer.cancel();
        setState(() => _remainingSeconds = 0);
        _submitQuiz(isAutoSubmitOnTimeout: true);
      } else {
        setState(() => _remainingSeconds = current - 1);
      }
    });
  }

  Future<bool> _confirmExit() async {
    if (_isSubmitting) return false;
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          ),
          title: Text('Keluar dari Kuis?', style: AppTextStyles.title),
          content: Text(
            'Progres jawaban Anda saat ini belum dikirim dan akan hilang jika Anda keluar.',
            style: AppTextStyles.body,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Lanjut Mengerjakan'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.errorRed,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Keluar'),
            ),
          ],
        );
      },
    );
    return shouldLeave ?? false;
  }

  Future<void> _submitQuiz({bool isAutoSubmitOnTimeout = false}) async {
    if (_isSubmitting) return;
    _countdownTimer?.cancel();
    setState(() => _isSubmitting = true);

    if (isAutoSubmitOnTimeout && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Waktu habis! Jawaban Anda sedang dinilai di server...',
          ),
        ),
      );
    }

    final result = await ref
        .read(quizSubmissionControllerProvider.notifier)
        .submit(
          quizId: widget.quizId,
          answers: Map<String, String>.from(_selectedAnswers),
        );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result != null) {
      context.pushReplacement(
        '/quiz/${widget.quizId}/result',
        extra: result,
      );
    } else {
      final err = ref.read(quizSubmissionControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            err?.toString() ??
                'Gagal mengirim jawaban kuis. Silakan coba lagi.',
          ),
        ),
      );
    }
  }

  String _ecoEncouragementText({
    required int answeredCount,
    required int totalQuestions,
    required int currentIndex,
  }) {
    if (answeredCount == totalQuestions && totalQuestions > 0) {
      return 'Semua $totalQuestions soal sudah terjawab! Siap kirim jawabanmu? 🏆';
    }
    if (currentIndex == 0 && answeredCount == 0) {
      return 'Soal pembuka! Baca dengan teliti dan pilih jawaban terbaikmu 🌱';
    }
    if (answeredCount >= (totalQuestions / 2).ceil()) {
      return 'Keren! $answeredCount dari $totalQuestions soal sudah terjawab, sedikit lagi! ⚡';
    }
    return 'Terjawab $answeredCount dari $totalQuestions soal • Kamu pasti bisa! 🌿';
  }

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    if (!isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('Kuis Energi Terbarukan')),
        body: SafeArea(
          child: EmptyView(
            icon: Icons.lock_outline_rounded,
            title: 'Wajib Masuk (Login)',
            description:
                'Silakan masuk menggunakan akun Anda untuk mengerjakan kuis dan menyimpan skor di server.',
            actionLabel: 'Ke Halaman Masuk',
            onAction: () => context.pushReplacement(RouteNames.loginPath),
          ),
        ),
      );
    }

    final quizAsync = ref.watch(quizDetailProvider(widget.quizId));
    final questionsAsync = ref.watch(quizQuestionsProvider(widget.quizId));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final confirmed = await _confirmExit();
        if (confirmed && context.mounted) {
          context.pop();
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: quizAsync.when(
            loading: () => const LoadingView(
              message: 'Menyiapkan kuis...',
            ),
            error: (error, _) => ErrorView(
              message: error.toString(),
              onRetry: () {
                ref.invalidate(quizDetailProvider(widget.quizId));
                ref.invalidate(quizQuestionsProvider(widget.quizId));
              },
            ),
            data: (quiz) {
              _initTimerIfNeeded(quiz);

              return questionsAsync.when(
                loading: () => const LoadingView(
                  message: 'Memuat soal kuis...',
                ),
                error: (error, _) => ErrorView(
                  message: error.toString(),
                  onRetry: () =>
                      ref.invalidate(quizQuestionsProvider(widget.quizId)),
                ),
                data: (questions) {
                  if (questions.isEmpty) {
                    return EmptyView(
                      icon: Icons.help_outline_rounded,
                      title: 'Soal Kuis Belum Tersedia',
                      description:
                          'Kuis ini belum memiliki daftar soal yang terkonfigurasi.',
                      actionLabel: 'Kembali',
                      onAction: () => context.pop(),
                    );
                  }

                  final safeIndex = _currentQuestionIndex.clamp(
                    0,
                    questions.length - 1,
                  );
                  final currentQuestion = questions[safeIndex];
                  final selectedOptionId =
                      _selectedAnswers[currentQuestion.id];
                  final isLastQuestion = safeIndex == questions.length - 1;
                  final answeredCount = questions
                      .where((q) => _selectedAnswers.containsKey(q.id))
                      .length;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildMoodboardHeader(
                        quizTitle: quiz.title,
                        currentIndex: safeIndex,
                        totalQuestions: questions.length,
                        questions: questions,
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Banner motivasi maskot Eco
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.mintGreen.withValues(
                                    alpha: 0.65,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppColors.sageGreen,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    SoftImagePlaceholder(
                                      width: 38,
                                      height: 38,
                                      borderRadius: 19,
                                      assetPath:
                                          answeredCount == questions.length
                                              ? 'assets/images/mascot/eco_congrats.png'
                                              : 'assets/images/mascot/eco_happy.png',
                                      backgroundColor: AppColors.surfaceWhite,
                                      fallbackIcon: Icons.eco_rounded,
                                      iconColor: AppColors.forestGreen,
                                      iconSize: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _ecoEncouragementText(
                                          answeredCount: answeredCount,
                                          totalQuestions: questions.length,
                                          currentIndex: safeIndex,
                                        ),
                                        style: AppTextStyles.caption.copyWith(
                                          color: AppColors.forestGreen,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Kartu Pertanyaan & Opsi dengan animasi pergantian halus
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 240),
                                transitionBuilder: (child, animation) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0.03, 0),
                                        end: Offset.zero,
                                      ).animate(animation),
                                      child: child,
                                    ),
                                  );
                                },
                                child: Column(
                                  key: ValueKey<String>(currentQuestion.id),
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(18),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceWhite,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: AppColors.divider,
                                        ),
                                        boxShadow: AppTheme.softCardShadow,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.mintGreen,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    AppTheme.pillRadius,
                                                  ),
                                            ),
                                            child: Text(
                                              'Pertanyaan ${safeIndex + 1} dari ${questions.length}',
                                              style: AppTextStyles.caption
                                                  .copyWith(
                                                    color:
                                                        AppColors.forestGreen,
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 11,
                                                  ),
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            currentQuestion.question,
                                            style: AppTextStyles.display
                                                .copyWith(
                                                  fontSize: 19.5,
                                                  height: 1.35,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ...List.generate(
                                      currentQuestion.options.length,
                                      (optIndex) {
                                        final option =
                                            currentQuestion.options[optIndex];
                                        final isSelected =
                                            selectedOptionId == option.id;
                                        final badgeLetter = option.id
                                            .trim()
                                            .toUpperCase();
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 12,
                                          ),
                                          child: _OptionTile(
                                            badgeLetter: badgeLetter.isEmpty
                                                ? String.fromCharCode(
                                                    65 + optIndex,
                                                  )
                                                : badgeLetter,
                                            option: option,
                                            isSelected: isSelected,
                                            onTap: _isSubmitting
                                                ? null
                                                : () {
                                                    setState(() {
                                                      _selectedAnswers[
                                                          currentQuestion.id] =
                                                          option.id;
                                                    });
                                                  },
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      _buildBottomActions(
                        safeIndex: safeIndex,
                        isLastQuestion: isLastQuestion,
                      ),
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

  Widget _buildMoodboardHeader({
    required String quizTitle,
    required int currentIndex,
    required int totalQuestions,
    required List<QuizQuestion> questions,
  }) {
    final progress = (currentIndex + 1) / totalQuestions;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 20, 10),
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Keluar dari Kuis',
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: AppColors.forestGreen,
                ),
                onPressed: () async {
                  final confirmed = await _confirmExit();
                  if (confirmed && mounted) {
                    context.pop();
                  }
                },
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quizTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.subtitle.copyWith(fontSize: 15),
                    ),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 7,
                        backgroundColor: AppColors.offWhite,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.freshGreen,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (_remainingSeconds != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: (_remainingSeconds ?? 0) <= 30
                        ? AppColors.errorLight
                        : AppColors.mintGreen,
                    borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 14,
                        color: (_remainingSeconds ?? 0) <= 30
                            ? AppColors.errorRed
                            : AppColors.forestGreen,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatTime(_remainingSeconds!),
                        style: AppTextStyles.caption.copyWith(
                          color: (_remainingSeconds ?? 0) <= 30
                              ? AppColors.errorRed
                              : AppColors.forestGreen,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Text(
                  '${currentIndex + 1}/$totalQuestions',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.forestGreen,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // Strip nomor soal interaktif (bisa lompat langsung ke soal mana saja)
          SizedBox(
            height: 32,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: questions.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (context, idx) {
                final q = questions[idx];
                final isCurrent = idx == currentIndex;
                final isAnswered = _selectedAnswers.containsKey(q.id);

                return GestureDetector(
                  onTap: _isSubmitting
                      ? null
                      : () => setState(() => _currentQuestionIndex = idx),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? AppColors.forestGreen
                          : isAnswered
                              ? AppColors.mintGreen
                              : AppColors.offWhite,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isCurrent
                            ? AppColors.forestGreen
                            : isAnswered
                                ? AppColors.freshGreen
                                : AppColors.divider,
                      ),
                    ),
                    child: Text(
                      '${idx + 1}',
                      style: AppTextStyles.caption.copyWith(
                        color: isCurrent
                            ? AppColors.surfaceWhite
                            : AppColors.forestGreen,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions({
    required int safeIndex,
    required bool isLastQuestion,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          if (safeIndex > 0) ...[
            Expanded(
              child: SecondaryButton(
                label: 'Sebelumnya',
                icon: Icons.arrow_back_rounded,
                onPressed: _isSubmitting
                    ? null
                    : () {
                        setState(() => _currentQuestionIndex = safeIndex - 1);
                      },
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isLastQuestion
                      ? AppColors.freshGreen
                      : AppColors.forestGreen,
                  foregroundColor: AppColors.surfaceWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                  ),
                ),
                onPressed: _isSubmitting
                    ? null
                    : () {
                        if (isLastQuestion) {
                          _submitQuiz();
                        } else {
                          setState(
                            () => _currentQuestionIndex = safeIndex + 1,
                          );
                        }
                      },
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.surfaceWhite,
                          ),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isLastQuestion
                                ? 'Kirim & Lihat Skor'
                                : 'Soal Berikutnya',
                            style: AppTextStyles.button,
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            isLastQuestion
                                ? Icons.rocket_launch_rounded
                                : Icons.arrow_forward_rounded,
                            size: 18,
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatTime(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.badgeLetter,
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final String badgeLetter;
  final QuizOption option;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.mintGreen : AppColors.surfaceWhite,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected ? AppColors.freshGreen : AppColors.divider,
              width: isSelected ? 1.8 : 1.0,
            ),
          ),
          child: Row(
            children: [
              AnimatedScale(
                scale: isSelected ? 1.06 : 1.0,
                duration: const Duration(milliseconds: 180),
                child: Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.forestGreen
                        : AppColors.offWhite,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.forestGreen
                          : AppColors.sageGreen,
                      width: 1.4,
                    ),
                  ),
                  child: Text(
                    badgeLetter,
                    style: AppTextStyles.caption.copyWith(
                      color: isSelected
                          ? AppColors.surfaceWhite
                          : AppColors.forestGreen,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  option.text,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.forestGreen,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 8),
                const Icon(
                  Icons.check_circle_rounded,
                  size: 22,
                  color: AppColors.freshGreen,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

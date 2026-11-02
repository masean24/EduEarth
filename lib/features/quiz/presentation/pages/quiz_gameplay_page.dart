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
import '../../../../core/widgets/common/primary_button.dart';
import '../../../../core/widgets/common/secondary_button.dart';
import '../../../../models/quiz.dart';
import '../../../../models/quiz_question.dart';
import '../../../../routes/route_names.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/quiz_providers.dart';

/// Halaman Pengerjaan Kuis (Quiz Gameplay).
///
/// Fitur:
/// - Wajib login.
/// - Menampilkan progres soal, navigasi antar soal, dan indikator terjawab.
/// - Menampilkan timer hitung mundur HANYA bila `quiz.timeLimitSeconds != null`.
/// - Mencegah keluar tidak sengaja dengan `PopScope` + dialog konfirmasi.
/// - Mengirim jawaban ke RPC `submit_quiz_attempt` untuk dinilai di server.
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
          content: Text('Waktu habis! Jawaban Anda sedang dinilai di server...'),
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
            err?.toString() ?? 'Gagal mengirim jawaban kuis. Silakan coba lagi.',
          ),
        ),
      );
    }
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
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Keluar dari Kuis',
            icon: const Icon(Icons.close_rounded),
            onPressed: () async {
              final confirmed = await _confirmExit();
              if (confirmed && context.mounted) {
                context.pop();
              }
            },
          ),
          title: Text(
            quizAsync.asData?.value.title ?? 'Mengerjakan Kuis',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            if (_remainingSeconds != null)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Container(
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
                          size: 16,
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
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
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

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildProgressHeader(
                        currentIndex: safeIndex,
                        totalQuestions: questions.length,
                        answeredCount: _selectedAnswers.length,
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceWhite,
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.cardRadius,
                                  ),
                                  border: Border.all(color: AppColors.divider),
                                ),
                                child: Text(
                                  currentQuestion.question,
                                  style: AppTextStyles.title.copyWith(
                                    height: 1.4,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              ...currentQuestion.options.map((option) {
                                final isSelected =
                                    selectedOptionId == option.id;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _OptionTile(
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
                              }),
                            ],
                          ),
                        ),
                      ),
                      _buildBottomActions(
                        safeIndex: safeIndex,
                        totalQuestions: questions.length,
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

  Widget _buildProgressHeader({
    required int currentIndex,
    required int totalQuestions,
    required int answeredCount,
  }) {
    final progress = (currentIndex + 1) / totalQuestions;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      color: AppColors.surfaceWhite,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Soal ${currentIndex + 1} dari $totalQuestions',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Terjawab: $answeredCount/$totalQuestions',
                style: AppTextStyles.caption,
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.pillRadius),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.mintGreen,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.freshGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions({
    required int safeIndex,
    required int totalQuestions,
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
            child: isLastQuestion
                ? PrimaryButton(
                    label: 'Kirim Jawaban',
                    icon: Icons.check_circle_outline_rounded,
                    isLoading: _isSubmitting,
                    onPressed: () => _submitQuiz(),
                  )
                : PrimaryButton(
                    label: 'Soal Berikutnya',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: _isSubmitting
                        ? null
                        : () {
                            setState(
                              () => _currentQuestionIndex = safeIndex + 1,
                            );
                          },
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
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final QuizOption option;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.mintGreen : AppColors.surfaceWhite,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.freshGreen : AppColors.divider,
              width: isSelected ? 1.8 : 1.0,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.freshGreen
                      : AppColors.offWhite,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.freshGreen
                        : AppColors.sageGreen,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  option.id.toUpperCase(),
                  style: AppTextStyles.caption.copyWith(
                    color: isSelected
                        ? AppColors.surfaceWhite
                        : AppColors.forestGreen,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(
                    option.text,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


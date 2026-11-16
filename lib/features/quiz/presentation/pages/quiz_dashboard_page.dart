import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common/empty_view.dart';
import '../../../../core/widgets/common/error_view.dart';
import '../../../../core/widgets/common/loading_view.dart';
import '../../../../core/widgets/common/primary_button.dart';
import '../../../../models/quiz.dart';
import '../../../../models/quiz_attempt.dart';
import '../../../../routes/route_names.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../learning/domain/learning_integration_helper.dart';
import '../providers/quiz_providers.dart';
import '../widgets/quiz_dashboard_sections.dart';

/// Halaman Utama Kuis (Quiz Dashboard) dalam palet Light Nature Tech.
///
/// Menyajikan kartu ringkasan progres solid forest-green + cincin skor emas,
/// pil filter kategori/status sticky, daftar paket kuis dengan penanda warna
/// kategori, serta akordeon riwayat percobaan per topik dengan badge skor tier.
class QuizDashboardPage extends ConsumerStatefulWidget {
  const QuizDashboardPage({super.key});

  @override
  ConsumerState<QuizDashboardPage> createState() => _QuizDashboardPageState();
}

class _QuizDashboardPageState extends ConsumerState<QuizDashboardPage> {
  String _selectedFilter = 'Semua';

  void _startQuiz(BuildContext context, Quiz quiz) {
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

  void _showScoringInfoDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: QuizLightPalette.cardBg,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: QuizLightPalette.goodBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.verified_user_outlined,
                  color: QuizLightPalette.goodFg,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Info Penilaian Kuis',
                  style: AppTextStyles.subtitle.copyWith(
                    color: QuizLightPalette.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Skor dan kunci jawaban dievaluasi secara aman di sisi server setelah kamu menyelesaikan seluruh soal.',
                style: AppTextStyles.body.copyWith(
                  color: QuizLightPalette.ink,
                  fontSize: 13.5,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 14),
              const QuizScoreTierLegend(),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.push(RouteNames.myLearningPath);
              },
              child: const Text('Progres Belajar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: QuizLightPalette.heroMid,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Mengerti'),
            ),
          ],
        );
      },
    );
  }

  void _handleAttemptTap(
    BuildContext context,
    QuizAttempt attempt,
    QuizAttemptSummary? summary,
  ) {
    final latestResult = ref.read(latestQuizResultProvider)[attempt.quizId];
    if (latestResult != null && latestResult.attemptId == attempt.id) {
      context.push('/quiz/${attempt.quizId}/result', extra: latestResult);
      return;
    }

    _showAttemptDetailSheet(context, attempt, summary);
  }

  void _showAttemptDetailSheet(
    BuildContext context,
    QuizAttempt attempt,
    QuizAttemptSummary? summary,
  ) {
    final tier = quizScoreTierForScore(attempt.score);
    final remedial = LearningIntegrationHelper.remedialInfoForQuiz(attempt.quizId);
    final dateText = formatQuizRelativeTime(attempt.completedAt);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: QuizLightPalette.cardBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: QuizLightPalette.line,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: tier.backgroundColor,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${attempt.score}',
                        style: AppTextStyles.title.copyWith(
                          color: tier.foregroundColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
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
                            style: AppTextStyles.subtitle.copyWith(
                              color: QuizLightPalette.ink,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Benar ${attempt.correctCount} dari ${attempt.totalQuestions} · $dateText (${tier.label})',
                            style: AppTextStyles.caption.copyWith(
                              color: QuizLightPalette.muted,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (summary != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: QuizLightPalette.fieldBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: QuizLightPalette.line),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Rekor terbaik topik ini: ${summary.bestScore}',
                            style: AppTextStyles.caption.copyWith(
                              color: QuizLightPalette.ink,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${summary.attemptCount}× percobaan',
                          style: AppTextStyles.caption.copyWith(
                            color: QuizLightPalette.muted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  'Pembahasan tiap nomor tersedia langsung setelah menyelesaikan sesi kuis dari server. Kamu bisa mengulang kuis atau meninjau modul materi di bawah.',
                  style: AppTextStyles.caption.copyWith(
                    color: QuizLightPalette.muted,
                    fontSize: 12.5,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 48),
                          foregroundColor: QuizLightPalette.goodFg,
                          side: const BorderSide(
                            color: QuizLightPalette.heroBright,
                            width: 1.4,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(sheetContext).pop();
                          context.push(
                            '/learning/material/${remedial.materialSlug}',
                          );
                        },
                        icon: const Icon(Icons.auto_stories_outlined, size: 17),
                        label: const Text('Pelajari Materi'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 48),
                          backgroundColor: QuizLightPalette.heroMid,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(sheetContext).pop();
                          context.push('/quiz/${attempt.quizId}/play');
                        },
                        icon: const Icon(Icons.replay_rounded, size: 17),
                        label: const Text('Ulangi Kuis'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final quizzesAsync = ref.watch(publishedQuizzesProvider);
    final attemptsAsync = ref.watch(userQuizAttemptsProvider);
    final groupedSummariesAsync = ref.watch(quizAttemptsByQuizIdProvider);
    final latestResults = ref.watch(latestQuizResultProvider);
    final isAuthenticated = ref.watch(isAuthenticatedProvider);

    final summariesMap = isAuthenticated
        ? (groupedSummariesAsync.asData?.value ??
            const <String, QuizAttemptSummary>{})
        : const <String, QuizAttemptSummary>{};

    return Scaffold(
      backgroundColor: QuizLightPalette.canvasBg,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: QuizLightPalette.heroMid,
          backgroundColor: QuizLightPalette.cardBg,
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

                final filterOptions = buildQuizFilterOptions(quizzes);
                final effectiveFilter = filterOptions.contains(_selectedFilter)
                    ? _selectedFilter
                    : 'Semua';
                final visibleQuizzes = filterAndSortQuizzes(
                  quizzes: quizzes,
                  summaries: summariesMap,
                  filterKey: effectiveFilter,
                );

                final doneCount = quizzes
                    .where((q) => summariesMap.containsKey(q.id))
                    .length;
                var bestOverall = 0;
                for (final q in quizzes) {
                  final s = summariesMap[q.id];
                  if (s != null) {
                    bestOverall = math.max(bestOverall, s.bestScore);
                  }
                }

                final bottomSafe = MediaQuery.viewPaddingOf(context).bottom;

                return CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildTopHeader(context),
                            const SizedBox(height: 18),
                            QuizProgressSummaryCard(
                              doneCount: isAuthenticated ? doneCount : 0,
                              totalCount: quizzes.length,
                              bestScore: bestOverall,
                              isAuthenticated: isAuthenticated,
                              onLoginTap: () =>
                                  context.push(RouteNames.loginPath),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: QuizFilterChipsHeaderDelegate(
                        options: filterOptions,
                        selectedFilter: effectiveFilter,
                        onSelectFilter: (value) {
                          setState(() => _selectedFilter = value);
                        },
                      ),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        14,
                        20,
                        AppTheme.bottomNavScrollPadding + bottomSafe,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          Text(
                            'Pilih kuis untuk dimulai',
                            style: AppTextStyles.title.copyWith(
                              color: QuizLightPalette.ink,
                              fontSize: 17.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.25,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (visibleQuizzes.isEmpty)
                            _buildFilteredEmptyCard()
                          else
                            ...visibleQuizzes.map((quiz) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: QuizPackageCard(
                                  quiz: quiz,
                                  isAuthenticated: isAuthenticated,
                                  attemptSummary: summariesMap[quiz.id],
                                  onStart: () => _startQuiz(context, quiz),
                                ),
                              );
                            }),
                          const SizedBox(height: 14),
                          Text(
                            'Riwayat percobaan',
                            style: AppTextStyles.title.copyWith(
                              color: QuizLightPalette.ink,
                              fontSize: 17.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.25,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildAttemptsSection(
                            context: context,
                            isAuthenticated: isAuthenticated,
                            attemptsAsync: attemptsAsync,
                            quizzes: quizzes,
                            summariesMap: summariesMap,
                            latestResults: latestResults,
                          ),
                        ]),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );
  }

  Widget _buildTopHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kuis Energi Terbarukan',
                style: AppTextStyles.display.copyWith(
                  color: QuizLightPalette.ink,
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  height: 1.18,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Uji pemahaman konsep pembangkit energi bersih.',
                style: AppTextStyles.caption.copyWith(
                  color: QuizLightPalette.muted,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _HeaderCircleButton(
          tooltip: 'Pencarian Global',
          icon: Icons.search_rounded,
          onTap: () => context.push(RouteNames.searchPath),
        ),
        const SizedBox(width: 8),
        _HeaderCircleButton(
          tooltip: 'Info penilaian kuis',
          icon: Icons.info_outline_rounded,
          onTap: () => _showScoringInfoDialog(context),
        ),
      ],
    );
  }

  Widget _buildFilteredEmptyCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
      decoration: BoxDecoration(
        color: QuizLightPalette.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: QuizLightPalette.line),
      ),
      child: Column(
        children: [
          Text(
            'Belum ada kuis pada filter ini.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: QuizLightPalette.muted,
              fontSize: 13.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => setState(() => _selectedFilter = 'Semua'),
            child: const Text('Tampilkan Semua Kuis'),
          ),
        ],
      ),
    );
  }

  Widget _buildAttemptsSection({
    required BuildContext context,
    required bool isAuthenticated,
    required AsyncValue<List<QuizAttempt>> attemptsAsync,
    required List<Quiz> quizzes,
    required Map<String, QuizAttemptSummary> summariesMap,
    required Map<String, QuizSubmissionResult> latestResults,
  }) {
    if (!isAuthenticated) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: QuizLightPalette.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: QuizLightPalette.line),
        ),
        child: Column(
          children: [
            Text(
              'Masuk ke akun EduEarth untuk menyimpan riwayat percobaan dan melihat ringkasan skor per kuis.',
              style: AppTextStyles.body.copyWith(
                color: QuizLightPalette.muted,
                fontSize: 13.5,
              ),
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
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: QuizLightPalette.cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: QuizLightPalette.line),
            ),
            child: EmptyView(
              icon: Icons.history_edu_rounded,
              title: 'Belum Ada Riwayat Percobaan',
              description:
                  'Kamu belum pernah menyelesaikan kuis. Pilih salah satu kuis di atas untuk mulai berlatih!',
            ),
          );
        }

        final groups = groupQuizAttempts(attempts: attempts, quizzes: quizzes);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const QuizScoreTierLegend(),
            const SizedBox(height: 12),
            ...List.generate(groups.length, (index) {
              final group = groups[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: QuizAttemptGroupCard(
                  group: group,
                  initiallyExpanded: index == 0,
                  hasReviewForAttempt: (attempt) {
                    final latest = latestResults[attempt.quizId];
                    return latest != null && latest.attemptId == attempt.id;
                  },
                  onTapAttempt: (attempt) => _handleAttemptTap(
                    context,
                    attempt,
                    summariesMap[attempt.quizId],
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

class _HeaderCircleButton extends StatelessWidget {
  const _HeaderCircleButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: QuizLightPalette.cardBg,
        shape: const CircleBorder(
          side: BorderSide(color: QuizLightPalette.line),
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, size: 19, color: QuizLightPalette.ink),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/common/category_chip.dart';
import '../../../../models/quiz.dart';
import '../../../../models/quiz_attempt.dart';
import '../providers/quiz_providers.dart';

/// Palet warna halaman kuis EduEarth selaras penuh dengan `AppColors` (Mode Terang).
class QuizLightPalette {
  const QuizLightPalette._();

  static const Color canvasBg = AppColors.offWhite;
  static const Color cardBg = AppColors.surfaceWhite;
  static const Color ink = AppColors.forestGreen;
  static const Color muted = AppColors.textMuted;
  static const Color line = AppColors.divider;
  static const Color fieldBg = AppColors.offWhite;

  static const Color heroDark = AppColors.forestGreen;
  static const Color heroMid = AppColors.actionGreen;
  static const Color heroBright = AppColors.freshGreen;
  static const Color goldAccent = Color(0xFFF2C14E);

  static const Color goodBg = AppColors.mintGreen;
  static const Color goodFg = AppColors.actionGreen;
  static const Color midBg = AppColors.warningBg;
  static const Color midFg = AppColors.warningFg;
  static const Color lowBg = AppColors.errorLight;
  static const Color lowFg = Color(0xFFB4372F);

  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: AppColors.forestGreen.withValues(alpha: 0.05),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];
}

/// Kategori visual & kunci filter chip untuk satu paket kuis.
class QuizCategoryMeta {
  const QuizCategoryMeta({
    required this.filterKey,
    required this.cardLabel,
    required this.accentColor,
  });

  final String filterKey;
  final String cardLabel;
  final Color accentColor;
}

/// Tingkatan skor untuk badge melingkar (`80+`, `40–79`, `<40`).
class QuizScoreTier {
  const QuizScoreTier({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
}

/// Kelompok riwayat percobaan per paket kuis pada akordeon riwayat.
class QuizAttemptGroup {
  const QuizAttemptGroup({
    required this.quizId,
    required this.quizTitle,
    required this.bestScore,
    required this.attempts,
  });

  final String quizId;
  final String quizTitle;
  final int bestScore;
  final List<QuizAttempt> attempts;
}

/// Memetakan metadata kategori kuis ke kunci filter chip dan warna aksen kartu.
QuizCategoryMeta quizCategoryMetaFor(Quiz quiz) {
  final slug = quiz.categorySlug?.toLowerCase().trim();
  switch (slug) {
    case 'solar':
      return QuizCategoryMeta(
        filterKey: 'Surya',
        cardLabel: shortDisplayLabelForSlug(slug, 'Surya'),
        accentColor: const Color(0xFFE9B032),
      );
    case 'geothermal':
      return QuizCategoryMeta(
        filterKey: 'Panas Bumi',
        cardLabel: shortDisplayLabelForSlug(slug, 'Panas Bumi'),
        accentColor: const Color(0xFFEF7D3C),
      );
    case 'hydro':
      return QuizCategoryMeta(
        filterKey: 'Air',
        cardLabel: shortDisplayLabelForSlug(slug, 'Air'),
        accentColor: AppColors.categoryHydro,
      );
    case 'wind':
      return QuizCategoryMeta(
        filterKey: 'Angin',
        cardLabel: shortDisplayLabelForSlug(slug, 'Angin'),
        accentColor: AppColors.categoryWind,
      );
    case 'bioenergy':
      return QuizCategoryMeta(
        filterKey: 'Bioenergi',
        cardLabel: shortDisplayLabelForSlug(slug, 'Bioenergi'),
        accentColor: const Color(0xFF2FA88A),
      );
    default:
      return const QuizCategoryMeta(
        filterKey: 'Lintas',
        cardLabel: 'Lintas Kategori',
        accentColor: QuizLightPalette.heroBright,
      );
  }
}

/// Membangun daftar pil filter dari kuis yang aktif secara dinamis.
List<String> buildQuizFilterOptions(List<Quiz> quizzes) {
  const preferredTopicOrder = <String>[
    'Surya',
    'Air',
    'Angin',
    'Panas Bumi',
    'Bioenergi',
    'Lintas',
  ];

  final presentKeys = quizzes.map((q) => quizCategoryMetaFor(q).filterKey).toSet();
  final orderedTopics = <String>[
    ...preferredTopicOrder.where(presentKeys.contains),
    ...presentKeys.where((k) => !preferredTopicOrder.contains(k)),
  ];

  return <String>['Semua', 'Belum dikerjakan', 'Selesai', ...orderedTopics];
}

/// Menyaring daftar kuis dan mengurutkan kuis yang belum dikerjakan di atas.
List<Quiz> filterAndSortQuizzes({
  required List<Quiz> quizzes,
  required Map<String, QuizAttemptSummary> summaries,
  required String filterKey,
}) {
  final filtered = quizzes.where((quiz) {
    final isDone = summaries.containsKey(quiz.id);
    switch (filterKey) {
      case 'Semua':
        return true;
      case 'Belum dikerjakan':
        return !isDone;
      case 'Selesai':
        return isDone;
      default:
        return quizCategoryMetaFor(quiz).filterKey == filterKey;
    }
  }).toList();

  filtered.sort((a, b) {
    final aDone = summaries.containsKey(a.id) ? 1 : 0;
    final bDone = summaries.containsKey(b.id) ? 1 : 0;
    return aDone.compareTo(bDone);
  });

  return filtered;
}

/// Mengelompokkan daftar `attempts` (diasumsikan terbaru dahulu) berdasarkan `quizId`.
List<QuizAttemptGroup> groupQuizAttempts({
  required List<QuizAttempt> attempts,
  required List<Quiz> quizzes,
}) {
  final titleByQuizId = <String, String>{
    for (final q in quizzes) q.id: q.title,
  };
  final grouped = <String, List<QuizAttempt>>{};

  for (final attempt in attempts) {
    grouped.putIfAbsent(attempt.quizId, () => <QuizAttempt>[]).add(attempt);
  }

  final groups = <QuizAttemptGroup>[];
  grouped.forEach((quizId, list) {
    var best = 0;
    for (final item in list) {
      if (item.score > best) best = item.score;
    }
    final resolvedTitle =
        list.first.quizTitle?.trim().isNotEmpty == true
            ? list.first.quizTitle!.trim()
            : (titleByQuizId[quizId] ?? 'Kuis Energi Terbarukan');

    groups.add(
      QuizAttemptGroup(
        quizId: quizId,
        quizTitle: resolvedTitle,
        bestScore: best,
        attempts: list,
      ),
    );
  });

  return groups;
}

/// Mengembalikan tier warna aksesibel (`>=80`, `40–79`, `<40`).
QuizScoreTier quizScoreTierForScore(int score) {
  if (score >= 80) {
    return const QuizScoreTier(
      label: 'Sangat Baik',
      backgroundColor: QuizLightPalette.goodBg,
      foregroundColor: QuizLightPalette.goodFg,
    );
  }
  if (score >= 40) {
    return const QuizScoreTier(
      label: 'Cukup Baik',
      backgroundColor: QuizLightPalette.midBg,
      foregroundColor: QuizLightPalette.midFg,
    );
  }
  return const QuizScoreTier(
    label: 'Perlu Latihan',
    backgroundColor: QuizLightPalette.lowBg,
    foregroundColor: QuizLightPalette.lowFg,
  );
}

/// Memformat tanggal percobaan kuis secara ringkas dalam bahasa Indonesia.
String formatQuizRelativeTime(DateTime? dateTime, {DateTime? now}) {
  if (dateTime == null) return 'Tercatat';
  final current = (now ?? DateTime.now()).toLocal();
  final target = dateTime.toLocal();
  final today = DateTime(current.year, current.month, current.day);
  final targetDay = DateTime(target.year, target.month, target.day);
  final diffDays = today.difference(targetDay).inDays;

  if (diffDays <= 0) return 'Hari ini';
  if (diffDays == 1) return 'Kemarin';
  if (diffDays < 7) return '$diffDays hari lalu';
  if (diffDays < 30) return '${(diffDays / 7).floor()} minggu lalu';

  final dd = target.day.toString().padLeft(2, '0');
  final mm = target.month.toString().padLeft(2, '0');
  return '$dd/$mm/${target.year}';
}

/// Kartu ringkasan progres kuis solid forest-green dengan cincin progres emas.
class QuizProgressSummaryCard extends StatelessWidget {
  const QuizProgressSummaryCard({
    super.key,
    required this.doneCount,
    required this.totalCount,
    required this.bestScore,
    required this.isAuthenticated,
    this.onLoginTap,
  });

  final int doneCount;
  final int totalCount;
  final int bestScore;
  final bool isAuthenticated;
  final VoidCallback? onLoginTap;

  @override
  Widget build(BuildContext context) {
    final safeTotal = totalCount <= 0 ? 1 : totalCount;
    final progress = (doneCount / safeTotal).clamp(0.0, 1.0);
    final disableAnim = MediaQuery.disableAnimationsOf(context);

    final headline = !isAuthenticated
        ? 'Mode tamu · $totalCount tantangan siap'
        : '$doneCount dari $totalCount kuis selesai';

    final subtitle = !isAuthenticated
        ? 'Masuk untuk mengerjakan kuis, mencatat skor terbaik, dan membuka pembahasan.'
        : doneCount >= totalCount && totalCount > 0
            ? 'Semua paket kuis selesai dikerjakan! Skor terbaikmu $bestScore.'
            : doneCount > 0
                ? 'Skor terbaikmu $bestScore. Lanjut ke kuis berikutnya untuk melengkapi kategori.'
                : 'Pilih paket kuis di bawah untuk menguji pemahamanmu dengan penilaian server.';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: QuizLightPalette.heroDark,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: QuizLightPalette.heroDark.withValues(alpha: 0.16),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 74,
            height: 74,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: progress),
              duration: disableAnim
                  ? Duration.zero
                  : const Duration(milliseconds: 750),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return CustomPaint(
                  painter: _QuizSummaryRingPainter(progress: value),
                  child: Center(
                    child: Text(
                      '$doneCount/$totalCount',
                      style: AppTextStyles.subtitle.copyWith(
                        color: AppColors.surfaceWhite,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  headline,
                  style: AppTextStyles.subtitle.copyWith(
                    color: AppColors.surfaceWhite,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.surfaceWhite.withValues(alpha: 0.88),
                    fontSize: 12.5,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      width: 30,
                      height: 3,
                      decoration: BoxDecoration(
                        color: QuizLightPalette.goldAccent,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    if (!isAuthenticated && onLoginTap != null) ...[
                      const Spacer(),
                      InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: onLoginTap,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceWhite.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: AppColors.surfaceWhite.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Text(
                            'Masuk sekarang',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.surfaceWhite,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuizSummaryRingPainter extends CustomPainter {
  const _QuizSummaryRingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 5;

    final trackPaint = Paint()
      ..color = AppColors.surfaceWhite.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;

    final arcPaint = Paint()
      ..color = QuizLightPalette.goldAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);
    if (progress > 0) {
      const startAngle = -3.141592653589793 / 2;
      final sweepAngle = 2 * 3.141592653589793 * progress;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        arcPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _QuizSummaryRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Delegate header sticky horizontal untuk bar pil filter kuis.
class QuizFilterChipsHeaderDelegate extends SliverPersistentHeaderDelegate {
  const QuizFilterChipsHeaderDelegate({
    required this.options,
    required this.selectedFilter,
    required this.onSelectFilter,
  });

  final List<String> options;
  final String selectedFilter;
  final ValueChanged<String> onSelectFilter;

  @override
  double get minExtent => 56;

  @override
  double get maxExtent => 56;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: QuizLightPalette.canvasBg,
        border: Border(
          bottom: BorderSide(
            color: overlapsContent ? QuizLightPalette.line : Colors.transparent,
          ),
        ),
      ),
      child: ListView.separated(
        key: const ValueKey<String>('quiz_filter_chips_list'),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final label = options[index];
          final isSelected = label == selectedFilter;
          return Semantics(
            button: true,
            selected: isSelected,
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                key: ValueKey<String>('quiz_filter_chip_$label'),
                borderRadius: BorderRadius.circular(999),
                onTap: () => onSelectFilter(label),
                child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? QuizLightPalette.heroMid
                      : QuizLightPalette.cardBg,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isSelected
                        ? QuizLightPalette.heroMid
                        : QuizLightPalette.line,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: QuizLightPalette.heroMid.withValues(
                              alpha: 0.24,
                            ),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: isSelected
                        ? AppColors.surfaceWhite
                        : QuizLightPalette.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            ),
          );
        },
      ),
    );
  }

  @override
  bool shouldRebuild(covariant QuizFilterChipsHeaderDelegate oldDelegate) {
    return oldDelegate.selectedFilter != selectedFilter ||
        oldDelegate.options.length != options.length;
  }
}

/// Kartu paket kuis beraksen garis vertikal kiri dan indikator kesulitan 3 titik.
class QuizPackageCard extends StatelessWidget {
  const QuizPackageCard({
    super.key,
    required this.quiz,
    required this.isAuthenticated,
    required this.onStart,
    this.attemptSummary,
  });

  final Quiz quiz;
  final bool isAuthenticated;
  final QuizAttemptSummary? attemptSummary;
  final VoidCallback onStart;

  int get _difficultyLevel {
    switch (quiz.difficulty.toLowerCase()) {
      case 'advanced':
        return 3;
      case 'intermediate':
        return 2;
      default:
        return 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryMeta = quizCategoryMetaFor(quiz);
    final isCompleted = attemptSummary != null;

    return Container(
      decoration: BoxDecoration(
        color: QuizLightPalette.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: QuizLightPalette.line),
        boxShadow: QuizLightPalette.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(23),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 18,
              bottom: 18,
              width: 4,
              child: Container(
                decoration: BoxDecoration(
                  color: categoryMeta.accentColor,
                  borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(4),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          categoryMeta.cardLabel,
                          style: AppTextStyles.caption.copyWith(
                            color: QuizLightPalette.muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (isCompleted)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_rounded,
                              size: 15,
                              color: QuizLightPalette.goodFg,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Selesai',
                              style: AppTextStyles.caption.copyWith(
                                color: QuizLightPalette.goodFg,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        )
                      else if (quiz.isDraft)
                        Text(
                          'Draf Review',
                          style: AppTextStyles.caption.copyWith(
                            color: QuizLightPalette.midFg,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      else
                        Text(
                          'Baru',
                          style: AppTextStyles.caption.copyWith(
                            color: QuizLightPalette.muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    quiz.title,
                    style: AppTextStyles.title.copyWith(
                      color: QuizLightPalette.ink,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      height: 1.28,
                      letterSpacing: -0.25,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    quiz.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body.copyWith(
                      color: QuizLightPalette.muted,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 14,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ...List.generate(3, (dotIndex) {
                            final active = dotIndex < _difficultyLevel;
                            return Container(
                              width: 6,
                              height: 6,
                              margin: EdgeInsets.only(
                                right: dotIndex < 2 ? 3 : 6,
                              ),
                              decoration: BoxDecoration(
                                color: active
                                    ? QuizLightPalette.heroBright
                                    : QuizLightPalette.line,
                                shape: BoxShape.circle,
                              ),
                            );
                          }),
                          Text(
                            quiz.difficultyLabel,
                            style: AppTextStyles.caption.copyWith(
                              color: QuizLightPalette.muted,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        quiz.timeLimitLabel,
                        style: AppTextStyles.caption.copyWith(
                          color: QuizLightPalette.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  if (attemptSummary != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
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
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  'Skor terbaik',
                                  style: AppTextStyles.caption.copyWith(
                                    color: QuizLightPalette.muted,
                                    fontSize: 12.5,
                                  ),
                                ),
                                Text(
                                  '${attemptSummary!.bestScore}',
                                  style: AppTextStyles.subtitle.copyWith(
                                    color: QuizLightPalette.ink,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  '·',
                                  style: AppTextStyles.caption.copyWith(
                                    color: QuizLightPalette.muted,
                                  ),
                                ),
                                Text(
                                  '${attemptSummary!.attemptCount}× coba',
                                  style: AppTextStyles.caption.copyWith(
                                    color: QuizLightPalette.muted,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (attemptSummary!.hasMultipleAttempts) ...[
                            const SizedBox(width: 8),
                            _ScoreDeltaChip(delta: attemptSummary!.scoreDelta),
                          ],
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  _QuizCardActionButton(
                    isCompleted: isCompleted,
                    isAuthenticated: isAuthenticated,
                    onTap: onStart,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreDeltaChip extends StatelessWidget {
  const _ScoreDeltaChip({required this.delta});

  final int delta;

  @override
  Widget build(BuildContext context) {
    final isPositive = delta >= 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isPositive ? QuizLightPalette.goodBg : QuizLightPalette.midBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '${isPositive ? '+' : ''}$delta poin',
        style: AppTextStyles.caption.copyWith(
          color: isPositive ? QuizLightPalette.goodFg : QuizLightPalette.midFg,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _QuizCardActionButton extends StatelessWidget {
  const _QuizCardActionButton({
    required this.isCompleted,
    required this.isAuthenticated,
    required this.onTap,
  });

  final bool isCompleted;
  final bool isAuthenticated;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final usePrimaryGradient = isAuthenticated && !isCompleted;
    final label = !isAuthenticated
        ? 'Masuk untuk mulai kuis'
        : isCompleted
            ? 'Ulangi kuis'
            : 'Mulai kuis';
    final icon = !isAuthenticated
        ? Icons.login_rounded
        : isCompleted
            ? Icons.replay_rounded
            : Icons.play_arrow_rounded;

    if (usePrimaryGradient) {
      return Material(
        color: QuizLightPalette.heroMid,
        borderRadius: BorderRadius.circular(16),
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: SizedBox(
            height: 50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 19, color: AppColors.surfaceWhite),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: AppTextStyles.button.copyWith(
                    color: AppColors.surfaceWhite,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Material(
      color: QuizLightPalette.cardBg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: QuizLightPalette.heroBright,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: QuizLightPalette.goodFg),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTextStyles.button.copyWith(
                  color: QuizLightPalette.goodFg,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Legenda tingkatan warna skor (`80+`, `40–79`, `di bawah 40`).
class QuizScoreTierLegend extends StatelessWidget {
  const QuizScoreTierLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 6,
      children: const [
        _LegendDot(color: QuizLightPalette.goodFg, label: '80+'),
        _LegendDot(color: QuizLightPalette.midFg, label: '40–79'),
        _LegendDot(color: QuizLightPalette.lowFg, label: 'di bawah 40'),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: QuizLightPalette.muted,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Akordeon riwayat percobaan per kuis dengan badge skor melingkar 44dp.
class QuizAttemptGroupCard extends StatefulWidget {
  const QuizAttemptGroupCard({
    super.key,
    required this.group,
    required this.initiallyExpanded,
    required this.hasReviewForAttempt,
    required this.onTapAttempt,
  });

  final QuizAttemptGroup group;
  final bool initiallyExpanded;
  final bool Function(QuizAttempt attempt) hasReviewForAttempt;
  final ValueChanged<QuizAttempt> onTapAttempt;

  @override
  State<QuizAttemptGroupCard> createState() => _QuizAttemptGroupCardState();
}

class _QuizAttemptGroupCardState extends State<QuizAttemptGroupCard> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final group = widget.group;

    return Container(
      decoration: BoxDecoration(
        color: QuizLightPalette.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: QuizLightPalette.line),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group.quizTitle,
                            style: AppTextStyles.subtitle.copyWith(
                              color: QuizLightPalette.ink,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${group.attempts.length} percobaan · terbaik ${group.bestScore}',
                            style: AppTextStyles.caption.copyWith(
                              color: QuizLightPalette.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0.0,
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : const Duration(milliseconds: 220),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 20,
                        color: QuizLightPalette.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_isExpanded)
              ...group.attempts.map((attempt) {
                final tier = quizScoreTierForScore(attempt.score);
                final hasReview = widget.hasReviewForAttempt(attempt);
                final dateLabel = formatQuizRelativeTime(attempt.completedAt);

                return InkWell(
                  onTap: () => widget.onTapAttempt(attempt),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 11,
                    ),
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: QuizLightPalette.line),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: tier.backgroundColor,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${attempt.score}',
                            style: AppTextStyles.subtitle.copyWith(
                              color: tier.foregroundColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Benar ${attempt.correctCount} dari ${attempt.totalQuestions}',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: QuizLightPalette.ink,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                dateLabel,
                                style: AppTextStyles.caption.copyWith(
                                  color: QuizLightPalette.muted,
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          hasReview ? 'Pembahasan' : 'Detail',
                          style: AppTextStyles.caption.copyWith(
                            color: QuizLightPalette.goodFg,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

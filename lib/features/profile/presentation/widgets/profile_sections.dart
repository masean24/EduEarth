import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common/soft_image_placeholder.dart';
import '../../../../models/achievement.dart';
import '../../../../models/learning_material.dart';
import '../../../../models/quiz.dart';
import '../../../../routes/route_names.dart';
import '../../../achievement/presentation/widgets/achievement_unlock_dialog.dart';
import '../../../learning/presentation/providers/reading_progress_provider.dart';
import '../../../quiz/presentation/providers/quiz_providers.dart';

/// Palet warna mode terang halaman profil yang selaras dengan `AppColors`.
class ProfileLightPalette {
  const ProfileLightPalette._();

  static const Color canvasBg = AppColors.offWhite;
  static const Color cardBg = AppColors.surfaceWhite;
  static const Color ink = AppColors.forestGreen;
  static const Color muted = AppColors.textMuted;
  static const Color line = AppColors.divider;

  static const Color heroSolid = AppColors.forestGreen;
  static const Color goldAccent = Color(0xFFF2C14E);
  static const Color goldSurface = Color(0xFFF7D56A);
  static const Color goldBorder = Color(0xFFD99B26);

  static const Color dangerFg = Color(0xFFB4372F);
  static const Color dangerBg = Color(0xFFFDE3E0);
  static const Color dangerBorder = Color(0xFFF0C4C0);
}

/// Target rekomendasi kontekstual untuk kartu "Lanjutkan belajar" di halaman profil.
class ProfileContinueTarget {
  const ProfileContinueTarget({
    required this.overline,
    required this.title,
    required this.routePath,
    required this.icon,
  });

  final String overline;
  final String title;
  final String routePath;
  final IconData icon;
}

/// Item konfigurasi tile 2x2 pada seksi "Belajar & progres".
class ProfileQuickTileData {
  const ProfileQuickTileData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.onTap,
    this.badgeCount = 0,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final VoidCallback onTap;
  final int badgeCount;
}

/// Item baris pada kartu menu "Akun & pengaturan".
class ProfileMenuRowData {
  const ProfileMenuRowData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
}

/// Menentukan gelar penjelajah berdasarkan jumlah badge yang sudah dibuka.
String computeProfileExplorerRankLabel(int unlockedBadges) {
  if (unlockedBadges >= 9) return '🏆 Master EduEarth';
  if (unlockedBadges >= 5) return '⚡ Ahli Transisi Nusantara';
  if (unlockedBadges >= 2) return '🌿 Duta Energi Bersih';
  return '🌱 Penjelajah Energi';
}

/// Menghitung total poin maksimal dari seluruh badge yang tersedia di katalog.
int computeTotalPossibleBadgePoints(List<Achievement> achievements) {
  var total = 0;
  for (final item in achievements) {
    total += item.points;
  }
  return total;
}

/// Menentukan target "Lanjutkan belajar" paling relevan dari progres nyata pengguna.
ProfileContinueTarget resolveProfileContinueTarget({
  required List<LearningMaterial> materials,
  required ReadingProgressState readingState,
  required List<Quiz> quizzes,
  required Map<String, QuizAttemptSummary> quizSummaries,
}) {
  // 1. Prioritaskan materi terakhir yang sedang dibaca (< 85% selesai)
  final lastSlug = readingState.lastReadSlug;
  if (lastSlug != null && lastSlug.isNotEmpty) {
    final progress = readingState.progressFor(lastSlug);
    if (progress > 0.02 && progress < 0.85) {
      for (final material in materials) {
        if (material.slug == lastSlug) {
          return ProfileContinueTarget(
            overline: 'Lanjutkan membaca (${(progress * 100).round()}%)',
            title: material.title,
            routePath: '/learning/material/${material.slug}',
            icon: Icons.menu_book_rounded,
          );
        }
      }
    }
  }

  for (final material in materials) {
    final progress = readingState.progressFor(material.slug);
    if (progress > 0.02 && progress < 0.85) {
      return ProfileContinueTarget(
        overline: 'Lanjutkan membaca (${(progress * 100).round()}%)',
        title: material.title,
        routePath: '/learning/material/${material.slug}',
        icon: Icons.menu_book_rounded,
      );
    }
  }

  // 2. Kuis berikutnya yang belum pernah dikerjakan
  for (final quiz in quizzes) {
    if (!quizSummaries.containsKey(quiz.id)) {
      return ProfileContinueTarget(
        overline: 'Lanjutkan belajar',
        title: '${quiz.title} belum dikerjakan',
        routePath: '/quiz/${quiz.id}/play',
        icon: Icons.play_arrow_rounded,
      );
    }
  }

  // 3. Materi yang belum dibuka sama sekali
  for (final material in materials) {
    if (readingState.progressFor(material.slug) <= 0.02) {
      return ProfileContinueTarget(
        overline: 'Mulai eksplorasi materi',
        title: material.title,
        routePath: '/learning/material/${material.slug}',
        icon: Icons.auto_stories_rounded,
      );
    }
  }

  // 4. Seluruh modul dan kuis telah dituntaskan
  return const ProfileContinueTarget(
    overline: 'Ringkasan aktivitas belajarmu',
    title: 'Lihat Progres Belajar & Skor',
    routePath: RouteNames.myLearningPath,
    icon: Icons.trending_up_rounded,
  );
}

/// Kartu Hero profil modern dengan avatar, level poin, dan 4 statistik interaktif.
class ProfileHeroCard extends StatelessWidget {
  const ProfileHeroCard({
    super.key,
    required this.displayName,
    required this.email,
    required this.avatarUrl,
    required this.rankLabel,
    required this.earnedPoints,
    required this.maxPoints,
    required this.bookmarkCount,
    required this.quizAttemptCount,
    required this.readMaterialsCount,
    required this.badgeCount,
    required this.onEditProfileTap,
    required this.onBookmarksTap,
    required this.onAttemptsTap,
    required this.onReadMaterialsTap,
    required this.onBadgesTap,
  });

  final String displayName;
  final String email;
  final String avatarUrl;
  final String rankLabel;
  final int earnedPoints;
  final int maxPoints;
  final int bookmarkCount;
  final int quizAttemptCount;
  final int readMaterialsCount;
  final int badgeCount;
  final VoidCallback onEditProfileTap;
  final VoidCallback onBookmarksTap;
  final VoidCallback onAttemptsTap;
  final VoidCallback onReadMaterialsTap;
  final VoidCallback onBadgesTap;

  @override
  Widget build(BuildContext context) {
    final safeMax = maxPoints > 0 ? maxPoints : 1;
    final progress = maxPoints > 0
        ? (earnedPoints / safeMax).clamp(0.0, 1.0)
        : 0.0;
    final pointsText = maxPoints > 0
        ? '$earnedPoints / $maxPoints poin'
        : '$earnedPoints poin';
    final disableAnim = MediaQuery.disableAnimationsOf(context);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: ProfileLightPalette.heroSolid,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: ProfileLightPalette.heroSolid.withValues(alpha: 0.18),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -34,
            top: -34,
            child: Container(
              width: 136,
              height: 136,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    _ProfileAvatarWithEditButton(
                      avatarUrl: avatarUrl,
                      onEditTap: onEditProfileTap,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.display.copyWith(
                              color: AppColors.surfaceWhite,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.35,
                              height: 1.15,
                            ),
                          ),
                          if (email.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.surfaceWhite.withValues(
                                  alpha: 0.82,
                                ),
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                          const SizedBox(height: 9),
                          Container(
                            width: 30,
                            height: 3,
                            decoration: BoxDecoration(
                              color: ProfileLightPalette.goldAccent,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        rankLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.surfaceWhite,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      pointsText,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.surfaceWhite.withValues(alpha: 0.84),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 8,
                    color: AppColors.surfaceWhite.withValues(alpha: 0.22),
                    alignment: Alignment.centerLeft,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: progress),
                      duration: disableAnim
                          ? Duration.zero
                          : const Duration(milliseconds: 700),
                      curve: Curves.easeOutCubic,
                      builder: (context, val, _) {
                        return FractionallySizedBox(
                          widthFactor: val,
                          child: Container(
                            decoration: BoxDecoration(
                              color: ProfileLightPalette.goldAccent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: ProfileLightPalette.cardBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IntrinsicHeight(
                    child: Row(
                      children: [
                        Expanded(
                          child: _ProfileStatCell(
                            value: '$bookmarkCount',
                            label: 'Tersimpan',
                            onTap: onBookmarksTap,
                          ),
                        ),
                        const VerticalDivider(
                          width: 1,
                          thickness: 1,
                          indent: 4,
                          endIndent: 4,
                          color: ProfileLightPalette.line,
                        ),
                        Expanded(
                          child: _ProfileStatCell(
                            value: '$quizAttemptCount',
                            label: 'Percobaan',
                            onTap: onAttemptsTap,
                          ),
                        ),
                        const VerticalDivider(
                          width: 1,
                          thickness: 1,
                          indent: 4,
                          endIndent: 4,
                          color: ProfileLightPalette.line,
                        ),
                        Expanded(
                          child: _ProfileStatCell(
                            value: '$readMaterialsCount',
                            label: 'Dibaca',
                            onTap: onReadMaterialsTap,
                          ),
                        ),
                        const VerticalDivider(
                          width: 1,
                          thickness: 1,
                          indent: 4,
                          endIndent: 4,
                          color: ProfileLightPalette.line,
                        ),
                        Expanded(
                          child: _ProfileStatCell(
                            value: '$badgeCount',
                            label: 'Badge',
                            onTap: onBadgesTap,
                          ),
                        ),
                      ],
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

class _ProfileAvatarWithEditButton extends StatelessWidget {
  const _ProfileAvatarWithEditButton({
    required this.avatarUrl,
    required this.onEditTap,
  });

  final String avatarUrl;
  final VoidCallback onEditTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 78,
      height: 78,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 76,
            height: 76,
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.mintGreen,
              border: Border.all(
                color: AppColors.surfaceWhite.withValues(alpha: 0.92),
                width: 2.5,
              ),
            ),
            child: SoftImagePlaceholder(
              width: 68,
              height: 68,
              borderRadius: 34,
              networkImageUrl: avatarUrl,
              assetPath: 'assets/images/mascot/eco_happy.png',
              backgroundColor: AppColors.mintGreen,
              fallbackIcon: Icons.person_rounded,
              iconColor: AppColors.forestGreen,
              iconSize: 34,
            ),
          ),
          Positioned(
            right: -4,
            bottom: -4,
            child: Semantics(
              button: true,
              label: 'Ubah profil dan foto avatar',
              child: Tooltip(
                message: 'Ubah avatar & nama',
                child: InkResponse(
                  onTap: onEditTap,
                  radius: 22,
                  child: SizedBox(
                    width: 36,
                    height: 36,
                    child: Center(
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceWhite,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: ProfileLightPalette.heroSolid,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.edit_outlined,
                          size: 13,
                          color: AppColors.actionGreen,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileStatCell extends StatelessWidget {
  const _ProfileStatCell({
    required this.value,
    required this.label,
    required this.onTap,
  });

  final String value;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: AppTextStyles.display.copyWith(
                  color: ProfileLightPalette.ink,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(
                color: ProfileLightPalette.muted,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kartu aksi cepat "Lanjutkan belajar" tepat di bawah kartu hero profil.
class ProfileContinueBannerCard extends StatelessWidget {
  const ProfileContinueBannerCard({
    super.key,
    required this.target,
    required this.onTap,
  });

  final ProfileContinueTarget target;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ProfileLightPalette.cardBg,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: ProfileLightPalette.cardBg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: ProfileLightPalette.line),
            boxShadow: AppTheme.softCardShadow,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.actionGreen,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  target.icon,
                  color: AppColors.surfaceWhite,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      target.overline,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: ProfileLightPalette.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      target.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.subtitle.copyWith(
                        color: ProfileLightPalette.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.15,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.actionGreen,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Etalase lencana horizontal dengan gaya medali emas vs lingkaran gembok terkunci.
class ProfileBadgeShowcaseSection extends StatelessWidget {
  const ProfileBadgeShowcaseSection({
    super.key,
    required this.achievements,
    required this.unlockedCount,
    required this.onSeeAllTap,
    required this.onUnlockedTap,
    required this.onLockedTap,
  });

  final List<Achievement> achievements;
  final int unlockedCount;
  final VoidCallback onSeeAllTap;
  final ValueChanged<Achievement> onUnlockedTap;
  final ValueChanged<Achievement> onLockedTap;

  @override
  Widget build(BuildContext context) {
    final totalCount = achievements.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Etalase lencana',
                      style: AppTextStyles.subtitle.copyWith(
                        color: ProfileLightPalette.ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.25,
                      ),
                    ),
                    Text(
                      '$unlockedCount/$totalCount terbuka',
                      style: AppTextStyles.caption.copyWith(
                        color: ProfileLightPalette.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: onSeeAllTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  child: Text(
                    'Semua →',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.actionGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: achievements.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = achievements[index];
              final isUnlocked = item.isUnlocked;

              return Semantics(
                button: true,
                label: isUnlocked
                    ? 'Lencana ${item.title} sudah diraih'
                    : 'Lencana ${item.title} masih terkunci',
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => isUnlocked ? onUnlockedTap(item) : onLockedTap(item),
                  child: SizedBox(
                    width: 78,
                    child: Column(
                      children: [
                        _BadgeMedalCircle(
                          iconData: iconForAchievementCode(item.icon),
                          isUnlocked: isUnlocked,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 11,
                            height: 1.25,
                            fontWeight: FontWeight.w600,
                            color: isUnlocked
                                ? ProfileLightPalette.ink
                                : ProfileLightPalette.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _BadgeMedalCircle extends StatelessWidget {
  const _BadgeMedalCircle({
    required this.iconData,
    required this.isUnlocked,
  });

  final IconData iconData;
  final bool isUnlocked;

  @override
  Widget build(BuildContext context) {
    if (isUnlocked) {
      return Container(
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: ProfileLightPalette.goldSurface,
          border: Border.all(
            color: ProfileLightPalette.goldBorder,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: ProfileLightPalette.goldAccent.withValues(alpha: 0.32),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Icon(
          iconData,
          size: 27,
          color: ProfileLightPalette.ink,
        ),
      );
    }

    return SizedBox(
      width: 62,
      height: 62,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CustomPaint(
            painter: const _DashedCirclePainter(
              color: AppColors.sageGreen,
              strokeWidth: 1.4,
            ),
            child: Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ProfileLightPalette.cardBg.withValues(alpha: 0.85),
              ),
              child: Icon(
                iconData,
                size: 25,
                color: ProfileLightPalette.muted.withValues(alpha: 0.45),
              ),
            ),
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ProfileLightPalette.cardBg,
                border: Border.all(color: ProfileLightPalette.line),
              ),
              child: const Icon(
                Icons.lock_rounded,
                size: 12,
                color: ProfileLightPalette.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  const _DashedCirclePainter({
    required this.color,
    required this.strokeWidth,
  });

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: (size.width / 2) - strokeWidth,
    );

    const dashCount = 20;
    const sweepStep = (2 * math.pi) / dashCount;
    const dashSweep = sweepStep * 0.56;

    for (var i = 0; i < dashCount; i++) {
      canvas.drawArc(rect, i * sweepStep, dashSweep, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}

/// Grid 2x2 seksi "Belajar & progres" dengan tinggi seimbang tiap baris.
class ProfileQuickTilesGrid extends StatelessWidget {
  const ProfileQuickTilesGrid({
    super.key,
    required this.tiles,
  });

  final List<ProfileQuickTileData> tiles;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < tiles.length; i += 2) {
      final first = tiles[i];
      final second = (i + 1 < tiles.length) ? tiles[i + 1] : null;
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _QuickBentoTile(data: first)),
              const SizedBox(width: 12),
              Expanded(
                child: second != null
                    ? _QuickBentoTile(data: second)
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
      if (i + 2 < tiles.length) {
        rows.add(const SizedBox(height: 12));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }
}

class _QuickBentoTile extends StatelessWidget {
  const _QuickBentoTile({required this.data});

  final ProfileQuickTileData data;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ProfileLightPalette.cardBg,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: data.onTap,
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ProfileLightPalette.cardBg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: ProfileLightPalette.line),
            boxShadow: AppTheme.softCardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: data.iconBackground,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      data.icon,
                      color: data.iconColor,
                      size: 21,
                    ),
                  ),
                  if (data.badgeCount > 0) ...[
                    const SizedBox(width: 6),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.mintGreen,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${data.badgeCount} baru',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.actionGreen,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Text(
                data.title,
                style: AppTextStyles.subtitle.copyWith(
                  color: ProfileLightPalette.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.15,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                data.subtitle,
                style: AppTextStyles.caption.copyWith(
                  color: ProfileLightPalette.muted,
                  fontSize: 11.5,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kartu grup menu rapi untuk "Akun & pengaturan".
class ProfileSettingsMenuGroup extends StatelessWidget {
  const ProfileSettingsMenuGroup({
    super.key,
    required this.rows,
  });

  final List<ProfileMenuRowData> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ProfileLightPalette.cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: ProfileLightPalette.line),
        boxShadow: AppTheme.softCardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(21),
        child: Column(
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0)
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: ProfileLightPalette.line,
                ),
              _ProfileMenuRow(data: rows[i]),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProfileMenuRow extends StatelessWidget {
  const _ProfileMenuRow({required this.data});

  final ProfileMenuRowData data;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: data.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.mintGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                data.icon,
                color: AppColors.actionGreen,
                size: 19,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    style: AppTextStyles.subtitle.copyWith(
                      color: ProfileLightPalette.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    data.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      color: ProfileLightPalette.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: ProfileLightPalette.muted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

/// Tombol keluar akun bergaya outline coral lembut + dialog konfirmasi aman.
class ProfileSignOutButton extends StatelessWidget {
  const ProfileSignOutButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ProfileLightPalette.cardBg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: isLoading ? null : onPressed,
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: ProfileLightPalette.dangerBorder,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: ProfileLightPalette.dangerFg,
                  ),
                )
              else
                const Icon(
                  Icons.logout_rounded,
                  size: 19,
                  color: ProfileLightPalette.dangerFg,
                ),
              const SizedBox(width: 9),
              Text(
                isLoading ? 'Sedang keluar...' : 'Keluar akun',
                style: AppTextStyles.button.copyWith(
                  color: ProfileLightPalette.dangerFg,
                  fontSize: 14,
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

/// Menampilkan dialog konfirmasi sebelum pengguna keluar dari akun.
Future<bool> showProfileSignOutConfirmDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: ProfileLightPalette.cardBg,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Text(
          'Keluar dari akun?',
          style: AppTextStyles.title.copyWith(
            color: ProfileLightPalette.ink,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          'Progres belajar dan skor kuismu tetap tersimpan. Kamu bisa masuk lagi kapan saja.',
          style: AppTextStyles.body.copyWith(
            color: ProfileLightPalette.muted,
            fontSize: 13.5,
            height: 1.5,
          ),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    foregroundColor: ProfileLightPalette.ink,
                    side: const BorderSide(
                      color: ProfileLightPalette.line,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Batal'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    backgroundColor: ProfileLightPalette.dangerFg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Ya, keluar'),
                ),
              ),
            ],
          ),
        ],
      );
    },
  );
  return result ?? false;
}

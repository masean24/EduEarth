import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common/primary_button.dart';
import '../../../../core/widgets/common/soft_image_placeholder.dart';
import '../../../../models/achievement.dart';

/// Helper terpusat untuk memetakan nama ikon achievement dari database ke `IconData`.
IconData iconForAchievementCode(String iconName) {
  switch (iconName.toLowerCase().trim()) {
    case 'bookmark_added_rounded':
      return Icons.bookmark_added_rounded;
    case 'menu_book_rounded':
      return Icons.menu_book_rounded;
    case 'auto_stories_rounded':
      return Icons.auto_stories_rounded;
    case 'map_rounded':
      return Icons.map_rounded;
    case 'explore_rounded':
      return Icons.explore_rounded;
    case 'stars_rounded':
      return Icons.stars_rounded;
    case 'quiz_rounded':
      return Icons.quiz_rounded;
    case 'bolt_rounded':
      return Icons.bolt_rounded;
    case 'military_tech_rounded':
      return Icons.military_tech_rounded;
    case 'workspace_premium_rounded':
      return Icons.workspace_premium_rounded;
    case 'school_rounded':
      return Icons.school_rounded;
    case 'emoji_events_rounded':
    default:
      return Icons.emoji_events_rounded;
  }
}

/// Menampilkan dialog animasi perayaan ketika pengguna membuka badge baru
/// (atau ketika mengetuk badge yang sudah terbuka untuk melihat detailnya).
Future<void> showAchievementUnlockDialog(
  BuildContext context, {
  required List<String> badgeTitles,
  Achievement? singleAchievement,
  bool isReplay = false,
}) async {
  if (badgeTitles.isEmpty && singleAchievement == null) return;

  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Tutup Dialog Badge',
    barrierColor: Colors.black.withValues(alpha: 0.55),
    transitionDuration: const Duration(milliseconds: 340),
    pageBuilder: (dialogContext, _, _) {
      return Center(
        child: _AchievementUnlockModalContent(
          badgeTitles: badgeTitles,
          singleAchievement: singleAchievement,
          isReplay: isReplay,
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
      );
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.82, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class _AchievementUnlockModalContent extends StatefulWidget {
  const _AchievementUnlockModalContent({
    required this.badgeTitles,
    this.singleAchievement,
    required this.isReplay,
  });

  final List<String> badgeTitles;
  final Achievement? singleAchievement;
  final bool isReplay;

  @override
  State<_AchievementUnlockModalContent> createState() =>
      _AchievementUnlockModalContentState();
}

class _AchievementUnlockModalContentState
    extends State<_AchievementUnlockModalContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sparkleController;

  @override
  void initState() {
    super.initState();
    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _sparkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ach = widget.singleAchievement;
    final titles = widget.badgeTitles.isNotEmpty
        ? widget.badgeTitles
        : (ach != null ? <String>[ach.title] : const <String>[]);

    return Material(
      color: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.65),
              width: 1.8,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                  border: Border.all(color: const Color(0xFFF59E0B)),
                ),
                child: Text(
                  widget.isReplay
                      ? '🏆 LENCANA TERBUKA'
                      : '🎉 PENCAPAIAN BARU TERBUKA!',
                  style: AppTextStyles.caption.copyWith(
                    color: const Color(0xFFB45309),
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Panggung animasi kilau + lencana emas + maskot Eco
              SizedBox(
                height: 132,
                child: AnimatedBuilder(
                  animation: _sparkleController,
                  builder: (context, _) {
                    final t = _sparkleController.value;
                    final angle = t * 2 * math.pi;
                    final pulse = 0.96 + (0.06 * math.sin(angle * 2));

                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // Lingkaran sinar berputar halus
                        Transform.rotate(
                          angle: angle,
                          child: Container(
                            width: 124,
                            height: 124,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: SweepGradient(
                                colors: [
                                  const Color(0xFFFDE047).withValues(
                                    alpha: 0.35,
                                  ),
                                  AppColors.mintGreen.withValues(alpha: 0.15),
                                  const Color(0xFFFDE047).withValues(
                                    alpha: 0.35,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Partikel bintang sudut
                        Positioned(
                          top: 6,
                          left: 44,
                          child: Transform.scale(
                            scale: pulse,
                            child: const Icon(
                              Icons.auto_awesome_rounded,
                              color: Color(0xFFF59E0B),
                              size: 20,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 10,
                          right: 40,
                          child: Transform.scale(
                            scale: 1.92 - pulse,
                            child: const Icon(
                              Icons.auto_awesome_rounded,
                              color: AppColors.freshGreen,
                              size: 18,
                            ),
                          ),
                        ),
                        // Medali utama
                        Transform.scale(
                          scale: pulse,
                          child: Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFFFDE047),
                                  Color(0xFFF59E0B),
                                  Color(0xFFD97706),
                                ],
                              ),
                              border: Border.all(
                                color: AppColors.surfaceWhite,
                                width: 3.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFF59E0B).withValues(
                                    alpha: 0.35,
                                  ),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Icon(
                              ach != null
                                  ? iconForAchievementCode(ach.icon)
                                  : Icons.emoji_events_rounded,
                              color: AppColors.surfaceWhite,
                              size: 42,
                            ),
                          ),
                        ),
                        // Maskot Eco merayakan di pojok kanan bawah medali
                        const Positioned(
                          right: 54,
                          bottom: 0,
                          child: SoftImagePlaceholder(
                            width: 46,
                            height: 46,
                            borderRadius: 23,
                            assetPath: 'assets/images/mascot/eco_congrats.png',
                            backgroundColor: AppColors.surfaceWhite,
                            fallbackIcon: Icons.celebration_rounded,
                            iconColor: AppColors.forestGreen,
                            iconSize: 22,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Text(
                titles.join(' & '),
                style: AppTextStyles.display.copyWith(
                  fontSize: 20,
                  height: 1.25,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                ach?.description ??
                    'Selamat! Kamu baru saja membuka lencana pencapaian baru atas dedikasi belajarmu di EduEarth.',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 13.5,
                  height: 1.45,
                ),
                textAlign: TextAlign.center,
              ),
              if (ach != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.mintGreen,
                    borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                  ),
                  child: Text(
                    '+${ach.points} Poin Eksplorasi ⚡',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.forestGreen,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              PrimaryButton(
                label: 'Keren! Lanjutkan',
                icon: Icons.check_circle_outline_rounded,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


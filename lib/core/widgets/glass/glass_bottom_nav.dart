import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import 'glass_container.dart';

/// Item konfigurasi untuk satu tab pada `GlassBottomNav`.
class GlassBottomNavItem {
  const GlassBottomNavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
}

/// Navigasi bawah 5 tab berbasis `GlassContainer` (Liquid Glass / Glassmorphism)
/// dengan satu indikator lembut:
/// - Tab aktif: pill `AppColors.mintGreen` semi-transparan di belakang ikon + label,
///   dengan warna ikon dan teks `AppColors.forestGreen`.
/// - Tab tidak aktif: tanpa latar belakang, warna ikon dan teks `AppColors.textMuted`.
/// - Efek blur `22.0` dan tint transparan `0.58` agar latar di belakangnya terbiaskan
///   secara nyata, dan otomatis jatuh ke permukaan solid saat "Kurangi efek glass" aktif.
class GlassBottomNav extends StatelessWidget {
  const GlassBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.items = defaultTabs,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<GlassBottomNavItem> items;

  static const List<GlassBottomNavItem> defaultTabs = <GlassBottomNavItem>[
    GlassBottomNavItem(
      label: 'Home',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
    ),
    GlassBottomNavItem(
      label: 'Explore',
      icon: Icons.explore_outlined,
      activeIcon: Icons.explore_rounded,
    ),
    GlassBottomNavItem(
      label: 'Learn',
      icon: Icons.menu_book_outlined,
      activeIcon: Icons.menu_book_rounded,
    ),
    GlassBottomNavItem(
      label: 'Quiz',
      icon: Icons.quiz_outlined,
      activeIcon: Icons.quiz_rounded,
    ),
    GlassBottomNavItem(
      label: 'Profile',
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.bottomNavHorizontalMargin,
          0,
          AppTheme.bottomNavHorizontalMargin,
          AppTheme.bottomNavBottomMargin,
        ),
        child: SizedBox(
          height: AppTheme.bottomNavHeight,
          child: GlassContainer(
            borderRadius: 30,
            blur: 14,
            tintOpacity: 0.62,
            borderOpacity: 0.65,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: List.generate(items.length, (index) {
                final item = items[index];
                final isSelected = index == currentIndex;

                return Expanded(
                  child: Semantics(
                    selected: isSelected,
                    button: true,
                    label: 'Tab ${item.label}',
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(
                          AppTheme.pillRadius,
                        ),
                        onTap: () => onTap(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutCubic,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.mintGreen.withValues(alpha: 0.82)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(
                              AppTheme.pillRadius,
                            ),
                            border: isSelected
                                ? Border.all(
                                    color: AppColors.sageGreen.withValues(
                                      alpha: 0.55,
                                    ),
                                    width: 1,
                                  )
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isSelected ? item.activeIcon : item.icon,
                                size: 22,
                                color: isSelected
                                    ? AppColors.forestGreen
                                    : AppColors.textMuted,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.caption.copyWith(
                                  fontSize: 11,
                                  height: 1.1,
                                  color: isSelected
                                      ? AppColors.forestGreen
                                      : AppColors.textMuted,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

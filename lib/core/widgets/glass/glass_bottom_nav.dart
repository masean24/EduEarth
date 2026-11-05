import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import 'glass_container.dart';

/// Item konfigurasi untuk satu tab pada `GlassBottomNav`.
class GlassBottomNavItem {
  const GlassBottomNavItem({
    required this.branchIndex,
    required this.label,
    required this.icon,
    required this.activeIcon,
    this.isCenterDocked = false,
  });

  /// Indeks branch pada `StatefulShellRoute` (`0=Home, 1=Explore, 2=Learn, 3=Quiz, 4=Profile`).
  final int branchIndex;
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final bool isCenterDocked;
}

/// Navigasi bawah 5 tab bergaya kapsul modern dengan tombol **Home** di tengah
/// (`Explore | Learn | Home (Center) | Quiz | Profile`).
///
/// Dirancang proporsional untuk layar mobile:
/// - Bar kapsul memiliki tinggi 64 dp dengan sudut membulat lembut.
/// - Tombol **Home** di tengah memiliki lingkaran hijau berbingkai putih yang
///   menonjol halus (12 dp di atas kapsul) agar elegan dan tidak menutupi konten.
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
      branchIndex: 1,
      label: 'Explore',
      icon: Icons.explore_outlined,
      activeIcon: Icons.explore_rounded,
    ),
    GlassBottomNavItem(
      branchIndex: 2,
      label: 'Learn',
      icon: Icons.menu_book_outlined,
      activeIcon: Icons.menu_book_rounded,
    ),
    GlassBottomNavItem(
      branchIndex: 0,
      label: 'Home',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      isCenterDocked: true,
    ),
    GlassBottomNavItem(
      branchIndex: 3,
      label: 'Quiz',
      icon: Icons.help_outline_rounded,
      activeIcon: Icons.help_rounded,
    ),
    GlassBottomNavItem(
      branchIndex: 4,
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
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              // Kapsul latar belakang utama (tinggi 64 dp)
              SizedBox(
                height: 64,
                child: GlassContainer(
                  borderRadius: 32,
                  blur: 16,
                  tintOpacity: 0.90,
                  borderOpacity: 0.75,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: items.map((item) {
                      if (item.isCenterDocked) {
                        // Ruang tengah untuk label "Home" (ikon lingkaran ada di layer atas Stack)
                        final isHomeSelected = currentIndex == item.branchIndex;
                        return Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => onTap(item.branchIndex),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  item.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.caption.copyWith(
                                    fontSize: 11.5,
                                    height: 1.1,
                                    color: isHomeSelected
                                        ? AppColors.forestGreen
                                        : const Color(0xFF7B8D9E),
                                    fontWeight: isHomeSelected
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 3),
                              ],
                            ),
                          ),
                        );
                      }

                      final isSelected = currentIndex == item.branchIndex;
                      return Expanded(
                        child: Semantics(
                          selected: isSelected,
                          button: true,
                          label: 'Tab ${item.label}',
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(22),
                              onTap: () => onTap(item.branchIndex),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOutCubic,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.mintGreen.withValues(
                                          alpha: 0.72,
                                        )
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(22),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AnimatedScale(
                                      scale: isSelected ? 1.08 : 1.0,
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      curve: Curves.easeOutBack,
                                      child: Icon(
                                        isSelected
                                            ? item.activeIcon
                                            : item.icon,
                                        size: 22,
                                        color: isSelected
                                            ? AppColors.forestGreen
                                            : const Color(0xFF7B8D9E),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      item.label,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyles.caption.copyWith(
                                        fontSize: 11,
                                        height: 1.1,
                                        color: isSelected
                                            ? AppColors.forestGreen
                                            : const Color(0xFF7B8D9E),
                                        fontWeight: isSelected
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // Tombol bulat Home di tengah (menonjol proporsional 12 dp di atas kapsul)
              Positioned(
                top: 2,
                child: _buildCenterHomeButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenterHomeButton() {
    final centerItem = items.firstWhere(
      (item) => item.isCenterDocked,
      orElse: () => defaultTabs[2],
    );
    final isSelected = currentIndex == centerItem.branchIndex;

    return Semantics(
      selected: isSelected,
      button: true,
      label: 'Tab ${centerItem.label}',
      child: GestureDetector(
        onTap: () => onTap(centerItem.branchIndex),
        child: AnimatedScale(
          scale: isSelected ? 1.04 : 0.96,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutBack,
          child: Container(
            padding: const EdgeInsets.all(3.5),
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? AppColors.freshGreen.withValues(alpha: 0.28)
                      : AppColors.forestGreen.withValues(alpha: 0.10),
                  blurRadius: isSelected ? 14 : 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isSelected
                      ? const [
                          AppColors.forestGreen,
                          Color(0xFF1E7E48),
                          AppColors.freshGreen,
                        ]
                      : [
                          AppColors.forestGreen.withValues(alpha: 0.85),
                          AppColors.freshGreen.withValues(alpha: 0.85),
                        ],
                ),
              ),
              child: Icon(
                isSelected ? centerItem.activeIcon : centerItem.icon,
                color: AppColors.surfaceWhite,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

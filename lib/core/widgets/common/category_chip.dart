import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import '../glass/glass_container.dart';

/// Helper pemetaan ikon Material berdasarkan `slug` kategori energi.
IconData iconForCategorySlug(String? slug) {
  switch (slug?.toLowerCase().trim()) {
    case 'solar':
      return Icons.wb_sunny_rounded;
    case 'hydro':
      return Icons.water_drop_rounded;
    case 'wind':
      return Icons.air_rounded;
    case 'geothermal':
      return Icons.thermostat_rounded;
    case 'bioenergy':
      return Icons.eco_rounded;
    default:
      return Icons.bolt_rounded;
  }
}

/// Chip filter kategori energi yang mendukung mode standar maupun mode Liquid Glass
/// (dipakai di atas peta Explore Map).
class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.categorySlug,
    this.useGlass = false,
  });

  final String label;
  final String? categorySlug;
  final bool isSelected;
  final VoidCallback onTap;
  final bool useGlass;

  @override
  Widget build(BuildContext context) {
    final accentColor = categorySlug != null
        ? AppColors.colorForCategorySlug(categorySlug!)
        : AppColors.freshGreen;

    final chipContent = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          categorySlug != null
              ? iconForCategorySlug(categorySlug)
              : Icons.layers_rounded,
          size: 16,
          color: isSelected ? AppColors.forestGreen : accentColor,
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.forestGreen,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );

    if (useGlass && !isSelected) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: GlassContainer(
          borderRadius: AppTheme.pillRadius,
          blur: 14,
          tintOpacity: 0.72,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: chipContent,
        ),
      );
    }

    return Material(
      color: isSelected ? AppColors.mintGreen : AppColors.surfaceWhite,
      borderRadius: BorderRadius.circular(AppTheme.pillRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.pillRadius),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.pillRadius),
            border: Border.all(
              color: isSelected ? accentColor : AppColors.divider,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: chipContent,
        ),
      ),
    );
  }
}


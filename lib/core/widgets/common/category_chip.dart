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
      return Icons.local_fire_department_rounded;
    case 'bioenergy':
      return Icons.eco_rounded;
    default:
      return Icons.bolt_rounded;
  }
}

/// Helper path slot aset ilustrasi kategori sesuai `docs/design/ASSETS.md`.
String assetForCategorySlug(String? slug) {
  switch (slug?.toLowerCase().trim()) {
    case 'solar':
      return 'assets/images/illustrations/cat_solar.png';
    case 'hydro':
      return 'assets/images/illustrations/cat_hydro.png';
    case 'wind':
      return 'assets/images/illustrations/cat_wind.png';
    case 'geothermal':
      return 'assets/images/illustrations/cat_geothermal.png';
    case 'bioenergy':
      return 'assets/images/illustrations/cat_bioenergy.png';
    default:
      return '';
  }
}

/// Label singkat kategori energi terpusat sesuai gaya `moodboard.png`
/// (Surya, Air, Angin, Panas Bumi, Bioenergi).
String shortDisplayLabelForSlug(
  String? slug, [
  String fallbackName = 'Energi Bersih',
]) {
  switch (slug?.toLowerCase().trim()) {
    case 'solar':
      return 'Surya';
    case 'hydro':
      return 'Air';
    case 'wind':
      return 'Angin';
    case 'geothermal':
      return 'Panas Bumi';
    case 'bioenergy':
      return 'Bioenergi';
    default:
      return fallbackName;
  }
}

/// Label lengkap kategori energi dalam Bahasa Indonesia secara terpusat
/// (Energi Surya, Energi Air, Energi Angin, Energi Panas Bumi, Bioenergi).
String fullDisplayLabelForSlug(
  String? slug, {
  String? shortCode,
  String fallbackName = 'Energi Terbarukan',
}) {
  String base;
  String defaultCode;
  switch (slug?.toLowerCase().trim()) {
    case 'solar':
      base = 'Energi Surya';
      defaultCode = 'PLTS';
      break;
    case 'hydro':
      base = 'Energi Air';
      defaultCode = 'PLTA';
      break;
    case 'wind':
      base = 'Energi Angin';
      defaultCode = 'PLTB';
      break;
    case 'geothermal':
      base = 'Energi Panas Bumi';
      defaultCode = 'PLTP';
      break;
    case 'bioenergy':
      base = 'Bioenergi';
      defaultCode = 'PLTBm/PLTBg';
      break;
    default:
      return fallbackName;
  }
  final effectiveCode =
      (shortCode != null && shortCode.trim().isNotEmpty) ? shortCode : defaultCode;
  return '$base ($effectiveCode)';
}

/// Chip filter kategori energi bergaya moodboard:
/// - Saat terpilih (`isSelected == true`): pill hijau tua solid (`forestGreen`) dengan teks putih.
/// - Saat tidak terpilih: `GlassContainer` (jika `useGlass == true` di atas peta) atau pill putih bersih.
class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.categorySlug,
    this.useGlass = false,
    this.showIcon = false,
  });

  final String label;
  final String? categorySlug;
  final bool isSelected;
  final VoidCallback onTap;
  final bool useGlass;
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    final accentColor = categorySlug != null
        ? AppColors.colorForCategorySlug(categorySlug!)
        : AppColors.freshGreen;

    final chipContent = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showIcon) ...[
          Icon(
            categorySlug != null
                ? iconForCategorySlug(categorySlug)
                : Icons.layers_rounded,
            size: 15,
            color: isSelected ? AppColors.surfaceWhite : accentColor,
          ),
          const SizedBox(width: 6),
        ],
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: isSelected ? AppColors.surfaceWhite : AppColors.forestGreen,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );

    if (isSelected) {
      return Material(
        color: AppColors.forestGreen,
        borderRadius: BorderRadius.circular(AppTheme.pillRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.pillRadius),
          child: Container(
            padding: AppTheme.chipPadding,
            alignment: Alignment.center,
            child: chipContent,
          ),
        ),
      );
    }

    if (useGlass) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: GlassContainer(
          borderRadius: AppTheme.pillRadius,
          blur: 14,
          tintOpacity: 0.72,
          padding: AppTheme.chipPadding,
          child: Center(child: chipContent),
        ),
      );
    }

    return Material(
      color: AppColors.surfaceWhite,
      borderRadius: BorderRadius.circular(AppTheme.pillRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.pillRadius),
        child: Container(
          padding: AppTheme.chipPadding,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.pillRadius),
            border: Border.all(
              color: AppColors.divider,
              width: AppTheme.cardBorderWidth,
            ),
            boxShadow: AppTheme.softCardShadow,
          ),
          child: chipContent,
        ),
      ),
    );
  }
}

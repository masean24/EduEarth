import 'package:flutter/material.dart';

import '../../../models/learning_material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import 'category_chip.dart';
import 'soft_image_placeholder.dart';

/// Kartu materi pembelajaran bergambar sesuai gaya `docs/design/moodboard.png`.
///
/// Menampilkan kotak ilustrasi/gambar lembut di sisi kiri, judul & ringkasan
/// di tengah, serta indikator panah di sisi kanan.
class MaterialCard extends StatelessWidget {
  const MaterialCard({
    super.key,
    required this.material,
    required this.onTap,
    this.readingProgress,
  });

  final LearningMaterial material;
  final VoidCallback onTap;

  /// Progres baca persisten (`0.0` s.d. `1.0`). Jika > 0.02, ditampilkan sebagai badge progres.
  final double? readingProgress;

  ({String label, IconData icon, Color color}) _topicBadgeForMaterial() {
    switch (material.slug.trim().toLowerCase()) {
      case 'transisi-energi-dan-dampak-lingkungan':
        return (
          label: 'Transisi & Dampak',
          icon: Icons.eco_rounded,
          color: AppColors.forestGreen,
        );
      case 'baseload-vs-intermiten-vre':
        return (
          label: 'Baseload vs VRE',
          icon: Icons.timeline_rounded,
          color: const Color(0xFF0284C7),
        );
      case 'teknologi-penyimpanan-energi-bess-pumped-storage':
        return (
          label: 'BESS & Pumped Storage',
          icon: Icons.battery_charging_full_rounded,
          color: const Color(0xFFD97706),
        );
      case 'smart-grid-dan-elektrifikasi-kepulauan':
        return (
          label: 'Smart Grid Kepulauan',
          icon: Icons.hub_rounded,
          color: const Color(0xFF0D9488),
        );
      default:
        final catSlug = material.categorySlug ?? '';
        return (
          label: shortDisplayLabelForSlug(catSlug, 'Energi Bersih'),
          icon: iconForCategorySlug(catSlug),
          color: catSlug == 'solar'
              ? const Color(0xFFD97706)
              : AppColors.forestGreen,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final slug = material.categorySlug ?? '';
    final softBg = AppColors.softBackgroundForCategorySlug(slug);
    final accentColor = AppColors.colorForCategorySlug(slug);
    final topicBadge = _topicBadgeForMaterial();
    final hasProgress = readingProgress != null && readingProgress! > 0.02;
    final clampedProgress = (readingProgress ?? 0.0).clamp(0.0, 1.0);

    return DecoratedBox(
      decoration: AppTheme.cardDecoration(),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          child: Padding(
            padding: AppTheme.cardPaddingCompact,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SoftImagePlaceholder(
                      width: 74,
                      height: 74,
                      borderRadius: 16,
                      networkImageUrl: material.coverImageUrl,
                      assetPath: assetForCategorySlug(slug),
                      backgroundColor: softBg,
                      fallbackIcon: topicBadge.icon,
                      iconColor: slug == 'solar'
                          ? const Color(0xFFD97706)
                          : accentColor == AppColors.freshGreen
                              ? AppColors.forestGreen
                              : accentColor,
                      iconSize: 34,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2.5,
                                ),
                                decoration: BoxDecoration(
                                  color: topicBadge.color.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.pillRadius,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      topicBadge.icon,
                                      size: 12,
                                      color: topicBadge.color,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      topicBadge.label,
                                      style: AppTextStyles.caption.copyWith(
                                        color: topicBadge.color,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 10.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (material.isDraft)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.warmYellow.withValues(
                                      alpha: 0.25,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.pillRadius,
                                    ),
                                    border: Border.all(
                                      color: AppColors.warmYellow,
                                    ),
                                  ),
                                  child: Text(
                                    'DRAF REVIEW',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.forestGreen,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            material.title,
                            style: AppTextStyles.subtitle.copyWith(
                              fontSize: 15.5,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            material.summary,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.35,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.schedule_rounded,
                                    size: 13,
                                    color: AppColors.textMuted,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${material.readMinutes} mnt • ${material.difficultyLabel}',
                                    style: AppTextStyles.caption.copyWith(
                                      fontSize: 11,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                              if (hasProgress)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: clampedProgress >= 0.95
                                        ? AppColors.mintGreen
                                        : AppColors.offWhite,
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.pillRadius,
                                    ),
                                    border: Border.all(
                                      color: clampedProgress >= 0.95
                                          ? AppColors.freshGreen
                                          : AppColors.divider,
                                    ),
                                  ),
                                  child: Text(
                                    clampedProgress >= 0.95
                                        ? 'Selesai ✓'
                                        : '${(clampedProgress * 100).round()}% dibaca',
                                    style: AppTextStyles.caption.copyWith(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.forestGreen,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
                if (hasProgress) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                    child: LinearProgressIndicator(
                      value: clampedProgress,
                      minHeight: 4,
                      backgroundColor: AppColors.offWhite,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        clampedProgress >= 0.95
                            ? AppColors.forestGreen
                            : AppColors.freshGreen,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

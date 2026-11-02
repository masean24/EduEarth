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
  });

  final LearningMaterial material;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final slug = material.categorySlug ?? '';
    final softBg = AppColors.softBackgroundForCategorySlug(slug);
    final accentColor = AppColors.colorForCategorySlug(slug);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SoftImagePlaceholder(
                width: 72,
                height: 72,
                borderRadius: 16,
                networkImageUrl: material.coverImageUrl,
                assetPath: assetForCategorySlug(slug),
                backgroundColor: softBg,
                fallbackIcon: iconForCategorySlug(slug),
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
                    if (material.isDraft) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warmYellow.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(
                            AppTheme.pillRadius,
                          ),
                          border: Border.all(color: AppColors.warmYellow),
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
                    Text(
                      material.title,
                      style: AppTextStyles.subtitle.copyWith(fontSize: 16),
                      maxLines: 1,
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
                    Row(
                      children: [
                        Icon(
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
        ),
      ),
    );
  }
}

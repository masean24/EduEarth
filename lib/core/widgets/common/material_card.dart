import 'package:flutter/material.dart';

import '../../../models/learning_material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import 'category_chip.dart';

/// Kartu materi pembelajaran reusable untuk Learning Dashboard, Energy Category,
/// dan halaman Bookmark.
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
    final categoryColor = AppColors.colorForCategorySlug(
      material.categorySlug ?? '',
    );

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: categoryColor.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                      border: Border.all(color: categoryColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          iconForCategorySlug(material.categorySlug),
                          size: 14,
                          color: AppColors.forestGreen,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          material.categoryShortCode ??
                              material.categoryName ??
                              'Materi Energi',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.forestGreen,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (material.isDraft) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
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
                  const Spacer(),
                  Icon(
                    Icons.schedule_rounded,
                    size: 14,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${material.readMinutes} mnt baca',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                material.title,
                style: AppTextStyles.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                material.summary,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.mintGreen,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Tingkat: ${material.difficultyLabel}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.forestGreen,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Baca selengkapnya',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.freshGreen,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: AppColors.freshGreen,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

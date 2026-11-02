import 'package:flutter/material.dart';

import '../../../models/power_plant.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import 'category_chip.dart';
import 'soft_image_placeholder.dart';

/// Kartu pembangkit energi reusable untuk Home, Nearby Plants, dan Search.
///
/// Menambahkan lencana jelas `DATA DEMO` bila `plant.isDemo == true`.
/// Mendukung mode banner bergambar (`isFeaturedBanner: true`) sesuai gaya
/// "Rekomendasi Pembangkit" pada `docs/design/moodboard.png`.
class PlantCard extends StatelessWidget {
  const PlantCard({
    super.key,
    required this.plant,
    required this.onTap,
    this.isFeaturedBanner = false,
  });

  final PowerPlant plant;
  final VoidCallback onTap;
  final bool isFeaturedBanner;

  @override
  Widget build(BuildContext context) {
    if (isFeaturedBanner) {
      return _buildFeaturedBannerCard();
    }

    final slug = plant.categorySlug ?? '';
    final softBg = AppColors.softBackgroundForCategorySlug(slug);
    final categoryColor = AppColors.colorForCategorySlug(slug);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              SoftImagePlaceholder(
                width: 68,
                height: 68,
                borderRadius: 16,
                networkImageUrl: plant.imageUrl,
                assetPath: assetForCategorySlug(slug),
                backgroundColor: softBg,
                fallbackIcon: iconForCategorySlug(slug),
                iconColor: AppColors.forestGreen,
                iconSize: 30,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: categoryColor.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(
                              AppTheme.pillRadius,
                            ),
                          ),
                          child: Text(
                            plant.categoryShortCode ??
                                plant.categoryName ??
                                'Energi Bersih',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.forestGreen,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        if (plant.isDemo) ...[
                          const SizedBox(width: 6),
                          _buildDemoBadge(),
                        ],
                        const Spacer(),
                        if (plant.distanceMeters != null)
                          Text(
                            _formatDistance(plant.distanceMeters!),
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.forestGreen,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      plant.name,
                      style: AppTextStyles.subtitle.copyWith(fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _buildSubtitleText(),
                      style: AppTextStyles.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: AppColors.offWhite,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: AppColors.forestGreen,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedBannerCard() {
    final slug = plant.categorySlug ?? '';
    final softBg = AppColors.softBackgroundForCategorySlug(slug);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 168,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Latar gambar / placeholder lembut
              SoftImagePlaceholder(
                borderRadius: 0,
                networkImageUrl: plant.imageUrl,
                assetPath: assetForCategorySlug(slug),
                backgroundColor: softBg,
                fallbackIcon: iconForCategorySlug(slug),
                iconColor: AppColors.forestGreen.withValues(alpha: 0.35),
                iconSize: 64,
              ),
              // Overlay gradasi gelap di bagian bawah untuk keterbacaan teks
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.forestGreen.withValues(alpha: 0.08),
                      AppColors.forestGreen.withValues(alpha: 0.86),
                    ],
                  ),
                ),
              ),
              // Badge DATA DEMO di pojok kiri atas (jika demo)
              if (plant.isDemo)
                Positioned(
                  top: 12,
                  left: 12,
                  child: _buildDemoBadge(),
                ),
              // Konten bawah sesuai moodboard
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                        color: AppColors.forestGreen,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        iconForCategorySlug(slug),
                        color: AppColors.mintGreen,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            plant.name,
                            style: AppTextStyles.subtitle.copyWith(
                              color: AppColors.surfaceWhite,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _buildSubtitleText(),
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.mintGreen,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceWhite.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                        color: AppColors.forestGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDemoBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.warmYellow,
        borderRadius: BorderRadius.circular(AppTheme.pillRadius),
      ),
      child: Text(
        'DATA DEMO',
        style: AppTextStyles.caption.copyWith(
          color: AppColors.forestGreen,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }

  String _buildSubtitleText() {
    final cap = plant.capacityMw != null
        ? ' • ${plant.capacityMw!.toStringAsFixed(1)} MW'
        : '';
    return '${plant.province}$cap';
  }

  static String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    }
    final km = meters / 1000.0;
    return '${km.toStringAsFixed(1)} km';
  }
}

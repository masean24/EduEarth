import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common/category_chip.dart';
import '../../../../core/widgets/common/primary_button.dart';
import '../../../../core/widgets/common/secondary_button.dart';
import '../../../../core/widgets/glass/glass_container.dart';
import '../../../../models/power_plant.dart';
import '../../../../services/external_map_service.dart';

/// Bottom sheet pratinjau pembangkit (Plant Preview) dengan efek iOS Liquid Glass
/// saat pengguna mengetuk marker di atas peta Explore Map.
class PlantPreviewSheet extends StatelessWidget {
  const PlantPreviewSheet({
    super.key,
    required this.plant,
    required this.externalMapService,
  });

  final PowerPlant plant;
  final ExternalMapService externalMapService;

  static Future<void> show({
    required BuildContext context,
    required PowerPlant plant,
    required ExternalMapService externalMapService,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PlantPreviewSheet(
        plant: plant,
        externalMapService: externalMapService,
      ),
    );
  }

  Future<void> _openGoogleMaps(BuildContext context) async {
    final launched = await externalMapService.openInGoogleMaps(
      latitude: plant.latitude,
      longitude: plant.longitude,
      label: plant.name,
    );

    if (!context.mounted) return;
    if (!launched) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tidak dapat membuka Google Maps di perangkat ini.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = AppColors.colorForCategorySlug(
      plant.categorySlug ?? '',
    );

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: GlassContainer(
          borderRadius: AppTheme.bottomSheetRadius,
          blur: 18,
          tintOpacity: 0.85,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.sageGreen,
                    borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: categoryColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                      border: Border.all(color: categoryColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          iconForCategorySlug(plant.categorySlug),
                          size: 15,
                          color: AppColors.forestGreen,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${plant.categoryName ?? 'Energi Terbarukan'} (${plant.categoryShortCode ?? '-'})',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.forestGreen,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (plant.isDemo) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warmYellow.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(
                          AppTheme.pillRadius,
                        ),
                        border: Border.all(color: AppColors.warmYellow),
                      ),
                      child: Text(
                        'DATA DEMO',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.forestGreen,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Text(plant.name, style: AppTextStyles.title),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      plant.locationLabel,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                plant.description,
                style: AppTextStyles.body,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MetaPill(
                    icon: Icons.bolt_rounded,
                    label: plant.capacityMw != null
                        ? 'Kapasitas: ${plant.capacityMw!.toStringAsFixed(1)} MW'
                        : 'Kapasitas: Belum tercatat',
                  ),
                  _MetaPill(
                    icon: Icons.info_outline_rounded,
                    label: 'Status: ${plant.operationalStatusLabel}',
                  ),
                ],
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Lihat Detail Pembangkit',
                icon: Icons.arrow_forward_rounded,
                onPressed: () {
                  Navigator.of(context).pop();
                  context.push('/plants/${plant.id}');
                },
              ),
              const SizedBox(height: 10),
              SecondaryButton(
                label: 'Buka di Google Maps',
                icon: Icons.open_in_new_rounded,
                onPressed: () => _openGoogleMaps(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.forestGreen),
          const SizedBox(width: 6),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}


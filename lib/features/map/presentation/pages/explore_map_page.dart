import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common/category_chip.dart';
import '../../../../core/widgets/common/empty_view.dart';
import '../../../../core/widgets/common/error_view.dart';
import '../../../../core/widgets/common/loading_view.dart';
import '../../../../core/widgets/glass/glass_container.dart';
import '../../../../models/energy_category.dart';
import '../../../../models/power_plant.dart';
import '../../../../routes/route_names.dart';
import '../../../../services/external_map_service.dart';
import '../../../plants/presentation/providers/plants_providers.dart';
import '../../../plants/presentation/widgets/plant_preview_sheet.dart';

/// Halaman Peta Eksplorasi Pembangkit (Explore Map) menggunakan `flutter_map`
/// dan tile OpenStreetMap.
///
/// Dilengkapi filter chip Liquid Glass per kategori energi, marker dengan warna
/// sesuai `AppColors.colorForCategorySlug`, bottom sheet `PlantPreviewSheet`,
/// dan atribusi resmi "© OpenStreetMap contributors".
class ExploreMapPage extends ConsumerStatefulWidget {
  const ExploreMapPage({super.key});

  @override
  ConsumerState<ExploreMapPage> createState() => _ExploreMapPageState();
}

class _ExploreMapPageState extends ConsumerState<ExploreMapPage> {
  final MapController _mapController = MapController();

  // Koordinat tengah kepulauan Indonesia sebagai posisi awal peta
  static const LatLng _indonesiaCenter = LatLng(-2.5489, 118.0149);
  static const double _defaultZoom = 4.6;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _resetCamera() {
    _mapController.move(_indonesiaCenter, _defaultZoom);
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(energyCategoriesProvider);
    final plantsAsync = ref.watch(filteredPlantsListProvider);
    final selectedSlug = ref.watch(selectedCategoryFilterProvider);
    final externalMapService = ref.watch(externalMapServiceProvider);

    return Scaffold(
      body: Stack(
        children: [
          // 1. Peta OpenStreetMap
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: _indonesiaCenter,
              initialZoom: _defaultZoom,
              minZoom: 3.5,
              maxZoom: 18.0,
            ),
            children: [
              TileLayer(
                urlTemplate: AppConstants.osmTileUrl,
                userAgentPackageName: AppConstants.appPackageName,
              ),
              if (plantsAsync.asData != null)
                MarkerLayer(
                  markers: plantsAsync.asData!.value.map((plant) {
                    return _buildPlantMarker(
                      context: context,
                      plant: plant,
                      externalMapService: externalMapService,
                    );
                  }).toList(),
                ),
            ],
          ),

          // 2. Header & Filter Chips (Glass Effect)
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: GlassContainer(
                    borderRadius: AppTheme.cardRadius,
                    blur: 16,
                    tintOpacity: 0.78,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.public_rounded,
                          color: AppColors.forestGreen,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Peta Pembangkit Energi',
                                style: AppTextStyles.subtitle,
                              ),
                              Text(
                                'Ketuk marker untuk melihat pratinjau pembangkit',
                                style: AppTextStyles.caption,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Pembangkit Terdekat',
                          onPressed: () =>
                              context.push(RouteNames.nearbyPlantsPath),
                          icon: const Icon(
                            Icons.near_me_rounded,
                            color: AppColors.forestGreen,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Reset Posisi Peta',
                          onPressed: _resetCamera,
                          icon: const Icon(
                            Icons.my_location_rounded,
                            color: AppColors.forestGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _buildCategoryFilterBar(categoriesAsync, selectedSlug),
              ],
            ),
          ),

          // 3. State Overlay (Loading / Error / Empty)
          plantsAsync.when(
            loading: () => Positioned.fill(
              child: Container(
                color: AppColors.offWhite.withValues(alpha: 0.75),
                child: const LoadingView(
                  message: 'Memuat titik pembangkit di peta...',
                ),
              ),
            ),
            error: (error, _) => Positioned.fill(
              child: Container(
                color: AppColors.offWhite.withValues(alpha: 0.9),
                child: ErrorView(
                  message: error.toString(),
                  onRetry: () {
                    ref.invalidate(allPlantsListProvider);
                    ref.invalidate(filteredPlantsListProvider);
                  },
                ),
              ),
            ),
            data: (plants) {
              if (plants.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: GlassContainer(
                      tintOpacity: 0.9,
                      child: EmptyView(
                        icon: Icons.location_off_outlined,
                        title: 'Tidak Ada Pembangkit pada Filter Ini',
                        description:
                            'Belum ada data pembangkit terpublikasi untuk kategori yang dipilih.',
                        actionLabel: 'Tampilkan Semua Kategori',
                        onAction: () {
                          ref
                              .read(selectedCategoryFilterProvider.notifier)
                              .selectCategory(null);
                        },
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // 4. Atribusi Resmi OpenStreetMap + Lencana Jumlah Titik di atas BottomNav
          Positioned(
            left: 16,
            right: 16,
            bottom: 92,
            child: SafeArea(
              top: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (plantsAsync.asData != null)
                    GlassContainer(
                      borderRadius: AppTheme.pillRadius,
                      blur: 12,
                      tintOpacity: 0.8,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Text(
                        '${plantsAsync.asData!.value.length} titik ditampilkan',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.forestGreen,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  GestureDetector(
                    onTap: () {
                      externalMapService.openExternalUrl(
                        'https://www.openstreetmap.org/copyright',
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceWhite.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Text(
                        AppConstants.osmAttribution,
                        style: AppTextStyles.caption.copyWith(fontSize: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilterBar(
    AsyncValue<List<EnergyCategory>> categoriesAsync,
    String? selectedSlug,
  ) {
    final categories = categoriesAsync.asData?.value ?? const <EnergyCategory>[];

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          CategoryChip(
            label: 'Semua',
            isSelected: selectedSlug == null,
            useGlass: true,
            onTap: () {
              ref
                  .read(selectedCategoryFilterProvider.notifier)
                  .selectCategory(null);
            },
          ),
          const SizedBox(width: 8),
          ...categories.map((cat) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: CategoryChip(
                label: '${cat.shortCode} • ${cat.name}',
                categorySlug: cat.slug,
                isSelected: selectedSlug == cat.slug,
                useGlass: true,
                onTap: () {
                  final next = selectedSlug == cat.slug ? null : cat.slug;
                  ref
                      .read(selectedCategoryFilterProvider.notifier)
                      .selectCategory(next);
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Marker _buildPlantMarker({
    required BuildContext context,
    required PowerPlant plant,
    required ExternalMapService externalMapService,
  }) {
    final markerColor = AppColors.colorForCategorySlug(
      plant.categorySlug ?? '',
    );

    return Marker(
      point: LatLng(plant.latitude, plant.longitude),
      width: 48,
      height: 48,
      child: Semantics(
        label: 'Marker pembangkit ${plant.name}',
        button: true,
        child: GestureDetector(
          onTap: () {
            PlantPreviewSheet.show(
              context: context,
              plant: plant,
              externalMapService: externalMapService,
            );
          },
          child: Center(
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: markerColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.surfaceWhite,
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.forestGreen.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                iconForCategorySlug(plant.categorySlug),
                size: 20,
                color: AppColors.forestGreen,
              ),
            ),
          ),
        ),
      ),
    );
  }
}


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
import '../../../../core/widgets/common/screen_header.dart';
import '../../../../core/widgets/common/soft_image_placeholder.dart';
import '../../../../core/widgets/glass/glass_container.dart';
import '../../../../models/energy_category.dart';
import '../../../../models/power_plant.dart';
import '../../../../routes/route_names.dart';
import '../../../../services/external_map_service.dart';
import '../../../plants/presentation/providers/plants_providers.dart';

/// Halaman Peta Eksplorasi Pembangkit (Explore Map).
class ExploreMapPage extends ConsumerStatefulWidget {
  const ExploreMapPage({super.key});

  @override
  ConsumerState<ExploreMapPage> createState() => _ExploreMapPageState();
}

class _ExploreMapPageState extends ConsumerState<ExploreMapPage> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  static const LatLng _indonesiaCenter = LatLng(-2.5489, 118.0149);
  static const double _defaultZoom = 4.6;

  String _localSearchQuery = '';
  String? _selectedPlantId;
  bool _isPreviewDismissed = false;

  @override
  void dispose() {
    _mapController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _resetCamera() {
    _mapController.move(_indonesiaCenter, _defaultZoom);
  }

  void _selectPlantOnMap(PowerPlant plant) {
    setState(() {
      _selectedPlantId = plant.id;
      _isPreviewDismissed = false;
    });
    _mapController.move(LatLng(plant.latitude, plant.longitude), 7.2);
  }

  List<PowerPlant> _applyLocalSearch(List<PowerPlant> plants) {
    final q = _localSearchQuery.trim().toLowerCase();
    if (q.isEmpty) return plants;
    return plants.where((p) {
      return p.name.toLowerCase().contains(q) ||
          p.province.toLowerCase().contains(q) ||
          (p.city?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(energyCategoriesProvider);
    final plantsAsync = ref.watch(filteredPlantsListProvider);
    final selectedSlug = ref.watch(selectedCategoryFilterProvider);
    final selectedStatuses = ref.watch(selectedStatusesFilterProvider);
    final externalMapService = ref.watch(externalMapServiceProvider);

    final visiblePlants = plantsAsync.asData != null
        ? _applyLocalSearch(plantsAsync.asData!.value)
        : const <PowerPlant>[];

    PowerPlant? activePreviewPlant;
    if (!_isPreviewDismissed && visiblePlants.isNotEmpty) {
      activePreviewPlant = visiblePlants
              .where((p) => p.id == _selectedPlantId)
              .firstOrNull ??
          visiblePlants.first;
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
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
              if (visiblePlants.isNotEmpty)
                MarkerLayer(
                  markers: visiblePlants.map((plant) {
                    final isSelected = activePreviewPlant?.id == plant.id;
                    return _buildPlantMarker(
                      plant: plant,
                      isSelected: isSelected,
                    );
                  }).toList(),
                ),
            ],
          ),

          // 2. ScreenHeader + Search Bar + Filter Kategori & Filter Status
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                  child: GlassContainer(
                    borderRadius: AppTheme.cardRadius,
                    blur: 14,
                    tintOpacity: 0.72,
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                    child: Column(
                      children: [
                        ScreenHeader(
                          title: 'Peta Pembangkit',
                          subtitle:
                              'Menampilkan ${visiblePlants.length} titik pembangkit',
                          isCompact: true,
                          actions: [
                            ScreenHeaderAction(
                              tooltip: 'Pembangkit Terdekat',
                              icon: Icons.near_me_rounded,
                              onTap: () =>
                                  context.push(RouteNames.nearbyPlantsPath),
                            ),
                            ScreenHeaderAction(
                              tooltip: 'Reset Posisi Peta',
                              icon: Icons.center_focus_strong_rounded,
                              onTap: _resetCamera,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceWhite.withValues(
                              alpha: 0.88,
                            ),
                            borderRadius: BorderRadius.circular(
                              AppTheme.pillRadius,
                            ),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.search_rounded,
                                color: AppColors.textSecondary,
                                size: 19,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  onChanged: (val) {
                                    setState(() {
                                      _localSearchQuery = val;
                                      _isPreviewDismissed = false;
                                    });
                                  },
                                  style: AppTextStyles.body.copyWith(
                                    fontSize: 13.5,
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: 'Cari lokasi pembangkit...',
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    filled: false,
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: 9,
                                    ),
                                  ),
                                ),
                              ),
                              if (_localSearchQuery.isNotEmpty)
                                GestureDetector(
                                  onTap: () {
                                    _searchController.clear();
                                    setState(() => _localSearchQuery = '');
                                  },
                                  child: const Icon(
                                    Icons.close_rounded,
                                    size: 18,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _buildCategoryFilterBar(categoriesAsync, selectedSlug),
                const SizedBox(height: 6),
                _buildStatusFilterBar(selectedStatuses),
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
            data: (_) {
              if (visiblePlants.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: GlassContainer(
                      tintOpacity: 0.9,
                      child: EmptyView(
                        icon: Icons.location_off_outlined,
                        title: 'Tidak Ada Pembangkit Ditemukan',
                        description:
                            'Tidak ada pembangkit yang cocok dengan filter kategori, status, atau pencarian saat ini.',
                        actionLabel: 'Reset Filter & Pencarian',
                        onAction: () {
                          _searchController.clear();
                          setState(() => _localSearchQuery = '');
                          ref
                              .read(selectedCategoryFilterProvider.notifier)
                              .selectCategory(null);
                          ref
                              .read(selectedStatusesFilterProvider.notifier)
                              .resetToDefault();
                        },
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // 4. Kartu Preview Pembangkit di Bawah + Tombol Terdekat + Atribusi OSM
          Positioned(
            left: AppTheme.bottomNavHorizontalMargin,
            right: AppTheme.bottomNavHorizontalMargin,
            bottom: AppTheme.mapOverlayBottomPadding +
                MediaQuery.viewPaddingOf(context).bottom,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () {
                        externalMapService.openExternalUrl(
                          'https://www.openstreetmap.org/copyright',
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceWhite.withValues(
                            alpha: 0.88,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Text(
                          AppConstants.osmAttribution,
                          style: AppTextStyles.caption.copyWith(fontSize: 10),
                        ),
                      ),
                    ),
                    Material(
                      color: AppColors.surfaceWhite,
                      shape: const CircleBorder(),
                      elevation: 2,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () =>
                            context.push(RouteNames.nearbyPlantsPath),
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: const Icon(
                            Icons.near_me_rounded,
                            color: AppColors.forestGreen,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (activePreviewPlant != null) ...[
                  const SizedBox(height: 10),
                  _MapPlantPreviewCard(
                    plant: activePreviewPlant,
                    onOpenDetail: () =>
                        context.push('/plants/${activePreviewPlant!.id}'),
                    onOpenGoogleMaps: () async {
                      final plant = activePreviewPlant!;
                      final ok = plant.isApproximate
                          ? await externalMapService.searchPlaceInGoogleMaps(
                              name: plant.name,
                              city: plant.city,
                              province: plant.province,
                            )
                          : await externalMapService
                              .openCoordinatesInGoogleMaps(
                              latitude: plant.latitude,
                              longitude: plant.longitude,
                            );
                      if (!ok && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Gagal membuka aplikasi Google Maps.',
                            ),
                          ),
                        );
                      }
                    },
                    onClose: () {
                      setState(() => _isPreviewDismissed = true);
                    },
                  ),
                ],
              ],
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
      height: 36,
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
            final label = shortDisplayLabelForSlug(cat.slug, cat.name);
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: CategoryChip(
                label: label,
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

  Widget _buildStatusFilterBar(Set<String> selectedStatuses) {
    const statusOptions = <(String, String, IconData)>[
      ('operating', 'Beroperasi', Icons.check_circle_outline_rounded),
      ('construction', 'Konstruksi', Icons.engineering_outlined),
      ('planned', 'Rencana', Icons.schedule_rounded),
    ];

    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: statusOptions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final opt = statusOptions[index];
          final code = opt.$1;
          final label = opt.$2;
          final icon = opt.$3;
          final isSelected = selectedStatuses.contains(code);

          return Material(
            color: isSelected
                ? AppColors.forestGreen
                : AppColors.surfaceWhite.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(AppTheme.pillRadius),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppTheme.pillRadius),
              onTap: () {
                ref
                    .read(selectedStatusesFilterProvider.notifier)
                    .toggleStatus(code);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.forestGreen
                        : AppColors.sageGreen.withValues(alpha: 0.65),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 14,
                      color: isSelected
                          ? AppColors.mintGreen
                          : AppColors.forestGreen,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      label,
                      style: AppTextStyles.caption.copyWith(
                        color: isSelected
                            ? AppColors.surfaceWhite
                            : AppColors.forestGreen,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Marker _buildPlantMarker({
    required PowerPlant plant,
    required bool isSelected,
  }) {
    final slug = plant.categorySlug ?? '';
    final markerColor = AppColors.colorForCategorySlug(slug);
    final status = plant.operationalStatus.trim().toLowerCase();
    final isConstruction = status == 'construction';
    final isPlanned = status == 'planned';

    final Color fillColor = isPlanned
        ? AppColors.surfaceWhite.withValues(alpha: 0.92)
        : isConstruction
            ? markerColor.withValues(alpha: 0.78)
            : markerColor;

    final Color borderColor = isPlanned
        ? markerColor
        : isConstruction
            ? const Color(0xFFD97706)
            : AppColors.surfaceWhite;

    final Color iconColor = isPlanned
        ? (slug == 'solar' ? const Color(0xFFD97706) : AppColors.forestGreen)
        : (slug == 'solar' ? AppColors.forestGreen : AppColors.surfaceWhite);

    return Marker(
      point: LatLng(plant.latitude, plant.longitude),
      width: isSelected ? 54 : 46,
      height: isSelected ? 54 : 46,
      child: Semantics(
        label:
            'Marker pembangkit ${plant.name} (${plant.operationalStatusLabel})',
        button: true,
        child: GestureDetector(
          onTap: () => _selectPlantOnMap(plant),
          child: Center(
            child: Opacity(
              opacity: isPlanned ? 0.78 : (isConstruction ? 0.88 : 1.0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isSelected ? 44 : 36,
                height: isSelected ? 44 : 36,
                decoration: BoxDecoration(
                  color: fillColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: borderColor,
                    width: isSelected ? 3.2 : (isPlanned || isConstruction ? 2.6 : 2.2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.forestGreen.withValues(
                        alpha: isSelected ? 0.35 : 0.2,
                      ),
                      blurRadius: isSelected ? 10 : 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      iconForCategorySlug(slug),
                      size: isSelected ? 21 : 17,
                      color: iconColor,
                    ),
                    if (isConstruction || isPlanned)
                      Positioned(
                        right: -3,
                        bottom: -3,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: isConstruction
                                ? const Color(0xFFD97706)
                                : AppColors.slateGray,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.surfaceWhite,
                              width: 1.2,
                            ),
                          ),
                          child: Icon(
                            isConstruction
                                ? Icons.build_rounded
                                : Icons.schedule_rounded,
                            size: 8.5,
                            color: AppColors.surfaceWhite,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MapPlantPreviewCard extends StatelessWidget {
  const _MapPlantPreviewCard({
    required this.plant,
    required this.onOpenDetail,
    required this.onOpenGoogleMaps,
    required this.onClose,
  });

  final PowerPlant plant;
  final VoidCallback onOpenDetail;
  final VoidCallback onOpenGoogleMaps;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final slug = plant.categorySlug ?? '';
    final softBg = AppColors.softBackgroundForCategorySlug(slug);
    final capacityText = plant.capacityMw != null
        ? ' • ${plant.capacityMw!.toStringAsFixed(1)} MW'
        : '';
    final status = plant.operationalStatus.trim().toLowerCase();

    return GlassContainer(
      borderRadius: AppTheme.cardRadius,
      blur: 14,
      tintOpacity: 0.78,
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Stack(
            children: [
              SoftImagePlaceholder(
                width: 74,
                height: 74,
                borderRadius: 12,
                networkImageUrl: plant.imageUrl,
                assetPath: assetForCategorySlug(slug),
                backgroundColor: softBg,
                fallbackIcon: iconForCategorySlug(slug),
                iconColor: AppColors.forestGreen,
                iconSize: 30,
              ),
              if (plant.isDemo)
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warmYellow,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'DEMO',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.forestGreen,
                        fontWeight: FontWeight.w700,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        plant.name,
                        style: AppTextStyles.subtitle.copyWith(fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: onClose,
                      child: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: status == 'operating'
                            ? AppColors.mintGreen
                            : status == 'construction'
                                ? const Color(0xFFFEF3C7)
                                : const Color(0xFFE2E8F0),
                        borderRadius:
                            BorderRadius.circular(AppTheme.pillRadius),
                      ),
                      child: Text(
                        plant.operationalStatusLabel,
                        style: AppTextStyles.caption.copyWith(
                          color: status == 'operating'
                              ? AppColors.forestGreen
                              : status == 'construction'
                                  ? const Color(0xFFB45309)
                                  : AppColors.slateGray,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    if (plant.isApproximate)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius:
                              BorderRadius.circular(AppTheme.pillRadius),
                        ),
                        child: Text(
                          'Lokasi perkiraan',
                          style: AppTextStyles.caption.copyWith(
                            color: const Color(0xFFB45309),
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    Text(
                      '${plant.province}$capacityText',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Material(
                        color: AppColors.forestGreen,
                        borderRadius: BorderRadius.circular(
                          AppTheme.pillRadius,
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(
                            AppTheme.pillRadius,
                          ),
                          onTap: onOpenDetail,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Lihat Detail',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.surfaceWhite,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 14,
                                  color: AppColors.surfaceWhite,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Tooltip(
                      message: plant.isApproximate
                          ? 'Cari di Google Maps'
                          : 'Lihat titik di Google Maps',
                      child: Material(
                        color: AppColors.mintGreen,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: onOpenGoogleMaps,
                          child: const Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(
                              Icons.open_in_new_rounded,
                              size: 16,
                              color: AppColors.forestGreen,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

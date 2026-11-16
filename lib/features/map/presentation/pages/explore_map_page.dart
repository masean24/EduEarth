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
import '../../../../services/location_service.dart';
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

  static final CameraFit _indonesiaCameraFit = CameraFit.bounds(
    bounds: LatLngBounds(
      const LatLng(-11.0, 94.8),
      const LatLng(6.2, 141.2),
    ),
    padding: const EdgeInsets.fromLTRB(16, 175, 16, 130),
  );

  String _localSearchQuery = '';
  String? _selectedPlantId;
  bool _isPreviewDismissed = false;
  bool _hasTileError = false;
  bool _isLocating = false;

  @override
  void dispose() {
    _mapController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _resetCamera() {
    _mapController.fitCamera(_indonesiaCameraFit);
  }

  PowerPlant? _pickFlagshipPlant(List<PowerPlant> plants) {
    if (plants.isEmpty) return null;
    return plants
            .where(
              (p) =>
                  !p.isApproximate &&
                  p.operationalStatus.trim().toLowerCase() == 'operating',
            )
            .firstOrNull ??
        plants.where((p) => !p.isApproximate).firstOrNull ??
        plants.first;
  }

  Future<void> _centerOnUserLocation() async {
    if (_isLocating) return;
    setState(() => _isLocating = true);
    try {
      final result =
          await ref.read(locationServiceProvider).getCurrentLocation();
      if (!mounted) return;
      if (result.hasPosition) {
        final pos = result.position!;
        _mapController.move(LatLng(pos.latitude, pos.longitude), 10.5);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Peta dipusatkan ke lokasi Anda.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.message ?? 'Lokasi perangkat belum tersedia.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLocating = false);
      }
    }
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
      activePreviewPlant = _selectedPlantId != null
          ? visiblePlants.where((p) => p.id == _selectedPlantId).firstOrNull
          : (_localSearchQuery.trim().isNotEmpty
                ? _pickFlagshipPlant(visiblePlants)
                : null);
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // 1. Peta OpenStreetMap
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCameraFit: _indonesiaCameraFit,
              minZoom: 3.2,
              maxZoom: 18.0,
            ),
            children: [
              TileLayer(
                urlTemplate: AppConstants.osmTileUrl,
                userAgentPackageName: AppConstants.appPackageName,
                errorTileCallback: (_, _, _) {
                  if (!_hasTileError && mounted) {
                    setState(() => _hasTileError = true);
                  }
                },
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
                                IconButton(
                                  tooltip: 'Hapus pencarian',
                                  constraints: const BoxConstraints(
                                    minWidth: 44,
                                    minHeight: 44,
                                  ),
                                  padding: EdgeInsets.zero,
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _localSearchQuery = '');
                                  },
                                  icon: const Icon(
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
                return Positioned(
                  top: 215,
                  left: 16,
                  right: 16,
                  bottom: AppTheme.mapOverlayBottomPadding + 16,
                  child: Center(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceWhite.withValues(alpha: 0.96),
                        borderRadius: BorderRadius.circular(
                          AppTheme.cardRadius,
                        ),
                        border: Border.all(color: AppColors.divider),
                        boxShadow: AppTheme.softCardShadow,
                      ),
                      child: EmptyView(
                        icon: Icons.location_off_outlined,
                        assetPath: 'assets/images/mascot/eco_thinking.png',
                        title: 'Tidak Ada Pembangkit Ditemukan',
                        description:
                            'Tidak ada pembangkit yang cocok dengan filter kategori, status, atau pencarian saat ini.',
                        actionLabel: 'Reset Filter & Pencarian',
                        onAction: () {
                          _searchController.clear();
                          setState(() {
                            _localSearchQuery = '';
                            _selectedPlantId = null;
                          });
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

          // 4. Kartu Preview Pembangkit di Bawah + Tombol Lokasi Saya + Atribusi OSM
          if (plantsAsync.asData != null && visiblePlants.isNotEmpty)
            Positioned(
              left: AppTheme.bottomNavHorizontalMargin,
              right: AppTheme.bottomNavHorizontalMargin,
              bottom: AppTheme.mapOverlayBottomPadding +
                  MediaQuery.viewPaddingOf(context).bottom,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_hasTileError) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warningBg,
                          borderRadius: BorderRadius.circular(
                            AppTheme.pillRadius,
                          ),
                          border: Border.all(
                            color: AppColors.warningFg.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          'Ubin peta dasar sedang offline — pin pembangkit tetap aktif',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.warningFg,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ],
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
                              alpha: 0.90,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: Text(
                            AppConstants.osmAttribution,
                            style: AppTextStyles.caption.copyWith(fontSize: 10.5),
                          ),
                        ),
                      ),
                      Semantics(
                        button: true,
                        label: 'Pusatkan ke lokasi saya',
                        child: Tooltip(
                          message: 'Pusatkan ke lokasi saya',
                          child: Material(
                            color: AppColors.surfaceWhite,
                            shape: const CircleBorder(),
                            elevation: 2,
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: _centerOnUserLocation,
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.divider),
                                ),
                                child: _isLocating
                                    ? const Padding(
                                        padding: EdgeInsets.all(13),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.my_location_rounded,
                                        color: AppColors.forestGreen,
                                        size: 22,
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (activePreviewPlant != null)
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
                        setState(() {
                          _selectedPlantId = null;
                          _isPreviewDismissed = true;
                        });
                      },
                    )
                  else
                    GlassContainer(
                      borderRadius: AppTheme.pillRadius,
                      blur: 14,
                      tintOpacity: 0.86,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.touch_app_rounded,
                            size: 18,
                            color: AppColors.forestGreen,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Ketuk pin di peta (${visiblePlants.length} titik)',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.forestGreen,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              final target = _pickFlagshipPlant(visiblePlants);
                              if (target != null) {
                                _selectPlantOnMap(target);
                              }
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              minimumSize: const Size(48, 36),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text('Lihat unggulan'),
                          ),
                        ],
                      ),
                    ),
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
      child: HorizontalChipStrip(
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 0, 32, 0),
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
            ? AppColors.warningFg
            : AppColors.surfaceWhite;

    final Color iconColor = isPlanned
        ? (slug == 'solar' ? AppColors.warningFg : AppColors.forestGreen)
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
                                ? AppColors.warningFg
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
                    IconButton(
                      tooltip: 'Tutup pratinjau',
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                      padding: EdgeInsets.zero,
                      onPressed: onClose,
                      icon: const Icon(
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
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 48),
                        child: Material(
                          color: AppColors.actionGreen,
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
                                horizontal: 14,
                                vertical: 11,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Lihat Detail',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.surfaceWhite,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 16,
                                    color: AppColors.surfaceWhite,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Tooltip(
                      message: plant.isApproximate
                          ? 'Cari di Google Maps'
                          : 'Lihat titik di Google Maps',
                      child: InkResponse(
                        onTap: onOpenGoogleMaps,
                        radius: 24,
                        customBorder: const CircleBorder(),
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: Center(
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: const BoxDecoration(
                                color: AppColors.mintGreen,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.open_in_new_rounded,
                                size: 17,
                                color: AppColors.forestGreen,
                              ),
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

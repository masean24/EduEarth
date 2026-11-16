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
import '../../../../core/widgets/common/plant_card.dart';
import '../../../../core/widgets/common/screen_header.dart';
import '../../../../core/widgets/common/soft_image_placeholder.dart';
import '../../../../core/widgets/glass/glass_container.dart';
import '../../../../models/energy_category.dart';
import '../../../../models/power_plant.dart';
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
    padding: const EdgeInsets.fromLTRB(16, 155, 16, 130),
  );

  String _localSearchQuery = '';
  String? _selectedPlantId;
  bool _isPreviewDismissed = false;
  bool _hasTileError = false;
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final nearbyState = ref.read(mapNearbyProvider);
      if (nearbyState.pendingAutoActivate) {
        ref.read(mapNearbyProvider.notifier).consumePendingAutoActivate();
        _activateOrRefreshNearbyMode();
      }
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _fitNearbyRadiusCamera(LatLng center, int radiusMeters) {
    final corners = computeNearbyRadiusCorners(
      center: center,
      radiusMeters: radiusMeters,
    );
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds(corners.southWest, corners.northEast),
        padding: const EdgeInsets.fromLTRB(28, 195, 28, 240),
      ),
    );
  }

  void _resetCamera() {
    final nearbyState = ref.read(mapNearbyProvider);
    if (nearbyState.isEnabled && nearbyState.userCenter != null) {
      _fitNearbyRadiusCamera(nearbyState.userCenter!, nearbyState.radiusMeters);
      return;
    }
    _mapController.fitCamera(_indonesiaCameraFit);
  }

  void _disableNearbyMode() {
    ref.read(mapNearbyProvider.notifier).disable();
    setState(() {
      _selectedPlantId = null;
      _isPreviewDismissed = true;
    });
    _mapController.fitCamera(_indonesiaCameraFit);
  }

  void _toggleNearbyMode() {
    final nearbyState = ref.read(mapNearbyProvider);
    if (nearbyState.isEnabled) {
      _disableNearbyMode();
      return;
    }
    _activateOrRefreshNearbyMode();
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

  Future<void> _activateOrRefreshNearbyMode({
    bool showCenteredSnackBar = true,
  }) async {
    if (_isLocating) return;
    setState(() => _isLocating = true);
    final locationService = ref.read(locationServiceProvider);

    try {
      final result = await locationService.getCurrentLocation();
      if (!mounted) return;

      if (result.hasPosition) {
        final pos = result.position!;
        final radiusMeters = ref.read(mapNearbyProvider).radiusMeters;
        ref.read(mapNearbyProvider.notifier).enable(
              userLat: pos.latitude,
              userLng: pos.longitude,
              radiusMeters: radiusMeters,
            );
        setState(() {
          _selectedPlantId = null;
          _isPreviewDismissed = false;
        });
        _fitNearbyRadiusCamera(
          LatLng(pos.latitude, pos.longitude),
          radiusMeters,
        );
        if (showCenteredSnackBar) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(
                  'Menampilkan pembangkit dalam radius ${formatRadiusLabel(radiusMeters)}.',
                ),
              ),
            );
        }
      } else {
        SnackBarAction? action;
        if (result.accessState == LocationAccessState.serviceDisabled) {
          action = SnackBarAction(
            label: 'Pengaturan',
            onPressed: locationService.openLocationSettings,
          );
        } else if (result.accessState ==
            LocationAccessState.permissionDeniedForever) {
          action = SnackBarAction(
            label: 'Izin App',
            onPressed: locationService.openAppSettings,
          );
        }
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                result.message ?? 'Lokasi perangkat belum tersedia.',
              ),
              action: action,
            ),
          );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Gagal membaca koordinat GPS. Pastikan GPS aktif lalu coba lagi.',
            ),
          ),
        );
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
    final currentZoom = _mapController.camera.zoom;
    final targetZoom = currentZoom > 7.2 ? currentZoom : 7.2;
    _mapController.move(LatLng(plant.latitude, plant.longitude), targetZoom);
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
    ref.listen<MapNearbyState>(mapNearbyProvider, (prev, next) {
      if (next.pendingAutoActivate && !(prev?.pendingAutoActivate ?? false)) {
        ref.read(mapNearbyProvider.notifier).consumePendingAutoActivate();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _activateOrRefreshNearbyMode();
          }
        });
      }
    });

    final categoriesAsync = ref.watch(energyCategoriesProvider);
    final plantsAsync = ref.watch(filteredPlantsListProvider);
    final selectedSlug = ref.watch(selectedCategoryFilterProvider);
    final selectedStatuses = ref.watch(selectedStatusesFilterProvider);
    final nearbyState = ref.watch(mapNearbyProvider);
    final externalMapService = ref.watch(externalMapServiceProvider);

    final basePlants = plantsAsync.asData?.value ?? const <PowerPlant>[];
    final nearbyFilteredPlants = nearbyState.isEnabled && nearbyState.hasLocation
        ? filterAndSortPlantsByRadius(
            plants: basePlants,
            userLat: nearbyState.userLat!,
            userLng: nearbyState.userLng!,
            radiusMeters: nearbyState.radiusMeters,
          )
        : basePlants;
    final visiblePlants = _applyLocalSearch(nearbyFilteredPlants);

    PowerPlant? activePreviewPlant;
    if (!_isPreviewDismissed && visiblePlants.isNotEmpty) {
      final matchedById = _selectedPlantId != null
          ? visiblePlants.where((p) => p.id == _selectedPlantId).firstOrNull
          : null;
      if (matchedById != null) {
        activePreviewPlant = matchedById;
      } else if (nearbyState.isEnabled) {
        activePreviewPlant = visiblePlants.first;
      } else if (_localSearchQuery.trim().isNotEmpty) {
        activePreviewPlant = _pickFlagshipPlant(visiblePlants);
      }
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
              if (nearbyState.isEnabled && nearbyState.userCenter != null)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: nearbyState.userCenter!,
                      radius: nearbyState.radiusMeters.toDouble(),
                      useRadiusInMeter: true,
                      color: AppColors.skyBlue.withValues(alpha: 0.14),
                      borderStrokeWidth: 2,
                      borderColor: AppColors.skyBlue.withValues(alpha: 0.72),
                    ),
                  ],
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
              if (nearbyState.isEnabled && nearbyState.userCenter != null)
                MarkerLayer(
                  markers: [
                    _buildUserLocationMarker(nearbyState.userCenter!),
                  ],
                ),
            ],
          ),

          // 2. ScreenHeader + Search Bar + Filter Kategori & Radius
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                  child: GlassContainer(
                    borderRadius: AppTheme.cardRadius,
                    blur: 14,
                    tintOpacity: 0.72,
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                    child: Column(
                      children: [
                        ScreenHeader(
                          title: 'Peta Pembangkit',
                          subtitle: _buildHeaderSubtitle(
                            visiblePlants.length,
                            nearbyState,
                            selectedStatuses,
                          ),
                          isCompact: true,
                          actions: [
                            ScreenHeaderAction(
                              tooltip: nearbyState.isEnabled
                                  ? 'Matikan mode terdekat'
                                  : 'Pembangkit Terdekat',
                              icon: Icons.near_me_rounded,
                              backgroundColor: nearbyState.isEnabled
                                  ? AppColors.actionGreen
                                  : AppColors.surfaceWhite,
                              iconColor: nearbyState.isEnabled
                                  ? AppColors.surfaceWhite
                                  : AppColors.forestGreen,
                              onTap: _toggleNearbyMode,
                            ),
                            ScreenHeaderAction(
                              tooltip: nearbyState.isEnabled
                                  ? 'Paskan kamera ke radius'
                                  : 'Reset Posisi Peta',
                              icon: Icons.center_focus_strong_rounded,
                              onTap: _resetCamera,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
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
                                      size: 18,
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
                                            vertical: 8,
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (_localSearchQuery.isNotEmpty)
                                      IconButton(
                                        tooltip: 'Hapus pencarian',
                                        constraints: const BoxConstraints(
                                          minWidth: 44,
                                          minHeight: 40,
                                        ),
                                        padding: EdgeInsets.zero,
                                        visualDensity: VisualDensity.compact,
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(
                                            () => _localSearchQuery = '',
                                          );
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
                            ),
                            const SizedBox(width: 8),
                            _StatusFilterButton(
                              activeCount: selectedStatuses.length,
                              isDefault: selectedStatuses.length == 1 &&
                                  selectedStatuses.contains('operating'),
                              onTap: () => _showStatusFilterBottomSheet(context),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                _buildCategoryFilterBar(categoriesAsync, selectedSlug),
                if (nearbyState.isEnabled) ...[
                  const SizedBox(height: 6),
                  _buildRadiusFilterBar(nearbyState),
                ],
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
                final isEmptyNearby =
                    nearbyState.isEnabled && _localSearchQuery.trim().isEmpty;
                return Positioned(
                  top: nearbyState.isEnabled ? 205 : 165,
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
                        title: isEmptyNearby
                            ? 'Tidak Ada di Radius ${formatRadiusLabel(nearbyState.radiusMeters)}'
                            : 'Tidak Ada Pembangkit Ditemukan',
                        description: isEmptyNearby
                            ? 'Perluas radius pencarian atau reset filter kategori & status untuk melihat pembangkit di sekitar Anda.'
                            : 'Tidak ada pembangkit yang cocok dengan filter kategori, status, atau pencarian saat ini.',
                        actionLabel: isEmptyNearby
                            ? (nearbyState.radiusMeters < 1500000
                                ? 'Perluas ke 1.500 km'
                                : 'Tampilkan Semua Wilayah')
                            : 'Reset Filter & Pencarian',
                        onAction: () {
                          if (isEmptyNearby) {
                            if (nearbyState.radiusMeters < 1500000) {
                              ref
                                  .read(mapNearbyProvider.notifier)
                                  .setRadiusMeters(1500000);
                              if (nearbyState.userCenter != null) {
                                _fitNearbyRadiusCamera(
                                  nearbyState.userCenter!,
                                  1500000,
                                );
                              }
                            } else {
                              ref
                                  .read(selectedCategoryFilterProvider.notifier)
                                  .selectCategory(null);
                              ref
                                  .read(selectedStatusesFilterProvider.notifier)
                                  .resetToDefault();
                              _disableNearbyMode();
                            }
                            return;
                          }
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
                      Flexible(
                        child: GestureDetector(
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
                              style: AppTextStyles.caption.copyWith(
                                fontSize: 10.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (nearbyState.isEnabled) ...[
                            _NearbyListTriggerChip(
                              count: visiblePlants.length,
                              onTap: () => _showNearbyPlantsBottomSheet(
                                context,
                                visiblePlants,
                                nearbyState.radiusMeters,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Semantics(
                            button: true,
                            label: nearbyState.isEnabled
                                ? 'Perbarui lokasi saya'
                                : 'Cari pembangkit terdekat dari lokasi saya',
                            child: Tooltip(
                              message: nearbyState.isEnabled
                                  ? 'Perbarui lokasi saya'
                                  : 'Cari pembangkit terdekat (GPS)',
                              child: Material(
                                color: nearbyState.isEnabled
                                    ? AppColors.actionGreen
                                    : AppColors.surfaceWhite,
                                shape: const CircleBorder(),
                                elevation: 2,
                                child: InkWell(
                                  customBorder: const CircleBorder(),
                                  onTap: _activateOrRefreshNearbyMode,
                                  child: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: nearbyState.isEnabled
                                            ? AppColors.actionGreen
                                            : AppColors.divider,
                                      ),
                                    ),
                                    child: _isLocating
                                        ? Padding(
                                            padding: const EdgeInsets.all(13),
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: nearbyState.isEnabled
                                                  ? AppColors.surfaceWhite
                                                  : AppColors.forestGreen,
                                            ),
                                          )
                                        : Icon(
                                            Icons.my_location_rounded,
                                            color: nearbyState.isEnabled
                                                ? AppColors.surfaceWhite
                                                : AppColors.forestGreen,
                                            size: 22,
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
                          Icon(
                            nearbyState.isEnabled
                                ? Icons.radar_rounded
                                : Icons.touch_app_rounded,
                            size: 18,
                            color: AppColors.forestGreen,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              nearbyState.isEnabled
                                  ? 'Radius ${formatRadiusLabel(nearbyState.radiusMeters)}: ${visiblePlants.length} titik terdekat'
                                  : 'Ketuk pin di peta (${visiblePlants.length} titik)',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.forestGreen,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              if (nearbyState.isEnabled) {
                                _showNearbyPlantsBottomSheet(
                                  context,
                                  visiblePlants,
                                  nearbyState.radiusMeters,
                                );
                                return;
                              }
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
                            child: Text(
                              nearbyState.isEnabled
                                  ? 'Lihat daftar'
                                  : 'Lihat unggulan',
                            ),
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

  String _buildHeaderSubtitle(
    int count,
    MapNearbyState nearbyState,
    Set<String> selectedStatuses,
  ) {
    if (nearbyState.isEnabled) {
      return 'Radius ${formatRadiusLabel(nearbyState.radiusMeters)} • $count titik terdekat';
    }
    if (selectedStatuses.length == 3) {
      return '$count titik pembangkit • Semua status';
    }
    if (selectedStatuses.length == 1 &&
        selectedStatuses.contains('operating')) {
      return '$count titik beroperasi';
    }
    return '$count titik • ${selectedStatuses.length} status aktif';
  }

  Future<void> _showStatusFilterBottomSheet(BuildContext context) async {
    const statusOptions = <(String, String, String, IconData)>[
      (
        'operating',
        'Beroperasi',
        'Sudah aktif menghasilkan listrik',
        Icons.check_circle_outline_rounded,
      ),
      (
        'construction',
        'Konstruksi',
        'Sedang dalam tahap pembangunan',
        Icons.engineering_outlined,
      ),
      (
        'planned',
        'Rencana',
        'Masih dalam tahap studi atau perencanaan',
        Icons.schedule_rounded,
      ),
    ];

    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.52,
          minChildSize: 0.34,
          maxChildSize: 0.78,
          expand: false,
          builder: (ctx, scrollController) {
            return Consumer(
              builder: (_, sheetRef, _) {
                final selectedStatuses =
                    sheetRef.watch(selectedStatusesFilterProvider);
                final isDefault = selectedStatuses.length == 1 &&
                    selectedStatuses.contains('operating');

                return Container(
                  decoration: const BoxDecoration(
                    color: AppColors.offWhite,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(AppTheme.cardRadius),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.divider,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 8, 4),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.tune_rounded,
                              color: AppColors.forestGreen,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Filter Status Operasional',
                                style: AppTextStyles.subtitle,
                              ),
                            ),
                            if (!isDefault)
                              TextButton(
                                onPressed: () {
                                  sheetRef
                                      .read(selectedStatusesFilterProvider
                                          .notifier)
                                      .resetToDefault();
                                },
                                child: const Text('Reset'),
                              ),
                            IconButton(
                              tooltip: 'Tutup filter',
                              constraints: const BoxConstraints(
                                minWidth: 44,
                                minHeight: 44,
                              ),
                              onPressed: () =>
                                  Navigator.of(sheetContext).pop(),
                              icon: const Icon(
                                Icons.close_rounded,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          padding: EdgeInsets.fromLTRB(
                            16,
                            12,
                            16,
                            24 + MediaQuery.viewPaddingOf(ctx).bottom,
                          ),
                          children: statusOptions.map((opt) {
                            final code = opt.$1;
                            final label = opt.$2;
                            final desc = opt.$3;
                            final icon = opt.$4;
                            final isSelected = selectedStatuses.contains(code);
                            final isLastSelected =
                                isSelected && selectedStatuses.length == 1;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Material(
                                color: isSelected
                                    ? AppColors.mintGreen.withValues(
                                        alpha: 0.72,
                                      )
                                    : AppColors.surfaceWhite,
                                borderRadius: BorderRadius.circular(14),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: isLastSelected
                                      ? null
                                      : () {
                                          sheetRef
                                              .read(
                                                selectedStatusesFilterProvider
                                                    .notifier,
                                              )
                                              .toggleStatus(code);
                                        },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.forestGreen.withValues(
                                                alpha: 0.45,
                                              )
                                            : AppColors.divider,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          icon,
                                          size: 20,
                                          color: isSelected
                                              ? AppColors.forestGreen
                                              : AppColors.textSecondary,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                label,
                                                style: AppTextStyles.subtitle
                                                    .copyWith(
                                                  fontSize: 14,
                                                  color: AppColors.forestGreen,
                                                ),
                                              ),
                                              Text(
                                                isLastSelected
                                                    ? 'Minimal 1 status harus dipilih'
                                                    : desc,
                                                style: AppTextStyles.caption
                                                    .copyWith(
                                                  fontSize: 11.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Icon(
                                          isSelected
                                              ? Icons.check_circle_rounded
                                              : Icons
                                                  .radio_button_unchecked_rounded,
                                          color: isSelected
                                              ? AppColors.actionGreen
                                              : AppColors.textMuted,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildRadiusFilterBar(MapNearbyState nearbyState) {
    return SizedBox(
      height: 32,
      child: HorizontalChipStrip(
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 0, 32, 0),
          children: [
            _buildRadiusPill(
              label: 'Semua',
              icon: Icons.public_rounded,
              isSelected: false,
              onTap: _disableNearbyMode,
            ),
            const SizedBox(width: 8),
            ...kNearbyRadiusOptions.map((opt) {
              final isSelected = nearbyState.radiusMeters == opt.meters;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildRadiusPill(
                  label: opt.label,
                  icon: isSelected ? Icons.check_rounded : null,
                  isSelected: isSelected,
                  onTap: () {
                    ref
                        .read(mapNearbyProvider.notifier)
                        .setRadiusMeters(opt.meters);
                    setState(() {
                      _selectedPlantId = null;
                      _isPreviewDismissed = false;
                    });
                    if (nearbyState.userCenter != null) {
                      _fitNearbyRadiusCamera(
                        nearbyState.userCenter!,
                        opt.meters,
                      );
                    }
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildRadiusPill({
    required String label,
    IconData? icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isSelected
          ? AppColors.actionGreen
          : AppColors.surfaceWhite.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(AppTheme.pillRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.pillRadius),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.pillRadius),
            border: Border.all(
              color: isSelected
                  ? AppColors.actionGreen
                  : AppColors.sageGreen.withValues(alpha: 0.65),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 13,
                  color: isSelected
                      ? AppColors.surfaceWhite
                      : AppColors.forestGreen,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: isSelected
                      ? AppColors.surfaceWhite
                      : AppColors.forestGreen,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Marker _buildUserLocationMarker(LatLng point) {
    return Marker(
      point: point,
      width: 28,
      height: 28,
      child: Semantics(
        label: 'Lokasi perangkat Anda',
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.skyBlue.withValues(alpha: 0.24),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: AppColors.skyBlue,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.surfaceWhite,
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showNearbyPlantsBottomSheet(
    BuildContext context,
    List<PowerPlant> plants,
    int radiusMeters,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.58,
          minChildSize: 0.36,
          maxChildSize: 0.88,
          expand: false,
          builder: (ctx, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.offWhite,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppTheme.cardRadius),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.mintGreen,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.near_me_rounded,
                            color: AppColors.forestGreen,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pembangkit Terdekat',
                                style: AppTextStyles.subtitle,
                              ),
                              Text(
                                'Radius ${formatRadiusLabel(radiusMeters)} • ${plants.length} titik (terdekat dulu)',
                                style: AppTextStyles.caption,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Tutup daftar',
                          constraints: const BoxConstraints(
                            minWidth: 48,
                            minHeight: 48,
                          ),
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      padding: EdgeInsets.fromLTRB(
                        16,
                        12,
                        16,
                        24 + MediaQuery.viewPaddingOf(ctx).bottom,
                      ),
                      itemCount: plants.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (_, index) {
                        final plant = plants[index];
                        return PlantCard(
                          plant: plant,
                          onTap: () {
                            Navigator.of(sheetContext).pop();
                            _selectPlantOnMap(plant);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
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
                    if (plant.distanceMeters != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.offWhite,
                          borderRadius:
                              BorderRadius.circular(AppTheme.pillRadius),
                          border: Border.all(
                            color: AppColors.sageGreen.withValues(alpha: 0.65),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.near_me_rounded,
                              size: 10,
                              color: AppColors.forestGreen,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${(plant.distanceMeters! / 1000).toStringAsFixed(1)} km',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.forestGreen,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
                            ),
                          ],
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

class _NearbyListTriggerChip extends StatelessWidget {
  const _NearbyListTriggerChip({
    required this.count,
    required this.onTap,
  });

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Daftar $count pembangkit terdekat',
      child: Material(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppTheme.pillRadius),
        elevation: 2,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.pillRadius),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.pillRadius),
              border: Border.all(
                color: AppColors.actionGreen.withValues(alpha: 0.45),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.format_list_bulleted_rounded,
                  size: 18,
                  color: AppColors.actionGreen,
                ),
                const SizedBox(width: 6),
                Text(
                  'Daftar ($count)',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.forestGreen,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusFilterButton extends StatelessWidget {
  const _StatusFilterButton({
    required this.activeCount,
    required this.isDefault,
    required this.onTap,
  });

  final int activeCount;
  final bool isDefault;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Filter status operasional ($activeCount aktif)',
      child: Tooltip(
        message: 'Filter status pembangkit',
        child: Material(
          color: isDefault
              ? AppColors.surfaceWhite.withValues(alpha: 0.88)
              : AppColors.mintGreen,
          borderRadius: BorderRadius.circular(AppTheme.pillRadius),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppTheme.pillRadius),
            onTap: onTap,
            child: Container(
              constraints: const BoxConstraints(minWidth: 44, minHeight: 40),
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                border: Border.all(
                  color: isDefault
                      ? AppColors.divider
                      : AppColors.forestGreen.withValues(alpha: 0.45),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.tune_rounded,
                    size: 18,
                    color: AppColors.forestGreen,
                  ),
                  if (!isDefault) ...[
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.actionGreen,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$activeCount',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.surfaceWhite,
                          fontWeight: FontWeight.w700,
                          fontSize: 10.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

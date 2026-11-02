import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common/empty_view.dart';
import '../../../../core/widgets/common/error_view.dart';
import '../../../../core/widgets/common/loading_view.dart';
import '../../../../core/widgets/common/plant_card.dart';
import '../../../../services/location_service.dart';
import '../../../plants/presentation/providers/plants_providers.dart';

/// Halaman Pembangkit Terdekat (Nearby Plants) yang memanggil RPC PostGIS
/// `nearby_plants` berdasarkan koordinat GPS pengguna.
///
/// Menangani izin lokasi ditolak, layanan GPS nonaktif, dan hasil kosong
/// menggunakan `EmptyView` yang informatif.
class NearbyPlantsPage extends ConsumerWidget {
  const NearbyPlantsPage({super.key});

  static const List<(String, int)> _radiusOptions = [
    ('50 km', 50000),
    ('250 km', 250000),
    ('500 km', 500000),
    ('1.500 km', 1500000),
    ('Seluruh ID (3.500 km)', 3500000),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nearbyAsync = ref.watch(nearbyPlantsStateProvider);
    final selectedRadius = ref.watch(nearbyRadiusMetersProvider);
    final locationService = ref.watch(locationServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pembangkit Terdekat'),
        actions: [
          IconButton(
            tooltip: 'Perbarui Lokasi',
            onPressed: () => ref.invalidate(nearbyPlantsStateProvider),
            icon: const Icon(Icons.my_location_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildRadiusSelector(ref, selectedRadius),
            const Divider(height: 1),
            Expanded(
              child: nearbyAsync.when(
                loading: () => const LoadingView(
                  message:
                      'Mendeteksi lokasi Anda dan mencari pembangkit terdekat...',
                ),
                error: (error, _) => ErrorView(
                  message: error.toString(),
                  onRetry: () => ref.invalidate(nearbyPlantsStateProvider),
                ),
                data: (state) {
                  final loc = state.locationResult;

                  // 1. GPS / layanan lokasi mati
                  if (loc.accessState == LocationAccessState.serviceDisabled) {
                    return EmptyView(
                      icon: Icons.location_disabled_rounded,
                      title: 'Layanan Lokasi (GPS) Nonaktif',
                      description:
                          loc.message ??
                          'Aktifkan layanan lokasi perangkat untuk menemukan pembangkit terdekat.',
                      actionLabel: 'Buka Pengaturan Lokasi',
                      onAction: () async {
                        await locationService.openLocationSettings();
                        ref.invalidate(nearbyPlantsStateProvider);
                      },
                    );
                  }

                  // 2. Izin lokasi ditolak
                  if (loc.accessState == LocationAccessState.permissionDenied) {
                    return EmptyView(
                      icon: Icons.location_off_outlined,
                      title: 'Izin Lokasi Ditolak',
                      description:
                          loc.message ??
                          'EduEarth memerlukan izin lokasi untuk mengurutkan jarak pembangkit terdekat.',
                      actionLabel: 'Minta Izin Lokasi Lagi',
                      onAction: () => ref.invalidate(nearbyPlantsStateProvider),
                    );
                  }

                  // 3. Izin lokasi ditolak permanen
                  if (loc.accessState ==
                      LocationAccessState.permissionDeniedForever) {
                    return EmptyView(
                      icon: Icons.settings_outlined,
                      title: 'Izin Lokasi Diblokir Permanen',
                      description:
                          loc.message ??
                          'Silakan aktifkan izin lokasi untuk EduEarth di pengaturan aplikasi.',
                      actionLabel: 'Buka Pengaturan Aplikasi',
                      onAction: () async {
                        await locationService.openAppSettings();
                        ref.invalidate(nearbyPlantsStateProvider);
                      },
                    );
                  }

                  // 4. Lokasi ditemukan tetapi tidak ada pembangkit dalam radius
                  if (state.plants.isEmpty) {
                    return EmptyView(
                      icon: Icons.radar_rounded,
                      title: 'Tidak Ada Pembangkit dalam Radius Ini',
                      description:
                          'Belum ditemukan pembangkit terpublikasi dalam radius ${(selectedRadius / 1000).round()} km dari lokasi Anda.',
                      actionLabel: 'Perluas Radius ke 3.500 km',
                      onAction: () {
                        ref
                            .read(nearbyRadiusMetersProvider.notifier)
                            .setRadiusMeters(3500000);
                      },
                    );
                  }

                  final pos = loc.position!;
                  return RefreshIndicator(
                    color: AppColors.freshGreen,
                    onRefresh: () async {
                      ref.invalidate(nearbyPlantsStateProvider);
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: state.plants.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.mintGreen,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.gps_fixed_rounded,
                                    size: 18,
                                    color: AppColors.forestGreen,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Lokasi Anda: ${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)} • Ditemukan ${state.plants.length} titik',
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.forestGreen,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        final plant = state.plants[index - 1];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: PlantCard(
                            plant: plant,
                            onTap: () => context.push('/plants/${plant.id}'),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadiusSelector(WidgetRef ref, int selectedRadius) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Radius Pencarian Jarak (PostGIS ST_DWithin):',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _radiusOptions.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final option = _radiusOptions[index];
                final isSelected = selectedRadius == option.$2;

                return ChoiceChip(
                  label: Text(option.$1),
                  selected: isSelected,
                  selectedColor: AppColors.mintGreen,
                  labelStyle: AppTextStyles.caption.copyWith(
                    color: AppColors.forestGreen,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                  ),
                  onSelected: (_) {
                    ref
                        .read(nearbyRadiusMetersProvider.notifier)
                        .setRadiusMeters(option.$2);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}


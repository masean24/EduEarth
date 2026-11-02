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
import '../../../../core/widgets/common/error_view.dart';
import '../../../../core/widgets/common/loading_view.dart';
import '../../../../core/widgets/common/primary_button.dart';
import '../../../../core/widgets/common/secondary_button.dart';
import '../../../../models/power_plant.dart';
import '../../../../routes/route_names.dart';
import '../../../../services/external_map_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../bookmark/presentation/providers/bookmark_providers.dart';
import '../providers/plants_providers.dart';

/// Halaman Detail Pembangkit Energi (Plant Detail).
///
/// Menampilkan atribut lengkap pembangkit, penanda data demo (bila `isDemo`),
/// peta pratinjau OpenStreetMap, tautan sumber (`source_url`), tombol toggle
/// Bookmark, dan tombol aksi "Buka di Google Maps" via `url_launcher`.
class PlantDetailPage extends ConsumerWidget {
  const PlantDetailPage({
    super.key,
    required this.plantId,
  });

  final String plantId;

  Future<void> _openGoogleMaps(
    BuildContext context,
    ExternalMapService externalMapService,
    PowerPlant plant,
  ) async {
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
            'Tidak dapat membuka Google Maps. Pastikan browser atau aplikasi peta tersedia.',
          ),
        ),
      );
    }
  }

  Future<void> _openSourceUrl(
    BuildContext context,
    ExternalMapService externalMapService,
    String sourceUrl,
  ) async {
    final launched = await externalMapService.openExternalUrl(sourceUrl);
    if (!context.mounted) return;
    if (!launched) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tautan sumber referensi tidak dapat dibuka.'),
        ),
      );
    }
  }

  Future<void> _handleToggleBookmark(
    BuildContext context,
    WidgetRef ref,
    String id,
    bool currentlyBookmarked,
  ) async {
    final isAuthenticated = ref.read(isAuthenticatedProvider);
    if (!isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan masuk (login) untuk menyimpan bookmark.'),
        ),
      );
      context.push(RouteNames.loginPath);
      return;
    }

    final success = await ref
        .read(bookmarkControllerProvider.notifier)
        .togglePlant(id);

    if (!context.mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            currentlyBookmarked
                ? 'Pembangkit dihapus dari Bookmark.'
                : 'Pembangkit disimpan ke Bookmark.',
          ),
        ),
      );
    } else {
      final err = ref.read(bookmarkControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err?.toString() ?? 'Gagal memperbarui bookmark.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plantAsync = ref.watch(plantDetailProvider(plantId));
    final externalMapService = ref.watch(externalMapServiceProvider);
    final isBookmarked = ref.watch(isPlantBookmarkedProvider(plantId));
    final bookmarkController = ref.watch(bookmarkControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Pembangkit'),
        actions: [
          if (plantAsync.asData != null)
            IconButton(
              tooltip: isBookmarked
                  ? 'Hapus dari Bookmark'
                  : 'Simpan ke Bookmark',
              onPressed: bookmarkController.isLoading
                  ? null
                  : () => _handleToggleBookmark(
                        context,
                        ref,
                        plantId,
                        isBookmarked,
                      ),
              icon: Icon(
                isBookmarked
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                color:
                    isBookmarked ? AppColors.freshGreen : AppColors.forestGreen,
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: plantAsync.when(
          loading: () => const LoadingView(
            message: 'Memuat informasi pembangkit...',
          ),
          error: (error, _) => ErrorView(
            message: error.toString(),
            onRetry: () => ref.invalidate(plantDetailProvider(plantId)),
          ),
          data: (plant) {
            final categoryColor = AppColors.colorForCategorySlug(
              plant.categorySlug ?? '',
            );

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                if (plant.isDemo) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.warmYellow.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.warmYellow),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.science_outlined,
                          color: AppColors.forestGreen,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Baris ini adalah DATA DEMO FIKTIF (is_demo = true) untuk pengujian UI dan bukan koordinat pembangkit nyata.',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.forestGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: categoryColor.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(
                          AppTheme.pillRadius,
                        ),
                        border: Border.all(color: categoryColor),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            iconForCategorySlug(plant.categorySlug),
                            size: 16,
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
                  ],
                ),
                const SizedBox(height: 12),
                Text(plant.name, style: AppTextStyles.display),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        plant.locationLabel,
                        style: AppTextStyles.subtitle.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildMiniMapCard(plant, categoryColor),
                const SizedBox(height: 20),
                Text('Deskripsi Pembangkit', style: AppTextStyles.title),
                const SizedBox(height: 8),
                Text(plant.description, style: AppTextStyles.body),
                const SizedBox(height: 20),
                Text('Spesifikasi & Data Teknis', style: AppTextStyles.title),
                const SizedBox(height: 12),
                _buildSpecificationCard(plant),
                const SizedBox(height: 20),
                Text('Sumber & Verifikasi Data', style: AppTextStyles.title),
                const SizedBox(height: 12),
                _buildSourceVerificationCard(
                  context: context,
                  externalMapService: externalMapService,
                  plant: plant,
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: 'Buka di Google Maps',
                  icon: Icons.open_in_new_rounded,
                  onPressed: () =>
                      _openGoogleMaps(context, externalMapService, plant),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMiniMapCard(PowerPlant plant, Color categoryColor) {
    final point = LatLng(plant.latitude, plant.longitude);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          border: Border.all(color: AppColors.divider),
        ),
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: point,
                initialZoom: 8.5,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: AppConstants.osmTileUrl,
                  userAgentPackageName: AppConstants.appPackageName,
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: point,
                      width: 44,
                      height: 44,
                      child: Container(
                        decoration: BoxDecoration(
                          color: categoryColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.surfaceWhite,
                            width: 2.5,
                          ),
                        ),
                        child: Icon(
                          iconForCategorySlug(plant.categorySlug),
                          color: AppColors.forestGreen,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Positioned(
              right: 8,
              bottom: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(6),
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
    );
  }

  Widget _buildSpecificationCard(PowerPlant plant) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          _SpecRow(
            label: 'Kapasitas Terpasang',
            value: plant.capacityMw != null
                ? '${plant.capacityMw!.toStringAsFixed(2)} MW'
                : 'Belum diketahui / tidak dicantumkan',
          ),
          const Divider(height: 20),
          _SpecRow(
            label: 'Status Operasional',
            value: plant.operationalStatusLabel,
          ),
          const Divider(height: 20),
          _SpecRow(
            label: 'Pengelola / Operator',
            value: plant.operatorName?.trim().isNotEmpty == true
                ? plant.operatorName!
                : 'Belum diketahui / tidak dicantumkan',
          ),
          const Divider(height: 20),
          _SpecRow(
            label: 'Koordinat (Lat, Lng)',
            value:
                '${plant.latitude.toStringAsFixed(4)}, ${plant.longitude.toStringAsFixed(4)}',
          ),
        ],
      ),
    );
  }

  Widget _buildSourceVerificationCard({
    required BuildContext context,
    required ExternalMapService externalMapService,
    required PowerPlant plant,
  }) {
    final hasSource =
        plant.sourceUrl != null && plant.sourceUrl!.trim().isNotEmpty;
    final verifiedDate = plant.verifiedAt != null
        ? '${plant.verifiedAt!.day.toString().padLeft(2, '0')}-${plant.verifiedAt!.month.toString().padLeft(2, '0')}-${plant.verifiedAt!.year}'
        : 'Belum tercatat';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.mintGreen.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppColors.sageGreen),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.verified_outlined,
                size: 18,
                color: AppColors.forestGreen,
              ),
              const SizedBox(width: 8),
              Text(
                'Tanggal Verifikasi: $verifiedDate',
                style: AppTextStyles.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            hasSource
                ? 'Sumber referensi: ${plant.sourceUrl}'
                : 'Sumber referensi resmi belum dilampirkan (baris pengembangan / demo).',
            style: AppTextStyles.caption,
          ),
          if (hasSource) ...[
            const SizedBox(height: 12),
            SecondaryButton(
              label: 'Buka Tautan Sumber Data',
              icon: Icons.link_rounded,
              onPressed: () => _openSourceUrl(
                context,
                externalMapService,
                plant.sourceUrl!,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SpecRow extends StatelessWidget {
  const _SpecRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(label, style: AppTextStyles.caption),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

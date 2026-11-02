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
import '../../../../core/widgets/common/screen_header.dart';
import '../../../../core/widgets/common/secondary_button.dart';
import '../../../../core/widgets/common/soft_image_placeholder.dart';
import '../../../../models/power_plant.dart';
import '../../../../routes/route_names.dart';
import '../../../../services/external_map_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../bookmark/presentation/providers/bookmark_providers.dart';
import '../providers/plants_providers.dart';

/// Halaman Detail Pembangkit Energi (Plant Detail).
///
/// Menampilkan:
/// - Hero card visual pembangkit beserta lencana kategori, status, dan penanda `DATA DEMO`
/// - Grid 2x2 ringkasan spesifikasi utama (Kapasitas, Status, Jenis Energi, Operator)
/// - Kartu Deskripsi Pembangkit & edukasi singkat cara kerja kategori energi terkait
/// - Peta lokasi interaktif OpenStreetMap dengan koordinat presisi
/// - Kartu Sumber & Verifikasi Data serta tombol aksi "Buka di Google Maps"
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

  static String _educationalNoteForCategory(String? slug) {
    switch (slug?.toLowerCase().trim()) {
      case 'solar':
        return 'PLTS mengubah radiasi sinar matahari menjadi arus listrik searah (DC) menggunakan sel fotovoltaik, lalu dikonversi menjadi arus bolak-balik (AC) melalui inverter.';
      case 'hydro':
        return 'PLTA memanfaatkan energi potensial dan kinetik aliran atau terjunan air untuk memutar turbin yang terhubung dengan generator listrik.';
      case 'wind':
        return 'PLTB menangkap hembusan energi kinetik angin menggunakan bilah turbin aerodinamis untuk memutar rotor generator penghasil listrik.';
      case 'geothermal':
        return 'PLTP memanfaatkan uap panas bumi dari reservoar bawah permukaan untuk menggerakkan turbin uap secara berkelanjutan (baseload) tanpa bergantung cuaca.';
      case 'bioenergy':
        return 'Pembangkit Bioenergi (PLTBm/PLTBg) mengonversi bahan organik (biomassa atau biogas) menjadi energi panas dan mekanik untuk menghasilkan listrik.';
      default:
        return 'Pembangkit energi terbarukan memanfaatkan sumber daya alam yang dapat pulih secara berkelanjutan dengan emisi karbon yang jauh lebih rendah.';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plantAsync = ref.watch(plantDetailProvider(plantId));
    final externalMapService = ref.watch(externalMapServiceProvider);
    final isBookmarked = ref.watch(isPlantBookmarkedProvider(plantId));
    final bookmarkController = ref.watch(bookmarkControllerProvider);

    return Scaffold(
      appBar: ScreenHeaderBar(
        title: 'Detail Pembangkit',
        subtitle: 'Informasi teknis & sumber verifikasi',
        actions: [
          if (plantAsync.asData != null)
            ScreenHeaderAction(
              tooltip: isBookmarked
                  ? 'Hapus dari Bookmark'
                  : 'Simpan ke Bookmark',
              icon: isBookmarked
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
              iconColor:
                  isBookmarked ? AppColors.freshGreen : AppColors.forestGreen,
              onTap: bookmarkController.isLoading
                  ? null
                  : () => _handleToggleBookmark(
                        context,
                        ref,
                        plantId,
                        isBookmarked,
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
            final slug = plant.categorySlug ?? '';
            final categoryColor = AppColors.colorForCategorySlug(slug);

            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                    children: [
                      // 1. Hero Visual Card
                      _buildHeroCard(plant, categoryColor),
                      const SizedBox(height: 16),

                      // 2. Grid 2x2 Ringkasan Spesifikasi Utama
                      _buildQuickMetricsGrid(plant, categoryColor),
                      const SizedBox(height: 20),

                      // 3. Kartu Deskripsi & Konteks Edukasi Kategori
                      _buildDescriptionAndEducationCard(
                        context: context,
                        plant: plant,
                        categoryColor: categoryColor,
                      ),
                      const SizedBox(height: 20),

                      // 4. Peta Lokasi Geografis & Koordinat
                      _buildLocationMapSection(plant, categoryColor),
                      const SizedBox(height: 20),

                      // 5. Kartu Sumber & Verifikasi Data
                      _buildSourceVerificationCard(
                        context: context,
                        externalMapService: externalMapService,
                        plant: plant,
                      ),
                    ],
                  ),
                ),

                // 6. Sticky Bottom Action Bar
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceWhite,
                    border: Border(top: BorderSide(color: AppColors.divider)),
                  ),
                  child: PrimaryButton(
                    label: 'Buka Lokasi di Google Maps',
                    icon: Icons.open_in_new_rounded,
                    onPressed: () =>
                        _openGoogleMaps(context, externalMapService, plant),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeroCard(PowerPlant plant, Color categoryColor) {
    final slug = plant.categorySlug ?? '';
    final softBg = AppColors.softBackgroundForCategorySlug(slug);
    final categoryLabel = shortDisplayLabelForSlug(
      slug,
      plant.categoryName ?? 'Energi Bersih',
    );

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 148,
            child: Stack(
              fit: StackFit.expand,
              children: [
                SoftImagePlaceholder(
                  borderRadius: 0,
                  networkImageUrl: plant.imageUrl,
                  assetPath: assetForCategorySlug(slug),
                  backgroundColor: softBg,
                  fallbackIcon: iconForCategorySlug(slug),
                  iconColor: AppColors.forestGreen.withValues(alpha: 0.28),
                  iconSize: 72,
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.forestGreen.withValues(alpha: 0.05),
                        AppColors.forestGreen.withValues(alpha: 0.55),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceWhite.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(
                            AppTheme.pillRadius,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              iconForCategorySlug(slug),
                              size: 15,
                              color: AppColors.forestGreen,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$categoryLabel (${plant.categoryShortCode ?? '-'})',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.forestGreen,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      if (plant.isDemo)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.warmYellow,
                            borderRadius: BorderRadius.circular(
                              AppTheme.pillRadius,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.science_outlined,
                                size: 13,
                                color: AppColors.forestGreen,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'DATA DEMO',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.forestGreen,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plant.name,
                        style: AppTextStyles.title.copyWith(
                          color: AppColors.surfaceWhite,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            size: 15,
                            color: AppColors.mintGreen,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              plant.locationLabel,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.mintGreen,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (plant.isDemo)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              color: AppColors.warmYellow.withValues(alpha: 0.18),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: AppColors.forestGreen,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Titik ini adalah data simulasi (is_demo = true) untuk pengujian fitur peta dan bukan lokasi pembangkit nyata.',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.forestGreen,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickMetricsGrid(PowerPlant plant, Color categoryColor) {
    final capacityValue = plant.capacityMw != null
        ? '${plant.capacityMw!.toStringAsFixed(1)} MW'
        : 'Belum tercatat';
    final operatorValue = plant.operatorName?.trim().isNotEmpty == true
        ? plant.operatorName!
        : 'Belum tercatat';

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                icon: Icons.bolt_rounded,
                iconBg: const Color(0xFFFEF9C3),
                iconColor: const Color(0xFFD97706),
                label: 'Kapasitas Terpasang',
                value: capacityValue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricTile(
                icon: Icons.verified_user_outlined,
                iconBg: AppColors.mintGreen,
                iconColor: AppColors.forestGreen,
                label: 'Status Operasional',
                value: plant.operationalStatusLabel,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                icon: Icons.apartment_rounded,
                iconBg: const Color(0xFFE0F2FE),
                iconColor: AppColors.skyBlue,
                label: 'Pengelola / Operator',
                value: operatorValue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricTile(
                icon: Icons.my_location_rounded,
                iconBg: AppColors.offWhite,
                iconColor: AppColors.forestGreen,
                label: 'Koordinat Peta',
                value:
                    '${plant.latitude.toStringAsFixed(2)}°, ${plant.longitude.toStringAsFixed(2)}°',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDescriptionAndEducationCard({
    required BuildContext context,
    required PowerPlant plant,
    required Color categoryColor,
  }) {
    final slug = plant.categorySlug ?? '';
    final shortLabel = shortDisplayLabelForSlug(
      slug,
      plant.categoryName ?? 'Energi Terbarukan',
    );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.article_outlined,
                size: 19,
                color: AppColors.forestGreen,
              ),
              const SizedBox(width: 8),
              Text('Deskripsi Pembangkit', style: AppTextStyles.subtitle),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            plant.description,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.mintGreen.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.sageGreen),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      iconForCategorySlug(slug),
                      size: 18,
                      color: AppColors.forestGreen,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Cara Kerja Singkat Energi $shortLabel',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.forestGreen,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _educationalNoteForCategory(slug),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.forestGreen,
                    height: 1.45,
                  ),
                ),
                if (slug.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => context.push('/learning/category/$slug'),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Pelajari Materi $shortLabel Selengkapnya',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.forestGreen,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: AppColors.forestGreen,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationMapSection(PowerPlant plant, Color categoryColor) {
    final point = LatLng(plant.latitude, plant.longitude);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                const Icon(
                  Icons.map_outlined,
                  size: 19,
                  color: AppColors.forestGreen,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Peta Lokasi Pembangkit',
                    style: AppTextStyles.subtitle,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.offWhite,
                    borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Text(
                    '${plant.latitude.toStringAsFixed(4)}, ${plant.longitude.toStringAsFixed(4)}',
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 185,
            child: Stack(
              children: [
                FlutterMap(
                  options: MapOptions(
                    initialCenter: point,
                    initialZoom: 6.2,
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
                          width: 46,
                          height: 46,
                          child: Container(
                            decoration: BoxDecoration(
                              color: categoryColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.surfaceWhite,
                                width: 2.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.forestGreen.withValues(
                                    alpha: 0.25,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Icon(
                              iconForCategorySlug(plant.categorySlug),
                              color: plant.categorySlug == 'solar'
                                  ? AppColors.forestGreen
                                  : AppColors.surfaceWhite,
                              size: 22,
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWhite.withValues(alpha: 0.88),
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
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: AppColors.mintGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified_outlined,
                  size: 18,
                  color: AppColors.forestGreen,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sumber & Verifikasi Data',
                      style: AppTextStyles.subtitle.copyWith(fontSize: 15),
                    ),
                    Text(
                      'Tanggal Verifikasi: $verifiedDate',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            hasSource
                ? 'Sumber referensi: ${plant.sourceUrl}'
                : 'Sumber referensi resmi belum dilampirkan karena baris ini merupakan data simulasi pengembangan (demo).',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
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

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.forestGreen,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

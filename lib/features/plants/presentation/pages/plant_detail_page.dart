import 'dart:math' as math;

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
import '../../../achievement/presentation/providers/achievement_providers.dart';
import '../../../achievement/presentation/widgets/achievement_unlock_dialog.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../bookmark/presentation/providers/bookmark_providers.dart';
import '../providers/plants_providers.dart';

/// Halaman Detail Pembangkit Energi (Plant Detail).
class PlantDetailPage extends ConsumerWidget {
  const PlantDetailPage({
    super.key,
    required this.plantId,
  });

  final String plantId;

  Future<void> _openCoordinatesInGoogleMaps(
    BuildContext context,
    ExternalMapService externalMapService,
    PowerPlant plant,
  ) async {
    final launched = await externalMapService.openCoordinatesInGoogleMaps(
      latitude: plant.latitude,
      longitude: plant.longitude,
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

  Future<void> _searchPlaceInGoogleMaps(
    BuildContext context,
    ExternalMapService externalMapService,
    PowerPlant plant,
  ) async {
    final launched = await externalMapService.searchPlaceInGoogleMaps(
      name: plant.name,
      city: plant.city,
      province: plant.province,
    );

    if (!context.mounted) return;
    if (!launched) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tidak dapat membuka pencarian Google Maps.',
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
      if (!currentlyBookmarked) {
        try {
          final award = await ref
              .read(achievementRepositoryProvider)
              .evaluateAchievements();
          ref.invalidate(achievementsListProvider);
          if (context.mounted && award.newlyAwardedTitles.isNotEmpty) {
            await showAchievementUnlockDialog(
              context,
              badgeTitles: award.newlyAwardedTitles,
            );
          }
        } catch (_) {}
      }
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
        subtitle: 'Informasi teknis & atribusi sumber data',
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

                      // 5. Kartu Sumber, Tanggal Data, & Catatan Metodologi
                      _buildSourceVerificationCard(
                        context: context,
                        externalMapService: externalMapService,
                        plant: plant,
                      ),
                    ],
                  ),
                ),

                // 6. Sticky Bottom Action Bar (2 Tombol Google Maps sesuai presisi koordinat)
                _buildBottomGoogleMapsBar(
                  context: context,
                  externalMapService: externalMapService,
                  plant: plant,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBottomGoogleMapsBar({
    required BuildContext context,
    required ExternalMapService externalMapService,
    required PowerPlant plant,
  }) {
    final isApprox = plant.isApproximate;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isApprox) ...[
            PrimaryButton(
              label: 'Cari di Google Maps',
              icon: Icons.travel_explore_rounded,
              onPressed: () =>
                  _searchPlaceInGoogleMaps(context, externalMapService, plant),
            ),
            const SizedBox(height: 8),
            SecondaryButton(
              label: 'Lihat titik di Google Maps',
              icon: Icons.pin_drop_outlined,
              onPressed: () => _openCoordinatesInGoogleMaps(
                context,
                externalMapService,
                plant,
              ),
            ),
          ] else ...[
            PrimaryButton(
              label: 'Lihat titik di Google Maps',
              icon: Icons.pin_drop_outlined,
              onPressed: () => _openCoordinatesInGoogleMaps(
                context,
                externalMapService,
                plant,
              ),
            ),
            const SizedBox(height: 8),
            SecondaryButton(
              label: 'Cari di Google Maps',
              icon: Icons.travel_explore_rounded,
              onPressed: () =>
                  _searchPlaceInGoogleMaps(context, externalMapService, plant),
            ),
          ],
        ],
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
    final hasNetworkImage =
        plant.imageUrl != null && plant.imageUrl!.trim().isNotEmpty;

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
            height: 174,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (hasNetworkImage)
                  SoftImagePlaceholder(
                    borderRadius: 0,
                    networkImageUrl: plant.imageUrl,
                    assetPath: assetForCategorySlug(slug),
                    backgroundColor: softBg,
                    fallbackIcon: iconForCategorySlug(slug),
                    iconColor: AppColors.forestGreen.withValues(alpha: 0.28),
                    iconSize: 72,
                  )
                else
                  _AnimatedCategorySceneBanner(
                    categorySlug: slug,
                    shortCode: plant.categoryShortCode,
                  ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.45, 1.0],
                      colors: [
                        Colors.black.withValues(alpha: 0.08),
                        Colors.transparent,
                        AppColors.forestGreen.withValues(alpha: 0.78),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    alignment: WrapAlignment.spaceBetween,
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
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (plant.isApproximate)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(
                                  AppTheme.pillRadius,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.location_searching_rounded,
                                    size: 13,
                                    color: Color(0xFFB45309),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Lokasi perkiraan',
                                    style: AppTextStyles.caption.copyWith(
                                      color: const Color(0xFFB45309),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 10.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (plant.isDemo) ...[
                            const SizedBox(width: 6),
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
          if (plant.isApproximate)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              color: const Color(0xFFFEF3C7).withValues(alpha: 0.65),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: Color(0xFFB45309),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Lokasi perkiraan: koordinat titik ini mewakili perkiraan administratif / wilayah sekitar dan bukan titik tapak presisi.',
                      style: AppTextStyles.caption.copyWith(
                        color: const Color(0xFF92400E),
                        fontSize: 11.5,
                      ),
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
        ? '${plant.capacityMw!.toStringAsFixed(2)} MW'
        : 'Belum tercatat';
    final operatorValue = plant.operatorName?.trim().isNotEmpty == true
        ? plant.operatorName!
        : 'Belum tercatat';
    final coordLabel =
        plant.isApproximate ? 'Koordinat (Lokasi perkiraan)' : 'Koordinat Peta';

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                icon: Icons.bolt_rounded,
                iconBg: const Color(0xFFFEF9C3),
                iconColor: const Color(0xFFD97706),
                label: 'Kapasitas terpasang (menurut sumber)',
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
                icon: plant.isApproximate
                    ? Icons.location_searching_rounded
                    : Icons.my_location_rounded,
                iconBg: plant.isApproximate
                    ? const Color(0xFFFEF3C7)
                    : AppColors.offWhite,
                iconColor: plant.isApproximate
                    ? const Color(0xFFB45309)
                    : AppColors.forestGreen,
                label: coordLabel,
                value:
                    '${plant.latitude.toStringAsFixed(4)}°, ${plant.longitude.toStringAsFixed(4)}°',
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
    final descText = (plant.description != null &&
            plant.description!.trim().isNotEmpty)
        ? plant.description!
        : 'Deskripsi ringkas pembangkit belum tercantum pada sumber data.';

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
            descText,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1),
          ),
          _InteractiveEnergyFlowSection(
            categorySlug: slug,
            shortLabel: shortLabel,
            summaryNote: _educationalNoteForCategory(slug),
            onLearnMore: slug.isNotEmpty
                ? () => context.push('/learning/category/$slug')
                : null,
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
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.map_outlined,
                      size: 19,
                      color: AppColors.forestGreen,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Peta Lokasi Pembangkit',
                      style: AppTextStyles.subtitle,
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (plant.isApproximate) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius:
                              BorderRadius.circular(AppTheme.pillRadius),
                          border: Border.all(
                            color: const Color(0xFFF59E0B).withValues(
                              alpha: 0.45,
                            ),
                          ),
                        ),
                        child: Text(
                          'Lokasi perkiraan',
                          style: AppTextStyles.caption.copyWith(
                            color: const Color(0xFFB45309),
                            fontWeight: FontWeight.w700,
                            fontSize: 10.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.offWhite,
                        borderRadius:
                            BorderRadius.circular(AppTheme.pillRadius),
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
    final hasDataAsOf =
        plant.dataAsOf != null && plant.dataAsOf!.trim().isNotEmpty;
    final hasSourceNotes =
        plant.sourceNotes != null && plant.sourceNotes!.trim().isNotEmpty;

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
                  Icons.source_outlined,
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
                      'Sumber & Atribusi Data',
                      style: AppTextStyles.subtitle.copyWith(fontSize: 15),
                    ),
                    Text(
                      hasDataAsOf
                          ? 'Tanggal Data (data_as_of): ${plant.dataAsOf}'
                          : 'Tanggal Data: Belum tercatat',
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            hasSource
                ? 'Tautan sumber: ${plant.sourceUrl}'
                : 'Sumber referensi belum dilampirkan pada baris ini.',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          if (hasSourceNotes) ...[
            const SizedBox(height: 10),
            Theme(
              data: Theme.of(context).copyWith(
                dividerColor: Colors.transparent,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.offWhite,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.divider),
                ),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 2,
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  leading: const Icon(
                    Icons.notes_rounded,
                    size: 18,
                    color: AppColors.forestGreen,
                  ),
                  title: Text(
                    'Catatan Sumber (source_notes)',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.forestGreen,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        plant.sourceNotes!,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textPrimary,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (hasSource) ...[
            const SizedBox(height: 12),
            SecondaryButton(
              label: 'Lihat Sumber',
              icon: Icons.open_in_new_rounded,
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
              fontSize: 11,
              height: 1.25,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.forestGreen,
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Banner visual ilustrasi berlapis dengan animasi halus per kategori energi
/// ketika `plant.imageUrl` belum tersedia di database.
class _AnimatedCategorySceneBanner extends StatefulWidget {
  const _AnimatedCategorySceneBanner({
    required this.categorySlug,
    this.shortCode,
  });

  final String categorySlug;
  final String? shortCode;

  @override
  State<_AnimatedCategorySceneBanner> createState() =>
      _AnimatedCategorySceneBannerState();
}

class _AnimatedCategorySceneBannerState
    extends State<_AnimatedCategorySceneBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Color> _gradientForSlug(String slug) {
    switch (slug.toLowerCase().trim()) {
      case 'solar':
        return const [
          Color(0xFF0F5132),
          Color(0xFF1E7E48),
          Color(0xFFD97706),
        ];
      case 'hydro':
        return const [
          Color(0xFF0C4A6E),
          Color(0xFF0284C7),
          Color(0xFF15803D),
        ];
      case 'wind':
        return const [
          Color(0xFF115E59),
          Color(0xFF0D9488),
          Color(0xFF22C55E),
        ];
      case 'geothermal':
        return const [
          Color(0xFF7C2D12),
          Color(0xFFC2410C),
          Color(0xFF14532D),
        ];
      case 'bioenergy':
      default:
        return const [
          Color(0xFF14532D),
          Color(0xFF15803D),
          Color(0xFF4ADE80),
        ];
    }
  }

  IconData _secondarySchematicIcon(String slug) {
    switch (slug.toLowerCase().trim()) {
      case 'solar':
        return Icons.solar_power_rounded;
      case 'hydro':
        return Icons.waves_rounded;
      case 'wind':
        return Icons.wind_power_rounded;
      case 'geothermal':
        return Icons.terrain_rounded;
      case 'bioenergy':
      default:
        return Icons.compost_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final slug = widget.categorySlug.toLowerCase().trim();
    final colors = _gradientForSlug(slug);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          final pulse = 0.94 + (0.08 * math.sin(t * 2 * math.pi));
          final angle = t * 2 * math.pi;

          return Stack(
            fit: StackFit.expand,
            children: [
              // Lingkaran gelombang dekoratif di kanan
              Positioned(
                right: -28,
                top: -18,
                child: Transform.scale(
                  scale: pulse,
                  child: Container(
                    width: 170,
                    height: 170,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.08),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.14),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 12,
                top: 22,
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.22),
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Cincin putar halus
                      Transform.rotate(
                        angle: slug == 'wind' || slug == 'solar'
                            ? angle
                            : angle * 0.5,
                        child: Icon(
                          slug == 'wind'
                              ? Icons.cyclone_rounded
                              : slug == 'solar'
                                  ? Icons.wb_sunny_outlined
                                  : Icons.autorenew_rounded,
                          size: 74,
                          color: Colors.white.withValues(alpha: 0.22),
                        ),
                      ),
                      Transform.scale(
                        scale: pulse,
                        child: Icon(
                          _secondarySchematicIcon(slug),
                          size: 40,
                          color: Colors.white.withValues(alpha: 0.92),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Siluet bukit halus di bagian bawah
              Positioned(
                left: -30,
                right: -30,
                bottom: -42,
                child: Container(
                  height: 76,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.14),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.elliptical(260, 70),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Bagian interaktif 3 tahap alur konversi energi pembangkit.
class _InteractiveEnergyFlowSection extends StatefulWidget {
  const _InteractiveEnergyFlowSection({
    required this.categorySlug,
    required this.shortLabel,
    required this.summaryNote,
    this.onLearnMore,
  });

  final String categorySlug;
  final String shortLabel;
  final String summaryNote;
  final VoidCallback? onLearnMore;

  @override
  State<_InteractiveEnergyFlowSection> createState() =>
      _InteractiveEnergyFlowSectionState();
}

class _InteractiveEnergyFlowSectionState
    extends State<_InteractiveEnergyFlowSection> {
  int _selectedStep = 0;

  List<({String title, IconData icon, String detail})> _stepsForSlug(
    String slug,
  ) {
    switch (slug.toLowerCase().trim()) {
      case 'solar':
        return const [
          (
            title: '1. Tangkap Sinar',
            icon: Icons.wb_sunny_rounded,
            detail:
                'Panel fotovoltaik menyerap foton radiasi matahari dan membangkitkan arus listrik searah (DC) pada sel semikonduktor silikon.',
          ),
          (
            title: '2. Konversi Inverter',
            icon: Icons.electrical_services_rounded,
            detail:
                'Inverter mengubah arus DC dari rangkaian modul surya menjadi arus bolak-balik (AC) yang sinkron dengan frekuensi jaringan.',
          ),
          (
            title: '3. Saluran Grid',
            icon: Icons.bolt_rounded,
            detail:
                'Tegangan dinaikkan melalui transformator step-up lalu disalurkan ke jaringan listrik PLN untuk rumah dan industri.',
          ),
        ];
      case 'hydro':
        return const [
          (
            title: '1. Aliran Air',
            icon: Icons.water_drop_rounded,
            detail:
                'Air dari waduk atau bendungan dialirkan melalui pipa pesat (penstock) untuk mengubah energi potensial gravitasi menjadi energi kinetik.',
          ),
          (
            title: '2. Putaran Turbin',
            icon: Icons.settings_suggest_rounded,
            detail:
                'Dorongan air bertekanan tinggi memutar sudu turbin air yang terhubung langsung pada poros generator.',
          ),
          (
            title: '3. Induksi Listrik',
            icon: Icons.bolt_rounded,
            detail:
                'Generator mengubah energi mekanik putaran menjadi energi listrik AC ramah lingkungan dan air dikembalikan ke daerah aliran sungai.',
          ),
        ];
      case 'wind':
        return const [
          (
            title: '1. Hembusan Angin',
            icon: Icons.air_rounded,
            detail:
                'Bilah rotor aerodinamis menangkap energi kinetik angin pada ketinggian menara dan mulai berputar mengikuti arah angin.',
          ),
          (
            title: '2. Nacelle & Generator',
            icon: Icons.wind_power_rounded,
            detail:
                'Poros di dalam nacelle memutar generator (baik melalui gearbox maupun direct-drive) untuk menghasilkan energi listrik.',
          ),
          (
            title: '3. Gardu & Jaringan',
            icon: Icons.bolt_rounded,
            detail:
                'Listrik dari tiap menara turbin dikumpulkan di gardu induk pembangkit lalu diinjeksikan ke jaringan transmisi.',
          ),
        ];
      case 'geothermal':
        return const [
          (
            title: '1. Uap Panas Bumi',
            icon: Icons.local_fire_department_rounded,
            detail:
                'Sumur produksi mengalirkan fluida dan uap bersuhu tinggi dari reservoar geotermal di bawah permukaan bumi.',
          ),
          (
            title: '2. Turbin Uap',
            icon: Icons.settings_input_component_rounded,
            detail:
                'Pemisah uap (separator) mengalirkan uap bersih bertekanan untuk memutar turbin uap dan generator secara stabil 24 jam (baseload).',
          ),
          (
            title: '3. Injeksi Ulang',
            icon: Icons.recycling_rounded,
            detail:
                'Uap yang telah dikondensasi diinjeksikan kembali ke dalam sumur injeksi agar tekanan reservoar bumi tetap lestari.',
          ),
        ];
      case 'bioenergy':
      default:
        return const [
          (
            title: '1. Bahan Organik',
            icon: Icons.eco_rounded,
            detail:
                'Residu pertanian/perkebunan (cangkang sawit, sekam, kayu energi) atau limbah cair organik dikumpulkan sebagai bahan bakar terbarukan.',
          ),
          (
            title: '2. Termal / Biogas',
            icon: Icons.local_fire_department_rounded,
            detail:
                'Biomassa dibakar di boiler uap (PLTBm) atau difermentasi menjadi gas metana (PLTBg) untuk menggerakkan turbin/mesin gas.',
          ),
          (
            title: '3. Listrik Bersih',
            icon: Icons.bolt_rounded,
            detail:
                'Generator membangkitkan listrik sekaligus membantu pengelolaan limbah agroindustri secara sirkular.',
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final steps = _stepsForSlug(widget.categorySlug);
    final activeStep = steps[_selectedStep.clamp(0, steps.length - 1)];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.mintGreen.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.sageGreen),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                iconForCategorySlug(widget.categorySlug),
                size: 18,
                color: AppColors.forestGreen,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Skema Interaktif Cara Kerja Energi ${widget.shortLabel}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.forestGreen,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            widget.summaryNote,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.forestGreen,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          // 3 tombol tahapan interaktif
          Row(
            children: List.generate(steps.length, (index) {
              final step = steps[index];
              final isSelected = index == _selectedStep;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: index < steps.length - 1 ? 6 : 0,
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => setState(() => _selectedStep = index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.forestGreen
                            : AppColors.surfaceWhite,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.forestGreen
                              : AppColors.sageGreen.withValues(alpha: 0.7),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            step.icon,
                            size: 16,
                            color: isSelected
                                ? AppColors.surfaceWhite
                                : AppColors.forestGreen,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            step.title,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? AppColors.surfaceWhite
                                  : AppColors.forestGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: Container(
              key: ValueKey<int>(_selectedStep),
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.mintGreen,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      activeStep.icon,
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
                          activeStep.title,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.forestGreen,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          activeStep.detail,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 11.5,
                            height: 1.42,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (widget.onLearnMore != null) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: widget.onLearnMore,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Pelajari Materi ${widget.shortLabel} Selengkapnya',
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
    );
  }
}

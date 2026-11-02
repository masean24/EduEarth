import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
import '../../../../routes/route_names.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../plants/presentation/providers/plants_providers.dart';

/// Halaman Beranda (Home Dashboard) sesuai referensi `docs/design/moodboard.png`.
///
/// Menampilkan:
/// 1. Sapaan pengguna ("Selamat datang, `<Nama>`! 👋")
/// 2. Search bar berbasis `GlassContainer` ("Cari pembangkit, materi...")
/// 3. Banner "Explore Renewable Energy" dengan tombol "Mulai Jelajah →"
/// 4. Baris "Kategori Energi" dengan ikon bulat per kategori
/// 5. Bagian "Rekomendasi Pembangkit" dengan kartu bergambar gaya moodboard
class HomeDashboardPage extends ConsumerWidget {
  const HomeDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(energyCategoriesProvider);
    final plantsAsync = ref.watch(allPlantsListProvider);
    final profileAsync = ref.watch(currentUserProfileProvider);
    final session = ref.watch(currentSessionProvider);

    final rawName = profileAsync.asData?.value?.displayName?.trim();
    final emailPrefix = session?.user.email?.split('@').first;
    final greetingName = (rawName != null && rawName.isNotEmpty)
        ? rawName
        : (emailPrefix != null && emailPrefix.isNotEmpty)
            ? emailPrefix
            : 'Penjelajah';

    final bottomSafe = MediaQuery.viewPaddingOf(context).bottom;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.freshGreen,
          onRefresh: () async {
            ref.invalidate(energyCategoriesProvider);
            ref.invalidate(allPlantsListProvider);
          },
          child: categoriesAsync.when(
            loading: () => const LoadingView(
              message: 'Memuat beranda energi terbarukan...',
            ),
            error: (error, _) => ErrorView(
              message: error.toString(),
              onRetry: () {
                ref.invalidate(energyCategoriesProvider);
                ref.invalidate(allPlantsListProvider);
              },
            ),
            data: (categories) {
              if (categories.isEmpty) {
                return EmptyView(
                  title: 'Kategori Energi Belum Tersedia',
                  description:
                      'Jalankan seed 5 kategori energi pada database Supabase Anda.',
                  actionLabel: 'Muat Ulang',
                  onAction: () => ref.invalidate(energyCategoriesProvider),
                );
              }

              return ListView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  16,
                  20,
                  AppTheme.bottomNavScrollPadding + bottomSafe,
                ),
                children: [
                  ScreenHeader(
                    title: '$greetingName! 👋',
                    subtitle: 'Selamat datang,',
                    subtitleAboveTitle: true,
                    actions: [
                      ScreenHeaderAction(
                        tooltip: 'Pembangkit Terdekat',
                        icon: Icons.near_me_outlined,
                        onTap: () => context.push(RouteNames.nearbyPlantsPath),
                      ),
                      ScreenHeaderAction(
                        tooltip: 'Bookmark Tersimpan',
                        icon: Icons.bookmark_outline_rounded,
                        onTap: () => context.push(RouteNames.bookmarksPath),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSearchBarTrigger(context),
                  const SizedBox(height: 18),
                  _buildExploreBanner(context),
                  const SizedBox(height: 24),
                  _buildSectionHeader(
                    title: 'Kategori Energi',
                    actionLabel: 'Lihat Semua →',
                    onAction: () => context.go(RouteNames.learningPath),
                  ),
                  const SizedBox(height: 12),
                  _buildCircularCategoriesRow(context, ref, categories),
                  const SizedBox(height: 24),
                  _buildSectionHeader(
                    title: 'Rekomendasi Pembangkit',
                    actionLabel: 'Peta →',
                    onAction: () => context.go(RouteNames.exploreMapPath),
                  ),
                  const SizedBox(height: 12),
                  _buildRecommendedPlants(context, ref, plantsAsync),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBarTrigger(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(RouteNames.searchPath),
      behavior: HitTestBehavior.opaque,
      child: GlassContainer(
        borderRadius: AppTheme.pillRadius,
        blur: 14,
        tintOpacity: 0.85,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            const Icon(
              Icons.search_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Cari pembangkit, materi...',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExploreBanner(BuildContext context) {
    return Container(
      height: 168,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        gradient: const LinearGradient(
          colors: [
            AppColors.forestGreen,
            Color(0xFF237A48),
            Color(0xFF56B870),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Stack(
        children: [
          // Slot ilustrasi sebelah kanan (fallback ikon energi bersih lembut)
          Positioned(
            right: -8,
            top: 0,
            bottom: 0,
            width: 170,
            child: SoftImagePlaceholder(
              borderRadius: 0,
              assetPath:
                  'assets/images/illustrations/banner_explore_energy.png',
              backgroundColor: AppColors.mintGreen.withValues(alpha: 0.18),
              fallbackIcon: Icons.solar_power_rounded,
              iconColor: AppColors.surfaceWhite.withValues(alpha: 0.85),
              iconSize: 64,
            ),
          ),
          // Badge bulat hijau + di kanan atas sesuai moodboard
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppColors.freshGreen,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surfaceWhite, width: 1.5),
              ),
              child: const Icon(
                Icons.eco_rounded,
                size: 16,
                color: AppColors.surfaceWhite,
              ),
            ),
          ),
          // Konten teks & tombol kiri
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Explore\nRenewable\nEnergy',
                  style: AppTextStyles.title.copyWith(
                    color: AppColors.surfaceWhite,
                    fontSize: 21,
                    height: 1.2,
                  ),
                ),
                Material(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                    onTap: () => context.go(RouteNames.exploreMapPath),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Mulai Jelajah',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.forestGreen,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 15,
                            color: AppColors.forestGreen,
                          ),
                        ],
                      ),
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

  Widget _buildSectionHeader({
    required String title,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTextStyles.subtitle.copyWith(fontSize: 17)),
        GestureDetector(
          onTap: onAction,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              actionLabel,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.forestGreen,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCircularCategoriesRow(
    BuildContext context,
    WidgetRef ref,
    List<EnergyCategory> categories,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: categories.map((category) {
          final slug = category.slug;
          final softBg = AppColors.softBackgroundForCategorySlug(slug);
          final accentColor = AppColors.colorForCategorySlug(slug);
          final shortLabel = shortDisplayLabelForSlug(slug, category.name);

          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                ref
                    .read(selectedCategoryFilterProvider.notifier)
                    .selectCategory(slug);
                context.go(RouteNames.exploreMapPath);
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: softBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      iconForCategorySlug(slug),
                      color: slug == 'solar'
                          ? const Color(0xFFD97706)
                          : accentColor == AppColors.freshGreen
                              ? AppColors.forestGreen
                              : accentColor,
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    shortLabel,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.forestGreen,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      height: 1.15,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRecommendedPlants(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<PowerPlant>> plantsAsync,
  ) {
    return plantsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: LoadingView(message: 'Memuat rekomendasi pembangkit...'),
      ),
      error: (error, _) => ErrorView(
        message: error.toString(),
        onRetry: () => ref.invalidate(allPlantsListProvider),
      ),
      data: (plants) {
        if (plants.isEmpty) {
          return const EmptyView(
            title: 'Belum Ada Data Pembangkit',
            description:
                'Tabel power_plants masih kosong. Jalankan seed demo atau tambahkan data pembangkit terverifikasi.',
          );
        }

        final displayPlants = plants.take(4).toList();
        return Column(
          children: List.generate(displayPlants.length, (index) {
            final plant = displayPlants[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: PlantCard(
                plant: plant,
                isFeaturedBanner: index == 0,
                onTap: () => context.push('/plants/${plant.id}'),
              ),
            );
          }),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common/category_chip.dart';
import '../../../../core/widgets/common/empty_view.dart';
import '../../../../core/widgets/common/error_view.dart';
import '../../../../core/widgets/common/loading_view.dart';
import '../../../../core/widgets/common/plant_card.dart';
import '../../../../core/widgets/common/primary_button.dart';
import '../../../../core/widgets/common/secondary_button.dart';
import '../../../../models/energy_category.dart';
import '../../../../models/power_plant.dart';
import '../../../../routes/route_names.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../plants/presentation/providers/plants_providers.dart';

/// Halaman Beranda (Home Dashboard) Fase 2.
///
/// Menampilkan ringkasan energi terbarukan Indonesia, akses cepat ke Explore Map
/// & Pembangkit Terdekat, daftar 5 kategori energi, serta pratinjau pembangkit.
class HomeDashboardPage extends ConsumerWidget {
  const HomeDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(energyCategoriesProvider);
    final plantsAsync = ref.watch(allPlantsListProvider);
    final profileAsync = ref.watch(currentUserProfileProvider);

    final greetingName = profileAsync.asData?.value?.displayName;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              greetingName != null && greetingName.isNotEmpty
                  ? 'Halo, $greetingName'
                  : AppConstants.appName,
              style: AppTextStyles.title,
            ),
            Text(
              AppConstants.appTagline,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.freshGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Pembangkit Terdekat',
            onPressed: () => context.push(RouteNames.nearbyPlantsPath),
            icon: const Icon(Icons.near_me_outlined),
          ),
          IconButton(
            tooltip: 'Demo Komponen & Design System',
            onPressed: () => context.push(RouteNames.designShowcasePath),
            icon: const Icon(Icons.palette_outlined),
          ),
        ],
      ),
      body: SafeArea(
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
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
                children: [
                  _buildHeroBanner(context, plantsAsync),
                  const SizedBox(height: 24),
                  Text('5 Kategori Energi Bersih', style: AppTextStyles.title),
                  const SizedBox(height: 6),
                  Text(
                    'Ketuk salah satu kategori untuk langsung memfilter peta pembangkit.',
                    style: AppTextStyles.caption,
                  ),
                  const SizedBox(height: 12),
                  _buildCategoriesHorizontalList(context, ref, categories),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Pembangkit Terdaftar', style: AppTextStyles.title),
                      TextButton.icon(
                        onPressed: () => context.go(RouteNames.exploreMapPath),
                        icon: const Icon(Icons.map_outlined, size: 18),
                        label: const Text('Buka Peta'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildPlantsSection(context, ref, plantsAsync),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeroBanner(
    BuildContext context,
    AsyncValue<List<PowerPlant>> plantsAsync,
  ) {
    final totalPlants = plantsAsync.asData?.value.length ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        gradient: const LinearGradient(
          colors: [
            AppColors.forestGreen,
            Color(0xFF1E7A44),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.mintGreen,
              borderRadius: BorderRadius.circular(AppTheme.pillRadius),
            ),
            child: Text(
              'Eksplorasi Nusantara • $totalPlants Titik Aktif',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.forestGreen,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Peta Pembangkit Energi Terbarukan Indonesia',
            style: AppTextStyles.title.copyWith(
              color: AppColors.surfaceWhite,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Temukan sebaran PLTS, PLTA, PLTB, PLTP, dan Bioenergi beserta lokasi terdekat dari posisi Anda.',
            style: AppTextStyles.body.copyWith(
              color: AppColors.mintGreen,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  label: 'Jelajahi Peta',
                  icon: Icons.map_rounded,
                  onPressed: () => context.go(RouteNames.exploreMapPath),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SecondaryButton(
                  label: 'Terdekat',
                  icon: Icons.near_me_rounded,
                  onPressed: () => context.push(RouteNames.nearbyPlantsPath),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesHorizontalList(
    BuildContext context,
    WidgetRef ref,
    List<EnergyCategory> categories,
  ) {
    return SizedBox(
      height: 148,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final category = categories[index];
          final color = AppColors.colorForCategorySlug(category.slug);

          return SizedBox(
            width: 168,
            child: Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                onTap: () {
                  ref
                      .read(selectedCategoryFilterProvider.notifier)
                      .selectCategory(category.slug);
                  context.go(RouteNames.exploreMapPath);
                },
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.18),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              iconForCategorySlug(category.slug),
                              color: AppColors.forestGreen,
                              size: 20,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.mintGreen,
                              borderRadius: BorderRadius.circular(
                                AppTheme.pillRadius,
                              ),
                            ),
                            child: Text(
                              category.shortCode,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.forestGreen,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        category.name,
                        style: AppTextStyles.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        category.description,
                        style: AppTextStyles.caption,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlantsSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<PowerPlant>> plantsAsync,
  ) {
    return plantsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: LoadingView(message: 'Memuat daftar pembangkit...'),
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

        return Column(
          children: plants.take(5).map((plant) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: PlantCard(
                plant: plant,
                onTap: () => context.push('/plants/${plant.id}'),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}


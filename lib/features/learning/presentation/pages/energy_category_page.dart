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
import '../../../../core/widgets/common/material_card.dart';
import '../../../../core/widgets/common/screen_header.dart';
import '../../../../core/widgets/common/secondary_button.dart';
import '../../../../core/widgets/common/soft_image_placeholder.dart';
import '../../../../routes/route_names.dart';
import '../../../plants/presentation/providers/plants_providers.dart';
import '../providers/learning_providers.dart';

/// Halaman Daftar Materi per Kategori Energi (Energy Category Page).
class EnergyCategoryPage extends ConsumerWidget {
  const EnergyCategoryPage({
    super.key,
    required this.categorySlug,
  });

  final String categorySlug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(energyCategoriesProvider);
    final allPlantsAsync = ref.watch(allPlantsListProvider);
    final materialsAsync = ref.watch(
      materialsByCategorySlugProvider(categorySlug),
    );

    final matchedCategory = categoriesAsync.asData?.value
        .where((c) => c.slug == categorySlug)
        .firstOrNull;

    final categoryPlants = (allPlantsAsync.asData?.value ?? const [])
        .where((p) => p.categorySlug == categorySlug)
        .toList();
    final opPlants = categoryPlants
        .where((p) => p.operationalStatus.toLowerCase() == 'operating')
        .toList();
    final conCount = categoryPlants
        .where((p) => p.operationalStatus.toLowerCase() == 'construction')
        .length;
    final planCount = categoryPlants
        .where((p) => p.operationalStatus.toLowerCase() == 'planned')
        .length;
    final double opTotalMw = opPlants.fold<double>(
      0.0,
      (sum, p) => sum + (p.capacityMw ?? 0.0),
    );

    final softBg = AppColors.softBackgroundForCategorySlug(categorySlug);
    final categoryDisplayTitle = fullDisplayLabelForSlug(
      categorySlug,
      shortCode: matchedCategory?.shortCode,
      fallbackName: matchedCategory?.name ?? 'Kategori Energi',
    );
    final categoryShortName = shortDisplayLabelForSlug(
      categorySlug,
      matchedCategory?.name ?? 'Kategori Energi',
    );

    return Scaffold(
      appBar: ScreenHeaderBar(
        title: 'Energi $categoryShortName',
        subtitle: matchedCategory != null
            ? 'Pembangkit ${matchedCategory.shortCode}'
            : 'Daftar materi pembelajaran per kategori',
        actions: [
          ScreenHeaderAction(
            tooltip: 'Pencarian Global',
            icon: Icons.search_rounded,
            onTap: () => context.push(RouteNames.searchPath),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.freshGreen,
          onRefresh: () async {
            ref.invalidate(materialsByCategorySlugProvider(categorySlug));
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              if (matchedCategory != null) ...[
                Container(
                  padding: const EdgeInsets.all(20),
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
                          SoftImagePlaceholder(
                            width: 60,
                            height: 60,
                            borderRadius: 16,
                            assetPath: assetForCategorySlug(categorySlug),
                            backgroundColor: softBg,
                            fallbackIcon: iconForCategorySlug(categorySlug),
                            iconColor: AppColors.forestGreen,
                            iconSize: 30,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  categoryDisplayTitle,
                                  style: AppTextStyles.title,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Singkatan Pembangkit: ${matchedCategory.shortCode}',
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
                      Text(
                        matchedCategory.description,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (categoryPlants.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.offWhite,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Data Pembangkit Tercatat (${categoryPlants.length} titik)',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.forestGreen,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Beroperasi: ${opPlants.length} • Konstruksi: $conCount • Rencana: $planCount',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (opTotalMw > 0) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Kapasitas terpasang beroperasi (menurut sumber): ${opTotalMw.toStringAsFixed(2)} MW',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.forestGreen,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      SecondaryButton(
                        label:
                            'Lihat Pembangkit ${matchedCategory.shortCode} di Peta',
                        icon: Icons.map_outlined,
                        onPressed: () {
                          ref
                              .read(selectedCategoryFilterProvider.notifier)
                              .selectCategory(categorySlug);
                          context.go(RouteNames.exploreMapPath);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              Text('Daftar Materi Kategori Ini', style: AppTextStyles.title),
              const SizedBox(height: 12),
              materialsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 28),
                  child: LoadingView(
                    message: 'Memuat materi kategori...',
                  ),
                ),
                error: (error, _) => ErrorView(
                  message: error.toString(),
                  onRetry: () => ref.invalidate(
                    materialsByCategorySlugProvider(categorySlug),
                  ),
                ),
                data: (materials) {
                  if (materials.isEmpty) {
                    return EmptyView(
                      title: 'Belum Ada Materi untuk Kategori Ini',
                      description:
                          'Materi pembelajaran untuk kategori ini belum dipublikasikan.',
                      actionLabel: 'Kembali ke Semua Materi',
                      onAction: () => context.pop(),
                    );
                  }

                  return Column(
                    children: materials.map((material) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: MaterialCard(
                          material: material,
                          onTap: () => context.push(
                            '/learning/material/${material.slug}',
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
import '../../../../core/widgets/common/secondary_button.dart';
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
    final materialsAsync = ref.watch(
      materialsByCategorySlugProvider(categorySlug),
    );

    final matchedCategory = categoriesAsync.asData?.value
        .where((c) => c.slug == categorySlug)
        .firstOrNull;

    final accentColor = AppColors.colorForCategorySlug(categorySlug);

    return Scaffold(
      appBar: AppBar(
        title: Text(matchedCategory?.name ?? 'Kategori Energi'),
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
                    border: Border.all(color: accentColor, width: 1.4),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              iconForCategorySlug(categorySlug),
                              color: AppColors.forestGreen,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  matchedCategory.name,
                                  style: AppTextStyles.title,
                                ),
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
                        style: AppTextStyles.body,
                      ),
                      const SizedBox(height: 16),
                      SecondaryButton(
                        label: 'Lihat Pembangkit ${matchedCategory.shortCode} di Peta',
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

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
import '../../../../models/energy_category.dart';
import '../../../../models/learning_material.dart';
import '../../../../routes/route_names.dart';
import '../../../plants/presentation/providers/plants_providers.dart';
import '../providers/learning_providers.dart';

/// Halaman Utama Pembelajaran (Learning Dashboard) Fase 3.
///
/// Menampilkan 5 kategori energi untuk dijelajahi dan daftar seluruh materi
/// pembelajaran terpublikasi.
class LearningDashboardPage extends ConsumerWidget {
  const LearningDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(energyCategoriesProvider);
    final materialsAsync = ref.watch(allLearningMaterialsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Belajar Energi Bersih'),
        actions: [
          IconButton(
            tooltip: 'Daftar Bookmark Saya',
            onPressed: () => context.push(RouteNames.bookmarksPath),
            icon: const Icon(Icons.bookmark_outline_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.freshGreen,
          onRefresh: () async {
            ref.invalidate(energyCategoriesProvider);
            ref.invalidate(allLearningMaterialsProvider);
          },
          child: categoriesAsync.when(
            loading: () => const LoadingView(
              message: 'Memuat ruang belajar energi terbarukan...',
            ),
            error: (error, _) => ErrorView(
              message: error.toString(),
              onRetry: () {
                ref.invalidate(energyCategoriesProvider);
                ref.invalidate(allLearningMaterialsProvider);
              },
            ),
            data: (categories) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
                children: [
                  _buildHeaderBanner(context),
                  const SizedBox(height: 24),
                  Text(
                    'Pilih Kategori Energi',
                    style: AppTextStyles.title,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Pelajari cara kerja, kelebihan, dan keterbatasan setiap jenis pembangkit.',
                    style: AppTextStyles.caption,
                  ),
                  const SizedBox(height: 12),
                  _buildCategoriesGrid(context, categories),
                  const SizedBox(height: 24),
                  Text(
                    'Semua Materi Pembelajaran',
                    style: AppTextStyles.title,
                  ),
                  const SizedBox(height: 12),
                  _buildMaterialsList(context, ref, materialsAsync),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.mintGreen,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppColors.sageGreen),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: AppColors.surfaceWhite,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: AppColors.forestGreen,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pustaka EduEarth',
                  style: AppTextStyles.subtitle,
                ),
                const SizedBox(height: 4),
                Text(
                  'Simpan materi atau pembangkit penting ke Bookmark agar mudah dibaca kembali.',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesGrid(
    BuildContext context,
    List<EnergyCategory> categories,
  ) {
    if (categories.isEmpty) {
      return const EmptyView(
        title: 'Kategori Belum Tersedia',
        description: 'Belum ada kategori energi yang terdaftar.',
      );
    }

    return Column(
      children: categories.map((cat) {
        final color = AppColors.colorForCategorySlug(cat.slug);
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              onTap: () => context.push('/learning/category/${cat.slug}'),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        iconForCategorySlug(cat.slug),
                        color: AppColors.forestGreen,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  cat.name,
                                  style: AppTextStyles.subtitle,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.mintGreen,
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.pillRadius,
                                  ),
                                ),
                                child: Text(
                                  cat.shortCode,
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.forestGreen,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            cat.description,
                            style: AppTextStyles.caption,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMaterialsList(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<LearningMaterial>> materialsAsync,
  ) {
    return materialsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: LoadingView(message: 'Memuat daftar materi...'),
      ),
      error: (error, _) => ErrorView(
        message: error.toString(),
        onRetry: () => ref.invalidate(allLearningMaterialsProvider),
      ),
      data: (materials) {
        if (materials.isEmpty) {
          return EmptyView(
            title: 'Belum Ada Materi Pembelajaran',
            description:
                'Jalankan file migrasi seed draf materi di Supabase SQL Editor untuk mengisi materi awal.',
            actionLabel: 'Muat Ulang',
            onAction: () => ref.invalidate(allLearningMaterialsProvider),
          );
        }

        return Column(
          children: materials.map((mat) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: MaterialCard(
                material: mat,
                onTap: () => context.push('/learning/material/${mat.slug}'),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}


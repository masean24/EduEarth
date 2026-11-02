import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/common/category_chip.dart';
import '../../../../core/widgets/common/empty_view.dart';
import '../../../../core/widgets/common/error_view.dart';
import '../../../../core/widgets/common/loading_view.dart';
import '../../../../core/widgets/common/material_card.dart';
import '../../../../core/widgets/common/soft_image_placeholder.dart';
import '../../../../models/energy_category.dart';
import '../../../../models/learning_material.dart';
import '../../../../routes/route_names.dart';
import '../../../plants/presentation/providers/plants_providers.dart';
import '../providers/learning_providers.dart';

/// Halaman Utama Pembelajaran ("Pusat Edukasi") sesuai `docs/design/moodboard.png`.
///
/// Menampilkan:
/// - Header "Pusat Edukasi" dengan slot maskot Eco membaca buku
/// - Baris chip filter kategori (`Semua`, `Surya`, `Air`, `Angin`, `Panas Bumi`, `Bioenergi`)
/// - Daftar kartu materi bergambar (`MaterialCard`)
class LearningDashboardPage extends ConsumerStatefulWidget {
  const LearningDashboardPage({super.key});

  @override
  ConsumerState<LearningDashboardPage> createState() =>
      _LearningDashboardPageState();
}

class _LearningDashboardPageState
    extends ConsumerState<LearningDashboardPage> {
  String? _selectedCategorySlug;

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(energyCategoriesProvider);
    final materialsAsync = ref.watch(allLearningMaterialsProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.freshGreen,
          onRefresh: () async {
            ref.invalidate(energyCategoriesProvider);
            ref.invalidate(allLearningMaterialsProvider);
          },
          child: categoriesAsync.when(
            loading: () => const LoadingView(
              message: 'Memuat Pusat Edukasi...',
            ),
            error: (error, _) => ErrorView(
              message: error.toString(),
              onRetry: () {
                ref.invalidate(energyCategoriesProvider);
                ref.invalidate(allLearningMaterialsProvider);
              },
            ),
            data: (categories) {
              final selectedCategory = categories
                  .where((c) => c.slug == _selectedCategorySlug)
                  .firstOrNull;

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                children: [
                  _buildTopBarActions(context),
                  const SizedBox(height: 8),
                  _buildEducationHeader(),
                  const SizedBox(height: 18),
                  _buildCategoryChips(categories),
                  if (selectedCategory != null) ...[
                    const SizedBox(height: 14),
                    _buildSelectedCategoryBanner(context, selectedCategory),
                  ],
                  const SizedBox(height: 18),
                  _buildMaterialsList(context, materialsAsync),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTopBarActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        IconButton(
          tooltip: 'Pencarian Global',
          onPressed: () => context.push(RouteNames.searchPath),
          icon: const Icon(
            Icons.search_rounded,
            color: AppColors.forestGreen,
          ),
        ),
        IconButton(
          tooltip: 'Daftar Bookmark Saya',
          onPressed: () => context.push(RouteNames.bookmarksPath),
          icon: const Icon(
            Icons.bookmark_outline_rounded,
            color: AppColors.forestGreen,
          ),
        ),
      ],
    );
  }

  Widget _buildEducationHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pusat Edukasi',
                style: AppTextStyles.display.copyWith(fontSize: 24),
              ),
              const SizedBox(height: 6),
              Text(
                'Belajar lebih dalam tentang energi terbarukan!',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        const SoftImagePlaceholder(
          width: 84,
          height: 84,
          borderRadius: 42,
          assetPath: 'assets/images/mascot/eco_reading.png',
          backgroundColor: AppColors.mintGreen,
          fallbackIcon: Icons.school_rounded,
          iconColor: AppColors.forestGreen,
          iconSize: 40,
        ),
      ],
    );
  }

  Widget _buildCategoryChips(List<EnergyCategory> categories) {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          CategoryChip(
            label: 'Semua',
            isSelected: _selectedCategorySlug == null,
            onTap: () {
              setState(() => _selectedCategorySlug = null);
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
                isSelected: _selectedCategorySlug == cat.slug,
                onTap: () {
                  setState(() {
                    _selectedCategorySlug =
                        _selectedCategorySlug == cat.slug ? null : cat.slug;
                  });
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSelectedCategoryBanner(
    BuildContext context,
    EnergyCategory category,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.mintGreen,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.sageGreen),
      ),
      child: Row(
        children: [
          Icon(
            iconForCategorySlug(category.slug),
            size: 18,
            color: AppColors.forestGreen,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${category.name} (${category.shortCode})',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.forestGreen,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => context.push('/learning/category/${category.slug}'),
            child: Text(
              'Detail Kategori →',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.forestGreen,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialsList(
    BuildContext context,
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
        final filtered = _selectedCategorySlug == null
            ? materials
            : materials
                .where((m) => m.categorySlug == _selectedCategorySlug)
                .toList();

        if (filtered.isEmpty) {
          return EmptyView(
            title: 'Belum Ada Materi Pembelajaran',
            description: _selectedCategorySlug == null
                ? 'Jalankan file migrasi seed draf materi di Supabase SQL Editor untuk mengisi materi awal.'
                : 'Belum ada materi yang dipublikasikan untuk kategori yang dipilih.',
            actionLabel: _selectedCategorySlug == null
                ? 'Muat Ulang'
                : 'Tampilkan Semua Kategori',
            onAction: () {
              if (_selectedCategorySlug != null) {
                setState(() => _selectedCategorySlug = null);
              } else {
                ref.invalidate(allLearningMaterialsProvider);
              }
            },
          );
        }

        return Column(
          children: filtered.map((mat) {
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

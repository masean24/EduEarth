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

    final bottomSafe = MediaQuery.viewPaddingOf(context).bottom;

    return Scaffold(
      body: SafeArea(
        bottom: false,
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
                padding: EdgeInsets.fromLTRB(
                  20,
                  16,
                  20,
                  AppTheme.bottomNavScrollPadding + bottomSafe,
                ),
                children: [
                  ScreenHeader(
                    title: 'Pusat Edukasi',
                    subtitle: 'Belajar lebih dalam tentang energi terbarukan!',
                    actions: [
                      ScreenHeaderAction(
                        tooltip: 'Perbandingan Energi',
                        icon: Icons.compare_arrows_rounded,
                        onTap: () =>
                            context.push(RouteNames.energyComparisonPath),
                      ),
                      ScreenHeaderAction(
                        tooltip: 'Pencarian Global',
                        icon: Icons.search_rounded,
                        onTap: () => context.push(RouteNames.searchPath),
                      ),
                      ScreenHeaderAction(
                        tooltip: 'Daftar Bookmark Saya',
                        icon: Icons.bookmark_outline_rounded,
                        onTap: () => context.push(RouteNames.bookmarksPath),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildEducationMascotBanner(context),
                  const SizedBox(height: 16),
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

  Widget _buildEducationMascotBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.mintGreen.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppColors.sageGreen),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const SoftImagePlaceholder(
                width: 56,
                height: 56,
                borderRadius: 28,
                assetPath: 'assets/images/mascot/eco_reading.png',
                backgroundColor: AppColors.surfaceWhite,
                fallbackIcon: Icons.school_rounded,
                iconColor: AppColors.forestGreen,
                iconSize: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Pilih kategori di bawah untuk menyaring materi atau bandingkan karakteristik 5 sumber energi bersih.',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.forestGreen,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Material(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => context.push(RouteNames.energyComparisonPath),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.compare_arrows_rounded,
                      size: 18,
                      color: AppColors.forestGreen,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Bandingkan Karakteristik 5 Kategori Energi',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.forestGreen,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: AppColors.forestGreen,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
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
              fullDisplayLabelForSlug(
                category.slug,
                shortCode: category.shortCode,
                fallbackName: category.name,
              ),
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

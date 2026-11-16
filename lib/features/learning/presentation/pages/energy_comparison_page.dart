import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/demo_data.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common/category_chip.dart';
import '../../../../core/widgets/common/empty_view.dart';
import '../../../../core/widgets/common/error_view.dart';
import '../../../../core/widgets/common/loading_view.dart';
import '../../../../core/widgets/common/screen_header.dart';
import '../../../../models/energy_category.dart';
import '../../../plants/presentation/providers/plants_providers.dart';

/// Halaman Perbandingan Energi Terbarukan & Dampak Lingkungan (Pilar Understand Impact)
/// yang membaca atribut JSONB `energy_categories.comparison`.
class EnergyComparisonPage extends ConsumerStatefulWidget {
  const EnergyComparisonPage({super.key, this.initialCategorySlug});

  final String? initialCategorySlug;

  @override
  ConsumerState<EnergyComparisonPage> createState() =>
      _EnergyComparisonPageState();
}

class _EnergyComparisonPageState extends ConsumerState<EnergyComparisonPage> {
  String _leftSlug = 'solar';
  String _rightSlug = 'geothermal';

  @override
  void initState() {
    super.initState();
    final initial = widget.initialCategorySlug?.trim();
    if (initial != null && initial.isNotEmpty) {
      _leftSlug = initial;
      _rightSlug = initial == 'geothermal' ? 'solar' : 'geothermal';
    }
  }

  static const List<(String, String, IconData)> _comparisonAttributes = [
    ('sumber_energi', 'Sumber Energi Primer', Icons.wb_incandescent_outlined),
    ('karakter_pasokan', 'Karakteristik Pasokan (Umum)', Icons.bolt_rounded),
    ('variasi_desain', 'Variasi Desain Pembangkit', Icons.tune_rounded),
    (
      'manfaat_lingkungan',
      'Manfaat Lingkungan & Dekarbonisasi',
      Icons.eco_outlined,
    ),
    (
      'tantangan_lingkungan',
      'Tantangan Lingkungan (Trade-off)',
      Icons.warning_amber_rounded,
    ),
    ('emisi_siklus_hidup', 'Emisi Siklus Hidup (LCA)', Icons.co2_rounded),
    ('kebutuhan_lahan', 'Kebutuhan Ruang / Lahan', Icons.terrain_rounded),
    ('faktor_kapasitas', 'Faktor Kapasitas (Kualitatif)', Icons.speed_rounded),
    (
      'keunggulan_utama',
      'Keunggulan Teknis Utama',
      Icons.thumb_up_alt_outlined,
    ),
    (
      'tantangan_utama',
      'Tantangan Teknis & Jaringan',
      Icons.build_circle_outlined,
    ),
    ('karakter_lokasi', 'Karakteristik Lokasi Ideal', Icons.map_outlined),
  ];

  Map<String, dynamic> _resolveComparison(EnergyCategory category) {
    final fallback =
        DemoData.comparisonBySlug[category.slug] ?? const <String, dynamic>{};
    if (category.comparison.isNotEmpty) {
      return <String, dynamic>{...fallback, ...category.comparison};
    }
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(energyCategoriesProvider);

    return Scaffold(
      appBar: const ScreenHeaderBar(
        title: 'Perbandingan & Dampak Energi',
        subtitle: 'Karakteristik teknis, manfaat, dan trade-off lingkungan',
      ),
      body: SafeArea(
        child: categoriesAsync.when(
          loading: () => const LoadingView(
            message: 'Memuat data perbandingan kategori energi...',
          ),
          error: (error, _) => ErrorView(
            message: error.toString(),
            onRetry: () => ref.invalidate(energyCategoriesProvider),
          ),
          data: (categories) {
            if (categories.length < 2) {
              return EmptyView(
                title: 'Data Kategori Belum Lengkap',
                description: 'Dibutuhkan minimal 2 kategori energi untuk menampilkan matriks perbandingan.',
                actionLabel: 'Muat Ulang',
                onAction: () => ref.invalidate(energyCategoriesProvider),
              );
            }

            final leftCategory = categories.firstWhere(
              (c) => c.slug == _leftSlug,
              orElse: () => categories.first,
            );
            final rightCategory = categories.firstWhere(
              (c) => c.slug == _rightSlug,
              orElse: () =>
                  categories.length > 1 ? categories[1] : categories.first,
            );

            final leftMap = _resolveComparison(leftCategory);
            final rightMap = _resolveComparison(rightCategory);

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
              children: [
                _buildMethodologyAndReferencesCard(context),
                const SizedBox(height: 14),

                // 1. Pemilih 2 Kategori yang Dibandingkan
                _buildSelectorCard(
                  categories: categories,
                  leftCategory: leftCategory,
                  rightCategory: rightCategory,
                ),
                const SizedBox(height: 16),

                // 2. Kartu Header 2 Kolom (Side-by-Side)
                Row(
                  children: [
                    Expanded(child: _buildCategoryHeaderPill(leftCategory)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.mintGreen,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.sageGreen),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'VS',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.forestGreen,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                    Expanded(child: _buildCategoryHeaderPill(rightCategory)),
                  ],
                ),
                const SizedBox(height: 18),

                // 3. Daftar Kartu Perbandingan per Dimensi Teknis
                ..._comparisonAttributes.map((attr) {
                  final key = attr.$1;
                  final label = attr.$2;
                  final icon = attr.$3;
                  final leftVal =
                      (leftMap[key] as String?) ?? 'Belum dicantumkan';
                  final rightVal =
                      (rightMap[key] as String?) ?? 'Belum dicantumkan';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildComparisonRowCard(
                      attributeTitle: label,
                      attributeIcon: icon,
                      leftCategory: leftCategory,
                      rightCategory: rightCategory,
                      leftValue: leftVal,
                      rightValue: rightVal,
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMethodologyAndReferencesCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.mintGreen.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.freshGreen.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.forestGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'METODOLOGI & SUMBER REFERENSI',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.surfaceWhite,
                    fontWeight: FontWeight.w800,
                    fontSize: 10.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Perbandingan ini menggunakan pendekatan kualitatif berbasis siklus hidup (Life-Cycle Assessment / LCA) dan karakteristik umum pembangkit. Karakteristik setiap proyek di lapangan dapat berbeda bergantung pada desain teknis dan kondisi geografis tapak.',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textPrimary,
              height: 1.45,
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sumber rujukan: IPCC AR6 WGIII (2022) Chapter 6 & Annex III • IRENA Renewable Power Generation Costs • Kementerian ESDM — Ditjen EBTKE.',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.forestGreen,
              fontWeight: FontWeight.w700,
              fontSize: 11.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () => context.push(
                '/learning/material/transisi-energi-dan-dampak-lingkungan',
              ),
              icon: const Icon(Icons.menu_book_rounded, size: 16),
              label: const Text(
                'Baca Modul Transisi Energi & Trade-off Lingkungan',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectorCard({
    required List<EnergyCategory> categories,
    required EnergyCategory leftCategory,
    required EnergyCategory rightCategory,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pilih Kategori Energi A',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.forestGreen,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          HorizontalChipStrip(
            fadeColor: AppColors.surfaceWhite,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(right: 28),
              child: Row(
                children: categories.map((cat) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: CategoryChip(
                      label: shortDisplayLabelForSlug(cat.slug, cat.name),
                      categorySlug: cat.slug,
                      isSelected: cat.slug == leftCategory.slug,
                      onTap: () {
                        setState(() => _leftSlug = cat.slug);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Bandingkan dengan Kategori Energi B',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.forestGreen,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          HorizontalChipStrip(
            fadeColor: AppColors.surfaceWhite,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(right: 28),
              child: Row(
                children: categories.map((cat) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: CategoryChip(
                      label: shortDisplayLabelForSlug(cat.slug, cat.name),
                      categorySlug: cat.slug,
                      isSelected: cat.slug == rightCategory.slug,
                      onTap: () {
                        setState(() => _rightSlug = cat.slug);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryHeaderPill(EnergyCategory category) {
    final color = AppColors.colorForCategorySlug(category.slug);
    final softBg = AppColors.softBackgroundForCategorySlug(category.slug);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: softBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: AppColors.surfaceWhite,
              shape: BoxShape.circle,
            ),
            child: Icon(
              iconForCategorySlug(category.slug),
              color: AppColors.foregroundColorForCategorySlug(category.slug),
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shortDisplayLabelForSlug(category.slug, category.name),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.subtitle.copyWith(
                    fontSize: 13.5,
                    height: 1.2,
                    color: AppColors.forestGreen,
                  ),
                ),
                Text(
                  category.shortCode,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonRowCard({
    required String attributeTitle,
    required IconData attributeIcon,
    required EnergyCategory leftCategory,
    required EnergyCategory rightCategory,
    required String leftValue,
    required String rightValue,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(attributeIcon, size: 18, color: AppColors.forestGreen),
              const SizedBox(width: 8),
              Text(
                attributeTitle,
                style: AppTextStyles.subtitle.copyWith(fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.softBackgroundForCategorySlug(
                        leftCategory.slug,
                      ).withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shortDisplayLabelForSlug(leftCategory.slug),
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.forestGreen,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          leftValue,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textPrimary,
                            height: 1.4,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.softBackgroundForCategorySlug(
                        rightCategory.slug,
                      ).withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shortDisplayLabelForSlug(rightCategory.slug),
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.forestGreen,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          rightValue,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textPrimary,
                            height: 1.4,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
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
}

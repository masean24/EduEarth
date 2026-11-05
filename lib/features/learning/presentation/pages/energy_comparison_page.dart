import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
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

/// Halaman Perbandingan Energi Terbarukan (Energy Comparison) Fase 6
/// yang membaca atribut JSONB `energy_categories.comparison`.
class EnergyComparisonPage extends ConsumerStatefulWidget {
  const EnergyComparisonPage({super.key});

  @override
  ConsumerState<EnergyComparisonPage> createState() =>
      _EnergyComparisonPageState();
}

class _EnergyComparisonPageState extends ConsumerState<EnergyComparisonPage> {
  String _leftSlug = 'solar';
  String _rightSlug = 'geothermal';

  static const List<(String, String, IconData)> _comparisonAttributes = [
    ('sumber_energi', 'Sumber Energi Primer', Icons.wb_incandescent_outlined),
    ('karakter_pasokan', 'Karakteristik Pasokan', Icons.bolt_rounded),
    ('faktor_kapasitas', 'Faktor Kapasitas (Kualitatif)', Icons.speed_rounded),
    ('emisi_siklus_hidup', 'Emisi Siklus Hidup', Icons.co2_rounded),
    ('kebutuhan_lahan', 'Kebutuhan Ruang / Lahan', Icons.terrain_rounded),
    ('keunggulan_utama', 'Keunggulan Utama', Icons.thumb_up_alt_outlined),
    ('tantangan_utama', 'Tantangan Teknis', Icons.build_circle_outlined),
    ('karakter_lokasi', 'Karakteristik Lokasi Ideal', Icons.map_outlined),
  ];

  Map<String, dynamic> _resolveComparison(EnergyCategory category) {
    if (category.comparison.isNotEmpty) {
      return category.comparison;
    }
    if (!AppConfig.isSupabaseConfigured) {
      return DemoData.comparisonBySlug[category.slug] ??
          const <String, dynamic>{};
    }
    return const <String, dynamic>{};
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(energyCategoriesProvider);

    return Scaffold(
      appBar: const ScreenHeaderBar(
        title: 'Perbandingan Energi',
        subtitle: 'Bandingkan karakteristik teknis 5 kategori EBT',
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
                description:
                    'Dibutuhkan minimal 2 kategori energi untuk menampilkan matriks perbandingan.',
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
              orElse: () => categories.length > 1
                  ? categories[1]
                  : categories.first,
            );

            final leftMap = _resolveComparison(leftCategory);
            final rightMap = _resolveComparison(rightCategory);

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
              children: [
                _buildDraftNoticeBanner(),
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

  Widget _buildDraftNoticeBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.warmYellow.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.warmYellow.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFB45309).withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'DRAF KUALITATIF',
              style: AppTextStyles.caption.copyWith(
                color: const Color(0xFFB45309),
                fontWeight: FontWeight.w800,
                fontSize: 10.5,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Matriks perbandingan ini memuat deskripsi kualitatif konseptual (tanpa statistik numerik) dan menunggu verifikasi literatur.',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textPrimary,
                height: 1.35,
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
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
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
          const SizedBox(height: 14),
          Text(
            'Bandingkan dengan Kategori Energi B',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.forestGreen,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
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
              color: category.slug == 'solar'
                  ? const Color(0xFFD97706)
                  : color == AppColors.freshGreen
                      ? AppColors.forestGreen
                      : color,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shortDisplayLabelForSlug(category.slug, category.name),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.subtitle.copyWith(
                    fontSize: 14,
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../routes/route_names.dart';
import '../../../../services/supabase_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import '../glass/glass_container.dart';
import 'empty_view.dart';
import 'error_view.dart';
import 'loading_view.dart';
import 'primary_button.dart';
import 'secondary_button.dart';

enum _PreviewStateMode { content, loading, error, empty }

/// Halaman demonstrasi sistem desain & komponen fondasi Fase 0.
///
/// Menampilkan palet warna Nature Tech, tipografi Plus Jakarta Sans,
/// `GlassContainer` (dengan toggle fallback tanpa blur), tiga state UI
/// (`LoadingView`, `ErrorView`, `EmptyView`), dan uji navigasi placeholder.
class DesignSystemShowcasePage extends ConsumerStatefulWidget {
  const DesignSystemShowcasePage({super.key});

  @override
  ConsumerState<DesignSystemShowcasePage> createState() =>
      _DesignSystemShowcasePageState();
}

class _DesignSystemShowcasePageState
    extends ConsumerState<DesignSystemShowcasePage> {
  _PreviewStateMode _stateMode = _PreviewStateMode.content;

  @override
  Widget build(BuildContext context) {
    final reduceGlass = ref.watch(reduceGlassEffectProvider);
    final isSupabaseReady = ref.watch(isSupabaseInitializedProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('EduEarth — Fondasi & Design System'),
        actions: [
          IconButton(
            tooltip: 'Kembali ke Home',
            onPressed: () => context.go(RouteNames.homePath),
            icon: const Icon(Icons.home_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildStatusBanner(isSupabaseReady),
            const SizedBox(height: 24),
            Text('1. Efek Liquid Glass & Fallback', style: AppTextStyles.title),
            const SizedBox(height: 8),
            Text(
              'Uji GlassContainer di atas latar berwarna. Aktifkan switch untuk menguji mode fallback tanpa blur (Kurangi efek glass).',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            _buildGlassPreviewSection(reduceGlass),
            const SizedBox(height: 24),
            Text(
              '2. Tiga State UI Wajib (Loading, Error, Empty)',
              style: AppTextStyles.title,
            ),
            const SizedBox(height: 12),
            _buildThreeStateSelector(),
            const SizedBox(height: 12),
            _buildStatePreviewBox(),
            const SizedBox(height: 24),
            Text('3. Palet Warna & Kategori Energi', style: AppTextStyles.title),
            const SizedBox(height: 12),
            _buildColorSwatches(),
            const SizedBox(height: 24),
            Text('4. Skala Tipografi & Tombol', style: AppTextStyles.title),
            const SizedBox(height: 12),
            _buildTypographyAndButtons(),
            const SizedBox(height: 24),
            Text('5. Uji Navigasi GoRouter (Fase 0)', style: AppTextStyles.title),
            const SizedBox(height: 12),
            _buildNavigationLinks(context),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBanner(bool isSupabaseReady) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.mintGreen,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppColors.sageGreen),
      ),
      child: Row(
        children: [
          Icon(
            isSupabaseReady
                ? Icons.cloud_done_rounded
                : Icons.info_outline_rounded,
            color: AppColors.forestGreen,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSupabaseReady
                      ? 'Supabase Terhubung'
                      : 'Mode Lokal Fase 0 (Supabase Belum Dikonfigurasi)',
                  style: AppTextStyles.subtitle,
                ),
                const SizedBox(height: 4),
                Text(
                  isSupabaseReady
                      ? 'Client Supabase aktif melalui --dart-define.'
                      : 'Aplikasi berjalan aman tanpa crash. Kredensial dapat disuntikkan lewat --dart-define saat masuk Fase 1.',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassPreviewSection(bool reduceGlass) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        gradient: const LinearGradient(
          colors: [
            AppColors.forestGreen,
            AppColors.freshGreen,
            AppColors.skyBlue,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          GlassContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      color: AppColors.forestGreen,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        reduceGlass
                            ? 'GlassContainer (Mode Fallback Solid)'
                            : 'GlassContainer (Mode Blur Aktif)',
                        style: AppTextStyles.subtitle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Dipakai selektif pada search bar, filter chip di atas peta, bottom nav, dan bottom sheet.',
                  style: AppTextStyles.body,
                ),
                const SizedBox(height: 12),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Kurangi efek glass (Fallback tanpa blur)',
                    style: AppTextStyles.bodyMedium,
                  ),
                  value: reduceGlass,
                  activeTrackColor: AppColors.freshGreen,
                  onChanged: (val) {
                    ref
                        .read(reduceGlassEffectProvider.notifier)
                        .setReduceEffect(val);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThreeStateSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(
          label: const Text('Data Ready'),
          selected: _stateMode == _PreviewStateMode.content,
          onSelected: (_) =>
              setState(() => _stateMode = _PreviewStateMode.content),
        ),
        ChoiceChip(
          label: const Text('Loading State'),
          selected: _stateMode == _PreviewStateMode.loading,
          onSelected: (_) =>
              setState(() => _stateMode = _PreviewStateMode.loading),
        ),
        ChoiceChip(
          label: const Text('Error State'),
          selected: _stateMode == _PreviewStateMode.error,
          onSelected: (_) =>
              setState(() => _stateMode = _PreviewStateMode.error),
        ),
        ChoiceChip(
          label: const Text('Empty State'),
          selected: _stateMode == _PreviewStateMode.empty,
          onSelected: (_) =>
              setState(() => _stateMode = _PreviewStateMode.empty),
        ),
      ],
    );
  }

  Widget _buildStatePreviewBox() {
    return Container(
      constraints: const BoxConstraints(minHeight: 240),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppColors.divider),
      ),
      child: switch (_stateMode) {
        _PreviewStateMode.loading => const LoadingView(),
        _PreviewStateMode.error => ErrorView(
            message:
                'Gagal memuat daftar pembangkit energi. Periksa koneksi Anda.',
            onRetry: () {
              setState(() => _stateMode = _PreviewStateMode.content);
            },
          ),
        _PreviewStateMode.empty => EmptyView(
            title: 'Belum Ada Pembangkit Terdekat',
            description:
                'Tidak ditemukan pembangkit energi terbarukan dalam radius pencarian ini.',
            actionLabel: 'Reset Filter',
            onAction: () {
              setState(() => _stateMode = _PreviewStateMode.content);
            },
          ),
        _PreviewStateMode.content => Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.mintGreen,
                    borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                  ),
                  child: Text(
                    '[DEMO] Contoh Kartu Komponen',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.forestGreen,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '[DEMO] Pembangkit Energi Contoh',
                  style: AppTextStyles.title,
                ),
                const SizedBox(height: 6),
                Text(
                  'Ini adalah tampilan ketika state data berhasil dimuat. Gunakan chip di atas untuk menguji LoadingView, ErrorView, dan EmptyView.',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
      },
    );
  }

  Widget _buildColorSwatches() {
    const items = <(String, Color)>[
      ('forestGreen #14532D', AppColors.forestGreen),
      ('freshGreen #22C55E', AppColors.freshGreen),
      ('sageGreen #A7C4AD', AppColors.sageGreen),
      ('mintGreen #DCFCE7', AppColors.mintGreen),
      ('skyBlue #38A6C8', AppColors.skyBlue),
      ('warmYellow #FACC15', AppColors.warmYellow),
    ];

    const categories = <(String, String)>[
      ('solar', 'Solar (PLTS)'),
      ('hydro', 'Hydro (PLTA)'),
      ('wind', 'Wind (PLTB)'),
      ('geothermal', 'Geothermal (PLTP)'),
      ('bioenergy', 'Bioenergy (PLTBm)'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: items.map((item) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: item.$2,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.sageGreen),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(item.$1, style: AppTextStyles.caption),
                ],
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: categories.map((cat) {
            final color = AppColors.colorForCategorySlug(cat.$1);
            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                border: Border.all(color: color),
              ),
              child: Text(
                cat.$2,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.forestGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTypographyAndButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Display — 28 Bold', style: AppTextStyles.display),
          const SizedBox(height: 8),
          Text('Title — 20 Bold', style: AppTextStyles.title),
          const SizedBox(height: 8),
          Text('Subtitle — 16 SemiBold', style: AppTextStyles.subtitle),
          const SizedBox(height: 8),
          Text(
            'Body — 14 Regular. Explore Energy, Understand Earth.',
            style: AppTextStyles.body,
          ),
          const SizedBox(height: 8),
          Text('Caption — 12 Medium', style: AppTextStyles.caption),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Contoh Primary Button',
            icon: Icons.bolt_rounded,
            onPressed: () {},
          ),
          const SizedBox(height: 12),
          SecondaryButton(
            label: 'Contoh Secondary Button',
            icon: Icons.compost_rounded,
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationLinks(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        SecondaryButton(
          label: 'Ke Tab Home',
          icon: Icons.home_rounded,
          isExpanded: false,
          onPressed: () => context.go(RouteNames.homePath),
        ),
        SecondaryButton(
          label: 'Ke Tab Explore Map',
          icon: Icons.map_rounded,
          isExpanded: false,
          onPressed: () => context.go(RouteNames.exploreMapPath),
        ),
        SecondaryButton(
          label: 'Ke Tab Learn',
          icon: Icons.menu_book_rounded,
          isExpanded: false,
          onPressed: () => context.go(RouteNames.learningPath),
        ),
        SecondaryButton(
          label: 'Ke Tab Quiz',
          icon: Icons.quiz_rounded,
          isExpanded: false,
          onPressed: () => context.go(RouteNames.quizPath),
        ),
        SecondaryButton(
          label: 'Ke Tab Profile',
          icon: Icons.person_rounded,
          isExpanded: false,
          onPressed: () => context.go(RouteNames.profilePath),
        ),
      ],
    );
  }
}


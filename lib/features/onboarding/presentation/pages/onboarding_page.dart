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
import '../../../../core/widgets/common/primary_button.dart';
import '../../../../core/widgets/common/secondary_button.dart';
import '../../../../core/widgets/common/soft_image_placeholder.dart';
import '../../../../routes/route_names.dart';
import '../../../../services/supabase_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/onboarding_provider.dart';

class _OnboardingSlideData {
  const _OnboardingSlideData({
    required this.stepIndex,
    required this.badge,
    required this.speechBubble,
    required this.title,
    required this.description,
    required this.mascotAsset,
    required this.fallbackIcon,
    required this.accentColor,
  });

  final int stepIndex;
  final String badge;
  final String speechBubble;
  final String title;
  final String description;
  final String mascotAsset;
  final IconData fallbackIcon;
  final Color accentColor;
}

/// Layar Onboarding 3 halaman singkat (Peta Pembangkit, Belajar, Kuis)
/// sesuai referensi `docs/design/moodboard.png`.
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  bool _isSaving = false;

  static const List<_OnboardingSlideData> _slides = [
    _OnboardingSlideData(
      stepIndex: 0,
      badge: '1 • Peta Pembangkit',
      speechBubble: 'Halo! Yuk keliling pembangkit hijau Nusantara! 🗺️',
      title: 'Jelajahi Pembangkit Energi Terbarukan Indonesia',
      description:
          'Temukan lokasi PLTS, PLTA, PLTB, PLTP, dan Bioenergi terverifikasi di seluruh Nusantara melalui peta OpenStreetMap interaktif.',
      mascotAsset: 'assets/images/mascot/eco_wave.png',
      fallbackIcon: Icons.explore_rounded,
      accentColor: AppColors.freshGreen,
    ),
    _OnboardingSlideData(
      stepIndex: 1,
      badge: '2 • Pusat Belajar',
      speechBubble: 'Materi ringkas & mudah dipahami kapan saja! 📖',
      title: 'Pelajari Cara Kerja Energi Bersih Secara Ringkas',
      description:
          'Baca materi terstruktur tentang 5 kategori energi terbarukan, prinsip konversi daya, serta potensi geografis Indonesia.',
      mascotAsset: 'assets/images/mascot/eco_reading.png',
      fallbackIcon: Icons.menu_book_rounded,
      accentColor: AppColors.skyBlue,
    ),
    _OnboardingSlideData(
      stepIndex: 2,
      badge: '3 • Kuis Edukatif',
      speechBubble: 'Uji wawasanmu & lihat pembahasan tiap soal! 🏆',
      title: 'Uji Pemahaman & Pantau Progres Belajarmu',
      description:
          'Kerjakan kuis interaktif dengan ulasan pembahasan per soal dan simpan materi serta pembangkit favoritmu.',
      mascotAsset: 'assets/images/mascot/eco_congrats.png',
      fallbackIcon: Icons.quiz_rounded,
      accentColor: AppColors.warmYellow,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finishOnboarding() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      await ref.read(onboardingStatusProvider.notifier).completeOnboarding();
      if (!mounted) return;

      final isSupabaseReady = ref.read(isSupabaseInitializedProvider);
      final isAuthenticated = ref.read(isAuthenticatedProvider);

      if (isSupabaseReady && !isAuthenticated) {
        context.go(RouteNames.loginPath);
      } else {
        context.go(RouteNames.homePath);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _nextSlide() {
    if (_currentIndex < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finishOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final onboardingState = ref.watch(onboardingStatusProvider);

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE1F5E8),
              AppColors.offWhite,
              Color(0xFFEEF8F1),
            ],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: onboardingState.when(
            loading: () => const LoadingView(
              message: 'Menyiapkan pengenalan EduEarth...',
            ),
            error: (error, _) => ErrorView(
              message: error.toString(),
              onRetry: () => ref.invalidate(onboardingStatusProvider),
            ),
            data: (_) {
              if (_slides.isEmpty) {
                return EmptyView(
                  title: 'Materi Pengenalan Kosong',
                  description: 'Slide pengenalan belum tersedia.',
                  actionLabel: 'Lanjut ke Aplikasi',
                  onAction: _finishOnboarding,
                );
              }

              return Column(
                children: [
                  // Header bar rapi & sejajar dengan kartu di bawahnya
                  _buildTopHeader(),

                  // Area slide 3 halaman (terpusat secara vertikal & simetris)
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _slides.length,
                      onPageChanged: (index) {
                        setState(() => _currentIndex = index);
                      },
                      itemBuilder: (context, index) {
                        final slide = _slides[index];
                        return _buildSlideCard(slide);
                      },
                    ),
                  ),

                  // Indikator halaman + tombol aksi bawah (sejajar margin 22px)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 8, 22, 20),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(_slides.length, (index) {
                            final isSelected = index == _currentIndex;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              height: 8,
                              width: isSelected ? 28 : 8,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.forestGreen
                                    : AppColors.sageGreen.withValues(
                                        alpha: 0.55,
                                      ),
                                borderRadius: BorderRadius.circular(
                                  AppTheme.pillRadius,
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            if (_currentIndex > 0) ...[
                              Expanded(
                                flex: 2,
                                child: SecondaryButton(
                                  label: 'Kembali',
                                  onPressed: () {
                                    _pageController.previousPage(
                                      duration: const Duration(
                                        milliseconds: 240,
                                      ),
                                      curve: Curves.easeOutCubic,
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            Expanded(
                              flex: 3,
                              child: PrimaryButton(
                                label: _currentIndex == _slides.length - 1
                                    ? 'Mulai Sekarang'
                                    : 'Lanjut',
                                icon: _currentIndex == _slides.length - 1
                                    ? Icons.rocket_launch_rounded
                                    : Icons.arrow_forward_rounded,
                                isLoading: _isSaving,
                                onPressed: _nextSlide,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.divider,
            width: AppTheme.cardBorderWidth,
          ),
          boxShadow: AppTheme.softCardShadow,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: AppColors.mintGreen.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const SoftImagePlaceholder(
                width: 32,
                height: 32,
                borderRadius: 9,
                assetPath: 'assets/images/branding/logo_eduearth.png',
                backgroundColor: Colors.transparent,
                fallbackIcon: Icons.eco_rounded,
                iconColor: AppColors.forestGreen,
                iconSize: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'EduEarth',
                    style: AppTextStyles.subtitle.copyWith(
                      color: AppColors.forestGreen,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    'Langkah ${_currentIndex + 1} dari ${_slides.length} • Pengenalan',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: _isSaving ? null : _finishOnboarding,
              style: TextButton.styleFrom(
                backgroundColor: AppColors.mintGreen.withValues(alpha: 0.65),
                foregroundColor: AppColors.forestGreen,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                  side: BorderSide(
                    color: AppColors.sageGreen.withValues(alpha: 0.6),
                  ),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Lewati',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.forestGreen,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 11,
                    color: AppColors.forestGreen,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlideCard(_OnboardingSlideData slide) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const verticalPadding = 12.0;
        final minContentHeight =
            (constraints.maxHeight - (verticalPadding * 2)).clamp(
              0.0,
              double.infinity,
            );

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 22,
            vertical: verticalPadding,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minContentHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Kartu showcase utama dengan header lanskap/maskot + pratinjau fitur
                Container(
                  width: double.infinity,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWhite,
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(
                      color: AppColors.divider,
                      width: AppTheme.cardBorderWidth,
                    ),
                    boxShadow: AppTheme.softCardShadow,
                  ),
                  child: Column(
                    children: [
                      _buildHeroStage(slide),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                        child: _buildFeaturePreview(slide.stepIndex),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    slide.title,
                    style: AppTextStyles.display.copyWith(
                      fontSize: 21,
                      height: 1.28,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    slide.description,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.48,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeroStage(_OnboardingSlideData slide) {
    // Slide 1 memakai ilustrasi penuh splash_landscape.png (yang sudah bersih tanpa logo ganda)
    if (slide.stepIndex == 0) {
      return Stack(
        children: [
          const SoftImagePlaceholder(
            height: 176,
            width: double.infinity,
            borderRadius: 0,
            assetPath: 'assets/images/branding/splash_landscape.png',
            backgroundColor: AppColors.mintGreen,
            fallbackIcon: Icons.landscape_rounded,
            iconColor: AppColors.forestGreen,
            iconSize: 48,
          ),
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: AppTheme.badgePadding,
              decoration: AppTheme.badgeDecoration(
                backgroundColor: AppColors.surfaceWhite.withValues(alpha: 0.92),
                borderColor: AppColors.sageGreen.withValues(alpha: 0.6),
              ),
              child: Text(
                slide.badge,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.forestGreen,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 10,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.forestGreen.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(AppTheme.pillRadius),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.public_rounded,
                    color: AppColors.warmYellow,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'OpenStreetMap • Data Terverifikasi',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.surfaceWhite,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // Slide 2 & 3 memakai panggung gradasi lembut + maskot besar + speech bubble
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            slide.accentColor.withValues(alpha: 0.18),
            AppColors.mintGreen.withValues(alpha: 0.72),
            const Color(0xFFEFFAF3),
          ],
        ),
        border: const Border(
          bottom: BorderSide(color: AppColors.divider),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: AppTheme.badgePadding,
                decoration: AppTheme.badgeDecoration(
                  backgroundColor: AppColors.surfaceWhite,
                  borderColor: AppColors.sageGreen.withValues(alpha: 0.6),
                ),
                child: Text(
                  slide.badge,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.forestGreen,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: AppTheme.badgePadding,
                decoration: AppTheme.badgeDecoration(
                  backgroundColor: AppColors.surfaceWhite,
                  borderColor: AppColors.sageGreen.withValues(alpha: 0.6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (slide.stepIndex == 2) ...[
                      const Icon(
                        Icons.bolt_rounded,
                        size: 15,
                        color: Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      slide.stepIndex == 1
                          ? '5 Kategori EBT'
                          : 'Umpan Balik Instan',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.forestGreen,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              SoftImagePlaceholder(
                width: 116,
                height: 116,
                borderRadius: 24,
                assetPath: slide.mascotAsset,
                backgroundColor: Colors.transparent,
                fallbackIcon: slide.fallbackIcon,
                iconColor: AppColors.forestGreen,
                iconSize: 48,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWhite,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                      bottomLeft: Radius.circular(4),
                    ),
                    border: Border.all(color: AppColors.divider),
                    boxShadow: AppTheme.softCardShadow,
                  ),
                  child: Text(
                    slide.speechBubble,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.forestGreen,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                      height: 1.35,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturePreview(int stepIndex) {
    if (stepIndex == 0) {
      // Pratinjau 5 ikon kategori berwarna + kartu mini pembangkit
      const slugs = ['solar', 'hydro', 'wind', 'geothermal', 'bioenergy'];
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: slugs.map((slug) {
              final color = AppColors.colorForCategorySlug(slug);
              final softBg = AppColors.softBackgroundForCategorySlug(slug);
              return Column(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: softBg,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: color.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Icon(
                      iconForCategorySlug(slug),
                      color: slug == 'solar'
                          ? const Color(0xFFD97706)
                          : color == AppColors.freshGreen
                              ? AppColors.forestGreen
                              : color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    shortDisplayLabelForSlug(slug),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.forestGreen,
                      fontWeight: FontWeight.w700,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.offWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.mintGreen,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: AppColors.forestGreen,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Peta Pembangkit & Lokasi Terdekat',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.forestGreen,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Filter kategori, lihat spesifikasi & buka Google Maps',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: AppColors.forestGreen,
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (stepIndex == 1) {
      // Pratinjau 2 kartu materi mini bergaya Pusat Edukasi moodboard
      return Column(
        children: [
          _buildMiniMaterialItem(
            slug: 'solar',
            title: 'Energi Surya (PLTS)',
            subtitle: 'Prinsip efek fotovoltaik & komponen sel surya',
            meta: '4 mnt • Pemula',
          ),
          const SizedBox(height: 8),
          _buildMiniMaterialItem(
            slug: 'geothermal',
            title: 'Panas Bumi & Hidro Nusantara',
            subtitle: 'Pembangkit beban dasar & potensi geografis',
            meta: '5 mnt • Pemula',
          ),
        ],
      );
    }

    // Slide 3: Pratinjau opsi kuis & ulasan jawaban sesuai moodboard
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.mintGreen.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.freshGreen),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.forestGreen,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Mengubah cahaya matahari menjadi listrik',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.forestGreen,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.forestGreen,
                  borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                ),
                child: Text(
                  'Benar',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.surfaceWhite,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: AppColors.offWhite,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.lightbulb_outline_rounded,
                color: Color(0xFFD97706),
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Dilengkapi penjelasan ilmiah untuk setiap soal setelah kuis diselesaikan.',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMiniMaterialItem({
    required String slug,
    required String title,
    required String subtitle,
    required String meta,
  }) {
    final softBg = AppColors.softBackgroundForCategorySlug(slug);
    final color = AppColors.colorForCategorySlug(slug);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.offWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: softBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              iconForCategorySlug(slug),
              color: slug == 'solar' ? const Color(0xFFD97706) : color,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.forestGreen,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(AppTheme.pillRadius),
              border: Border.all(color: AppColors.divider),
            ),
            child: Text(
              meta,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.forestGreen,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

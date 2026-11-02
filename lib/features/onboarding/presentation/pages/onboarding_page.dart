import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common/empty_view.dart';
import '../../../../core/widgets/common/error_view.dart';
import '../../../../core/widgets/common/loading_view.dart';
import '../../../../core/widgets/common/primary_button.dart';
import '../../../../core/widgets/common/secondary_button.dart';
import '../../../../core/widgets/glass/glass_container.dart';
import '../../../../routes/route_names.dart';
import '../../../../services/supabase_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/onboarding_provider.dart';

class _OnboardingSlideData {
  const _OnboardingSlideData({
    required this.badge,
    required this.title,
    required this.description,
    required this.icon,
    required this.accentColor,
  });

  final String badge;
  final String title;
  final String description;
  final IconData icon;
  final Color accentColor;
}

/// Layar Onboarding 3 slide yang memperkenalkan fitur utama EduEarth
/// dan menyimpan status selesai ke `SharedPreferences`.
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
      badge: 'Peta Interaktif',
      title: 'Jelajahi Pembangkit Energi Terbarukan Indonesia',
      description:
          'Temukan lokasi PLTS, PLTA, PLTB, PLTP, dan Bioenergi terverifikasi di seluruh Nusantara melalui peta OpenStreetMap interaktif.',
      icon: Icons.map_rounded,
      accentColor: AppColors.freshGreen,
    ),
    _OnboardingSlideData(
      badge: 'Materi Edukatif',
      title: 'Pelajari Cara Kerja Energi Bersih Secara Ringkas',
      description:
          'Baca materi terstruktur tentang 5 kategori energi terbarukan, potensi geografis Indonesia, serta dampaknya bagi bumi.',
      icon: Icons.menu_book_rounded,
      accentColor: AppColors.skyBlue,
    ),
    _OnboardingSlideData(
      badge: 'Kuis Interaktif',
      title: 'Uji Pemahaman & Pantau Progres Belajarmu',
      description:
          'Kerjakan kuis dengan pembahasan lengkap untuk menguji wawasanmu seputar transisi energi bersih.',
      icon: Icons.quiz_rounded,
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
      body: SafeArea(
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.eco_rounded,
                            color: AppColors.forestGreen,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text('EduEarth', style: AppTextStyles.subtitle),
                        ],
                      ),
                      TextButton(
                        onPressed: _isSaving ? null : _finishOnboarding,
                        child: Text(
                          'Lewati',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
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
                                  ? AppColors.freshGreen
                                  : AppColors.sageGreen.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(
                                AppTheme.pillRadius,
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 24),
                      PrimaryButton(
                        label: _currentIndex == _slides.length - 1
                            ? 'Mulai Sekarang'
                            : 'Lanjutkan',
                        icon: _currentIndex == _slides.length - 1
                            ? Icons.rocket_launch_rounded
                            : Icons.arrow_forward_rounded,
                        isLoading: _isSaving,
                        onPressed: _nextSlide,
                      ),
                      if (_currentIndex > 0) ...[
                        const SizedBox(height: 10),
                        SecondaryButton(
                          label: 'Sebelumnya',
                          onPressed: () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 240),
                              curve: Curves.easeOutCubic,
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSlideCard(_OnboardingSlideData slide) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                colors: [
                  AppColors.forestGreen,
                  slide.accentColor.withValues(alpha: 0.85),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: GlassContainer(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 28,
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: AppColors.mintGreen,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      slide.icon,
                      size: 40,
                      color: AppColors.forestGreen,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.mintGreen,
                      borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                    ),
                    child: Text(
                      slide.badge,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.forestGreen,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            slide.title,
            style: AppTextStyles.display.copyWith(fontSize: 24),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            slide.description,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}


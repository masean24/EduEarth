import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/common/error_view.dart';
import '../../../../core/widgets/common/soft_image_placeholder.dart';
import '../../../../routes/route_names.dart';
import '../../../../services/supabase_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../onboarding/presentation/providers/onboarding_provider.dart';

/// Layar pembuka (Splash Screen) bergaya `docs/design/moodboard.png` yang
/// memeriksa status onboarding dan sesi autentikasi sebelum mengarahkan pengguna.
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _evaluateNavigation();
    });
  }

  Future<void> _evaluateNavigation() async {
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;

    final onboardingAsync = ref.read(onboardingStatusProvider);
    if (onboardingAsync.isLoading) {
      await ref.read(onboardingStatusProvider.future);
    }
    if (!mounted) return;

    final isOnboardingDone =
        ref.read(onboardingStatusProvider).value ?? false;
    final isAuthenticated = ref.read(isAuthenticatedProvider);
    final isSupabaseReady = ref.read(isSupabaseInitializedProvider);

    if (!isOnboardingDone) {
      context.go(RouteNames.onboardingPath);
      return;
    }

    if (isSupabaseReady && !isAuthenticated) {
      context.go(RouteNames.loginPath);
      return;
    }

    context.go(RouteNames.homePath);
  }

  @override
  Widget build(BuildContext context) {
    final onboardingAsync = ref.watch(onboardingStatusProvider);

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE3F5EA),
              AppColors.offWhite,
              Color(0xFFDDF3E4),
            ],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: onboardingAsync.when(
            loading: () => _buildSplashContent(),
            error: (error, _) => ErrorView(
              title: 'Gagal Memulai Aplikasi',
              message: error.toString(),
              onRetry: () {
                ref.invalidate(onboardingStatusProvider);
                _evaluateNavigation();
              },
            ),
            data: (_) => _buildSplashContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildSplashContent() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Aksen lingkaran cahaya lembut di latar atas sesuai moodboard
        Positioned(
          top: -60,
          right: -40,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.mintGreen.withValues(alpha: 0.65),
            ),
          ),
        ),
        Positioned(
          top: 90,
          left: -50,
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.mintGreen.withValues(alpha: 0.45),
            ),
          ),
        ),

        // Ilustrasi bukit hijau & maskot Eco di bagian bawah layar
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SoftImagePlaceholder(
                  height: 150,
                  width: double.infinity,
                  borderRadius: 24,
                  assetPath: 'assets/images/branding/splash_landscape.png',
                  backgroundColor: AppColors.mintGreen.withValues(alpha: 0.4),
                  fallbackIcon: Icons.landscape_rounded,
                  iconColor: AppColors.forestGreen,
                  iconSize: 48,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 44,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF2E7D4F),
                      AppColors.forestGreen,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(32),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Konten utama tengah: Logo EduEarth + Judul + Tagline + Indikator
        Align(
          alignment: const Alignment(0, -0.22),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SoftImagePlaceholder(
                  width: 112,
                  height: 112,
                  borderRadius: 32,
                  assetPath: 'assets/images/branding/logo_eduearth.png',
                  backgroundColor: Colors.transparent,
                  fallbackIcon: Icons.eco_rounded,
                  iconColor: AppColors.forestGreen,
                  iconSize: 56,
                ),
                const SizedBox(height: 18),
                Text(
                  AppConstants.appName,
                  style: AppTextStyles.display.copyWith(
                    fontSize: 34,
                    color: AppColors.forestGreen,
                    letterSpacing: -0.6,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Explore Energy,\nUnderstand Earth.',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.forestGreen.withValues(alpha: 0.82),
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                const SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.6,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.forestGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

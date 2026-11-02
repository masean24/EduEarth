import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/common/error_view.dart';
import '../../../../routes/route_names.dart';
import '../../../../services/supabase_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../onboarding/presentation/providers/onboarding_provider.dart';

/// Layar pembuka (Splash Screen) yang memeriksa status onboarding
/// dan sesi autentikasi pengguna sebelum mengarahkan ke halaman yang sesuai.
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
      body: SafeArea(
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
    );
  }

  Widget _buildSplashContent() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.mintGreen,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.freshGreen.withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.eco_rounded,
                size: 48,
                color: AppColors.forestGreen,
                semanticLabel: 'Logo EduEarth',
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppConstants.appName,
              style: AppTextStyles.display,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              AppConstants.appTagline,
              style: AppTextStyles.subtitle.copyWith(
                color: AppColors.freshGreen,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.8,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.freshGreen,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


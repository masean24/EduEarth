import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/common/design_system_showcase_page.dart';
import '../core/widgets/common/error_view.dart';
import '../core/widgets/common/loading_view.dart';
import '../core/widgets/common/primary_button.dart';
import '../core/widgets/common/secondary_button.dart';
import '../core/widgets/glass/glass_container.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/register_page.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/home/presentation/pages/home_dashboard_page.dart';
import '../features/map/presentation/pages/explore_map_page.dart';
import '../features/map/presentation/pages/nearby_plants_page.dart';
import '../features/onboarding/presentation/pages/onboarding_page.dart';
import '../features/onboarding/presentation/providers/onboarding_provider.dart';
import '../features/plants/presentation/pages/plant_detail_page.dart';
import '../features/splash/presentation/pages/splash_page.dart';
import '../services/supabase_service.dart';
import 'route_names.dart';

/// Notifier internal untuk memicu evaluasi ulang redirect GoRouter
/// ketika status onboarding atau sesi autentikasi berubah.
class _RouterRefreshListenable extends ChangeNotifier {
  void notify() => notifyListeners();
}

/// Provider GoRouter utama untuk aplikasi EduEarth.
final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshListenable = _RouterRefreshListenable();
  ref.onDispose(refreshListenable.dispose);

  ref.listen(onboardingStatusProvider, (_, _) => refreshListenable.notify());
  ref.listen(currentSessionProvider, (_, _) => refreshListenable.notify());

  return GoRouter(
    initialLocation: RouteNames.splashPath,
    refreshListenable: refreshListenable,
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final location = state.matchedLocation;

      if (location == RouteNames.designShowcasePath) {
        return null;
      }

      final onboardingAsync = ref.read(onboardingStatusProvider);
      if (onboardingAsync.isLoading) {
        return location == RouteNames.splashPath
            ? null
            : RouteNames.splashPath;
      }

      final isOnboardingDone = onboardingAsync.value ?? false;
      final isSupabaseReady = ref.read(isSupabaseInitializedProvider);
      final isAuthenticated = ref.read(isAuthenticatedProvider);

      if (!isOnboardingDone) {
        if (location == RouteNames.onboardingPath ||
            location == RouteNames.splashPath) {
          return null;
        }
        return RouteNames.onboardingPath;
      }

      final isAuthRoute =
          location == RouteNames.loginPath ||
          location == RouteNames.registerPath;

      if (isSupabaseReady && !isAuthenticated) {
        if (isAuthRoute || location == RouteNames.splashPath) {
          return null;
        }
        return RouteNames.loginPath;
      }

      if (isAuthenticated &&
          (isAuthRoute || location == RouteNames.onboardingPath)) {
        return RouteNames.homePath;
      }

      return null;
    },
    routes: [
      GoRoute(
        name: RouteNames.splashName,
        path: RouteNames.splashPath,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        name: RouteNames.onboardingName,
        path: RouteNames.onboardingPath,
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        name: RouteNames.loginName,
        path: RouteNames.loginPath,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        name: RouteNames.registerName,
        path: RouteNames.registerPath,
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        name: RouteNames.designShowcaseName,
        path: RouteNames.designShowcasePath,
        builder: (context, state) => const DesignSystemShowcasePage(),
      ),
      GoRoute(
        name: RouteNames.plantDetailName,
        path: RouteNames.plantDetailPath,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return PlantDetailPage(plantId: id);
        },
      ),
      GoRoute(
        name: RouteNames.nearbyPlantsName,
        path: RouteNames.nearbyPlantsPath,
        builder: (context, state) => const NearbyPlantsPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return _MainShellScaffold(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: RouteNames.homeName,
                path: RouteNames.homePath,
                builder: (context, state) => const HomeDashboardPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: RouteNames.exploreMapName,
                path: RouteNames.exploreMapPath,
                builder: (context, state) => const ExploreMapPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: RouteNames.learningName,
                path: RouteNames.learningPath,
                builder: (context, state) => const _PlaceholderScreen(
                  title: 'Learning Dashboard',
                  phaseLabel: 'Fase 3 — Pembelajaran dan Bookmark',
                  description:
                      'Eksplorasi materi pembelajaran 5 kategori energi terbarukan Indonesia (PLTS, PLTA, PLTB, PLTP, Bioenergi).',
                  icon: Icons.menu_book_rounded,
                  showShowcaseButton: true,
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: RouteNames.quizName,
                path: RouteNames.quizPath,
                builder: (context, state) => const _PlaceholderScreen(
                  title: 'Quiz Dashboard',
                  phaseLabel: 'Fase 4 — Kuis',
                  description:
                      'Uji pemahaman energi terbarukan dengan penilaian aman di sisi server (Supabase RPC).',
                  icon: Icons.quiz_rounded,
                  showShowcaseButton: true,
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: RouteNames.profileName,
                path: RouteNames.profilePath,
                builder: (context, state) => const _Phase1ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

/// Kerangka navigasi bawah 5 tab menggunakan efek Liquid Glass selektif.
class _MainShellScaffold extends StatelessWidget {
  const _MainShellScaffold({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: GlassContainer(
            borderRadius: 24,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: NavigationBarTheme(
              data: NavigationBarThemeData(
                backgroundColor: Colors.transparent,
                indicatorColor: AppColors.mintGreen,
                labelTextStyle: WidgetStateProperty.resolveWith((states) {
                  final isSelected = states.contains(WidgetState.selected);
                  return AppTextStyles.caption.copyWith(
                    color: isSelected
                        ? AppColors.forestGreen
                        : AppColors.textMuted,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                  );
                }),
              ),
              child: NavigationBar(
                height: 60,
                elevation: 0,
                backgroundColor: Colors.transparent,
                selectedIndex: navigationShell.currentIndex,
                onDestinationSelected: (index) {
                  navigationShell.goBranch(
                    index,
                    initialLocation: index == navigationShell.currentIndex,
                  );
                },
                destinations: const [
                  NavigationDestination(
                    icon: Icon(
                      Icons.home_outlined,
                      color: AppColors.textMuted,
                    ),
                    selectedIcon: Icon(
                      Icons.home_rounded,
                      color: AppColors.forestGreen,
                    ),
                    label: 'Home',
                  ),
                  NavigationDestination(
                    icon: Icon(
                      Icons.map_outlined,
                      color: AppColors.textMuted,
                    ),
                    selectedIcon: Icon(
                      Icons.map_rounded,
                      color: AppColors.forestGreen,
                    ),
                    label: 'Explore',
                  ),
                  NavigationDestination(
                    icon: Icon(
                      Icons.menu_book_outlined,
                      color: AppColors.textMuted,
                    ),
                    selectedIcon: Icon(
                      Icons.menu_book_rounded,
                      color: AppColors.forestGreen,
                    ),
                    label: 'Learn',
                  ),
                  NavigationDestination(
                    icon: Icon(
                      Icons.quiz_outlined,
                      color: AppColors.textMuted,
                    ),
                    selectedIcon: Icon(
                      Icons.quiz_rounded,
                      color: AppColors.forestGreen,
                    ),
                    label: 'Quiz',
                  ),
                  NavigationDestination(
                    icon: Icon(
                      Icons.person_outline_rounded,
                      color: AppColors.textMuted,
                    ),
                    selectedIcon: Icon(
                      Icons.person_rounded,
                      color: AppColors.forestGreen,
                    ),
                    label: 'Profile',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Phase1ProfileScreen extends ConsumerWidget {
  const _Phase1ProfileScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(currentSessionProvider);
    final profileAsync = ref.watch(currentUserProfileProvider);
    final authController = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil & Sesi Akun'),
      ),
      body: SafeArea(
        child: profileAsync.when(
          loading: () =>
              const LoadingView(message: 'Memuat profil pengguna...'),
          error: (error, _) => ErrorView(
            message: error.toString(),
            onRetry: () => ref.invalidate(currentUserProfileProvider),
          ),
          data: (profile) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 120),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWhite,
                    borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: const BoxDecoration(
                          color: AppColors.mintGreen,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          size: 36,
                          color: AppColors.forestGreen,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        profile?.displayName ??
                            session?.user.email ??
                            'Pengguna Tamu (Mode Lokal)',
                        style: AppTextStyles.title,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        session?.user.email ??
                            'Belum masuk dengan akun Supabase',
                        style: AppTextStyles.caption,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (session != null)
                  PrimaryButton(
                    label: 'Keluar (Logout)',
                    icon: Icons.logout_rounded,
                    isLoading: authController.isLoading,
                    onPressed: () async {
                      await ref
                          .read(authControllerProvider.notifier)
                          .signOut();
                    },
                  )
                else
                  PrimaryButton(
                    label: 'Ke Halaman Masuk (Login)',
                    icon: Icons.login_rounded,
                    onPressed: () => context.push(RouteNames.loginPath),
                  ),
                const SizedBox(height: 12),
                SecondaryButton(
                  label: 'Ulangi Onboarding',
                  icon: Icons.replay_rounded,
                  onPressed: () async {
                    await ref
                        .read(onboardingStatusProvider.notifier)
                        .resetOnboarding();
                    if (context.mounted) {
                      context.go(RouteNames.onboardingPath);
                    }
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PlaceholderScreen extends ConsumerWidget {
  const _PlaceholderScreen({
    required this.title,
    required this.phaseLabel,
    required this.description,
    required this.icon,
    this.showShowcaseButton = false,
  });

  final String title;
  final String phaseLabel;
  final String description;
  final IconData icon;
  final bool showShowcaseButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuthenticated = ref.watch(isAuthenticatedProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (showShowcaseButton)
            IconButton(
              tooltip: 'Buka Demo Komponen & Design System',
              onPressed: () => context.push(RouteNames.designShowcasePath),
              icon: const Icon(Icons.palette_outlined),
            ),
          if (isAuthenticated)
            IconButton(
              tooltip: 'Keluar (Logout)',
              onPressed: () =>
                  ref.read(authControllerProvider.notifier).signOut(),
              icon: const Icon(Icons.logout_rounded),
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: AppColors.mintGreen,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 36, color: AppColors.forestGreen),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.mintGreen,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    phaseLabel,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.forestGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: AppTextStyles.display,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  AppConstants.appTagline,
                  style: AppTextStyles.subtitle.copyWith(
                    color: AppColors.freshGreen,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  description,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (showShowcaseButton) ...[
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: 'Buka Demo Komponen & Glass UI',
                    icon: Icons.auto_awesome_rounded,
                    isExpanded: false,
                    onPressed: () =>
                        context.push(RouteNames.designShowcasePath),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

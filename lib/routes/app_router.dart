import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/common/design_system_showcase_page.dart';
import '../core/widgets/glass/glass_bottom_nav.dart';
import '../features/achievement/presentation/pages/achievements_page.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/register_page.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/bookmark/presentation/pages/bookmarks_page.dart';
import '../features/home/presentation/pages/home_dashboard_page.dart';
import '../features/learning/presentation/pages/energy_category_page.dart';
import '../features/learning/presentation/pages/energy_comparison_page.dart';
import '../features/learning/presentation/pages/learning_dashboard_page.dart';
import '../features/learning/presentation/pages/learning_detail_page.dart';
import '../features/map/presentation/pages/explore_map_page.dart';
import '../features/map/presentation/pages/nearby_plants_page.dart';
import '../features/notification/presentation/pages/notifications_page.dart';
import '../features/onboarding/presentation/pages/onboarding_page.dart';
import '../features/onboarding/presentation/providers/onboarding_provider.dart';
import '../features/plants/presentation/pages/plant_detail_page.dart';
import '../features/profile/presentation/pages/my_learning_page.dart';
import '../features/profile/presentation/pages/profile_page.dart';
import '../features/quiz/presentation/pages/quiz_dashboard_page.dart';
import '../features/quiz/presentation/pages/quiz_gameplay_page.dart';
import '../features/quiz/presentation/pages/quiz_result_page.dart';
import '../features/search/presentation/pages/global_search_page.dart';
import '../features/settings/presentation/pages/about_page.dart';
import '../features/settings/presentation/pages/settings_page.dart';
import '../features/splash/presentation/pages/splash_page.dart';
import '../models/quiz_attempt.dart';
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
      GoRoute(
        name: RouteNames.energyCategoryName,
        path: RouteNames.energyCategoryPath,
        builder: (context, state) {
          final slug = state.pathParameters['slug'] ?? '';
          return EnergyCategoryPage(categorySlug: slug);
        },
      ),
      GoRoute(
        name: RouteNames.learningDetailName,
        path: RouteNames.learningDetailPath,
        builder: (context, state) {
          final slug = state.pathParameters['slug'] ?? '';
          return LearningDetailPage(materialSlug: slug);
        },
      ),
      GoRoute(
        name: RouteNames.bookmarksName,
        path: RouteNames.bookmarksPath,
        builder: (context, state) => const BookmarksPage(),
      ),
      GoRoute(
        name: RouteNames.quizGameplayName,
        path: RouteNames.quizGameplayPath,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return QuizGameplayPage(quizId: id);
        },
      ),
      GoRoute(
        name: RouteNames.quizResultName,
        path: RouteNames.quizResultPath,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          final extraResult = state.extra is QuizSubmissionResult
              ? state.extra as QuizSubmissionResult
              : null;
          return QuizResultPage(
            quizId: id,
            initialResult: extraResult,
          );
        },
      ),
      GoRoute(
        name: RouteNames.myLearningName,
        path: RouteNames.myLearningPath,
        builder: (context, state) => const MyLearningPage(),
      ),
      GoRoute(
        name: RouteNames.settingsName,
        path: RouteNames.settingsPath,
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        name: RouteNames.aboutName,
        path: RouteNames.aboutPath,
        builder: (context, state) => const AboutPage(),
      ),
      GoRoute(
        name: RouteNames.searchName,
        path: RouteNames.searchPath,
        builder: (context, state) => const GlobalSearchPage(),
      ),
      GoRoute(
        name: RouteNames.achievementsName,
        path: RouteNames.achievementsPath,
        builder: (context, state) => const AchievementsPage(),
      ),
      GoRoute(
        name: RouteNames.notificationsName,
        path: RouteNames.notificationsPath,
        builder: (context, state) => const NotificationsPage(),
      ),
      GoRoute(
        name: RouteNames.energyComparisonName,
        path: RouteNames.energyComparisonPath,
        builder: (context, state) => const EnergyComparisonPage(),
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
                builder: (context, state) => const LearningDashboardPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: RouteNames.quizName,
                path: RouteNames.quizPath,
                builder: (context, state) => const QuizDashboardPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: RouteNames.profileName,
                path: RouteNames.profilePath,
                builder: (context, state) => const ProfilePage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

/// Kerangka navigasi bawah 5 tab menggunakan `GlassBottomNav` dengan transisi
/// halus (fade + slide ringan) saat berpindah antar-tab utama.
class _MainShellScaffold extends StatelessWidget {
  const _MainShellScaffold({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: TweenAnimationBuilder<double>(
        key: ValueKey<int>(navigationShell.currentIndex),
        tween: Tween<double>(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Opacity(
            opacity: 0.85 + (0.15 * value),
            child: Transform.translate(
              offset: Offset(0, (1 - value) * 8),
              child: child,
            ),
          );
        },
        child: navigationShell,
      ),
      bottomNavigationBar: GlassBottomNav(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
      ),
    );
  }
}

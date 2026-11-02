import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/widgets/common/design_system_showcase_page.dart';
import '../core/widgets/common/primary_button.dart';
import '../core/widgets/common/secondary_button.dart';
import '../core/widgets/glass/glass_container.dart';
import 'route_names.dart';

/// Provider GoRouter utama untuk aplikasi EduEarth.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: RouteNames.homePath,
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        name: RouteNames.splashName,
        path: RouteNames.splashPath,
        builder: (context, state) => const _PlaceholderScreen(
          title: 'Splash Screen',
          phaseLabel: 'Fase 1 — Database & Autentikasi',
          description:
              'Layar pembuka EduEarth yang memeriksa status onboarding dan sesi autentikasi pengguna.',
          icon: Icons.eco_rounded,
        ),
      ),
      GoRoute(
        name: RouteNames.onboardingName,
        path: RouteNames.onboardingPath,
        builder: (context, state) => const _PlaceholderScreen(
          title: 'Onboarding',
          phaseLabel: 'Fase 1 — Database & Autentikasi',
          description:
              'Pengenalan interaktif tentang peta pembangkit energi terbarukan, materi belajar, dan kuis.',
          icon: Icons.wb_sunny_outlined,
        ),
      ),
      GoRoute(
        name: RouteNames.loginName,
        path: RouteNames.loginPath,
        builder: (context, state) => const _PlaceholderScreen(
          title: 'Masuk (Login)',
          phaseLabel: 'Fase 1 — Database & Autentikasi',
          description: 'Halaman autentikasi pengguna dengan Supabase Auth.',
          icon: Icons.login_rounded,
        ),
      ),
      GoRoute(
        name: RouteNames.registerName,
        path: RouteNames.registerPath,
        builder: (context, state) => const _PlaceholderScreen(
          title: 'Daftar Akun (Register)',
          phaseLabel: 'Fase 1 — Database & Autentikasi',
          description:
              'Pendaftaran akun baru yang otomatis membuat profil melalui trigger handle_new_user.',
          icon: Icons.person_add_alt_1_rounded,
        ),
      ),
      GoRoute(
        name: RouteNames.designShowcaseName,
        path: RouteNames.designShowcasePath,
        builder: (context, state) => const DesignSystemShowcasePage(),
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
                builder: (context, state) => const _PlaceholderScreen(
                  title: 'Home Dashboard',
                  phaseLabel: 'Fase 0 Fondasi Aktif (Isi penuh di Fase 2)',
                  description:
                      'Selamat datang di EduEarth! Fondasi arsitektur, tema Nature Tech, GlassContainer, dan GoRouter 5 tab telah siap.',
                  icon: Icons.home_rounded,
                  showShowcaseButton: true,
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: RouteNames.exploreMapName,
                path: RouteNames.exploreMapPath,
                builder: (context, state) => const _PlaceholderScreen(
                  title: 'Explore Map (OSM)',
                  phaseLabel: 'Fase 2 — Peta dan Pembangkit',
                  description:
                      'Peta interaktif flutter_map + OpenStreetMap dengan marker per kategori energi dan filter chip Liquid Glass.',
                  icon: Icons.map_rounded,
                  showShowcaseButton: true,
                ),
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
                builder: (context, state) => const _PlaceholderScreen(
                  title: 'Profil Pengguna',
                  phaseLabel: 'Fase 5 — Profil dan Kelengkapan',
                  description:
                      'Kelola profil, riwayat belajar, bookmark, dan pengaturan efek visual.',
                  icon: Icons.person_rounded,
                  showShowcaseButton: true,
                ),
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

/// Layar placeholder Fase 0 untuk memverifikasi routing & tema.
class _PlaceholderScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
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
                  const SizedBox(height: 12),
                  SecondaryButton(
                    label: 'Cek Route Onboarding (Placeholder)',
                    icon: Icons.explore_outlined,
                    isExpanded: false,
                    onPressed: () => context.push(RouteNames.onboardingPath),
                  ),
                ] else ...[
                  const SizedBox(height: 24),
                  SecondaryButton(
                    label: 'Kembali ke Home',
                    icon: Icons.arrow_back_rounded,
                    isExpanded: false,
                    onPressed: () => context.go(RouteNames.homePath),
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


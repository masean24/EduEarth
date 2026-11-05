import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/common/empty_view.dart';
import '../../../../core/widgets/common/error_view.dart';
import '../../../../core/widgets/common/loading_view.dart';
import '../../../../core/widgets/common/primary_button.dart';
import '../../../../core/widgets/common/screen_header.dart';
import '../../../../core/widgets/common/soft_image_placeholder.dart';
import '../../../../models/achievement.dart';
import '../../../../models/user_profile.dart';
import '../../../../routes/route_names.dart';
import '../../../achievement/presentation/providers/achievement_providers.dart';
import '../../../achievement/presentation/widgets/achievement_unlock_dialog.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../bookmark/presentation/providers/bookmark_providers.dart';
import '../../../quiz/presentation/providers/quiz_providers.dart';
import '../providers/profile_providers.dart';

/// Halaman Profil Pengguna (Tab Profile) dengan:
/// - Kartu Hero Identitas Nature-Tech (Avatar, Nama, Gelar Penjelajah, Poin, & 3 Statistik Interaktif)
/// - Etalase Horizontal Koleksi Lencana (ketuk badge terbuka untuk memutar animasi perayaan)
/// - Grup Menu Terstruktur & Informasi Versi Aplikasi
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  Future<void> _showEditProfileSheet(
    BuildContext context,
    WidgetRef ref,
    UserProfile? currentProfile,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.bottomSheetRadius),
        ),
      ),
      builder: (_) => _EditProfileBottomSheet(initialProfile: currentProfile),
    );
  }

  static String _explorerRankLabel(int unlockedBadges) {
    if (unlockedBadges >= 9) return '🏆 Master EduEarth';
    if (unlockedBadges >= 5) return '⚡ Ahli Transisi Nusantara';
    if (unlockedBadges >= 2) return '🌿 Duta Energi Bersih';
    return '🌱 Penjelajah Energi';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(currentSessionProvider);
    final profileAsync = ref.watch(currentUserProfileProvider);
    final bookmarksAsync = ref.watch(userBookmarksProvider);
    final attemptsAsync = ref.watch(userQuizAttemptsProvider);
    final achievementsAsync = ref.watch(achievementsListProvider);
    final authController = ref.watch(authControllerProvider);

    final bottomSafe = MediaQuery.viewPaddingOf(context).bottom;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: profileAsync.when(
          loading: () => const LoadingView(
            message: 'Memuat profil pengguna...',
          ),
          error: (error, _) => ErrorView(
            message: error.toString(),
            onRetry: () => ref.invalidate(currentUserProfileProvider),
          ),
          data: (profile) {
            if (session == null) {
              return EmptyView(
                icon: Icons.person_outline_rounded,
                title: 'Belum Masuk ke Akun',
                description:
                    'Masuk ke akun EduEarth Anda untuk mengelola profil, melihat progres belajar, dan menyimpan bookmark.',
                actionLabel: 'Masuk (Login)',
                onAction: () => context.push(RouteNames.loginPath),
              );
            }

            final bookmarkCount = bookmarksAsync.asData?.value.length ?? 0;
            final quizAttemptCount = attemptsAsync.asData?.value.length ?? 0;
            final avatarUrl = profile?.avatarUrl?.trim() ?? '';
            final badgeCount = ref.watch(unlockedAchievementCountProvider);
            final totalPoints = ref.watch(unlockedAchievementPointsProvider);
            final achievements =
                achievementsAsync.asData?.value ?? const <Achievement>[];

            return RefreshIndicator(
              color: AppColors.freshGreen,
              onRefresh: () async {
                ref.invalidate(currentUserProfileProvider);
                ref.invalidate(userBookmarksProvider);
                ref.invalidate(userQuizAttemptsProvider);
                ref.invalidate(achievementsListProvider);
              },
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  16,
                  20,
                  AppTheme.bottomNavScrollPadding + bottomSafe,
                ),
                children: [
                  ScreenHeader(
                    title: 'Profil Saya',
                    subtitle: 'Kelola akun dan pantau progres belajar Anda',
                    actions: [
                      ScreenHeaderAction(
                        tooltip: 'Ubah Profil',
                        icon: Icons.edit_outlined,
                        onTap: () =>
                            _showEditProfileSheet(context, ref, profile),
                      ),
                      ScreenHeaderAction(
                        tooltip: 'Pengaturan Aplikasi',
                        icon: Icons.settings_outlined,
                        onTap: () => context.push(RouteNames.settingsPath),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 1. Kartu Hero Identitas & Statistik Interaktif
                  _buildProfileHeroCard(
                    context: context,
                    ref: ref,
                    profile: profile,
                    email: session.user.email ?? '',
                    avatarUrl: avatarUrl,
                    bookmarkCount: bookmarkCount,
                    quizAttemptCount: quizAttemptCount,
                    badgeCount: badgeCount,
                    totalPoints: totalPoints,
                  ),
                  const SizedBox(height: 18),

                  // 2. Etalase Koleksi Lencana Horizontal
                  if (achievements.isNotEmpty) ...[
                    _buildBadgeShowcaseCard(
                      context: context,
                      achievements: achievements,
                      unlockedCount: badgeCount,
                    ),
                    const SizedBox(height: 18),
                  ],

                  // 3. Grup Menu: Aktivitas & Pembelajaran
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      'Aktivitas & Pembelajaran',
                      style: AppTextStyles.subtitle.copyWith(fontSize: 15),
                    ),
                  ),
                  Container(
                    decoration: AppTheme.cardDecoration(),
                    child: Column(
                      children: [
                        _MoodboardMenuTile(
                          icon: Icons.menu_book_rounded,
                          iconBackground: const Color(0xFFFEF9C3),
                          iconColor: const Color(0xFFD97706),
                          title: 'Progres Belajar Saya',
                          subtitle: 'Riwayat nilai kuis & statistik belajar',
                          onTap: () => context.push(RouteNames.myLearningPath),
                        ),
                        const Divider(height: 1, indent: 68),
                        _MoodboardMenuTile(
                          icon: Icons.bookmark_rounded,
                          iconBackground: AppColors.mintGreen,
                          iconColor: AppColors.forestGreen,
                          title: 'Daftar Tersimpan',
                          subtitle:
                              '$bookmarkCount materi & pembangkit favorit',
                          onTap: () => context.push(RouteNames.bookmarksPath),
                        ),
                        const Divider(height: 1, indent: 68),
                        _MoodboardMenuTile(
                          icon: Icons.emoji_events_rounded,
                          iconBackground: const Color(0xFFFEF9C3),
                          iconColor: const Color(0xFFD97706),
                          title: 'Pencapaian & Badge',
                          subtitle:
                              '$badgeCount lencana terbuka • $totalPoints Poin',
                          onTap: () =>
                              context.push(RouteNames.achievementsPath),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 4. Grup Menu: Eksplorasi & Informasi
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      'Eksplorasi & Informasi',
                      style: AppTextStyles.subtitle.copyWith(fontSize: 15),
                    ),
                  ),
                  Container(
                    decoration: AppTheme.cardDecoration(),
                    child: Column(
                      children: [
                        _MoodboardMenuTile(
                          icon: Icons.compare_arrows_rounded,
                          iconBackground: AppColors.mintGreen,
                          iconColor: AppColors.forestGreen,
                          title: 'Perbandingan Energi',
                          subtitle: 'Bandingkan karakteristik 5 sumber EBT',
                          onTap: () =>
                              context.push(RouteNames.energyComparisonPath),
                        ),
                        const Divider(height: 1, indent: 68),
                        _MoodboardMenuTile(
                          icon: Icons.campaign_rounded,
                          iconBackground: const Color(0xFFE0F2FE),
                          iconColor: AppColors.skyBlue,
                          title: 'Pusat Informasi',
                          subtitle: 'Pengumuman & pembaruan materi EduEarth',
                          onTap: () =>
                              context.push(RouteNames.notificationsPath),
                        ),
                        const Divider(height: 1, indent: 68),
                        _MoodboardMenuTile(
                          icon: Icons.search_rounded,
                          iconBackground: const Color(0xFFE0F2FE),
                          iconColor: AppColors.skyBlue,
                          title: 'Pencarian Global',
                          subtitle: 'Cari cepat pembangkit, materi, dan kuis',
                          onTap: () => context.push(RouteNames.searchPath),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 5. Grup Menu: Pengaturan & Tentang
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      'Akun & Pengaturan',
                      style: AppTextStyles.subtitle.copyWith(fontSize: 15),
                    ),
                  ),
                  Container(
                    decoration: AppTheme.cardDecoration(),
                    child: Column(
                      children: [
                        _MoodboardMenuTile(
                          icon: Icons.edit_outlined,
                          iconBackground: AppColors.mintGreen,
                          iconColor: AppColors.forestGreen,
                          title: 'Ubah Profil',
                          subtitle: 'Perbarui nama tampilan & foto avatar',
                          onTap: () => _showEditProfileSheet(
                            context,
                            ref,
                            profile,
                          ),
                        ),
                        const Divider(height: 1, indent: 68),
                        _MoodboardMenuTile(
                          icon: Icons.settings_outlined,
                          iconBackground: AppColors.offWhite,
                          iconColor: AppColors.forestGreen,
                          title: 'Pengaturan Aplikasi',
                          subtitle: 'Efek visual Liquid Glass & onboarding',
                          onTap: () => context.push(RouteNames.settingsPath),
                        ),
                        const Divider(height: 1, indent: 68),
                        _MoodboardMenuTile(
                          icon: Icons.info_outline_rounded,
                          iconBackground: AppColors.offWhite,
                          iconColor: AppColors.forestGreen,
                          title: 'Tentang EduEarth',
                          subtitle:
                              'Sumber data, atribusi, & versi v${AppConstants.appVersion}',
                          onTap: () => context.push(RouteNames.aboutPath),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  PrimaryButton(
                    label: 'Keluar Akun',
                    icon: Icons.logout_rounded,
                    isLoading: authController.isLoading,
                    onPressed: () async {
                      await ref
                          .read(authControllerProvider.notifier)
                          .signOut();
                    },
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: Text(
                      '${AppConstants.appName} v${AppConstants.appVersion} (${AppConstants.appBuildNumber}) • Explore Energy, Understand Earth.',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileHeroCard({
    required BuildContext context,
    required WidgetRef ref,
    required UserProfile? profile,
    required String email,
    required String avatarUrl,
    required int bookmarkCount,
    required int quizAttemptCount,
    required int badgeCount,
    required int totalPoints,
  }) {
    final displayName = (profile?.displayName != null &&
            profile!.displayName!.trim().isNotEmpty)
        ? profile.displayName!.trim()
        : (email.isNotEmpty ? email.split('@').first : 'Pengguna EduEarth');

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.forestGreen,
            Color(0xFF1E7E48),
            Color(0xFF3CA662),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.forestGreen.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Lingkaran dekoratif halus di latar kanan atas
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.surfaceWhite.withValues(
                              alpha: 0.25,
                            ),
                            border: Border.all(
                              color: AppColors.surfaceWhite,
                              width: 2,
                            ),
                          ),
                          child: SoftImagePlaceholder(
                            width: 74,
                            height: 74,
                            borderRadius: 37,
                            networkImageUrl: avatarUrl,
                            assetPath: 'assets/images/mascot/eco_happy.png',
                            backgroundColor: AppColors.mintGreen,
                            fallbackIcon: Icons.person_rounded,
                            iconColor: AppColors.forestGreen,
                            iconSize: 38,
                          ),
                        ),
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Material(
                            color: AppColors.freshGreen,
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () => _showEditProfileSheet(
                                context,
                                ref,
                                profile,
                              ),
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.surfaceWhite,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.edit_rounded,
                                  size: 13,
                                  color: AppColors.surfaceWhite,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceWhite.withValues(
                                    alpha: 0.18,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.pillRadius,
                                  ),
                                  border: Border.all(
                                    color: AppColors.surfaceWhite.withValues(
                                      alpha: 0.35,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  _explorerRankLabel(badgeCount),
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.surfaceWhite,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              if (totalPoints > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.pillRadius,
                                    ),
                                  ),
                                  child: Text(
                                    '⚡ $totalPoints Poin',
                                    style: AppTextStyles.caption.copyWith(
                                      color: const Color(0xFFB45309),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.display.copyWith(
                              color: AppColors.surfaceWhite,
                              fontSize: 21,
                              height: 1.15,
                            ),
                          ),
                          if (email.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.mintGreen.withValues(
                                  alpha: 0.92,
                                ),
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                // Baris 3 Statistik Interaktif di dalam kartu hero
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWhite,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _InteractiveStatItem(
                          icon: Icons.bookmark_rounded,
                          iconColor: AppColors.forestGreen,
                          value: '$bookmarkCount',
                          label: 'Tersimpan',
                          onTap: () => context.push(RouteNames.bookmarksPath),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 34,
                        color: AppColors.divider,
                      ),
                      Expanded(
                        child: _InteractiveStatItem(
                          icon: Icons.quiz_rounded,
                          iconColor: AppColors.skyBlue,
                          value: '$quizAttemptCount',
                          label: 'Kuis Selesai',
                          onTap: () => context.push(RouteNames.myLearningPath),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 34,
                        color: AppColors.divider,
                      ),
                      Expanded(
                        child: _InteractiveStatItem(
                          icon: Icons.emoji_events_rounded,
                          iconColor: const Color(0xFFD97706),
                          value: '$badgeCount',
                          label: 'Badge',
                          onTap: () =>
                              context.push(RouteNames.achievementsPath),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeShowcaseCard({
    required BuildContext context,
    required List<Achievement> achievements,
    required int unlockedCount,
  }) {
    final total = achievements.length;
    final progress = total > 0 ? unlockedCount / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.workspace_premium_rounded,
                    color: Color(0xFFD97706),
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Etalase Lencana ($unlockedCount/$total)',
                    style: AppTextStyles.subtitle.copyWith(fontSize: 15),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => context.push(RouteNames.achievementsPath),
                child: Text(
                  'Lihat Semua →',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.forestGreen,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.pillRadius),
            child: LinearProgressIndicator(
              value: progress.clamp(0.04, 1.0),
              minHeight: 6,
              backgroundColor: AppColors.offWhite,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.freshGreen,
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 86,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: achievements.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final item = achievements[index];
                final isUnlocked = item.isUnlocked;

                return GestureDetector(
                  onTap: () {
                    if (isUnlocked) {
                      showAchievementUnlockDialog(
                        context,
                        badgeTitles: <String>[item.title],
                        singleAchievement: item,
                        isReplay: true,
                      );
                    } else {
                      context.push(RouteNames.achievementsPath);
                    }
                  },
                  child: SizedBox(
                    width: 72,
                    child: Column(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: isUnlocked
                                ? const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFFFDE047),
                                      Color(0xFFF59E0B),
                                    ],
                                  )
                                : null,
                            color: isUnlocked ? null : AppColors.offWhite,
                            border: Border.all(
                              color: isUnlocked
                                  ? const Color(0xFFD97706)
                                  : AppColors.divider,
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            iconForAchievementCode(item.icon),
                            size: 24,
                            color: isUnlocked
                                ? AppColors.surfaceWhite
                                : AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 10.5,
                            fontWeight: isUnlocked
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isUnlocked
                                ? AppColors.forestGreen
                                : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _InteractiveStatItem extends StatelessWidget {
  const _InteractiveStatItem({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: iconColor),
                const SizedBox(width: 5),
                Text(
                  value,
                  style: AppTextStyles.display.copyWith(
                    fontSize: 20,
                    height: 1.1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoodboardMenuTile extends StatelessWidget {
  const _MoodboardMenuTile({
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.forestGreen,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontSize: 11.5,
              ),
            )
          : null,
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textSecondary,
        size: 20,
      ),
    );
  }
}

class _EditProfileBottomSheet extends ConsumerStatefulWidget {
  const _EditProfileBottomSheet({this.initialProfile});

  final UserProfile? initialProfile;

  @override
  ConsumerState<_EditProfileBottomSheet> createState() =>
      _EditProfileBottomSheetState();
}

class _EditProfileBottomSheetState
    extends ConsumerState<_EditProfileBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _avatarController;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialProfile?.displayName ?? '',
    );
    _avatarController = TextEditingController(
      text: widget.initialProfile?.avatarUrl ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _avatarController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _errorMessage = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final success = await ref
        .read(profileControllerProvider.notifier)
        .updateProfile(
          displayName: _nameController.text,
          avatarUrl: _avatarController.text,
        );

    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil berhasil diperbarui.')),
      );
    } else {
      final err = ref.read(profileControllerProvider).error;
      setState(() => _errorMessage = err?.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final controllerState = ref.watch(profileControllerProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, bottomInset + 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Edit Profil', style: AppTextStyles.title),
            const SizedBox(height: 16),
            if (_errorMessage != null) ...[
              Text(
                _errorMessage!,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.errorRed,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
            ],
            Text('Nama Tampilan', style: AppTextStyles.bodyMedium),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              validator: AppValidators.validateDisplayName,
              decoration: const InputDecoration(
                hintText: 'Masukkan nama tampilan Anda',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
            ),
            const SizedBox(height: 16),
            Text('URL Avatar (Opsional)', style: AppTextStyles.bodyMedium),
            const SizedBox(height: 8),
            TextFormField(
              controller: _avatarController,
              keyboardType: TextInputType.url,
              validator: (value) {
                final trimmed = value?.trim() ?? '';
                if (trimmed.isEmpty) return null;
                final uri = Uri.tryParse(trimmed);
                if (uri == null ||
                    !uri.hasAbsolutePath ||
                    (uri.scheme != 'https' && uri.scheme != 'http')) {
                  return 'Masukkan URL gambar yang valid (diawali https://).';
                }
                return null;
              },
              decoration: const InputDecoration(
                hintText: 'https://... (kosongkan untuk avatar bawaan)',
                prefixIcon: Icon(Icons.image_outlined),
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Simpan Perubahan',
              icon: Icons.check_rounded,
              isLoading: controllerState.isLoading,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}

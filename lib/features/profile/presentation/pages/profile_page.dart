import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/validators.dart';
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
import '../../../learning/presentation/providers/learning_providers.dart';
import '../../../learning/presentation/providers/reading_progress_provider.dart';
import '../../../notification/presentation/providers/notification_providers.dart';
import '../../../quiz/presentation/providers/quiz_providers.dart';
import '../providers/profile_providers.dart';
import '../widgets/profile_sections.dart';

/// Halaman Profil Pengguna (Tab Profile) bergaya Light Nature Tech modern:
/// - Hero card identitas, level poin lencana, & 4 statistik interaktif nyata
/// - Kartu aksi cepat "Lanjutkan belajar" kontekstual dari progres baca & kuis
/// - Etalase horizontal koleksi lencana terbuka vs terkunci
/// - Grid 2x2 "Belajar & progres" & kartu menu rapi "Akun & pengaturan"
/// - Tombol keluar akun dengan dialog konfirmasi aman
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  Future<void> _showEditProfileSheet(
    BuildContext context,
    UserProfile? currentProfile,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
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

  Future<void> _handleSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showProfileSignOutConfirmDialog(context);
    if (!confirmed || !context.mounted) return;
    await ref.read(authControllerProvider.notifier).signOut();
  }

  void _showLockedAchievementHint(BuildContext context, Achievement item) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text('Terkunci: ${item.description}'),
        action: SnackBarAction(
          label: 'Detail',
          onPressed: () => context.push(RouteNames.achievementsPath),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(currentSessionProvider);
    final profileAsync = ref.watch(currentUserProfileProvider);
    final bookmarksAsync = ref.watch(userBookmarksProvider);
    final attemptsAsync = ref.watch(userQuizAttemptsProvider);
    final quizSummariesAsync = ref.watch(quizAttemptsByQuizIdProvider);
    final quizzesAsync = ref.watch(publishedQuizzesProvider);
    final materialsAsync = ref.watch(allLearningMaterialsProvider);
    final readingState = ref.watch(readingProgressProvider);
    final achievementsAsync = ref.watch(achievementsListProvider);
    final unreadNotifications = ref.watch(unreadNotificationsCountProvider);
    final authController = ref.watch(authControllerProvider);

    final bottomSafe = MediaQuery.viewPaddingOf(context).bottom;

    return Scaffold(
      backgroundColor: ProfileLightPalette.canvasBg,
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
              return _buildGuestProfileView(
                context: context,
                bottomSafe: bottomSafe,
                unreadNotifications: unreadNotifications,
              );
            }

            final bookmarkCount = bookmarksAsync.asData?.value.length ?? 0;
            final quizAttemptCount = attemptsAsync.asData?.value.length ?? 0;
            final readMaterialsCount = readingState.startedCount();
            final avatarUrl = profile?.avatarUrl?.trim() ?? '';
            final email = session.user.email ?? '';
            final displayName =
                (profile?.displayName != null &&
                        profile!.displayName!.trim().isNotEmpty)
                    ? profile.displayName!.trim()
                    : (email.isNotEmpty
                        ? email.split('@').first
                        : 'Pengguna EduEarth');

            final badgeCount = ref.watch(unlockedAchievementCountProvider);
            final totalPoints = ref.watch(unlockedAchievementPointsProvider);
            final achievements =
                achievementsAsync.asData?.value ?? const <Achievement>[];
            final maxPoints = computeTotalPossibleBadgePoints(achievements);

            final materials = materialsAsync.asData?.value ?? const [];
            final quizzes = quizzesAsync.asData?.value ?? const [];
            final quizSummaries = quizSummariesAsync.asData?.value ?? const {};
            final continueTarget = resolveProfileContinueTarget(
              materials: materials,
              readingState: readingState,
              quizzes: quizzes,
              quizSummaries: quizSummaries,
            );

            return RefreshIndicator(
              color: AppColors.actionGreen,
              backgroundColor: ProfileLightPalette.cardBg,
              onRefresh: () async {
                ref.invalidate(currentUserProfileProvider);
                ref.invalidate(userBookmarksProvider);
                ref.invalidate(userQuizAttemptsProvider);
                ref.invalidate(achievementsListProvider);
                ref.invalidate(publishedQuizzesProvider);
                ref.invalidate(allLearningMaterialsProvider);
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  20,
                  16,
                  20,
                  AppTheme.bottomNavScrollPadding + bottomSafe,
                ),
                children: [
                  ScreenHeader(
                    title: 'Profil Saya',
                    subtitle: 'Kelola akun dan pantau progres belajarmu.',
                    actions: [
                      ScreenHeaderAction(
                        tooltip: 'Pencarian Global',
                        icon: Icons.search_rounded,
                        onTap: () => context.push(RouteNames.searchPath),
                      ),
                      ScreenHeaderAction(
                        tooltip: 'Pengaturan Aplikasi',
                        icon: Icons.settings_outlined,
                        onTap: () => context.push(RouteNames.settingsPath),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  ProfileHeroCard(
                    displayName: displayName,
                    email: email,
                    avatarUrl: avatarUrl,
                    rankLabel: computeProfileExplorerRankLabel(badgeCount),
                    earnedPoints: totalPoints,
                    maxPoints: maxPoints,
                    bookmarkCount: bookmarkCount,
                    quizAttemptCount: quizAttemptCount,
                    readMaterialsCount: readMaterialsCount,
                    badgeCount: badgeCount,
                    onEditProfileTap: () =>
                        _showEditProfileSheet(context, profile),
                    onBookmarksTap: () => context.push(RouteNames.bookmarksPath),
                    onAttemptsTap: () => context.push(RouteNames.myLearningPath),
                    onReadMaterialsTap: () =>
                        context.push(RouteNames.myLearningPath),
                    onBadgesTap: () => context.push(RouteNames.achievementsPath),
                  ),
                  const SizedBox(height: 14),
                  ProfileContinueBannerCard(
                    target: continueTarget,
                    onTap: () => context.push(continueTarget.routePath),
                  ),
                  if (achievements.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    ProfileBadgeShowcaseSection(
                      achievements: achievements,
                      unlockedCount: badgeCount,
                      onSeeAllTap: () =>
                          context.push(RouteNames.achievementsPath),
                      onUnlockedTap: (item) => showAchievementUnlockDialog(
                        context,
                        badgeTitles: <String>[item.title],
                        singleAchievement: item,
                        isReplay: true,
                      ),
                      onLockedTap: (item) =>
                          _showLockedAchievementHint(context, item),
                    ),
                  ],
                  const SizedBox(height: 20),
                  _buildSectionTitle('Belajar & progres'),
                  const SizedBox(height: 12),
                  ProfileQuickTilesGrid(
                    tiles: [
                      ProfileQuickTileData(
                        title: 'Progres & Skor',
                        subtitle: 'Perkembangan skor dan materi',
                        icon: Icons.trending_up_rounded,
                        iconBackground: AppColors.mintGreen,
                        iconColor: AppColors.actionGreen,
                        onTap: () => context.push(RouteNames.myLearningPath),
                      ),
                      ProfileQuickTileData(
                        title: 'Bandingkan 5 Energi',
                        subtitle: 'Karakteristik dan trade-off',
                        icon: Icons.compare_arrows_rounded,
                        iconBackground: const Color(0xFFE0F2FE),
                        iconColor: const Color(0xFF0E7490),
                        onTap: () =>
                            context.push(RouteNames.energyComparisonPath),
                      ),
                      ProfileQuickTileData(
                        title: 'Tersimpan',
                        subtitle: '$bookmarkCount materi & pembangkit favorit',
                        icon: Icons.bookmark_rounded,
                        iconBackground: AppColors.warningBg,
                        iconColor: AppColors.warningFg,
                        onTap: () => context.push(RouteNames.bookmarksPath),
                      ),
                      ProfileQuickTileData(
                        title: 'Pusat Informasi',
                        subtitle: 'Panduan 4 pilar & dataset',
                        icon: Icons.help_outline_rounded,
                        iconBackground: AppColors.mintGreen,
                        iconColor: AppColors.actionGreen,
                        badgeCount: unreadNotifications,
                        onTap: () => context.push(RouteNames.notificationsPath),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Akun & pengaturan'),
                  const SizedBox(height: 12),
                  ProfileSettingsMenuGroup(
                    rows: [
                      ProfileMenuRowData(
                        title: 'Ubah profil',
                        subtitle: 'Nama tampilan & foto avatar',
                        icon: Icons.edit_outlined,
                        onTap: () => _showEditProfileSheet(context, profile),
                      ),
                      ProfileMenuRowData(
                        title: 'Pengaturan aplikasi',
                        subtitle: 'Efek visual Liquid Glass & onboarding',
                        icon: Icons.tune_rounded,
                        onTap: () => context.push(RouteNames.settingsPath),
                      ),
                      ProfileMenuRowData(
                        title: 'Tentang EduEarth',
                        subtitle:
                            'Sumber data, atribusi & v${AppConstants.appVersion}',
                        icon: Icons.info_outline_rounded,
                        onTap: () => context.push(RouteNames.aboutPath),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ProfileSignOutButton(
                    isLoading: authController.isLoading,
                    onPressed: () => _handleSignOut(context, ref),
                  ),
                  const SizedBox(height: 14),
                  _buildVersionCaption(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildGuestProfileView({
    required BuildContext context,
    required double bottomSafe,
    required int unreadNotifications,
  }) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        AppTheme.bottomNavScrollPadding + bottomSafe,
      ),
      children: [
        ScreenHeader(
          title: 'Profil Saya',
          subtitle: 'Masuk untuk menyimpan progres & lencana belajarmu.',
          actions: [
            ScreenHeaderAction(
              tooltip: 'Pencarian Global',
              icon: Icons.search_rounded,
              onTap: () => context.push(RouteNames.searchPath),
            ),
            ScreenHeaderAction(
              tooltip: 'Pengaturan Aplikasi',
              icon: Icons.settings_outlined,
              onTap: () => context.push(RouteNames.settingsPath),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: ProfileLightPalette.heroSolid,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: ProfileLightPalette.heroSolid.withValues(alpha: 0.16),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.mintGreen,
                      border: Border.all(
                        color: AppColors.surfaceWhite,
                        width: 2.5,
                      ),
                    ),
                    child: const SoftImagePlaceholder(
                      width: 62,
                      height: 62,
                      borderRadius: 31,
                      assetPath: 'assets/images/mascot/eco_wave.png',
                      backgroundColor: AppColors.mintGreen,
                      fallbackIcon: Icons.person_outline_rounded,
                      iconColor: AppColors.forestGreen,
                      iconSize: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mode Tamu Aktif',
                          style: AppTextStyles.subtitle.copyWith(
                            color: AppColors.surfaceWhite,
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Masuk ke akun EduEarth untuk menyimpan riwayat kuis, progres baca, bookmark, dan badge.',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.surfaceWhite.withValues(
                              alpha: 0.85,
                            ),
                            fontSize: 12.5,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 48,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.surfaceWhite,
                    foregroundColor: ProfileLightPalette.heroSolid,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => context.push(RouteNames.loginPath),
                  icon: const Icon(Icons.login_rounded, size: 18),
                  label: const Text(
                    'Masuk / Daftar Akun',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        _buildSectionTitle('Jelajahi tanpa akun'),
        const SizedBox(height: 12),
        ProfileQuickTilesGrid(
          tiles: [
            ProfileQuickTileData(
              title: 'Bandingkan 5 Energi',
              subtitle: 'Karakteristik dan trade-off',
              icon: Icons.compare_arrows_rounded,
              iconBackground: const Color(0xFFE0F2FE),
              iconColor: const Color(0xFF0E7490),
              onTap: () => context.push(RouteNames.energyComparisonPath),
            ),
            ProfileQuickTileData(
              title: 'Pusat Informasi',
              subtitle: 'Panduan 4 pilar & dataset',
              icon: Icons.help_outline_rounded,
              iconBackground: AppColors.mintGreen,
              iconColor: AppColors.actionGreen,
              badgeCount: unreadNotifications,
              onTap: () => context.push(RouteNames.notificationsPath),
            ),
          ],
        ),
        const SizedBox(height: 22),
        _buildSectionTitle('Akun & pengaturan'),
        const SizedBox(height: 12),
        ProfileSettingsMenuGroup(
          rows: [
            ProfileMenuRowData(
              title: 'Pengaturan aplikasi',
              subtitle: 'Efek visual Liquid Glass & onboarding',
              icon: Icons.tune_rounded,
              onTap: () => context.push(RouteNames.settingsPath),
            ),
            ProfileMenuRowData(
              title: 'Tentang EduEarth',
              subtitle: 'Sumber data, atribusi & v${AppConstants.appVersion}',
              icon: Icons.info_outline_rounded,
              onTap: () => context.push(RouteNames.aboutPath),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildVersionCaption(),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Text(
        title,
        style: AppTextStyles.subtitle.copyWith(
          color: ProfileLightPalette.ink,
          fontSize: 17,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.25,
        ),
      ),
    );
  }

  Widget _buildVersionCaption() {
    return Center(
      child: Text(
        '${AppConstants.appName} v${AppConstants.appVersion} (${AppConstants.appBuildNumber}) • Explore Energy, Understand Earth.',
        style: AppTextStyles.caption.copyWith(
          color: ProfileLightPalette.muted,
          fontSize: 11.5,
        ),
        textAlign: TextAlign.center,
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

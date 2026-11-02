import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/common/empty_view.dart';
import '../../../../core/widgets/common/error_view.dart';
import '../../../../core/widgets/common/loading_view.dart';
import '../../../../core/widgets/common/primary_button.dart';
import '../../../../core/widgets/common/soft_image_placeholder.dart';
import '../../../../models/user_profile.dart';
import '../../../../routes/route_names.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../bookmark/presentation/providers/bookmark_providers.dart';
import '../../../quiz/presentation/providers/quiz_providers.dart';
import '../providers/profile_providers.dart';

/// Halaman Profil Pengguna (Tab Profile) sesuai `docs/design/moodboard.png`.
///
/// Ketentuan:
/// - Menampilkan avatar bulat di tengah (dengan slot `eco_happy.png` / `avatar_url`),
///   nama tampilan, dan email (TANPA Level/XP).
/// - Menampilkan statistik dari data nyata yang sudah ada: "Tersimpan" (jumlah bookmark)
///   dan "Kuis" (jumlah percobaan kuis); kolom "Badge" disembunyikan bila belum ada.
/// - Daftar menu berikon lembut bergaya moodboard.
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(currentSessionProvider);
    final profileAsync = ref.watch(currentUserProfileProvider);
    final bookmarksAsync = ref.watch(userBookmarksProvider);
    final attemptsAsync = ref.watch(userQuizAttemptsProvider);
    final authController = ref.watch(authControllerProvider);

    return Scaffold(
      body: SafeArea(
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
            const int? badgeCount = null; // Disembunyikan sampai Fase 6 (Achievement)

            return RefreshIndicator(
              color: AppColors.freshGreen,
              onRefresh: () async {
                ref.invalidate(currentUserProfileProvider);
                ref.invalidate(userBookmarksProvider);
                ref.invalidate(userQuizAttemptsProvider);
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                children: [
                  // 1. Header Avatar + Nama (Tanpa Level/XP)
                  Center(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.sageGreen,
                              width: 2,
                            ),
                          ),
                          child: SoftImagePlaceholder(
                            width: 96,
                            height: 96,
                            borderRadius: 48,
                            networkImageUrl: avatarUrl,
                            assetPath: 'assets/images/mascot/eco_happy.png',
                            backgroundColor: AppColors.mintGreen,
                            fallbackIcon: Icons.person_rounded,
                            iconColor: AppColors.forestGreen,
                            iconSize: 46,
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Tooltip(
                            message: 'Edit Profil',
                            child: Material(
                              color: AppColors.forestGreen,
                              shape: const CircleBorder(),
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: () => _showEditProfileSheet(
                                  context,
                                  ref,
                                  profile,
                                ),
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.surfaceWhite,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.edit_rounded,
                                    size: 15,
                                    color: AppColors.surfaceWhite,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    profile?.displayName ??
                        session.user.email ??
                        'Pengguna EduEarth',
                    style: AppTextStyles.display.copyWith(fontSize: 22),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    session.user.email ?? '',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // 2. Kartu Statistik (Tersimpan & Kuis, + Badge bila tersedia)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWhite,
                      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: _StatItem(
                            value: '$bookmarkCount',
                            label: 'Tersimpan',
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 36,
                          color: AppColors.divider,
                        ),
                        Expanded(
                          child: _StatItem(
                            value: '$quizAttemptCount',
                            label: 'Kuis',
                          ),
                        ),
                        if (badgeCount != null) ...[
                          Container(
                            width: 1,
                            height: 36,
                            color: AppColors.divider,
                          ),
                          Expanded(
                            child: _StatItem(
                              value: '$badgeCount',
                              label: 'Badge',
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 3. Grup Menu Utama (My Learning, Bookmark, Pencarian)
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWhite,
                      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Column(
                      children: [
                        _MoodboardMenuTile(
                          icon: Icons.menu_book_rounded,
                          iconBackground: const Color(0xFFFEF9C3),
                          iconColor: const Color(0xFFD97706),
                          title: 'My Learning',
                          onTap: () => context.push(RouteNames.myLearningPath),
                        ),
                        const Divider(height: 1, indent: 64),
                        _MoodboardMenuTile(
                          icon: Icons.bookmark_rounded,
                          iconBackground: AppColors.mintGreen,
                          iconColor: AppColors.forestGreen,
                          title: 'Bookmark',
                          onTap: () => context.push(RouteNames.bookmarksPath),
                        ),
                        const Divider(height: 1, indent: 64),
                        _MoodboardMenuTile(
                          icon: Icons.search_rounded,
                          iconBackground: const Color(0xFFE0F2FE),
                          iconColor: AppColors.skyBlue,
                          title: 'Pencarian Global',
                          onTap: () => context.push(RouteNames.searchPath),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 4. Grup Menu Pengaturan & Tentang
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWhite,
                      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Column(
                      children: [
                        _MoodboardMenuTile(
                          icon: Icons.edit_outlined,
                          iconBackground: AppColors.mintGreen,
                          iconColor: AppColors.forestGreen,
                          title: 'Edit Nama & Avatar Profil',
                          onTap: () => _showEditProfileSheet(
                            context,
                            ref,
                            profile,
                          ),
                        ),
                        const Divider(height: 1, indent: 64),
                        _MoodboardMenuTile(
                          icon: Icons.settings_outlined,
                          iconBackground: AppColors.offWhite,
                          iconColor: AppColors.forestGreen,
                          title: 'Settings',
                          onTap: () => context.push(RouteNames.settingsPath),
                        ),
                        const Divider(height: 1, indent: 64),
                        _MoodboardMenuTile(
                          icon: Icons.info_outline_rounded,
                          iconBackground: AppColors.offWhite,
                          iconColor: AppColors.forestGreen,
                          title: 'About EduEarth',
                          onTap: () => context.push(RouteNames.aboutPath),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: 'Keluar (Logout)',
                    icon: Icons.logout_rounded,
                    isLoading: authController.isLoading,
                    onPressed: () async {
                      await ref
                          .read(authControllerProvider.notifier)
                          .signOut();
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: AppTextStyles.display.copyWith(fontSize: 22),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _MoodboardMenuTile extends StatelessWidget {
  const _MoodboardMenuTile({
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 38,
        height: 38,
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
          fontWeight: FontWeight.w600,
        ),
      ),
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

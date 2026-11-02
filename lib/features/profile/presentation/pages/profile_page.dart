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
import '../../../../core/widgets/common/secondary_button.dart';
import '../../../../models/user_profile.dart';
import '../../../../routes/route_names.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../bookmark/presentation/providers/bookmark_providers.dart';
import '../../../quiz/presentation/providers/quiz_providers.dart';
import '../providers/profile_providers.dart';

/// Halaman Profil Pengguna (Tab Profile) Fase 5.
///
/// Fitur:
/// - Menampilkan informasi akun, avatar opsional, dan ringkasan progres.
/// - Dialog / bottom sheet untuk mengedit `display_name` dan `avatar_url`.
/// - Navigasi cepat ke My Learning, Bookmark Saya, Pencarian, Pengaturan, dan Tentang EduEarth.
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
      appBar: AppBar(
        title: const Text('Profil Saya'),
        actions: [
          IconButton(
            tooltip: 'Pengaturan',
            onPressed: () => context.push(RouteNames.settingsPath),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
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

            return RefreshIndicator(
              color: AppColors.freshGreen,
              onRefresh: () async {
                ref.invalidate(currentUserProfileProvider);
                ref.invalidate(userBookmarksProvider);
                ref.invalidate(userQuizAttemptsProvider);
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
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
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: AppColors.mintGreen,
                          backgroundImage: avatarUrl.isNotEmpty
                              ? NetworkImage(avatarUrl)
                              : null,
                          onBackgroundImageError: avatarUrl.isNotEmpty
                              ? (_, _) {}
                              : null,
                          child: avatarUrl.isEmpty
                              ? const Icon(
                                  Icons.person_rounded,
                                  size: 40,
                                  color: AppColors.forestGreen,
                                )
                              : null,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          profile?.displayName ??
                              session.user.email ??
                              'Pengguna EduEarth',
                          style: AppTextStyles.title,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          session.user.email ?? '',
                          style: AppTextStyles.caption,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _StatBadge(
                              label: 'Percobaan Kuis',
                              value: '$quizAttemptCount',
                              icon: Icons.quiz_outlined,
                            ),
                            Container(
                              width: 1,
                              height: 32,
                              color: AppColors.divider,
                            ),
                            _StatBadge(
                              label: 'Bookmark',
                              value: '$bookmarkCount',
                              icon: Icons.bookmark_outline_rounded,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SecondaryButton(
                          label: 'Edit Nama & Avatar Profil',
                          icon: Icons.edit_outlined,
                          onPressed: () =>
                              _showEditProfileSheet(context, ref, profile),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Aktivitas & Menu', style: AppTextStyles.title),
                  const SizedBox(height: 12),
                  _MenuTile(
                    icon: Icons.school_outlined,
                    title: 'Progres Belajar Saya (My Learning)',
                    subtitle: 'Riwayat kuis, statistik skor, dan materi tersimpan',
                    onTap: () => context.push(RouteNames.myLearningPath),
                  ),
                  const SizedBox(height: 10),
                  _MenuTile(
                    icon: Icons.bookmark_outline_rounded,
                    title: 'Bookmark Saya',
                    subtitle: 'Daftar materi dan pembangkit yang disimpan',
                    onTap: () => context.push(RouteNames.bookmarksPath),
                  ),
                  const SizedBox(height: 10),
                  _MenuTile(
                    icon: Icons.search_rounded,
                    title: 'Pencarian Global',
                    subtitle: 'Cari pembangkit energi dan materi pembelajaran',
                    onTap: () => context.push(RouteNames.searchPath),
                  ),
                  const SizedBox(height: 10),
                  _MenuTile(
                    icon: Icons.settings_outlined,
                    title: 'Pengaturan Aplikasi',
                    subtitle: 'Kurangi efek glass (Liquid Glass) & preferensi',
                    onTap: () => context.push(RouteNames.settingsPath),
                  ),
                  const SizedBox(height: 10),
                  _MenuTile(
                    icon: Icons.info_outline_rounded,
                    title: 'Tentang EduEarth',
                    subtitle: 'Visi edukasi energi terbarukan & prinsip sumber data',
                    onTap: () => context.push(RouteNames.aboutPath),
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

class _StatBadge extends StatelessWidget {
  const _StatBadge({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppColors.forestGreen),
            const SizedBox(width: 6),
            Text(value, style: AppTextStyles.title),
          ],
        ),
        const SizedBox(height: 2),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        ),
        leading: Container(
          width: 42,
          height: 42,
          decoration: const BoxDecoration(
            color: AppColors.mintGreen,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.forestGreen, size: 22),
        ),
        title: Text(title, style: AppTextStyles.bodyMedium),
        subtitle: Text(subtitle, style: AppTextStyles.caption),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: AppColors.textMuted,
        ),
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


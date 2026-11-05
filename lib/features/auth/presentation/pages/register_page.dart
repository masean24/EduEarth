import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/common/empty_view.dart';
import '../../../../core/widgets/common/primary_button.dart';
import '../../../../core/widgets/common/soft_image_placeholder.dart';
import '../../../../routes/route_names.dart';
import '../../../../services/supabase_service.dart';
import '../providers/auth_provider.dart';

/// Halaman Daftar Akun (Register) dengan nama tampilan, email, dan kata sandi.
///
/// Trigger `handle_new_user()` di Supabase otomatis membuat baris di `user_profiles`.
/// Mengikuti gaya `docs/design/moodboard.png`: tanpa AppBar judul ganda,
/// menampilkan hero banner Nature-Tech dengan `logo_eduearth.png` & `eco_wave.png`,
/// tab switcher Masuk/Daftar, serta kartu form modern.
class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _errorMessage;
  String? _infoMessage;

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitRegister() async {
    setState(() {
      _errorMessage = null;
      _infoMessage = null;
    });
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final result = await ref.read(authControllerProvider.notifier).signUp(
          email: _emailController.text,
          password: _passwordController.text,
          displayName: _displayNameController.text,
        );

    if (!mounted) return;

    if (!result.success) {
      final authState = ref.read(authControllerProvider);
      if (authState.hasError) {
        setState(() => _errorMessage = authState.error.toString());
      }
      return;
    }

    if (result.requiresEmailConfirmation) {
      setState(() {
        _infoMessage =
            'Pendaftaran berhasil! Silakan periksa kotak masuk email Anda untuk konfirmasi sebelum masuk.';
      });
    } else {
      context.go(RouteNames.homePath);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSupabaseReady = ref.watch(isSupabaseInitializedProvider);
    final authAsync = ref.watch(authControllerProvider);

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE1F5E8),
              AppColors.offWhite,
              Color(0xFFEEF8F1),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: !isSupabaseReady
              ? EmptyView(
                  icon: Icons.cloud_off_rounded,
                  title: 'Server Belum Dikonfigurasi',
                  description:
                      'Jalankan aplikasi dengan --dart-define=SUPABASE_URL=... dan --dart-define=SUPABASE_ANON_KEY=... untuk mendaftarkan akun.',
                  actionLabel: 'Kembali ke Halaman Masuk',
                  onAction: () => context.go(RouteNames.loginPath),
                )
              : Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildHeroBanner(),
                          const SizedBox(height: 16),

                          // Kartu form registrasi putih bersih
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: AppTheme.cardDecoration(),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildAuthModeSwitcher(context),
                                  const SizedBox(height: 18),
                                  if (_errorMessage != null) ...[
                                    Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: AppColors.errorLight,
                                        borderRadius: BorderRadius.circular(
                                          AppTheme.buttonRadius,
                                        ),
                                        border: Border.all(
                                          color: AppColors.errorRed.withValues(
                                            alpha: 0.4,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.error_outline_rounded,
                                            color: AppColors.errorRed,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              _errorMessage!,
                                              style: AppTextStyles.caption
                                                  .copyWith(
                                                    color: AppColors.errorRed,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                  if (_infoMessage != null) ...[
                                    Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: AppColors.mintGreen,
                                        borderRadius: BorderRadius.circular(
                                          AppTheme.buttonRadius,
                                        ),
                                        border: Border.all(
                                          color: AppColors.freshGreen,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.check_circle_outline_rounded,
                                            color: AppColors.forestGreen,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              _infoMessage!,
                                              style: AppTextStyles.caption
                                                  .copyWith(
                                                    color:
                                                        AppColors.forestGreen,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                  Text(
                                    'Nama Tampilan',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.forestGreen,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _displayNameController,
                                    textInputAction: TextInputAction.next,
                                    validator:
                                        AppValidators.validateDisplayName,
                                    decoration: const InputDecoration(
                                      hintText: 'Contoh: Budi Santoso',
                                      prefixIcon: Icon(
                                        Icons.person_outline_rounded,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    'Alamat Email',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.forestGreen,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    autocorrect: false,
                                    validator: AppValidators.validateEmail,
                                    decoration: const InputDecoration(
                                      hintText: 'nama@email.com',
                                      prefixIcon: Icon(Icons.email_outlined),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    'Kata Sandi',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.forestGreen,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    textInputAction: TextInputAction.done,
                                    validator: AppValidators.validatePassword,
                                    onFieldSubmitted: (_) => _submitRegister(),
                                    decoration: InputDecoration(
                                      hintText: 'Minimal 6 karakter',
                                      prefixIcon: const Icon(
                                        Icons.lock_outline_rounded,
                                      ),
                                      suffixIcon: IconButton(
                                        tooltip: _obscurePassword
                                            ? 'Tampilkan kata sandi'
                                            : 'Sembunyikan kata sandi',
                                        onPressed: () {
                                          setState(
                                            () => _obscurePassword =
                                                !_obscurePassword,
                                          );
                                        },
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  PrimaryButton(
                                    label: 'Buat Akun Sekarang',
                                    icon: Icons.person_add_alt_1_rounded,
                                    isLoading: authAsync.isLoading,
                                    onPressed: _submitRegister,
                                  ),
                                  const SizedBox(height: 18),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Sudah punya akun? ',
                                        style: AppTextStyles.body.copyWith(
                                          color: AppColors.textSecondary,
                                          fontSize: 14,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: authAsync.isLoading
                                            ? null
                                            : () => context.go(
                                                  RouteNames.loginPath,
                                                ),
                                        child: Text(
                                          'Masuk di sini',
                                          style: AppTextStyles.body.copyWith(
                                            color: AppColors.forestGreen,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.forestGreen,
            Color(0xFF1F7A46),
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
          Positioned(
            right: -12,
            top: 0,
            bottom: 0,
            width: 165,
            child: Opacity(
              opacity: 0.25,
              child: SoftImagePlaceholder(
                borderRadius: 0,
                assetPath:
                    'assets/images/illustrations/banner_explore_energy.png',
                backgroundColor: Colors.transparent,
                fallbackIcon: Icons.solar_power_rounded,
                iconColor: AppColors.surfaceWhite,
                iconSize: 48,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceWhite.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const SoftImagePlaceholder(
                        width: 28,
                        height: 28,
                        borderRadius: 8,
                        assetPath: 'assets/images/branding/logo_eduearth.png',
                        backgroundColor: Colors.transparent,
                        fallbackIcon: Icons.eco_rounded,
                        iconColor: AppColors.forestGreen,
                        iconSize: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppConstants.appName,
                          style: AppTextStyles.subtitle.copyWith(
                            color: AppColors.surfaceWhite,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                          ),
                        ),
                        Text(
                          AppConstants.appTagline,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.mintGreen,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                              'Gabung Bersama Eco 🌱',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.surfaceWhite,
                                fontWeight: FontWeight.w700,
                                fontSize: 11.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Mulai Langkah Hijau!',
                            style: AppTextStyles.title.copyWith(
                              color: AppColors.surfaceWhite,
                              fontSize: 20,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Simpan progres belajar, kuis, dan pembangkit favoritmu di awan.',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.mintGreen.withValues(
                                alpha: 0.92,
                              ),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const SoftImagePlaceholder(
                      width: 90,
                      height: 90,
                      borderRadius: 24,
                      assetPath: 'assets/images/mascot/eco_wave.png',
                      backgroundColor: Colors.transparent,
                      fallbackIcon: Icons.waving_hand_rounded,
                      iconColor: AppColors.surfaceWhite,
                      iconSize: 38,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthModeSwitcher(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.offWhite,
        borderRadius: BorderRadius.circular(AppTheme.pillRadius),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(AppTheme.pillRadius),
              onTap: () => context.go(RouteNames.loginPath),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  'Masuk Akun',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.mintGreen,
                borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                border: Border.all(
                  color: AppColors.sageGreen.withValues(alpha: 0.6),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                'Daftar Baru',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.forestGreen,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

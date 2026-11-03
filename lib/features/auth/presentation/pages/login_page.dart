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
import '../../../../core/widgets/common/secondary_button.dart';
import '../../../../core/widgets/common/soft_image_placeholder.dart';
import '../../../../routes/route_names.dart';
import '../../../../services/supabase_service.dart';
import '../providers/auth_provider.dart';

/// Halaman Masuk (Login) dengan email + kata sandi melalui Supabase Auth.
///
/// Mengikuti gaya `docs/design/moodboard.png`: tanpa AppBar judul ganda,
/// menampilkan hero banner Nature-Tech dengan `logo_eduearth.png` & `eco_wave.png`,
/// tab switcher Masuk/Daftar, serta kartu form modern.
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitLogin() async {
    setState(() => _errorMessage = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final success = await ref.read(authControllerProvider.notifier).signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );

    if (!mounted) return;
    if (success) {
      context.go(RouteNames.homePath);
    } else {
      final authState = ref.read(authControllerProvider);
      if (authState.hasError) {
        setState(() => _errorMessage = authState.error.toString());
      }
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
                      'Jalankan aplikasi dengan --dart-define=SUPABASE_URL=... dan --dart-define=SUPABASE_ANON_KEY=... untuk menggunakan fitur autentikasi, atau lanjut ke beranda dalam mode pratinjau.',
                  actionLabel: 'Lanjut ke Beranda',
                  onAction: () => context.go(RouteNames.homePath),
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

                          // Kartu utama form dengan tab switcher Masuk / Daftar
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: AppTheme.cardDecoration(),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildAuthModeSwitcher(context),
                                  const SizedBox(height: 20),
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
                                  Text(
                                    'Alamat Email',
                                    style: AppTextStyles.bodyMedium,
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
                                  const SizedBox(height: 16),
                                  Text(
                                    'Kata Sandi',
                                    style: AppTextStyles.bodyMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    textInputAction: TextInputAction.done,
                                    validator: AppValidators.validatePassword,
                                    onFieldSubmitted: (_) => _submitLogin(),
                                    decoration: InputDecoration(
                                      hintText: 'Masukkan kata sandi Anda',
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
                                  const SizedBox(height: 22),
                                  PrimaryButton(
                                    label: 'Masuk ke EduEarth',
                                    icon: Icons.login_rounded,
                                    isLoading: authAsync.isLoading,
                                    onPressed: _submitLogin,
                                  ),
                                  const SizedBox(height: 12),
                                  SecondaryButton(
                                    label: 'Belum Punya Akun? Daftar Sekarang',
                                    icon: Icons.person_add_alt_1_rounded,
                                    onPressed: authAsync.isLoading
                                        ? null
                                        : () => context.go(
                                              RouteNames.registerPath,
                                            ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildFeatureHighlightsRow(),
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
          // Aksen ilustrasi lembut di kanan belakang
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
            padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Baris identitas brand EduEarth
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
                const SizedBox(height: 14),
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
                              'Halo! Aku Eco 🌿',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.surfaceWhite,
                                fontWeight: FontWeight.w700,
                                fontSize: 11.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Selamat Datang Kembali!',
                            style: AppTextStyles.title.copyWith(
                              color: AppColors.surfaceWhite,
                              fontSize: 21,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Masuk untuk melanjutkan petualangan energi terbarukanmu di Indonesia.',
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
                      width: 96,
                      height: 96,
                      borderRadius: 24,
                      assetPath: 'assets/images/mascot/eco_wave.png',
                      backgroundColor: Colors.transparent,
                      fallbackIcon: Icons.waving_hand_rounded,
                      iconColor: AppColors.surfaceWhite,
                      iconSize: 40,
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
                'Masuk Akun',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.forestGreen,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(AppTheme.pillRadius),
              onTap: () => context.go(RouteNames.registerPath),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  'Daftar Baru',
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
        ],
      ),
    );
  }

  Widget _buildFeatureHighlightsRow() {
    const items = [
      (Icons.map_outlined, 'Peta EBT'),
      (Icons.menu_book_outlined, '5 Kategori'),
      (Icons.verified_user_outlined, 'Kuis Aman'),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: items.map((item) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.$1, size: 15, color: AppColors.forestGreen),
            const SizedBox(width: 5),
            Text(
              item.$2,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 11.5,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

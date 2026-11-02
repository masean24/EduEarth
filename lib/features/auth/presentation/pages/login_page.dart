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
import '../../../../routes/route_names.dart';
import '../../../../services/supabase_service.dart';
import '../providers/auth_provider.dart';

/// Halaman Masuk (Login) dengan email + kata sandi melalui Supabase Auth.
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
      appBar: AppBar(
        title: const Text('Masuk ke EduEarth'),
      ),
      body: SafeArea(
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
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Container(
                              width: 72,
                              height: 72,
                              decoration: const BoxDecoration(
                                color: AppColors.mintGreen,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.eco_rounded,
                                size: 36,
                                color: AppColors.forestGreen,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Selamat Datang Kembali',
                            style: AppTextStyles.display.copyWith(fontSize: 24),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            AppConstants.appTagline,
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
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
                                      style: AppTextStyles.caption.copyWith(
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
                          Text('Email', style: AppTextStyles.bodyMedium),
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
                          Text('Kata Sandi', style: AppTextStyles.bodyMedium),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            validator: AppValidators.validatePassword,
                            onFieldSubmitted: (_) => _submitLogin(),
                            decoration: InputDecoration(
                              hintText: 'Masukkan kata sandi Anda',
                              prefixIcon: const Icon(Icons.lock_outline_rounded),
                              suffixIcon: IconButton(
                                tooltip: _obscurePassword
                                    ? 'Tampilkan kata sandi'
                                    : 'Sembunyikan kata sandi',
                                onPressed: () {
                                  setState(
                                    () => _obscurePassword = !_obscurePassword,
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
                          const SizedBox(height: 24),
                          PrimaryButton(
                            label: 'Masuk',
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
                                : () => context.go(RouteNames.registerPath),
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
}


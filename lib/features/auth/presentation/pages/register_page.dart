import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

/// Halaman Daftar Akun (Register) dengan nama tampilan, email, dan kata sandi.
///
/// Trigger `handle_new_user()` di Supabase otomatis membuat baris di `user_profiles`.
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
      appBar: AppBar(
        title: const Text('Daftar Akun EduEarth'),
      ),
      body: SafeArea(
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
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Buat Akun Baru',
                            style: AppTextStyles.display.copyWith(fontSize: 24),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Simpan progres belajar, kuis, dan pembangkit favoritmu.',
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
                          if (_infoMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.mintGreen,
                                borderRadius: BorderRadius.circular(
                                  AppTheme.buttonRadius,
                                ),
                                border: Border.all(color: AppColors.freshGreen),
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
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.forestGreen,
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
                            style: AppTextStyles.bodyMedium,
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _displayNameController,
                            textInputAction: TextInputAction.next,
                            validator: AppValidators.validateDisplayName,
                            decoration: const InputDecoration(
                              hintText: 'Contoh: Budi Santoso',
                              prefixIcon: Icon(Icons.person_outline_rounded),
                            ),
                          ),
                          const SizedBox(height: 16),
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
                            onFieldSubmitted: (_) => _submitRegister(),
                            decoration: InputDecoration(
                              hintText: 'Minimal 6 karakter',
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
                            label: 'Daftar Akun',
                            icon: Icons.person_add_alt_1_rounded,
                            isLoading: authAsync.isLoading,
                            onPressed: _submitRegister,
                          ),
                          const SizedBox(height: 12),
                          SecondaryButton(
                            label: 'Sudah Punya Akun? Masuk',
                            icon: Icons.login_rounded,
                            onPressed: authAsync.isLoading
                                ? null
                                : () => context.go(RouteNames.loginPath),
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


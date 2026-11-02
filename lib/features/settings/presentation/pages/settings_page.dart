import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common/secondary_button.dart';
import '../../../../core/widgets/glass/glass_container.dart';
import '../../../../routes/route_names.dart';
import '../../../onboarding/presentation/providers/onboarding_provider.dart';

/// Halaman Pengaturan Aplikasi (Settings) Fase 5.
///
/// Menyediakan opsi "Kurangi efek glass" (tersimpan di `SharedPreferences`),
/// tombol ulangi onboarding, dan tautan ke Tentang EduEarth.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reduceGlass = ref.watch(reduceGlassEffectProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan Aplikasi'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [
            Text('Tampilan & Performa', style: AppTextStyles.title),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                border: Border.all(color: AppColors.divider),
              ),
              child: SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Kurangi efek glass (Liquid Glass)',
                  style: AppTextStyles.subtitle,
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Mengganti efek blur transparan (BackdropFilter) dengan latar semi-solid agar lebih ringan di perangkat berspesifikasi menengah/rendah.',
                    style: AppTextStyles.caption,
                  ),
                ),
                value: reduceGlass,
                activeTrackColor: AppColors.freshGreen,
                onChanged: (value) {
                  ref
                      .read(reduceGlassEffectProvider.notifier)
                      .setReduceEffect(value);
                },
              ),
            ),
            const SizedBox(height: 24),
            Text('Panduan & Informasi', style: AppTextStyles.title),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                ),
                leading: const Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.forestGreen,
                ),
                title: Text('Tentang EduEarth', style: AppTextStyles.bodyMedium),
                subtitle: Text(
                  'Tujuan aplikasi, 5 kategori energi, dan atribusi peta',
                  style: AppTextStyles.caption,
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push(RouteNames.aboutPath),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                ),
                leading: const Icon(
                  Icons.palette_outlined,
                  color: AppColors.forestGreen,
                ),
                title: Text(
                  'Showcase Komponen & Design System',
                  style: AppTextStyles.bodyMedium,
                ),
                subtitle: Text(
                  'Pratinjau komponen UI, tiga state UI, dan GlassContainer',
                  style: AppTextStyles.caption,
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push(RouteNames.designShowcasePath),
              ),
            ),
            const SizedBox(height: 24),
            SecondaryButton(
              label: 'Tampilkan Ulang Onboarding',
              icon: Icons.replay_rounded,
              onPressed: () async {
                await ref
                    .read(onboardingStatusProvider.notifier)
                    .resetOnboarding();
                if (context.mounted) {
                  context.go(RouteNames.onboardingPath);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

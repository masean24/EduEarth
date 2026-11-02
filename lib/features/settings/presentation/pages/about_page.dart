import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common/secondary_button.dart';
import '../../../../services/external_map_service.dart';

/// Halaman Tentang EduEarth (About EduEarth) Fase 5.
class AboutPage extends ConsumerWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final externalMapService = ref.watch(externalMapServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tentang EduEarth'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.mintGreen,
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                border: Border.all(color: AppColors.sageGreen),
              ),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceWhite,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.eco_rounded,
                      size: 38,
                      color: AppColors.forestGreen,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(AppConstants.appName, style: AppTextStyles.display),
                  const SizedBox(height: 4),
                  Text(
                    AppConstants.appTagline,
                    style: AppTextStyles.subtitle.copyWith(
                      color: AppColors.forestGreen,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Versi 1.0.0 • Aplikasi Edukasi Energi Terbarukan Indonesia',
                    style: AppTextStyles.caption,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('Tujuan Aplikasi', style: AppTextStyles.title),
            const SizedBox(height: 8),
            Text(
              'EduEarth dirancang untuk membantu pelajar dan masyarakat Indonesia memahami potensi serta cara kerja energi terbarukan melalui peta pembangkit interaktif, materi pembelajaran ringkas, dan kuis edukatif.',
              style: AppTextStyles.body,
            ),
            const SizedBox(height: 20),
            Text('Prinsip Akurasi & Integritas Data', style: AppTextStyles.title),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• Akurasi di atas kuantitas: setiap data pembangkit nyata wajib disertai tautan sumber referensi (source_url) dan tanggal verifikasi (verified_at).',
                    style: AppTextStyles.body,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Data contoh untuk pengembangan ditandai secara eksplisit dengan label [DEMO] dan status is_demo = true agar tidak tertukar dengan data pembangkit nyata.',
                    style: AppTextStyles.body,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('Atribusi Peta & Sumber Terbuka', style: AppTextStyles.title),
            const SizedBox(height: 8),
            Text(
              'Peta interaktif di dalam aplikasi menggunakan layanan tile OpenStreetMap (${AppConstants.osmAttribution}).',
              style: AppTextStyles.body,
            ),
            const SizedBox(height: 12),
            SecondaryButton(
              label: 'Buka Hak Cipta OpenStreetMap',
              icon: Icons.open_in_new_rounded,
              onPressed: () {
                externalMapService.openExternalUrl(
                  'https://www.openstreetmap.org/copyright',
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}


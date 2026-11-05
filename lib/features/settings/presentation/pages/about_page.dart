import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common/screen_header.dart';
import '../../../../core/widgets/common/secondary_button.dart';
import '../../../../core/widgets/common/soft_image_placeholder.dart';
import '../../../../services/external_map_service.dart';

/// Halaman Tentang EduEarth (About EduEarth) beserta dokumentasi lengkap
/// "Sumber Data dan Cakupan" sesuai `data/DATA_LOG.md`.
class AboutPage extends ConsumerWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final externalMapService = ref.watch(externalMapServiceProvider);

    return Scaffold(
      appBar: const ScreenHeaderBar(
        title: 'Tentang EduEarth',
        subtitle: 'Misi edukasi energi bersih, sumber data, & cakupan',
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
                  const SoftImagePlaceholder(
                    width: 84,
                    height: 84,
                    borderRadius: 42,
                    assetPath: 'assets/images/branding/logo_eduearth.png',
                    backgroundColor: AppColors.surfaceWhite,
                    fallbackIcon: Icons.eco_rounded,
                    iconColor: AppColors.forestGreen,
                    iconSize: 38,
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
            const SizedBox(height: 22),

            // Bagian wajib: Sumber Data dan Cakupan (dari data/DATA_LOG.md)
            Text('Sumber Data dan Cakupan', style: AppTextStyles.title),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '1. Sumber & Atribusi Dataset Pembangkit',
                    style: AppTextStyles.subtitle.copyWith(fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  _buildBulletItem(
                    'Global Energy Monitor (GEM): Halaman proyek per pembangkit pada tracker panas bumi (Geothermal), angin (Wind), air (Hydropower), dan surya (Solar) di gem.wiki (lisensi CC BY 4.0; diakses 2026-11-03; nama rilis/bulan spesifik tracker belum diverifikasi langsung).',
                  ),
                  const SizedBox(height: 6),
                  _buildBulletItem(
                    'Direktorat Jenderal EBTKE — Kementerian ESDM: Buku Saku Bioenergi 2023 (publikasi pemerintah; diakses 2026-11-03, hal. 72–75) untuk daftar pembangkit bioenergi (PLTBm/PLTBg).',
                  ),
                  const SizedBox(height: 6),
                  _buildBulletItem(
                    'Kementerian ESDM, PLN, & Publikasi Media Terkait: Siaran pers ESDM/PLN serta artikel referensi yang tercantum spesifik pada kolom source_url tiap baris pembangkit.',
                  ),
                  const SizedBox(height: 6),
                  _buildBulletItem(
                    'OpenStreetMap & Nominatim: Peta dasar dan layanan geocoding sentroid wilayah untuk penurunan koordinat perkiraan bioenergi (© OpenStreetMap contributors, lisensi ODbL 1.0).',
                  ),
                  const SizedBox(height: 6),
                  _buildBulletItem(
                    'Poligon Batas Provinsi: Repositori ans-4175/peta-indonesia-geojson (MIT License, Ahmad Anshorimuslim Syuhada) untuk pemeriksaan spasial provinsi.',
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1),
                  ),
                  Text(
                    '2. Tanggal Data & Cakupan',
                    style: AppTextStyles.subtitle.copyWith(fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  _buildBulletItem(
                    'Tanggal referensi data (data_as_of): tercatat per baris pembangkit (rentang 2017-12-18 s.d. 2026-03 sesuai rujukan masing-masing proyek; audit staging diperbarui pada 2026-11-04).',
                  ),
                  const SizedBox(height: 6),
                  _buildBulletItem(
                    'Cakupan teknis: pembangkit energi terbarukan on-grid berkapasitas >= 1 MW di Indonesia (128 unit pada staging: 85 beroperasi, 9 konstruksi, 34 rencana).',
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1),
                  ),
                  Text(
                    '3. Keterbatasan Jujur Dataset',
                    style: AppTextStyles.subtitle.copyWith(fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  _buildBulletItem(
                    'Cakupan terhadap total nasional belum diverifikasi: angka kapasitas terpasang nasional resmi Kementerian ESDM belum diverifikasi langsung dari publikasi primer, sehingga aplikasi ini tidak mengklaim persentase cakupan terhadap total nasional.',
                  ),
                  const SizedBox(height: 6),
                  _buildBulletItem(
                    'Di luar cakupan: PLTS Atap, pembangkit skala kecil (< 1 MW / mikrohidro / off-grid komunitas), serta pembangkit captive (industri mandiri di luar jaringan listrik publik) tidak tercakup dalam dataset ini.',
                  ),
                  const SizedBox(height: 6),
                  _buildBulletItem(
                    'Koordinat bioenergi merupakan perkiraan (approximate): karena Buku Saku Bioenergi 2023 tidak memuat koordinat geografis, titik lokasi 22 pembangkit bioenergi diturunkan dari sentroid wilayah tingkat desa/kecamatan/kabupaten melalui OpenStreetMap Nominatim dan diberi label "Lokasi perkiraan".',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            Text('Atribusi Peta & Sumber Terbuka', style: AppTextStyles.title),
            const SizedBox(height: 8),
            Text(
              'Peta interaktif di dalam aplikasi menggunakan layanan tile OpenStreetMap (${AppConstants.osmAttribution}) di bawah lisensi Open Database License (ODbL 1.0).',
              style: AppTextStyles.body,
            ),
            const SizedBox(height: 12),
            SecondaryButton(
              label: 'Buka Hak Cipta OpenStreetMap (ODbL)',
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

  Widget _buildBulletItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '• ',
          style: AppTextStyles.body.copyWith(
            color: AppColors.forestGreen,
            fontWeight: FontWeight.w700,
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
              fontSize: 13.5,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}

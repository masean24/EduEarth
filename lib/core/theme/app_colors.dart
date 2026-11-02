import 'package:flutter/material.dart';

/// Palet warna resmi EduEarth (Nature Tech + iOS Liquid Glass).
///
/// Seluruh komponen wajib mengambil warna dari kelas ini atau `ThemeData`,
/// jangan menggunakan nilai hex langsung di widget.
class AppColors {
  const AppColors._();

  // Palet utama sesuai docs/03_DESIGN_SYSTEM.md & docs/design/moodboard.png
  static const Color forestGreen = Color(0xFF14532D);
  static const Color freshGreen = Color(0xFF22C55E);
  static const Color sageGreen = Color(0xFFA7C4AD);
  static const Color mintGreen = Color(0xFFDCFCE7);
  static const Color offWhite = Color(0xFFF8FAF7);
  static const Color skyBlue = Color(0xFF38A6C8);
  static const Color warmYellow = Color(0xFFFACC15);
  static const Color slateGray = Color(0xFF64748B);

  // Warna permukaan & utilitas pendukung keterbacaan
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color textPrimary = forestGreen;
  static const Color textSecondary = slateGray;
  static const Color textMuted = Color(0xFF6B8A76);
  static const Color divider = Color(0xFFD8E6DB);
  static const Color errorRed = Color(0xFFDC2626);
  static const Color errorLight = Color(0xFFFEE2E2);

  // Warna khusus kategori energi berdasarkan slug
  static const Color categorySolar = warmYellow;
  static const Color categoryHydro = skyBlue;
  static const Color categoryWind = Color(0xFF0EA5E9);
  static const Color categoryGeothermal = Color(0xFFF97316);
  static const Color categoryBioenergy = freshGreen;

  /// Mengembalikan warna aksen untuk `slug` kategori energi.
  static Color colorForCategorySlug(String slug) {
    switch (slug.toLowerCase().trim()) {
      case 'solar':
        return categorySolar;
      case 'hydro':
        return categoryHydro;
      case 'wind':
        return categoryWind;
      case 'geothermal':
        return categoryGeothermal;
      case 'bioenergy':
        return categoryBioenergy;
      default:
        return freshGreen;
    }
  }

  /// Mengembalikan warna latar pastel lembut untuk placeholder ikon/ilustrasi kategori.
  static Color softBackgroundForCategorySlug(String? slug) {
    switch (slug?.toLowerCase().trim()) {
      case 'solar':
        return const Color(0xFFFEF9C3);
      case 'hydro':
        return const Color(0xFFE0F2FE);
      case 'wind':
        return const Color(0xFFE0F7FA);
      case 'geothermal':
        return const Color(0xFFFFEDD5);
      case 'bioenergy':
        return mintGreen;
      default:
        return mintGreen;
    }
  }
}

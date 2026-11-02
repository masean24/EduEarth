/// Konstanta aplikasi global untuk EduEarth.
class AppConstants {
  const AppConstants._();

  static const String appName = 'EduEarth';
  static const String appTagline = 'Explore Energy, Understand Earth.';
  static const String appPackageName = 'com.eduearth.app';

  // OpenStreetMap tile & atribusi sesuai kebijakan penggunaan OSM
  static const String osmTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String osmAttribution = '© OpenStreetMap contributors';

  // Kunci penyimpanan lokal (SharedPreferences)
  static const String prefOnboardingCompleted = 'onboarding_completed';
  static const String prefReduceMotionAndGlass = 'reduce_glass_effect';
}


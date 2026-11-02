import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

final externalMapServiceProvider = Provider<ExternalMapService>((ref) {
  return const ExternalMapService();
});

/// Layanan untuk membuka koordinat pembangkit di Google Maps resmi atau tautan sumber
/// eksternal menggunakan `url_launcher` tanpa memerlukan Google Maps API key.
class ExternalMapService {
  const ExternalMapService();

  /// Membuka koordinat `(latitude, longitude)` di Google Maps.
  /// Mengembalikan `true` jika berhasil dibuka, atau `false` jika gagal.
  Future<bool> openInGoogleMaps({
    required double latitude,
    required double longitude,
    String? label,
  }) async {
    final query = label != null && label.trim().isNotEmpty
        ? '$latitude,$longitude (${Uri.encodeComponent(label.trim())})'
        : '$latitude,$longitude';

    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$query',
    );

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (launched) return true;

      return await launchUrl(
        uri,
        mode: LaunchMode.platformDefault,
      );
    } catch (_) {
      return false;
    }
  }

  /// Membuka URL sumber referensi (`source_url`) di browser eksternal.
  Future<bool> openExternalUrl(String urlString) async {
    final uri = Uri.tryParse(urlString.trim());
    if (uri == null) return false;
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}


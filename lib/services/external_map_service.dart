import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

final externalMapServiceProvider = Provider<ExternalMapService>((ref) {
  return const ExternalMapService();
});

/// Layanan untuk membuka titik koordinat maupun pencarian nama pembangkit di
/// Google Maps resmi atau tautan sumber eksternal menggunakan `url_launcher`
/// tanpa memerlukan Google Maps API key.
class ExternalMapService {
  const ExternalMapService();

  /// Membuka titik koordinat (`query=lat,lng`) di Google Maps.
  Future<bool> openCoordinatesInGoogleMaps({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
    );
    return _launchUri(uri);
  }

  /// Mencari pembangkit di Google Maps dengan `query = nama pembangkit + kota + provinsi`.
  Future<bool> searchPlaceInGoogleMaps({
    required String name,
    String? city,
    required String province,
  }) async {
    final parts = <String>[
      name.trim(),
      if (city != null && city.trim().isNotEmpty) city.trim(),
      province.trim(),
    ].where((s) => s.isNotEmpty).toList();

    final query = Uri.encodeQueryComponent(parts.join(' '));
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$query',
    );
    return _launchUri(uri);
  }

  /// Kompatibilitas pemanggil umum untuk membuka titik koordinat di Google Maps.
  Future<bool> openInGoogleMaps({
    required double latitude,
    required double longitude,
    String? label,
  }) async {
    return openCoordinatesInGoogleMaps(
      latitude: latitude,
      longitude: longitude,
    );
  }

  /// Membuka URL sumber referensi (`source_url`) di browser eksternal.
  Future<bool> openExternalUrl(String urlString) async {
    final uri = Uri.tryParse(urlString.trim());
    if (uri == null) return false;
    return _launchUri(uri);
  }

  Future<bool> _launchUri(Uri uri) async {
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
}

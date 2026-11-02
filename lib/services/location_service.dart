import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

/// Status hasil pemeriksaan izin & layanan lokasi perangkat.
enum LocationAccessState {
  granted,
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
}

/// Hasil pembacaan lokasi pengguna.
class LocationResult {
  const LocationResult({
    required this.accessState,
    this.position,
    this.message,
  });

  final LocationAccessState accessState;
  final Position? position;
  final String? message;

  bool get hasPosition =>
      accessState == LocationAccessState.granted && position != null;
}

final locationServiceProvider = Provider<LocationService>((ref) {
  return const LocationService();
});

/// Layanan pembungkus `geolocator` untuk meminta izin dan mengambil koordinat pengguna.
class LocationService {
  const LocationService();

  Future<LocationResult> getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return const LocationResult(
        accessState: LocationAccessState.serviceDisabled,
        message:
            'Layanan lokasi (GPS) di perangkat Anda sedang tidak aktif. Silakan aktifkan GPS untuk mencari pembangkit terdekat.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return const LocationResult(
          accessState: LocationAccessState.permissionDenied,
          message:
              'Izin akses lokasi ditolak. Berikan izin lokasi agar EduEarth dapat menghitung jarak pembangkit terdekat.',
        );
      }
    }

    if (permission == LocationLocationPermissionHelper.deniedForever) {
      return const LocationResult(
        accessState: LocationAccessState.permissionDeniedForever,
        message:
            'Izin lokasi ditolak secara permanen. Silakan aktifkan izin lokasi melalui Pengaturan Aplikasi di perangkat Anda.',
      );
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 12),
      ),
    );

    return LocationResult(
      accessState: LocationAccessState.granted,
      position: position,
    );
  }

  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();

  Future<bool> openAppSettings() => Geolocator.openAppSettings();
}

class LocationLocationPermissionHelper {
  const LocationLocationPermissionHelper._();
  static const LocationPermission deniedForever =
      LocationPermission.deniedForever;
}


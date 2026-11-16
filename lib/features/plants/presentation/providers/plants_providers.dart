import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/config/app_config.dart';
import '../../../../models/energy_category.dart';
import '../../../../models/power_plant.dart';
import '../../data/plants_repository.dart';

final plantsRepositoryProvider = Provider<PlantsRepository>((ref) {
  return const PlantsRepository();
});

/// Daftar seluruh kategori energi terbarukan dari Supabase (atau fallback demo).
final energyCategoriesProvider =
    FutureProvider<List<EnergyCategory>>((ref) async {
  final repo = ref.watch(plantsRepositoryProvider);
  return repo.getEnergyCategories();
});

/// Filter kategori energi yang sedang dipilih di Explore Map (`null` = Semua).
class SelectedCategoryFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void selectCategory(String? slug) {
    state = slug;
  }
}

final selectedCategoryFilterProvider =
    NotifierProvider<SelectedCategoryFilterNotifier, String?>(
  SelectedCategoryFilterNotifier.new,
);

/// Filter status operasional pembangkit di Explore Map.
/// Default wajib HANYA `'operating'` (Beroperasi).
class SelectedStatusesFilterNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => const <String>{'operating'};

  void toggleStatus(String status) {
    final normalized = status.trim().toLowerCase();
    final next = Set<String>.from(state);
    if (next.contains(normalized)) {
      if (next.length > 1) {
        next.remove(normalized);
      }
    } else {
      next.add(normalized);
    }
    state = next;
  }

  void resetToDefault() {
    state = const <String>{'operating'};
  }
}

final selectedStatusesFilterProvider =
    NotifierProvider<SelectedStatusesFilterNotifier, Set<String>>(
  SelectedStatusesFilterNotifier.new,
);

/// Daftar seluruh pembangkit terpublikasi (tanpa filter).
final allPlantsListProvider = FutureProvider<List<PowerPlant>>((ref) async {
  final repo = ref.watch(plantsRepositoryProvider);
  return repo.getPublishedPlants();
});

/// Daftar pembangkit terpublikasi sesuai filter kategori dan status yang dipilih di peta.
final filteredPlantsListProvider =
    FutureProvider<List<PowerPlant>>((ref) async {
  final selectedSlug = ref.watch(selectedCategoryFilterProvider);
  final selectedStatuses = ref.watch(selectedStatusesFilterProvider);
  final allPlants = await ref.watch(allPlantsListProvider.future);

  return allPlants.where((plant) {
    final matchesCategory = selectedSlug == null ||
        selectedSlug.isEmpty ||
        plant.categorySlug == selectedSlug;
    if (!matchesCategory) return false;

    final status = plant.operationalStatus.trim().toLowerCase();
    if (!AppConfig.isSupabaseConfigured && status == 'unknown') {
      return true;
    }
    return selectedStatuses.contains(status);
  }).toList();
});

/// Detail satu pembangkit berdasarkan `id`.
final plantDetailProvider =
    FutureProvider.family<PowerPlant, String>((ref, id) async {
  final repo = ref.watch(plantsRepositoryProvider);
  return repo.getPlantById(id);
});

/// Opsi pilihan radius pencarian pembangkit terdekat pada peta eksplorasi.
class NearbyRadiusOption {
  const NearbyRadiusOption({
    required this.label,
    required this.meters,
  });

  final String label;
  final int meters;
}

/// Pilihan radius jarak default untuk Mode Pembangkit Terdekat di peta.
const List<NearbyRadiusOption> kNearbyRadiusOptions = [
  NearbyRadiusOption(label: '50 km', meters: 50000),
  NearbyRadiusOption(label: '250 km', meters: 250000),
  NearbyRadiusOption(label: '500 km', meters: 500000),
  NearbyRadiusOption(label: '1.500 km', meters: 1500000),
];

/// Memformat angka meter menjadi label radius ringkas berbahasa Indonesia.
String formatRadiusLabel(int meters) {
  for (final option in kNearbyRadiusOptions) {
    if (option.meters == meters) return option.label;
  }
  if (meters >= 1000000) {
    final km = meters ~/ 1000;
    final thousands = km ~/ 1000;
    final rem = (km % 1000).toString().padLeft(3, '0');
    return '$thousands.$rem km';
  }
  if (meters >= 1000) {
    return '${meters ~/ 1000} km';
  }
  return '$meters m';
}

/// State untuk Mode Pembangkit Terdekat langsung di dalam `ExploreMapPage`.
class MapNearbyState {
  const MapNearbyState({
    this.isEnabled = false,
    this.radiusMeters = 500000,
    this.userLat,
    this.userLng,
    this.pendingAutoActivate = false,
  });

  final bool isEnabled;
  final int radiusMeters;
  final double? userLat;
  final double? userLng;
  final bool pendingAutoActivate;

  bool get hasLocation => userLat != null && userLng != null;

  LatLng? get userCenter => hasLocation ? LatLng(userLat!, userLng!) : null;

  MapNearbyState copyWith({
    bool? isEnabled,
    int? radiusMeters,
    double? userLat,
    double? userLng,
    bool clearUserLocation = false,
    bool? pendingAutoActivate,
  }) {
    return MapNearbyState(
      isEnabled: isEnabled ?? this.isEnabled,
      radiusMeters: radiusMeters ?? this.radiusMeters,
      userLat: clearUserLocation ? null : (userLat ?? this.userLat),
      userLng: clearUserLocation ? null : (userLng ?? this.userLng),
      pendingAutoActivate: pendingAutoActivate ?? this.pendingAutoActivate,
    );
  }
}

/// Mengelola state Mode Pembangkit Terdekat pada peta eksplorasi.
class MapNearbyNotifier extends Notifier<MapNearbyState> {
  @override
  MapNearbyState build() => const MapNearbyState();

  /// Menandai agar `ExploreMapPage` otomatis mengaktifkan Mode Terdekat
  /// setelah berpindah tab dari halaman Beranda.
  void requestAutoActivate() {
    state = state.copyWith(pendingAutoActivate: true);
  }

  void consumePendingAutoActivate() {
    if (!state.pendingAutoActivate) return;
    state = state.copyWith(pendingAutoActivate: false);
  }

  void enable({
    required double userLat,
    required double userLng,
    int? radiusMeters,
  }) {
    state = state.copyWith(
      isEnabled: true,
      userLat: userLat,
      userLng: userLng,
      radiusMeters: radiusMeters ?? state.radiusMeters,
      pendingAutoActivate: false,
    );
  }

  void setRadiusMeters(int meters) {
    state = state.copyWith(radiusMeters: meters);
  }

  void disable() {
    state = state.copyWith(
      isEnabled: false,
      clearUserLocation: true,
      pendingAutoActivate: false,
    );
  }
}

final mapNearbyProvider = NotifierProvider<MapNearbyNotifier, MapNearbyState>(
  MapNearbyNotifier.new,
);

/// Menyaring dan mengurutkan daftar pembangkit dalam [radiusMeters] dari lokasi
/// pengguna, sekaligus mengisi properti `distanceMeters` tiap item (terdekat dulu).
List<PowerPlant> filterAndSortPlantsByRadius({
  required List<PowerPlant> plants,
  required double userLat,
  required double userLng,
  required int radiusMeters,
}) {
  const distance = Distance();
  final origin = LatLng(userLat, userLng);
  final withinRadius = <PowerPlant>[];

  for (final plant in plants) {
    final meters = distance.distance(
      origin,
      LatLng(plant.latitude, plant.longitude),
    );
    if (meters <= radiusMeters) {
      withinRadius.add(plant.copyWith(distanceMeters: meters));
    }
  }

  withinRadius.sort(
    (a, b) => (a.distanceMeters ?? double.infinity)
        .compareTo(b.distanceMeters ?? double.infinity),
  );
  return withinRadius;
}

/// Menghitung sudut batas barat-daya dan timur-laut (SW, NE) untuk sebuah
/// lingkaran radius agar kamera peta dapat di-zoom pas ke cakupan radius.
({LatLng southWest, LatLng northEast}) computeNearbyRadiusCorners({
  required LatLng center,
  required int radiusMeters,
}) {
  const distance = Distance();
  final north = distance.offset(center, radiusMeters, 0);
  final east = distance.offset(center, radiusMeters, 90);
  final south = distance.offset(center, radiusMeters, 180);
  final west = distance.offset(center, radiusMeters, 270);

  return (
    southWest: LatLng(
      south.latitude.clamp(-85.0, 85.0),
      west.longitude.clamp(-180.0, 180.0),
    ),
    northEast: LatLng(
      north.latitude.clamp(-85.0, 85.0),
      east.longitude.clamp(-180.0, 180.0),
    ),
  );
}


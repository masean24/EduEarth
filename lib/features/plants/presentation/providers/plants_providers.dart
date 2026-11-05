import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../models/energy_category.dart';
import '../../../../models/power_plant.dart';
import '../../../../services/location_service.dart';
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

/// Radius pencarian pembangkit terdekat dalam meter (default: 500 km agar mencakup
/// titik di kepulauan Indonesia, dapat diubah oleh pengguna di halaman Nearby).
class NearbyRadiusMetersNotifier extends Notifier<int> {
  @override
  int build() => 500000;

  void setRadiusMeters(int meters) {
    state = meters;
  }
}

final nearbyRadiusMetersProvider =
    NotifierProvider<NearbyRadiusMetersNotifier, int>(
  NearbyRadiusMetersNotifier.new,
);

/// State gabungan hasil lokasi pengguna dan daftar pembangkit terdekat.
class NearbyPlantsViewState {
  const NearbyPlantsViewState({
    required this.locationResult,
    this.plants = const <PowerPlant>[],
  });

  final LocationResult locationResult;
  final List<PowerPlant> plants;
}

final nearbyPlantsStateProvider =
    FutureProvider<NearbyPlantsViewState>((ref) async {
  final locationService = ref.watch(locationServiceProvider);
  final repo = ref.watch(plantsRepositoryProvider);
  final radiusMeters = ref.watch(nearbyRadiusMetersProvider);
  final selectedCategorySlug = ref.watch(selectedCategoryFilterProvider);

  final locationResult = await locationService.getCurrentLocation();
  if (!locationResult.hasPosition) {
    return NearbyPlantsViewState(locationResult: locationResult);
  }

  final pos = locationResult.position!;
  final nearby = await repo.getNearbyPlants(
    latitude: pos.latitude,
    longitude: pos.longitude,
    radiusMeters: radiusMeters,
    categorySlug: selectedCategorySlug,
  );

  return NearbyPlantsViewState(
    locationResult: locationResult,
    plants: nearby,
  );
});


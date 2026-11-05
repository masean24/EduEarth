import 'package:latlong2/latlong.dart';

import '../../../core/config/app_config.dart';
import '../../../core/constants/demo_data.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../models/energy_category.dart';
import '../../../models/power_plant.dart';
import '../../../services/supabase_service.dart';

/// Repository terpusat untuk mengambil kategori energi, daftar pembangkit,
/// detail pembangkit, serta hasil RPC `nearby_plants` dari Supabase.
///
/// Fallback `DemoData` HANYA dipakai bila `AppConfig.isSupabaseConfigured == false`.
/// Apabila Supabase sudah dikonfigurasi tetapi query/inisialisasi gagal,
/// repository melempar `AppException` agar UI menampilkan `ErrorView`.
class PlantsRepository {
  const PlantsRepository();

  Future<List<EnergyCategory>> getEnergyCategories() async {
    if (!AppConfig.isSupabaseConfigured) {
      return DemoData.categories;
    }

    try {
      final rows = await SupabaseService.client
          .from('energy_categories')
          .select()
          .order('sort_order', ascending: true);

      return (rows as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(EnergyCategory.fromJson)
          .toList();
    } catch (e, st) {
      throw ErrorMapper.map(e, st);
    }
  }

  Future<List<PowerPlant>> getPublishedPlants({String? categorySlug}) async {
    if (!AppConfig.isSupabaseConfigured) {
      if (categorySlug == null || categorySlug.isEmpty) {
        return DemoData.plants;
      }
      return DemoData.plants
          .where((p) => p.categorySlug == categorySlug)
          .toList();
    }

    try {
      final rows = await SupabaseService.client
          .from('power_plants')
          .select(
            '*, energy_categories!inner(slug, name, short_code)',
          )
          .eq('is_published', true)
          .eq('is_demo', false)
          .order('name', ascending: true);

      final plants = (rows as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(PowerPlant.fromJson)
          .where((plant) => !plant.isDemo)
          .toList();

      if (categorySlug == null || categorySlug.isEmpty) {
        return plants;
      }
      return plants
          .where((plant) => plant.categorySlug == categorySlug)
          .toList();
    } catch (e, st) {
      throw ErrorMapper.map(e, st);
    }
  }

  Future<PowerPlant> getPlantById(String id) async {
    if (!AppConfig.isSupabaseConfigured) {
      final match = DemoData.plants.where((p) => p.id == id).firstOrNull;
      if (match != null) return match;
      throw const AppException(
        message: 'Data pembangkit tidak ditemukan.',
        code: 'not_found',
      );
    }

    try {
      final row = await SupabaseService.client
          .from('power_plants')
          .select(
            '*, energy_categories(slug, name, short_code)',
          )
          .eq('id', id)
          .eq('is_published', true)
          .eq('is_demo', false)
          .maybeSingle();

      if (row == null) {
        throw const AppException(
          message: 'Data pembangkit tidak ditemukan atau belum dipublikasikan.',
          code: 'not_found',
        );
      }

      return PowerPlant.fromJson(row);
    } catch (e, st) {
      throw ErrorMapper.map(e, st);
    }
  }

  Future<List<PowerPlant>> getNearbyPlants({
    required double latitude,
    required double longitude,
    required int radiusMeters,
    String? categorySlug,
  }) async {
    if (!AppConfig.isSupabaseConfigured) {
      const distance = Distance();
      final userPoint = LatLng(latitude, longitude);

      final filtered = DemoData.plants
          .where(
            (p) =>
                categorySlug == null ||
                categorySlug.isEmpty ||
                p.categorySlug == categorySlug,
          )
          .map((plant) {
            final meters = distance.as(
              LengthUnit.Meter,
              userPoint,
              LatLng(plant.latitude, plant.longitude),
            );
            return plant.copyWith(distanceMeters: meters);
          })
          .where(
            (plant) =>
                (plant.distanceMeters ?? double.infinity) <= radiusMeters,
          )
          .toList()
        ..sort(
          (a, b) => (a.distanceMeters ?? 0).compareTo(b.distanceMeters ?? 0),
        );

      return filtered;
    }

    try {
      final rows = await SupabaseService.client.rpc(
        'nearby_plants',
        params: {
          'lat': latitude,
          'lng': longitude,
          'radius_m': radiusMeters,
          'category_slug': categorySlug,
        },
      );

      return (rows as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(PowerPlant.fromJson)
          .where((plant) => !plant.isDemo)
          .toList();
    } catch (e, st) {
      throw ErrorMapper.map(e, st);
    }
  }
}

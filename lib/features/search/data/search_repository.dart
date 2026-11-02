import '../../../core/config/app_config.dart';
import '../../../core/constants/demo_data.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../models/learning_material.dart';
import '../../../models/power_plant.dart';
import '../../../services/supabase_service.dart';

/// Hasil pencarian gabungan untuk pembangkit energi dan materi pembelajaran.
class GlobalSearchResults {
  const GlobalSearchResults({
    this.plants = const <PowerPlant>[],
    this.materials = const <LearningMaterial>[],
  });

  final List<PowerPlant> plants;
  final List<LearningMaterial> materials;

  bool get isEmpty => plants.isEmpty && materials.isEmpty;
}

/// Repository untuk mencari pembangkit (`power_plants`) dan materi (`learning_materials`)
/// berdasarkan kata kunci.
class SearchRepository {
  const SearchRepository();

  /// Menyanitasi input pengguna agar aman terhadap parser filter `.or()` PostgREST
  /// (menghapus koma, kurung, titik, kutip) serta meng-escape karakter wildcard
  /// SQL `ILIKE` (`\`, `%`, dan `_`).
  static String sanitizeForPostgrestIlike(String rawInput) {
    // 1. Ganti karakter pemisah sintaks PostgREST (koma, kurung, titik, kutip) dengan spasi
    final withoutSyntaxChars = rawInput
        .replaceAll(RegExp(r'[,().":;]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (withoutSyntaxChars.isEmpty) {
      return '';
    }

    // 2. Escape backslash terlebih dahulu, lalu karakter wildcard % dan _
    return withoutSyntaxChars
        .replaceAll(r'\', r'\\')
        .replaceAll('%', r'\%')
        .replaceAll('_', r'\_');
  }

  Future<GlobalSearchResults> search(String rawQuery) async {
    final query = rawQuery.trim();
    if (query.isEmpty) {
      return const GlobalSearchResults();
    }

    if (!AppConfig.isSupabaseConfigured) {
      final lower = query.toLowerCase();
      final matchedPlants = DemoData.plants.where((p) {
        return p.name.toLowerCase().contains(lower) ||
            p.province.toLowerCase().contains(lower) ||
            (p.city?.toLowerCase().contains(lower) ?? false);
      }).toList();

      final matchedMaterials = DemoData.materials.where((m) {
        return m.title.toLowerCase().contains(lower) ||
            m.summary.toLowerCase().contains(lower);
      }).toList();

      return GlobalSearchResults(
        plants: matchedPlants,
        materials: matchedMaterials,
      );
    }

    try {
      final sanitized = sanitizeForPostgrestIlike(query);
      if (sanitized.isEmpty) {
        return const GlobalSearchResults();
      }
      final pattern = '%$sanitized%';

      final plantsFuture = SupabaseService.client
          .from('power_plants')
          .select('*, energy_categories(slug, name, short_code)')
          .eq('is_published', true)
          .or(
            'name.ilike.$pattern,province.ilike.$pattern,city.ilike.$pattern,description.ilike.$pattern',
          )
          .order('name', ascending: true)
          .limit(20);

      final materialsFuture = SupabaseService.client
          .from('learning_materials')
          .select('*, energy_categories(slug, name, short_code)')
          .eq('is_published', true)
          .or('title.ilike.$pattern,summary.ilike.$pattern')
          .order('sort_order', ascending: true)
          .limit(20);

      final results = await Future.wait<dynamic>([
        plantsFuture,
        materialsFuture,
      ]);

      final plants = (results[0] as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(PowerPlant.fromJson)
          .toList();

      final materials = (results[1] as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(LearningMaterial.fromJson)
          .toList();

      return GlobalSearchResults(
        plants: plants,
        materials: materials,
      );
    } catch (e, st) {
      throw ErrorMapper.map(e, st);
    }
  }
}

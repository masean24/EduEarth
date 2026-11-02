import '../../../core/config/app_config.dart';
import '../../../core/constants/demo_data.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../models/learning_material.dart';
import '../../../services/supabase_service.dart';

/// Repository untuk membaca materi pembelajaran (`learning_materials`) dari Supabase.
///
/// Fallback `DemoData.materials` HANYA dipakai saat `AppConfig.isSupabaseConfigured == false`.
class LearningRepository {
  const LearningRepository();

  Future<List<LearningMaterial>> getPublishedMaterials({
    String? categorySlug,
  }) async {
    if (!AppConfig.isSupabaseConfigured) {
      if (categorySlug == null || categorySlug.isEmpty) {
        return DemoData.materials;
      }
      return DemoData.materials
          .where((m) => m.categorySlug == categorySlug)
          .toList();
    }

    try {
      final rows = await SupabaseService.client
          .from('learning_materials')
          .select(
            '*, energy_categories!inner(slug, name, short_code)',
          )
          .eq('is_published', true)
          .order('sort_order', ascending: true)
          .order('created_at', ascending: true);

      final materials = (rows as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(LearningMaterial.fromJson)
          .toList();

      if (categorySlug == null || categorySlug.isEmpty) {
        return materials;
      }
      return materials
          .where((m) => m.categorySlug == categorySlug)
          .toList();
    } catch (e, st) {
      throw ErrorMapper.map(e, st);
    }
  }

  Future<LearningMaterial> getMaterialBySlug(String slug) async {
    if (!AppConfig.isSupabaseConfigured) {
      final match = DemoData.materials.where((m) => m.slug == slug).firstOrNull;
      if (match != null) return match;
      throw const AppException(
        message: 'Materi pembelajaran tidak ditemukan.',
        code: 'not_found',
      );
    }

    try {
      final row = await SupabaseService.client
          .from('learning_materials')
          .select(
            '*, energy_categories(slug, name, short_code)',
          )
          .eq('slug', slug)
          .eq('is_published', true)
          .maybeSingle();

      if (row == null) {
        throw const AppException(
          message: 'Materi pembelajaran tidak ditemukan atau belum dipublikasikan.',
          code: 'not_found',
        );
      }

      return LearningMaterial.fromJson(row);
    } catch (e, st) {
      throw ErrorMapper.map(e, st);
    }
  }
}


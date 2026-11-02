import '../../../core/config/app_config.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../models/bookmark.dart';
import '../../../services/supabase_service.dart';

/// Repository untuk membaca, menambah, dan menghapus bookmark milik pengguna.
class BookmarkRepository {
  const BookmarkRepository();

  Future<List<Bookmark>> getUserBookmarks() async {
    if (!AppConfig.isSupabaseConfigured) {
      return const <Bookmark>[];
    }

    try {
      final user = SupabaseService.client.auth.currentUser;
      if (user == null) {
        return const <Bookmark>[];
      }

      final rows = await SupabaseService.client
          .from('bookmarks')
          .select(
            '*, '
            'learning_materials(*, energy_categories(slug, name, short_code)), '
            'power_plants(*, energy_categories(slug, name, short_code))',
          )
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      return (rows as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(Bookmark.fromJson)
          .toList();
    } catch (e, st) {
      throw ErrorMapper.map(e, st);
    }
  }

  Future<void> toggleMaterialBookmark(String materialId) async {
    try {
      final user = SupabaseService.client.auth.currentUser;
      if (user == null) {
        throw const AppException(
          message: 'Silakan masuk (login) terlebih dahulu untuk menyimpan bookmark.',
          code: 'unauthenticated',
        );
      }

      final existing = await SupabaseService.client
          .from('bookmarks')
          .select('id')
          .eq('user_id', user.id)
          .eq('material_id', materialId)
          .maybeSingle();

      if (existing != null) {
        await SupabaseService.client
            .from('bookmarks')
            .delete()
            .eq('id', existing['id'] as String);
      } else {
        await SupabaseService.client.from('bookmarks').insert({
          'user_id': user.id,
          'material_id': materialId,
        });
      }
    } catch (e, st) {
      throw ErrorMapper.map(e, st);
    }
  }

  Future<void> togglePlantBookmark(String plantId) async {
    try {
      final user = SupabaseService.client.auth.currentUser;
      if (user == null) {
        throw const AppException(
          message: 'Silakan masuk (login) terlebih dahulu untuk menyimpan bookmark.',
          code: 'unauthenticated',
        );
      }

      final existing = await SupabaseService.client
          .from('bookmarks')
          .select('id')
          .eq('user_id', user.id)
          .eq('plant_id', plantId)
          .maybeSingle();

      if (existing != null) {
        await SupabaseService.client
            .from('bookmarks')
            .delete()
            .eq('id', existing['id'] as String);
      } else {
        await SupabaseService.client.from('bookmarks').insert({
          'user_id': user.id,
          'plant_id': plantId,
        });
      }
    } catch (e, st) {
      throw ErrorMapper.map(e, st);
    }
  }
}

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/config/app_config.dart';
import '../../../core/constants/demo_data.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../models/app_notification.dart';
import '../../../services/supabase_service.dart';

/// Repository untuk mengambil pengumuman publik dari tabel `notifications`
/// serta mengelola timestamp terakhir dibaca di `SharedPreferences`.
class NotificationRepository {
  const NotificationRepository();

  static const String _lastReadAtPrefsKey =
      'eduearth_notifications_last_read_at';

  Future<List<AppNotification>> getPublishedNotifications() async {
    if (!AppConfig.isSupabaseConfigured) {
      return DemoData.notifications;
    }

    try {
      final rows = await SupabaseService.client
          .from('notifications')
          .select('*')
          .eq('is_published', true)
          .order('created_at', ascending: false);

      return (rows as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(AppNotification.fromJson)
          .toList();
    } catch (e, st) {
      throw ErrorMapper.map(e, st);
    }
  }

  Future<DateTime?> getLastReadAt() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_lastReadAtPrefsKey);
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> setLastReadAt(DateTime timestamp) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastReadAtPrefsKey, timestamp.toUtc().toIso8601String());
  }
}


import '../../../core/config/app_config.dart';
import '../../../core/constants/demo_data.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../models/achievement.dart';
import '../../../services/supabase_service.dart';

/// Repository untuk mengelola daftar `achievements`, progres `user_achievements`,
/// serta evaluasi server-side melalui RPC `check_and_award_achievements()`.
class AchievementRepository {
  const AchievementRepository();

  /// Antrian sementara untuk menampung judul badge yang baru saja diberikan oleh
  /// server saat `getAchievementsWithStatus()` atau `evaluateAchievements()` dipanggil,
  /// agar dialog animasi perayaan tidak pernah terlewat oleh UI.
  static final List<String> _pendingCelebrationTitles = <String>[];

  /// Mengambil dan mengosongkan daftar judul badge baru yang belum ditampilkan
  /// pada dialog perayaan.
  List<String> consumePendingCelebrations() {
    if (_pendingCelebrationTitles.isEmpty) return const <String>[];
    final copy = List<String>.from(_pendingCelebrationTitles);
    _pendingCelebrationTitles.clear();
    return copy;
  }

  void _recordNewlyAwarded(List<String> titles) {
    for (final title in titles) {
      if (title.trim().isNotEmpty &&
          !_pendingCelebrationTitles.contains(title)) {
        _pendingCelebrationTitles.add(title);
      }
    }
  }

  Future<List<Achievement>> getAchievementsWithStatus() async {
    if (!AppConfig.isSupabaseConfigured) {
      return DemoData.achievements;
    }

    try {
      final client = SupabaseService.client;
      final user = client.auth.currentUser;

      // Evaluasi otomatis di server bila pengguna sedang login
      if (user != null) {
        final rpcRes = await client.rpc('check_and_award_achievements');
        if (rpcRes is Map<String, dynamic>) {
          final awardResult = AchievementAwardResult.fromJson(rpcRes);
          _recordNewlyAwarded(awardResult.newlyAwardedTitles);
        }
      }

      final rows = await client
          .from('achievements')
          .select('*')
          .order('sort_order', ascending: true);

      final Map<String, DateTime> unlockedByAchievementId = {};
      if (user != null) {
        final userRows = await client
            .from('user_achievements')
            .select('achievement_id, unlocked_at')
            .eq('user_id', user.id);

        for (final item in (userRows as List<dynamic>)) {
          if (item is Map<String, dynamic>) {
            final achId = item['achievement_id'] as String?;
            final unlockedRaw = item['unlocked_at'] as String?;
            if (achId != null && unlockedRaw != null) {
              final parsed = DateTime.tryParse(unlockedRaw);
              if (parsed != null) {
                unlockedByAchievementId[achId] = parsed;
              }
            }
          }
        }
      }

      return (rows as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map((json) {
            final id = (json['id'] as String?) ?? '';
            return Achievement.fromJson(
              json,
              unlockedAtOverride: unlockedByAchievementId[id],
            );
          })
          .toList();
    } catch (e, st) {
      throw ErrorMapper.map(e, st);
    }
  }

  Future<AchievementAwardResult> evaluateAchievements() async {
    if (!AppConfig.isSupabaseConfigured) {
      return const AchievementAwardResult(
        newlyAwardedTitles: <String>[],
        totalUnlocked: 0,
      );
    }

    try {
      final user = SupabaseService.client.auth.currentUser;
      if (user == null) {
        return const AchievementAwardResult(
          newlyAwardedTitles: <String>[],
          totalUnlocked: 0,
        );
      }

      final response = await SupabaseService.client.rpc(
        'check_and_award_achievements',
      );
      if (response is Map<String, dynamic>) {
        final parsed = AchievementAwardResult.fromJson(response);
        _recordNewlyAwarded(parsed.newlyAwardedTitles);
        final allNew = consumePendingCelebrations();
        return AchievementAwardResult(
          newlyAwardedTitles: allNew,
          totalUnlocked: parsed.totalUnlocked,
        );
      }
      return const AchievementAwardResult(
        newlyAwardedTitles: <String>[],
        totalUnlocked: 0,
      );
    } catch (e, st) {
      throw ErrorMapper.map(e, st);
    }
  }
}

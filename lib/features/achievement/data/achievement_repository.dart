import '../../../core/config/app_config.dart';
import '../../../core/constants/demo_data.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../models/achievement.dart';
import '../../../services/supabase_service.dart';

/// Repository untuk mengelola daftar `achievements`, progres `user_achievements`,
/// serta evaluasi server-side melalui RPC `check_and_award_achievements()`.
class AchievementRepository {
  const AchievementRepository();

  Future<List<Achievement>> getAchievementsWithStatus() async {
    if (!AppConfig.isSupabaseConfigured) {
      return DemoData.achievements;
    }

    try {
      final client = SupabaseService.client;
      final user = client.auth.currentUser;

      // Evaluasi otomatis di server bila pengguna sedang login
      if (user != null) {
        await client.rpc('check_and_award_achievements');
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
        return AchievementAwardResult.fromJson(response);
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


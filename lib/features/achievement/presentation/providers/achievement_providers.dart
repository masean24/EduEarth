import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/achievement.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../bookmark/presentation/providers/bookmark_providers.dart';
import '../../../quiz/presentation/providers/quiz_providers.dart';
import '../../data/achievement_repository.dart';

final achievementRepositoryProvider = Provider<AchievementRepository>((ref) {
  return const AchievementRepository();
});

/// Memuat daftar seluruh achievement beserta status terbuka milik pengguna saat ini.
/// Otomatis ikut ter-refresh saat sesi auth, daftar bookmark, atau riwayat kuis berubah.
final achievementsListProvider = FutureProvider<List<Achievement>>((ref) async {
  ref.watch(currentSessionProvider);
  ref.watch(userBookmarksProvider);
  ref.watch(userQuizAttemptsProvider);

  final repository = ref.watch(achievementRepositoryProvider);
  return repository.getAchievementsWithStatus();
});

/// Menghitung jumlah badge yang sudah berhasil dibuka oleh pengguna.
final unlockedAchievementCountProvider = Provider<int>((ref) {
  final list = ref.watch(achievementsListProvider).asData?.value;
  if (list == null) return 0;
  return list.where((a) => a.isUnlocked).length;
});

/// Menghitung total poin eksplorasi dari seluruh badge yang sudah dibuka.
final unlockedAchievementPointsProvider = Provider<int>((ref) {
  final list = ref.watch(achievementsListProvider).asData?.value;
  if (list == null) return 0;
  return list
      .where((a) => a.isUnlocked)
      .fold<int>(0, (sum, item) => sum + item.points);
});

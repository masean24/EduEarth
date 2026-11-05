import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/app_notification.dart';
import '../../data/notification_repository.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return const NotificationRepository();
});

/// Memuat daftar pengumuman publik (`is_published = true`) terurut terbaru.
final notificationsListProvider =
    FutureProvider<List<AppNotification>>((ref) async {
      final repository = ref.watch(notificationRepositoryProvider);
      return repository.getPublishedNotifications();
    });

/// Mengelola timestamp terakhir kali pengguna membuka halaman Notification Center
/// yang disimpan secara lokal di `SharedPreferences`.
class LastReadNotificationsNotifier extends AsyncNotifier<DateTime?> {
  @override
  Future<DateTime?> build() async {
    final repository = ref.watch(notificationRepositoryProvider);
    return repository.getLastReadAt();
  }

  Future<void> markAsReadUpTo(DateTime timestamp) async {
    final repository = ref.read(notificationRepositoryProvider);
    final current = state.asData?.value;
    final target = (current != null && current.isAfter(timestamp))
        ? current
        : timestamp;
    await repository.setLastReadAt(target);
    state = AsyncData(target);
  }
}

final lastReadNotificationsAtProvider =
    AsyncNotifierProvider<LastReadNotificationsNotifier, DateTime?>(
      LastReadNotificationsNotifier.new,
    );

/// Menghitung jumlah pengumuman yang belum dibaca berdasarkan perbandingan
/// `notification.createdAt` terhadap timestamp lokal di `SharedPreferences`.
final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationsListProvider).asData?.value;
  if (notifications == null || notifications.isEmpty) {
    return 0;
  }

  final lastReadAsync = ref.watch(lastReadNotificationsAtProvider);
  if (lastReadAsync.isLoading) {
    return 0;
  }

  final lastReadAt = lastReadAsync.asData?.value;
  if (lastReadAt == null) {
    return notifications.length;
  }

  return notifications
      .where((item) => item.createdAt.toUtc().isAfter(lastReadAt.toUtc()))
      .length;
});


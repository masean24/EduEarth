import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/bookmark.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/bookmark_repository.dart';

final bookmarkRepositoryProvider = Provider<BookmarkRepository>((ref) {
  return const BookmarkRepository();
});

/// Daftar seluruh bookmark milik pengguna yang sedang login.
final userBookmarksProvider = FutureProvider<List<Bookmark>>((ref) async {
  final session = ref.watch(currentSessionProvider);
  if (session == null) {
    return const <Bookmark>[];
  }
  final repo = ref.watch(bookmarkRepositoryProvider);
  return repo.getUserBookmarks();
});

/// Mengecek apakah suatu `materialId` sudah di-bookmark oleh pengguna saat ini.
final isMaterialBookmarkedProvider = Provider.family<bool, String>((
  ref,
  materialId,
) {
  final bookmarksAsync = ref.watch(userBookmarksProvider);
  final bookmarks = bookmarksAsync.asData?.value ?? const <Bookmark>[];
  return bookmarks.any((b) => b.materialId == materialId);
});

/// Mengecek apakah suatu `plantId` sudah di-bookmark oleh pengguna saat ini.
final isPlantBookmarkedProvider = Provider.family<bool, String>((
  ref,
  plantId,
) {
  final bookmarksAsync = ref.watch(userBookmarksProvider);
  final bookmarks = bookmarksAsync.asData?.value ?? const <Bookmark>[];
  return bookmarks.any((b) => b.plantId == plantId);
});

/// Controller untuk melakukan toggle bookmark materi atau pembangkit.
class BookmarkController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<bool> toggleMaterial(String materialId) async {
    state = const AsyncLoading();
    final repo = ref.read(bookmarkRepositoryProvider);
    state = await AsyncValue.guard(() async {
      await repo.toggleMaterialBookmark(materialId);
      ref.invalidate(userBookmarksProvider);
    });
    return !state.hasError;
  }

  Future<bool> togglePlant(String plantId) async {
    state = const AsyncLoading();
    final repo = ref.read(bookmarkRepositoryProvider);
    state = await AsyncValue.guard(() async {
      await repo.togglePlantBookmark(plantId);
      ref.invalidate(userBookmarksProvider);
    });
    return !state.hasError;
  }
}

final bookmarkControllerProvider =
    AsyncNotifierProvider<BookmarkController, void>(BookmarkController.new);

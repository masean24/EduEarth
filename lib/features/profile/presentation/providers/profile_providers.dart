import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return const ProfileRepository();
});

/// Controller untuk menyimpan perubahan nama tampilan dan URL avatar profil.
class ProfileController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<bool> updateProfile({
    required String displayName,
    String? avatarUrl,
  }) async {
    state = const AsyncLoading();
    final repo = ref.read(profileRepositoryProvider);
    state = await AsyncValue.guard(() async {
      await repo.updateMyProfile(
        displayName: displayName,
        avatarUrl: avatarUrl,
      );
      ref.invalidate(currentUserProfileProvider);
    });
    return !state.hasError;
  }
}

final profileControllerProvider =
    AsyncNotifierProvider<ProfileController, void>(ProfileController.new);

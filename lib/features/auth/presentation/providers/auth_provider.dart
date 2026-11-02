import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../models/user_profile.dart';
import '../../data/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return const AuthRepository();
});

/// Stream perubahan state autentikasi Supabase.
final authStateStreamProvider = StreamProvider<AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.onAuthStateChange;
});

/// Provider `Session?` saat ini yang bereaksi otomatis terhadap login/logout.
final currentSessionProvider = Provider<Session?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  final authStateAsync = ref.watch(authStateStreamProvider);
  return authStateAsync.maybeWhen(
    data: (authState) => authState.session,
    orElse: () => repo.currentSession,
  );
});

/// Provider apakah pengguna saat ini sudah terautentikasi.
final isAuthenticatedProvider = Provider<bool>((ref) {
  final session = ref.watch(currentSessionProvider);
  return session != null;
});

/// Provider untuk mengambil `UserProfile` milik pengguna yang sedang login.
final currentUserProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final session = ref.watch(currentSessionProvider);
  if (session == null) return null;
  final repo = ref.watch(authRepositoryProvider);
  return repo.getCurrentUserProfile();
});

/// Controller aksi login, register, dan logout.
class AuthController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    final repo = ref.read(authRepositoryProvider);
    state = await AsyncValue.guard(() async {
      await repo.signInWithPassword(email: email, password: password);
    });
    return !state.hasError;
  }

  /// Mengembalikan `true` bila pendaftaran berhasil, dan mengisi `requiresEmailConfirmation`
  /// bila proyek Supabase mewajibkan konfirmasi email sebelum sesi aktif.
  Future<({bool success, bool requiresEmailConfirmation})> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    state = const AsyncLoading();
    final repo = ref.read(authRepositoryProvider);
    AuthResponse? response;

    state = await AsyncValue.guard(() async {
      response = await repo.signUpWithPassword(
        email: email,
        password: password,
        displayName: displayName,
      );
    });

    if (state.hasError) {
      return (success: false, requiresEmailConfirmation: false);
    }

    final needsConfirmation =
        response?.user != null && response?.session == null;
    return (
      success: true,
      requiresEmailConfirmation: needsConfirmation,
    );
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    final repo = ref.read(authRepositoryProvider);
    state = await AsyncValue.guard(repo.signOut);
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, void>(AuthController.new);


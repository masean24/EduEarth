import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../models/user_profile.dart';
import '../../../../services/supabase_service.dart';
import '../../data/auth_repository.dart';

/// Nilai awal mode tamu yang dapat di-override dari `SharedPreferences` saat app start.
final initialGuestModeProvider = Provider<bool>((ref) => false);

/// State mode tamu (disimpan lokal agar pengguna tamu tidak mengulang ke layar masuk).
class GuestModeNotifier extends Notifier<bool> {
  @override
  bool build() => ref.watch(initialGuestModeProvider);

  Future<void> restoreSavedGuestMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getBool(AppConstants.prefGuestMode) ?? false;
      if (saved) {
        state = true;
      }
    } catch (_) {
      // Abaikan jika binding SharedPreferences belum siap di lingkungan test unit.
    }
  }

  Future<void> enterGuestMode() async {
    state = true;
    await _persistGuestMode(true);
  }

  Future<void> exitGuestMode() async {
    state = false;
    await _persistGuestMode(false);
  }

  Future<void> _persistGuestMode(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.prefGuestMode, value);
    } catch (_) {}
  }
}

final isGuestModeProvider = NotifierProvider<GuestModeNotifier, bool>(
  GuestModeNotifier.new,
);

/// Bernilai `true` bila Supabase aktif, pengguna belum login, dan sedang memakai Mode Tamu.
final isGuestSessionProvider = Provider<bool>((ref) {
  final isSupabaseReady = ref.watch(isSupabaseInitializedProvider);
  final isAuthenticated = ref.watch(isAuthenticatedProvider);
  final isGuestMode = ref.watch(isGuestModeProvider);
  return isSupabaseReady && !isAuthenticated && isGuestMode;
});

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
    if (!state.hasError) {
      ref.read(isGuestModeProvider.notifier).exitGuestMode();
    }
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

    if (response?.session != null) {
      ref.read(isGuestModeProvider.notifier).exitGuestMode();
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
    ref.read(isGuestModeProvider.notifier).exitGuestMode();
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, void>(AuthController.new);


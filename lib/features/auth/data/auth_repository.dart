import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/error_mapper.dart';
import '../../../models/user_profile.dart';
import '../../../services/supabase_service.dart';

/// Repository autentikasi pengguna dan pembacaan profil dari Supabase.
class AuthRepository {
  const AuthRepository();

  bool get isSupabaseConfigured => SupabaseService.isInitialized;

  Session? get currentSession {
    if (!SupabaseService.isInitialized) return null;
    return SupabaseService.client.auth.currentSession;
  }

  User? get currentUser {
    if (!SupabaseService.isInitialized) return null;
    return SupabaseService.client.auth.currentUser;
  }

  Stream<AuthState> get onAuthStateChange {
    if (!SupabaseService.isInitialized) {
      return const Stream<AuthState>.empty();
    }
    return SupabaseService.client.auth.onAuthStateChange;
  }

  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await SupabaseService.client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
    } catch (e, st) {
      throw ErrorMapper.map(e, st);
    }
  }

  Future<AuthResponse> signUpWithPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      return await SupabaseService.client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'display_name': displayName.trim(),
        },
      );
    } catch (e, st) {
      throw ErrorMapper.map(e, st);
    }
  }

  Future<void> signOut() async {
    try {
      if (!SupabaseService.isInitialized) return;
      await SupabaseService.client.auth.signOut();
    } catch (e, st) {
      throw ErrorMapper.map(e, st);
    }
  }

  Future<UserProfile?> getCurrentUserProfile() async {
    try {
      if (!SupabaseService.isInitialized) return null;
      final user = currentUser;
      if (user == null) return null;

      final response = await SupabaseService.client
          .from('user_profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (response == null) return null;
      return UserProfile.fromJson(response);
    } catch (e, st) {
      throw ErrorMapper.map(e, st);
    }
  }
}


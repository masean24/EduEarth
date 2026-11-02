import '../../../core/config/app_config.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../models/user_profile.dart';
import '../../../services/supabase_service.dart';

/// Repository untuk membaca dan memperbarui baris `user_profiles` milik pengguna.
class ProfileRepository {
  const ProfileRepository();

  Future<UserProfile?> getMyProfile() async {
    if (!AppConfig.isSupabaseConfigured) {
      return null;
    }

    try {
      final user = SupabaseService.client.auth.currentUser;
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

  Future<UserProfile> updateMyProfile({
    required String displayName,
    String? avatarUrl,
  }) async {
    if (!AppConfig.isSupabaseConfigured) {
      throw const AppException(
        message: 'Server Supabase belum dikonfigurasi.',
        code: 'supabase_not_configured',
      );
    }

    try {
      final user = SupabaseService.client.auth.currentUser;
      if (user == null) {
        throw const AppException(
          message: 'Silakan masuk (login) terlebih dahulu untuk mengubah profil.',
          code: 'unauthenticated',
        );
      }

      final trimmedAvatar = avatarUrl?.trim() ?? '';
      final row = await SupabaseService.client
          .from('user_profiles')
          .update({
            'display_name': displayName.trim(),
            'avatar_url': trimmedAvatar.isEmpty ? null : trimmedAvatar,
          })
          .eq('id', user.id)
          .select()
          .single();

      return UserProfile.fromJson(row);
    } catch (e, st) {
      throw ErrorMapper.map(e, st);
    }
  }
}


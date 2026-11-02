import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/app_config.dart';
import '../core/errors/app_exception.dart';

/// Provider untuk memeriksa apakah Supabase sudah terinisialisasi dan siap digunakan.
final isSupabaseInitializedProvider = Provider<bool>((ref) {
  return SupabaseService.isInitialized;
});

/// Provider untuk mengakses `SupabaseClient`.
///
/// Melempar `AppException` yang ramah apabila kredensial belum dikonfigurasi.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return SupabaseService.client;
});

/// Layanan terpusat untuk inisialisasi dan akses client Supabase.
class SupabaseService {
  const SupabaseService._();

  static bool _isInitialized = false;

  static bool get isInitialized => _isInitialized;

  /// Menginisialisasi Supabase secara aman.
  ///
  /// Bila `SUPABASE_URL` dan `SUPABASE_ANON_KEY` belum diberikan lewat
  /// `--dart-define`, inisialisasi dilewati tanpa membuat aplikasi crash.
  static Future<void> initialize() async {
    if (_isInitialized) return;

    if (!AppConfig.isSupabaseConfigured) {
      if (kDebugMode) {
        debugPrint(
          '[SupabaseService] SUPABASE_URL atau SUPABASE_ANON_KEY belum '
          'dikonfigurasi via --dart-define. Berjalan tanpa koneksi Supabase.',
        );
      }
      return;
    }

    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        publishableKey: AppConfig.supabaseAnonKey,
      );
      _isInitialized = true;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[SupabaseService] Gagal menginisialisasi Supabase: $e');
        debugPrintStack(stackTrace: st);
      }
    }
  }

  static SupabaseClient get client {
    if (!_isInitialized) {
      throw const AppException(
        message:
            'Koneksi server belum dikonfigurasi. Jalankan aplikasi dengan '
            '--dart-define=SUPABASE_URL=... dan --dart-define=SUPABASE_ANON_KEY=...',
        code: 'supabase_not_initialized',
      );
    }
    return Supabase.instance.client;
  }
}


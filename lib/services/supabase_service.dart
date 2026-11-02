import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/app_config.dart';
import '../core/errors/app_exception.dart';

/// Provider untuk memeriksa apakah kredensial Supabase diberikan via `--dart-define`.
final isSupabaseConfiguredProvider = Provider<bool>((ref) {
  return AppConfig.isSupabaseConfigured;
});

/// Provider untuk memeriksa apakah Supabase sudah terinisialisasi dan siap digunakan.
final isSupabaseInitializedProvider = Provider<bool>((ref) {
  return SupabaseService.isInitialized;
});

/// Provider untuk mengakses `SupabaseClient`.
///
/// Melempar `AppException` yang ramah apabila kredensial belum dikonfigurasi
/// atau inisialisasi gagal.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return SupabaseService.client;
});

/// Layanan terpusat untuk inisialisasi dan akses client Supabase.
class SupabaseService {
  const SupabaseService._();

  static bool _isInitialized = false;
  static Object? _initializationError;

  static bool get isInitialized => _isInitialized;
  static Object? get initializationError => _initializationError;

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
      _initializationError = null;
    } catch (e, st) {
      _initializationError = e;
      if (kDebugMode) {
        debugPrint('[SupabaseService] Gagal menginisialisasi Supabase: $e');
        debugPrintStack(stackTrace: st);
      }
    }
  }

  static SupabaseClient get client {
    if (!AppConfig.isSupabaseConfigured) {
      throw const AppException(
        message:
            'Koneksi server belum dikonfigurasi. Jalankan aplikasi dengan '
            '--dart-define=SUPABASE_URL=... dan --dart-define=SUPABASE_ANON_KEY=...',
        code: 'supabase_not_configured',
      );
    }
    if (!_isInitialized) {
      throw AppException(
        message:
            'Gagal menginisialisasi koneksi ke server Supabase. Periksa URL/kunci konfigurasi dan koneksi internet Anda.',
        code: 'supabase_init_failed',
        originalError: _initializationError,
      );
    }
    return Supabase.instance.client;
  }
}

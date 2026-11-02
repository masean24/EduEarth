import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_exception.dart';

/// Memetakan error teknis dari Supabase atau jaringan menjadi `AppException`
/// dengan pesan Bahasa Indonesia yang ramah pengguna.
class ErrorMapper {
  const ErrorMapper._();

  static AppException map(Object error, [StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('ErrorMapper caught: $error');
      if (stackTrace != null) {
        debugPrintStack(stackTrace: stackTrace);
      }
    }

    if (error is AppException) {
      return error;
    }

    if (error is AuthException) {
      return AppException(
        message: _mapAuthMessage(error.message),
        code: error.statusCode,
        originalError: error,
      );
    }

    if (error is PostgrestException) {
      return AppException(
        message:
            'Gagal memuat atau menyimpan data. Silakan coba beberapa saat lagi.',
        code: error.code,
        originalError: error,
      );
    }

    return AppException(
      message:
          'Terjadi kesalahan koneksi atau sistem. Silakan periksa internet Anda dan coba lagi.',
      originalError: error,
    );
  }

  static String _mapAuthMessage(String rawMessage) {
    final lower = rawMessage.toLowerCase();
    if (lower.contains('invalid login credentials') ||
        lower.contains('invalid_credentials')) {
      return 'Email atau kata sandi yang Anda masukkan salah.';
    }
    if (lower.contains('user already registered') ||
        lower.contains('already exists')) {
      return 'Email ini sudah terdaftar. Silakan masuk menggunakan akun Anda.';
    }
    if (lower.contains('email not confirmed')) {
      return 'Email Anda belum dikonfirmasi. Silakan periksa kotak masuk email Anda.';
    }
    if (lower.contains('password should be at least') ||
        lower.contains('weak_password')) {
      return 'Kata sandi terlalu pendek. Gunakan minimal 6 karakter.';
    }
    if (lower.contains('rate limit') ||
        lower.contains('over_email_send_rate_limit') ||
        lower.contains('too many requests')) {
      return 'Terlalu banyak percobaan. Silakan tunggu beberapa saat sebelum mencoba lagi.';
    }
    if (lower.contains('invalid format') ||
        lower.contains('unable to validate email')) {
      return 'Format alamat email tidak valid.';
    }
    if (lower.contains('network') || lower.contains('socketexception')) {
      return 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
    }
    return 'Gagal memproses autentikasi. Silakan periksa kembali data Anda dan coba lagi.';
  }
}

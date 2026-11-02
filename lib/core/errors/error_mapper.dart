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
        message: 'Gagal memuat atau menyimpan data. Silakan coba beberapa saat lagi.',
        code: error.code,
        originalError: error,
      );
    }

    return AppException(
      message: 'Terjadi kesalahan koneksi atau sistem. Silakan periksa internet Anda dan coba lagi.',
      originalError: error,
    );
  }

  static String _mapAuthMessage(String rawMessage) {
    final lower = rawMessage.toLowerCase();
    if (lower.contains('invalid login credentials')) {
      return 'Email atau kata sandi yang Anda masukkan salah.';
    }
    if (lower.contains('user already registered')) {
      return 'Email ini sudah terdaftar. Silakan masuk menggunakan akun Anda.';
    }
    if (lower.contains('email not confirmed')) {
      return 'Email Anda belum dikonfirmasi. Silakan periksa kotak masuk email Anda.';
    }
    if (lower.contains('password should be at least')) {
      return 'Kata sandi terlalu pendek. Gunakan minimal 6 karakter.';
    }
    return 'Gagal memproses autentikasi. Silakan coba lagi.';
  }
}


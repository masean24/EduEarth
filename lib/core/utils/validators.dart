/// Validator input form untuk autentikasi dan profil dalam Bahasa Indonesia.
class AppValidators {
  const AppValidators._();

  static final RegExp _emailRegExp = RegExp(
    r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
  );

  static String? validateEmail(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Email wajib diisi.';
    }
    if (!_emailRegExp.hasMatch(trimmed)) {
      return 'Format email tidak valid.';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    final raw = value ?? '';
    if (raw.isEmpty) {
      return 'Kata sandi wajib diisi.';
    }
    if (raw.length < 6) {
      return 'Kata sandi minimal terdiri dari 6 karakter.';
    }
    return null;
  }

  static String? validateDisplayName(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Nama tampilan wajib diisi.';
    }
    if (trimmed.length < 2) {
      return 'Nama tampilan minimal 2 karakter.';
    }
    return null;
  }
}


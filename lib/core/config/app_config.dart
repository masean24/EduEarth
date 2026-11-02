/// Konfigurasi environment aplikasi yang disuntikkan melalui `--dart-define`.
///
/// Jangan pernah menaruh `service_role` key atau kredensial rahasia secara
/// hardcode di file ini.
class AppConfig {
  const AppConfig._();

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static bool get isSupabaseConfigured =>
      supabaseUrl.trim().isNotEmpty && supabaseAnonKey.trim().isNotEmpty;
}


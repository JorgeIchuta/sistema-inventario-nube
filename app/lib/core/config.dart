/// Valores que se pasan al compilar con --dart-define (nunca se escriben aqui).
class Config {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// URL publica de la version web. Se usa como destino del correo de
  /// recuperacion de contrasena cuando se pide desde el APK. Opcional.
  static const webUrl = String.fromEnvironment('WEB_URL');

  static bool get valida => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}

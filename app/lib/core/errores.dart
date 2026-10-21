import 'package:supabase_flutter/supabase_flutter.dart';

/// Error de validacion con mensaje listo para mostrar.
class AvisoUsuario implements Exception {
  const AvisoUsuario(this.mensaje);
  final String mensaje;
  @override
  String toString() => mensaje;
}

/// Convierte cualquier error en un mensaje claro en espanol.
String mensajeError(Object e) {
  if (e is AvisoUsuario) return e.mensaje;
  if (e is AuthException) {
    final m = e.message.toLowerCase();
    if (m.contains('invalid login')) return 'Correo o contraseña incorrectos.';
    if (m.contains('email not confirmed')) return 'El correo aún no fue confirmado.';
    if (m.contains('password')) return 'La contraseña no cumple los requisitos (mínimo 6 caracteres).';
    return e.message;
  }
  if (e is PostgrestException) {
    if (e.code == '23505') return 'Ya existe un registro con ese valor (por ejemplo, el código o el nombre).';
    if (e.code == '42501') return 'No tienes permiso para realizar esta operación.';
    if (e.code == '23503') return 'El registro está relacionado con otros datos.';
    return e.message; // mensajes en espanol lanzados por las funciones SQL
  }
  final t = e.toString();
  if (t.contains('SocketException') || t.contains('Failed host lookup') ||
      t.contains('ClientException') || t.contains('XMLHttpRequest')) {
    return 'Sin conexión a Internet. Revisa tu conexión e inténtalo de nuevo.';
  }
  return 'Ocurrió un error inesperado. Inténtalo de nuevo.';
}

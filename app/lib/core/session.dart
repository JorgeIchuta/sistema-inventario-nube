import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

SupabaseClient get supabase => Supabase.instance.client;

/// Estado de la sesion: usuario autenticado y su perfil (nombre, rol, activo).
class SesionApp extends ChangeNotifier {
  SesionApp._();
  static final instance = SesionApp._();

  Map<String, dynamic>? perfil;
  bool recuperandoClave = false;
  String? aviso; // mensaje para mostrar en el login (p. ej. cuenta desactivada)
  StreamSubscription<AuthState>? _sub;

  bool get conectado => supabase.auth.currentUser != null && perfil != null;
  bool get esAdmin => perfil?['rol'] == 'administrador';
  String get nombre => (perfil?['nombre'] as String?) ?? '';
  String get rolTexto => esAdmin ? 'Administrador' : 'Empleado';
  String get correo => supabase.auth.currentUser?.email ?? '';
  String get iniciales {
    final partes = nombre.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (partes.isEmpty) return '?';
    return partes.take(2).map((p) => p[0].toUpperCase()).join();
  }

  Future<void> iniciar() async {
    _sub = supabase.auth.onAuthStateChange.listen((data) async {
      switch (data.event) {
        case AuthChangeEvent.passwordRecovery:
          recuperandoClave = true;
          await cargarPerfil();
        case AuthChangeEvent.signedIn:
        case AuthChangeEvent.tokenRefreshed:
        case AuthChangeEvent.userUpdated:
          if (perfil == null) await cargarPerfil();
        case AuthChangeEvent.signedOut:
          perfil = null;
          recuperandoClave = false;
          notifyListeners();
        default:
          break;
      }
    });
    if (supabase.auth.currentUser != null) await cargarPerfil();
  }

  /// Lee el perfil del usuario. Si esta desactivado, cierra la sesion.
  Future<void> cargarPerfil() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return;
    try {
      final data = await supabase
          .from('perfiles')
          .select('id, nombre, rol, activo')
          .eq('id', uid)
          .maybeSingle();
      if (data == null || data['activo'] != true) {
        aviso = 'Tu cuenta está desactivada. Consulta con el administrador.';
        perfil = null;
        await supabase.auth.signOut();
      } else {
        perfil = data;
        aviso = null;
      }
    } catch (_) {
      perfil = null;
    }
    notifyListeners();
  }

  Future<void> cerrarSesion() async {
    await supabase.auth.signOut();
    perfil = null;
    notifyListeners();
  }

  void terminarRecuperacion() {
    recuperandoClave = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

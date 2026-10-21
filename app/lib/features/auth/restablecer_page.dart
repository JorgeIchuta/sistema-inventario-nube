import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errores.dart';
import '../../core/session.dart';
import '../../shared/widgets/comunes.dart';

/// Se muestra al abrir el enlace de recuperacion de contrasena.
class RestablecerPage extends StatefulWidget {
  const RestablecerPage({super.key});

  @override
  State<RestablecerPage> createState() => _RestablecerPageState();
}

class _RestablecerPageState extends State<RestablecerPage> {
  final _form = GlobalKey<FormState>();
  final _clave = TextEditingController();
  final _repetir = TextEditingController();
  bool _cargando = false;

  @override
  void dispose() {
    _clave.dispose();
    _repetir.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _cargando = true);
    try {
      await supabase.auth.updateUser(UserAttributes(password: _clave.text));
      if (!mounted) return;
      mostrarMensaje(context, 'Contraseña actualizada.');
      SesionApp.instance.terminarRecuperacion();
    } catch (e) {
      if (mounted) mostrarMensaje(context, mensajeError(e), error: true);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Tarjeta(
              padding: const EdgeInsets.all(28),
              child: Form(
                key: _form,
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  const Text('Nueva contraseña',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _clave,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Nueva contraseña'),
                    validator: (v) => (v ?? '').length < 6 ? 'Mínimo 6 caracteres.' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _repetir,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Repetir contraseña'),
                    validator: (v) => v != _clave.text ? 'Las contraseñas no coinciden.' : null,
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _cargando ? null : _guardar,
                    child: const Text('Guardar contraseña'),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

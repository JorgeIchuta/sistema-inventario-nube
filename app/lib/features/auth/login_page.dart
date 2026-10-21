import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/config.dart';
import '../../core/errores.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../shared/widgets/comunes.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _form = GlobalKey<FormState>();
  final _correo = TextEditingController();
  final _clave = TextEditingController();
  bool _cargando = false;
  bool _verClave = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _error = SesionApp.instance.aviso;
  }

  @override
  void dispose() {
    _correo.dispose();
    _clave.dispose();
    super.dispose();
  }

  Future<void> _ingresar() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      await supabase.auth.signInWithPassword(email: _correo.text.trim(), password: _clave.text);
      await SesionApp.instance.cargarPerfil();
      if (mounted && !SesionApp.instance.conectado) {
        setState(() => _error = SesionApp.instance.aviso ?? 'No se pudo cargar tu perfil.');
      }
    } catch (e) {
      if (mounted) setState(() => _error = mensajeError(e));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _recuperar() async {
    final ctrl = TextEditingController(text: _correo.text.trim());
    final correo = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Recuperar contraseña'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Te enviaremos un enlace para crear una nueva contraseña.'),
          const SizedBox(height: 16),
          TextField(
            controller: ctrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Correo electrónico'),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('Enviar')),
        ],
      ),
    );
    ctrl.dispose();
    if (correo == null || correo.isEmpty || !mounted) return;
    try {
      final destino = kIsWeb ? Uri.base.origin : (Config.webUrl.isEmpty ? null : Config.webUrl);
      await supabase.auth.resetPasswordForEmail(correo, redirectTo: destino);
      if (mounted) mostrarMensaje(context, 'Si el correo está registrado, recibirás el enlace en unos minutos.');
    } catch (e) {
      if (mounted) mostrarMensaje(context, mensajeError(e), error: true);
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
                  Center(child: Image.asset('assets/images/logo.png', height: 110)),
                  const SizedBox(height: 12),
                  const Text('Ingresa con tu cuenta',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  const Text('Control de inventario en la nube',
                      textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted)),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _correo,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(
                        labelText: 'Correo electrónico', prefixIcon: Icon(Icons.mail_outline)),
                    validator: (v) {
                      final t = (v ?? '').trim();
                      if (t.isEmpty) return 'Escribe tu correo.';
                      if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(t)) return 'Correo no válido.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _clave,
                    obscureText: !_verClave,
                    autofillHints: const [AutofillHints.password],
                    onFieldSubmitted: (_) => _ingresar(),
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        tooltip: _verClave ? 'Ocultar' : 'Mostrar',
                        icon: Icon(_verClave ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _verClave = !_verClave),
                      ),
                    ),
                    validator: (v) => (v ?? '').isEmpty ? 'Escribe tu contraseña.' : null,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: AppColors.dangerBg, borderRadius: BorderRadius.circular(10)),
                      child: Text(_error!, style: const TextStyle(color: AppColors.danger)),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _cargando ? null : _ingresar,
                    child: _cargando
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Ingresar'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(onPressed: _recuperar, child: const Text('¿Olvidaste tu contraseña?')),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

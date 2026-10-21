import 'package:flutter/material.dart';

import '../../core/errores.dart';
import '../../core/theme.dart';
import 'comunes.dart';

/// Abre un formulario en dialogo (pantalla completa en movil).
/// [guardar] debe lanzar una excepcion si falla; devuelve true si se guardo.
Future<bool> abrirFormulario({
  required BuildContext context,
  required String titulo,
  required List<Widget> Function(StateSetter setState) campos,
  required Future<void> Function() guardar,
  String textoGuardar = 'Guardar',
  double ancho = 560,
}) async {
  final resultado = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _FormularioDialog(
        titulo: titulo, campos: campos, guardar: guardar, textoGuardar: textoGuardar, ancho: ancho),
  );
  return resultado ?? false;
}

class _FormularioDialog extends StatefulWidget {
  const _FormularioDialog({required this.titulo, required this.campos, required this.guardar,
      required this.textoGuardar, required this.ancho});
  final String titulo;
  final List<Widget> Function(StateSetter setState) campos;
  final Future<void> Function() guardar;
  final String textoGuardar;
  final double ancho;

  @override
  State<_FormularioDialog> createState() => _FormularioDialogState();
}

class _FormularioDialogState extends State<_FormularioDialog> {
  final _form = GlobalKey<FormState>();
  bool _guardando = false;
  String? _error;

  Future<void> _enviar() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      await widget.guardar();
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _error = mensajeError(e));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final movil = MediaQuery.sizeOf(context).width < 680;
    final contenido = Form(
      key: _form,
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('INVENTARIO CLOUD', style: mono(size: 11, color: AppColors.muted)),
              Text(widget.titulo, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            ]),
          ),
          IconButton(
            tooltip: 'Cerrar',
            onPressed: _guardando ? null : () => Navigator.of(context).pop(false),
            icon: const Icon(Icons.close),
          ),
        ]),
        const SizedBox(height: 20),
        Flexible(
          child: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (context, setLocal) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final c in widget.campos(setLocal))
                    Padding(padding: const EdgeInsets.only(bottom: 16), child: c),
                ],
              ),
            ),
          ),
        ),
        if (_error != null)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.dangerBg, borderRadius: BorderRadius.circular(10)),
            child: Text(_error!, style: const TextStyle(color: AppColors.danger)),
          ),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          OutlinedButton(
            onPressed: _guardando ? null : () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          const SizedBox(width: 10),
          FilledButton(
            onPressed: _guardando ? null : _enviar,
            child: _guardando
                ? const SizedBox(
                    width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(widget.textoGuardar),
          ),
        ]),
      ]),
    );

    if (movil) {
      return Dialog.fullscreen(
        child: SafeArea(child: Padding(padding: const EdgeInsets.all(16), child: contenido)),
      );
    }
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: widget.ancho, maxHeight: MediaQuery.sizeOf(context).height * .9),
        child: Padding(padding: const EdgeInsets.all(24), child: contenido),
      ),
    );
  }
}

/// Dialogo de confirmacion. Devuelve true si el usuario acepta.
Future<bool> confirmar(BuildContext context, String titulo, String mensaje,
    {String aceptar = 'Confirmar', bool peligro = false}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(titulo),
      content: Text(mensaje),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
        FilledButton(
          style: peligro ? FilledButton.styleFrom(backgroundColor: AppColors.danger) : null,
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(aceptar),
        ),
      ],
    ),
  );
  return r ?? false;
}

/// Ejecuta una accion mostrando el resultado en un SnackBar.
Future<bool> ejecutar(BuildContext context, Future<void> Function() accion, String exito) async {
  try {
    await accion();
    if (context.mounted) mostrarMensaje(context, exito);
    return true;
  } catch (e) {
    if (context.mounted) mostrarMensaje(context, mensajeError(e), error: true);
    return false;
  }
}

/// Insignia de estado activo/inactivo.
Widget insigniaActivo(bool activo) =>
    activo ? const Insignia('Activo', Tono.exito) : const Insignia('Inactivo', Tono.peligro);

/// Botones de fila: editar y activar/desactivar.
class AccionesFila extends StatelessWidget {
  const AccionesFila({super.key, required this.onEditar, required this.onEstado, required this.activo,
      this.extras = const []});
  final VoidCallback onEditar;
  final VoidCallback onEstado;
  final bool activo;
  final List<Widget> extras;

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      ...extras,
      IconButton(tooltip: 'Editar', icon: const Icon(Icons.edit_outlined), onPressed: onEditar),
      IconButton(
        tooltip: activo ? 'Desactivar' : 'Activar',
        icon: Icon(activo ? Icons.block : Icons.check_circle_outline),
        onPressed: onEstado,
      ),
    ]);
  }
}

import 'package:flutter/material.dart';

import '../../core/session.dart';
import '../../core/theme.dart';
import '../../shared/validators.dart';
import '../../shared/widgets/formulario.dart';

/// Ajuste de inventario (solo administrador): fija el stock real con un motivo.
Future<bool> mostrarAjuste(BuildContext context, Map<String, dynamic> producto) async {
  final stock = TextEditingController(text: '${producto['stock_actual']}');
  final motivo = TextEditingController();
  final ok = await abrirFormulario(
    context: context,
    titulo: 'Ajustar inventario',
    textoGuardar: 'Registrar ajuste',
    campos: (_) => [
      Text('${producto['codigo']} · ${producto['nombre']}', style: const TextStyle(fontWeight: FontWeight.w700)),
      Text('Stock registrado: ${producto['stock_actual']}', style: mono(color: AppColors.muted)),
      TextFormField(
        controller: stock,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          labelText: 'Stock real (conteo físico) *',
          helperText: 'Quedará un movimiento de ajuste en el historial.',
        ),
        validator: (v) {
          final e = enteroNoNegativo(v);
          if (e != null) return e;
          return int.parse(v!.trim()) == producto['stock_actual'] ? 'Es igual al stock registrado.' : null;
        },
      ),
      TextFormField(
        controller: motivo,
        maxLines: 2,
        decoration: const InputDecoration(labelText: 'Motivo *', hintText: 'Ej.: producto dañado, conteo físico'),
        validator: (v) => requerido(v, 'El motivo'),
      ),
    ],
    guardar: () => supabase.rpc('registrar_ajuste', params: {
      'p_producto_id': producto['id'],
      'p_stock_nuevo': int.parse(stock.text.trim()),
      'p_motivo': motivo.text.trim(),
    }),
  );
  stock.dispose();
  motivo.dispose();
  return ok;
}

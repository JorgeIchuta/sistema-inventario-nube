import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../core/errores.dart';
import '../../core/formatters.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../shared/validators.dart';
import '../../shared/widgets/comunes.dart';
import '../../shared/widgets/formulario.dart';

class _Fila {
  _Fila({this.producto});
  int? producto;
  final cantidad = TextEditingController();
  final costo = TextEditingController();

  int get cant => int.tryParse(cantidad.text.trim()) ?? 0;
  double get cost => leerDecimal(costo.text) ?? 0;

  void dispose() {
    cantidad.dispose();
    costo.dispose();
  }
}

/// Abre el formulario de nueva entrada. Devuelve el id creado o null.
Future<int?> mostrarNuevaEntrada(BuildContext context, {int? productoInicial}) async {
  late final List<Map<String, dynamic>> proveedores;
  late final List<Map<String, dynamic>> productos;
  try {
    proveedores = await supabase.from('proveedores').select('id, nombre').eq('activo', true).order('nombre');
    productos = await supabase
        .from('productos')
        .select('id, codigo, nombre, stock_actual')
        .eq('activo', true)
        .order('nombre');
  } catch (e) {
    if (context.mounted) mostrarMensaje(context, mensajeError(e), error: true);
    return null;
  }
  if (!context.mounted) return null;
  if (proveedores.isEmpty || productos.isEmpty) {
    mostrarMensaje(context, 'Primero registra al menos un proveedor y un producto activos.', error: true);
    return null;
  }

  // La clave se genera al abrir: si se reintenta por mala conexion, no se duplica.
  final clave = const Uuid().v4();
  int? proveedor;
  final observaciones = TextEditingController();
  final filas = <_Fila>[_Fila(producto: productoInicial)];
  int? creada;

  double total() => filas.fold(0, (s, f) => s + f.cant * f.cost);

  final ok = await abrirFormulario(
    context: context,
    titulo: 'Nueva entrada',
    textoGuardar: 'Confirmar entrada',
    ancho: 760,
    campos: (setLocal) => [
      DropdownButtonFormField<int>(
        initialValue: proveedor,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Proveedor *'),
        items: [for (final p in proveedores) DropdownMenuItem(value: p['id'] as int, child: Text(p['nombre']))],
        onChanged: (v) => setLocal(() => proveedor = v),
        validator: (v) => v == null ? 'Elige un proveedor.' : null,
      ),
      const Text('Productos', style: TextStyle(fontWeight: FontWeight.w700)),
      for (var i = 0; i < filas.length; i++)
        _FilaEntrada(
          key: ObjectKey(filas[i]),
          fila: filas[i],
          productos: productos,
          onCambio: () => setLocal(() {}),
          onQuitar: filas.length == 1
              ? null
              : () => setLocal(() {
                    filas.removeAt(i).dispose();
                  }),
        ),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => setLocal(() => filas.add(_Fila())),
          icon: const Icon(Icons.add),
          label: const Text('Agregar producto'),
        ),
      ),
      TextFormField(
        controller: observaciones,
        maxLines: 2,
        decoration: const InputDecoration(labelText: 'Observaciones'),
      ),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.softBlue, borderRadius: BorderRadius.circular(10)),
        child: Row(children: [
          const Text('Total de la entrada', style: TextStyle(fontWeight: FontWeight.w700)),
          const Spacer(),
          Text(bs(total()), style: mono(size: 18, weight: FontWeight.w700)),
        ]),
      ),
    ],
    guardar: () async {
      final ids = filas.map((f) => f.producto).toList();
      if (ids.toSet().length != ids.length) {
        throw const AvisoUsuario('Hay un producto repetido. Junta las cantidades en una sola fila.');
      }
      final id = await supabase.rpc('registrar_entrada', params: {
        'p_proveedor_id': proveedor,
        'p_items': [
          for (final f in filas) {'producto_id': f.producto, 'cantidad': f.cant, 'costo_unitario': f.cost},
        ],
        'p_clave': clave,
        'p_observaciones': textoONull(observaciones.text),
      });
      creada = (id as num).toInt();
    },
  );

  for (final f in filas) {
    f.dispose();
  }
  observaciones.dispose();
  return ok ? creada : null;
}

class _FilaEntrada extends StatelessWidget {
  const _FilaEntrada({super.key, required this.fila, required this.productos, required this.onCambio, this.onQuitar});
  final _Fila fila;
  final List<Map<String, dynamic>> productos;
  final VoidCallback onCambio;
  final VoidCallback? onQuitar;

  @override
  Widget build(BuildContext context) {
    final movil = MediaQuery.sizeOf(context).width < 680;
    final producto = DropdownButtonFormField<int>(
      initialValue: fila.producto,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Producto *'),
      items: [
        for (final p in productos)
          DropdownMenuItem(
            value: p['id'] as int,
            child: Text('${p['codigo']} · ${p['nombre']} (stock ${p['stock_actual']})', overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (v) {
        fila.producto = v;
        onCambio();
      },
      validator: (v) => v == null ? 'Elige un producto.' : null,
    );
    final cantidad = TextFormField(
      controller: fila.cantidad,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(labelText: 'Cantidad *'),
      validator: enteroPositivo,
      onChanged: (_) => onCambio(),
    );
    final costo = TextFormField(
      controller: fila.costo,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: const InputDecoration(labelText: 'Costo unit. (Bs) *'),
      validator: decimalNoNegativo,
      onChanged: (_) => onCambio(),
    );
    final quitar = IconButton(
      tooltip: 'Quitar',
      onPressed: onQuitar,
      icon: const Icon(Icons.delete_outline),
    );

    if (movil) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(10)),
        child: Column(children: [
          producto,
          const SizedBox(height: 12),
          Row(children: [Expanded(child: cantidad), const SizedBox(width: 10), Expanded(child: costo), quitar]),
        ]),
      );
    }
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(flex: 5, child: producto),
      const SizedBox(width: 10),
      Expanded(flex: 2, child: cantidad),
      const SizedBox(width: 10),
      Expanded(flex: 2, child: costo),
      quitar,
    ]);
  }
}

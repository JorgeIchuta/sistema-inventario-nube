import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../core/errores.dart';
import '../../core/formatters.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../shared/widgets/comunes.dart';
import '../../shared/widgets/formulario.dart';
import '../../shared/widgets/tabla.dart';

class _Item {
  _Item(this.producto, this.cantidad);
  final Map<String, dynamic> producto;
  int cantidad;
  int get stock => producto['stock_actual'] as int;
  double get precio => (producto['precio_venta'] as num).toDouble();
  double get subtotal => precio * cantidad;
}

/// Registrar venta: buscar productos, armar el carrito y confirmar.
class VentasPage extends StatefulWidget {
  const VentasPage({super.key});

  @override
  State<VentasPage> createState() => _VentasPageState();
}

class _VentasPageState extends State<VentasPage> {
  final _busqueda = TextEditingController();
  List<Map<String, dynamic>> _productos = [];
  final List<_Item> _carrito = [];
  bool _cargando = true;
  bool _enviando = false;
  String? _error;

  /// Clave de la venta en curso: se reutiliza en los reintentos para no duplicar.
  String _clave = const Uuid().v4();

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final data = await supabase
          .from('productos')
          .select('id, codigo, nombre, precio_venta, stock_actual, stock_minimo')
          .eq('activo', true)
          .order('nombre');
      _productos = data;
      // Actualiza el stock de lo que ya esta en el carrito
      for (final item in _carrito) {
        final p = _productos.where((x) => x['id'] == item.producto['id']);
        if (p.isNotEmpty) item.producto.addAll(p.first);
      }
    } catch (e) {
      _error = mensajeError(e);
    }
    if (mounted) setState(() => _cargando = false);
  }

  List<Map<String, dynamic>> get _resultados {
    final q = _busqueda.text.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return _productos
        .where((p) => '${p['codigo']} ${p['nombre']}'.toLowerCase().contains(q))
        .take(8)
        .toList();
  }

  void _agregar(Map<String, dynamic> p) {
    final stock = p['stock_actual'] as int;
    if (stock <= 0) {
      mostrarMensaje(context, '${p['nombre']} está agotado.', error: true);
      return;
    }
    setState(() {
      final existente = _carrito.where((i) => i.producto['id'] == p['id']);
      if (existente.isNotEmpty) {
        final i = existente.first;
        if (i.cantidad < i.stock) i.cantidad++;
      } else {
        _carrito.add(_Item(Map<String, dynamic>.from(p), 1));
      }
      _busqueda.clear();
    });
  }

  double get _total => _carrito.fold(0, (s, i) => s + i.subtotal);
  int get _unidades => _carrito.fold(0, (s, i) => s + i.cantidad);

  Future<void> _confirmar() async {
    if (_carrito.isEmpty) return;
    final ok = await confirmar(context, 'Confirmar venta',
        '¿Registrar la venta de $_unidades unidad(es) por ${bs(_total)}?', aceptar: 'Confirmar venta');
    if (!ok || !mounted) return;
    setState(() => _enviando = true);
    try {
      final id = await supabase.rpc('registrar_venta', params: {
        'p_items': [
          for (final i in _carrito) {'producto_id': i.producto['id'], 'cantidad': i.cantidad},
        ],
        'p_clave': _clave,
      });
      if (!mounted) return;
      mostrarMensaje(context, 'Venta ${folio('VEN', id as num)} registrada por ${bs(_total)}.');
      setState(() {
        _carrito.clear();
        _clave = const Uuid().v4();
      });
      await _cargar();
    } catch (e) {
      // Se conserva el carrito y la misma clave para poder reintentar.
      if (mounted) mostrarMensaje(context, mensajeError(e), error: true);
      await _cargar();
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Widget _buscador() {
    return Tarjeta(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        CampoBusqueda(
          controller: _busqueda,
          hint: 'Buscar producto o código...',
          onChanged: (_) => setState(() {}),
        ),
        for (final p in _resultados)
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            title: Text(p['nombre'], style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('${p['codigo']} · ${bs(p['precio_venta'] as num)}', style: mono(size: 12, color: AppColors.muted)),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              insigniaStock(p['stock_actual'] as int, p['stock_minimo'] as int),
              const SizedBox(width: 8),
              const Icon(Icons.add_circle, color: AppColors.primary),
            ]),
            onTap: () => _agregar(p),
          ),
        if (_busqueda.text.trim().isNotEmpty && _resultados.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text('No se encontraron productos activos.', style: TextStyle(color: AppColors.muted)),
          ),
        const SizedBox(height: 8),
        if (_carrito.isEmpty)
          const EstadoVacio(mensaje: 'Busca un producto para agregarlo a la venta.', icono: Icons.shopping_cart_outlined)
        else
          for (final i in _carrito) _filaCarrito(i),
      ]),
    );
  }

  Widget _filaCarrito(_Item i) {
    final stock = i.stock;
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(i.producto['nombre'], style: const TextStyle(fontWeight: FontWeight.w700)),
            Text(i.producto['codigo'], style: mono(size: 12, color: AppColors.muted)),
            const SizedBox(height: 4),
            Insignia('En stock: $stock', stock <= (i.producto['stock_minimo'] as int) ? Tono.alerta : Tono.exito),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(bs(i.subtotal), style: mono(weight: FontWeight.w700)),
          const SizedBox(height: 6),
          Row(mainAxisSize: MainAxisSize.min, children: [
            IconButton.filledTonal(
              tooltip: 'Reducir cantidad',
              onPressed: () => setState(() {
                if (i.cantidad > 1) {
                  i.cantidad--;
                } else {
                  _carrito.remove(i);
                }
              }),
              icon: Icon(i.cantidad > 1 ? Icons.remove : Icons.delete_outline, size: 18),
            ),
            SizedBox(width: 34, child: Text('${i.cantidad}', textAlign: TextAlign.center, style: mono(weight: FontWeight.w700))),
            IconButton.filled(
              tooltip: 'Aumentar cantidad',
              onPressed: i.cantidad < stock ? () => setState(() => i.cantidad++) : null,
              icon: const Icon(Icons.add, size: 18),
            ),
          ]),
        ]),
      ]),
    );
  }

  Widget _resumen() {
    Widget linea(String a, String b, {bool fuerte = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(children: [
            Text(a, style: TextStyle(fontWeight: fuerte ? FontWeight.w700 : FontWeight.w400, fontSize: fuerte ? 18 : 15)),
            const Spacer(),
            Text(b, style: mono(size: fuerte ? 18 : 15, weight: fuerte ? FontWeight.w700 : FontWeight.w500)),
          ]),
        );
    return Tarjeta(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('Resumen de venta', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        linea('Productos', '$_unidades'),
        linea('Subtotal', bs(_total)),
        const Divider(),
        linea('Total', bs(_total), fuerte: true),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: _carrito.isEmpty || _enviando ? null : _confirmar,
          icon: _enviando
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.check_circle_outline),
          label: const Text('Confirmar venta'),
        ),
        if (_carrito.isNotEmpty)
          TextButton(
            onPressed: _enviando ? null : () => setState(_carrito.clear),
            child: const Text('Vaciar carrito'),
          ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.sizeOf(context).width;
    final dosColumnas = ancho >= 1100;
    return Pagina(onRefresh: _cargar, children: [
      const PageHeader(titulo: 'Registrar venta', descripcion: 'Selecciona productos y confirma la operación.'),
      if (_cargando && _productos.isEmpty)
        const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
      else if (_error != null && _productos.isEmpty)
        Tarjeta(
          child: EstadoVacio(
            mensaje: _error!,
            icono: Icons.cloud_off,
            accion: OutlinedButton(onPressed: _cargar, child: const Text('Reintentar')),
          ),
        )
      else if (dosColumnas)
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: _buscador()),
          const SizedBox(width: 20),
          SizedBox(width: 340, child: _resumen()),
        ])
      else ...[
        _buscador(),
        const SizedBox(height: 16),
        _resumen(),
      ],
    ]);
  }
}

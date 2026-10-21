import 'package:flutter/material.dart';

import '../../core/errores.dart';
import '../../core/formatters.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../shared/validators.dart';
import '../../shared/widgets/comunes.dart';
import '../../shared/widgets/formulario.dart';
import '../../shared/widgets/tabla.dart';
import 'ajuste.dart';

const _estados = ['En stock', 'Stock bajo', 'Agotado'];

String estadoStock(Map<String, dynamic> p) {
  final s = p['stock_actual'] as int, m = p['stock_minimo'] as int;
  if (s == 0) return 'Agotado';
  if (s <= m) return 'Stock bajo';
  return 'En stock';
}

class ProductosPage extends StatefulWidget {
  const ProductosPage({super.key, this.busquedaInicial});
  final String? busquedaInicial;

  @override
  State<ProductosPage> createState() => _ProductosPageState();
}

class _ProductosPageState extends State<ProductosPage> {
  late final _busqueda = TextEditingController(text: widget.busquedaInicial ?? '');
  late Future<List<Map<String, dynamic>>> _datos = _cargar();
  List<Map<String, dynamic>> _categorias = [];
  int? _filtroCategoria;
  String? _filtroEstado;

  @override
  void didUpdateWidget(ProductosPage old) {
    super.didUpdateWidget(old);
    if (widget.busquedaInicial != old.busquedaInicial) {
      setState(() => _busqueda.text = widget.busquedaInicial ?? '');
    }
  }

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _cargar() async {
    final cats = await supabase.from('categorias').select('id, nombre, activo').order('nombre');
    _categorias = cats;
    final prods = await supabase
        .from('productos')
        .select('id, codigo, nombre, descripcion, categoria_id, precio_venta, stock_actual, stock_minimo, activo, categorias(nombre)')
        .order('nombre');
    return prods;
  }

  Future<void> _refrescar() async {
    final f = _cargar();
    setState(() => _datos = f);
    await f.catchError((_) => <Map<String, dynamic>>[]);
  }

  List<Map<String, dynamic>> _filtrar(List<Map<String, dynamic>> todos) {
    final q = _busqueda.text.trim().toLowerCase();
    return todos.where((p) {
      if (q.isNotEmpty && !'${p['codigo']} ${p['nombre']}'.toLowerCase().contains(q)) return false;
      if (_filtroCategoria != null && p['categoria_id'] != _filtroCategoria) return false;
      if (_filtroEstado != null && (p['activo'] != true || estadoStock(p) != _filtroEstado)) return false;
      return true;
    }).toList();
  }

  Future<void> _formulario([Map<String, dynamic>? p]) async {
    final codigo = TextEditingController(text: p?['codigo'] ?? '');
    final nombre = TextEditingController(text: p?['nombre'] ?? '');
    final precio = TextEditingController(text: p == null ? '' : '${p['precio_venta']}');
    final minimo = TextEditingController(text: p == null ? '' : '${p['stock_minimo']}');
    final descripcion = TextEditingController(text: p?['descripcion'] ?? '');
    int? categoria = p?['categoria_id'] as int?;
    final opciones = _categorias.where((c) => c['activo'] == true || c['id'] == categoria).toList();

    final ok = await abrirFormulario(
      context: context,
      titulo: p == null ? 'Nuevo producto' : 'Editar producto',
      campos: (setLocal) => [
        TextFormField(
          controller: codigo,
          decoration: const InputDecoration(labelText: 'Código *', hintText: 'Ej.: ABA-006'),
          validator: (v) => requerido(v, 'El código'),
        ),
        TextFormField(
          controller: nombre,
          decoration: const InputDecoration(labelText: 'Nombre *'),
          validator: (v) => requerido(v, 'El nombre'),
        ),
        DropdownButtonFormField<int>(
          initialValue: categoria,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Categoría *'),
          items: [for (final c in opciones) DropdownMenuItem(value: c['id'] as int, child: Text(c['nombre']))],
          onChanged: (v) => setLocal(() => categoria = v),
          validator: (v) => v == null ? 'Elige una categoría.' : null,
        ),
        Row(children: [
          Expanded(
            child: TextFormField(
              controller: precio,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Precio de venta (Bs) *'),
              validator: decimalNoNegativo,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: minimo,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Stock mínimo *'),
              validator: enteroNoNegativo,
            ),
          ),
        ]),
        if (p != null)
          InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Stock actual',
              helperText: 'Solo cambia con entradas, ventas o ajustes.',
            ),
            child: Text('${p['stock_actual']}', style: mono()),
          ),
        TextFormField(
          controller: descripcion,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Descripción'),
        ),
      ],
      guardar: () async {
        final datos = {
          'codigo': codigo.text.trim(),
          'nombre': nombre.text.trim(),
          'categoria_id': categoria,
          'precio_venta': leerDecimal(precio.text),
          'stock_minimo': int.parse(minimo.text.trim()),
          'descripcion': textoONull(descripcion.text),
        };
        if (p == null) {
          await supabase.from('productos').insert(datos);
        } else {
          await supabase.from('productos').update(datos).eq('id', p['id']);
        }
      },
    );
    if (ok && mounted) {
      mostrarMensaje(context, p == null ? 'Producto registrado con stock 0. Usa una entrada para cargar existencias.' : 'Producto actualizado.');
      _refrescar();
    }
  }

  Future<void> _cambiarEstado(Map<String, dynamic> p) async {
    final activo = p['activo'] == true;
    if (activo &&
        !await confirmar(context, 'Desactivar producto',
            '¿Desactivar "${p['nombre']}"? Ya no se ofrecerá para nuevas ventas ni entradas.',
            aceptar: 'Desactivar', peligro: true)) {
      return;
    }
    if (!mounted) return;
    final ok = await ejecutar(
      context,
      () => supabase.from('productos').update({'activo': !activo}).eq('id', p['id']),
      activo ? 'Producto desactivado.' : 'Producto activado.',
    );
    if (ok) _refrescar();
  }

  Widget _botonAjuste(Map<String, dynamic> p) => IconButton(
        tooltip: 'Ajustar inventario',
        icon: const Icon(Icons.tune),
        onPressed: () async {
          if (await mostrarAjuste(context, p) && mounted) {
            mostrarMensaje(context, 'Ajuste registrado.');
            _refrescar();
          }
        },
      );

  Widget _estado(Map<String, dynamic> p) => p['activo'] == true
      ? insigniaStock(p['stock_actual'] as int, p['stock_minimo'] as int)
      : const Insignia('Inactivo', Tono.neutro);

  @override
  Widget build(BuildContext context) {
    final admin = SesionApp.instance.esAdmin;
    final movil = MediaQuery.sizeOf(context).width < 680;

    List<Widget> filtros() => [
      SizedBox(
        width: movil ? double.infinity : 320,
        child: CampoBusqueda(
          controller: _busqueda,
          hint: 'Buscar por código o nombre...',
          onChanged: (_) => setState(() {}),
        ),
      ),
      SizedBox(
        width: movil ? double.infinity : 220,
        child: DropdownButtonFormField<int?>(
          initialValue: _filtroCategoria,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Categoría'),
          items: [
            const DropdownMenuItem<int?>(value: null, child: Text('Todas las categorías')),
            for (final c in _categorias) DropdownMenuItem<int?>(value: c['id'] as int, child: Text(c['nombre'])),
          ],
          onChanged: (v) => setState(() => _filtroCategoria = v),
        ),
      ),
      SizedBox(
        width: movil ? double.infinity : 200,
        child: DropdownButtonFormField<String?>(
          initialValue: _filtroEstado,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Estado'),
          items: [
            const DropdownMenuItem<String?>(value: null, child: Text('Todos los estados')),
            for (final e in _estados) DropdownMenuItem<String?>(value: e, child: Text(e)),
          ],
          onChanged: (v) => setState(() => _filtroEstado = v),
        ),
      ),
    ];

    return Pagina(onRefresh: _refrescar, children: [
      PageHeader(
        titulo: 'Productos',
        descripcion: 'Gestiona el catálogo y controla los niveles de inventario.',
        acciones: [
          if (admin)
            FilledButton.icon(
                onPressed: () => _formulario(), icon: const Icon(Icons.add), label: const Text('Agregar producto')),
        ],
      ),
      FutureBuilder<List<Map<String, dynamic>>>(
        future: _datos,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()));
          }
          if (snap.hasError) {
            return Tarjeta(child: EstadoVacio(mensaje: mensajeError(snap.error!), icono: Icons.cloud_off));
          }
          final lista = _filtrar(snap.data!);
          final filas = [
            for (final p in lista)
              FilaTabla(
                celdas: [
                  Text(p['codigo'], style: mono()),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 260),
                    child: Text(p['nombre'], style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  Text(p['categorias']?['nombre'] ?? '—'),
                  Text(bs(p['precio_venta'] as num), style: mono()),
                  Text('${p['stock_actual']}', style: mono()),
                  Text('${p['stock_minimo']}', style: mono()),
                  _estado(p),
                  if (admin)
                    AccionesFila(
                        onEditar: () => _formulario(p), onEstado: () => _cambiarEstado(p), activo: p['activo'] == true, extras: [_botonAjuste(p)]),
                ],
                tarjeta: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  CabeceraTarjeta(titulo: p['nombre'], subtitulo: p['codigo'], insignia: _estado(p)),
                  Text(p['categorias']?['nombre'] ?? '', style: const TextStyle(color: AppColors.muted)),
                  const SizedBox(height: 8),
                  Row(children: [
                    Text(bs(p['precio_venta'] as num), style: mono(size: 15, weight: FontWeight.w700)),
                    const Spacer(),
                    const Text('Existencias: '),
                    Text('${p['stock_actual']}', style: mono(weight: FontWeight.w700)),
                    if (admin)
                      AccionesFila(
                          onEditar: () => _formulario(p), onEstado: () => _cambiarEstado(p), activo: p['activo'] == true, extras: [_botonAjuste(p)]),
                  ]),
                ]),
              ),
          ];
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Wrap(spacing: 12, runSpacing: 12, children: filtros()),
            const SizedBox(height: 18),
            TablaResponsiva(
              columnas: [
                const Columna('Código'), const Columna('Producto'), const Columna('Categoría'),
                const Columna('Precio', numerica: true), const Columna('Stock', numerica: true),
                const Columna('Mín.', numerica: true), const Columna('Estado'),
                if (admin) const Columna('Acciones'),
              ],
              filas: filas,
              mensajeVacio: 'No se encontraron productos.',
            ),
          ]);
        },
      ),
    ]);
  }
}

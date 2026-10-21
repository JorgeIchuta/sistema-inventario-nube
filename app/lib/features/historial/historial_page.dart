import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/errores.dart';
import '../../core/formatters.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../shared/widgets/comunes.dart';
import '../../shared/widgets/tabla.dart';

const _porPagina = 20;

/// Historial de movimientos (kardex). El empleado solo ve los suyos (RLS).
class HistorialPage extends StatefulWidget {
  const HistorialPage({super.key});

  @override
  State<HistorialPage> createState() => _HistorialPageState();
}

class _HistorialPageState extends State<HistorialPage> {
  final List<Map<String, dynamic>> _filas = [];
  String? _tipo;
  DateTimeRange? _rango;
  bool _cargando = false;
  bool _hayMas = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _recargar();
  }

  Future<void> _recargar() async {
    _filas.clear();
    _hayMas = true;
    await _cargarMas();
  }

  Future<void> _cargarMas() async {
    if (_cargando) return;
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      var q = supabase.from('movimientos_inventario').select(
          'id, tipo, cantidad, stock_anterior, stock_resultante, observaciones, creado_en, productos(codigo, nombre), perfiles(nombre)');
      if (_tipo != null) q = q.eq('tipo', _tipo!);
      if (_rango != null) {
        final desde = DateTime(_rango!.start.year, _rango!.start.month, _rango!.start.day);
        final hasta = DateTime(_rango!.end.year, _rango!.end.month, _rango!.end.day).add(const Duration(days: 1));
        q = q.gte('creado_en', desde.toUtc().toIso8601String()).lt('creado_en', hasta.toUtc().toIso8601String());
      }
      final data = await q.order('creado_en', ascending: false).order('id', ascending: false)
          .range(_filas.length, _filas.length + _porPagina - 1);
      _filas.addAll(data);
      _hayMas = data.length == _porPagina;
    } catch (e) {
      _error = mensajeError(e);
    }
    if (mounted) setState(() => _cargando = false);
  }

  Future<void> _elegirRango() async {
    final ahora = DateTime.now();
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(ahora.year - 2),
      lastDate: ahora,
      initialDateRange: _rango,
      helpText: 'Rango de fechas',
    );
    if (r != null) {
      setState(() => _rango = r);
      _recargar();
    }
  }

  /// Cantidad con signo: + entrada, - venta, ajuste segun diferencia.
  int _conSigno(Map<String, dynamic> m) =>
      (m['stock_resultante'] as int) - (m['stock_anterior'] as int);

  Insignia _insigniaTipo(String tipo) => switch (tipo) {
        'entrada' => const Insignia('Entrada', Tono.exito),
        'venta' => const Insignia('Venta', Tono.alerta),
        _ => const Insignia('Ajuste', Tono.peligro),
      };

  @override
  Widget build(BuildContext context) {
    final movil = MediaQuery.sizeOf(context).width < 680;
    final fmt = DateFormat('dd/MM/yyyy');
    final filtros = Wrap(spacing: 12, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
      SizedBox(
        width: movil ? double.infinity : 200,
        child: DropdownButtonFormField<String?>(
          initialValue: _tipo,
          decoration: const InputDecoration(labelText: 'Tipo'),
          items: const [
            DropdownMenuItem<String?>(value: null, child: Text('Todos')),
            DropdownMenuItem<String?>(value: 'entrada', child: Text('Entradas')),
            DropdownMenuItem<String?>(value: 'venta', child: Text('Ventas')),
            DropdownMenuItem<String?>(value: 'ajuste', child: Text('Ajustes')),
          ],
          onChanged: (v) {
            setState(() => _tipo = v);
            _recargar();
          },
        ),
      ),
      OutlinedButton.icon(
        onPressed: _elegirRango,
        icon: const Icon(Icons.date_range),
        label: Text(_rango == null ? 'Todas las fechas' : '${fmt.format(_rango!.start)} – ${fmt.format(_rango!.end)}'),
      ),
      if (_rango != null)
        TextButton(
          onPressed: () {
            setState(() => _rango = null);
            _recargar();
          },
          child: const Text('Quitar fechas'),
        ),
    ]);

    final filas = [
      for (final m in _filas)
        () {
          final n = _conSigno(m);
          final cant = Text(n > 0 ? '+$n' : '$n',
              style: mono(weight: FontWeight.w700, color: n > 0 ? AppColors.success : AppColors.danger));
          final producto = m['productos']?['nombre'] ?? '—';
          final usuario = m['perfiles']?['nombre'] ?? '—';
          return FilaTabla(
            celdas: [
              Text(fechaHora(m['creado_en'])),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 240),
                child: Text(producto, style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
              _insigniaTipo(m['tipo']),
              cant,
              Text('${m['stock_resultante']}', style: mono()),
              Text(usuario),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 200),
                child: Text(m['observaciones'] ?? '', overflow: TextOverflow.ellipsis),
              ),
            ],
            tarjeta: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              CabeceraTarjeta(titulo: producto, subtitulo: m['productos']?['codigo'], insignia: _insigniaTipo(m['tipo'])),
              const SizedBox(height: 6),
              Row(children: [
                Expanded(
                  child: Text('${fechaHora(m['creado_en'])} · $usuario', style: const TextStyle(color: AppColors.muted)),
                ),
                cant,
              ]),
              Text('Stock: ${m['stock_anterior']} → ${m['stock_resultante']}'),
              if (m['observaciones'] != null) Text(m['observaciones'], style: const TextStyle(color: AppColors.muted)),
            ]),
          );
        }(),
    ];

    return Pagina(onRefresh: _recargar, children: [
      PageHeader(
        titulo: 'Historial de movimientos',
        descripcion: SesionApp.instance.esAdmin
            ? 'Auditoría de entradas, ventas y ajustes.'
            : 'Tus ventas registradas.',
      ),
      filtros,
      const SizedBox(height: 18),
      if (_error != null)
        Tarjeta(child: EstadoVacio(mensaje: _error!, icono: Icons.cloud_off))
      else if (_filas.isEmpty && _cargando)
        const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
      else
        TablaResponsiva(
          columnas: const [
            Columna('Fecha'), Columna('Producto'), Columna('Tipo'), Columna('Cantidad', numerica: true),
            Columna('Stock final', numerica: true), Columna('Usuario'), Columna('Observaciones'),
          ],
          filas: filas,
          mensajeVacio: 'No hay movimientos con estos filtros.',
        ),
      if (_filas.isNotEmpty && _hayMas)
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Center(
            child: OutlinedButton(
              onPressed: _cargando ? null : _cargarMas,
              child: Text(_cargando ? 'Cargando...' : 'Cargar más'),
            ),
          ),
        ),
    ]);
  }
}

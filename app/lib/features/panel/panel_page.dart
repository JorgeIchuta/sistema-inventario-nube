import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/errores.dart';
import '../../core/formatters.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../shared/widgets/comunes.dart';

class PanelPage extends StatefulWidget {
  const PanelPage({super.key});

  @override
  State<PanelPage> createState() => _PanelPageState();
}

class _Resumen {
  int productos = 0;
  double ventasHoy = 0;
  int entradasHoy = 0;
  List<Map<String, dynamic>> bajoStock = [];
  List<double> semana = List.filled(7, 0); // del dia -6 al dia de hoy
  List<DateTime> dias = [];
  List<Map<String, dynamic>> movimientos = [];
}

class _PanelPageState extends State<PanelPage> {
  late Future<_Resumen> _datos = _cargar();

  Future<_Resumen> _cargar() async {
    final r = _Resumen();
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    r.dias = [for (var i = 6; i >= 0; i--) hoy.subtract(Duration(days: i))];

    final res = await Future.wait<List<Map<String, dynamic>>>([
      supabase.from('productos').select('id').eq('activo', true),
      // RLS: el empleado solo recibe sus propias ventas
      supabase.from('ventas').select('total, creado_en').gte('creado_en', r.dias.first.toUtc().toIso8601String()),
      supabase.from('productos_bajo_stock').select().order('stock_actual').limit(50),
      supabase
          .from('movimientos_inventario')
          .select('id, tipo, stock_anterior, stock_resultante, creado_en, productos(nombre), perfiles(nombre)')
          .order('creado_en', ascending: false)
          .limit(3),
    ]);
    r.productos = res[0].length;
    for (final v in res[1]) {
      final f = DateTime.parse(v['creado_en']).toLocal();
      final i = r.dias.indexWhere((d) => d.year == f.year && d.month == f.month && d.day == f.day);
      if (i >= 0) r.semana[i] += (v['total'] as num).toDouble();
    }
    r.ventasHoy = r.semana.last;
    r.bajoStock = res[2];
    r.movimientos = res[3];

    if (SesionApp.instance.esAdmin) {
      final entradas = await supabase.from('entradas').select('id').gte('creado_en', hoy.toUtc().toIso8601String());
      r.entradasHoy = entradas.length;
    }
    return r;
  }

  Future<void> _refrescar() async {
    final f = _cargar();
    setState(() => _datos = f);
    await f.catchError((_) => _Resumen());
  }

  @override
  Widget build(BuildContext context) {
    final admin = SesionApp.instance.esAdmin;
    final ancho = MediaQuery.sizeOf(context).width;
    final columnas = ancho >= 1200 ? 4 : (ancho >= 520 ? 2 : 1);

    return Pagina(onRefresh: _refrescar, children: [
      PageHeader(
        titulo: 'Resumen general',
        descripcion: 'Vista rápida del inventario al día de hoy.',
        acciones: [
          if (admin)
            OutlinedButton.icon(
              onPressed: () => context.go('/entradas'),
              icon: const Icon(Icons.add),
              label: const Text('Registrar entrada'),
            ),
          FilledButton.icon(
            onPressed: () => context.go('/ventas'),
            icon: const Icon(Icons.shopping_cart_outlined),
            label: const Text('Registrar venta'),
          ),
        ],
      ),
      FutureBuilder<_Resumen>(
        future: _datos,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()));
          }
          if (snap.hasError) {
            return Tarjeta(
              child: EstadoVacio(
                mensaje: mensajeError(snap.error!),
                icono: Icons.cloud_off,
                accion: OutlinedButton(onPressed: _refrescar, child: const Text('Reintentar')),
              ),
            );
          }
          final r = snap.data!;
          final tarjetas = <Widget>[
            StatCard(icono: Icons.inventory_2_outlined, etiqueta: 'Total de productos', valor: '${r.productos}'),
            StatCard(
                icono: Icons.payments_outlined,
                etiqueta: admin ? 'Ventas del día' : 'Mis ventas del día',
                valor: bs(r.ventasHoy),
                tono: Tono.exito),
            if (admin)
              StatCard(icono: Icons.move_to_inbox_outlined, etiqueta: 'Entradas de hoy', valor: '${r.entradasHoy}'),
            StatCard(
              icono: Icons.warning_amber_outlined,
              etiqueta: 'Bajo stock',
              valor: '${r.bajoStock.length}',
              tono: Tono.peligro,
              extra: r.bajoStock.isNotEmpty ? const Insignia('Atención', Tono.peligro) : null,
            ),
          ];
          final grafico = _VentasSemana(dias: r.dias, valores: r.semana, titulo: admin ? 'Ventas semanales' : 'Mis ventas de la semana');
          final alertas = _Alertas(productos: r.bajoStock.take(3).toList());
          final movimientos = _Movimientos(filas: r.movimientos);

          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            LayoutBuilder(builder: (context, c) {
              const gap = 18.0;
              final w = (c.maxWidth - gap * (columnas - 1)) / columnas;
              return Wrap(spacing: gap, runSpacing: gap, children: [for (final t in tarjetas) SizedBox(width: w, child: t)]);
            }),
            const SizedBox(height: 20),
            if (ancho >= 1100)
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(flex: 2, child: grafico),
                const SizedBox(width: 20),
                Expanded(child: alertas),
              ])
            else ...[
              grafico,
              const SizedBox(height: 20),
              alertas,
            ],
            const SizedBox(height: 20),
            movimientos,
          ]);
        },
      ),
    ]);
  }
}

class _Encabezado extends StatelessWidget {
  const _Encabezado(this.titulo, {this.enlace, this.ruta});
  final String titulo;
  final String? enlace;
  final String? ruta;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: Text(titulo, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
      if (enlace != null) TextButton(onPressed: () => context.go(ruta!), child: Text(enlace!)),
    ]);
  }
}

/// Barras simples de los ultimos 7 dias (el dia de hoy resaltado).
class _VentasSemana extends StatelessWidget {
  const _VentasSemana({required this.dias, required this.valores, required this.titulo});
  final List<DateTime> dias;
  final List<double> valores;
  final String titulo;

  static const _nombres = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

  @override
  Widget build(BuildContext context) {
    final maximo = valores.fold<double>(0, (m, v) => v > m ? v : m);
    return Tarjeta(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _Encabezado(titulo),
        Text('Total: ${bs(valores.fold<double>(0, (s, v) => s + v))}', style: const TextStyle(color: AppColors.muted)),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: Tooltip(
                  message: bs(valores[i]),
                  child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          heightFactor: maximo == 0 ? 0.02 : (valores[i] / maximo).clamp(0.02, 1.0),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: BoxDecoration(
                              color: i == 6 ? AppColors.primary : const Color(0xFF9AAED6),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(_nombres[dias[i].weekday - 1],
                        style: TextStyle(
                            fontSize: 12,
                            color: i == 6 ? AppColors.text : AppColors.muted,
                            fontWeight: i == 6 ? FontWeight.w700 : FontWeight.w400)),
                  ]),
                ),
              ),
          ]),
        ),
      ]),
    );
  }
}

class _Alertas extends StatelessWidget {
  const _Alertas({required this.productos});
  final List<Map<String, dynamic>> productos;

  @override
  Widget build(BuildContext context) {
    return Tarjeta(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const _Encabezado('Alertas de stock', enlace: 'Ver todo', ruta: '/bajo-stock'),
        if (productos.isEmpty)
          const EstadoVacio(mensaje: 'Sin productos en bajo stock.', icono: Icons.check_circle_outline)
        else
          for (final p in productos)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(p['nombre'], style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(p['codigo'], style: mono(size: 12, color: AppColors.muted)),
              trailing: Insignia('${p['stock_actual']} uds.',
                  (p['stock_actual'] as int) == 0 ? Tono.peligro : Tono.alerta),
            ),
      ]),
    );
  }
}

class _Movimientos extends StatelessWidget {
  const _Movimientos({required this.filas});
  final List<Map<String, dynamic>> filas;

  @override
  Widget build(BuildContext context) {
    return Tarjeta(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const _Encabezado('Movimientos recientes', enlace: 'Ver historial', ruta: '/historial'),
        if (filas.isEmpty)
          const EstadoVacio(mensaje: 'Aún no hay movimientos.')
        else
          for (final m in filas)
            () {
              final n = (m['stock_resultante'] as int) - (m['stock_anterior'] as int);
              final (texto, tono, icono) = switch (m['tipo']) {
                'entrada' => ('Entrada', Tono.exito, Icons.move_to_inbox_outlined),
                'venta' => ('Venta', Tono.alerta, Icons.shopping_cart_outlined),
                _ => ('Ajuste', Tono.peligro, Icons.tune),
              };
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(backgroundColor: AppColors.softBlue, child: Icon(icono, color: AppColors.primary, size: 20)),
                title: Text(m['productos']?['nombre'] ?? '—', style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('${fechaHora(m['creado_en'])} · ${m['perfiles']?['nombre'] ?? ''}'),
                trailing: Insignia('$texto ${n > 0 ? '+' : ''}$n', tono),
              );
            }(),
      ]),
    );
  }
}

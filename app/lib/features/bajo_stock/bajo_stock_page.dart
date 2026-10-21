import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/errores.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../shared/widgets/comunes.dart';
import '../../shared/widgets/tabla.dart';

/// Productos activos con stock igual o menor al minimo.
class BajoStockPage extends StatefulWidget {
  const BajoStockPage({super.key});

  @override
  State<BajoStockPage> createState() => _BajoStockPageState();
}

class _BajoStockPageState extends State<BajoStockPage> {
  late Future<List<Map<String, dynamic>>> _datos = _cargar();

  Future<List<Map<String, dynamic>>> _cargar() =>
      supabase.from('productos_bajo_stock').select().order('stock_actual').order('nombre');

  Future<void> _refrescar() async {
    final f = _cargar();
    setState(() => _datos = f);
    await f.catchError((_) => <Map<String, dynamic>>[]);
  }

  @override
  Widget build(BuildContext context) {
    final admin = SesionApp.instance.esAdmin;
    return Pagina(onRefresh: _refrescar, children: [
      const PageHeader(titulo: 'Bajo stock', descripcion: 'Productos que necesitan reposición.'),
      FutureBuilder<List<Map<String, dynamic>>>(
        future: _datos,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()));
          }
          if (snap.hasError) {
            return Tarjeta(child: EstadoVacio(mensaje: mensajeError(snap.error!), icono: Icons.cloud_off));
          }
          Widget accion(Map<String, dynamic> p) => OutlinedButton(
                onPressed: () => context.go('/entradas?producto=${p['id']}'),
                child: const Text('Registrar entrada'),
              );
          final filas = [
            for (final p in snap.data!)
              FilaTabla(
                celdas: [
                  Text(p['nombre'], style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(p['codigo'], style: mono()),
                  Text(p['categoria'] ?? '—'),
                  Text('${p['stock_actual']}', style: mono()),
                  Text('${p['stock_minimo']}', style: mono()),
                  insigniaStock(p['stock_actual'] as int, p['stock_minimo'] as int),
                  if (admin) accion(p),
                ],
                tarjeta: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  CabeceraTarjeta(
                    titulo: p['nombre'],
                    subtitulo: p['codigo'],
                    insignia: insigniaStock(p['stock_actual'] as int, p['stock_minimo'] as int),
                  ),
                  const SizedBox(height: 6),
                  Text('Existencias: ${p['stock_actual']} · Mínimo: ${p['stock_minimo']}'),
                  if (admin) ...[const SizedBox(height: 8), accion(p)],
                ]),
              ),
          ];
          return TablaResponsiva(
            columnas: [
              const Columna('Producto'), const Columna('Código'), const Columna('Categoría'),
              const Columna('Existencias', numerica: true), const Columna('Mínimo', numerica: true),
              const Columna('Estado'), if (admin) const Columna('Acción'),
            ],
            filas: filas,
            mensajeVacio: 'Todos los productos tienen stock suficiente.',
          );
        },
      ),
    ]);
  }
}

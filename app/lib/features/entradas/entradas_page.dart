import 'package:flutter/material.dart';

import '../../core/errores.dart';
import '../../core/formatters.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../shared/widgets/comunes.dart';
import '../../shared/widgets/tabla.dart';
import 'nueva_entrada.dart';

class EntradasPage extends StatefulWidget {
  const EntradasPage({super.key, this.productoInicial});

  /// Si viene de "Bajo stock", abre el formulario con este producto cargado.
  final int? productoInicial;

  @override
  State<EntradasPage> createState() => _EntradasPageState();
}

class _EntradasPageState extends State<EntradasPage> {
  late Future<List<Map<String, dynamic>>> _datos = _cargar();

  @override
  void initState() {
    super.initState();
    if (widget.productoInicial != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _nueva(widget.productoInicial));
    }
  }

  Future<List<Map<String, dynamic>>> _cargar() => supabase
      .from('entradas')
      .select('id, total, creado_en, observaciones, proveedores(nombre), perfiles(nombre), detalle_entradas(cantidad)')
      .order('creado_en', ascending: false)
      .limit(100);

  Future<void> _refrescar() async {
    final f = _cargar();
    setState(() => _datos = f);
    await f.catchError((_) => <Map<String, dynamic>>[]);
  }

  Future<void> _nueva([int? producto]) async {
    final id = await mostrarNuevaEntrada(context, productoInicial: producto);
    if (id != null && mounted) {
      mostrarMensaje(context, 'Entrada ${folio('ENT', id)} registrada. El stock se actualizó.');
      _refrescar();
    }
  }

  int _unidades(Map<String, dynamic> e) =>
      (e['detalle_entradas'] as List? ?? []).fold<int>(0, (s, d) => s + (d['cantidad'] as int));

  @override
  Widget build(BuildContext context) {
    return Pagina(onRefresh: _refrescar, children: [
      PageHeader(
        titulo: 'Entradas de mercadería',
        descripcion: 'Consulta y registra el abastecimiento de productos.',
        acciones: [
          FilledButton.icon(onPressed: () => _nueva(), icon: const Icon(Icons.add), label: const Text('Nueva entrada')),
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
          final filas = [
            for (final e in snap.data!)
              FilaTabla(
                celdas: [
                  Text(folio('ENT', e['id'] as num), style: mono()),
                  Text(e['proveedores']?['nombre'] ?? '—'),
                  Text(fechaHora(e['creado_en'])),
                  Text('${_unidades(e)}', style: mono()),
                  Text(bs(e['total'] as num), style: mono()),
                  Text(e['perfiles']?['nombre'] ?? '—'),
                  const Insignia('Confirmada', Tono.exito),
                ],
                tarjeta: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  CabeceraTarjeta(
                    titulo: e['proveedores']?['nombre'] ?? '—',
                    subtitulo: folio('ENT', e['id'] as num),
                    insignia: const Insignia('Confirmada', Tono.exito),
                  ),
                  const SizedBox(height: 6),
                  Text('${fechaHora(e['creado_en'])} · ${e['perfiles']?['nombre'] ?? ''}',
                      style: const TextStyle(color: AppColors.muted)),
                  const SizedBox(height: 6),
                  Row(children: [
                    Text('${_unidades(e)} unidades'),
                    const Spacer(),
                    Text(bs(e['total'] as num), style: mono(size: 15, weight: FontWeight.w700)),
                  ]),
                ]),
              ),
          ];
          return TablaResponsiva(
            columnas: const [
              Columna('Folio'), Columna('Proveedor'), Columna('Fecha'), Columna('Unidades', numerica: true),
              Columna('Total', numerica: true), Columna('Usuario'), Columna('Estado'),
            ],
            filas: filas,
            mensajeVacio: 'Aún no hay entradas registradas.',
          );
        },
      ),
    ]);
  }
}

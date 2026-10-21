import 'package:flutter/material.dart';

import '../../core/errores.dart';
import '../../core/session.dart';
import '../../shared/validators.dart';
import '../../shared/widgets/comunes.dart';
import '../../shared/widgets/formulario.dart';
import '../../shared/widgets/tabla.dart';

class CategoriasPage extends StatefulWidget {
  const CategoriasPage({super.key});

  @override
  State<CategoriasPage> createState() => _CategoriasPageState();
}

class _CategoriasPageState extends State<CategoriasPage> {
  late Future<List<Map<String, dynamic>>> _datos = _cargar();

  Future<List<Map<String, dynamic>>> _cargar() => supabase
      .from('categorias')
      .select('id, nombre, descripcion, activo, productos(count)')
      .order('nombre');

  Future<void> _refrescar() async {
    final f = _cargar();
    setState(() => _datos = f);
    await f.catchError((_) => <Map<String, dynamic>>[]);
  }

  Future<void> _formulario([Map<String, dynamic>? cat]) async {
    final nombre = TextEditingController(text: cat?['nombre'] ?? '');
    final descripcion = TextEditingController(text: cat?['descripcion'] ?? '');
    final ok = await abrirFormulario(
      context: context,
      titulo: cat == null ? 'Nueva categoría' : 'Editar categoría',
      campos: (_) => [
        TextFormField(
          controller: nombre,
          decoration: const InputDecoration(labelText: 'Nombre *'),
          validator: (v) => requerido(v, 'El nombre'),
        ),
        TextFormField(
          controller: descripcion,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Descripción'),
        ),
      ],
      guardar: () async {
        final datos = {'nombre': nombre.text.trim(), 'descripcion': textoONull(descripcion.text)};
        if (cat == null) {
          await supabase.from('categorias').insert(datos);
        } else {
          await supabase.from('categorias').update(datos).eq('id', cat['id']);
        }
      },
    );
    if (ok && mounted) {
      mostrarMensaje(context, 'Categoría guardada.');
      _refrescar();
    }
  }

  Future<void> _cambiarEstado(Map<String, dynamic> cat) async {
    final activo = cat['activo'] == true;
    if (activo &&
        !await confirmar(context, 'Desactivar categoría',
            '¿Desactivar "${cat['nombre']}"? No se podrá elegir para productos nuevos.',
            aceptar: 'Desactivar', peligro: true)) {
      return;
    }
    if (!mounted) return;
    final ok = await ejecutar(
      context,
      () => supabase.from('categorias').update({'activo': !activo}).eq('id', cat['id']),
      activo ? 'Categoría desactivada.' : 'Categoría activada.',
    );
    if (ok) _refrescar();
  }

  int _conteo(Map<String, dynamic> c) {
    final p = c['productos'];
    if (p is List && p.isNotEmpty) return (p.first['count'] as num?)?.toInt() ?? 0;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Pagina(onRefresh: _refrescar, children: [
      PageHeader(
        titulo: 'Categorías',
        descripcion: 'Organiza los productos del inventario.',
        acciones: [
          FilledButton.icon(onPressed: () => _formulario(), icon: const Icon(Icons.add), label: const Text('Agregar')),
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
            for (final c in snap.data!)
              FilaTabla(
                celdas: [
                  Text(c['nombre'], style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(c['descripcion'] ?? '—'),
                  Text('${_conteo(c)}'),
                  insigniaActivo(c['activo'] == true),
                  AccionesFila(onEditar: () => _formulario(c), onEstado: () => _cambiarEstado(c), activo: c['activo'] == true),
                ],
                tarjeta: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  CabeceraTarjeta(titulo: c['nombre'], insignia: insigniaActivo(c['activo'] == true)),
                  if (c['descripcion'] != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(c['descripcion'])),
                  const SizedBox(height: 6),
                  Row(children: [
                    Text('Productos: ${_conteo(c)}'),
                    const Spacer(),
                    AccionesFila(onEditar: () => _formulario(c), onEstado: () => _cambiarEstado(c), activo: c['activo'] == true),
                  ]),
                ]),
              ),
          ];
          return TablaResponsiva(
            columnas: const [
              Columna('Nombre'), Columna('Descripción'), Columna('Productos', numerica: true),
              Columna('Estado'), Columna('Acciones'),
            ],
            filas: filas,
            mensajeVacio: 'Aún no hay categorías.',
          );
        },
      ),
    ]);
  }
}

import 'package:flutter/material.dart';

import '../../core/errores.dart';
import '../../core/session.dart';
import '../../shared/validators.dart';
import '../../shared/widgets/comunes.dart';
import '../../shared/widgets/formulario.dart';
import '../../shared/widgets/tabla.dart';

class ProveedoresPage extends StatefulWidget {
  const ProveedoresPage({super.key});

  @override
  State<ProveedoresPage> createState() => _ProveedoresPageState();
}

class _ProveedoresPageState extends State<ProveedoresPage> {
  late Future<List<Map<String, dynamic>>> _datos = _cargar();

  Future<List<Map<String, dynamic>>> _cargar() => supabase
      .from('proveedores')
      .select('id, nombre, telefono, correo, direccion, activo')
      .order('nombre');

  Future<void> _refrescar() async {
    final f = _cargar();
    setState(() => _datos = f);
    await f.catchError((_) => <Map<String, dynamic>>[]);
  }

  Future<void> _formulario([Map<String, dynamic>? p]) async {
    final nombre = TextEditingController(text: p?['nombre'] ?? '');
    final telefono = TextEditingController(text: p?['telefono'] ?? '');
    final correo = TextEditingController(text: p?['correo'] ?? '');
    final direccion = TextEditingController(text: p?['direccion'] ?? '');
    final ok = await abrirFormulario(
      context: context,
      titulo: p == null ? 'Nuevo proveedor' : 'Editar proveedor',
      campos: (_) => [
        TextFormField(
          controller: nombre,
          decoration: const InputDecoration(labelText: 'Nombre *'),
          validator: (v) => requerido(v, 'El nombre'),
        ),
        TextFormField(
          controller: telefono,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'Teléfono'),
        ),
        TextFormField(
          controller: correo,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Correo'),
          validator: correoOpcional,
        ),
        TextFormField(
          controller: direccion,
          maxLines: 2,
          decoration: const InputDecoration(labelText: 'Dirección'),
        ),
      ],
      guardar: () async {
        final datos = {
          'nombre': nombre.text.trim(),
          'telefono': textoONull(telefono.text),
          'correo': textoONull(correo.text),
          'direccion': textoONull(direccion.text),
        };
        if (p == null) {
          await supabase.from('proveedores').insert(datos);
        } else {
          await supabase.from('proveedores').update(datos).eq('id', p['id']);
        }
      },
    );
    if (ok && mounted) {
      mostrarMensaje(context, 'Proveedor guardado.');
      _refrescar();
    }
  }

  Future<void> _cambiarEstado(Map<String, dynamic> p) async {
    final activo = p['activo'] == true;
    if (activo &&
        !await confirmar(context, 'Desactivar proveedor',
            '¿Desactivar "${p['nombre']}"? No se podrá elegir en nuevas entradas.',
            aceptar: 'Desactivar', peligro: true)) {
      return;
    }
    if (!mounted) return;
    final ok = await ejecutar(
      context,
      () => supabase.from('proveedores').update({'activo': !activo}).eq('id', p['id']),
      activo ? 'Proveedor desactivado.' : 'Proveedor activado.',
    );
    if (ok) _refrescar();
  }

  @override
  Widget build(BuildContext context) {
    return Pagina(onRefresh: _refrescar, children: [
      PageHeader(
        titulo: 'Proveedores',
        descripcion: 'Administra los datos de contacto de tus proveedores.',
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
            for (final p in snap.data!)
              FilaTabla(
                celdas: [
                  Text(p['nombre'], style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(p['telefono'] ?? '—'),
                  Text(p['correo'] ?? '—'),
                  insigniaActivo(p['activo'] == true),
                  AccionesFila(onEditar: () => _formulario(p), onEstado: () => _cambiarEstado(p), activo: p['activo'] == true),
                ],
                tarjeta: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  CabeceraTarjeta(titulo: p['nombre'], insignia: insigniaActivo(p['activo'] == true)),
                  const SizedBox(height: 6),
                  if (p['telefono'] != null) Text('Tel.: ${p['telefono']}'),
                  if (p['correo'] != null) Text(p['correo']),
                  Align(
                    alignment: Alignment.centerRight,
                    child: AccionesFila(onEditar: () => _formulario(p), onEstado: () => _cambiarEstado(p), activo: p['activo'] == true),
                  ),
                ]),
              ),
          ];
          return TablaResponsiva(
            columnas: const [Columna('Nombre'), Columna('Teléfono'), Columna('Correo'), Columna('Estado'), Columna('Acciones')],
            filas: filas,
            mensajeVacio: 'Aún no hay proveedores.',
          );
        },
      ),
    ]);
  }
}

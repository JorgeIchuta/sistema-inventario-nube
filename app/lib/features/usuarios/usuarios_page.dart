import 'package:flutter/material.dart';

import '../../core/errores.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../shared/validators.dart';
import '../../shared/widgets/comunes.dart';
import '../../shared/widgets/formulario.dart';
import '../../shared/widgets/tabla.dart';

/// Gestion de roles y estado de las cuentas (solo administrador).
class UsuariosPage extends StatefulWidget {
  const UsuariosPage({super.key});

  @override
  State<UsuariosPage> createState() => _UsuariosPageState();
}

class _UsuariosPageState extends State<UsuariosPage> {
  late Future<List<Map<String, dynamic>>> _datos = _cargar();

  Future<List<Map<String, dynamic>>> _cargar() =>
      supabase.from('perfiles').select('id, nombre, rol, activo, creado_en').order('nombre');

  Future<void> _refrescar() async {
    final f = _cargar();
    setState(() => _datos = f);
    await f.catchError((_) => <Map<String, dynamic>>[]);
  }

  bool _esYo(Map<String, dynamic> u) => u['id'] == supabase.auth.currentUser?.id;

  Future<void> _editar(Map<String, dynamic> u) async {
    final nombre = TextEditingController(text: u['nombre']);
    String rol = u['rol'];
    final ok = await abrirFormulario(
      context: context,
      titulo: 'Editar usuario',
      campos: (setLocal) => [
        TextFormField(
          controller: nombre,
          decoration: const InputDecoration(labelText: 'Nombre *'),
          validator: (v) => requerido(v, 'El nombre'),
        ),
        DropdownButtonFormField<String>(
          initialValue: rol,
          decoration: InputDecoration(
            labelText: 'Rol *',
            helperText: _esYo(u) ? 'No puedes cambiar tu propio rol.' : null,
          ),
          items: const [
            DropdownMenuItem(value: 'administrador', child: Text('Administrador')),
            DropdownMenuItem(value: 'empleado', child: Text('Empleado')),
          ],
          onChanged: _esYo(u) ? null : (v) => setLocal(() => rol = v ?? rol),
        ),
      ],
      guardar: () => supabase
          .from('perfiles')
          .update({'nombre': nombre.text.trim(), 'rol': rol})
          .eq('id', u['id']),
    );
    nombre.dispose();
    if (ok && mounted) {
      mostrarMensaje(context, 'Usuario actualizado.');
      if (_esYo(u)) await SesionApp.instance.cargarPerfil();
      _refrescar();
    }
  }

  Future<void> _cambiarEstado(Map<String, dynamic> u) async {
    if (_esYo(u)) {
      mostrarMensaje(context, 'No puedes desactivar tu propia cuenta.', error: true);
      return;
    }
    final activo = u['activo'] == true;
    if (activo &&
        !await confirmar(context, 'Desactivar usuario',
            '¿Desactivar a "${u['nombre']}"? No podrá ingresar ni consultar datos.',
            aceptar: 'Desactivar', peligro: true)) {
      return;
    }
    if (!mounted) return;
    final ok = await ejecutar(
      context,
      () => supabase.from('perfiles').update({'activo': !activo}).eq('id', u['id']),
      activo ? 'Usuario desactivado.' : 'Usuario activado.',
    );
    if (ok) _refrescar();
  }

  @override
  Widget build(BuildContext context) {
    return Pagina(onRefresh: _refrescar, children: [
      const PageHeader(titulo: 'Usuarios', descripcion: 'Controla las cuentas y permisos del sistema.'),
      Container(
        margin: const EdgeInsets.only(bottom: 18),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.softBlue, borderRadius: BorderRadius.circular(12)),
        child: const Row(children: [
          Icon(Icons.info_outline, color: AppColors.primary),
          SizedBox(width: 10),
          Expanded(
            child: Text('Para crear una cuenta nueva, agrégala en Supabase → Authentication → Users. '
                'Aparecerá aquí como Empleado y podrás cambiar su rol.'),
          ),
        ]),
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
          Widget rol(Map<String, dynamic> u) => u['rol'] == 'administrador'
              ? const Insignia('Administrador', Tono.neutro)
              : const Insignia('Empleado', Tono.exito);
          final filas = [
            for (final u in snap.data!)
              FilaTabla(
                celdas: [
                  Text(_esYo(u) ? '${u['nombre']} (tú)' : u['nombre'], style: const TextStyle(fontWeight: FontWeight.w700)),
                  rol(u),
                  insigniaActivo(u['activo'] == true),
                  AccionesFila(onEditar: () => _editar(u), onEstado: () => _cambiarEstado(u), activo: u['activo'] == true),
                ],
                tarjeta: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  CabeceraTarjeta(titulo: _esYo(u) ? '${u['nombre']} (tú)' : u['nombre'], insignia: insigniaActivo(u['activo'] == true)),
                  const SizedBox(height: 6),
                  Row(children: [
                    rol(u),
                    const Spacer(),
                    AccionesFila(onEditar: () => _editar(u), onEstado: () => _cambiarEstado(u), activo: u['activo'] == true),
                  ]),
                ]),
              ),
          ];
          return TablaResponsiva(
            columnas: const [Columna('Nombre'), Columna('Rol'), Columna('Estado'), Columna('Acciones')],
            filas: filas,
          );
        },
      ),
    ]);
  }
}

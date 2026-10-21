import 'package:flutter/material.dart';

import '../../core/theme.dart';
import 'comunes.dart';

class Columna {
  const Columna(this.titulo, {this.numerica = false});
  final String titulo;
  final bool numerica;
}

class FilaTabla {
  const FilaTabla({required this.celdas, required this.tarjeta});
  final List<Widget> celdas; // vista de escritorio
  final Widget tarjeta; // vista movil
}

/// Tabla en escritorio y lista de tarjetas en movil (< 680 px).
class TablaResponsiva extends StatelessWidget {
  const TablaResponsiva({super.key, required this.columnas, required this.filas,
      this.mensajeVacio = 'No hay registros.'});
  final List<Columna> columnas;
  final List<FilaTabla> filas;
  final String mensajeVacio;

  @override
  Widget build(BuildContext context) {
    if (filas.isEmpty) return Tarjeta(child: EstadoVacio(mensaje: mensajeVacio));
    final movil = MediaQuery.sizeOf(context).width < 680;
    if (movil) {
      return Column(children: [
        for (final f in filas)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Tarjeta(padding: const EdgeInsets.all(15), child: f.tarjeta),
          ),
      ]);
    }
    return Tarjeta(
      padding: EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (context, c) => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: c.maxWidth),
            child: DataTable(
              headingRowColor: const WidgetStatePropertyAll(AppColors.surface),
              headingTextStyle: const TextStyle(
                  fontWeight: FontWeight.w700, color: AppColors.muted, fontSize: 13),
              dataRowMinHeight: 56,
              dataRowMaxHeight: 68,
              columns: [
                for (final col in columnas) DataColumn(label: Text(col.titulo), numeric: col.numerica),
              ],
              rows: [
                for (final f in filas) DataRow(cells: [for (final c in f.celdas) DataCell(c)]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Cabecera comun de las tarjetas moviles: titulo, subtitulo e insignia.
class CabeceraTarjeta extends StatelessWidget {
  const CabeceraTarjeta({super.key, required this.titulo, this.subtitulo, this.insignia, this.acciones});
  final String titulo;
  final String? subtitulo;
  final Widget? insignia;
  final Widget? acciones;

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (subtitulo != null) Text(subtitulo!, style: mono(size: 12, color: AppColors.muted)),
          Text(titulo, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        ]),
      ),
      if (insignia != null) insignia!,
      if (acciones != null) acciones!,
    ]);
  }
}

/// Campo de busqueda en forma de pildora.
class CampoBusqueda extends StatelessWidget {
  const CampoBusqueda({super.key, required this.controller, required this.hint, required this.onChanged});
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final borde = OutlineInputBorder(
        borderRadius: BorderRadius.circular(999), borderSide: const BorderSide(color: AppColors.border));
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search),
        border: borde,
        enabledBorder: borde,
      ),
    );
  }
}

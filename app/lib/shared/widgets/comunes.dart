import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// Tarjeta blanca con borde y sombra suave (estilo .card del prototipo).
class Tarjeta extends StatelessWidget {
  const Tarjeta({super.key, required this.child, this.padding = const EdgeInsets.all(20)});
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 24, offset: Offset(0, 8))],
      ),
      child: child,
    );
  }
}

/// Titulo de pagina con descripcion y acciones a la derecha (abajo en movil).
class PageHeader extends StatelessWidget {
  const PageHeader({super.key, required this.titulo, required this.descripcion, this.acciones = const []});
  final String titulo;
  final String descripcion;
  final List<Widget> acciones;

  @override
  Widget build(BuildContext context) {
    final movil = MediaQuery.sizeOf(context).width < 680;
    final textos = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo,
            style: TextStyle(fontSize: movil ? 26 : 32, fontWeight: FontWeight.w700, height: 1.15)),
        const SizedBox(height: 4),
        Text(descripcion, style: const TextStyle(color: AppColors.muted)),
      ],
    );
    final botones = Wrap(spacing: 10, runSpacing: 10, children: acciones);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: movil || acciones.isEmpty
          ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              textos,
              if (acciones.isNotEmpty) ...[const SizedBox(height: 16), botones],
            ])
          : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: textos),
              botones,
            ]),
    );
  }
}

enum Tono { exito, alerta, peligro, neutro }

/// Insignia en forma de pildora ("En stock", "Stock bajo", "Agotado"...).
class Insignia extends StatelessWidget {
  const Insignia(this.texto, this.tono, {super.key});
  final String texto;
  final Tono tono;

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = switch (tono) {
      Tono.exito => (AppColors.success, AppColors.successBg),
      Tono.alerta => (AppColors.warning, AppColors.warningBg),
      Tono.peligro => (AppColors.danger, AppColors.dangerBg),
      Tono.neutro => (AppColors.primary, AppColors.softBlue),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(texto, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}

/// Estado del stock segun la regla del sistema.
Insignia insigniaStock(int stock, int minimo) {
  if (stock == 0) return const Insignia('Agotado', Tono.peligro);
  if (stock <= minimo) return const Insignia('Stock bajo', Tono.alerta);
  return const Insignia('En stock', Tono.exito);
}

/// Tarjeta de estadistica del panel.
class StatCard extends StatelessWidget {
  const StatCard({super.key, required this.icono, required this.etiqueta, required this.valor,
      this.tono = Tono.neutro, this.extra});
  final IconData icono;
  final String etiqueta;
  final String valor;
  final Tono tono;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = switch (tono) {
      Tono.exito => (AppColors.success, AppColors.successBg),
      Tono.peligro || Tono.alerta => (AppColors.danger, AppColors.dangerBg),
      Tono.neutro => (AppColors.primary, AppColors.softBlue),
    };
    return Tarjeta(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 43, height: 43,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(11)),
            child: Icon(icono, color: fg, size: 22),
          ),
          const Spacer(),
          if (extra != null) extra!,
        ]),
        const SizedBox(height: 16),
        Text(etiqueta, style: const TextStyle(color: AppColors.muted)),
        const SizedBox(height: 2),
        Text(valor, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

/// Mensaje centrado para listas vacias o errores.
class EstadoVacio extends StatelessWidget {
  const EstadoVacio({super.key, required this.mensaje, this.icono = Icons.inbox_outlined, this.accion});
  final String mensaje;
  final IconData icono;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icono, size: 40, color: AppColors.muted),
        const SizedBox(height: 12),
        Text(mensaje, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted)),
        if (accion != null) ...[const SizedBox(height: 16), accion!],
      ]),
    );
  }
}

/// Contenedor de pagina con margenes y ancho maximo del prototipo.
class Pagina extends StatelessWidget {
  const Pagina({super.key, required this.children, this.onRefresh});
  final List<Widget> children;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final movil = MediaQuery.sizeOf(context).width < 680;
    final lista = ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(movil ? 16 : 30),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1320),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
          ),
        ),
      ],
    );
    return onRefresh == null ? lista : RefreshIndicator(onRefresh: onRefresh!, child: lista);
  }
}

/// Pantalla temporal para modulos de fases siguientes.
class PendientePage extends StatelessWidget {
  const PendientePage({super.key, required this.titulo});
  final String titulo;

  @override
  Widget build(BuildContext context) {
    return Pagina(children: [
      PageHeader(titulo: titulo, descripcion: 'Módulo en construcción.'),
      const Tarjeta(child: EstadoVacio(
          mensaje: 'Este módulo se implementa en las siguientes fases.', icono: Icons.construction)),
    ]);
  }
}

void mostrarMensaje(BuildContext context, String texto, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(texto),
      backgroundColor: error ? AppColors.danger : AppColors.text,
    ));
}

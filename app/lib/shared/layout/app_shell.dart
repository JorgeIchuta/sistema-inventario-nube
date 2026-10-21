import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router.dart';
import '../../core/session.dart';
import '../../core/theme.dart';

/// Estructura principal: sidebar fijo (>= 980 px), menu desplegable
/// (680-979 px) o barra inferior (< 680 px), como en diseno/template.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.ruta, required this.child});
  final String ruta;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.sizeOf(context).width;
    final session = SesionApp.instance;
    final items = menuPara(session);

    if (ancho >= 980) {
      return Scaffold(
        body: Row(children: [
          SizedBox(width: 264, child: _Sidebar(ruta: ruta, items: items)),
          const VerticalDivider(width: 1, color: AppColors.border),
          Expanded(child: Column(children: [_TopBar(movil: false, conMenu: false), Expanded(child: child)])),
        ]),
      );
    }

    final movil = ancho < 680;
    const inferiores = ['/panel', '/productos', '/ventas'];
    final indice = inferiores.indexOf(ruta);
    return Scaffold(
      drawer: Drawer(
        width: 280,
        backgroundColor: AppColors.card,
        child: _Sidebar(ruta: ruta, items: items, enDrawer: true),
      ),
      body: Column(children: [_TopBar(movil: movil, conMenu: !movil), Expanded(child: child)]),
      bottomNavigationBar: !movil
          ? null
          : Builder(
              builder: (ctx) => NavigationBar(
                height: 68,
                backgroundColor: AppColors.card,
                indicatorColor: AppColors.softBlue,
                selectedIndex: indice < 0 ? 3 : indice,
                onDestinationSelected: (i) {
                  if (i == 3) {
                    Scaffold.of(ctx).openDrawer();
                  } else {
                    context.go(inferiores[i]);
                  }
                },
                destinations: const [
                  NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Panel'),
                  NavigationDestination(icon: Icon(Icons.inventory_2_outlined), label: 'Productos'),
                  NavigationDestination(icon: Icon(Icons.shopping_cart_outlined), label: 'Ventas'),
                  NavigationDestination(icon: Icon(Icons.menu), label: 'Más'),
                ],
              ),
            ),
    );
  }
}

class _Marca extends StatelessWidget {
  const _Marca();

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.asset('assets/images/logo.png', width: 40, height: 40, fit: BoxFit.cover),
      ),
      const SizedBox(width: 10),
      const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Inventario',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primaryDark, height: 1)),
        Text('Cloud',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.brandCyan)),
      ]),
    ]);
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.ruta, required this.items, this.enDrawer = false});
  final String ruta;
  final List<OpcionMenu> items;
  final bool enDrawer;

  @override
  Widget build(BuildContext context) {
    final session = SesionApp.instance;
    return Container(
      color: AppColors.card,
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 16),
      child: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Padding(padding: EdgeInsets.fromLTRB(10, 0, 10, 24), child: _Marca()),
          Expanded(
            child: ListView(children: [
              for (final m in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: _ItemMenu(
                    item: m,
                    activo: ruta == m.ruta,
                    onTap: () {
                      final router = GoRouter.of(context);
                      if (enDrawer) Navigator.of(context).pop();
                      router.go(m.ruta);
                    },
                  ),
                ),
            ]),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.softBlue, borderRadius: BorderRadius.circular(13)),
            child: Row(children: [
              _Avatar(texto: session.iniciales),
              const SizedBox(width: 11),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(session.nombre,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  Text(session.rolTexto, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                ]),
              ),
              IconButton(
                tooltip: 'Cerrar sesión',
                icon: const Icon(Icons.logout, size: 20),
                onPressed: () => session.cerrarSesion(),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _ItemMenu extends StatelessWidget {
  const _ItemMenu({required this.item, required this.activo, required this.onTap});
  final OpcionMenu item;
  final bool activo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = activo ? Colors.white : const Color(0xFF485366);
    return Material(
      color: activo ? AppColors.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        hoverColor: AppColors.softBlue,
        onTap: onTap,
        child: SizedBox(
          height: 46,
          child: Row(children: [
            const SizedBox(width: 14),
            Icon(item.icono, color: color, size: 21),
            const SizedBox(width: 13),
            Text(item.titulo, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.texto});
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38, height: 38,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: [Color(0xFF22B4C8), AppColors.primary]),
      ),
      child: Text(texto, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
    );
  }
}

/// Barra superior con buscador global (lleva a Productos) y menu de usuario.
class _TopBar extends StatefulWidget {
  const _TopBar({required this.movil, required this.conMenu});
  final bool movil;
  final bool conMenu;

  @override
  State<_TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<_TopBar> {
  final _busqueda = TextEditingController();

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  void _buscar(String texto) {
    final q = texto.trim();
    context.go(q.isEmpty ? '/productos' : '/productos?q=${Uri.encodeQueryComponent(q)}');
  }

  @override
  Widget build(BuildContext context) {
    final session = SesionApp.instance;
    return Container(
      height: 68,
      padding: EdgeInsets.symmetric(horizontal: widget.movil ? 12 : 28),
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(children: [
          if (widget.conMenu)
            IconButton(
              tooltip: 'Abrir menú',
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          if (widget.movil) const _Marca(),
          if (!widget.movil)
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: TextField(
                controller: _busqueda,
                textInputAction: TextInputAction.search,
                onSubmitted: _buscar,
                decoration: InputDecoration(
                  hintText: 'Buscar productos...',
                  prefixIcon: const Icon(Icons.search),
                  fillColor: AppColors.softBlue,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(999), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(999), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(999),
                      borderSide: const BorderSide(color: AppColors.secondary, width: 2)),
                ),
              ),
            ),
          const Spacer(),
          PopupMenuButton<String>(
            tooltip: 'Perfil de usuario',
            onSelected: (v) {
              if (v == 'salir') session.cerrarSesion();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                enabled: false,
                child: Text('${session.nombre}\n${session.correo}',
                    style: const TextStyle(color: AppColors.muted, fontSize: 13)),
              ),
              const PopupMenuItem(value: 'salir', child: Text('Cerrar sesión')),
            ],
            child: _Avatar(texto: session.iniciales),
          ),
        ]),
      ),
    );
  }
}

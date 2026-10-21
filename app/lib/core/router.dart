import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/login_page.dart';
import '../features/auth/restablecer_page.dart';
import '../features/bajo_stock/bajo_stock_page.dart';
import '../features/categorias/categorias_page.dart';
import '../features/entradas/entradas_page.dart';
import '../features/panel/panel_page.dart';
import '../features/productos/productos_page.dart';
import '../features/historial/historial_page.dart';
import '../features/proveedores/proveedores_page.dart';
import '../features/usuarios/usuarios_page.dart';
import '../features/ventas/ventas_page.dart';
import '../shared/layout/app_shell.dart';
import '../shared/widgets/comunes.dart';
import 'session.dart';

/// Elemento del menu principal (seccion 3.5 del plan).
class OpcionMenu {
  const OpcionMenu(this.ruta, this.titulo, this.icono, {this.soloAdmin = false});
  final String ruta;
  final String titulo;
  final IconData icono;
  final bool soloAdmin;
}

const menu = <OpcionMenu>[
  OpcionMenu('/panel', 'Panel', Icons.dashboard_outlined),
  OpcionMenu('/productos', 'Productos', Icons.inventory_2_outlined),
  OpcionMenu('/categorias', 'Categorías', Icons.category_outlined, soloAdmin: true),
  OpcionMenu('/proveedores', 'Proveedores', Icons.local_shipping_outlined, soloAdmin: true),
  OpcionMenu('/entradas', 'Entradas', Icons.move_to_inbox_outlined, soloAdmin: true),
  OpcionMenu('/ventas', 'Ventas', Icons.shopping_cart_outlined),
  OpcionMenu('/bajo-stock', 'Bajo stock', Icons.warning_amber_outlined),
  OpcionMenu('/historial', 'Historial', Icons.history),
  OpcionMenu('/usuarios', 'Usuarios', Icons.group_outlined, soloAdmin: true),
];

List<OpcionMenu> menuPara(SesionApp s) => menu.where((m) => !m.soloAdmin || s.esAdmin).toList();

/// Pantallas de cada ruta. Las que aun no se implementan muestran un aviso.
Widget _pantalla(String ruta, GoRouterState state) {
  switch (ruta) {
    case '/panel':
      return const PanelPage();
    case '/productos':
      return ProductosPage(busquedaInicial: state.uri.queryParameters['q']);
    case '/categorias':
      return const CategoriasPage();
    case '/proveedores':
      return const ProveedoresPage();
    case '/entradas':
      return EntradasPage(productoInicial: int.tryParse(state.uri.queryParameters['producto'] ?? ''));
    case '/ventas':
      return const VentasPage();
    case '/bajo-stock':
      return const BajoStockPage();
    case '/historial':
      return const HistorialPage();
    case '/usuarios':
      return const UsuariosPage();
    default:
      final item = menu.firstWhere((m) => m.ruta == ruta);
      return PendientePage(titulo: item.titulo);
  }
}

GoRouter crearRouter(SesionApp session) {
  return GoRouter(
    initialLocation: '/panel',
    refreshListenable: session,
    redirect: (context, state) {
      final ruta = state.matchedLocation;
      if (session.recuperandoClave) return ruta == '/restablecer' ? null : '/restablecer';
      if (!session.conectado) return ruta == '/login' ? null : '/login';
      if (ruta == '/login' || ruta == '/restablecer') return '/panel';
      final item = menu.where((m) => m.ruta == ruta);
      if (item.isNotEmpty && item.first.soloAdmin && !session.esAdmin) return '/panel';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/restablecer', builder: (_, __) => const RestablecerPage()),
      ShellRoute(
        builder: (context, state, child) => AppShell(ruta: state.matchedLocation, child: child),
        routes: [
          for (final m in menu)
            GoRoute(
              path: m.ruta,
              pageBuilder: (context, state) =>
                  NoTransitionPage(key: state.pageKey, child: _pantalla(m.ruta, state)),
            ),
        ],
      ),
    ],
  );
}

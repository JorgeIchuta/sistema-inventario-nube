import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config.dart';
import 'core/router.dart';
import 'core/session.dart';
import 'core/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Intl.defaultLocale = 'es';
  await initializeDateFormatting('es');

  if (!Config.valida) {
    runApp(const _FaltaConfiguracion());
    return;
  }

  await Supabase.initialize(url: Config.supabaseUrl, anonKey: Config.supabaseAnonKey);
  await SesionApp.instance.iniciar();
  runApp(InventarioApp(router: crearRouter(SesionApp.instance)));
}

class InventarioApp extends StatelessWidget {
  const InventarioApp({super.key, required this.router});
  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Inventario Cloud',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      routerConfig: router,
      locale: const Locale('es'),
      supportedLocales: const [Locale('es')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}

/// Se muestra si se ejecuto sin --dart-define de Supabase.
class _FaltaConfiguracion extends StatelessWidget {
  const _FaltaConfiguracion();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Falta la configuración de Supabase.\n'
              'Ejecuta: flutter run --dart-define-from-file=dart_defines.json',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

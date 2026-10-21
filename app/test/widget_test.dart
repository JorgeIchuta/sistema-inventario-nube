// Pruebas unitarias de Inventario Cloud (flutter test).
// Reemplaza al archivo de ejemplo que genera "flutter create".
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:inventario_cloud/core/errores.dart';
import 'package:inventario_cloud/core/formatters.dart';
import 'package:inventario_cloud/features/productos/productos_page.dart' show estadoStock;
import 'package:inventario_cloud/shared/validators.dart';
import 'package:inventario_cloud/shared/widgets/comunes.dart';

void main() {
  setUpAll(() async => initializeDateFormatting('es'));

  group('Regla de estado del stock', () {
    test('stock 0 es Agotado', () {
      expect(estadoStock({'stock_actual': 0, 'stock_minimo': 5}), 'Agotado');
    });
    test('stock igual al mínimo es Stock bajo (CP-09)', () {
      expect(estadoStock({'stock_actual': 5, 'stock_minimo': 5}), 'Stock bajo');
    });
    test('stock menor al mínimo es Stock bajo', () {
      expect(estadoStock({'stock_actual': 3, 'stock_minimo': 5}), 'Stock bajo');
    });
    test('stock mayor al mínimo es En stock', () {
      expect(estadoStock({'stock_actual': 6, 'stock_minimo': 5}), 'En stock');
    });
    test('insignia coincide con la regla', () {
      expect(insigniaStock(0, 5).texto, 'Agotado');
      expect(insigniaStock(5, 5).tono, Tono.alerta);
      expect(insigniaStock(9, 5).tono, Tono.exito);
    });
  });

  group('Formato', () {
    test('moneda en bolivianos', () {
      expect(bs(12.5), 'Bs 12,50');
      expect(bs(0), 'Bs 0,00');
    });
    test('folios', () {
      expect(folio('ENT', 18), 'ENT-0018');
      expect(folio('VEN', 12345), 'VEN-12345');
    });
    test('fecha y hora local', () {
      final local = DateTime(2026, 10, 21, 14, 5);
      expect(fechaHora(local.toUtc().toIso8601String()), '21/10/2026 14:05');
    });
  });

  group('Validadores (CP-12)', () {
    test('campo obligatorio', () {
      expect(requerido('  '), isNotNull);
      expect(requerido('Arroz'), isNull);
    });
    test('decimales con coma o punto', () {
      expect(leerDecimal('12,50'), 12.5);
      expect(leerDecimal('12.50'), 12.5);
      expect(decimalNoNegativo('-1'), isNotNull);
      expect(decimalNoNegativo('abc'), isNotNull);
      expect(decimalNoNegativo('0'), isNull);
    });
    test('enteros', () {
      expect(enteroNoNegativo('3.5'), isNotNull);
      expect(enteroNoNegativo('0'), isNull);
      expect(enteroPositivo('0'), isNotNull);
      expect(enteroPositivo('10'), isNull);
    });
    test('correo opcional', () {
      expect(correoOpcional(''), isNull);
      expect(correoOpcional('ventas@tienda.bo'), isNull);
      expect(correoOpcional('ventas@'), isNotNull);
    });
  });

  group('Mensajes de error', () {
    test('aviso de usuario se muestra tal cual', () {
      expect(mensajeError(const AvisoUsuario('Hay un producto repetido.')), 'Hay un producto repetido.');
    });
    test('sin conexión', () {
      expect(mensajeError(Exception('SocketException: Failed host lookup')), contains('Sin conexión'));
    });
  });

  testWidgets('la insignia muestra su texto', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Insignia('Stock bajo', Tono.alerta))));
    expect(find.text('Stock bajo'), findsOneWidget);
  });
}

import 'package:intl/intl.dart';

final _moneda = NumberFormat.currency(locale: 'es', symbol: 'Bs', customPattern: '\u00A4 #,##0.00', decimalDigits: 2);
final _fecha = DateFormat('dd/MM/yyyy HH:mm', 'es');

/// 12.5 -> "Bs 12,50"
String bs(num valor) => _moneda.format(valor);

/// Fecha ISO de Supabase -> "21/10/2026 14:05" (hora local)
String fechaHora(String iso) => _fecha.format(DateTime.parse(iso).toLocal());

/// 18 -> "ENT-0018"
String folio(String prefijo, num id) => '$prefijo-${id.toInt().toString().padLeft(4, '0')}';

/// Inicio del dia local en formato ISO UTC, para filtrar "hoy".
String inicioDeHoyIso() {
  final ahora = DateTime.now();
  return DateTime(ahora.year, ahora.month, ahora.day).toUtc().toIso8601String();
}

/// Validadores de formularios (mensajes en espanol).
String? requerido(String? v, [String campo = 'Este campo']) =>
    (v ?? '').trim().isEmpty ? '$campo es obligatorio.' : null;

/// Convierte "12,50" o "12.50" en numero.
double? leerDecimal(String? v) => double.tryParse((v ?? '').trim().replaceAll(',', '.'));

String? decimalNoNegativo(String? v) {
  if ((v ?? '').trim().isEmpty) return 'Obligatorio.';
  final n = leerDecimal(v);
  if (n == null) return 'Número no válido.';
  if (n < 0) return 'No puede ser negativo.';
  return null;
}

String? enteroNoNegativo(String? v) {
  if ((v ?? '').trim().isEmpty) return 'Obligatorio.';
  final n = int.tryParse(v!.trim());
  if (n == null) return 'Debe ser un número entero.';
  if (n < 0) return 'No puede ser negativo.';
  return null;
}

String? enteroPositivo(String? v) {
  final e = enteroNoNegativo(v);
  if (e != null) return e;
  return int.parse(v!.trim()) == 0 ? 'Debe ser mayor que 0.' : null;
}

String? correoOpcional(String? v) {
  final t = (v ?? '').trim();
  if (t.isEmpty) return null;
  return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(t) ? null : 'Correo no válido.';
}

/// Texto vacio -> null (para columnas opcionales).
String? textoONull(String v) => v.trim().isEmpty ? null : v.trim();

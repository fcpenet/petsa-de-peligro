/// Money is always stored as whole centavos in an [int]. Never use doubles.
library;

/// Formats centavos as pesos, e.g. 121166 → "₱1,211.66", -500 → "-₱5.00".
String formatPeso(int cents) {
  final negative = cents < 0;
  final abs = cents.abs();
  final pesos = abs ~/ 100;
  final centavos = (abs % 100).toString().padLeft(2, '0');

  final digits = pesos.toString();
  final grouped = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) grouped.write(',');
    grouped.write(digits[i]);
  }
  return '${negative ? '-' : ''}₱$grouped.$centavos';
}

final _pesoPattern = RegExp(r'^\d+(\.\d{0,2})?$');

/// Parses user input like "1,211.67", "₱800", "72.5" into centavos.
/// Returns null for empty, negative, or malformed input, or more than two
/// decimal places.
int? parsePesoToCents(String input) {
  final cleaned = input.trim().replaceAll(',', '').replaceAll('₱', '').trim();
  if (!_pesoPattern.hasMatch(cleaned)) return null;

  final parts = cleaned.split('.');
  final pesos = int.parse(parts[0]);
  final fraction = parts.length > 1 ? parts[1].padRight(2, '0') : '00';
  return pesos * 100 + int.parse(fraction);
}

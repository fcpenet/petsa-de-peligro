import 'package:flutter_test/flutter_test.dart';
import 'package:petsa/core/money.dart';

void main() {
  group('formatPeso', () {
    test('formats zero', () => expect(formatPeso(0), '₱0.00'));

    test('formats centavos only', () {
      expect(formatPeso(5), '₱0.05');
      expect(formatPeso(99), '₱0.99');
    });

    test('groups thousands', () {
      expect(formatPeso(100000), '₱1,000.00');
      expect(formatPeso(121166), '₱1,211.66');
      expect(formatPeso(24212223), '₱242,122.23');
      expect(formatPeso(123456789012), '₱1,234,567,890.12');
    });

    test('does not group below a thousand', () {
      expect(formatPeso(99999), '₱999.99');
    });

    test('formats negatives', () {
      expect(formatPeso(-500), '-₱5.00');
      expect(formatPeso(-1323844), '-₱13,238.44');
    });
  });

  group('parsePesoToCents', () {
    test('parses whole pesos', () {
      expect(parsePesoToCents('800'), 80000);
      expect(parsePesoToCents('0'), 0);
    });

    test('parses decimals and pads one decimal place', () {
      expect(parsePesoToCents('72.28'), 7228);
      expect(parsePesoToCents('72.5'), 7250);
      expect(parsePesoToCents('72.'), 7200);
    });

    test('strips commas, peso sign and whitespace', () {
      expect(parsePesoToCents(' ₱1,211.67 '), 121167);
      expect(parsePesoToCents('25,000'), 2500000);
    });

    test('rejects invalid input', () {
      for (final bad in ['', '  ', 'abc', '-5', '1.234', '1.2.3', '₱', '.5']) {
        expect(parsePesoToCents(bad), isNull, reason: 'input "$bad"');
      }
    });

    test('round-trips with formatPeso', () {
      for (final cents in [0, 1, 7228, 121167, 2500000]) {
        expect(parsePesoToCents(formatPeso(cents)), cents);
      }
    });
  });
}

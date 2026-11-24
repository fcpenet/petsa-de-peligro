import 'package:flutter_test/flutter_test.dart';
import 'package:petsa/core/db/connection.dart';

void main() {
  final page = Uri.parse('https://petsa.pages.dev/#/budget/2026-11');

  test('a path means the same-site proxy', () {
    expect(usesSameSiteProxy('/'), isTrue);
    expect(usesSameSiteProxy('libsql://db.turso.io'), isFalse);
  });

  test('the proxy needs no token; a Turso URL does', () {
    expect(hasTursoConfigFor('/', ''), isTrue);
    expect(hasTursoConfigFor('libsql://db.turso.io', ''), isFalse);
    expect(hasTursoConfigFor('libsql://db.turso.io', 't'), isTrue);
    expect(hasTursoConfigFor('', ''), isFalse);
  });

  test('resolves the proxy against the page, dropping the hash route', () {
    expect(resolveTursoUrl('/', page), 'https://petsa.pages.dev/');
    expect(
      resolveTursoUrl('libsql://db.turso.io', page),
      'libsql://db.turso.io',
    );
  });
}

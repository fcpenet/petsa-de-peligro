// Runs the repository suite against a real Turso database.
//
//   flutter test test/integration/turso_test.dart --dart-define-from-file=.env.test.local
//   flutter test test/integration/turso_test.dart --platform chrome --dart-define-from-file=.env.test.local
//
// Uses TURSO_TEST_URL / TURSO_TEST_TOKEN (separate from the app's settings)
// and is skipped when they are not defined. Every test wipes and recreates
// the schema, so never point it at the database the app uses.
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:petsa/core/db/database.dart';
import 'package:petsa/core/db/turso/turso_database.dart';
import 'package:petsa/features/budget/data/budget_repository.dart';

import '../features/budget/budget_repository_suite.dart';
import '../helpers/units.dart';

const _url = String.fromEnvironment('TURSO_TEST_URL');
const _token = String.fromEnvironment('TURSO_TEST_TOKEN');
const _configured = _url != '' && _token != '';

const _tables = [
  'templates',
  'items',
  'income_top_ups',
  'incomes',
  'accounts',
  'institutions',
  'months',
];

Future<AppDatabase> openFreshTursoDatabase() async {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final db = AppDatabase(TursoDatabase(url: _url, authToken: _token));
  await db.customSelect('SELECT 1').get(); // opens and runs migrations
  await db.batch((b) {
    for (final table in _tables) {
      b.customStatement('DROP TABLE IF EXISTS $table');
    }
  });
  await db.createMigrator().createAll();
  return db;
}

void main() {
  group('Turso', () {
    budgetRepositoryTests(openFreshTursoDatabase);

    test('latency of common operations', () async {
      final db = await openFreshTursoDatabase();
      addTearDown(db.close);
      final repo = BudgetRepository(db);

      Future<T> timed<T>(String label, Future<T> Function() op) async {
        final sw = Stopwatch()..start();
        final result = await op();
        // ignore: avoid_print
        print('  ${label.padRight(36)} ${sw.elapsedMilliseconds} ms');
        return result;
      }

      final month = await timed(
        'ensureMonth (new)',
        () => repo.ensureMonth('2026-11'),
      );
      await timed('ensureMonth (existing)', () => repo.ensureMonth('2026-11'));
      final misc = await timed(
        'addItem (top level)',
        () => repo.addItem(
          monthId: month.id,
          name: 'Misc',
          amountCents: php(5000),
          isCollection: true,
        ),
      );
      final children = <String>[];
      for (var i = 0; i < 5; i++) {
        children.add(
          await timed(
            'addItem (sub-expense)',
            () => repo.addItem(
              monthId: month.id,
              name: 'child $i',
              amountCents: php(100),
              parentId: misc,
            ),
          ),
        );
      }
      await timed(
        'setStatus (sub-expense)',
        () => repo.setStatus(children.first, ItemStatus.paid),
      );
      await timed(
        'setStatus (parent → 5 children)',
        () => repo.setStatus(misc, ItemStatus.paid),
      );
      await timed('updateItem', () => repo.updateItem(misc, name: 'Misc 2'));
      await timed('itemsFor (month)', () => repo.itemsFor(month.id));
      final totals = await timed(
        'totalsFor (month)',
        () => repo.totalsFor(month.id),
      );
      expect(totals.paidCents, php(500));
    });
  }, skip: _configured ? false : 'TURSO_TEST_URL / TURSO_TEST_TOKEN not set');
}

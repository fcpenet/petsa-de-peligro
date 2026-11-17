// ignore_for_file: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
// Wipes the TEST Turso database and fills it with the November sample
// plus a salary top-up, an expense paid from another account and a
// "Monthly" template.
// Not part of the normal suite (lives outside test/). Run explicitly:
//
//   flutter test tool/seed_demo_test.dart --dart-define-from-file=.env.test.local
import 'package:flutter_test/flutter_test.dart';
import 'package:petsa/core/db/database.dart';
import 'package:petsa/core/db/turso/turso_database.dart';
import 'package:petsa/features/budget/data/budget_repository.dart';
import 'package:petsa/features/templates/data/template_repository.dart';

import '../test/helpers/november.dart';

const _url = String.fromEnvironment('TURSO_TEST_URL');
const _token = String.fromEnvironment('TURSO_TEST_TOKEN');

void main() {
  test('seed November sample into the test database', () async {
    final db = AppDatabase(TursoDatabase(url: _url, authToken: _token));
    await db.customSelect('SELECT 1').get();
    await db.batch((b) {
      for (final t in [
        'templates',
        'transfers',
        'items',
        'income_top_ups',
        'incomes',
        'accounts',
        'institutions',
        'months',
      ]) {
        b.customStatement('DROP TABLE IF EXISTS $t');
      }
    });
    await db.createMigrator().createAll();
    final ids = await seedNovember(db);
    await BudgetRepository(db).addTopUp(
      incomeId: ids.salary,
      amountCents: 12106112,
      receivedAt: DateTime(2026, 11, 15),
      note: '15th payout',
    );
    // Planned on the RCBC Card, paid from UB: shows the Rebalance card.
    await BudgetRepository(db).setStatus(
      ids.items['Electric']!,
      ItemStatus.paid,
      paidAt: DateTime(2026, 11, 16),
      paidFromAccountId: ids.accounts['UB'],
    );
    await TemplateRepository(db)
        .saveFromMonth(monthId: ids.monthId, name: 'Monthly');
    await db.close();
  }, skip: _url.isEmpty ? 'TURSO_TEST_URL not set' : false);
}

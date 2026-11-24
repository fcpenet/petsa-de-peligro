import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:petsa/core/db/database.dart';
import 'package:petsa/features/accounts/data/account_repository.dart';
import 'package:petsa/features/budget/data/budget_repository.dart';
import 'package:petsa/features/budget/domain/budget_calculator.dart';
import 'package:petsa/features/sheet/domain/sheet_model.dart';
import 'package:petsa/features/templates/data/template_repository.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

import '../../helpers/app_harness.dart';
import '../../helpers/legacy_schema.dart';
import '../../helpers/november.dart';
import '../../helpers/test_db.dart';

void main() {
  late AppDatabase db;
  late NovemberIds ids;
  late BudgetRepository repo;

  setUp(() async {
    db = createTestDatabase();
    ids = await seedNovember(db);
    repo = BudgetRepository(db);
  });

  group('repository', () {
    tearDown(() => db.close());

    test('top-ups add up to what was received', () async {
      await repo.addTopUp(
        incomeId: ids.salary,
        amountCents: php(121061.12),
        receivedAt: DateTime(2026, 11, 15),
        note: ' 15th ',
      );
      await repo.addTopUp(
        incomeId: ids.salary,
        amountCents: php(100000),
        receivedAt: DateTime(2026, 11, 1),
      );
      final topUps = await repo.topUpsFor(ids.monthId);
      // Oldest first.
      expect(topUps.map((t) => t.receivedAt.day), [1, 15]);
      expect(topUps.last.note, '15th');
      expect(topUps.first.note, isNull);

      final totals = await repo.totalsFor(ids.monthId);
      expect(totals.incomeCents, php(242122.23)); // expected is unchanged
      expect(totals.receivedCents, php(221061.12));
      expect(totals.toReceiveCents, php(21061.11));
      // Budgeting still plans against the expected salary.
      expect(totals.unbudgetedCents, php(188642.23));
    });

    test('edit and delete a top-up', () async {
      final id = await repo.addTopUp(
        incomeId: ids.salary,
        amountCents: php(1000),
        receivedAt: DateTime(2026, 11, 15),
        note: 'oops',
      );
      await repo.updateTopUp(
        id,
        amountCents: php(1500),
        receivedAt: DateTime(2026, 11, 16),
        note: const Value(null),
      );
      final t = (await repo.topUpsFor(ids.monthId)).single;
      expect(t.amountCents, php(1500));
      expect(t.receivedAt, DateTime(2026, 11, 16));
      expect(t.note, isNull);

      await repo.deleteTopUp(id);
      expect(await repo.topUpsFor(ids.monthId), isEmpty);
      expect(
        () => repo.updateTopUp(id, amountCents: 1),
        throwsA(isA<BudgetException>()),
      );
    });

    test('rejects zero amounts and missing incomes', () async {
      expect(
        () => repo.addTopUp(
          incomeId: ids.salary,
          amountCents: 0,
          receivedAt: DateTime(2026, 11, 15),
        ),
        throwsA(isA<BudgetException>()),
      );
      expect(
        () => repo.addTopUp(
          incomeId: 'nope',
          amountCents: 1,
          receivedAt: DateTime(2026, 11, 15),
        ),
        throwsA(isA<BudgetException>()),
      );
    });

    test('a deleted income takes its top-ups out of the totals', () async {
      await repo.addTopUp(
        incomeId: ids.salary,
        amountCents: php(5000),
        receivedAt: DateTime(2026, 11, 15),
      );
      await repo.deleteIncome(ids.salary);
      expect(await repo.topUpsFor(ids.monthId), isEmpty);
      expect((await repo.totalsFor(ids.monthId)).receivedCents, 0);
      expect(
        () => repo.addTopUp(
          incomeId: ids.salary,
          amountCents: 1,
          receivedAt: DateTime(2026, 11, 15),
        ),
        throwsA(isA<BudgetException>()),
      );
    });

    test('templates keep the expected amount, never top-ups', () async {
      await repo.addTopUp(
        incomeId: ids.salary,
        amountCents: php(5000),
        receivedAt: DateTime(2026, 11, 15),
      );
      final december = (await repo.ensureMonth('2026-12')).id;
      await TemplateRepository(db)
          .copyMonth(fromYearMonth: '2026-11', toMonthId: december);
      final totals = await repo.totalsFor(december);
      expect(totals.incomeCents, php(242122.23));
      expect(totals.receivedCents, 0);
    });

    test('the Overview shows received next to expected', () async {
      await repo.addTopUp(
        incomeId: ids.salary,
        amountCents: php(5000),
        receivedAt: DateTime(2026, 11, 15),
      );
      final model = buildSheet(
        accounts: await AccountRepository(db).accounts(),
        items: await repo.itemsFor(ids.monthId),
        incomes: await repo.incomesFor(ids.monthId),
        topUps: await repo.topUpsFor(ids.monthId),
      );
      final pos = model.find(
        (c) => c.field == CellField.incomeReceived && c.incomeId == ids.salary,
      )!;
      expect(model.cell(pos.$1, pos.$2).cents, php(5000));
      final label = model.find((c) => c.text == 'Salary received')!;
      expect(model.cell(label.$1, label.$2 + 1).cents, php(5000));
    });
  });

  group('calculator', () {
    tearDown(() => db.close());

    Income income(String id, int cents) => Income(
      id: id,
      updatedAt: DateTime(2026),
      monthId: 'm',
      name: id,
      amountCents: cents,
      sortOrder: 0,
    );
    TopUp topUp(String incomeId, int cents, {DateTime? deletedAt}) => TopUp(
      id: '$incomeId-$cents',
      updatedAt: DateTime(2026),
      deletedAt: deletedAt,
      incomeId: incomeId,
      amountCents: cents,
      receivedAt: DateTime(2026, 11, 15),
    );

    test('extra on one income does not cover another that is short', () {
      final totals = computeMonthTotals(
        items: const [],
        incomes: [income('salary', 1000), income('bonus', 500)],
        topUps: [
          topUp('salary', 1200),
          topUp('bonus', 100),
          topUp('bonus', 50, deletedAt: DateTime(2026)),
          topUp('gone', 999),
        ],
      );
      expect(totals.receivedCents, 1300);
      expect(totals.receivedByIncome, {'salary': 1200, 'bonus': 100});
      expect(totals.toReceiveCents, 400);
    });

    test('without top-ups everything is still to come', () {
      final totals = computeMonthTotals(
        items: const [],
        incomes: [income('salary', 1000)],
      );
      expect(totals.receivedCents, 0);
      expect(totals.toReceiveCents, 1000);
    });
  });

  test('upgrades a version 2 database by adding top-ups', () async {
    await db.close();
    final dir = Directory.systemTemp.createTempSync('petsa-v2');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/petsa.db');

    // A current database, rolled back to v2's shape.
    final seed = AppDatabase(NativeDatabase(file));
    final seedIds = await seedNovember(seed);
    await seed.close();
    final raw = sqlite.sqlite3.open(file.path)
      ..execute('DROP TABLE income_top_ups')
      ..execute('DROP TABLE transfers');
    dropColumns(raw, 'items', [
      'is_collection',
      'paid_from_account_id',
      'charged_at',
    ]);
    raw
      ..execute('PRAGMA user_version = 2')
      ..close();

    final upgraded = AppDatabase(NativeDatabase(file));
    addTearDown(upgraded.close);
    final r = BudgetRepository(upgraded);
    await r.addTopUp(
      incomeId: seedIds.salary,
      amountCents: 100,
      receivedAt: DateTime(2026, 11, 15),
    );
    expect((await r.totalsFor(seedIds.monthId)).receivedCents, 100);
    expect((await r.incomesFor(seedIds.monthId)).single.name, 'Salary');
  });

  group('budget page', () {
    // The top-up form opens on top of the income form.
    Future<void> saveTop(WidgetTester tester) async {
      await tester.tap(find.byKey(const Key('form-save')).last);
      await tester.pumpAndSettle();
    }

    String text(WidgetTester tester, String key) =>
        tester.widget<Text>(find.byKey(Key(key))).data!;

    testWidgets('top up from the income row, with a date', (tester) async {
      await pumpApp(tester, db);
      expect(text(tester, 'stat-Received'), '₱0.00');
      expect(find.text('Nothing received yet'), findsOneWidget);

      await tester.tap(find.byKey(ValueKey('top-up-${ids.salary}')));
      await tester.pumpAndSettle();
      expect(find.text('Top up Salary'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('field-amount')),
        '121061.12',
      );
      await tester.tap(find.byKey(const Key('field-date')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('3'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('field-note')), '15th');
      await save(tester);

      final t = (await repo.topUpsFor(ids.monthId)).single;
      expect(t.amountCents, php(121061.12));
      expect(t.receivedAt.day, 3);
      expect(t.note, '15th');

      expect(text(tester, 'stat-Received'), '₱121,061.12');
      expect(text(tester, 'stat-Expected income'), '₱242,122.23');
      expect(text(tester, 'received-${ids.salary}'), '₱121,061.12');
      expect(find.textContaining('₱121,061.11 to come'), findsOneWidget);
      await closeApp(tester, db);
    });

    testWidgets('the income form lists top-ups to edit or delete', (
      tester,
    ) async {
      final id = await repo.addTopUp(
        incomeId: ids.salary,
        amountCents: php(242122.23),
        receivedAt: DateTime(2026, 11, 15),
      );
      await pumpApp(tester, db);
      expect(find.textContaining('Received in full'), findsOneWidget);

      await tester.tap(find.byKey(ValueKey('income-${ids.salary}')));
      await tester.pumpAndSettle();
      expect(find.text('Expected amount'), findsOneWidget);
      expect(text(tester, 'received-summary'), '₱242,122.23 of ₱242,122.23');

      // Edit the top-up.
      await tester.tap(find.byKey(ValueKey('top-up-$id')));
      await tester.pumpAndSettle();
      expect(find.text('Edit top-up'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('field-amount')).last,
        '1000',
      );
      await saveTop(tester);
      expect(text(tester, 'received-summary'), '₱1,000.00 of ₱242,122.23');

      // Add another from inside the form.
      await tester.tap(find.byKey(const Key('add-top-up')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('field-amount')).last, '500');
      await saveTop(tester);
      expect(text(tester, 'received-summary'), '₱1,500.00 of ₱242,122.23');

      // Delete the first.
      await tester.tap(find.byKey(ValueKey('top-up-$id')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('form-delete')).last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm-delete')));
      await tester.pumpAndSettle();
      expect(text(tester, 'received-summary'), '₱500.00 of ₱242,122.23');
      expect((await repo.topUpsFor(ids.monthId)).single.amountCents, 50000);
      await closeApp(tester, db);
    });

    testWidgets('top-ups work on a phone', (tester) async {
      await pumpApp(tester, db, size: phone);
      await tester.scrollUntilVisible(
        find.byKey(ValueKey('top-up-${ids.salary}')),
        400,
        // The page also has a sideways row of account chips.
        scrollable: find.byWidgetPredicate(
          (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey('top-up-${ids.salary}')));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
      await tester.enterText(find.byKey(const Key('field-amount')).last, '100');
      await save(tester);
      expect(await repo.topUpsFor(ids.monthId), hasLength(1));
      await closeApp(tester, db);
    });
  });
}

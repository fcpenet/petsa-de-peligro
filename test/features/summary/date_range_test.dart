import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:petsa/core/db/database.dart';
import 'package:petsa/features/accounts/data/account_repository.dart';
import 'package:petsa/features/budget/data/budget_repository.dart';
import 'package:petsa/features/summary/domain/account_summary.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/november.dart';
import '../../helpers/test_db.dart';

final _t = DateTime(2026, 11, 1);

BudgetItem item({
  ItemStatus status = ItemStatus.planned,
  DateTime? paidAt,
  int? dueDay,
}) => BudgetItem(
  id: 'x',
  updatedAt: _t,
  monthId: 'm',
  name: 'x',
  amountCents: 1,
  kind: ItemKind.expense,
  status: status,
  paidAt: paidAt,
  dueDay: dueDay,
  sortOrder: 0,
  isCollection: false,
);

void main() {
  group('itemDate', () {
    test('paid: the payment day', () {
      expect(
        itemDate(
          item(status: ItemStatus.paid, paidAt: DateTime(2026, 12, 2, 18)),
          '2026-11',
        ),
        DateTime(2026, 12, 2),
      );
    });

    test('unpaid: the due day in its month, else the 1st', () {
      expect(itemDate(item(dueDay: 20), '2026-11'), DateTime(2026, 11, 20));
      expect(
        itemDate(item(status: ItemStatus.allotted), '2026-11'),
        DateTime(2026, 11, 1),
      );
    });

    test('due days past the end of the month fall on its last day', () {
      expect(itemDate(item(dueDay: 31), '2027-02'), DateTime(2027, 2, 28));
      expect(itemDate(item(dueDay: 31), '2028-02'), DateTime(2028, 2, 29));
    });
  });

  group('summarizeRange', () {
    late AppDatabase db;
    late NovemberIds ids;
    late BudgetRepository repo;
    late String december;

    setUp(() async {
      db = createTestDatabase();
      ids = await seedNovember(db); // paid items are paid Nov 15
      repo = BudgetRepository(db, clock: () => DateTime(2026, 11, 15, 9));
      await repo.updateItem(ids.items['UB Loan']!, dueDay: const Value(20));
      await repo.updateItem(ids.items['Pru']!, dueDay: const Value(28));
      december = (await repo.ensureMonth('2026-12')).id;
      await repo.addItem(
        monthId: december,
        name: 'December rent',
        amountCents: 100,
        accountId: ids.accounts['BPI'],
        dueDay: 5,
      );
    });

    tearDown(() => db.close());

    Future<MonthSummary> between(DateTime from, DateTime to) async {
      final rows = await repo.itemsBetween(from, to);
      return summarizeRange(
        accounts: await AccountRepository(db).accounts(),
        items: [for (final (i, _) in rows) i],
        yearMonthOf: {for (final (i, ym) in rows) i.monthId: ym},
        range: (from: from, to: to),
        transfers: await repo.transfersBetween(from, to),
      );
    }

    AccountSummary named(MonthSummary s, String name) => [
      ...s.accounts.accounts,
      ...s.cards.accounts,
    ].singleWhere((a) => a.account.name == name);

    test('counts paid by payment date and unpaid by due day', () async {
      final s = await between(DateTime(2026, 11, 10), DateTime(2026, 11, 22));
      final ub = named(s, 'UB');
      expect(ub.items.map((i) => i.name), ['UB Loan']); // due 20th; Pru 28th
      expect(ub.budgetedCents, 700000);
      // Paid on the 15th: Basic (Cash), Cats (RCBC), Rent (BPI), pliers.
      expect(named(s, 'Cash').items.map((i) => i.name), ['Basic']);
      expect(named(s, 'JCB').items.single.name, 'dental pliers');
      // Unpaid with no due day count on Nov 1: outside.
      expect(named(s, 'RCBC Card').items.map((i) => i.name), ['Cats']);
      expect(named(s, 'BPI').items.map((i) => i.name), ['Rent']); // not QR
    });

    test('spans months', () async {
      final s = await between(DateTime(2026, 11, 25), DateTime(2026, 12, 10));
      expect(named(s, 'UB').items.map((i) => i.name), ['Pru']);
      expect(named(s, 'BPI').items.map((i) => i.name), ['December rent']);
    });

    test('a November expense paid in December counts in December', () async {
      await repo.setStatus(
        ids.items['Electric']!,
        ItemStatus.paid,
        paidAt: DateTime(2026, 12, 2),
      );
      final dec = await between(DateTime(2026, 12, 1), DateTime(2026, 12, 31));
      expect(named(dec, 'RCBC Card').items.single.name, 'Electric');
      expect(named(dec, 'RCBC Card').paidCents, 600000);
      final nov = await between(DateTime(2026, 11, 1), DateTime(2026, 11, 30));
      expect(
        named(nov, 'RCBC Card').items.map((i) => i.name),
        isNot(contains('Electric')),
      );
    });

    test(
      'a sub-expense still finds its account through its collection',
      () async {
        // sleeve has its own account; add one that uses Misc's (Cash).
        await repo.addItem(
          monthId: ids.monthId,
          name: 'tape',
          amountCents: 50,
          parentId: ids.misc,
          dueDay: 12,
        );
        final s = await between(DateTime(2026, 11, 12), DateTime(2026, 11, 12));
        expect(named(s, 'Cash').items.single.name, 'tape');
      },
    );

    test('transfers count by the day they were made', () async {
      await repo.setStatus(
        ids.items['Electric']!,
        ItemStatus.paid,
        paidAt: DateTime(2026, 11, 16),
        paidFromAccountId: ids.accounts['UB'],
      );
      await repo.addTransfer(
        monthId: ids.monthId,
        fromAccountId: ids.accounts['RCBC Card']!,
        toAccountId: ids.accounts['UB']!,
        amountCents: 600000,
        transferredAt: DateTime(2026, 11, 25),
      );
      final before = await between(
        DateTime(2026, 11, 1),
        DateTime(2026, 11, 20),
      );
      expect(named(before, 'UB').balanceCents, -600000);
      final after = await between(
        DateTime(2026, 11, 1),
        DateTime(2026, 11, 30),
      );
      expect(named(after, 'UB').balanceCents, 0);
    });
  });

  group('page', () {
    late AppDatabase db;
    late NovemberIds ids;

    setUp(() async {
      db = createTestDatabase();
      ids = await seedNovember(db);
    });

    testWidgets('pick dates, see the range, go back to the month', (
      tester,
    ) async {
      final router = await pumpApp(tester, db, location: '/summary/2026-11');
      await tester.tap(find.byKey(const Key('summary-range')));
      await tester.pumpAndSettle();
      // Starts on the whole month; save it as is.
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(
        router.routerDelegate.currentConfiguration.uri.toString(),
        '/summary/range?from=2026-11-01&to=2026-11-30',
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('summary-range-label'))).data,
        'Nov 1, 2026 – Nov 30, 2026',
      );
      expect(find.byKey(const Key('summary-range-note')), findsOneWidget);
      expect(find.byKey(const Key('summary-cards')), findsOneWidget);

      await tester.tap(find.byKey(const Key('summary-range-clear')));
      await tester.pumpAndSettle();
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        '/summary/2026-11',
      );
      await closeApp(tester, db);
    });

    testWidgets('a narrow range shows only what falls in it', (tester) async {
      await pumpApp(
        tester,
        db,
        location: '/summary/range?from=2026-11-15&to=2026-11-15',
        size: phone,
      );
      // Paid on the 15th: Cash, RCBC (Cats), BPI (Rent), JCB.
      String figure(String key) =>
          tester.widget<Text>(find.byKey(Key(key))).data!;
      expect(figure('figure-Accounts-Paid'), '₱33,000.00');
      expect(figure('figure-Accounts-Left to pay'), '₱0.00');
      expect(figure('figure-Credit cards-Settled'), '₱3,549.00');
      expect(
        find.byKey(ValueKey('summary-${ids.accounts['UB']}')),
        findsNothing,
      );
      await closeApp(tester, db);
    });

    testWidgets('bad ranges fall back to this month', (tester) async {
      final router = await pumpApp(
        tester,
        db,
        location: '/summary/range?from=2026-11-20&to=2026-11-01',
      );
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        '/summary/2026-11',
      );
      router.go('/summary/range?from=nope&to=2026-11-01');
      await tester.pumpAndSettle();
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        '/summary/2026-11',
      );
      await closeApp(tester, db);
    });
  });
}

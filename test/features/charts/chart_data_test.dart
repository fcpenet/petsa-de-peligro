import 'package:flutter_test/flutter_test.dart';
import 'package:petsa/core/db/database.dart';
import 'package:petsa/features/budget/data/budget_repository.dart';
import 'package:petsa/features/charts/domain/chart_data.dart';
import 'package:petsa/features/charts/ui/charts_page.dart' show compactPeso;

import '../../helpers/november.dart';
import '../../helpers/test_db.dart';

void main() {
  late AppDatabase db;
  late NovemberIds ids;
  late BudgetRepository repo;

  setUp(() async {
    db = createTestDatabase();
    ids = await seedNovember(db);
    repo = BudgetRepository(db, clock: () => DateTime(2026, 11, 15));
  });
  tearDown(() => db.close());

  group('chartDataFor', () {
    test('counts sub-expenses, not the collection holding them', () async {
      final data = chartDataFor(await repo.itemsFor(ids.monthId));
      // Basic, Cats, Rent, dental pliers.
      expect(data.byStatus[ItemStatus.paid], php(36549));
      // UB Loan, Pru, Electric, QR, sleeve.
      expect(data.byStatus[ItemStatus.planned], php(15576.26));
      expect(data.totalCents, php(52125.26));
      expect(data.byName.any((e) => e.$1 == 'Misc'), isFalse);
    });

    test('a sub-expense counts toward its own account', () async {
      final data = chartDataFor(await repo.itemsFor(ids.monthId));
      final cash = data.byAccount[ids.accounts['Cash']]!;
      expect(cash[ItemStatus.paid], php(8000)); // Basic
      expect(cash[ItemStatus.planned], php(296.26)); // sleeve
      expect(data.byAccount[ids.accounts['JCB']]![ItemStatus.paid], php(549));
      expect(
        data.byAccount[ids.accounts['UB']]![ItemStatus.planned],
        php(9000),
      );
    });

    test('names add up across months, biggest first', () async {
      final december = (await repo.ensureMonth('2026-12')).id;
      await repo.addItem(
        monthId: december,
        name: 'rent ',
        amountCents: php(25000),
        accountId: ids.accounts['BPI'],
      );
      final data = chartDataFor([
        ...await repo.itemsFor(ids.monthId),
        ...await repo.itemsFor(december),
      ]);
      expect(data.byName.first, ('Rent', php(50000)));
    });

    test('topNames folds the rest into one unnamed entry', () async {
      final data = chartDataFor(await repo.itemsFor(ids.monthId));
      final top = data.topNames(3);
      expect(top, hasLength(3));
      expect(top[0].$1, 'Rent');
      expect(top[2].$1, isNull);
      expect(top.fold(0, (s, e) => s + e.$2), data.totalCents);
    });

    test('include picks which expenses count', () async {
      final data = chartDataFor(
        await repo.itemsFor(ids.monthId),
        include: (i) => i.status == ItemStatus.paid,
      );
      expect(data.totalCents, php(36549));
      expect(data.byStatus[ItemStatus.planned], 0);
    });

    test('all one kind by default', () async {
      final data = chartDataFor(await repo.itemsFor(ids.monthId));
      expect(data.byKind, [(ItemKind.expense, php(52125.26))]);
    });
  });

  group('months', () {
    test('monthsBetween crosses years', () {
      expect(monthsBetween('2026-11', '2027-02'), [
        '2026-11',
        '2026-12',
        '2027-01',
        '2027-02',
      ]);
      expect(monthsBetween('2026-11', '2026-11'), ['2026-11']);
    });

    test('monthsEndingAt counts back', () {
      expect(monthsEndingAt('2026-02', 3), ['2025-12', '2026-01', '2026-02']);
      expect(monthsEndingAt('2026-11', 6).first, '2026-06');
    });

    test('monthlySeries has a point per month, zeros where empty', () async {
      final items = await repo.watchItemsInMonths('2026-10', '2026-12').first;
      final incomes = await repo
          .watchIncomesInMonths('2026-10', '2026-12')
          .first;
      final topUps = await repo.watchTopUpsInMonths('2026-10', '2026-12').first;
      final points = monthlySeries(
        yearMonths: monthsBetween('2026-10', '2026-12'),
        items: items,
        incomes: incomes,
        topUps: topUps,
      );
      expect(
        [for (final p in points) p.yearMonth],
        ['2026-10', '2026-11', '2026-12'],
      );
      expect(points[0].expensesCents, 0);
      expect(points[1].incomeCents, php(242122.23));
      expect(points[1].paidCents, php(36549));
      expect(points[2].incomeCents, 0);
    });
  });

  test('compactPeso', () {
    expect(compactPeso(0), '₱0');
    expect(compactPeso(950), '₱950');
    expect(compactPeso(1200), '₱1.2k');
    expect(compactPeso(45000), '₱45k');
    expect(compactPeso(1300000), '₱1.3M');
  });
}

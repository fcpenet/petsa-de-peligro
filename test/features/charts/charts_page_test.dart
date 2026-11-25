import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:petsa/core/db/database.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/november.dart';
import '../../helpers/test_db.dart';

void main() {
  late AppDatabase db;
  late NovemberIds ids;

  setUp(() async {
    db = createTestDatabase();
    ids = await seedNovember(db);
  });

  Finder inCard(String card, Finder f) =>
      find.descendant(of: find.byKey(Key(card)), matching: f);

  testWidgets('Charts is in the menu and keeps the month', (tester) async {
    final router = await pumpApp(tester, db, location: '/budget/2026-10');
    await tester.tap(find.byKey(const Key('nav-charts')));
    await tester.pumpAndSettle();
    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      '/charts/2026-10',
    );
    await closeApp(tester, db);
  });

  testWidgets('shows all four charts for the month', (tester) async {
    await pumpApp(tester, db, location: '/charts/2026-11');
    for (final key in [
      'chart-status',
      'chart-accounts',
      'chart-trend',
      'chart-where',
    ]) {
      expect(find.byKey(Key(key)), findsOneWidget, reason: key);
    }
    expect(
      inCard('chart-status', find.text('70% paid of ₱52,125.26')),
      findsOneWidget,
    );
    expect(
      inCard(
        'chart-account-${ids.accounts['UB']}',
        find.text('₱9,000.00 left of ₱9,000.00'),
      ),
      findsOneWidget,
    );
    expect(
      inCard(
        'chart-account-${ids.accounts['BPI']}',
        find.text('₱280.00 left of ₱25,280.00'),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('trend-bars')), findsOneWidget);
    expect(find.byKey(const Key('where-donut')), findsOneWidget);
    expect(inCard('where-legend', find.text('Rent')), findsOneWidget);
    expect(inCard('where-legend', find.text('₱25,000.00')), findsOneWidget);
    await closeApp(tester, db);
  });

  testWidgets('where the money goes by kind', (tester) async {
    await pumpApp(tester, db, location: '/charts/2026-11');
    await tester.tap(find.text('Kind'));
    await tester.pumpAndSettle();
    expect(inCard('where-legend', find.text('Expenses')), findsOneWidget);
    expect(inCard('where-legend', find.text('100%')), findsOneWidget);
    await closeApp(tester, db);
  });

  testWidgets('month by month has a table view', (tester) async {
    await pumpApp(tester, db, location: '/charts/2026-11');
    await tester.tap(find.byKey(const Key('trend-table')));
    await tester.pumpAndSettle();
    final table = find.byKey(const Key('trend-table-view'));
    expect(table, findsOneWidget);
    expect(
      find.descendant(of: table, matching: find.text('Jun 2026')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: table, matching: find.text('₱242,122.23')),
      findsOneWidget,
    );
    await closeApp(tester, db);
  });

  testWidgets('a date range', (tester) async {
    await pumpApp(
      tester,
      db,
      location: '/charts/range?from=2026-11-01&to=2026-11-30',
    );
    expect(find.byKey(const Key('charts-range-label')), findsOneWidget);
    expect(find.byKey(const Key('charts-range-note')), findsOneWidget);
    expect(find.byKey(const Key('chart-status')), findsOneWidget);

    await tester.tap(find.byKey(const Key('charts-range-clear')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('charts-range-label')), findsNothing);
    await closeApp(tester, db);
  });

  testWidgets('a range with nothing in it', (tester) async {
    await pumpApp(
      tester,
      db,
      location: '/charts/range?from=2020-01-01&to=2020-01-31',
    );
    expect(find.byKey(const Key('charts-empty')), findsOneWidget);
    expect(find.byKey(const Key('chart-trend')), findsOneWidget);
    await closeApp(tester, db);
  });

  testWidgets('fits a phone', (tester) async {
    await pumpApp(tester, db, size: phone, location: '/charts/2026-11');
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.byKey(const Key('where-legend')),
      300,
      scrollable: find.byWidgetPredicate(
        (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
      ),
    );
    expect(tester.takeException(), isNull);
    await closeApp(tester, db);
  });
}

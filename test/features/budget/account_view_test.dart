import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:petsa/app/side_nav.dart';
import 'package:petsa/core/db/database.dart';
import 'package:petsa/features/budget/data/budget_repository.dart';

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

  Finder item(String name) => find.byKey(ValueKey('item-${ids.items[name]}'));
  String? leftToPay(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const Key('stat-Left to pay'))).data;
  String path(router) =>
      router.routerDelegate.currentConfiguration.uri.toString();

  test('budgetLocation adds the account as a query', () {
    expect(budgetLocation('2026-11'), '/budget/2026-11');
    expect(budgetLocation('2026-11', 'a b'), '/budget/2026-11?account=a+b');
  });

  group('side menu (desktop)', () {
    testWidgets('lists the accounts under Budget with what is left', (
      tester,
    ) async {
      await pumpApp(tester, db);
      final ub = find.byKey(Key('nav-account-${ids.accounts['UB']}'));
      expect(ub, findsOneWidget);
      expect(
        find.descendant(of: ub, matching: find.text('₱9,000.00')),
        findsOneWidget,
      );
      // Cash: only the unpaid sleeve is left.
      expect(
        find.descendant(
          of: find.byKey(Key('nav-account-${ids.accounts['Cash']}')),
          matching: find.text('₱296.26'),
        ),
        findsOneWidget,
      );
      await closeApp(tester, db);
    });

    testWidgets('only shows the accounts while on Budget', (tester) async {
      await pumpApp(tester, db, location: '/summary/2026-11');
      expect(find.byKey(const Key('nav-accounts-list')), findsNothing);
      await closeApp(tester, db);
    });

    testWidgets('an account shows only its expenses, and Budget shows all', (
      tester,
    ) async {
      final router = await pumpApp(tester, db);
      await tester.tap(find.byKey(Key('nav-account-${ids.accounts['UB']}')));
      await tester.pumpAndSettle();

      expect(path(router), '/budget/2026-11?account=${ids.accounts['UB']}');
      expect(find.byKey(const Key('account-view')), findsOneWidget);
      expect(item('UB Loan'), findsOneWidget);
      expect(item('Pru'), findsOneWidget);
      expect(item('Rent'), findsNothing);
      expect(find.text('Left to pay · UB'), findsOneWidget);
      expect(leftToPay(tester), '₱9,000.00');

      await tester.tap(find.byKey(const Key('nav-budget')));
      await tester.pumpAndSettle();
      expect(path(router), '/budget/2026-11');
      expect(item('Rent'), findsOneWidget);
      expect(leftToPay(tester), '₱15,576.26');
      await closeApp(tester, db);
    });

    testWidgets('sub-expenses from other collections show on their account', (
      tester,
    ) async {
      final jcb = ids.accounts['JCB']!;
      await pumpApp(tester, db, location: '/budget/2026-11?account=$jcb');
      expect(find.byKey(Key('elsewhere-$jcb')), findsOneWidget);
      expect(item('dental pliers'), findsOneWidget);
      expect(find.textContaining('In Misc'), findsOneWidget);
      await closeApp(tester, db);
    });

    testWidgets('switching months keeps the account', (tester) async {
      final ub = ids.accounts['UB']!;
      final router = await pumpApp(
        tester,
        db,
        location: '/budget/2026-11?account=$ub',
      );
      await tester.tap(find.byTooltip('Next month'));
      await tester.pumpAndSettle();
      expect(path(router), '/budget/2026-12?account=$ub');
      await closeApp(tester, db);
    });

    testWidgets('an unknown account falls back to everything', (tester) async {
      await pumpApp(tester, db, location: '/budget/2026-11?account=nope');
      expect(find.byKey(const Key('account-view')), findsNothing);
      expect(item('Rent'), findsOneWidget);
      await closeApp(tester, db);
    });
  });

  group('account chips (phone)', () {
    testWidgets('pick one account, then all again', (tester) async {
      await pumpApp(tester, db, size: phone);
      expect(find.byKey(const Key('side-nav')), findsNothing);
      final bpi = find.byKey(ValueKey('account-chip-${ids.accounts['BPI']}'));
      await tester.ensureVisible(bpi);
      await tester.pumpAndSettle();
      await tester.tap(bpi);
      await tester.pumpAndSettle();
      expect(item('QR'), findsOneWidget);
      expect(item('UB Loan'), findsNothing);
      expect(leftToPay(tester), '₱280.00');

      await tester.tap(find.byKey(const ValueKey('account-chip-all')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('account-view')), findsNothing);
      expect(leftToPay(tester), '₱15,576.26');
      await closeApp(tester, db);
    });
  });

  group('pinned left-to-pay bar', () {
    testWidgets('Unpaid shows only what is not paid yet', (tester) async {
      await pumpApp(tester, db);
      expect(find.text('Unpaid 5'), findsOneWidget);
      await tester.tap(find.byKey(const Key('filter-unpaid')));
      await tester.pumpAndSettle();
      expect(item('Rent'), findsNothing);
      expect(item('UB Loan'), findsOneWidget);
      expect(item('sleeve'), findsOneWidget);

      expect(find.text('5 shown · ₱15,576.26'), findsOneWidget);

      await tester.tap(find.byKey(const Key('filter-all')));
      await tester.pumpAndSettle();
      expect(item('Rent'), findsOneWidget);
      await closeApp(tester, db);
    });

    testWidgets('Charged shows only card charges with the bill unpaid', (
      tester,
    ) async {
      await BudgetRepository(db)
          .setStatus(ids.items['Electric']!, ItemStatus.charged);
      await pumpApp(tester, db);
      expect(find.text('Charged 1'), findsOneWidget);
      await tester.tap(find.byKey(const Key('filter-charged')));
      await tester.pumpAndSettle();
      expect(item('Electric'), findsOneWidget);
      expect(item('UB Loan'), findsNothing);
      await closeApp(tester, db);
    });

    testWidgets('counts only the selected account', (tester) async {
      await pumpApp(
        tester,
        db,
        location: '/budget/2026-11?account=${ids.accounts['UB']}',
      );
      expect(find.text('Unpaid 2'), findsOneWidget);
      expect(find.text('Planned 2'), findsOneWidget);
      await closeApp(tester, db);
    });

    testWidgets('stays visible while the list scrolls', (tester) async {
      await pumpApp(tester, db, size: const Size(400, 700));
      await tester.drag(find.byType(ListView).first, const Offset(0, -1500));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('stat-Left to pay')).hitTestable(),
        findsOneWidget,
      );
      await closeApp(tester, db);
    });
  });
}

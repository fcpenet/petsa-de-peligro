import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:petsa/core/db/database.dart';
import 'package:petsa/features/budget/data/budget_repository.dart';
import 'package:petsa/features/budget/domain/status_filter.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/november.dart';
import '../../helpers/test_db.dart';

final _t = DateTime(2026, 11, 1);

BudgetItem item(
  String id,
  ItemStatus status, {
  String? parent,
  bool collection = false,
}) => BudgetItem(
  id: id,
  updatedAt: _t,
  monthId: 'm',
  parentId: parent,
  accountId: 'ub',
  name: id,
  amountCents: 100,
  kind: ItemKind.expense,
  status: status,
  sortOrder: 0,
  isCollection: collection,
);

void main() {
  group('StatusFilter', () {
    final items = [
      item('rent', ItemStatus.paid),
      item('loan', ItemStatus.planned),
      item('misc', ItemStatus.planned, collection: true),
      item('a', ItemStatus.paid, parent: 'misc'),
      item('b', ItemStatus.planned, parent: 'misc'),
      item('gifts', ItemStatus.allotted, collection: true), // empty
    ];

    test('everything shows by default', () {
      final f = StatusFilter(items, ItemStatus.values.toSet());
      expect(f.isActive, isFalse);
      expect(items.where(f.matches), hasLength(items.length));
    });

    test('a collection shows when any sub-expense matches', () {
      final f = StatusFilter(items, {ItemStatus.paid});
      expect(f.isActive, isTrue);
      expect(f.matches(items[0]), isTrue); // rent
      expect(f.matches(items[1]), isFalse); // loan
      expect(f.matches(items[2]), isTrue); // misc, via a
      expect(f.childrenOf('misc').map((c) => c.id), ['a']);
      expect(f.matches(items[5]), isFalse); // empty, allotted
    });

    test('an empty collection uses its own status', () {
      final f = StatusFilter(items, {ItemStatus.allotted});
      expect(f.matches(items[5]), isTrue);
      expect(f.matches(items[2]), isFalse);
    });

    test('counts expenses, not collections', () {
      expect(StatusFilter.counts(items), {
        ItemStatus.planned: 2, // loan, b
        ItemStatus.allotted: 0,
        ItemStatus.charged: 0,
        ItemStatus.paid: 2, // rent, a
      });
    });
  });

  group('budget page', () {
    late AppDatabase db;
    late NovemberIds ids;

    setUp(() async {
      db = createTestDatabase();
      ids = await seedNovember(db);
      await BudgetRepository(db).allotAccount(ids.monthId, ids.accounts['UB']!);
    });

    Finder row(String name) => find.byKey(ValueKey('item-${ids.items[name]}'));

    testWidgets('picking a status shows only those, totals unchanged', (
      tester,
    ) async {
      await pumpApp(tester, db);
      expect(find.text('Planned 3'), findsOneWidget); // Electric, QR, sleeve
      expect(find.text('Allotted 2'), findsOneWidget);
      expect(find.text('Paid 4'), findsOneWidget);
      expect(find.text('Unpaid 5'), findsOneWidget);
      expect(find.byKey(const Key('filter-summary')), findsNothing);
      final left = tester
          .widget<Text>(find.byKey(const Key('stat-Left to pay')))
          .data;

      // Unpaid: only what's still to pay.
      await tester.tap(find.byKey(const Key('filter-unpaid')));
      await tester.pumpAndSettle();
      expect(row('Basic'), findsNothing);
      expect(row('Electric'), findsOneWidget);
      expect(row('dental pliers'), findsNothing); // paid sub-expense
      expect(row('sleeve'), findsOneWidget); // its planned sibling
      expect(find.byKey(ValueKey('collection-${ids.misc}')), findsOneWidget);
      expect(find.byKey(const Key('filter-summary')), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('stat-Left to pay'))).data,
        left,
      );

      // Only allotted: just UB's two, other accounts hidden.
      await tester.tap(find.byKey(const Key('filter-allotted')));
      await tester.pumpAndSettle();
      expect(row('UB Loan'), findsOneWidget);
      expect(row('Pru'), findsOneWidget);
      expect(row('Electric'), findsNothing);
      expect(
        find.byKey(ValueKey('account-section-${ids.accounts['BPI']}')),
        findsNothing,
      );
      expect(find.byKey(ValueKey('collection-${ids.misc}')), findsNothing);
      expect(find.text('2 shown · ₱9,000.00'), findsOneWidget);

      // Only paid.
      await tester.tap(find.byKey(const Key('filter-paid')));
      await tester.pumpAndSettle();
      expect(row('Basic'), findsOneWidget);
      expect(row('UB Loan'), findsNothing);

      await tester.tap(find.byKey(const Key('filter-all')));
      await tester.pumpAndSettle();
      expect(row('Basic'), findsOneWidget);
      expect(row('UB Loan'), findsOneWidget);
      expect(find.byKey(const Key('filter-summary')), findsNothing);
      await closeApp(tester, db);
    });

    testWidgets('the filter stays when switching months', (tester) async {
      await pumpApp(tester, db);
      await tester.tap(find.byKey(const Key('filter-unpaid')));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Previous month'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Next month'));
      await tester.pumpAndSettle();
      expect(row('Basic'), findsNothing);
      expect(row('Electric'), findsOneWidget);
      await closeApp(tester, db);
    });
  });
}

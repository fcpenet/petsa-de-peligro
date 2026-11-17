import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:petsa/core/db/database.dart';
import 'package:petsa/core/ui/adaptive.dart';
import 'package:petsa/features/accounts/data/account_repository.dart';
import 'package:petsa/features/budget/data/budget_repository.dart';
import 'package:petsa/features/sheet/domain/sheet_model.dart';

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

  Future<Finder> cellFor(CellField field, String itemId) async {
    final repo = BudgetRepository(db);
    final model = buildSheet(
      accounts: await AccountRepository(db).accounts(includeArchived: true),
      items: await repo.itemsFor(ids.monthId),
      incomes: await repo.incomesFor(ids.monthId),
    );
    final pos = model.find((c) => c.field == field && c.itemId == itemId)!;
    return find.byKey(ValueKey('cell-${pos.$1}-${pos.$2}'));
  }

  testWidgets('shows the month as a read-only spreadsheet', (tester) async {
    await pumpApp(
      tester,
      db,
      location: '/overview/2026-11',
      size: const Size(3200, 1400),
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('cell-0-0')),
        matching: find.text('Summary'),
      ),
      findsOneWidget,
    );
    expect(find.text('Electric'), findsOneWidget);
    expect(find.text('Paid?'), findsWidgets);
    expect(find.text('A'), findsOneWidget);
    // No editing affordances.
    expect(find.textContaining('+ Add'), findsNothing);
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(FloatingActionButton), findsNothing);
    await closeApp(tester, db);
  });

  testWidgets('tapping selects a cell and shows it in the fx bar', (
    tester,
  ) async {
    await pumpApp(
      tester,
      db,
      location: '/overview/2026-11',
      size: const Size(3200, 1400),
    );
    final cell = await cellFor(CellField.itemAmount, ids.items['UB Loan']!);
    await tester.tap(cell);
    await tester.pump();
    await tester.tap(cell);
    await tester.pump();
    expect(
      tester.widget<Text>(find.byKey(const Key('formula-content'))).data,
      '₱7,000.00',
    );
    expect(find.byType(TextField), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(
      tester.widget<Text>(find.byKey(const Key('formula-content'))).data,
      '₱2,000.00', // Pru
    );
    await closeApp(tester, db);
  });

  testWidgets('tapping a paid box does not change anything', (tester) async {
    await pumpApp(
      tester,
      db,
      location: '/overview/2026-11',
      size: const Size(3200, 1400),
    );
    await tester.tap(
      await cellFor(CellField.itemStatus, ids.items['Electric']!),
    );
    await tester.pumpAndSettle();
    expect(
      (await BudgetRepository(db).item(ids.items['Electric']!)).status,
      ItemStatus.planned,
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('formula-content'))).data,
      'Planned',
    );
    await closeApp(tester, db);
  });

  testWidgets('month arrows stay on the overview', (tester) async {
    await pumpApp(
      tester,
      db,
      location: '/overview/2026-11',
      size: const Size(3200, 1400),
    );
    await tester.tap(find.byTooltip('Next month'));
    await tester.pumpAndSettle();
    expect(find.text('December 2026'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('cell-0-0')),
        matching: find.text('Summary'),
      ),
      findsOneWidget,
    );
    await closeApp(tester, db);
  });

  group('month helpers', () {
    test('monthLabel', () {
      expect(monthLabel('2026-11'), 'November 2026');
      expect(monthLabel('2026-11', short: true), 'Nov 2026');
    });
    test('shiftMonth wraps years', () {
      expect(shiftMonth('2026-12', 1), '2027-01');
      expect(shiftMonth('2026-01', -1), '2025-12');
    });
    test('centsToInput', () {
      expect(centsToInput(700000), '7000');
      expect(centsToInput(29626), '296.26');
      expect(centsToInput(5), '0.05');
    });
  });
}

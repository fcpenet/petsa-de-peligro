import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:petsa/core/db/database.dart';
import 'package:petsa/features/accounts/data/account_repository.dart';
import 'package:petsa/features/budget/data/budget_repository.dart';
import 'package:petsa/features/sheet/domain/sheet_model.dart';

import '../../helpers/app_harness.dart';
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

  String stat(WidgetTester tester, String label) =>
      tester.widget<Text>(find.byKey(Key('stat-$label'))).data!;

  Finder inSection(String account, Finder finder) => find.descendant(
    of: find.byKey(ValueKey('account-section-${ids.accounts[account]}')),
    matching: finder,
  );

  testWidgets('allot an account with one tap', (tester) async {
    await pumpApp(tester, db);
    // Unpaid November items are planned: UB Loan 7,000 + Pru 2,000, etc.
    expect(stat(tester, 'To allot'), '₱15,576.26');
    expect(
      inSection('UB', find.text('₱9,000.00 still to move into UB')),
      findsOneWidget,
    );
    expect(inSection('UB', find.text('Planned')), findsNWidgets(2));

    await tester.tap(find.byKey(ValueKey('allot-${ids.accounts['UB']}')));
    await tester.pumpAndSettle();
    expect(
      (await repo.item(ids.items['UB Loan']!)).status,
      ItemStatus.allotted,
    );
    expect(find.text('Marked 2 expenses in UB as allotted'), findsOneWidget);
    expect(inSection('UB', find.text('Planned')), findsNothing);
    expect(find.byKey(ValueKey('allot-${ids.accounts['UB']}')), findsNothing);
    expect(stat(tester, 'To allot'), '₱6,576.26');
    // Still to pay.
    expect(stat(tester, 'Left to pay'), '₱15,576.26');
    await closeApp(tester, db);
  });

  testWidgets('the checkbox pays; unticking leaves it allotted', (
    tester,
  ) async {
    await pumpApp(tester, db);
    final pru = ids.items['Pru']!;
    await tester.tap(find.byKey(ValueKey('paid-$pru')));
    await tester.pumpAndSettle();
    expect((await repo.item(pru)).status, ItemStatus.paid);
    await tester.tap(find.byKey(ValueKey('paid-$pru')));
    await tester.pumpAndSettle();
    expect((await repo.item(pru)).status, ItemStatus.allotted);
    await closeApp(tester, db);
  });

  testWidgets('choose any status in the form', (tester) async {
    await pumpApp(tester, db);
    await tester.tap(find.byKey(ValueKey('item-${ids.items['QR']}')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.byKey(const Key('status-help'))).data,
      'Budgeted; the money isn’t in the account yet',
    );
    await tester.tap(find.byKey(const Key('status-allotted')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('field-paid-from')), findsNothing);
    await save(tester);
    expect((await repo.item(ids.items['QR']!)).status, ItemStatus.allotted);

    // New expenses start planned unless you pick otherwise.
    await tester.tap(find.byKey(const Key('add-expense')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('field-name')), 'Water');
    await tester.enterText(find.byKey(const Key('field-amount')), '500');
    await choose(tester, 'field-account', 'BPI');
    await save(tester);
    final water = (await repo.itemsFor(ids.monthId))
        .singleWhere((i) => i.name == 'Water');
    expect(water.status, ItemStatus.planned);
    await closeApp(tester, db);
  });

  test('the Overview shows what is left to allot', () async {
    addTearDown(db.close);
    await repo.allotAccount(ids.monthId, ids.accounts['UB']!);
    final model = buildSheet(
      accounts: await AccountRepository(db).accounts(),
      items: await repo.itemsFor(ids.monthId),
      incomes: await repo.incomesFor(ids.monthId),
    );
    final label = model.find((c) => c.text == 'To allot')!;
    expect(model.cell(label.$1, label.$2 + 1).cents, 657626);
    final loan = model.find(
      (c) =>
          c.field == CellField.itemStatus && c.itemId == ids.items['UB Loan'],
    )!;
    expect(model.cell(loan.$1, loan.$2).tooltip, 'Allotted');
  });
}

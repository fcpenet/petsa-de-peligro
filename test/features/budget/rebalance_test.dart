import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:petsa/core/db/database.dart';
import 'package:petsa/features/budget/data/budget_repository.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/november.dart';
import '../../helpers/test_db.dart';

void main() {
  late AppDatabase db;
  late NovemberIds ids;
  late BudgetRepository repo;
  late String rcbc;
  late String ub;
  late String electric;

  setUp(() async {
    db = createTestDatabase();
    ids = await seedNovember(db);
    repo = BudgetRepository(db);
    rcbc = ids.accounts['RCBC Card']!;
    ub = ids.accounts['UB']!;
    electric = ids.items['Electric']!;
  });

  Future<void> tapKey(WidgetTester tester, Key key) async {
    await tester.tap(find.byKey(key));
    await tester.pumpAndSettle();
  }

  Finder section(String accountId) =>
      find.byKey(ValueKey('account-section-$accountId'));

  Finder inSection(String accountId, String text) =>
      find.descendant(of: section(accountId), matching: find.text(text));

  testWidgets('pay from another account, then rebalance', (tester) async {
    await pumpApp(tester, db);
    expect(find.byKey(const Key('rebalance-card')), findsNothing);

    // Electric was planned on the RCBC Card but paid from UB.
    await tapKey(tester, ValueKey('item-$electric'));
    await tapKey(tester, const Key('status-paid'));
    expect(find.text('As planned (RCBC Card)'), findsOneWidget);
    await choose(tester, 'field-paid-from', 'UB');
    await save(tester);

    final item = await repo.item(electric);
    expect(item.status, ItemStatus.paid);
    expect(item.paidFromAccountId, ub);
    // Still listed under the RCBC Card, tagged with where it was paid.
    expect(
      find.descendant(
        of: section(rcbc),
        matching: find.textContaining('Paid from UB'),
      ),
      findsOneWidget,
    );
    expect(inSection(rcbc, 'All paid'), findsOneWidget);
    expect(
      find.descendant(
        of: section(rcbc),
        matching: find.textContaining('₱6,000.00 unused'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: section(ub),
        matching: find.textContaining('₱6,000.00 over'),
      ),
      findsOneWidget,
    );

    // The Rebalance card suggests the move.
    final card = find.byKey(const Key('rebalance-card'));
    expect(
      find.descendant(
        of: card,
        matching: find.text('Move ₱6,000.00 from RCBC Card → UB'),
      ),
      findsOneWidget,
    );
    await tapKey(tester, ValueKey('move-$rcbc-$ub'));

    final transfer = (await repo.transfersFor(ids.monthId)).single;
    expect(transfer.fromAccountId, rcbc);
    expect(transfer.toAccountId, ub);
    expect(transfer.amountCents, 600000);
    expect(card, findsNothing);
    expect(
      find.descendant(
        of: section(rcbc),
        matching: find.textContaining('unused'),
      ),
      findsNothing,
    );
    final transfers = find.byKey(const Key('transfers-section'));
    expect(
      find.descendant(of: transfers, matching: find.text('RCBC Card → UB')),
      findsOneWidget,
    );

    // Undo the transfer: the suggestion comes back.
    await tapKey(tester, ValueKey('transfer-${transfer.id}'));
    expect(find.text('Edit transfer'), findsOneWidget);
    await tapKey(tester, const Key('form-delete'));
    await tapKey(tester, const Key('confirm-delete'));
    expect(await repo.transfersFor(ids.monthId), isEmpty);
    expect(card, findsOneWidget);
    expect(transfers, findsNothing);
    await closeApp(tester, db);
  });

  testWidgets('"Not now" hides the suggestion until it changes', (
    tester,
  ) async {
    await repo.setStatus(electric, ItemStatus.paid, paidFromAccountId: ub);
    await pumpApp(tester, db);
    final card = find.byKey(const Key('rebalance-card'));
    expect(card, findsOneWidget);
    await tapKey(tester, const Key('rebalance-dismiss'));
    expect(card, findsNothing);

    // Another payment from the wrong account changes the suggestion.
    await repo.setStatus(
      ids.items['QR']!,
      ItemStatus.paid,
      paidFromAccountId: ub,
    );
    await tester.pumpAndSettle();
    expect(card, findsOneWidget);
    await closeApp(tester, db);
  });

  testWidgets('un-paying clears where it was paid from', (tester) async {
    await repo.setStatus(electric, ItemStatus.paid, paidFromAccountId: ub);
    await pumpApp(tester, db);
    expect(find.byKey(const Key('rebalance-card')), findsOneWidget);
    await tapKey(tester, ValueKey('paid-$electric'));
    expect((await repo.item(electric)).paidFromAccountId, isNull);
    expect(find.byKey(const Key('rebalance-card')), findsNothing);
    await closeApp(tester, db);
  });

  testWidgets('move money by hand from the add menu', (tester) async {
    await pumpApp(tester, db);
    await tapKey(tester, const Key('add-menu'));
    await tester.tap(find.text('Move money'));
    await tester.pumpAndSettle();
    await save(tester);
    expect(find.text('Choose an account'), findsNWidgets(2));

    await choose(tester, 'field-from', 'BPI');
    await choose(tester, 'field-to', 'BPI');
    await tester.enterText(find.byKey(const Key('field-amount')), '500');
    await save(tester);
    expect(find.text('Choose two different accounts'), findsWidgets);

    await choose(tester, 'field-to', 'Cash');
    await tester.enterText(find.byKey(const Key('field-note')), 'allowance');
    await save(tester);
    final t = (await repo.transfersFor(ids.monthId)).single;
    expect(t.fromAccountId, ids.accounts['BPI']);
    expect(t.toAccountId, ids.accounts['Cash']);
    expect(t.note, 'allowance');
    expect(find.textContaining('allowance'), findsOneWidget);
    // Nothing called for it, so the app suggests moving it back.
    expect(find.text('Move ₱500.00 from Cash → BPI'), findsOneWidget);
    await closeApp(tester, db);
  });

  testWidgets('works on a phone', (tester) async {
    await repo.setStatus(electric, ItemStatus.paid, paidFromAccountId: ub);
    await pumpApp(tester, db, size: phone);
    await tapKey(tester, ValueKey('move-$rcbc-$ub'));
    expect(await repo.transfersFor(ids.monthId), hasLength(1));
    await closeApp(tester, db);
  });
}

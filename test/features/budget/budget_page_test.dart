import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:petsa/core/db/database.dart';
import 'package:petsa/features/budget/data/budget_repository.dart';
import 'package:petsa/features/templates/data/template_repository.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/november.dart';
import '../../helpers/test_db.dart';

void main() {
  late AppDatabase db;
  late NovemberIds ids;
  late BudgetRepository repo;

  setUp(() async {
    db = createTestDatabase();
    repo = BudgetRepository(db);
    ids = await seedNovember(db);
  });

  Finder row(String name) => find.byKey(ValueKey('item-${ids.items[name]}'));

  String statText(WidgetTester tester, String label) =>
      tester.widget<Text>(find.byKey(Key('stat-$label'))).data!;

  testWidgets('shows totals, account sections, collections and income', (
    tester,
  ) async {
    await pumpApp(tester, db);

    expect(find.text('November 2026'), findsOneWidget);
    expect(statText(tester, 'Left to pay'), '₱15,576.26');
    expect(statText(tester, 'Expected income'), '₱242,122.23');
    expect(statText(tester, 'Unbudgeted'), '₱188,642.23');
    for (final name in ['UB', 'RCBC Card', 'BPI', 'JCB', 'Misc', 'Income']) {
      expect(find.text(name), findsWidgets, reason: name);
    }
    expect(find.text('Electric'), findsOneWidget);
    expect(find.text('₱9,000.00 left'), findsOneWidget); // UB
    // Misc is a collection inside Cash, with its sub-expenses below it.
    final cash = find.byKey(
      ValueKey('account-section-${ids.accounts['Cash']}'),
    );
    final misc = find.byKey(ValueKey('collection-${ids.misc}'));
    expect(find.descendant(of: cash, matching: misc), findsOneWidget);
    expect(
      find.descendant(of: misc, matching: row('dental pliers')),
      findsOneWidget,
    );
    expect(find.text('₱845.26 of ₱2,200.00 · 1/2 paid'), findsOneWidget);
    // dental pliers shows its own account; sleeve uses Misc's (Cash).
    expect(find.textContaining('JCB · Paid'), findsOneWidget);
    expect(find.text('₱296.26 left'), findsOneWidget); // Cash: just sleeve
    // No separate group sections any more.
    expect(find.byKey(ValueKey('group-section-${ids.misc}')), findsNothing);
    await closeApp(tester, db);
  });

  testWidgets('the checkbox marks an item paid', (tester) async {
    await pumpApp(tester, db);
    await tester.tap(find.byKey(ValueKey('paid-${ids.items['Electric']}')));
    await tester.pumpAndSettle();

    final electric = await repo.item(ids.items['Electric']!);
    expect(electric.status, ItemStatus.paid);
    expect(statText(tester, 'Left to pay'), '₱9,576.26');
    await closeApp(tester, db);
  });

  testWidgets('the collection checkbox pays every sub-expense', (tester) async {
    await pumpApp(tester, db);
    await tester.tap(find.byKey(ValueKey('paid-${ids.misc}')));
    await tester.pumpAndSettle();
    expect((await repo.item(ids.items['sleeve']!)).status, ItemStatus.paid);
    await closeApp(tester, db);
  });

  group('expense form', () {
    testWidgets('add an item to an account', (tester) async {
      await pumpApp(tester, db);
      await tester.tap(find.byKey(const Key('add-expense')));
      await tester.pumpAndSettle();
      expect(find.text('Add expense'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('field-name')), 'Fixitfoot');
      await tester.enterText(find.byKey(const Key('field-amount')), '13,920');
      await choose(tester, 'field-account', 'BPI');
      await save(tester);

      final added = (await repo.itemsFor(ids.monthId))
          .singleWhere((i) => i.name == 'Fixitfoot');
      expect(added.amountCents, php(13920));
      expect(added.accountId, ids.accounts['BPI']);
      expect(added.parentId, isNull);
      expect(find.text('Fixitfoot'), findsOneWidget);
      await closeApp(tester, db);
    });

    testWidgets('add a sub-expense to a collection', (tester) async {
      await pumpApp(tester, db);
      await tester.tap(find.byKey(const Key('add-expense')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('type-sub')));
      await tester.pumpAndSettle();
      // The only collection is picked automatically.
      expect(find.text('Misc'), findsWidgets);
      await tester.enterText(
        find.byKey(const Key('field-name')),
        'ashwagandha',
      );
      await tester.enterText(find.byKey(const Key('field-amount')), '819.18');
      await choose(tester, 'field-account', 'JCB');
      await save(tester);

      final added = (await repo.itemsFor(ids.monthId))
          .singleWhere((i) => i.name == 'ashwagandha');
      expect(added.parentId, ids.misc);
      expect(added.accountId, ids.accounts['JCB']);
      await closeApp(tester, db);
    });

    testWidgets('shows validation errors', (tester) async {
      await pumpApp(tester, db);
      await tester.tap(find.byKey(const Key('add-expense')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('field-amount')), 'abc');
      await save(tester);

      expect(find.text('Enter a name'), findsOneWidget);
      expect(find.text('Enter an amount like 1,250.50'), findsOneWidget);
      expect(find.text('Choose an account'), findsOneWidget);
      expect(find.text('Add expense'), findsOneWidget); // still open
      await closeApp(tester, db);
    });

    testWidgets('"Add to UB" starts with the account filled in', (
      tester,
    ) async {
      await pumpApp(tester, db);
      await tester.tap(find.byKey(ValueKey('add-to-${ids.accounts['UB']}')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('field-name')), 'Phone');
      await tester.enterText(find.byKey(const Key('field-amount')), '1082');
      await save(tester);

      final phoneBill = (await repo.itemsFor(ids.monthId))
          .singleWhere((i) => i.name == 'Phone');
      expect(phoneBill.accountId, ids.accounts['UB']);
      await closeApp(tester, db);
    });

    testWidgets('"Add to Misc" starts as a sub-expense of Misc', (
      tester,
    ) async {
      await pumpApp(tester, db);
      await tester.tap(find.byKey(ValueKey('add-to-${ids.misc}')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('field-name')), 'tiktok');
      await tester.enterText(find.byKey(const Key('field-amount')), '72.28');
      await save(tester);

      final added = (await repo.itemsFor(ids.monthId))
          .singleWhere((i) => i.name == 'tiktok');
      expect(added.parentId, ids.misc);
      // "Same as Misc": counts toward Cash.
      expect(added.accountId, isNull);
      expect(find.text('₱368.54 left'), findsOneWidget); // 296.26 + 72.28
      await closeApp(tester, db);
    });

    testWidgets('edit an amount', (tester) async {
      await pumpApp(tester, db);
      await tester.tap(row('UB Loan'));
      await tester.pumpAndSettle();
      expect(find.text('Edit expense'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, '7000'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('field-amount')), '6,500.50');
      await save(tester);
      expect((await repo.item(ids.items['UB Loan']!)).amountCents, 650050);
      expect(find.text('₱6,500.50'), findsOneWidget);
      await closeApp(tester, db);
    });

    testWidgets('move a sub-expense out of its collection', (tester) async {
      await pumpApp(tester, db);
      await tester.tap(row('sleeve'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('type-item')));
      await tester.pumpAndSettle();
      await save(tester);

      final sleeve = await repo.item(ids.items['sleeve']!);
      expect(sleeve.parentId, isNull);
      expect(sleeve.accountId, ids.accounts['Cash']);
      // Misc's only remaining sub-expense is paid, so Misc is now paid.
      expect((await repo.item(ids.misc)).status, ItemStatus.paid);
      await closeApp(tester, db);
    });

    testWidgets('mark paid from the form', (tester) async {
      await pumpApp(tester, db);
      await tester.tap(row('QR'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('status-paid')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Paid on '), findsOneWidget);
      await save(tester);

      final qr = await repo.item(ids.items['QR']!);
      expect(qr.status, ItemStatus.paid);
      expect(qr.paidAt, isNotNull);
      await closeApp(tester, db);
    });

    testWidgets('kind, due day and note are saved and shown', (tester) async {
      await pumpApp(tester, db);
      await tester.tap(row('Pru'));
      await tester.pumpAndSettle();
      await choose(tester, 'field-kind', 'Savings');
      await tester.enterText(find.byKey(const Key('field-due')), '15');
      await tester.enterText(find.byKey(const Key('field-note')), 'insurance');
      await save(tester);

      final pru = await repo.item(ids.items['Pru']!);
      expect(pru.kind, ItemKind.savings);
      expect(pru.dueDay, 15);
      expect(pru.note, 'insurance');
      expect(
        find.text('Savings · Planned · Due on the 15th · insurance'),
        findsOneWidget,
      );
      await closeApp(tester, db);
    });

    testWidgets('delete from the form', (tester) async {
      await pumpApp(tester, db);
      await tester.tap(row('QR'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('form-delete')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm-delete')));
      await tester.pumpAndSettle();

      expect(
        (await repo.itemsFor(ids.monthId)).where((i) => i.name == 'QR'),
        isEmpty,
      );
      expect(find.text('QR'), findsNothing);
      await closeApp(tester, db);
    });
  });

  group('collections', () {
    testWidgets('there is no root-level collection button', (tester) async {
      await pumpApp(tester, db);
      await tester.tap(find.byKey(const Key('add-menu')));
      await tester.pumpAndSettle();
      expect(find.text('Add account'), findsOneWidget); // menu is open
      expect(find.text('Add collection'), findsNothing);
      await closeApp(tester, db);
    });

    testWidgets('a collection can have no account', (tester) async {
      await pumpApp(tester, db);
      await tester.tap(find.byKey(const Key('add-expense')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('field-collection')));
      await tester.pumpAndSettle();
      expect(find.text('Add collection'), findsOneWidget);
      expect(find.text('Budget (optional)'), findsOneWidget);
      expect(find.text('Account (optional)'), findsOneWidget);
      expect(find.byKey(const Key('field-status')), findsNothing);
      await tester.enterText(find.byKey(const Key('field-name')), 'Gifts');
      await tester.enterText(find.byKey(const Key('field-amount')), '3000');
      await save(tester);

      final gifts = (await repo.itemsFor(ids.monthId))
          .singleWhere((i) => i.name == 'Gifts');
      expect(gifts.isCollection, isTrue);
      expect(gifts.amountCents, php(3000));
      expect(gifts.accountId, isNull);
      // Listed in the Collections card, not as a problem.
      final card = find.byKey(const ValueKey('collections-section'));
      expect(
        find.descendant(of: card, matching: find.text('Add to Gifts')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('account-section-none')), findsNothing);
      // The empty budget is set aside, but isn't "left to pay" anywhere.
      expect(statText(tester, 'Expenses'), '₱56,480.00');
      expect(statText(tester, 'Left to pay'), '₱15,576.26');

      // Its sub-expenses must say what paid for them.
      await tester.tap(find.byKey(ValueKey('add-to-${gifts.id}')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('field-name')), 'mug');
      await tester.enterText(find.byKey(const Key('field-amount')), '450');
      await save(tester);
      expect(find.text('Choose an account'), findsOneWidget);
      await choose(tester, 'field-account', 'JCB');
      await save(tester);
      final mug = (await repo.itemsFor(ids.monthId))
          .singleWhere((i) => i.name == 'mug');
      expect(mug.parentId, gifts.id);
      expect(mug.accountId, ids.accounts['JCB']);
      expect(
        find.descendant(of: card, matching: find.textContaining('JCB')),
        findsOneWidget,
      );
      await closeApp(tester, db);
    });

    testWidgets('a collection can also live in an account', (tester) async {
      await pumpApp(tester, db);
      await tester.tap(find.byKey(ValueKey('add-to-${ids.accounts['BPI']}')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('field-collection')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('field-name')), 'Gifts');
      await save(tester);
      final bpi = find.byKey(
        ValueKey('account-section-${ids.accounts['BPI']}'),
      );
      expect(
        find.descendant(of: bpi, matching: find.text('Add to Gifts')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('collections-section')), findsNothing);
      await closeApp(tester, db);
    });

    testWidgets('turn an expense into a collection and add to it', (
      tester,
    ) async {
      await pumpApp(tester, db);
      await tester.tap(row('QR'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('field-collection')));
      await tester.pumpAndSettle();
      expect(find.text('Edit collection'), findsOneWidget);
      await save(tester);
      expect((await repo.item(ids.items['QR']!)).isCollection, isTrue);

      await tester.tap(find.byKey(ValueKey('add-to-${ids.items['QR']}')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('field-name')), 'gcash qr');
      await tester.enterText(find.byKey(const Key('field-amount')), '100');
      await save(tester);
      final child = (await repo.itemsFor(ids.monthId))
          .singleWhere((i) => i.name == 'gcash qr');
      expect(child.parentId, ids.items['QR']);
      await closeApp(tester, db);
    });

    testWidgets('a collection with sub-expenses stays a collection', (
      tester,
    ) async {
      await pumpApp(tester, db);
      await tester.tap(find.byKey(ValueKey('item-${ids.misc}')));
      await tester.pumpAndSettle();
      expect(find.text('Edit collection'), findsOneWidget);
      expect(find.text('Has 2 sub-expenses'), findsOneWidget);
      final toggle = tester.widget<SwitchListTile>(
        find.byKey(const Key('field-collection')),
      );
      expect(toggle.onChanged, isNull);
      // It can't become a sub-expense either.
      await tester.tap(find.byKey(const Key('type-sub')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('field-parent')), findsNothing);
      await closeApp(tester, db);
    });

    testWidgets('edit a collection budget by tapping it', (tester) async {
      await pumpApp(tester, db);
      await tester.tap(find.byKey(ValueKey('item-${ids.misc}')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('field-amount')), '500');
      await save(tester);
      expect((await repo.item(ids.misc)).amountCents, php(500));
      expect(find.text('₱345.26 over'), findsOneWidget);
      await closeApp(tester, db);
    });

    testWidgets('deleting a collection warns about its sub-expenses', (
      tester,
    ) async {
      await pumpApp(tester, db);
      await tester.tap(find.byKey(ValueKey('item-${ids.misc}')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('form-delete')));
      await tester.pumpAndSettle();
      expect(
        find.text('Its 2 sub-expenses will be deleted too.'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('confirm-delete')));
      await tester.pumpAndSettle();
      expect(
        (await repo.itemsFor(ids.monthId))
            .where((i) => i.id == ids.misc || i.parentId == ids.misc),
        isEmpty,
      );
      await closeApp(tester, db);
    });

    testWidgets('old expenses without an account are listed until fixed', (
      tester,
    ) async {
      // Only old data can be a plain expense with no account.
      final stray = await repo.addItem(
        monthId: ids.monthId,
        name: 'Stray',
        amountCents: php(10),
      );
      await pumpApp(tester, db);
      final none = find.byKey(const ValueKey('account-section-none'));
      expect(
        find.descendant(of: none, matching: find.text('Stray')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(ValueKey('item-$stray')));
      await tester.pumpAndSettle();
      await choose(tester, 'field-account', 'UB');
      await save(tester);
      expect(none, findsNothing);
      expect((await repo.item(stray)).accountId, ids.accounts['UB']);
      await closeApp(tester, db);
    });
  });

  group('income form', () {
    testWidgets('add and edit income', (tester) async {
      await pumpApp(tester, db);
      await tester.tap(find.byKey(const Key('add-income')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('field-name')), '13th month');
      await tester.enterText(find.byKey(const Key('field-amount')), '50000');
      await save(tester);
      expect(statText(tester, 'Expected income'), '₱292,122.23');

      await tester.tap(find.byKey(ValueKey('income-${ids.salary}')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('field-amount')), '240000');
      await save(tester);
      expect(
        (await repo.incomesFor(ids.monthId))
            .singleWhere((i) => i.id == ids.salary)
            .amountCents,
        php(240000),
      );
      await closeApp(tester, db);
    });
  });

  group('templates', () {
    testWidgets('save a template, then start December from it', (tester) async {
      await pumpApp(tester, db);
      await tester.tap(find.byKey(const Key('templates-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('save-template')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('template-name')), 'Monthly');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();
      expect(find.text('Saved template “Monthly”'), findsOneWidget);
      expect((await TemplateRepository(db).templates()).single.name, 'Monthly');

      await tester.tap(find.byTooltip('Next month'));
      await tester.pumpAndSettle();
      expect(find.text('December 2026 is empty'), findsOneWidget);
      await tester.tap(find.byKey(const Key('use-template-Monthly')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('empty-month-banner')), findsNothing);
      expect(find.text('Electric'), findsOneWidget);
      expect(find.text('dental pliers'), findsNothing);
      await closeApp(tester, db);
    });

    testWidgets('copy the previous month', (tester) async {
      await pumpApp(tester, db, location: '/budget/2026-12');
      await tester.tap(find.byKey(const Key('copy-previous')));
      await tester.pumpAndSettle();
      expect(find.text('Electric'), findsOneWidget);
      expect(find.textContaining('Copied'), findsOneWidget);
      await closeApp(tester, db);
    });
  });

  testWidgets('on a phone, forms open as bottom sheets', (tester) async {
    await pumpApp(tester, db, size: phone);
    expect(find.byType(NavigationBar), findsOneWidget);
    await tester.tap(find.byKey(const Key('add-expense')));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
    await tester.enterText(find.byKey(const Key('field-name')), 'Water');
    await tester.enterText(find.byKey(const Key('field-amount')), '600');
    await choose(tester, 'field-account', 'BPI');
    await save(tester);
    expect(find.byType(BottomSheet), findsNothing);
    expect(
      (await repo.itemsFor(ids.monthId)).where((i) => i.name == 'Water'),
      hasLength(1),
    );
    await closeApp(tester, db);
  });
}

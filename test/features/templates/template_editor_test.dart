import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:petsa/core/db/database.dart';
import 'package:petsa/features/budget/data/budget_repository.dart';
import 'package:petsa/features/templates/data/template_repository.dart';
import 'package:petsa/features/templates/domain/month_template.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/november.dart';
import '../../helpers/test_db.dart';

void main() {
  late AppDatabase db;
  late NovemberIds ids;
  late TemplateRepository repo;

  setUp(() async {
    db = createTestDatabase();
    ids = await seedNovember(db);
    repo = TemplateRepository(db);
  });

  Future<void> tapKey(WidgetTester tester, String key) async {
    await tester.tap(find.byKey(Key(key)));
    await tester.pumpAndSettle();
  }

  Future<void> fillItem(
    WidgetTester tester,
    String name,
    String amount, {
    String? account,
  }) async {
    await tester.enterText(find.byKey(const Key('field-name')), name);
    await tester.enterText(find.byKey(const Key('field-amount')), amount);
    if (account != null) await choose(tester, 'field-account', account);
  }

  Future<MonthTemplate> savedTemplate(String name) async {
    final row = (await repo.templates()).singleWhere((t) => t.name == name);
    return MonthTemplate.decode(row.payload);
  }

  testWidgets('Templates is in the navigation and starts empty', (
    tester,
  ) async {
    await pumpApp(tester, db);
    await tapKey(tester, 'nav-templates');
    expect(find.textContaining('No templates yet'), findsOneWidget);
    await closeApp(tester, db);
  });

  testWidgets('build a template from scratch and start a month from it', (
    tester,
  ) async {
    final router = await pumpApp(tester, db, location: '/templates');
    await tapKey(tester, 'new-template');
    expect(find.text('New template'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('template-name')), 'Lean');

    // An item paid from BPI.
    await tapKey(tester, 'add-expense');
    await fillItem(tester, 'Rent', '25000', account: 'BPI');
    await tester.enterText(find.byKey(const Key('field-due')), '5');
    await save(tester);

    // A collection in Cash with a sub-expense paid by card.
    await tapKey(tester, 'add-collection');
    expect(find.text('Budget (optional)'), findsOneWidget);
    await fillItem(tester, 'Misc', '2000', account: 'Cash');
    await save(tester);
    await tapKey(tester, 'add-to-collection-1');
    expect(find.text('Sub-expense'), findsOneWidget);
    await fillItem(tester, 'Coffee', '300', account: 'JCB');
    await save(tester);
    final cash = find.byKey(
      ValueKey('template-account-${ids.accounts['Cash']}'),
    );
    expect(
      find.descendant(of: cash, matching: find.text('Coffee')),
      findsOneWidget,
    );
    expect(find.text('JCB'), findsOneWidget); // paid from another account

    // Income.
    await tapKey(tester, 'add-income');
    await tester.enterText(find.byKey(const Key('field-amount')), '30000');
    await save(tester);

    String stat(String label) => tester
        .widgetList<Text>(
          find.descendant(
            of: find.byKey(Key('template-stat-$label')),
            matching: find.byType(Text),
          ),
        )
        .last
        .data!;
    expect(stat('Income'), '₱30,000.00');
    expect(stat('Expenses'), '₱27,000.00');
    expect(stat('Unallotted'), '₱3,000.00');
    expect(find.text('Due on the 5'), findsOneWidget);

    await tapKey(tester, 'template-save');
    expect(router.routerDelegate.currentConfiguration.uri.path, '/templates');
    expect(find.text('Lean'), findsOneWidget);

    final t = await savedTemplate('Lean');
    expect(t.items.map((i) => i.name), ['Rent', 'Misc']);
    expect(t.items[0].accountId, ids.accounts['BPI']);
    expect(t.items[0].dueDay, 5);
    expect(t.items[1].isCollection, isTrue);
    expect(t.items[1].accountId, ids.accounts['Cash']);
    expect(t.items[1].children.single.name, 'Coffee');
    expect(t.incomes.single.amountCents, 3000000);

    // December is empty: the banner offers the new template.
    router.go('/budget/2026-12');
    await tester.pumpAndSettle();
    await tapKey(tester, 'use-template-Lean');
    final dec = await BudgetRepository(db).findMonth('2026-12');
    expect(await BudgetRepository(db).itemsFor(dec!.id), hasLength(3));
    await closeApp(tester, db);
  });

  testWidgets('needs a name and at least one entry', (tester) async {
    await pumpApp(tester, db, location: '/templates/new');
    await tapKey(tester, 'template-save');
    expect(find.text('Give the template a name'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('template-name')), 'Empty');
    await tapKey(tester, 'template-save');
    expect(find.text('Add at least one expense or income'), findsOneWidget);
    expect(await repo.templates(), isEmpty);
    await closeApp(tester, db);
  });

  testWidgets('a name already in use is rejected', (tester) async {
    await repo.saveFromMonth(monthId: ids.monthId, name: 'Monthly');
    await pumpApp(tester, db, location: '/templates/new');
    await tester.enterText(find.byKey(const Key('template-name')), 'monthly');
    await tapKey(tester, 'add-income');
    await tester.enterText(find.byKey(const Key('field-amount')), '1');
    await save(tester);
    await tapKey(tester, 'template-save');
    expect(find.textContaining('already a template named'), findsOneWidget);
    expect(await repo.templates(), hasLength(1));
    await closeApp(tester, db);
  });

  testWidgets('edit a saved template: move, change and delete entries', (
    tester,
  ) async {
    final id = await repo.saveFromMonth(monthId: ids.monthId, name: 'Monthly');
    await pumpApp(tester, db, location: '/templates');
    await tester.tap(find.byKey(ValueKey('template-$id')));
    await tester.pumpAndSettle();
    expect(find.text('Edit template'), findsOneWidget);

    var t = await savedTemplate('Monthly');
    final qr = t.items.indexWhere((i) => i.name == 'QR');
    final pru = t.items.indexWhere((i) => i.name == 'Pru');

    // Move QR into Misc.
    await tapKey(tester, 'template-item-$qr-null');
    await tapKey(tester, 'type-sub');
    await save(tester);

    // Change Pru's amount.
    await tapKey(tester, 'template-item-$pru-null');
    await tester.enterText(find.byKey(const Key('field-amount')), '2500');
    await save(tester);

    // Delete Electric.
    await tester.tap(find.text('Electric'));
    await tester.pumpAndSettle();
    await tapKey(tester, 'form-delete');
    await tapKey(tester, 'confirm-delete');

    await tester.enterText(find.byKey(const Key('template-name')), 'Usual');
    await tapKey(tester, 'template-save');

    t = await savedTemplate('Usual');
    final names = t.items.map((i) => i.name);
    expect(names, isNot(contains('QR')));
    expect(names, isNot(contains('Electric')));
    expect(
      t.items.singleWhere((i) => i.name == 'Misc').children.single.name,
      'QR',
    );
    expect(t.items.singleWhere((i) => i.name == 'Pru').amountCents, 250000);
    expect(await repo.templates(), hasLength(1));
    await closeApp(tester, db);
  });

  testWidgets('leaving with unsaved changes asks first', (tester) async {
    await pumpApp(tester, db, location: '/templates');
    await tapKey(tester, 'new-template');
    await tester.enterText(find.byKey(const Key('template-name')), 'Draft');
    await tester.pumpAndSettle();

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Discard changes?'), findsOneWidget);
    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(find.text('New template'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tapKey(tester, 'confirm-discard');
    expect(find.text('New template'), findsNothing);
    expect(find.textContaining('No templates yet'), findsOneWidget);
    await closeApp(tester, db);
  });

  testWidgets('delete a template from the editor', (tester) async {
    final id = await repo.saveFromMonth(monthId: ids.monthId, name: 'Monthly');
    await pumpApp(tester, db, location: '/templates');
    await tester.tap(find.byKey(ValueKey('template-$id')));
    await tester.pumpAndSettle();
    await tapKey(tester, 'template-delete');
    await tapKey(tester, 'confirm-delete');
    expect(await repo.templates(), isEmpty);
    expect(find.textContaining('No templates yet'), findsOneWidget);
    await closeApp(tester, db);
  });

  testWidgets('works on a phone with bottom-sheet forms', (tester) async {
    await pumpApp(tester, db, location: '/templates/new', size: phone);
    await tester.enterText(find.byKey(const Key('template-name')), 'Phone');
    await tapKey(tester, 'add-expense');
    expect(find.byType(BottomSheet), findsOneWidget);
    await fillItem(tester, 'Load', '500', account: 'Cash');
    await save(tester);
    await tapKey(tester, 'template-save');
    expect((await savedTemplate('Phone')).items.single.name, 'Load');
    await closeApp(tester, db);
  });

  testWidgets('the Budget templates menu links to the editor', (tester) async {
    final router = await pumpApp(tester, db);
    await tapKey(tester, 'templates-menu');
    await tapKey(tester, 'new-template');
    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      '/templates/new',
    );
    await closeApp(tester, db);
  });
}

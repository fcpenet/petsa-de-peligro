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
    ids = await seedNovember(db);
    repo = BudgetRepository(db);
    // Fill in the rest of November: a top-up and a transfer.
    await repo.addTopUp(
      incomeId: ids.salary,
      amountCents: 100,
      receivedAt: DateTime(2026, 11, 15),
    );
    await repo.addTransfer(
      monthId: ids.monthId,
      fromAccountId: ids.accounts['UB']!,
      toAccountId: ids.accounts['Cash']!,
      amountCents: 100,
      transferredAt: DateTime(2026, 11, 15),
    );
  });

  group('repository', () {
    tearDown(() => db.close());

    test('clears everything in the month and nothing else', () async {
      final december = (await repo.ensureMonth('2026-12')).id;
      final rent = await repo.addItem(
        monthId: december,
        name: 'Rent',
        amountCents: 1,
        accountId: ids.accounts['BPI'],
      );

      await repo.clearMonth(ids.monthId);
      expect(await repo.itemsFor(ids.monthId), isEmpty);
      expect(await repo.incomesFor(ids.monthId), isEmpty);
      expect(await repo.topUpsFor(ids.monthId), isEmpty);
      expect(await repo.transfersFor(ids.monthId), isEmpty);
      final totals = await repo.totalsFor(ids.monthId);
      expect(totals.allottedCents, 0);
      expect(totals.incomeCents, 0);
      // The month itself is still there, empty, and so is December.
      expect((await repo.findMonth('2026-11'))?.id, ids.monthId);
      expect((await repo.itemsFor(december)).single.id, rent);
    });

    test('a cleared month can be filled from a template again', () async {
      final templates = TemplateRepository(db);
      final id = await templates.saveFromMonth(
        monthId: ids.monthId,
        name: 'Monthly',
      );
      final before = (await repo.itemsFor(ids.monthId))
          .where((i) => i.parentId == null)
          .length;
      await repo.clearMonth(ids.monthId);
      final created = await templates.applyTemplate(
        templateId: id,
        monthId: ids.monthId,
      );
      expect(created, before);
      final items = await repo.itemsFor(ids.monthId);
      expect(items.every((i) => i.status == ItemStatus.planned), isTrue);
    });
  });

  group('budget page', () {
    Future<void> openMenu(WidgetTester tester) async {
      await tester.tap(find.byKey(const Key('templates-menu')));
      await tester.pumpAndSettle();
    }

    testWidgets('delete the month, then start again from scratch', (
      tester,
    ) async {
      await pumpApp(tester, db);
      await openMenu(tester);
      await tester.tap(find.byKey(const Key('clear-month')));
      await tester.pumpAndSettle();
      expect(find.text('Delete everything in November 2026?'), findsOneWidget);
      expect(
        find.textContaining('Deletes 10 expenses and 1 income'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('confirm-delete')));
      await tester.pumpAndSettle();

      expect(await repo.itemsFor(ids.monthId), isEmpty);
      expect(find.byKey(const Key('empty-month-banner')), findsOneWidget);
      expect(find.text('Electric'), findsNothing);

      // Let the "Cleared" message go away, then start from scratch.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('add-expense')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('field-name')), 'Rent');
      await tester.enterText(find.byKey(const Key('field-amount')), '25000');
      await choose(tester, 'field-account', 'BPI');
      await save(tester);
      expect((await repo.itemsFor(ids.monthId)).single.name, 'Rent');
      expect(find.byKey(const Key('empty-month-banner')), findsNothing);
      await closeApp(tester, db);
    });

    testWidgets('cancelling keeps everything', (tester) async {
      await pumpApp(tester, db);
      await openMenu(tester);
      await tester.tap(find.byKey(const Key('clear-month')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(await repo.itemsFor(ids.monthId), hasLength(10));
      expect(find.text('Electric'), findsOneWidget);
      await closeApp(tester, db);
    });

    testWidgets('an empty month has nothing to delete', (tester) async {
      await pumpApp(tester, db, location: '/budget/2026-12');
      await openMenu(tester);
      final item = tester.widget<PopupMenuItem<String>>(
        find.byKey(const Key('clear-month')),
      );
      expect(item.enabled, isFalse);
      await closeApp(tester, db);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:petsa/core/db/database.dart';
import 'package:petsa/features/accounts/data/account_repository.dart';
import 'package:petsa/features/budget/data/budget_repository.dart';
import 'package:petsa/features/summary/domain/account_summary.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/november.dart';
import '../../helpers/test_db.dart';

void main() {
  late AppDatabase db;
  late NovemberIds ids;
  late BudgetRepository repo;
  late String electric; // planned on the RCBC Card
  late String rcbc;

  setUp(() async {
    db = createTestDatabase();
    ids = await seedNovember(db);
    repo = BudgetRepository(db);
    electric = ids.items['Electric']!;
    rcbc = ids.accounts['RCBC Card']!;
  });

  Checkbox box(WidgetTester tester, String id) =>
      tester.widget<Checkbox>(find.byKey(ValueKey('paid-$id')));

  testWidgets('a card expense goes charged, then paid', (tester) async {
    await pumpApp(tester, db);
    expect(box(tester, electric).value, isFalse);

    await tester.tap(find.byKey(ValueKey('paid-$electric')));
    await tester.pumpAndSettle();
    expect((await repo.item(electric)).status, ItemStatus.charged);
    expect(box(tester, electric).value, isNull); // dash
    expect(find.textContaining('Charged '), findsWidgets);
    expect(
      tester.widget<Text>(find.byKey(const Key('stat-Card bills'))).data,
      '₱6,000.00',
    );
    expect(find.text('₱6,000.00 charged, bill not paid yet'), findsOneWidget);
    // Still left to pay.
    expect(
      tester.widget<Text>(find.byKey(const Key('stat-Left to pay'))).data,
      '₱15,576.26',
    );

    await tester.tap(find.byKey(ValueKey('paid-$electric')));
    await tester.pumpAndSettle();
    expect((await repo.item(electric)).status, ItemStatus.paid);
    expect(box(tester, electric).value, isTrue);
    expect(find.byKey(const Key('stat-Card bills')), findsNothing);

    // Unticking a paid card expense leaves it charged.
    await tester.tap(find.byKey(ValueKey('paid-$electric')));
    await tester.pumpAndSettle();
    expect((await repo.item(electric)).status, ItemStatus.charged);
    await closeApp(tester, db);
  });

  testWidgets('Pay bill settles everything charged on the card', (
    tester,
  ) async {
    await repo.setStatus(electric, ItemStatus.charged);
    await pumpApp(tester, db);
    await tester.tap(find.byKey(ValueKey('settle-$rcbc')));
    await tester.pumpAndSettle();
    expect((await repo.item(electric)).status, ItemStatus.paid);
    expect(find.text('Paid the RCBC Card bill: 1 expense'), findsOneWidget);
    expect(find.byKey(ValueKey('settle-$rcbc')), findsNothing);
    await closeApp(tester, db);
  });

  testWidgets('non-card expenses never show Charged', (tester) async {
    await pumpApp(tester, db);
    // A bank expense: three statuses, checkbox pays directly.
    await tester.tap(find.byKey(ValueKey('item-${ids.items['QR']}')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('status-charged')), findsNothing);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    // A card expense offers it, with a charge date.
    await tester.tap(find.byKey(ValueKey('item-$electric')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('status-charged')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('field-charged-date')), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('status-help'))).data,
      startsWith('Charged on '),
    );
    // Switching to a bank account drops back to Allotted.
    await choose(tester, 'field-account', 'BPI');
    expect(find.byKey(const Key('status-charged')), findsNothing);
    await save(tester);
    final item = await repo.item(electric);
    expect(item.accountId, ids.accounts['BPI']);
    expect(item.status, ItemStatus.allotted);
    await closeApp(tester, db);
  });

  testWidgets('filter by Charged', (tester) async {
    await repo.setStatus(electric, ItemStatus.charged);
    await pumpApp(tester, db);
    expect(find.text('Charged (1)'), findsOneWidget);
    for (final s in ['planned', 'allotted', 'paid']) {
      await tester.tap(find.byKey(Key('filter-$s')));
      await tester.pumpAndSettle();
    }
    expect(find.byKey(ValueKey('item-$electric')), findsOneWidget);
    expect(find.byKey(ValueKey('item-${ids.items['Cats']}')), findsNothing);
    await closeApp(tester, db);
  });

  group('summary', () {
    tearDown(() => db.close());

    test('cards split charged (to settle) from not charged yet', () async {
      await repo.setStatus(
        electric,
        ItemStatus.charged,
        chargedAt: DateTime(2026, 11, 9),
      );
      final accounts = await AccountRepository(db).accounts();
      final month = summarizeMonth(
        accounts: accounts,
        items: await repo.itemsFor(ids.monthId),
      );
      final card = month.cards.accounts.first;
      expect(card.chargedCents, 600000);
      expect(card.notChargedCents, 0);
      expect(card.leftCents, 600000);
      expect(month.cards.chargedCents, 600000);

      // In a date range it counts on the charge date.
      final rows = await repo.itemsBetween(
        DateTime(2026, 11, 9),
        DateTime(2026, 11, 9),
      );
      final range = summarizeRange(
        accounts: accounts,
        items: [for (final (i, _) in rows) i],
        yearMonthOf: {for (final (i, ym) in rows) i.monthId: ym},
        range: (from: DateTime(2026, 11, 9), to: DateTime(2026, 11, 9)),
      );
      expect(range.cards.accounts.single.items.single.name, 'Electric');
    });
  });
}

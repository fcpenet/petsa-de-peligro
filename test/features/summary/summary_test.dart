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

  setUp(() async {
    db = createTestDatabase();
    ids = await seedNovember(db);
    repo = BudgetRepository(db);
    await repo.allotAccount(ids.monthId, ids.accounts['UB']!);
  });

  Future<MonthSummary> summarize() async => summarizeMonth(
    accounts: await AccountRepository(db).accounts(includeArchived: true),
    items: await repo.itemsFor(ids.monthId),
    transfers: await repo.transfersFor(ids.monthId),
  );

  group('summarizeMonth', () {
    tearDown(() => db.close());

    test('splits accounts from credit cards', () async {
      final s = await summarize();
      expect(s.accounts.accounts.map((a) => a.account.name), [
        'Cash',
        'UB',
        'BPI',
      ]);
      expect(s.cards.accounts.map((a) => a.account.name), ['RCBC Card', 'JCB']);
      expect(s.hiddenCount, 0);
    });

    test('per-account figures follow the statuses', () async {
      final s = await summarize();
      final ub = s.accounts.accounts.singleWhere((a) => a.account.name == 'UB');
      expect(ub.budgetedCents, php(9000));
      expect(ub.allottedCents, php(9000));
      expect(ub.plannedCents, 0);
      expect(ub.paidCents, 0);
      expect(ub.leftCents, php(9000));

      // Cash: Basic paid + Misc's sleeve (planned, uses Cash).
      final cash = s.accounts.accounts.first;
      expect(cash.budgetedCents, php(8296.26));
      expect(cash.paidCents, php(8000));
      expect(cash.plannedCents, php(296.26));
      expect(cash.items.map((i) => i.name), ['Basic', 'sleeve']);
      expect(cash.progress, closeTo(8000 / 8296.26, 1e-9));

      // JCB only has the paid Misc purchase.
      final jcb = s.cards.accounts.last;
      expect(jcb.items.single.name, 'dental pliers');
      expect(jcb.leftCents, 0);
    });

    test('group totals add up their accounts', () async {
      final s = await summarize();
      expect(s.cards.budgetedCents, php(3000 + 6000 + 549));
      expect(s.cards.paidCents, php(3000 + 549));
      expect(s.cards.leftCents, php(6000));
      expect(
        s.accounts.leftCents + s.cards.leftCents,
        (await repo.totalsFor(ids.monthId)).remainingCents,
      );
    });

    test('unused / over follow paid-from and transfers', () async {
      await repo.setStatus(
        ids.items['Electric']!,
        ItemStatus.paid,
        paidFromAccountId: ids.accounts['UB'],
      );
      final s = await summarize();
      expect(s.cards.accounts.first.balanceCents, php(6000)); // RCBC unused
      expect(
        s.accounts.accounts
            .singleWhere((a) => a.account.name == 'UB')
            .balanceCents,
        -php(6000),
      );
    });

    test('accounts with nothing this month are left out', () async {
      await AccountRepository(db)
          .createAccount(name: 'Maya', type: AccountType.ewallet);
      final s = await summarize();
      expect(s.hiddenCount, 1);
      expect(
        s.accounts.accounts.map((a) => a.account.name),
        isNot(contains('Maya')),
      );
    });
  });

  group('page', () {
    testWidgets('Summary is in the navigation and keeps the month', (
      tester,
    ) async {
      final router = await pumpApp(tester, db);
      await tester.tap(find.byKey(const Key('nav-summary')));
      await tester.pumpAndSettle();
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        '/summary/2026-11',
      );
      expect(find.byKey(const Key('summary-accounts')), findsOneWidget);
      expect(find.byKey(const Key('summary-cards')), findsOneWidget);
      String figure(String key) =>
          tester.widget<Text>(find.byKey(Key(key))).data!;
      expect(figure('figure-Credit cards-On card'), '₱9,549.00');
      expect(figure('figure-Credit cards-Settled'), '₱3,549.00');
      expect(figure('figure-Credit cards-To settle'), '₱6,000.00');
      expect(figure('figure-Accounts-Left to pay'), '₱9,576.26');
      expect(find.text('₱6,000.00 to settle'), findsOneWidget); // RCBC
      expect(find.text('All settled'), findsOneWidget); // JCB
      await closeApp(tester, db);
    });

    testWidgets('expand an account to see its expenses', (tester) async {
      await pumpApp(tester, db, location: '/summary/2026-11');
      final ub = find.byKey(ValueKey('summary-${ids.accounts['UB']}'));
      expect(
        find.byKey(ValueKey('summary-item-${ids.items['UB Loan']}')),
        findsNothing,
      );
      await tester.tap(ub);
      await tester.pumpAndSettle();
      expect(
        find.byKey(ValueKey('summary-item-${ids.items['UB Loan']}')),
        findsOneWidget,
      );
      expect(find.text('Allotted'), findsNWidgets(2));
      await closeApp(tester, db);
    });

    testWidgets('works on a phone and for an empty month', (tester) async {
      await pumpApp(tester, db, location: '/summary/2026-12', size: phone);
      expect(find.text('Nothing budgeted this month yet.'), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
      await tester.tap(find.byTooltip('Previous month'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('summary-cards')), findsOneWidget);
      await closeApp(tester, db);
    });
  });
}

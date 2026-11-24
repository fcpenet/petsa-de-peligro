import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:petsa/core/db/database.dart';
import 'package:petsa/features/accounts/data/account_repository.dart';
import 'package:petsa/features/budget/data/budget_repository.dart';

import '../../helpers/units.dart';

/// Repository behaviour shared by every backend (in-memory SQLite, Turso).
void budgetRepositoryTests(Future<AppDatabase> Function() openDb) {
  late AppDatabase db;
  late BudgetRepository repo;
  late AccountRepository accounts;
  late String monthId;

  /// Account for test collections, so their sub-expenses can leave theirs
  /// empty.
  late String wallet;
  var now = DateTime(2026, 11, 15, 9);

  setUp(() async {
    db = await openDb();
    now = DateTime(2026, 11, 15, 9);
    repo = BudgetRepository(db, clock: () => now);
    accounts = AccountRepository(db);
    monthId = (await repo.ensureMonth('2026-11')).id;
    wallet = await accounts.createAccount(
      name: 'Wallet',
      type: AccountType.cash,
    );
  });

  tearDown(() => db.close());

  Future<ItemStatus> statusOf(String id) async => (await repo.item(id)).status;

  group('months', () {
    test('ensureMonth is idempotent', () async {
      final again = await repo.ensureMonth('2026-11');
      expect(again.id, monthId);
    });

    test('clearMonth empties only that month', () async {
      final misc = await repo.addItem(
        monthId: monthId,
        name: 'Misc',
        amountCents: 1,
        accountId: wallet,
        isCollection: true,
      );
      await repo.addItem(
        monthId: monthId,
        name: 'x',
        amountCents: 1,
        parentId: misc,
      );
      final salary = await repo.addIncome(
        monthId: monthId,
        name: 'Salary',
        amountCents: 100,
      );
      await repo.addTopUp(incomeId: salary, amountCents: 50, receivedAt: now);
      final other = await accounts.createAccount(
        name: 'Other',
        type: AccountType.bank,
      );
      await repo.addTransfer(
        monthId: monthId,
        fromAccountId: wallet,
        toAccountId: other,
        amountCents: 10,
        transferredAt: now,
      );
      final dec = (await repo.ensureMonth('2026-12')).id;
      await repo.addIncome(monthId: dec, name: 'Bonus', amountCents: 1);

      await repo.clearMonth(monthId);
      expect(await repo.itemsFor(monthId), isEmpty);
      expect(await repo.incomesFor(monthId), isEmpty);
      expect(await repo.topUpsFor(monthId), isEmpty);
      expect(await repo.transfersFor(monthId), isEmpty);
      expect(await repo.incomesFor(dec), hasLength(1));
    });

    test('itemsBetween finds expenses by month, payment and parent', () async {
      final misc = await repo.addItem(
        monthId: monthId,
        name: 'Misc',
        amountCents: 0,
        accountId: wallet,
        isCollection: true,
      );
      final child = await repo.addItem(
        monthId: monthId,
        name: 'pliers',
        amountCents: 1,
        parentId: misc,
      );
      final oct = (await repo.ensureMonth('2026-10')).id;
      final late = await repo.addItem(
        monthId: oct,
        name: 'paid late',
        amountCents: 1,
        accountId: wallet,
      );
      await repo.addItem(
        monthId: oct,
        name: 'october only',
        amountCents: 1,
        accountId: wallet,
      );
      await repo.setStatus(
        late,
        ItemStatus.paid,
        paidAt: DateTime(2026, 11, 3, 22),
      );
      await repo.addTransfer(
        monthId: oct,
        fromAccountId: wallet,
        toAccountId: await accounts.createAccount(
          name: 'Other',
          type: AccountType.bank,
        ),
        amountCents: 1,
        transferredAt: DateTime(2026, 11, 30, 23),
      );

      final rows = await repo.itemsBetween(
        DateTime(2026, 11, 1),
        DateTime(2026, 11, 30),
      );
      final names = {for (final (i, ym) in rows) i.name: ym};
      expect(names, {
        'Misc': '2026-11',
        'pliers': '2026-11',
        'paid late': '2026-10',
      });

      // Charged in the range from another month (needs a card).
      final card = await accounts.createAccount(
        name: 'Card',
        type: AccountType.creditCard,
      );
      final charged = await repo.addItem(
        monthId: oct,
        name: 'charged late',
        amountCents: 1,
        accountId: card,
      );
      await repo.setStatus(
        charged,
        ItemStatus.charged,
        chargedAt: DateTime(2026, 11, 5),
      );
      final again = await repo.itemsBetween(
        DateTime(2026, 11, 1),
        DateTime(2026, 11, 30),
      );
      expect(again.map((r) => r.$1.name), contains('charged late'));
      expect(rows.map((r) => r.$1.id), contains(child));
      // Transfers by day, whichever month they're filed under.
      expect(
        await repo.transfersBetween(
          DateTime(2026, 11, 30),
          DateTime(2026, 11, 30),
        ),
        hasLength(1),
      );
      expect(
        await repo.transfersBetween(
          DateTime(2026, 12, 1),
          DateTime(2026, 12, 31),
        ),
        isEmpty,
      );
    });

    test('ensureMonth rejects malformed months', () {
      for (final bad in ['2026-13', '2026-1', 'nov', '2026-00']) {
        expect(
          () => repo.ensureMonth(bad),
          throwsA(isA<BudgetException>()),
          reason: bad,
        );
      }
    });

    test('yearMonthOf pads', () {
      expect(BudgetRepository.yearMonthOf(DateTime(2026, 3, 9)), '2026-03');
    });
  });

  group('items', () {
    test('new items start planned with no paid date', () async {
      final id = await repo.addItem(
        monthId: monthId,
        name: 'Rent',
        amountCents: php(25000),
      );
      final item = await repo.item(id);
      expect(item.status, ItemStatus.planned);
      expect(item.paidAt, isNull);
      expect(item.kind, ItemKind.expense);
    });

    test('rejects negative amounts and invalid due days', () {
      expect(
        () => repo.addItem(monthId: monthId, name: 'x', amountCents: -1),
        throwsA(isA<BudgetException>()),
      );
      expect(
        () => repo.addItem(
          monthId: monthId,
          name: 'x',
          amountCents: 1,
          dueDay: 32,
        ),
        throwsA(isA<BudgetException>()),
      );
    });

    test('sub-expenses cannot be nested more than one level', () async {
      final misc = await repo.addItem(
        monthId: monthId,
        name: 'Misc',
        isCollection: true,
        accountId: wallet,
        amountCents: php(5000),
      );
      final child = await repo.addItem(
        monthId: monthId,
        name: 'lazada',
        amountCents: php(549),
        parentId: misc,
      );
      expect(
        () => repo.addItem(
          monthId: monthId,
          name: 'too deep',
          amountCents: 1,
          parentId: child,
        ),
        throwsA(isA<BudgetException>()),
      );
    });

    test('sub-expense must be in the same month as its parent', () async {
      final misc = await repo.addItem(
        monthId: monthId,
        name: 'Misc',
        isCollection: true,
        accountId: wallet,
        amountCents: 0,
      );
      final december = (await repo.ensureMonth('2026-12')).id;
      expect(
        () => repo.addItem(
          monthId: december,
          name: 'x',
          amountCents: 1,
          parentId: misc,
        ),
        throwsA(isA<BudgetException>()),
      );
    });

    test('updateItem edits fields and can clear nullable ones', () async {
      final gcash = await accounts.createAccount(
        name: 'GCash',
        type: AccountType.ewallet,
      );
      final id = await repo.addItem(
        monthId: monthId,
        name: 'Phone',
        amountCents: php(1082),
        accountId: gcash,
        note: 'plan',
      );
      now = DateTime(2026, 11, 16);
      await repo.updateItem(
        id,
        name: 'Phone plan',
        amountCents: php(1200),
        accountId: const Value(null),
        note: const Value(null),
        kind: ItemKind.debt,
      );
      final item = await repo.item(id);
      expect(item.name, 'Phone plan');
      expect(item.amountCents, php(1200));
      expect(item.accountId, isNull);
      expect(item.note, isNull);
      expect(item.kind, ItemKind.debt);
      expect(item.updatedAt, now);
    });

    test('deleted items disappear from queries', () async {
      final id = await repo.addItem(
        monthId: monthId,
        name: 'Netflix',
        amountCents: php(800),
      );
      await repo.deleteItem(id);
      expect(await repo.itemsFor(monthId), isEmpty);
      expect(() => repo.item(id), throwsA(isA<BudgetException>()));
    });
  });

  group('status cascade', () {
    late String misc;
    late String a;
    late String b;
    late String c;

    setUp(() async {
      misc = await repo.addItem(
        monthId: monthId,
        name: 'Misc',
        isCollection: true,
        accountId: wallet,
        amountCents: php(5000),
      );
      a = await repo.addItem(
        monthId: monthId,
        name: 'dental pliers',
        amountCents: php(549),
        parentId: misc,
      );
      b = await repo.addItem(
        monthId: monthId,
        name: 'sleeve',
        amountCents: php(296.26),
        parentId: misc,
      );
      c = await repo.addItem(
        monthId: monthId,
        name: 'imed',
        amountCents: php(800),
        parentId: misc,
      );
    });

    test('a standalone item can be paid with a specific date', () async {
      final rent = await repo.addItem(
        monthId: monthId,
        name: 'Rent',
        amountCents: php(25000),
      );
      final paidOn = DateTime(2026, 11, 5);
      await repo.setStatus(rent, ItemStatus.paid, paidAt: paidOn);
      final item = await repo.item(rent);
      expect(item.status, ItemStatus.paid);
      expect(item.paidAt, paidOn);

      await repo.setStatus(rent, ItemStatus.allotted);
      expect((await repo.item(rent)).paidAt, isNull);
    });

    test('paid date defaults to now', () async {
      await repo.setStatus(a, ItemStatus.paid);
      expect((await repo.item(a)).paidAt, now);
    });

    test('parent stays planned until every sub-expense is paid', () async {
      await repo.setStatus(a, ItemStatus.paid);
      expect(await statusOf(misc), ItemStatus.planned);
      await repo.setStatus(b, ItemStatus.paid);
      expect(await statusOf(misc), ItemStatus.planned);
      await repo.setStatus(c, ItemStatus.paid);
      expect(await statusOf(misc), ItemStatus.paid);
    });

    test('parent paid date is the latest sub-expense payment', () async {
      await repo.setStatus(a, ItemStatus.paid, paidAt: DateTime(2026, 11, 3));
      await repo.setStatus(c, ItemStatus.paid, paidAt: DateTime(2026, 11, 20));
      await repo.setStatus(b, ItemStatus.paid, paidAt: DateTime(2026, 11, 10));
      expect((await repo.item(misc)).paidAt, DateTime(2026, 11, 20));
    });

    test('un-paying one sub-expense reverts the parent', () async {
      for (final id in [a, b, c]) {
        await repo.setStatus(id, ItemStatus.paid);
      }
      await repo.setStatus(b, ItemStatus.allotted);
      expect(await statusOf(misc), ItemStatus.allotted);
      expect((await repo.item(misc)).paidAt, isNull);
      expect(await statusOf(a), ItemStatus.paid);
    });

    test(
      'paying the parent pays all sub-expenses, keeping earlier dates',
      () async {
        final early = DateTime(2026, 11, 2);
        await repo.setStatus(a, ItemStatus.paid, paidAt: early);

        final payDay = DateTime(2026, 11, 30);
        await repo.setStatus(misc, ItemStatus.paid, paidAt: payDay);

        expect(await statusOf(misc), ItemStatus.paid);
        expect((await repo.item(a)).paidAt, early);
        expect((await repo.item(b)).paidAt, payDay);
        expect((await repo.item(c)).paidAt, payDay);
        expect((await repo.item(misc)).paidAt, payDay);
      },
    );

    test('un-paying the parent reverts all sub-expenses', () async {
      await repo.setStatus(misc, ItemStatus.paid);
      await repo.setStatus(misc, ItemStatus.allotted);
      for (final id in [misc, a, b, c]) {
        final item = await repo.item(id);
        expect(item.status, ItemStatus.allotted, reason: item.name);
        expect(item.paidAt, isNull, reason: item.name);
      }
    });

    test('adding an unpaid sub-expense to a paid parent reverts it', () async {
      await repo.setStatus(misc, ItemStatus.paid);
      await repo.addItem(
        monthId: monthId,
        name: 'glitter sticker',
        amountCents: php(236.7),
        parentId: misc,
      );
      expect(await statusOf(misc), ItemStatus.planned);
    });

    test(
      'deleting the last unpaid sub-expense makes the parent paid',
      () async {
        await repo.setStatus(a, ItemStatus.paid);
        await repo.setStatus(b, ItemStatus.paid);
        await repo.deleteItem(c);
        expect(await statusOf(misc), ItemStatus.paid);
      },
    );

    test('deleting a parent deletes its sub-expenses', () async {
      await repo.deleteItem(misc);
      expect(await repo.itemsFor(monthId), isEmpty);
    });

    test('a parent left with no sub-expenses keeps its status', () async {
      await repo.setStatus(misc, ItemStatus.paid);
      for (final id in [a, b, c]) {
        await repo.deleteItem(id);
      }
      expect(await statusOf(misc), ItemStatus.paid);
      await repo.setStatus(misc, ItemStatus.allotted);
      expect(await statusOf(misc), ItemStatus.allotted);
    });

    test('status changes do not touch other parents', () async {
      final other = await repo.addItem(
        monthId: monthId,
        name: 'Other',
        isCollection: true,
        accountId: wallet,
        amountCents: php(100),
      );
      final otherChild = await repo.addItem(
        monthId: monthId,
        name: 'x',
        amountCents: php(10),
        parentId: other,
      );
      await repo.setStatus(misc, ItemStatus.paid);
      expect(await statusOf(other), ItemStatus.planned);
      expect(await statusOf(otherChild), ItemStatus.planned);
    });
  });

  group('setParent', () {
    late String misc;
    late String rent;
    late String child;

    setUp(() async {
      misc = await repo.addItem(
        monthId: monthId,
        name: 'Misc',
        isCollection: true,
        accountId: wallet,
        amountCents: php(1000),
      );
      child = await repo.addItem(
        monthId: monthId,
        name: 'lazada',
        amountCents: php(100),
        parentId: misc,
      );
      rent = await repo.addItem(
        monthId: monthId,
        name: 'Rent',
        amountCents: php(25000),
      );
    });

    test('moves an item into a group', () async {
      await repo.setParent(rent, misc);
      expect((await repo.item(rent)).parentId, misc);
    });

    test('moves a sub-expense out of its group', () async {
      await repo.setParent(child, null);
      expect((await repo.item(child)).parentId, isNull);
    });

    test('moving an unpaid item into a paid group reverts the group', () async {
      await repo.setStatus(misc, ItemStatus.paid);
      await repo.setParent(rent, misc);
      expect(await statusOf(misc), ItemStatus.planned);
    });

    test('moving the last unpaid item out pays the group', () async {
      final paid = await repo.addItem(
        monthId: monthId,
        name: 'paid one',
        amountCents: 1,
        parentId: misc,
      );
      await repo.setStatus(paid, ItemStatus.paid);
      expect(await statusOf(misc), ItemStatus.planned);
      await repo.setParent(child, null);
      expect(await statusOf(misc), ItemStatus.paid);
    });

    test('rejects invalid moves', () async {
      final other = await repo.addItem(
        monthId: monthId,
        name: 'Other',
        isCollection: true,
        accountId: wallet,
        amountCents: 0,
      );
      // Into a sub-expense.
      expect(
        () => repo.setParent(other, child),
        throwsA(isA<BudgetException>()),
      );
      // A group with children into another group.
      expect(
        () => repo.setParent(misc, other),
        throwsA(isA<BudgetException>()),
      );
      // Into itself.
      expect(
        () => repo.setParent(other, other),
        throwsA(isA<BudgetException>()),
      );
    });

    test('no-op when the parent is unchanged', () async {
      await repo.setParent(child, misc);
      expect((await repo.item(child)).parentId, misc);
    });
  });

  group('totals', () {
    test('watchItems emits when status changes', () async {
      final id = await repo.addItem(
        monthId: monthId,
        name: 'Rent',
        amountCents: php(25000),
      );
      final statuses = repo
          .watchItems(monthId)
          .map((items) => items.single.status);
      expectLater(
        statuses,
        emitsInOrder([ItemStatus.planned, ItemStatus.paid]),
      );
      await pumpEventQueue();
      await repo.setStatus(id, ItemStatus.paid);
    });

    /// Reproduces the November sheet: the per-account "remaining" column
    /// (UB 24,894 · RCBC 7,200 · BPI 15,550 · total 47,644).
    test('matches the spreadsheet remaining totals', () async {
      final cash = await accounts.createAccount(
        name: 'Cash',
        type: AccountType.cash,
      );
      final ub = await accounts.createAccount(
        name: 'UB',
        type: AccountType.bank,
      );
      final rcbc = await accounts.createAccount(
        name: 'RCBC Card',
        type: AccountType.creditCard,
      );
      final bpi = await accounts.createAccount(
        name: 'BPI',
        type: AccountType.bank,
      );
      final jcb = await accounts.createAccount(
        name: 'JCB',
        type: AccountType.creditCard,
      );

      await repo.addIncome(
        monthId: monthId,
        name: 'Salary',
        amountCents: php(242122.23),
        accountId: bpi,
      );

      Future<String> add(
        String name,
        num pesos,
        String account, {
        bool paid = false,
        String? parent,
        ItemKind kind = ItemKind.expense,
      }) async {
        final id = await repo.addItem(
          monthId: monthId,
          name: name,
          amountCents: php(pesos),
          accountId: account,
          parentId: parent,
          kind: kind,
        );
        if (paid) await repo.setStatus(id, ItemStatus.paid);
        return id;
      }

      // Cash — all paid.
      await add('Basic', 8000, cash, paid: true);
      await add('Date fund', 5000, cash, paid: true, kind: ItemKind.savings);
      await add('Travel fund', 10000, cash, paid: true, kind: ItemKind.savings);
      // UB — none paid.
      await add('UB Loan', 7000, ub, kind: ItemKind.debt);
      await add('Pru', 2000, ub);
      await add('Phone', 1082, ub);
      await add('Loan', 13385, ub, kind: ItemKind.debt);
      await add('Apple subs', 1427, ub);
      // RCBC card.
      await add('Cats', 3000, rcbc, paid: true);
      await add('Electric', 6000, rcbc);
      await add('Youtube', 400, rcbc);
      await add('Grab', 2000, rcbc, paid: true);
      await add('Netflix', 800, rcbc);
      // BPI.
      await add('Rent', 25000, bpi, paid: true);
      await add('MP2/Condo', 22000, bpi, paid: true);
      await add('QR', 280, bpi);
      await add('Fixitfoot', 13920, bpi);
      await add('Airpods max', 1350, bpi);
      // Misc — sub-expenses on different accounts, all paid.
      final misc = await repo.addItem(
        monthId: monthId,
        name: 'Misc',
        isCollection: true,
        accountId: wallet,
        amountCents: php(2200),
      );
      await add('dental pliers', 549, jcb, paid: true, parent: misc);
      await add('sticker hikaw', 72.28, cash, paid: true, parent: misc);
      await add('sandbag', 377.74, rcbc, paid: true, parent: misc);

      var totals = await repo.totalsFor(monthId);
      expect(totals.byAccount[ub]!.remainingCents, php(24894));
      expect(totals.byAccount[rcbc]!.remainingCents, php(7200));
      expect(totals.byAccount[bpi]!.remainingCents, php(15550));
      expect(totals.byAccount[cash]!.remainingCents, 0);
      expect(totals.byAccount[jcb]!.remainingCents, 0);
      expect(totals.remainingCents, php(47644));
      expect((await repo.item(misc)).status, ItemStatus.paid);

      // Misc used 999.02 of its 2,200 cap.
      expect(totals.byParent[misc]!.leftCents, php(1200.98));
      expect(totals.slackCents, php(1200.98));
      expect(
        totals.allottedCents,
        totals.paidCents + totals.remainingCents + totals.slackCents,
      );

      // A new unpaid Misc purchase on JCB shows up in JCB's remaining and
      // moves Misc back to planned.
      await add('sleeve', 296.26, jcb, parent: misc);
      totals = await repo.totalsFor(monthId);
      expect(totals.byAccount[jcb]!.remainingCents, php(296.26));
      expect(totals.remainingCents, php(47940.26));
      expect((await repo.item(misc)).status, ItemStatus.planned);
    });
  });

  group('collections', () {
    late String cash;
    late String jcb;

    setUp(() async {
      cash = await accounts.createAccount(name: 'Cash', type: AccountType.cash);
      jcb = await accounts.createAccount(
        name: 'JCB',
        type: AccountType.creditCard,
      );
    });

    Future<String> collection({int cents = 220000}) => repo.addItem(
      monthId: monthId,
      name: 'Misc',
      amountCents: cents,
      accountId: cash,
      isCollection: true,
    );

    test('sub-expenses only go into collections', () async {
      final rent = await repo.addItem(
        monthId: monthId,
        name: 'Rent',
        amountCents: 1,
        accountId: cash,
      );
      expect(
        () => repo.addItem(
          monthId: monthId,
          name: 'x',
          amountCents: 1,
          parentId: rent,
        ),
        throwsA(isA<BudgetException>()),
      );
      final other = await repo.addItem(
        monthId: monthId,
        name: 'y',
        amountCents: 1,
        accountId: cash,
      );
      expect(
        () => repo.setParent(other, rent),
        throwsA(isA<BudgetException>()),
      );
    });

    test('a collection cannot be or go inside another collection', () async {
      final misc = await collection();
      final gifts = await collection(cents: 1);
      expect(
        () => repo.addItem(
          monthId: monthId,
          name: 'z',
          amountCents: 1,
          parentId: misc,
          isCollection: true,
        ),
        throwsA(isA<BudgetException>()),
      );
      // Even while empty.
      expect(
        () => repo.setParent(gifts, misc),
        throwsA(isA<BudgetException>()),
      );
    });

    test('turning Collection on and off', () async {
      final misc = await collection();
      final rent = await repo.addItem(
        monthId: monthId,
        name: 'Rent',
        amountCents: 1,
        accountId: cash,
      );
      await repo.updateItem(rent, isCollection: true);
      expect((await repo.item(rent)).isCollection, isTrue);
      await repo.updateItem(rent, isCollection: false);
      expect((await repo.item(rent)).isCollection, isFalse);

      final child = await repo.addItem(
        monthId: monthId,
        name: 'pliers',
        amountCents: 1,
        parentId: misc,
      );
      // Not while it has sub-expenses, and never for a sub-expense.
      expect(
        () => repo.updateItem(misc, isCollection: false),
        throwsA(isA<BudgetException>()),
      );
      expect(
        () => repo.updateItem(child, isCollection: true),
        throwsA(isA<BudgetException>()),
      );
    });

    test('a sub-expense without an account counts toward the '
        "collection's", () async {
      final misc = await collection();
      await repo.addItem(
        monthId: monthId,
        name: 'sleeve',
        amountCents: php(296.26),
        parentId: misc,
      );
      await repo.addItem(
        monthId: monthId,
        name: 'pliers',
        amountCents: php(549),
        accountId: jcb,
        parentId: misc,
      );
      final totals = await repo.totalsFor(monthId);
      expect(totals.byAccount[cash]!.remainingCents, php(296.26));
      expect(totals.byAccount[jcb]!.remainingCents, php(549));
      expect(totals.byAccount.containsKey(null), isFalse);
      expect(totals.byParent[misc]!.usedByAccount, {
        cash: php(296.26),
        jcb: php(549),
      });
    });

    test('sub-expenses of a collection without an account need one', () async {
      final gifts = await repo.addItem(
        monthId: monthId,
        name: 'Gifts',
        amountCents: 0,
        isCollection: true,
      );
      expect(
        () => repo.addItem(
          monthId: monthId,
          name: 'mug',
          amountCents: 1,
          parentId: gifts,
        ),
        throwsA(isA<BudgetException>()),
      );
      await repo.addItem(
        monthId: monthId,
        name: 'mug',
        amountCents: 1,
        accountId: jcb,
        parentId: gifts,
      );
      final totals = await repo.totalsFor(monthId);
      expect(totals.byAccount[jcb]!.remainingCents, 1);
      expect(totals.byAccount.containsKey(null), isFalse);
    });

    test('an empty collection sets aside its budget', () async {
      final misc = await collection(cents: php(2200));
      final totals = await repo.totalsFor(monthId);
      expect(totals.allottedCents, php(2200));
      expect(totals.slackCents, php(2200));
      // Not a bill to pay from Cash.
      expect(totals.remainingCents, 0);
      expect(totals.byAccount[cash], isNull);
      expect(totals.byParent[misc]!.childCount, 0);
    });
  });

  group('paid from another account and transfers', () {
    late String rcbc;
    late String ub;
    late String electric;

    setUp(() async {
      rcbc = await accounts.createAccount(
        name: 'RCBC Card',
        type: AccountType.creditCard,
      );
      ub = await accounts.createAccount(name: 'UB', type: AccountType.bank);
      electric = await repo.addItem(
        monthId: monthId,
        name: 'Electric',
        amountCents: php(6000),
        accountId: rcbc,
      );
    });

    test('paying from another account records it', () async {
      await repo.setStatus(electric, ItemStatus.paid, paidFromAccountId: ub);
      expect((await repo.item(electric)).paidFromAccountId, ub);
      final totals = await repo.totalsFor(monthId);
      expect(totals.balanceByAccount, {rcbc: php(6000), ub: -php(6000)});
      expect(totals.suggestedTransfers.single.amountCents, php(6000));
    });

    test('the planned account is stored as "as planned"', () async {
      await repo.setStatus(electric, ItemStatus.paid, paidFromAccountId: rcbc);
      expect((await repo.item(electric)).paidFromAccountId, isNull);
    });

    test('changing or clearing paid-from on a paid item', () async {
      await repo.setStatus(electric, ItemStatus.paid, paidFromAccountId: ub);
      await repo.setStatus(electric, ItemStatus.paid);
      expect((await repo.item(electric)).paidFromAccountId, isNull);
    });

    test('un-paying clears paid-from, including via a collection', () async {
      await repo.setStatus(electric, ItemStatus.paid, paidFromAccountId: ub);
      await repo.setStatus(electric, ItemStatus.allotted);
      expect((await repo.item(electric)).paidFromAccountId, isNull);

      final misc = await repo.addItem(
        monthId: monthId,
        name: 'Misc',
        amountCents: 0,
        accountId: wallet,
        isCollection: true,
      );
      final child = await repo.addItem(
        monthId: monthId,
        name: 'pliers',
        amountCents: php(549),
        parentId: misc,
      );
      await repo.setStatus(child, ItemStatus.paid, paidFromAccountId: ub);
      await repo.setStatus(misc, ItemStatus.allotted);
      expect((await repo.item(child)).paidFromAccountId, isNull);
      // A collection itself can't be "paid from" somewhere.
      expect(
        () => repo.setStatus(misc, ItemStatus.paid, paidFromAccountId: ub),
        throwsA(isA<BudgetException>()),
      );
    });

    test(
      'a transfer settles the difference; deleting it brings it back',
      () async {
        await repo.setStatus(electric, ItemStatus.paid, paidFromAccountId: ub);
        final id = await repo.addTransfer(
          monthId: monthId,
          fromAccountId: rcbc,
          toAccountId: ub,
          amountCents: php(6000),
          transferredAt: DateTime(2026, 11, 18),
          note: ' cover electric ',
        );
        final t = (await repo.transfersFor(monthId)).single;
        expect(t.note, 'cover electric');
        expect((await repo.totalsFor(monthId)).suggestedTransfers, isEmpty);

        await repo.updateTransfer(
          id,
          fromAccountId: rcbc,
          toAccountId: ub,
          amountCents: php(1000),
          transferredAt: DateTime(2026, 11, 19),
        );
        expect(
          (await repo.totalsFor(monthId)).suggestedTransfers.single.amountCents,
          php(5000),
        );

        await repo.deleteTransfer(id);
        expect(await repo.transfersFor(monthId), isEmpty);
        expect(
          (await repo.totalsFor(monthId)).suggestedTransfers.single.amountCents,
          php(6000),
        );
      },
    );

    test('transfers need two accounts and an amount', () async {
      expect(
        () => repo.addTransfer(
          monthId: monthId,
          fromAccountId: ub,
          toAccountId: ub,
          amountCents: 1,
          transferredAt: now,
        ),
        throwsA(isA<BudgetException>()),
      );
      expect(
        () => repo.addTransfer(
          monthId: monthId,
          fromAccountId: rcbc,
          toAccountId: ub,
          amountCents: 0,
          transferredAt: now,
        ),
        throwsA(isA<BudgetException>()),
      );
    });
  });

  group('planned, allotted, paid', () {
    late String ub;
    late String jcb;

    setUp(() async {
      ub = await accounts.createAccount(name: 'UB', type: AccountType.bank);
      jcb = await accounts.createAccount(
        name: 'JCB',
        type: AccountType.creditCard,
      );
    });

    Future<String> add(
      String name,
      String? account, {
      String? parent,
      bool collection = false,
    }) => repo.addItem(
      monthId: monthId,
      name: name,
      amountCents: php(100),
      accountId: account,
      parentId: parent,
      isCollection: collection,
    );

    test('allotting an account moves its planned expenses forward', () async {
      final loan = await add('Loan', ub);
      final pru = await add('Pru', ub);
      final other = await add('Netflix', jcb);
      final misc = await add('Misc', ub, collection: true);
      final sleeve = await add('sleeve', null, parent: misc); // uses UB
      final pliers = await add('pliers', jcb, parent: misc); // JCB's
      await repo.setStatus(pru, ItemStatus.paid);

      var totals = await repo.totalsFor(monthId);
      expect(totals.byAccount[ub]!.plannedCents, php(200)); // loan, sleeve
      expect(totals.plannedCents, php(400));

      expect(await repo.allotAccount(monthId, ub), 2);
      expect(await statusOf(loan), ItemStatus.allotted);
      expect(await statusOf(sleeve), ItemStatus.allotted);
      expect(await statusOf(pru), ItemStatus.paid); // untouched
      expect(await statusOf(other), ItemStatus.planned);
      expect(await statusOf(pliers), ItemStatus.planned);
      // Misc still has a planned sub-expense (on JCB).
      expect(await statusOf(misc), ItemStatus.planned);

      await repo.allotAccount(monthId, jcb);
      expect(await statusOf(misc), ItemStatus.allotted);
      totals = await repo.totalsFor(monthId);
      expect(totals.plannedCents, 0);
      // Allotted is still "left to pay".
      expect(totals.remainingCents, php(400));
      expect(await repo.allotAccount(monthId, ub), 0);
    });

    test('going back to planned clears the payment', () async {
      final loan = await add('Loan', ub);
      await repo.setStatus(loan, ItemStatus.paid, paidFromAccountId: jcb);
      await repo.setStatus(loan, ItemStatus.planned);
      final item = await repo.item(loan);
      expect(item.status, ItemStatus.planned);
      expect(item.paidAt, isNull);
      expect(item.paidFromAccountId, isNull);
    });
  });

  group('charged (credit cards)', () {
    late String card;
    late String bank;
    late String netflix;

    setUp(() async {
      card = await accounts.createAccount(
        name: 'JCB',
        type: AccountType.creditCard,
      );
      bank = await accounts.createAccount(name: 'UB', type: AccountType.bank);
      netflix = await repo.addItem(
        monthId: monthId,
        name: 'Netflix',
        amountCents: php(549),
        accountId: card,
      );
    });

    test('a card expense can be charged, with the charge date', () async {
      await repo.setStatus(
        netflix,
        ItemStatus.charged,
        chargedAt: DateTime(2026, 11, 10),
      );
      final item = await repo.item(netflix);
      expect(item.status, ItemStatus.charged);
      expect(item.chargedAt, DateTime(2026, 11, 10));
      expect(item.paidAt, isNull);
      final totals = await repo.totalsFor(monthId);
      expect(totals.chargedCents, php(549));
      expect(totals.byAccount[card]!.chargedCents, php(549));
      expect(totals.remainingCents, php(549)); // still to pay
    });

    test('only card expenses, and not collections, can be charged', () async {
      final rent = await repo.addItem(
        monthId: monthId,
        name: 'Rent',
        amountCents: 1,
        accountId: bank,
      );
      expect(
        () => repo.setStatus(rent, ItemStatus.charged),
        throwsA(isA<BudgetException>()),
      );
      final misc = await repo.addItem(
        monthId: monthId,
        name: 'Misc',
        amountCents: 0,
        accountId: card,
        isCollection: true,
      );
      expect(
        () => repo.setStatus(misc, ItemStatus.charged),
        throwsA(isA<BudgetException>()),
      );
      // A sub-expense that uses its card collection's account can be.
      final child = await repo.addItem(
        monthId: monthId,
        name: 'mug',
        amountCents: 1,
        parentId: misc,
      );
      await repo.setStatus(child, ItemStatus.charged);
      expect(await statusOf(misc), ItemStatus.charged);
    });

    test('paying keeps the charge date; going back clears it', () async {
      await repo.setStatus(
        netflix,
        ItemStatus.charged,
        chargedAt: DateTime(2026, 11, 10),
      );
      await repo.setStatus(netflix, ItemStatus.paid);
      expect((await repo.item(netflix)).chargedAt, DateTime(2026, 11, 10));
      await repo.setStatus(netflix, ItemStatus.charged);
      expect((await repo.item(netflix)).status, ItemStatus.charged);
      await repo.setStatus(netflix, ItemStatus.allotted);
      expect((await repo.item(netflix)).chargedAt, isNull);
    });

    test('settleCard pays every charged expense on that card', () async {
      final spotify = await repo.addItem(
        monthId: monthId,
        name: 'Spotify',
        amountCents: php(149),
        accountId: card,
      );
      final notYet = await repo.addItem(
        monthId: monthId,
        name: 'Later',
        amountCents: 1,
        accountId: card,
      );
      final misc = await repo.addItem(
        monthId: monthId,
        name: 'Misc',
        amountCents: 0,
        accountId: bank,
        isCollection: true,
      );
      final onCard = await repo.addItem(
        monthId: monthId,
        name: 'pliers',
        amountCents: 1,
        accountId: card,
        parentId: misc,
      );
      for (final id in [netflix, spotify, onCard]) {
        await repo.setStatus(id, ItemStatus.charged);
      }
      expect(
        await repo.settleCard(monthId, card, paidAt: DateTime(2026, 11, 28)),
        3,
      );
      for (final id in [netflix, spotify, onCard]) {
        final item = await repo.item(id);
        expect(item.status, ItemStatus.paid);
        expect(item.paidAt, DateTime(2026, 11, 28));
      }
      expect(await statusOf(notYet), ItemStatus.planned);
      expect(await statusOf(misc), ItemStatus.paid);
      expect((await repo.totalsFor(monthId)).chargedCents, 0);
      expect(await repo.settleCard(monthId, card), 0);
    });
  });
}

BudgetRepository budgetRepo(AppDatabase db) =>
    BudgetRepository(db, clock: () => DateTime(2026, 11, 15, 9));

/// Creates November with a "Misc" parent and [children] sub-expenses.
Future<({String monthId, String parent, List<String> children})>
seedMiscWithChildren(AppDatabase db, {required int children}) async {
  final repo = budgetRepo(db);
  final monthId = (await repo.ensureMonth('2026-11')).id;
  final cash = await AccountRepository(db)
      .createAccount(name: 'Cash', type: AccountType.cash);
  final parent = await repo.addItem(
    monthId: monthId,
    name: 'Misc',
    isCollection: true,
    accountId: cash,
    amountCents: php(5000),
  );
  final ids = [
    for (var i = 0; i < children; i++)
      await repo.addItem(
        monthId: monthId,
        name: 'child $i',
        amountCents: php(100),
        parentId: parent,
      ),
  ];
  return (monthId: monthId, parent: parent, children: ids);
}

import 'package:flutter_test/flutter_test.dart';
import 'package:petsa/core/db/database.dart';
import 'package:petsa/features/budget/domain/budget_calculator.dart';

import '../../helpers/test_db.dart';

final _t = DateTime(2026, 11, 1);

BudgetItem item(
  String id,
  num pesos, {
  String? account,
  String? parent,
  ItemStatus status = ItemStatus.allotted,
  bool deleted = false,
  bool collection = false,
  String? paidFrom,
}) => BudgetItem(
  id: id,
  updatedAt: _t,
  deletedAt: deleted ? _t : null,
  monthId: 'm',
  parentId: parent,
  accountId: account,
  name: id,
  amountCents: php(pesos),
  kind: ItemKind.expense,
  status: status,
  paidAt: status == ItemStatus.paid ? _t : null,
  sortOrder: 0,
  isCollection: collection,
  paidFromAccountId: paidFrom,
);

Income income(num pesos, {bool deleted = false}) => Income(
  id: 'i$pesos',
  updatedAt: _t,
  deletedAt: deleted ? _t : null,
  monthId: 'm',
  name: 'Salary',
  amountCents: php(pesos),
  sortOrder: 0,
);

Transfer transfer(String from, String to, num pesos, {bool deleted = false}) =>
    Transfer(
      id: '$from-$to-$pesos',
      updatedAt: _t,
      deletedAt: deleted ? _t : null,
      monthId: 'm',
      fromAccountId: from,
      toAccountId: to,
      amountCents: php(pesos),
      transferredAt: _t,
    );

void main() {
  group('paid from another account', () {
    test('leaves the planned account spare and the payer short', () {
      final totals = computeMonthTotals(
        items: [
          item(
            'Electric',
            6000,
            account: 'rcbc',
            status: ItemStatus.paid,
            paidFrom: 'ub',
          ),
          item('Loan', 7000, account: 'ub', status: ItemStatus.paid),
        ],
        incomes: const [],
      );
      expect(totals.balanceByAccount, {'rcbc': php(6000), 'ub': -php(6000)});
      expect(totals.suggestedTransfers, [
        SuggestedTransfer('rcbc', 'ub', php(6000)),
      ]);
      // Paid and remaining still follow the plan.
      expect(totals.byAccount['rcbc']!.paidCents, php(6000));
      expect(totals.byAccount['rcbc']!.remainingCents, 0);
    });

    test('paid from the planned account changes nothing', () {
      final totals = computeMonthTotals(
        items: [
          item(
            'Rent',
            100,
            account: 'bpi',
            status: ItemStatus.paid,
            paidFrom: 'bpi',
          ),
        ],
        incomes: const [],
      );
      expect(totals.balanceByAccount, isEmpty);
    });

    test('unpaid items do not count, even with a stale paid-from', () {
      final totals = computeMonthTotals(
        items: [item('Rent', 100, account: 'bpi', paidFrom: 'ub')],
        incomes: const [],
      );
      expect(totals.balanceByAccount, isEmpty);
    });

    test("a sub-expense's plan is its own account or its collection's", () {
      final totals = computeMonthTotals(
        items: [
          item('Misc', 500, account: 'cash', collection: true),
          item(
            'a',
            100,
            parent: 'Misc',
            status: ItemStatus.paid,
            paidFrom: 'jcb',
          ),
          item(
            'b',
            50,
            parent: 'Misc',
            account: 'ub',
            status: ItemStatus.paid,
            paidFrom: 'jcb',
          ),
        ],
        incomes: const [],
      );
      expect(totals.balanceByAccount, {
        'cash': php(100),
        'ub': php(50),
        'jcb': -php(150),
      });
    });

    test('transfers even accounts out; deleted ones are ignored', () {
      final items = [
        item(
          'Electric',
          6000,
          account: 'rcbc',
          status: ItemStatus.paid,
          paidFrom: 'ub',
        ),
      ];
      var totals = computeMonthTotals(
        items: items,
        incomes: const [],
        transfers: [transfer('rcbc', 'ub', 6000)],
      );
      expect(totals.balanceByAccount, isEmpty);
      expect(totals.suggestedTransfers, isEmpty);

      totals = computeMonthTotals(
        items: items,
        incomes: const [],
        transfers: [
          transfer('rcbc', 'ub', 2000),
          transfer('rcbc', 'ub', 4000, deleted: true),
        ],
      );
      expect(totals.suggestedTransfers, [
        SuggestedTransfer('rcbc', 'ub', php(4000)),
      ]);
    });

    test('a transfer with nothing behind it is suggested back', () {
      final totals = computeMonthTotals(
        items: const [],
        incomes: const [],
        transfers: [transfer('ub', 'gcash', 500)],
      );
      expect(totals.suggestedTransfers, [
        SuggestedTransfer('gcash', 'ub', php(500)),
      ]);
    });
  });

  group('suggestTransfers', () {
    test('covers the biggest shortfall from the biggest surplus first', () {
      final moves = suggestTransfers({
        'a': 700,
        'b': 300,
        'x': -600,
        'y': -400,
      });
      expect(moves, [
        const SuggestedTransfer('a', 'x', 600),
        const SuggestedTransfer('a', 'y', 100),
        const SuggestedTransfer('b', 'y', 300),
      ]);
      // Applying the moves evens everything out.
      final after = {'a': 700, 'b': 300, 'x': -600, 'y': -400};
      for (final m in moves) {
        after[m.fromAccountId] = after[m.fromAccountId]! - m.amountCents;
        after[m.toAccountId] = after[m.toAccountId]! + m.amountCents;
      }
      expect(after.values.every((v) => v == 0), isTrue);
    });

    test('nothing to do when balanced', () {
      expect(suggestTransfers({}), isEmpty);
    });
  });

  group('deriveParentStatus', () {
    test('null when there are no sub-expenses', () {
      expect(deriveParentStatus([]), isNull);
    });

    test('paid only when all are paid', () {
      expect(
        deriveParentStatus([ItemStatus.paid, ItemStatus.paid]),
        ItemStatus.paid,
      );
      expect(
        deriveParentStatus([ItemStatus.paid, ItemStatus.allotted]),
        ItemStatus.allotted,
      );
      expect(deriveParentStatus([ItemStatus.allotted]), ItemStatus.allotted);
    });
  });

  group('computeMonthTotals', () {
    test('empty month', () {
      final t = computeMonthTotals(items: [], incomes: []);
      expect(t.incomeCents, 0);
      expect(t.allottedCents, 0);
      expect(t.unbudgetedCents, 0);
      expect(t.byAccount, isEmpty);
    });

    test('sums standalone items per account', () {
      final t = computeMonthTotals(
        items: [
          item('rent', 25000, account: 'bpi', status: ItemStatus.paid),
          item('qr', 280, account: 'bpi'),
          item('loan', 7000, account: 'ub'),
        ],
        incomes: [income(40000)],
      );
      expect(t.byAccount['bpi']!.allottedCents, php(25280));
      expect(t.byAccount['bpi']!.paidCents, php(25000));
      expect(t.byAccount['bpi']!.remainingCents, php(280));
      expect(t.byAccount['ub']!.remainingCents, php(7000));
      expect(t.allottedCents, php(32280));
      expect(t.paidCents, php(25000));
      expect(t.remainingCents, php(7280));
      expect(t.unbudgetedCents, php(7720));
    });

    test('items without an account are grouped under null', () {
      final t = computeMonthTotals(items: [item('x', 100)], incomes: []);
      expect(t.byAccount[null]!.allottedCents, php(100));
    });

    test('parent cap counts toward month, children toward accounts', () {
      final t = computeMonthTotals(
        items: [
          item('misc', 5000),
          item('pliers', 549, parent: 'misc', account: 'jcb'),
          item('sleeve', 296.26, parent: 'misc', account: 'cash'),
          item(
            'sticker',
            72.28,
            parent: 'misc',
            account: 'jcb',
            status: ItemStatus.paid,
          ),
        ],
        incomes: [],
      );

      // The parent itself has no account entry; only its children do.
      expect(t.byAccount.containsKey(null), isFalse);
      expect(t.byAccount['jcb']!.allottedCents, php(621.28));
      expect(t.byAccount['jcb']!.paidCents, php(72.28));
      expect(t.byAccount['cash']!.allottedCents, php(296.26));

      final misc = t.byParent['misc']!;
      expect(misc.budgetCents, php(5000));
      expect(misc.usedCents, php(917.54));
      expect(misc.paidCents, php(72.28));
      expect(misc.leftCents, php(4082.46));
      expect(misc.childCount, 3);
      expect(misc.paidCount, 1);
      expect(misc.usedByAccount, {'jcb': php(621.28), 'cash': php(296.26)});
      expect(misc.isOverBudget, isFalse);

      expect(t.allottedCents, php(5000));
      expect(t.slackCents, php(4082.46));
    });

    test('an over-budget parent allots what was actually used', () {
      final t = computeMonthTotals(
        items: [
          item('misc', 1000),
          item('a', 800, parent: 'misc'),
          item('b', 700, parent: 'misc'),
        ],
        incomes: [],
      );
      final misc = t.byParent['misc']!;
      expect(misc.isOverBudget, isTrue);
      expect(misc.leftCents, php(-500));
      expect(misc.slackCents, 0);
      expect(t.allottedCents, php(1500));
    });

    test('a parent with a zero cap behaves like a sum of its children', () {
      final t = computeMonthTotals(
        items: [
          item('misc', 0),
          item('a', 300, parent: 'misc'),
        ],
        incomes: [],
      );
      expect(t.allottedCents, php(300));
    });

    test('allotted always equals paid + remaining + slack', () {
      final t = computeMonthTotals(
        items: [
          item('rent', 25000, status: ItemStatus.paid),
          item('loan', 7000),
          item('misc', 2000),
          item('a', 500, parent: 'misc', status: ItemStatus.paid),
          item('b', 300, parent: 'misc'),
          item('fun', 100),
          item('c', 150, parent: 'fun'),
        ],
        incomes: [],
      );
      expect(t.allottedCents, t.paidCents + t.remainingCents + t.slackCents);
    });

    test('ignores soft-deleted items and incomes', () {
      final t = computeMonthTotals(
        items: [
          item('kept', 100, account: 'a'),
          item('gone', 900, account: 'a', deleted: true),
          item('misc', 500),
          item('gone-child', 400, parent: 'misc', deleted: true),
        ],
        incomes: [income(1000), income(5000, deleted: true)],
      );
      expect(t.incomeCents, php(1000));
      expect(t.byAccount['a']!.allottedCents, php(100));
      // misc lost its only child, so it is a standalone item again.
      expect(t.byParent, isEmpty);
      expect(t.allottedCents, php(600));
    });

    test('negative unallotted when over budget', () {
      final t = computeMonthTotals(
        items: [item('a', 1500)],
        incomes: [income(1000)],
      );
      expect(t.unbudgetedCents, php(-500));
    });
  });
}

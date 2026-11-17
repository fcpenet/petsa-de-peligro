import 'package:flutter_test/flutter_test.dart';
import 'package:petsa/core/db/database.dart';
import 'package:petsa/features/templates/domain/month_template.dart';

final _t = DateTime(2026, 11, 1);

BudgetItem item(
  String id,
  int cents, {
  String? parent,
  String? account,
  int order = 0,
  bool deleted = false,
  bool collection = false,
  ItemKind kind = ItemKind.expense,
  ItemStatus status = ItemStatus.allotted,
}) => BudgetItem(
  id: id,
  updatedAt: _t,
  deletedAt: deleted ? _t : null,
  monthId: 'm',
  parentId: parent,
  accountId: account,
  name: id,
  amountCents: cents,
  kind: kind,
  status: status,
  paidAt: status == ItemStatus.paid ? _t : null,
  dueDay: id == 'Rent' ? 5 : null,
  sortOrder: order,
  isCollection: collection,
);

Income income(String name, int cents, {bool deleted = false}) => Income(
  id: name,
  updatedAt: _t,
  deletedAt: deleted ? _t : null,
  monthId: 'm',
  name: name,
  amountCents: cents,
  sortOrder: 0,
);

void main() {
  final items = [
    item('Rent', 2500000, account: 'bpi', order: 2, status: ItemStatus.paid),
    item('Savings', 6000000, account: 'maya', order: 1, kind: ItemKind.savings),
    item('Misc', 220000, account: 'cash', order: 3, collection: true),
    item('lazada', 54900, parent: 'Misc', account: 'jcb', order: 4),
    item('tiktok', 7228, parent: 'Misc', order: 5),
    item('Gone', 100, order: 0, deleted: true),
  ];
  final incomes = [income('Salary', 24212223), income('Old', 1, deleted: true)];

  group('templateFromMonth', () {
    test('keeps top-level items in order, drops deleted rows', () {
      final t = templateFromMonth(items: items, incomes: incomes);
      expect(t.items.map((i) => i.name), ['Savings', 'Rent', 'Misc']);
      expect(t.incomes.map((i) => i.name), ['Salary']);
    });

    test('keeps amounts, accounts, kinds and due days but not status', () {
      final t = templateFromMonth(items: items, incomes: incomes);
      final rent = t.items[1];
      expect(rent.amountCents, 2500000);
      expect(rent.accountId, 'bpi');
      expect(rent.dueDay, 5);
      expect(t.items[0].kind, ItemKind.savings);
    });

    test('keeps collections but leaves out their sub-expenses by default', () {
      final t = templateFromMonth(items: items, incomes: incomes);
      expect(t.items[2].isCollection, isTrue);
      expect(t.items[2].accountId, 'cash');
      expect(t.items[2].children, isEmpty);
      expect(t.items[2].amountCents, 220000);
      expect(t.itemCount, 3);
    });

    test('can include sub-expenses', () {
      final t = templateFromMonth(
        items: items,
        incomes: incomes,
        includeSubExpenses: true,
      );
      expect(t.items[2].children.map((c) => c.name), ['lazada', 'tiktok']);
      expect(t.items[2].children.first.accountId, 'jcb');
      expect(t.itemCount, 5);
    });

    test('can leave out incomes', () {
      final t = templateFromMonth(
        items: items,
        incomes: incomes,
        includeIncomes: false,
      );
      expect(t.incomes, isEmpty);
    });

    test('an empty month gives an empty template', () {
      expect(templateFromMonth(items: [], incomes: []).isEmpty, isTrue);
    });
  });

  group('JSON', () {
    test('round-trips', () {
      final original = templateFromMonth(
        items: items,
        incomes: incomes,
        includeSubExpenses: true,
      );
      final decoded = MonthTemplate.decode(original.encode());
      expect(decoded.toJson(), original.toJson());
      expect(decoded.items[2].children[0].accountId, 'jcb');
      expect(decoded.items[1].dueDay, 5);
    });

    test('includes a version and omits empty optional fields', () {
      final json = const MonthTemplate(
        items: [TemplateItem(name: 'X', amountCents: 1)],
      ).toJson();
      expect(json['version'], MonthTemplate.currentVersion);
      expect((json['items'] as List).single, {
        'name': 'X',
        'amountCents': 1,
        'kind': 'expense',
      });
    });

    test('collections are marked in JSON, plain expenses are not', () {
      final json = const MonthTemplate(
        items: [
          TemplateItem(name: 'Misc', amountCents: 0, isCollection: true),
          TemplateItem(name: 'Rent', amountCents: 1, accountId: 'bpi'),
        ],
      ).toJson();
      final items = json['items'] as List;
      expect((items[0] as Map)['collection'], true);
      expect((items[1] as Map).containsKey('collection'), isFalse);
      final back = MonthTemplate.fromJson(json);
      expect(back.items[0].isCollection, isTrue);
      expect(back.items[1].isCollection, isFalse);
    });

    test('version 1 groups are read as collections', () {
      final t = MonthTemplate.fromJson({
        'version': 1,
        'items': [
          {'name': 'Rent', 'amountCents': 1, 'accountId': 'bpi'},
          // A group: no account.
          {'name': 'Misc', 'amountCents': 2},
          // Anything with sub-expenses.
          {
            'name': 'Cards',
            'amountCents': 3,
            'accountId': 'ub',
            'children': [
              {'name': 'x', 'amountCents': 1, 'accountId': 'jcb'},
            ],
          },
        ],
      });
      expect(t.items.map((i) => i.isCollection), [false, true, true]);
      expect(t.items[2].children.single.isCollection, isFalse);
    });

    test('an empty collection plans its whole budget', () {
      const misc = TemplateItem(
        name: 'Misc',
        amountCents: 2000,
        isCollection: true,
      );
      expect(misc.plannedCents, 2000);
      expect(const MonthTemplate(items: [misc]).expenseCents, 2000);
    });

    test('unknown kinds fall back to expense', () {
      final t = MonthTemplate.fromJson({
        'version': 1,
        'items': [
          {'name': 'X', 'amountCents': 1, 'kind': 'mystery'},
        ],
      });
      expect(t.items.single.kind, ItemKind.expense);
    });

    test('rejects templates from a newer app version', () {
      expect(
        () => MonthTemplate.fromJson({'version': 99}),
        throwsFormatException,
      );
    });
  });
}

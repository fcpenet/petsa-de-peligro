import 'package:flutter_test/flutter_test.dart';
import 'package:petsa/core/db/database.dart';
import 'package:petsa/features/templates/domain/month_template.dart';
import 'package:petsa/features/templates/domain/template_draft.dart';

TemplateItem item(String name, int cents, [String? account = 'ub']) =>
    TemplateItem(name: name, amountCents: cents, accountId: account);

TemplateItem group(String name, int cap, [List<TemplateItem> c = const []]) =>
    TemplateItem(
      name: name,
      amountCents: cap,
      accountId: 'cash',
      isCollection: true,
      children: c,
    );

List<String> names(TemplateDraft d) => [
  for (final i in d.items) ...[
    i.name,
    for (final c in i.children) '  ${c.name}',
  ],
];

void main() {
  test('starts empty and builds what was added', () {
    final d = TemplateDraft()
      ..add(item('Rent', 25000))
      ..add(group('Misc', 2000))
      ..add(item('Coffee', 300, null), collectionIndex: 1)
      ..incomes.add(const TemplateIncome(name: 'Salary', amountCents: 90000));
    final t = d.build();
    expect(names(d), ['Rent', 'Misc', '  Coffee']);
    expect(t.itemCount, 3);
    expect(t.incomeCents, 90000);
    expect(t.expenseCents, 27000); // Misc counts its 2000 budget
    // Round-trips through JSON.
    expect(MonthTemplate.decode(t.encode()).itemCount, 3);
  });

  test('a collection counts its sub-expenses when they exceed the budget', () {
    expect(
      group('Misc', 500, [item('a', 400), item('b', 300)]).plannedCents,
      700,
    );
    expect(group('Misc', 1000, [item('a', 400)]).plannedCents, 1000);
    expect(group('Misc', 0).plannedCents, 0);
    expect(group('Misc', 800).plannedCents, 800); // empty but budgeted
  });

  test('does not modify the template it was loaded from', () {
    final original = MonthTemplate(
      items: [
        group('Misc', 100, [item('a', 1)]),
      ],
    );
    TemplateDraft(original).add(item('b', 2), collectionIndex: 0);
    expect(original.items.single.children.length, 1);
  });

  test('collectionIndexes lists top-level items without an account', () {
    final d = TemplateDraft()
      ..add(item('Rent', 1))
      ..add(group('Misc', 0))
      ..add(group('Gifts', 0));
    expect(d.collectionIndexes, [1, 2]);
    expect(() => d.add(item('x', 1), collectionIndex: 0), throwsArgumentError);
  });

  test('replace in place keeps a collection’s sub-expenses', () {
    final d = TemplateDraft()
      ..add(group('Misc', 0))
      ..add(item('a', 1), collectionIndex: 0);
    d.replace((index: 0, child: null), group('Extras', 500));
    expect(names(d), ['Extras', '  a']);
    expect(d.items[0].amountCents, 500);

    d.replace((index: 0, child: 0), item('b', 2), collectionIndex: 0);
    expect(names(d), ['Extras', '  b']);
  });

  test('moves an expense into a collection, and back out', () {
    final d = TemplateDraft()
      ..add(item('Coffee', 300))
      ..add(group('Misc', 0));
    d.replace((index: 0, child: null), item('Coffee', 300), collectionIndex: 1);
    // Misc shifted from index 1 to 0 when Coffee left the top level.
    expect(names(d), ['Misc', '  Coffee']);

    d.replace((index: 0, child: 0), item('Coffee', 350));
    expect(names(d), ['Misc', 'Coffee']);
    expect(d.items[1].amountCents, 350);
  });

  test('moves a sub-expense between collections', () {
    final d = TemplateDraft()
      ..add(group('Misc', 0))
      ..add(group('Gifts', 0))
      ..add(item('Card', 100), collectionIndex: 0);
    d.replace((index: 0, child: 0), item('Card', 100), collectionIndex: 1);
    expect(names(d), ['Misc', 'Gifts', '  Card']);
  });

  test('refuses to nest collections', () {
    final d = TemplateDraft()
      ..add(group('Misc', 0, [item('a', 1)]))
      ..add(group('Gifts', 0));
    expect(
      () => d.replace(
        (index: 0, child: null),
        group('Misc', 0),
        collectionIndex: 1,
      ),
      throwsArgumentError,
    );
    expect(
      () => d.replace(
        (index: 1, child: null),
        group('Gifts', 0),
        collectionIndex: 1,
      ),
      throwsArgumentError,
    ); // Even an empty collection can't go inside another.
    expect(
      () => d.replace(
        (index: 1, child: null),
        group('Gifts', 0),
        collectionIndex: 0,
      ),
      throwsArgumentError,
    );
  });

  test('removing a collection removes its sub-expenses', () {
    final d = TemplateDraft()
      ..add(group('Misc', 0, [item('a', 1)]))
      ..add(item('Rent', 1));
    d.remove((index: 0, child: null));
    expect(names(d), ['Rent']);
  });

  test('copyWith can clear nullable fields', () {
    final i = TemplateItem(
      name: 'x',
      amountCents: 1,
      accountId: 'ub',
      dueDay: 5,
      note: 'n',
      kind: ItemKind.debt,
    ).copyWith(accountId: () => null, dueDay: () => null, note: () => null);
    expect(i.accountId, isNull);
    expect(i.dueDay, isNull);
    expect(i.note, isNull);
    expect(i.kind, ItemKind.debt);
  });
}

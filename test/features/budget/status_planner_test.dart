import 'package:flutter_test/flutter_test.dart';
import 'package:petsa/core/db/database.dart';
import 'package:petsa/features/budget/domain/budget_calculator.dart';
import 'package:petsa/features/budget/domain/status_planner.dart';

final _now = DateTime(2026, 11, 15, 9);
final _payDay = DateTime(2026, 11, 30);
final _early = DateTime(2026, 11, 2);

BudgetItem item(
  String id, {
  String? parent,
  ItemStatus status = ItemStatus.allotted,
  DateTime? paidAt,
  bool deleted = false,
}) => BudgetItem(
  id: id,
  updatedAt: _now,
  deletedAt: deleted ? _now : null,
  monthId: 'm',
  parentId: parent,
  name: id,
  amountCents: 100,
  kind: ItemKind.expense,
  status: status,
  paidAt: status == ItemStatus.paid ? (paidAt ?? _early) : null,
  sortOrder: 0,
  isCollection: false,
);

Map<String, StatusPatch> plan(
  List<BudgetItem> items,
  String target,
  ItemStatus status,
) => planStatusChange(
  ItemFamily(items),
  targetId: target,
  status: status,
  paidAt: _payDay,
  now: _now,
);

const allotted = StatusPatch(ItemStatus.allotted, null);
StatusPatch paidOn(DateTime d) => StatusPatch(ItemStatus.paid, d);

void main() {
  group('planStatusChange', () {
    test('standalone item: only the target changes', () {
      expect(plan([item('rent'), item('other')], 'rent', ItemStatus.paid), {
        'rent': paidOn(_payDay),
      });
    });

    test('target is always included, even when unchanged', () {
      expect(plan([item('rent')], 'rent', ItemStatus.allotted), {
        'rent': allotted,
      });
    });

    test(
      'paying a sub-expense leaves the parent alone while others unpaid',
      () {
        final family = [
          item('misc'),
          item('a', parent: 'misc'),
          item('b', parent: 'misc'),
        ];
        expect(plan(family, 'a', ItemStatus.paid), {'a': paidOn(_payDay)});
      },
    );

    test('paying the last sub-expense pays the parent at the latest date', () {
      final late = DateTime(2026, 12, 5);
      final family = [
        item('misc'),
        item('a', parent: 'misc', status: ItemStatus.paid, paidAt: late),
        item('b', parent: 'misc'),
      ];
      expect(plan(family, 'b', ItemStatus.paid), {
        'b': paidOn(_payDay),
        'misc': paidOn(late),
      });
    });

    test('un-paying a sub-expense reverts a paid parent', () {
      final family = [
        item('misc', status: ItemStatus.paid),
        item('a', parent: 'misc', status: ItemStatus.paid),
        item('b', parent: 'misc', status: ItemStatus.paid),
      ];
      expect(plan(family, 'a', ItemStatus.allotted), {
        'a': allotted,
        'misc': allotted,
      });
    });

    test('paying a parent pays unpaid children and keeps earlier dates', () {
      final family = [
        item('misc'),
        item('a', parent: 'misc', status: ItemStatus.paid, paidAt: _early),
        item('b', parent: 'misc'),
      ];
      expect(plan(family, 'misc', ItemStatus.paid), {
        'misc': paidOn(_payDay),
        'b': paidOn(_payDay),
      });
    });

    test('un-paying a parent reverts every child', () {
      final family = [
        item('misc', status: ItemStatus.paid),
        item('a', parent: 'misc', status: ItemStatus.paid),
        item('b', parent: 'misc', status: ItemStatus.paid),
      ];
      expect(plan(family, 'misc', ItemStatus.allotted), {
        'misc': allotted,
        'a': allotted,
        'b': allotted,
      });
    });

    test('deleted children are ignored', () {
      final family = [
        item('misc'),
        item('a', parent: 'misc'),
        item('gone', parent: 'misc', deleted: true),
      ];
      expect(plan(family, 'a', ItemStatus.paid), {
        'a': paidOn(_payDay),
        'misc': paidOn(_payDay),
      });
    });

    test('throws when the target is missing', () {
      expect(
        () => plan([item('x')], 'missing', ItemStatus.paid),
        throwsArgumentError,
      );
    });
  });

  group('three statuses', () {
    const planned = StatusPatch(ItemStatus.planned, null);

    test('a collection follows its least advanced sub-expense', () {
      expect(
        deriveParentStatus([ItemStatus.paid, ItemStatus.planned]),
        ItemStatus.planned,
      );
      expect(
        deriveParentStatus([ItemStatus.paid, ItemStatus.allotted]),
        ItemStatus.allotted,
      );
      expect(
        deriveParentStatus([ItemStatus.paid, ItemStatus.paid]),
        ItemStatus.paid,
      );
      expect(deriveParentStatus([]), isNull);
    });

    test('allotting a collection brings planned ones up, keeps paid', () {
      final family = [
        item('misc', status: ItemStatus.planned),
        item('a', parent: 'misc', status: ItemStatus.planned),
        item('b', parent: 'misc', status: ItemStatus.paid),
      ];
      expect(plan(family, 'misc', ItemStatus.allotted), {
        'misc': allotted,
        'a': allotted,
      });
    });

    test('un-paying a collection takes paid ones back to allotted only', () {
      final family = [
        item('misc', status: ItemStatus.paid),
        item('a', parent: 'misc', status: ItemStatus.paid),
        item('b', parent: 'misc', status: ItemStatus.paid),
      ];
      expect(plan(family, 'misc', ItemStatus.allotted), {
        'misc': allotted,
        'a': allotted,
        'b': allotted,
      });
    });

    test('planning a collection takes every sub-expense back', () {
      final family = [
        item('misc', status: ItemStatus.allotted),
        item('a', parent: 'misc', status: ItemStatus.allotted),
        item('b', parent: 'misc', status: ItemStatus.planned),
      ];
      expect(plan(family, 'misc', ItemStatus.planned), {
        'misc': planned,
        'a': planned,
      });
    });

    test('allotting the last planned sub-expense allots the collection', () {
      final family = [
        item('misc', status: ItemStatus.planned),
        item('a', parent: 'misc', status: ItemStatus.paid),
        item('b', parent: 'misc', status: ItemStatus.planned),
      ];
      expect(plan(family, 'b', ItemStatus.allotted), {
        'b': allotted,
        'misc': allotted,
      });
    });
  });

  group('planParentRederive', () {
    test('null when the parent has no children', () {
      final family = ItemFamily([item('misc', status: ItemStatus.paid)]);
      expect(planParentRederive(family, 'misc', now: _now), isNull);
    });

    test('null when nothing changes', () {
      final family = ItemFamily([item('misc'), item('a', parent: 'misc')]);
      expect(planParentRederive(family, 'misc', now: _now), isNull);
    });

    test('reverts a paid parent with a new unpaid child', () {
      final family = ItemFamily([
        item('misc', status: ItemStatus.paid),
        item('a', parent: 'misc', status: ItemStatus.paid),
        item('new', parent: 'misc'),
      ]);
      expect(planParentRederive(family, 'misc', now: _now), allotted);
    });

    test('pays the parent when only paid children remain', () {
      final family = ItemFamily([
        item('misc'),
        item('a', parent: 'misc', status: ItemStatus.paid, paidAt: _early),
      ]);
      expect(planParentRederive(family, 'misc', now: _now), paidOn(_early));
    });
  });
}

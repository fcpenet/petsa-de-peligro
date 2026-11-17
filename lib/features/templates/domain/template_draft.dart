import 'month_template.dart';

/// Where an item sits in a draft: a top-level index, plus the index inside
/// that collection for a sub-expense.
typedef ItemRef = ({int index, int? child});

/// A template being edited. Changes are made in place and turned back into
/// a [MonthTemplate] with [build] when saving.
class TemplateDraft {
  TemplateDraft([MonthTemplate template = const MonthTemplate()])
    : items = [
        for (final i in template.items) i.copyWith(children: [...i.children]),
      ],
      incomes = [...template.incomes];

  final List<TemplateItem> items;
  final List<TemplateIncome> incomes;

  TemplateItem itemAt(ItemRef ref) => ref.child == null
      ? items[ref.index]
      : items[ref.index].children[ref.child!];

  /// Indexes of the collections, in order.
  List<int> get collectionIndexes => [
    for (final (i, item) in items.indexed)
      if (item.isCollection) i,
  ];

  /// Adds [item] at the end, or into the collection at [collectionIndex].
  void add(TemplateItem item, {int? collectionIndex}) {
    if (collectionIndex == null) {
      items.add(item);
    } else {
      _checkCollection(collectionIndex);
      _setChildren(collectionIndex, [...items[collectionIndex].children, item]);
    }
  }

  /// Replaces the item at [ref] with [item], moving it into the collection at
  /// [collectionIndex] (or to the top level when null) if that changed. A
  /// top-level item keeps its sub-expenses.
  void replace(ItemRef ref, TemplateItem item, {int? collectionIndex}) {
    final current = itemAt(ref);
    if (ref.child == null) {
      item = item.copyWith(children: current.children);
    }
    if (collectionIndex == (ref.child == null ? null : ref.index)) {
      if (ref.child == null) {
        items[ref.index] = item;
      } else {
        final children = [...items[ref.index].children];
        children[ref.child!] = item;
        _setChildren(ref.index, children);
      }
      return;
    }
    if (collectionIndex != null) {
      _checkCollection(collectionIndex);
      if (collectionIndex == ref.index && ref.child == null) {
        throw ArgumentError('A collection cannot go inside itself');
      }
      if (item.isCollection || item.children.isNotEmpty) {
        throw ArgumentError('A collection cannot go inside another collection');
      }
    }
    // Remember the target by identity: removing a top-level item shifts
    // the indexes after it.
    final target = collectionIndex == null ? null : items[collectionIndex];
    remove(ref);
    if (target == null) {
      items.add(item);
    } else {
      add(item, collectionIndex: items.indexWhere((i) => identical(i, target)));
    }
  }

  /// Removes the item at [ref]; a collection takes its sub-expenses with it.
  void remove(ItemRef ref) {
    if (ref.child == null) {
      items.removeAt(ref.index);
    } else {
      _setChildren(
        ref.index,
        [...items[ref.index].children]..removeAt(ref.child!),
      );
    }
  }

  MonthTemplate build() => MonthTemplate(
    items: List.unmodifiable(items),
    incomes: List.unmodifiable(incomes),
  );

  void _setChildren(int index, List<TemplateItem> children) =>
      items[index] = items[index].copyWith(children: children);

  void _checkCollection(int index) {
    if (index < 0 || index >= items.length || !items[index].isCollection) {
      throw ArgumentError('Item $index is not a collection');
    }
  }
}

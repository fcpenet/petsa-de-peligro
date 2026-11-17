import '../../../core/db/database.dart';

/// Decides which expenses the Budget list shows for a set of statuses.
///
/// - A plain expense shows when its status is selected.
/// - A collection shows when any of its sub-expenses do (only those are
///   listed under it), or — while it has none — when its own status is
///   selected.
class StatusFilter {
  StatusFilter(Iterable<BudgetItem> items, this.shown)
    : _children = _childrenOf(items);

  final Set<ItemStatus> shown;
  final Map<String, List<BudgetItem>> _children;

  /// Whether anything is filtered out.
  bool get isActive => shown.length < ItemStatus.values.length;

  bool matches(BudgetItem item) {
    final children = _children[item.id];
    if (children == null) return shown.contains(item.status);
    if (children.isEmpty) return shown.contains(item.status);
    return children.any((c) => shown.contains(c.status));
  }

  /// Sub-expenses of [collectionId] to list under it.
  List<BudgetItem> childrenOf(String collectionId) => [
    for (final c in _children[collectionId] ?? const <BudgetItem>[])
      if (shown.contains(c.status)) c,
  ];

  /// How many expenses (not collections) are in each status.
  static Map<ItemStatus, int> counts(Iterable<BudgetItem> items) {
    final children = _childrenOf(items);
    final counts = {for (final s in ItemStatus.values) s: 0};
    for (final i in items) {
      if (children.containsKey(i.id)) continue;
      counts[i.status] = counts[i.status]! + 1;
    }
    return counts;
  }

  static Map<String, List<BudgetItem>> _childrenOf(Iterable<BudgetItem> items) {
    final map = <String, List<BudgetItem>>{
      for (final i in items)
        if (i.isCollection) i.id: [],
    };
    for (final i in items) {
      if (i.parentId != null) (map[i.parentId!] ??= []).add(i);
    }
    return map;
  }
}

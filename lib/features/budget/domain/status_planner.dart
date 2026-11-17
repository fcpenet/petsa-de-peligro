import '../../../core/db/database.dart';
import 'budget_calculator.dart';

/// The status and payment date an item should end up with.
class StatusPatch {
  const StatusPatch(this.status, this.paidAt);

  final ItemStatus status;
  final DateTime? paidAt;

  @override
  bool operator ==(Object other) =>
      other is StatusPatch && other.status == status && other.paidAt == paidAt;

  @override
  int get hashCode => Object.hash(status, paidAt);

  @override
  String toString() => 'StatusPatch($status, $paidAt)';
}

/// The live (non-deleted) items related to one item: the item itself, its
/// parent, its siblings and its children.
class ItemFamily {
  ItemFamily(Iterable<BudgetItem> items)
    : _byId = {
        for (final i in items)
          if (i.deletedAt == null) i.id: i,
      };

  final Map<String, BudgetItem> _byId;

  BudgetItem? operator [](String id) => _byId[id];

  List<BudgetItem> childrenOf(String id) => [
    for (final i in _byId.values)
      if (i.parentId == id) i,
  ];
}

/// The parent's status follows its children: paid when all are paid, dated
/// at the latest child payment. Returns null when there are no children.
StatusPatch? deriveParentPatch(
  Iterable<StatusPatch> children, {
  required DateTime now,
}) {
  final status = deriveParentStatus(children.map((c) => c.status));
  if (status == null) return null;
  if (status != ItemStatus.paid) return StatusPatch(status, null);
  final latest = children
      .map((c) => c.paidAt ?? now)
      .reduce((a, b) => a.isAfter(b) ? a : b);
  return StatusPatch(ItemStatus.paid, latest);
}

/// Works out every status change caused by setting [targetId] to [status].
///
/// Returns patches keyed by item id. The target is always included; other
/// items only when their status or payment date actually changes.
///
/// - Target with sub-expenses: moving it forward brings every sub-expense
///   behind it up to [status] (paying pays them on [paidAt]; already-paid
///   ones keep their date); moving it back brings every sub-expense ahead
///   of it back to [status] (e.g. un-paying reverts them all).
/// - Target that is a sub-expense: its parent is re-derived.
Map<String, StatusPatch> planStatusChange(
  ItemFamily family, {
  required String targetId,
  required ItemStatus status,
  required DateTime paidAt,
  required DateTime now,
}) {
  final target = family[targetId];
  if (target == null) throw ArgumentError('Item $targetId not in family');

  final patches = <String, StatusPatch>{
    targetId: StatusPatch(status, status == ItemStatus.paid ? paidAt : null),
  };

  final forward = !status.isBefore(target.status);
  for (final child in family.childrenOf(targetId)) {
    final behind = child.status.isBefore(status);
    final ahead = status.isBefore(child.status);
    if (forward ? !behind && status != ItemStatus.paid : !ahead) continue;
    final next = status == ItemStatus.paid
        ? StatusPatch(
            ItemStatus.paid,
            child.status == ItemStatus.paid ? child.paidAt ?? paidAt : paidAt,
          )
        : StatusPatch(status, null);
    _putIfChanged(patches, child, next);
  }

  final parentId = target.parentId;
  if (parentId != null) {
    final parent = family[parentId];
    if (parent != null) {
      final siblings = [
        for (final s in family.childrenOf(parentId))
          patches[s.id] ?? StatusPatch(s.status, s.paidAt),
      ];
      final derived = deriveParentPatch(siblings, now: now);
      if (derived != null) _putIfChanged(patches, parent, derived);
    }
  }
  return patches;
}

/// Re-derives [parentId] from its current children, e.g. after a sub-expense
/// was added or deleted. Returns null when nothing changes or the parent has
/// no children left (it then keeps its own status).
StatusPatch? planParentRederive(
  ItemFamily family,
  String parentId, {
  required DateTime now,
}) {
  final parent = family[parentId];
  if (parent == null) return null;
  final derived = deriveParentPatch([
    for (final c in family.childrenOf(parentId))
      StatusPatch(c.status, c.paidAt),
  ], now: now);
  if (derived == null || derived == StatusPatch(parent.status, parent.paidAt)) {
    return null;
  }
  return derived;
}

void _putIfChanged(
  Map<String, StatusPatch> patches,
  BudgetItem item,
  StatusPatch next,
) {
  if (next != StatusPatch(item.status, item.paidAt)) patches[item.id] = next;
}

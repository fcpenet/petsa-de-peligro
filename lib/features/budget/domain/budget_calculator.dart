import '../../../core/db/database.dart';

/// A parent's status follows its sub-expenses: paid only when all are paid.
/// Returns null when there are no sub-expenses (the parent's own status
/// applies).
ItemStatus? deriveParentStatus(Iterable<ItemStatus> childStatuses) {
  if (childStatuses.isEmpty) return null;
  return childStatuses.every((s) => s == ItemStatus.paid)
      ? ItemStatus.paid
      : ItemStatus.allotted;
}

class AccountTotals {
  const AccountTotals({required this.allottedCents, required this.paidCents});

  final int allottedCents;
  final int paidCents;

  /// Allotted but not yet paid — the per-account number from the sheet.
  int get remainingCents => allottedCents - paidCents;
}

class ParentTotals {
  const ParentTotals({
    required this.budgetCents,
    required this.usedCents,
    required this.paidCents,
    required this.childCount,
    required this.paidCount,
    required this.usedByAccount,
  });

  /// The parent's own amount: a cap for its sub-expenses.
  final int budgetCents;

  /// Sum of all sub-expenses.
  final int usedCents;

  /// Sum of paid sub-expenses.
  final int paidCents;

  final int childCount;
  final int paidCount;

  /// Sub-expense totals per account id (null = no account set).
  final Map<String?, int> usedByAccount;

  /// Negative when sub-expenses exceed the budget.
  int get leftCents => budgetCents - usedCents;
  bool get isOverBudget => usedCents > budgetCents;

  /// What this parent reserves from the month: its cap, or what was actually
  /// used when that exceeds the cap.
  int get effectiveAllottedCents =>
      usedCents > budgetCents ? usedCents : budgetCents;

  /// Unused part of the cap. Not tied to any account.
  int get slackCents => leftCents > 0 ? leftCents : 0;
}

class MonthTotals {
  const MonthTotals({
    required this.incomeCents,
    required this.allottedCents,
    required this.paidCents,
    required this.remainingCents,
    required this.slackCents,
    required this.byAccount,
    required this.byParent,
  });

  final int incomeCents;

  /// Total reserved for the month. Equals paid + remaining + slack.
  final int allottedCents;

  final int paidCents;

  /// Allotted but unpaid, across all accounts.
  final int remainingCents;

  /// Unused parent budget caps.
  final int slackCents;

  /// Keyed by account id; null collects items with no account.
  final Map<String?, AccountTotals> byAccount;

  /// Keyed by parent item id (only items that have sub-expenses).
  final Map<String, ParentTotals> byParent;

  /// Income not yet given a job. Negative means over-allotted.
  int get unallottedCents => incomeCents - allottedCents;
}

/// Computes all totals for a month.
///
/// Rules:
/// - Account and paid/remaining totals count only *leaf* items (items with no
///   sub-expenses), so a parent never double-counts its children.
/// - A parent with sub-expenses contributes `max(cap, used)` to the month's
///   allotted total. The unused part of the cap is reported as slack.
/// - Soft-deleted items and incomes are ignored.
MonthTotals computeMonthTotals({
  required Iterable<BudgetItem> items,
  required Iterable<Income> incomes,
}) {
  final live = items.where((i) => i.deletedAt == null).toList();
  final childrenOf = <String, List<BudgetItem>>{};
  for (final item in live) {
    if (item.parentId != null) {
      (childrenOf[item.parentId!] ??= []).add(item);
    }
  }

  final accountAllotted = <String?, int>{};
  final accountPaid = <String?, int>{};
  var paid = 0;
  var remaining = 0;

  for (final item in live) {
    final isLeaf = !childrenOf.containsKey(item.id);
    if (!isLeaf) continue;
    accountAllotted.update(
      item.accountId,
      (v) => v + item.amountCents,
      ifAbsent: () => item.amountCents,
    );
    if (item.status == ItemStatus.paid) {
      accountPaid.update(
        item.accountId,
        (v) => v + item.amountCents,
        ifAbsent: () => item.amountCents,
      );
      paid += item.amountCents;
    } else {
      remaining += item.amountCents;
    }
  }

  final byParent = <String, ParentTotals>{};
  var allotted = 0;
  var slack = 0;

  for (final item in live.where((i) => i.parentId == null)) {
    final children = childrenOf[item.id];
    if (children == null) {
      allotted += item.amountCents;
      continue;
    }
    final usedByAccount = <String?, int>{};
    var used = 0;
    var childPaid = 0;
    var paidCount = 0;
    for (final c in children) {
      used += c.amountCents;
      usedByAccount.update(
        c.accountId,
        (v) => v + c.amountCents,
        ifAbsent: () => c.amountCents,
      );
      if (c.status == ItemStatus.paid) {
        childPaid += c.amountCents;
        paidCount++;
      }
    }
    final totals = ParentTotals(
      budgetCents: item.amountCents,
      usedCents: used,
      paidCents: childPaid,
      childCount: children.length,
      paidCount: paidCount,
      usedByAccount: usedByAccount,
    );
    byParent[item.id] = totals;
    allotted += totals.effectiveAllottedCents;
    slack += totals.slackCents;
  }

  return MonthTotals(
    incomeCents: incomes
        .where((i) => i.deletedAt == null)
        .fold(0, (sum, i) => sum + i.amountCents),
    allottedCents: allotted,
    paidCents: paid,
    remainingCents: remaining,
    slackCents: slack,
    byAccount: {
      for (final id in accountAllotted.keys)
        id: AccountTotals(
          allottedCents: accountAllotted[id]!,
          paidCents: accountPaid[id] ?? 0,
        ),
    },
    byParent: byParent,
  );
}

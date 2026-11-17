import '../../../core/db/database.dart';

/// A parent's status follows its sub-expenses: the least advanced one (paid
/// only when all are paid, planned while any is planned). Returns null when
/// there are no sub-expenses (the parent's own status applies).
ItemStatus? deriveParentStatus(Iterable<ItemStatus> childStatuses) {
  if (childStatuses.isEmpty) return null;
  return childStatuses.reduce((a, b) => a.isBefore(b) ? a : b);
}

class AccountTotals {
  const AccountTotals({
    required this.allottedCents,
    required this.paidCents,
    this.plannedCents = 0,
  });

  /// Everything budgeted from this account, whatever its status.
  final int allottedCents;
  final int paidCents;

  /// Still planned: the money hasn't been moved into the account yet.
  final int plannedCents;

  /// Not paid yet (planned or allotted) — the per-account number from the
  /// sheet.
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
    this.expectedByIncome = const {},
    this.receivedByIncome = const {},
    this.balanceByAccount = const {},
    required this.allottedCents,
    required this.paidCents,
    required this.remainingCents,
    this.plannedCents = 0,
    required this.slackCents,
    required this.byAccount,
    required this.byParent,
  });

  /// Expected income. Budgeting (unallotted) is planned against this.
  final int incomeCents;

  /// Expected amount per income id.
  final Map<String, int> expectedByIncome;

  /// Top-ups received so far, per income id.
  final Map<String, int> receivedByIncome;

  /// Income that actually arrived.
  int get receivedCents => receivedByIncome.values.fold(0, (s, v) => s + v);

  /// Expected income still to arrive. An income that came in above what
  /// was expected doesn't make up for one that's short.
  int get toReceiveCents => expectedByIncome.entries.fold(0, (s, e) {
    final short = e.value - (receivedByIncome[e.key] ?? 0);
    return short > 0 ? s + short : s;
  });

  /// Money each account has spare (positive) or is short (negative) because
  /// expenses were paid from another account than planned, after
  /// transfers. Accounts that are even are left out. Sums to zero.
  final Map<String, int> balanceByAccount;

  /// Moves that would even out [balanceByAccount].
  List<SuggestedTransfer> get suggestedTransfers =>
      suggestTransfers(balanceByAccount);

  /// Total reserved for the month. Equals paid + remaining + slack.
  final int allottedCents;

  final int paidCents;

  /// Not paid yet (planned or allotted), across all accounts.
  final int remainingCents;

  /// Still planned: money not yet moved into the accounts ("to allot").
  final int plannedCents;

  /// Unused parent budget caps.
  final int slackCents;

  /// Keyed by account id; null collects items with no account.
  final Map<String?, AccountTotals> byAccount;

  /// Keyed by parent item id (only items that have sub-expenses).
  final Map<String, ParentTotals> byParent;

  /// Expected income not given to any expense. Negative means the month
  /// budgets more than it expects.
  int get unbudgetedCents => incomeCents - allottedCents;
}

/// Move [amountCents] from [fromAccountId] to [toAccountId].
class SuggestedTransfer {
  const SuggestedTransfer(
    this.fromAccountId,
    this.toAccountId,
    this.amountCents,
  );

  final String fromAccountId;
  final String toAccountId;
  final int amountCents;

  @override
  bool operator ==(Object other) =>
      other is SuggestedTransfer &&
      other.fromAccountId == fromAccountId &&
      other.toAccountId == toAccountId &&
      other.amountCents == amountCents;

  @override
  int get hashCode => Object.hash(fromAccountId, toAccountId, amountCents);

  @override
  String toString() =>
      'SuggestedTransfer($fromAccountId → $toAccountId, $amountCents)';
}

/// Few moves that even out [balances]: the account with the most spare
/// money covers the one most short, and so on.
List<SuggestedTransfer> suggestTransfers(Map<String, int> balances) {
  int byAmount(MapEntry<String, int> a, MapEntry<String, int> b) {
    final c = b.value.abs().compareTo(a.value.abs());
    return c != 0 ? c : a.key.compareTo(b.key);
  }

  final spare = [
    for (final e in balances.entries)
      if (e.value > 0) MapEntry(e.key, e.value),
  ]..sort(byAmount);
  final short = [
    for (final e in balances.entries)
      if (e.value < 0) MapEntry(e.key, -e.value),
  ]..sort(byAmount);

  final moves = <SuggestedTransfer>[];
  var i = 0, j = 0;
  var have = spare.isEmpty ? 0 : spare[0].value;
  var need = short.isEmpty ? 0 : short[0].value;
  while (i < spare.length && j < short.length) {
    final amount = have < need ? have : need;
    moves.add(SuggestedTransfer(spare[i].key, short[j].key, amount));
    have -= amount;
    need -= amount;
    if (have == 0 && ++i < spare.length) have = spare[i].value;
    if (need == 0 && ++j < short.length) need = short[j].value;
  }
  return moves;
}

/// Computes all totals for a month.
///
/// Rules:
/// - Account and paid/remaining totals count only *leaf* items (not
///   collections), so a collection never double-counts its sub-expenses.
///   A sub-expense without an account counts toward its collection's.
/// - A collection contributes `max(cap, used)` to the month's allotted
///   total, even before it has sub-expenses. The unused part of the cap is
///   reported as slack.
/// - Soft-deleted items and incomes are ignored.
/// - Income is planned on the expected amount; [topUps] give what arrived.
/// - A paid item's `paidFromAccountId` (when set) is where the money really
///   came from; the difference from the plan, after [transfers], is
///   reported per account in `balanceByAccount`.
MonthTotals computeMonthTotals({
  required Iterable<BudgetItem> items,
  required Iterable<Income> incomes,
  Iterable<TopUp> topUps = const [],
  Iterable<Transfer> transfers = const [],
}) {
  final live = items.where((i) => i.deletedAt == null).toList();
  final byId = {for (final i in live) i.id: i};
  final childrenOf = <String, List<BudgetItem>>{
    for (final i in live)
      if (i.isCollection) i.id: [],
  };
  for (final item in live) {
    if (item.parentId != null) {
      (childrenOf[item.parentId!] ??= []).add(item);
    }
  }

  /// A sub-expense without its own account is paid from its collection's.
  String? accountOf(BudgetItem i) =>
      i.accountId ?? (i.parentId == null ? null : byId[i.parentId]?.accountId);

  final accountAllotted = <String?, int>{};
  final accountPaid = <String?, int>{};
  final accountPlanned = <String?, int>{};
  var planned = 0;
  // Planned minus actually paid, per account; becomes balanceByAccount.
  final balance = <String, int>{};
  void shift(String? account, int cents) {
    if (account == null || cents == 0) return;
    balance.update(account, (v) => v + cents, ifAbsent: () => cents);
  }

  var paid = 0;
  var remaining = 0;

  for (final item in live) {
    final isLeaf = !childrenOf.containsKey(item.id);
    if (!isLeaf) continue;
    final account = accountOf(item);
    accountAllotted.update(
      account,
      (v) => v + item.amountCents,
      ifAbsent: () => item.amountCents,
    );
    if (item.status == ItemStatus.paid) {
      accountPaid.update(
        account,
        (v) => v + item.amountCents,
        ifAbsent: () => item.amountCents,
      );
      paid += item.amountCents;
      final actual = item.paidFromAccountId ?? account;
      if (actual != account) {
        shift(account, item.amountCents); // set aside here, not spent
        shift(actual, -item.amountCents); // spent here, not planned
      }
    } else {
      remaining += item.amountCents;
      if (item.status == ItemStatus.planned) {
        planned += item.amountCents;
        accountPlanned.update(
          account,
          (v) => v + item.amountCents,
          ifAbsent: () => item.amountCents,
        );
      }
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
        accountOf(c),
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

  final expected = {
    for (final i in incomes.where((i) => i.deletedAt == null))
      i.id: i.amountCents,
  };
  final received = <String, int>{};
  for (final t in topUps) {
    // Top-ups of deleted incomes don't count.
    if (t.deletedAt != null || !expected.containsKey(t.incomeId)) continue;
    received.update(
      t.incomeId,
      (v) => v + t.amountCents,
      ifAbsent: () => t.amountCents,
    );
  }

  for (final t in transfers) {
    if (t.deletedAt != null) continue;
    shift(t.fromAccountId, -t.amountCents);
    shift(t.toAccountId, t.amountCents);
  }

  return MonthTotals(
    incomeCents: expected.values.fold(0, (sum, v) => sum + v),
    balanceByAccount: {
      for (final MapEntry(:key, :value) in balance.entries)
        if (value != 0) key: value,
    },
    expectedByIncome: expected,
    receivedByIncome: received,
    allottedCents: allotted,
    paidCents: paid,
    remainingCents: remaining,
    plannedCents: planned,
    slackCents: slack,
    byAccount: {
      for (final id in accountAllotted.keys)
        id: AccountTotals(
          allottedCents: accountAllotted[id]!,
          paidCents: accountPaid[id] ?? 0,
          plannedCents: accountPlanned[id] ?? 0,
        ),
    },
    byParent: byParent,
  );
}

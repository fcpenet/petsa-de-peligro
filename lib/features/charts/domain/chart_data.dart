import '../../../core/db/database.dart';
import '../../budget/domain/budget_calculator.dart';

/// Totals for the charts, from expenses only: collections with
/// sub-expenses are left out (their sub-expenses count instead), so nothing
/// is counted twice.
class ChartData {
  ChartData({
    required this.byStatus,
    required this.byAccount,
    required this.byName,
    required this.byKind,
  });

  /// Cents per status.
  final Map<ItemStatus, int> byStatus;

  /// Cents per status for each account (null = no account), in the order
  /// accounts first appear.
  final Map<String?, Map<ItemStatus, int>> byAccount;

  /// Cents per expense name, biggest first. The same name in different
  /// months adds up (so "Rent" over three months is one slice).
  final List<(String, int)> byName;

  /// Cents per kind (expense, savings, debt), biggest first.
  final List<(ItemKind, int)> byKind;

  int get totalCents => byStatus.values.fold(0, (s, v) => s + v);

  bool get isEmpty => totalCents == 0;

  /// [byName] cut to the [max] biggest, the rest summed as one entry whose
  /// name is null.
  List<(String?, int)> topNames(int max) {
    if (byName.length <= max) return byName;
    final rest = byName.skip(max - 1).fold(0, (s, e) => s + e.$2);
    return [...byName.take(max - 1), (null, rest)];
  }
}

/// Builds [ChartData] from [items] (expenses with their collections).
/// [include] decides which expenses count, e.g. only those dated in a range.
ChartData chartDataFor(
  Iterable<BudgetItem> items, {
  bool Function(BudgetItem item)? include,
}) {
  final live = items.where((i) => i.deletedAt == null).toList();
  final byId = {for (final i in live) i.id: i};
  final parents = {for (final i in live) ?i.parentId};

  final byStatus = {for (final s in ItemStatus.values) s: 0};
  final byAccount = <String?, Map<ItemStatus, int>>{};
  final byName = <String, int>{};
  final displayName = <String, String>{};
  final byKind = <ItemKind, int>{};

  for (final i in live) {
    if (parents.contains(i.id)) continue; // counted through its children
    if (include != null && !include(i)) continue;
    final cents = i.amountCents;
    if (cents == 0) continue;
    byStatus[i.status] = byStatus[i.status]! + cents;
    final account = i.accountId ?? byId[i.parentId]?.accountId;
    final perStatus = byAccount.putIfAbsent(
      account,
      () => {for (final s in ItemStatus.values) s: 0},
    );
    perStatus[i.status] = perStatus[i.status]! + cents;
    final key = i.name.trim().toLowerCase();
    displayName.putIfAbsent(key, () => i.name.trim());
    byName[key] = (byName[key] ?? 0) + cents;
    byKind[i.kind] = (byKind[i.kind] ?? 0) + cents;
  }

  List<(K, int)> sorted<K>(Map<K, int> m) =>
      [for (final e in m.entries) (e.key, e.value)]
        ..sort((a, b) => b.$2.compareTo(a.$2));

  return ChartData(
    byStatus: byStatus,
    byAccount: byAccount,
    byName: [for (final (k, v) in sorted(byName)) (displayName[k]!, v)],
    byKind: sorted(byKind),
  );
}

/// One month in the month-by-month chart.
class MonthPoint {
  MonthPoint({
    required this.yearMonth,
    required this.expensesCents,
    required this.paidCents,
    required this.incomeCents,
    required this.receivedCents,
  });

  final String yearMonth;

  /// Everything budgeted for the month.
  final int expensesCents;
  final int paidCents;

  /// Expected income.
  final int incomeCents;

  /// Income actually received (top-ups).
  final int receivedCents;
}

/// The months from [from] to [to] ('YYYY-MM', inclusive), oldest first.
List<String> monthsBetween(String from, String to) {
  var [y, m] = [for (final p in from.split('-')) int.parse(p)];
  final [ty, tm] = [for (final p in to.split('-')) int.parse(p)];
  final out = <String>[];
  while (y < ty || (y == ty && m <= tm)) {
    out.add('$y-${m.toString().padLeft(2, '0')}');
    if (++m > 12) {
      m = 1;
      y++;
    }
  }
  return out;
}

/// [count] months ending with [yearMonth], oldest first.
List<String> monthsEndingAt(String yearMonth, int count) {
  var [y, m] = [for (final p in yearMonth.split('-')) int.parse(p)];
  m -= count - 1;
  while (m < 1) {
    m += 12;
    y--;
  }
  return monthsBetween('$y-${m.toString().padLeft(2, '0')}', yearMonth);
}

/// One [MonthPoint] per month in [yearMonths], from rows tagged with their
/// month. Months without data are zeros.
List<MonthPoint> monthlySeries({
  required List<String> yearMonths,
  required List<(BudgetItem, String)> items,
  required List<(Income, String)> incomes,
  required List<(TopUp, String)> topUps,
}) => [
  for (final ym in yearMonths)
    () {
      final totals = computeMonthTotals(
        items: [
          for (final (i, m) in items)
            if (m == ym) i,
        ],
        incomes: [
          for (final (i, m) in incomes)
            if (m == ym) i,
        ],
        topUps: [
          for (final (t, m) in topUps)
            if (m == ym) t,
        ],
      );
      return MonthPoint(
        yearMonth: ym,
        expensesCents: totals.allottedCents,
        paidCents: totals.paidCents,
        incomeCents: totals.incomeCents,
        receivedCents: totals.receivedCents,
      );
    }(),
];

import '../../../core/db/database.dart';
import '../../budget/domain/budget_calculator.dart';

/// One account's month: what was budgeted from it and how far along it is.
class AccountSummary {
  const AccountSummary({
    required this.account,
    required this.budgetedCents,
    required this.plannedCents,
    required this.allottedCents,
    this.chargedCents = 0,
    required this.paidCents,
    required this.balanceCents,
    required this.items,
  });

  final Account account;

  /// Everything budgeted from this account (sub-expenses included).
  final int budgetedCents;

  /// Still planned: not moved into the account yet.
  final int plannedCents;

  /// In the account, waiting to be paid.
  final int allottedCents;

  /// Charged to a card, bill not paid yet ("to settle").
  final int chargedCents;

  /// Paid (for a credit card: settled).
  final int paidCents;

  /// Spare (positive) or short (negative) after expenses paid from another
  /// account than planned, and transfers.
  final int balanceCents;

  /// The expenses budgeted from this account, sub-expenses included.
  final List<BudgetItem> items;

  bool get isCard => account.type == AccountType.creditCard;

  /// Not paid yet (planned, allotted or charged).
  int get leftCents => plannedCents + allottedCents + chargedCents;

  /// For a card: not charged to it yet.
  int get notChargedCents => plannedCents + allottedCents;

  /// Share paid, 0–1.
  double get progress => budgetedCents == 0 ? 0 : paidCents / budgetedCents;

  bool get isEmpty => budgetedCents == 0 && balanceCents == 0 && items.isEmpty;
}

/// Totals for a group of accounts (all accounts, or all cards).
class SummaryGroup {
  SummaryGroup(this.accounts);

  final List<AccountSummary> accounts;

  int _sum(int Function(AccountSummary) f) =>
      accounts.fold(0, (s, a) => s + f(a));

  int get budgetedCents => _sum((a) => a.budgetedCents);
  int get plannedCents => _sum((a) => a.plannedCents);
  int get allottedCents => _sum((a) => a.allottedCents);
  int get chargedCents => _sum((a) => a.chargedCents);
  int get notChargedCents => _sum((a) => a.notChargedCents);
  int get paidCents => _sum((a) => a.paidCents);
  int get leftCents => _sum((a) => a.leftCents);
}

class MonthSummary {
  const MonthSummary({
    required this.accounts,
    required this.cards,
    required this.hiddenCount,
  });

  /// Cash, bank and e-wallet accounts with something this month.
  final SummaryGroup accounts;

  /// Credit cards with something this month.
  final SummaryGroup cards;

  /// Accounts left out because nothing touches them this month.
  final int hiddenCount;
}

/// The day an expense counts on for a date range: its payment date once
/// paid, its charge date while charged to a card, otherwise its due day in
/// its month ([yearMonth], e.g. '2026-11'), or the 1st when it has no due
/// day. Due days past the month's end (31 in
/// February) fall on its last day.
DateTime itemDate(BudgetItem item, String yearMonth) {
  final paidAt = item.paidAt;
  if (item.status == ItemStatus.paid && paidAt != null) {
    return DateTime(paidAt.year, paidAt.month, paidAt.day);
  }
  final chargedAt = item.chargedAt;
  if (item.status == ItemStatus.charged && chargedAt != null) {
    return DateTime(chargedAt.year, chargedAt.month, chargedAt.day);
  }
  final [year, month] = [for (final p in yearMonth.split('-')) int.parse(p)];
  final lastDay = DateTime(year, month + 1, 0).day;
  final day = (item.dueDay ?? 1).clamp(1, lastDay);
  return DateTime(year, month, day);
}

/// Inclusive range of days.
typedef DayRange = ({DateTime from, DateTime to});

bool _inRange(DateTime day, DayRange range) =>
    !day.isBefore(range.from) && !day.isAfter(range.to);

/// Splits a month by account, with credit cards on their own. Accounts
/// with nothing this month are left out (archived ones always are, unless
/// used).
MonthSummary summarizeMonth({
  required List<Account> accounts,
  required List<BudgetItem> items,
  List<Transfer> transfers = const [],
}) => _summarize(accounts: accounts, items: items, transfers: transfers);

/// Like [summarizeMonth], but over [range]: items from any month count when
/// their [itemDate] falls in it (collections are kept so sub-expenses find
/// their account), and transfers by the day they were made.
/// [yearMonthOf] maps month ids to 'YYYY-MM'.
MonthSummary summarizeRange({
  required List<Account> accounts,
  required List<BudgetItem> items,
  required Map<String, String> yearMonthOf,
  required DayRange range,
  List<Transfer> transfers = const [],
}) {
  final parents = {for (final i in items) ?i.parentId};
  bool counts(BudgetItem i) {
    if (i.isCollection || parents.contains(i.id)) return true;
    final ym = yearMonthOf[i.monthId];
    return ym != null && _inRange(itemDate(i, ym), range);
  }

  return _summarize(
    accounts: accounts,
    items: [
      for (final i in items)
        if (counts(i)) i,
    ],
    transfers: [
      for (final t in transfers)
        if (_inRange(
          DateTime(
            t.transferredAt.year,
            t.transferredAt.month,
            t.transferredAt.day,
          ),
          range,
        ))
          t,
    ],
  );
}

MonthSummary _summarize({
  required List<Account> accounts,
  required List<BudgetItem> items,
  List<Transfer> transfers = const [],
}) {
  final live = items.where((i) => i.deletedAt == null).toList();
  final totals = computeMonthTotals(
    items: live,
    incomes: const [],
    transfers: transfers,
  );
  final byId = {for (final i in live) i.id: i};
  final parents = {for (final i in live) ?i.parentId};
  String? accountOf(BudgetItem i) =>
      i.accountId ?? (i.parentId == null ? null : byId[i.parentId]?.accountId);

  final summaries = <AccountSummary>[];
  var hidden = 0;
  for (final account in accounts) {
    final t = totals.byAccount[account.id];
    final summary = AccountSummary(
      account: account,
      budgetedCents: t?.allottedCents ?? 0,
      plannedCents: t?.plannedCents ?? 0,
      allottedCents:
          (t?.remainingCents ?? 0) -
          (t?.plannedCents ?? 0) -
          (t?.chargedCents ?? 0),
      chargedCents: t?.chargedCents ?? 0,
      paidCents: t?.paidCents ?? 0,
      balanceCents: totals.balanceByAccount[account.id] ?? 0,
      items: [
        for (final i in live)
          if (!i.isCollection &&
              !parents.contains(i.id) &&
              accountOf(i) == account.id)
            i,
      ],
    );
    if (summary.isEmpty) {
      if (!account.archived) hidden++;
    } else {
      summaries.add(summary);
    }
  }
  return MonthSummary(
    accounts: SummaryGroup([
      for (final s in summaries)
        if (!s.isCard) s,
    ]),
    cards: SummaryGroup([
      for (final s in summaries)
        if (s.isCard) s,
    ]),
    hiddenCount: hidden,
  );
}

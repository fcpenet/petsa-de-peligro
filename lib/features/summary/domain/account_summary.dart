import '../../../core/db/database.dart';
import '../../budget/domain/budget_calculator.dart';

/// One account's month: what was budgeted from it and how far along it is.
class AccountSummary {
  const AccountSummary({
    required this.account,
    required this.budgetedCents,
    required this.plannedCents,
    required this.allottedCents,
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

  /// Paid (for a credit card: settled).
  final int paidCents;

  /// Spare (positive) or short (negative) after expenses paid from another
  /// account than planned, and transfers.
  final int balanceCents;

  /// The expenses budgeted from this account, sub-expenses included.
  final List<BudgetItem> items;

  bool get isCard => account.type == AccountType.creditCard;

  /// Not paid yet (planned or allotted).
  int get leftCents => plannedCents + allottedCents;

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

/// Splits a month by account, with credit cards on their own. Accounts
/// with nothing this month are left out (archived ones always are, unless
/// used).
MonthSummary summarizeMonth({
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
      allottedCents: (t?.remainingCents ?? 0) - (t?.plannedCents ?? 0),
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

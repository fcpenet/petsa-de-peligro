import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../core/db/database.dart';
import '../core/money.dart';
import '../features/accounts/ui/account_form.dart';
import '../features/budget/domain/budget_calculator.dart';
import 'providers.dart';

typedef NavDestination = ({IconData icon, String label, String path});

/// The wide-screen navigation: sections, and under Budget the month's
/// accounts, each opening just that account's expenses.
class SideNav extends StatelessWidget {
  const SideNav({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelect,
    required this.budgetMonth,
    required this.selectedAccount,
    required this.onAccount,
  });

  final List<NavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  /// The month shown on the Budget page, or null when elsewhere.
  final String? budgetMonth;

  /// The `account` filter of the Budget page (null = all accounts).
  final String? selectedAccount;
  final ValueChanged<String?> onAccount;

  static const width = 248.0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final budgetMonth = this.budgetMonth;
    return Material(
      key: const Key('side-nav'),
      color: scheme.surfaceContainerLow,
      child: SizedBox(
        width: width,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
              child: Row(
                children: [
                  const Icon(Icons.savings, color: Color(0xFF188038), size: 28),
                  const SizedBox(width: 10),
                  Text('petsa', style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
            ),
            for (final (i, d) in destinations.indexed) ...[
              _NavTile(
                key: Key('nav-${d.path}'),
                icon: d.icon,
                label: d.label,
                selected: i == selectedIndex && selectedAccount == null,
                highlighted: i == selectedIndex,
                onTap: () => onSelect(i),
              ),
              if (d.path == 'budget' && budgetMonth != null)
                BudgetAccountsNav(
                  yearMonth: budgetMonth,
                  selected: selectedAccount,
                  onSelect: onAccount,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.highlighted = false,
    this.trailing,
    this.indent = 0,
  });

  final IconData icon;
  final String label;

  /// Filled background: this is exactly what's shown.
  final bool selected;

  /// Bold label: the section that's shown (e.g. Budget while an account
  /// inside it is selected).
  final bool highlighted;
  final Widget? trailing;
  final double indent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(left: indent, bottom: 2),
      child: ListTile(
        dense: indent > 0,
        visualDensity: VisualDensity.compact,
        shape: const StadiumBorder(),
        selected: selected,
        selectedColor: scheme.onSecondaryContainer,
        selectedTileColor: scheme.secondaryContainer,
        leading: Icon(icon, size: indent > 0 ? 20 : 24),
        minLeadingWidth: 0,
        horizontalTitleGap: 12,
        title: Text(
          label,
          overflow: TextOverflow.ellipsis,
          style: highlighted || selected
              ? const TextStyle(fontWeight: FontWeight.w600)
              : null,
        ),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}

/// What's left to pay per account in a month, plus account-less collections.
class AccountLeft {
  AccountLeft({required this.byAccount, required this.collectionsLeft});

  final Map<String, int> byAccount;

  /// Null when the month has no account-less collections.
  final int? collectionsLeft;
}

AccountLeft accountLeftFor(List<BudgetItem> items) {
  final totals = computeMonthTotals(items: items, incomes: const []);
  final live = items.where((i) => i.deletedAt == null).toList();
  final loose = [
    for (final i in live)
      if (i.parentId == null && i.accountId == null && i.isCollection) i,
  ];
  var unpaid = 0;
  for (final c in loose) {
    final children = live.where((i) => i.parentId == c.id).toList();
    for (final leaf in children.isEmpty ? [c] : children) {
      if (leaf.status != ItemStatus.paid) unpaid += leaf.amountCents;
    }
  }
  return AccountLeft(
    byAccount: {
      for (final MapEntry(:key, :value) in totals.byAccount.entries)
        ?key: value.remainingCents,
    },
    collectionsLeft: loose.isEmpty ? null : unpaid,
  );
}

/// The accounts listed under Budget, with what's left to pay in each.
class BudgetAccountsNav extends ConsumerWidget {
  const BudgetAccountsNav({
    super.key,
    required this.yearMonth,
    required this.selected,
    required this.onSelect,
  });

  final String yearMonth;
  final String? selected;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(monthProvider(yearMonth)).value;
    final accounts = ref.watch(accountsProvider).value;
    final items = month == null
        ? null
        : ref.watch(itemsProvider(month.id)).value;
    if (accounts == null || items == null) return const SizedBox.shrink();

    final used = {
      for (final i in items) ...[i.accountId, i.paidFromAccountId],
    };
    final shown = [
      for (final a in accounts)
        if (!a.archived || used.contains(a.id)) a,
    ];
    final left = accountLeftFor(items);
    Widget amount(int? cents) => cents == null || cents == 0
        ? const SizedBox.shrink()
        : Text(
            formatPeso(cents),
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
          );

    return Column(
      key: const Key('nav-accounts-list'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final a in shown)
          _NavTile(
            key: Key('nav-account-${a.id}'),
            indent: 16,
            icon: accountTypeIcons[a.type]!,
            label: a.name,
            selected: selected == a.id,
            trailing: amount(left.byAccount[a.id]),
            onTap: () => onSelect(a.id),
          ),
        if (left.collectionsLeft != null)
          _NavTile(
            key: const Key('nav-account-$collectionsFilter'),
            indent: 16,
            icon: Icons.folder_outlined,
            label: 'Collections',
            selected: selected == collectionsFilter,
            trailing: amount(left.collectionsLeft),
            onTap: () => onSelect(collectionsFilter),
          ),
        const SizedBox(height: 8),
      ],
    );
  }
}

/// The Budget page's `account` value for the account-less collections card.
const collectionsFilter = 'collections';

/// The Budget page for [yearMonth], optionally showing one account.
String budgetLocation(String yearMonth, [String? account]) => account == null
    ? '/budget/$yearMonth'
    : '/budget/$yearMonth?account=${Uri.encodeQueryComponent(account)}';

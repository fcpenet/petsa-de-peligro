import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/providers.dart';
import '../../../core/db/database.dart';
import '../../../core/money.dart';
import '../../../core/ui/adaptive.dart';
import '../../accounts/ui/account_form.dart';
import '../../templates/ui/template_widgets.dart';
import '../data/budget_repository.dart';
import '../domain/budget_calculator.dart';
import '../domain/status_filter.dart';
import '../domain/status_planner.dart';
import 'item_form.dart';
import 'simple_forms.dart';

/// The month as a list: totals, one section per account (collections inside
/// their account), income.
/// Route: `/budget/:yearMonth`.
class BudgetPage extends ConsumerWidget {
  const BudgetPage({super.key, required this.yearMonth});

  final String yearMonth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(monthProvider(yearMonth))) {
      AsyncData(:final value) => BudgetView(
        key: ValueKey(value.id),
        month: value,
      ),
      AsyncError(:final error) => Scaffold(
        body: Center(child: Text('Could not load the month: $error')),
      ),
      _ => const Scaffold(body: Center(child: CircularProgressIndicator())),
    };
  }
}

class BudgetView extends ConsumerStatefulWidget {
  const BudgetView({super.key, required this.month});

  final Month month;

  @override
  ConsumerState<BudgetView> createState() => _BudgetViewState();
}

class _BudgetViewState extends ConsumerState<BudgetView> {
  /// Checkbox changes shown immediately, until the database catches up.
  final Map<String, BudgetItem> _overrides = {};
  final Set<String> _settled = {};

  /// Rebalance suggestions hidden with "Not now", until they change.
  String? _dismissedMoves;

  String get _monthId => widget.month.id;
  BudgetRepository get _repo => ref.read(budgetRepositoryProvider);

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// Checkbox tap. Card expenses go empty → charged → paid (unticking a
  /// paid one leaves it charged); everything else toggles paid / allotted.
  void _toggle(BudgetItem item, List<BudgetItem> items, Set<String> cards) {
    final account =
        item.accountId ??
        items.where((i) => i.id == item.parentId).firstOrNull?.accountId;
    final onCard =
        cards.contains(account) &&
        !item.isCollection &&
        !items.any((i) => i.parentId == item.id);
    final status = switch (item.status) {
      ItemStatus.paid => onCard ? ItemStatus.charged : ItemStatus.allotted,
      ItemStatus.charged => ItemStatus.paid,
      _ => onCard ? ItemStatus.charged : ItemStatus.paid,
    };
    final now = DateTime.now();
    final patches = planStatusChange(
      ItemFamily(items),
      targetId: item.id,
      status: status,
      paidAt: now,
      now: now,
    );
    final changes = {
      for (final MapEntry(key: id, value: patch) in patches.entries)
        if (items.where((i) => i.id == id).firstOrNull case final i?)
          id: i.copyWith(
            status: patch.status,
            paidAt: Value(patch.paidAt),
            chargedAt: status == ItemStatus.charged && id == item.id
                ? Value(now)
                : Value(i.chargedAt),
          ),
    };
    setState(() {
      _overrides.addAll(changes);
      _settled.removeAll(changes.keys);
    });
    _repo
        .setStatus(item.id, status, paidAt: now)
        .then(
          (_) => _settled.addAll(changes.keys),
          onError: (Object e) {
            if (!mounted) return;
            setState(() => changes.keys.forEach(_overrides.remove));
            _toast('Could not save: $e');
          },
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(itemsProvider(_monthId), (_, next) {
      if (next.hasValue && _settled.isNotEmpty) {
        setState(() {
          _settled.forEach(_overrides.remove);
          _settled.clear();
        });
      }
    });

    final itemsAsync = ref.watch(itemsProvider(_monthId));
    final incomesAsync = ref.watch(incomesProvider(_monthId));
    final topUpsAsync = ref.watch(topUpsProvider(_monthId));
    final transfersAsync = ref.watch(transfersProvider(_monthId));
    final accountsAsync = ref.watch(accountsProvider);
    final error =
        itemsAsync.error ??
        incomesAsync.error ??
        topUpsAsync.error ??
        transfersAsync.error ??
        accountsAsync.error;
    final loaded =
        itemsAsync.hasValue &&
        incomesAsync.hasValue &&
        topUpsAsync.hasValue &&
        transfersAsync.hasValue &&
        accountsAsync.hasValue;

    Widget body;
    if (error != null) {
      body = Center(child: Text('Something went wrong: $error'));
    } else if (!loaded) {
      body = const Center(child: CircularProgressIndicator());
    } else {
      final items = [
        for (final i in itemsAsync.requireValue) _overrides[i.id] ?? i,
      ];
      body = _content(
        items,
        incomesAsync.requireValue,
        topUpsAsync.requireValue,
        transfersAsync.requireValue,
        accountsAsync.requireValue,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: MonthSwitcher(
          yearMonth: widget.month.yearMonth,
          onChanged: (ym) => context.go('/budget/$ym'),
        ),
        centerTitle: true,
        actions: [
          TemplatesMenu(month: widget.month, onMessage: _toast),
          PopupMenuButton<String>(
            key: const Key('add-menu'),
            tooltip: 'Add',
            icon: const Icon(Icons.add_circle_outline),
            onSelected: (v) => switch (v) {
              'income' => showIncomeForm(context, monthId: _monthId),
              'transfer' => showTransferForm(context, monthId: _monthId),
              'account' => showAccountForm(context),
              _ => null,
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'income', child: Text('Add income')),
              PopupMenuItem(value: 'transfer', child: Text('Move money')),
              PopupMenuItem(value: 'account', child: Text('Add account')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('add-expense'),
        onPressed: () => showItemForm(context, monthId: _monthId),
        icon: const Icon(Icons.add),
        label: const Text('Expense'),
      ),
      body: body,
    );
  }

  Widget _content(
    List<BudgetItem> items,
    List<Income> incomes,
    List<TopUp> topUps,
    List<Transfer> transfers,
    List<Account> accounts,
  ) {
    final totals = computeMonthTotals(
      items: items,
      incomes: incomes,
      topUps: topUps,
      transfers: transfers,
    );
    final moves = totals.suggestedTransfers;
    final movesKey = moves.join();
    final used = {
      for (final i in items) ...[i.accountId, i.paidFromAccountId],
      ...totals.balanceByAccount.keys,
    };
    final shownAccounts = [
      for (final a in accounts)
        if (!a.archived || used.contains(a.id)) a,
    ];
    final accountName = {for (final a in accounts) a.id: a.name};
    final cardIds = {
      for (final a in accounts)
        if (a.type == AccountType.creditCard) a.id,
    };
    final childrenOf = <String, List<BudgetItem>>{
      for (final i in items)
        if (i.isCollection) i.id: [],
    };
    for (final i in items) {
      if (i.parentId != null) (childrenOf[i.parentId!] ??= []).add(i);
    }
    // Collections without an account get their own card; anything else
    // without one (only old data) is listed until an account is chosen.
    final looseCollections = [
      for (final i in items)
        if (i.parentId == null && i.accountId == null && i.isCollection) i,
    ];
    final orphans = [
      for (final i in items)
        if (i.parentId == null && i.accountId == null && !i.isCollection) i,
    ];

    final filter = StatusFilter(items, ref.watch(shownStatusesProvider));
    List<BudgetItem> topLevel(Account? account, {bool collections = false}) => [
      for (final i
          in account == null
              ? (collections ? looseCollections : orphans)
              : [
                  for (final i in items)
                    if (i.parentId == null && i.accountId == account.id) i,
                ])
        if (filter.matches(i)) i,
    ];
    final visibleChildren = {
      for (final id in childrenOf.keys) id: filter.childrenOf(id),
    };
    // While filtering, sections with nothing to show are hidden.
    bool showSection(Account? account, {bool collections = false}) =>
        !filter.isActive ||
        topLevel(account, collections: collections).isNotEmpty;
    final nothingMatches =
        filter.isActive &&
        !shownAccounts.any(showSection) &&
        !(looseCollections.isNotEmpty &&
            showSection(null, collections: true)) &&
        !(orphans.isNotEmpty && showSection(null));

    Widget section(Account? account, {bool collections = false}) =>
        _AccountSection(
          account: account,
          collectionsCard: collections,
          items: topLevel(account, collections: collections),
          childrenOf: visibleChildren,
          totals: totals,
          accountName: accountName,
          onToggle: (i) => _toggle(i, items, cardIds),
          onEdit: (i) => showItemForm(context, monthId: _monthId, existing: i),
          onAdd: account == null
              ? null
              : () => showItemForm(
                  context,
                  monthId: _monthId,
                  accountId: account.id,
                ),
          onAddSub: (c) =>
              showItemForm(context, monthId: _monthId, parentId: c.id),
          onAllot: account == null
              ? null
              : () async {
                  final n = await _repo.allotAccount(_monthId, account.id);
                  _toast(
                    'Marked $n expense${n == 1 ? '' : 's'} in '
                    '${account.name} as allotted',
                  );
                },
          onSettle: account == null || !cardIds.contains(account.id)
              ? null
              : () async {
                  final n = await _repo.settleCard(_monthId, account.id);
                  _toast(
                    'Paid the ${account.name} bill: $n '
                    'expense${n == 1 ? '' : 's'}',
                  );
                },
        );

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
          children: [
            if (items.isEmpty && incomes.isEmpty)
              EmptyMonthBanner(month: widget.month, onMessage: _toast),
            _SummaryCard(totals: totals),
            if (moves.isNotEmpty && movesKey != _dismissedMoves)
              _RebalanceCard(
                moves: moves,
                accountName: accountName,
                onMoved: (m) async {
                  await _repo.addTransfer(
                    monthId: _monthId,
                    fromAccountId: m.fromAccountId,
                    toAccountId: m.toAccountId,
                    amountCents: m.amountCents,
                    transferredAt: DateTime.now(),
                  );
                  _toast(
                    'Recorded ${formatPeso(m.amountCents)} moved to '
                    '${accountName[m.toAccountId]}',
                  );
                },
                onDismiss: () => setState(() => _dismissedMoves = movesKey),
              ),
            if (accounts.isEmpty)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.account_balance),
                  title: const Text('Add your first account'),
                  subtitle: const Text(
                    'Banks, cards and wallets you pay expenses from.',
                  ),
                  trailing: const Icon(Icons.add),
                  onTap: () => showAccountForm(context),
                ),
              ),
            if (items.isNotEmpty)
              _StatusFilterBar(
                showCharged:
                    cardIds.isNotEmpty ||
                    StatusFilter.counts(items)[ItemStatus.charged]! > 0,
                counts: StatusFilter.counts(items),
                shown: filter.shown,
                onToggle: ref.read(shownStatusesProvider.notifier).toggle,
                onShowAll: ref.read(shownStatusesProvider.notifier).showAll,
              ),
            if (nothingMatches)
              const Card(
                key: Key('filter-empty'),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No expenses match the selected statuses.'),
                ),
              ),
            for (final account in shownAccounts)
              if (showSection(account)) section(account),
            if (looseCollections.isNotEmpty &&
                showSection(null, collections: true))
              section(null, collections: true),
            if (orphans.isNotEmpty && showSection(null)) section(null),
            if (transfers.isNotEmpty)
              _TransfersSection(
                transfers: transfers,
                accountName: accountName,
                onEdit: (t) =>
                    showTransferForm(context, monthId: _monthId, existing: t),
              ),
            _IncomeSection(
              incomes: incomes,
              totals: totals,
              lastTopUp: {for (final t in topUps) t.incomeId: t.receivedAt},
              onTopUp: (i) => showTopUpForm(context, income: i),
              onEdit: (i) =>
                  showIncomeForm(context, monthId: _monthId, existing: i),
              onAdd: () => showIncomeForm(context, monthId: _monthId),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ pieces

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.totals});

  final MonthTotals totals;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget stat(String label, int cents, {Color? color, bool big = false}) =>
        SizedBox(
          width: 150,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelMedium),
              Text(
                formatPeso(cents),
                key: Key('stat-$label'),
                style:
                    (big
                            ? Theme.of(context).textTheme.titleLarge
                            : Theme.of(context).textTheme.titleMedium)
                        ?.copyWith(color: color, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 16,
          runSpacing: 12,
          children: [
            stat('Left to pay', totals.remainingCents, big: true),
            stat(
              'Unbudgeted',
              totals.unbudgetedCents,
              big: true,
              color: totals.unbudgetedCents < 0 ? scheme.error : null,
            ),
            stat('Expected income', totals.incomeCents),
            stat('Received', totals.receivedCents),
            stat('Expenses', totals.allottedCents),
            stat('To allot', totals.plannedCents),
            if (totals.chargedCents > 0)
              stat('Card bills', totals.chargedCents),
            stat('Paid', totals.paidCents),
          ],
        ),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.item,
    required this.onToggle,
    required this.onTap,
    this.extra,
    this.paidFrom,
    this.indent = 0,
  });

  /// Name of the account it was actually paid from, when not as planned.
  final String? paidFrom;

  final BudgetItem item;

  /// Left padding, for sub-expenses.
  final double indent;
  final VoidCallback onToggle;
  final VoidCallback onTap;

  /// Extra subtitle detail, e.g. the account of a sub-expense.
  final String? extra;

  @override
  Widget build(BuildContext context) {
    final paid = item.status == ItemStatus.paid;
    final details = [
      ?extra,
      if (item.kind != ItemKind.expense) itemKindLabels[item.kind]!,
      if (item.status == ItemStatus.planned) 'Planned',
      if (item.status == ItemStatus.charged)
        item.chargedAt == null
            ? 'Charged'
            : 'Charged ${formatShortDate(item.chargedAt!)}',
      if (paid && paidFrom != null) 'Paid from $paidFrom',
      if (paid && item.paidAt != null)
        'Paid ${formatShortDate(item.paidAt!)}'
      else if (item.dueDay != null)
        'Due on the ${_ordinal(item.dueDay!)}',
      ?item.note,
    ];
    return ListTile(
      key: ValueKey('item-${item.id}'),
      contentPadding: EdgeInsets.only(left: 4 + indent, right: 16),
      // A dash means charged to a card, bill not paid yet.
      leading: Checkbox(
        key: ValueKey('paid-${item.id}'),
        tristate: true,
        value: paid
            ? true
            : item.status == ItemStatus.charged
            ? null
            : false,
        onChanged: (_) => onToggle(),
      ),
      title: Text(
        item.name,
        style: paid
            ? TextStyle(color: Theme.of(context).colorScheme.outline)
            : null,
      ),
      subtitle: details.isEmpty ? null : Text(details.join(' · ')),
      trailing: Text(
        formatPeso(item.amountCents),
        style: Theme.of(context).textTheme.bodyLarge
            ?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
      ),
      onTap: onTap,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.trailing,
    this.subtitle,
    this.leading,
  });

  final String title;
  final String? subtitle;
  final String trailing;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: leading,
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: Text(trailing, style: theme.textTheme.titleSmall),
    );
  }
}

/// An account's expenses. Collections show their sub-expenses indented
/// underneath. With a null [account] it lists expenses that have none.
class _AccountSection extends StatelessWidget {
  const _AccountSection({
    required this.account,
    this.collectionsCard = false,
    required this.items,
    required this.childrenOf,
    required this.totals,
    required this.accountName,
    required this.onToggle,
    required this.onEdit,
    required this.onAdd,
    required this.onAddSub,
    this.onAllot,
    this.onSettle,
  });

  final Account? account;

  /// The card for collections that have no account.
  final bool collectionsCard;

  /// Top-level expenses in this account.
  final List<BudgetItem> items;
  final Map<String, List<BudgetItem>> childrenOf;
  final MonthTotals totals;
  final Map<String, String> accountName;
  final ValueChanged<BudgetItem> onToggle;
  final ValueChanged<BudgetItem> onEdit;
  final VoidCallback? onAdd;
  final ValueChanged<BudgetItem> onAddSub;

  /// Marks everything planned for this account as allotted.
  final VoidCallback? onAllot;

  /// For a credit card: pays the bill (charged → paid).
  final VoidCallback? onSettle;

  @override
  Widget build(BuildContext context) {
    final account = this.account;
    final unpaidLeaves = [
      for (final i in items) ...childrenOf[i.id] ?? [i],
    ].where((i) => i.status != ItemStatus.paid);
    final remaining = collectionsCard
        ? unpaidLeaves.fold(0, (s, i) => s + i.amountCents)
        : totals.byAccount[account?.id]?.remainingCents ?? 0;
    // Unpaid here that's charged to this account; the rest of `remaining`
    // comes from sub-expenses in other accounts' collections.
    final own = unpaidLeaves
        .where((i) => i.accountId == null || i.accountId == account?.id)
        .fold(0, (s, i) => s + i.amountCents);
    final fromOthers = remaining - own;
    return Card(
      key: collectionsCard
          ? const ValueKey('collections-section')
          : ValueKey('account-section-${account?.id ?? 'none'}'),
      child: Column(
        children: [
          _SectionHeader(
            leading: Icon(
              collectionsCard
                  ? Icons.folder_outlined
                  : account == null
                  ? Icons.help_outline
                  : accountTypeIcons[account.type],
            ),
            title: collectionsCard
                ? 'Collections'
                : account?.name ?? 'No account',
            subtitle: collectionsCard
                ? 'Each sub-expense counts toward its own account'
                : account == null
                ? 'Tap an expense to choose its account'
                : [
                    if (fromOthers > 0)
                      'Incl. ${formatPeso(fromOthers)} from other collections',
                    if (totals.balanceByAccount[account.id] case final b?)
                      b > 0
                          ? '${formatPeso(b)} unused'
                          : '${formatPeso(-b)} over',
                  ].join(' · ').emptyAsNull,
            trailing: remaining == 0
                ? 'All paid'
                : '${formatPeso(remaining)} left',
          ),
          if ((totals.byAccount[account?.id]?.plannedCents ?? 0)
              case final toAllot
              when toAllot > 0 && onAllot != null && !collectionsCard)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${formatPeso(toAllot)} still to move into '
                      '${account!.name}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  FilledButton.tonalIcon(
                    key: ValueKey('allot-${account.id}'),
                    onPressed: onAllot,
                    icon: const Icon(Icons.move_down, size: 18),
                    label: const Text('Allot'),
                  ),
                ],
              ),
            ),
          if ((totals.byAccount[account?.id]?.chargedCents ?? 0) case final bill
              when bill > 0 && onSettle != null)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${formatPeso(bill)} charged, bill not paid yet',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  FilledButton.tonalIcon(
                    key: ValueKey('settle-${account!.id}'),
                    onPressed: onSettle,
                    icon: const Icon(Icons.credit_score, size: 18),
                    label: const Text('Pay bill'),
                  ),
                ],
              ),
            ),
          for (final item in items)
            if (childrenOf[item.id] case final children?)
              _CollectionBlock(
                collection: item,
                children: children,
                totals: totals.byParent[item.id],
                accountName: accountName,
                onToggle: onToggle,
                onEdit: onEdit,
                onAdd: () => onAddSub(item),
              )
            else
              _ItemRow(
                item: item,
                paidFrom: accountName[item.paidFromAccountId],
                onToggle: () => onToggle(item),
                onTap: () => onEdit(item),
              ),
          if (onAdd != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: ValueKey('add-to-${account!.id}'),
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: Text('Add to ${account.name}'),
              ),
            ),
        ],
      ),
    );
  }
}

/// A collection row (budget, used, paid count) and its sub-expenses.
class _CollectionBlock extends StatelessWidget {
  const _CollectionBlock({
    required this.collection,
    required this.children,
    required this.totals,
    required this.accountName,
    required this.onToggle,
    required this.onEdit,
    required this.onAdd,
  });

  final BudgetItem collection;
  final List<BudgetItem> children;
  final ParentTotals? totals;
  final Map<String, String> accountName;
  final ValueChanged<BudgetItem> onToggle;
  final ValueChanged<BudgetItem> onEdit;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final used = totals?.usedCents ?? 0;
    final budget = collection.amountCents;
    final left = totals?.leftCents ?? budget;
    final paidCount = totals?.paidCount ?? 0;
    final paid = collection.status == ItemStatus.paid;
    return Padding(
      key: ValueKey('collection-${collection.id}'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            ListTile(
              key: ValueKey('item-${collection.id}'),
              contentPadding: const EdgeInsets.only(left: 0, right: 12),
              leading: Checkbox(
                key: ValueKey('paid-${collection.id}'),
                tristate: true,
                value: paid
                    ? true
                    : collection.status == ItemStatus.charged
                    ? null
                    : false,
                onChanged: (_) => onToggle(collection),
              ),
              title: Row(
                children: [
                  Flexible(
                    child: Text(
                      collection.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: paid ? theme.colorScheme.outline : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.folder_outlined,
                    size: 16,
                    color: theme.colorScheme.outline,
                  ),
                ],
              ),
              subtitle: Text(
                [
                  budget == 0
                      ? '${formatPeso(used)} spent'
                      : '${formatPeso(used)} of ${formatPeso(budget)}',
                  if (children.isNotEmpty) '$paidCount/${children.length} paid',
                ].join(' · '),
              ),
              trailing: Text(
                budget == 0
                    ? formatPeso(used)
                    : left < 0
                    ? '${formatPeso(-left)} over'
                    : '${formatPeso(left)} left',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: left < 0 ? theme.colorScheme.error : null,
                ),
              ),
              onTap: () => onEdit(collection),
            ),
            for (final item in children)
              _ItemRow(
                item: item,
                paidFrom: accountName[item.paidFromAccountId],
                indent: 24,
                extra:
                    item.accountId == null ||
                        item.accountId == collection.accountId
                    ? null
                    : accountName[item.accountId],
                onToggle: () => onToggle(item),
                onTap: () => onEdit(item),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 24),
                child: TextButton.icon(
                  key: ValueKey('add-to-${collection.id}'),
                  onPressed: onAdd,
                  icon: const Icon(Icons.add),
                  label: Text('Add to ${collection.name}'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Planned / Allotted / Paid chips that narrow the list.
class _StatusFilterBar extends StatelessWidget {
  const _StatusFilterBar({
    required this.showCharged,
    required this.counts,
    required this.shown,
    required this.onToggle,
    required this.onShowAll,
  });

  /// Charged only applies to credit cards.
  final bool showCharged;
  final Map<ItemStatus, int> counts;
  final Set<ItemStatus> shown;
  final ValueChanged<ItemStatus> onToggle;
  final VoidCallback onShowAll;

  static const _labels = {
    ItemStatus.planned: 'Planned',
    ItemStatus.allotted: 'Allotted',
    ItemStatus.charged: 'Charged',
    ItemStatus.paid: 'Paid',
  };

  @override
  Widget build(BuildContext context) {
    final filtering = shown.length < ItemStatus.values.length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final s in ItemStatus.values)
            if (s != ItemStatus.charged || showCharged)
              FilterChip(
                key: Key('filter-${s.name}'),
                label: Text('${_labels[s]} (${counts[s] ?? 0})'),
                selected: shown.contains(s),
                onSelected: (_) => onToggle(s),
              ),
          if (filtering)
            TextButton(
              key: const Key('filter-all'),
              onPressed: onShowAll,
              child: const Text('Show all'),
            ),
        ],
      ),
    );
  }
}

/// Suggested moves that even out accounts after expenses were paid from
/// another account than planned.
class _RebalanceCard extends StatelessWidget {
  const _RebalanceCard({
    required this.moves,
    required this.accountName,
    required this.onMoved,
    required this.onDismiss,
  });

  final List<SuggestedTransfer> moves;
  final Map<String, String> accountName;
  final ValueChanged<SuggestedTransfer> onMoved;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      key: const Key('rebalance-card'),
      color: theme.colorScheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.swap_horiz),
                const SizedBox(width: 8),
                Text('Rebalance', style: theme.textTheme.titleMedium),
                const Spacer(),
                TextButton(
                  key: const Key('rebalance-dismiss'),
                  onPressed: onDismiss,
                  child: const Text('Not now'),
                ),
              ],
            ),
            const Text(
              'Some expenses were paid from a different account than planned.',
            ),
            for (final m in moves)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  children: [
                    Text(
                      'Move ${formatPeso(m.amountCents)} from '
                      '${accountName[m.fromAccountId] ?? '?'} → '
                      '${accountName[m.toAccountId] ?? '?'}',
                      style: theme.textTheme.bodyLarge,
                    ),
                    FilledButton.tonal(
                      key: ValueKey('move-${m.fromAccountId}-${m.toAccountId}'),
                      onPressed: () => onMoved(m),
                      child: const Text('Mark as moved'),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// Money moved between accounts this month.
class _TransfersSection extends StatelessWidget {
  const _TransfersSection({
    required this.transfers,
    required this.accountName,
    required this.onEdit,
  });

  final List<Transfer> transfers;
  final Map<String, String> accountName;
  final ValueChanged<Transfer> onEdit;

  @override
  Widget build(BuildContext context) => Card(
    key: const Key('transfers-section'),
    child: Column(
      children: [
        _SectionHeader(
          leading: const Icon(Icons.swap_horiz),
          title: 'Transfers',
          trailing: formatPeso(transfers.fold(0, (s, t) => s + t.amountCents)),
        ),
        for (final t in transfers)
          ListTile(
            key: ValueKey('transfer-${t.id}'),
            title: Text(
              '${accountName[t.fromAccountId] ?? '?'} → '
              '${accountName[t.toAccountId] ?? '?'}',
            ),
            subtitle: Text(
              [formatShortDate(t.transferredAt), ?t.note].join(' · '),
            ),
            trailing: Text(
              formatPeso(t.amountCents),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            onTap: () => onEdit(t),
          ),
      ],
    ),
  );
}

extension on String {
  String? get emptyAsNull => isEmpty ? null : this;
}

class _IncomeSection extends StatelessWidget {
  const _IncomeSection({
    required this.incomes,
    required this.totals,
    required this.lastTopUp,
    required this.onTopUp,
    required this.onEdit,
    required this.onAdd,
  });

  final List<Income> incomes;
  final MonthTotals totals;

  /// Latest top-up date per income id.
  final Map<String, DateTime> lastTopUp;
  final ValueChanged<Income> onTopUp;
  final ValueChanged<Income> onEdit;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      key: const Key('income-section'),
      child: Column(
        children: [
          _SectionHeader(
            leading: const Icon(Icons.savings_outlined),
            title: 'Income',
            subtitle: totals.toReceiveCents > 0
                ? '${formatPeso(totals.toReceiveCents)} still to come'
                : null,
            trailing:
                '${formatPeso(totals.receivedCents)} of '
                '${formatPeso(totals.incomeCents)}',
          ),
          for (final income in incomes) _incomeRow(context, theme, income),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const Key('add-income'),
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add income'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _incomeRow(BuildContext context, ThemeData theme, Income income) {
    final received = totals.receivedByIncome[income.id] ?? 0;
    final last = lastTopUp[income.id];
    final status = switch (received) {
      0 => 'Nothing received yet',
      _ when received >= income.amountCents =>
        'Received in full · ${formatShortDate(last!)}',
      _ =>
        '${formatPeso(income.amountCents - received)} to come · '
            'last ${formatShortDate(last!)}',
    };
    return ListTile(
      key: ValueKey('income-${income.id}'),
      title: Text(income.name),
      subtitle: Text(status),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatPeso(received),
                key: ValueKey('received-${income.id}'),
                style: theme.textTheme.bodyLarge,
              ),
              Text(
                'of ${formatPeso(income.amountCents)}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          IconButton(
            key: ValueKey('top-up-${income.id}'),
            tooltip: 'Top up',
            onPressed: () => onTopUp(income),
            icon: const Icon(Icons.add_card),
          ),
        ],
      ),
      onTap: () => onEdit(income),
    );
  }
}

String _ordinal(int n) {
  if (n >= 11 && n <= 13) return '${n}th';
  return switch (n % 10) {
    1 => '${n}st',
    2 => '${n}nd',
    3 => '${n}rd',
    _ => '${n}th',
  };
}

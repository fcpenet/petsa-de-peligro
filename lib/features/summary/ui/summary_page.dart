import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/providers.dart';
import '../../../core/db/database.dart';
import '../../../core/money.dart';
import '../../../core/ui/adaptive.dart';
import '../../accounts/ui/account_form.dart';
import '../../budget/data/budget_repository.dart';
import '../domain/account_summary.dart';

/// The month (or a date range) by account, with credit cards on their own.
/// Routes: `/summary/:yearMonth` and `/summary/range?from=…&to=…`.
class SummaryPage extends ConsumerWidget {
  const SummaryPage({super.key, required this.yearMonth}) : range = null;

  const SummaryPage.range({super.key, required DayRange this.range})
    : yearMonth = null;

  final String? yearMonth;
  final DayRange? range;

  static String rangeLocation(DayRange r) =>
      '/summary/range?from=${_day(r.from)}&to=${_day(r.to)}';

  static String _day(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickRange(BuildContext context) async {
    final current = range;
    final DateTimeRange initial;
    if (current != null) {
      initial = DateTimeRange(start: current.from, end: current.to);
    } else {
      final [y, m] = [for (final p in yearMonth!.split('-')) int.parse(p)];
      initial = DateTimeRange(
        start: DateTime(y, m),
        end: DateTime(y, m + 1, 0),
      );
    }
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Summary for these dates',
    );
    if (picked != null && context.mounted) {
      context.go(rangeLocation((from: picked.start, to: picked.end)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = this.range;
    return Scaffold(
      appBar: AppBar(
        title: range == null
            ? MonthSwitcher(
                yearMonth: yearMonth!,
                onChanged: (ym) => context.go('/summary/$ym'),
              )
            : FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${formatShortDate(range.from)} – '
                  '${formatShortDate(range.to)}',
                  key: const Key('summary-range-label'),
                ),
              ),
        centerTitle: true,
        leading: range == null
            ? null
            : IconButton(
                key: const Key('summary-range-clear'),
                tooltip: 'Back to month view',
                icon: const Icon(Icons.close),
                onPressed: () => context.go(
                  '/summary/${BudgetRepository.yearMonthOf(range.to)}',
                ),
              ),
        actions: [
          IconButton(
            key: const Key('summary-range'),
            tooltip: 'Choose dates',
            icon: const Icon(Icons.date_range),
            onPressed: () => _pickRange(context),
          ),
        ],
      ),
      body: range == null
          ? switch (ref.watch(monthProvider(yearMonth!))) {
              AsyncData(:final value) => _MonthBody(month: value),
              AsyncError(:final error) => Center(child: Text('Error: $error')),
              _ => const Center(child: CircularProgressIndicator()),
            }
          : _RangeBody(range: range),
    );
  }
}

class _MonthBody extends ConsumerWidget {
  const _MonthBody({required this.month});

  final Month month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(itemsProvider(month.id));
    final transfers = ref.watch(transfersProvider(month.id));
    final accounts = ref.watch(accountsProvider);
    final error = items.error ?? transfers.error ?? accounts.error;
    if (error != null) return Center(child: Text('Error: $error'));
    if (!items.hasValue || !transfers.hasValue || !accounts.hasValue) {
      return const Center(child: CircularProgressIndicator());
    }
    return _SummaryList(
      summary: summarizeMonth(
        accounts: accounts.requireValue,
        items: items.requireValue,
        transfers: transfers.requireValue,
      ),
      dateOf: (i) => itemDate(i, month.yearMonth),
      emptyText: 'Nothing budgeted this month yet.',
    );
  }
}

class _RangeBody extends ConsumerWidget {
  const _RangeBody({required this.range});

  final DayRange range;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = ref.watch(rangeItemsProvider(range));
    final transfers = ref.watch(rangeTransfersProvider(range));
    final accounts = ref.watch(accountsProvider);
    final error = rows.error ?? transfers.error ?? accounts.error;
    if (error != null) return Center(child: Text('Error: $error'));
    if (!rows.hasValue || !transfers.hasValue || !accounts.hasValue) {
      return const Center(child: CircularProgressIndicator());
    }
    final yearMonthOf = {
      for (final (item, ym) in rows.requireValue) item.monthId: ym,
    };
    return _SummaryList(
      summary: summarizeRange(
        accounts: accounts.requireValue,
        items: [for (final (item, _) in rows.requireValue) item],
        yearMonthOf: yearMonthOf,
        range: range,
        transfers: transfers.requireValue,
      ),
      dateOf: (i) => itemDate(i, yearMonthOf[i.monthId]!),
      emptyText: 'Nothing paid or due in these dates.',
      note:
          'Paid expenses count on their payment date; unpaid ones on their '
          'due day, or the 1st of their month if they have none.',
    );
  }
}

class _SummaryList extends StatelessWidget {
  const _SummaryList({
    required this.summary,
    required this.dateOf,
    required this.emptyText,
    this.note,
  });

  final MonthSummary summary;
  final DateTime Function(BudgetItem) dateOf;
  final String emptyText;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final empty =
        summary.accounts.accounts.isEmpty && summary.cards.accounts.isEmpty;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
          children: [
            if (note != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                child: Text(
                  note!,
                  key: const Key('summary-range-note'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            if (empty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(emptyText, textAlign: TextAlign.center),
              ),
            if (summary.accounts.accounts.isNotEmpty)
              _GroupCard(
                key: const Key('summary-accounts'),
                title: 'Accounts',
                icon: Icons.account_balance_outlined,
                group: summary.accounts,
                card: false,
                dateOf: dateOf,
              ),
            if (summary.cards.accounts.isNotEmpty)
              _GroupCard(
                key: const Key('summary-cards'),
                title: 'Credit cards',
                icon: Icons.credit_card,
                group: summary.cards,
                card: true,
                dateOf: dateOf,
              ),
            if (summary.hiddenCount > 0 && !empty)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  '${summary.hiddenCount} other account'
                  '${summary.hiddenCount == 1 ? ' has' : 's have'} nothing '
                  'here.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Labels differ for cards: a card item is "settled" when its bill is paid.
({String budgeted, String paid, String left}) _labels(bool card) => card
    ? (budgeted: 'On card', paid: 'Settled', left: 'To settle')
    : (budgeted: 'Budgeted', paid: 'Paid', left: 'Left to pay');

class _GroupCard extends StatelessWidget {
  const _GroupCard({
    super.key,
    required this.title,
    required this.icon,
    required this.group,
    required this.card,
    required this.dateOf,
  });

  final String title;
  final IconData icon;
  final SummaryGroup group;
  final bool card;
  final DateTime Function(BudgetItem) dateOf;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labels = _labels(card);
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            leading: Icon(icon),
            title: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Wrap(
              spacing: 20,
              runSpacing: 8,
              children: [
                _Figure(labels.budgeted, group.budgetedCents, title),
                _Figure(labels.paid, group.paidCents, title),
                if (card) ...[
                  // The card bills: charged, not paid yet.
                  _Figure(labels.left, group.chargedCents, title, strong: true),
                  if (group.notChargedCents > 0)
                    _Figure('Not charged yet', group.notChargedCents, title),
                ] else ...[
                  _Figure(labels.left, group.leftCents, title, strong: true),
                  if (group.plannedCents > 0)
                    _Figure('To allot', group.plannedCents, title),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          for (final a in group.accounts)
            _AccountTile(summary: a, dateOf: dateOf),
        ],
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure(this.label, this.cents, this.group, {this.strong = false});

  final String label;
  final int cents;
  final String group;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelMedium),
        Text(
          formatPeso(cents),
          key: Key('figure-$group-$label'),
          style:
              (strong
                      ? theme.textTheme.titleLarge
                      : theme.textTheme.titleMedium)
                  ?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({required this.summary, required this.dateOf});

  final AccountSummary summary;
  final DateTime Function(BudgetItem) dateOf;

  static const _statusLabels = {
    ItemStatus.planned: 'Planned',
    ItemStatus.allotted: 'Allotted',
    ItemStatus.charged: 'Charged',
    ItemStatus.paid: 'Paid',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = summary;
    final labels = _labels(s.isCard);
    final details = [
      '${labels.budgeted} ${formatPeso(s.budgetedCents)}',
      '${labels.paid} ${formatPeso(s.paidCents)}',
      if (s.isCard && s.notChargedCents > 0)
        'Not charged yet ${formatPeso(s.notChargedCents)}',
      if (!s.isCard && s.plannedCents > 0)
        'To allot ${formatPeso(s.plannedCents)}',
      if (s.balanceCents > 0) '${formatPeso(s.balanceCents)} unused',
      if (s.balanceCents < 0) '${formatPeso(-s.balanceCents)} over',
    ];
    return ExpansionTile(
      key: ValueKey('summary-${s.account.id}'),
      leading: Icon(accountTypeIcons[s.account.type]),
      title: Row(
        children: [
          Expanded(
            child: Text(
              s.account.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          // Long amounts wrap instead of overflowing on phones.
          Flexible(
            child: Text(textAlign: TextAlign.end, switch (s) {
              _ when s.isCard && s.chargedCents > 0 =>
                '${formatPeso(s.chargedCents)} to settle',
              _ when s.isCard && s.notChargedCents > 0 => 'Nothing charged yet',
              _ when s.isCard => 'All settled',
              _ when s.leftCents == 0 => 'All paid',
              _ => '${formatPeso(s.leftCents)} left',
            }, style: theme.textTheme.bodyLarge),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: s.progress.clamp(0, 1),
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
          const SizedBox(height: 6),
          Text(details.join(' · ')),
        ],
      ),
      children: [
        for (final item in s.items)
          ListTile(
            key: ValueKey('summary-item-${item.id}'),
            dense: true,
            contentPadding: const EdgeInsets.only(left: 72, right: 16),
            title: Text(item.name),
            subtitle: Text(
              [
                _statusLabels[item.status]!,
                if (item.status == ItemStatus.paid ||
                    item.status == ItemStatus.charged)
                  formatShortDate(dateOf(item))
                else if (item.dueDay != null)
                  'due ${formatShortDate(dateOf(item))}'
                else
                  'no due day',
              ].join(' · '),
            ),
            trailing: Text(formatPeso(item.amountCents)),
          ),
        if (s.items.isEmpty)
          const ListTile(
            dense: true,
            contentPadding: EdgeInsets.only(left: 72, right: 16),
            title: Text('No expenses budgeted here this month'),
          ),
      ],
    );
  }
}

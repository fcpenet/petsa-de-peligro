import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/providers.dart';
import '../../../core/db/database.dart';
import '../../../core/money.dart';
import '../../../core/ui/adaptive.dart';
import '../../accounts/ui/account_form.dart';
import '../domain/account_summary.dart';

/// The month by account, with credit cards on their own.
/// Route: `/summary/:yearMonth`.
class SummaryPage extends ConsumerWidget {
  const SummaryPage({super.key, required this.yearMonth});

  final String yearMonth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(monthProvider(yearMonth));
    return Scaffold(
      appBar: AppBar(
        title: MonthSwitcher(
          yearMonth: yearMonth,
          onChanged: (ym) => context.go('/summary/$ym'),
        ),
        centerTitle: true,
      ),
      body: switch (month) {
        AsyncData(:final value) => _SummaryBody(monthId: value.id),
        AsyncError(:final error) => Center(child: Text('Error: $error')),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _SummaryBody extends ConsumerWidget {
  const _SummaryBody({required this.monthId});

  final String monthId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(itemsProvider(monthId));
    final transfers = ref.watch(transfersProvider(monthId));
    final accounts = ref.watch(accountsProvider);
    final error = items.error ?? transfers.error ?? accounts.error;
    if (error != null) return Center(child: Text('Error: $error'));
    if (!items.hasValue || !transfers.hasValue || !accounts.hasValue) {
      return const Center(child: CircularProgressIndicator());
    }
    final summary = summarizeMonth(
      accounts: accounts.requireValue,
      items: items.requireValue,
      transfers: transfers.requireValue,
    );
    final empty =
        summary.accounts.accounts.isEmpty && summary.cards.accounts.isEmpty;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
          children: [
            if (empty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Nothing budgeted this month yet.',
                  textAlign: TextAlign.center,
                ),
              ),
            if (summary.accounts.accounts.isNotEmpty)
              _GroupCard(
                key: const Key('summary-accounts'),
                title: 'Accounts',
                icon: Icons.account_balance_outlined,
                group: summary.accounts,
                card: false,
              ),
            if (summary.cards.accounts.isNotEmpty)
              _GroupCard(
                key: const Key('summary-cards'),
                title: 'Credit cards',
                icon: Icons.credit_card,
                group: summary.cards,
                card: true,
              ),
            if (summary.hiddenCount > 0)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  '${summary.hiddenCount} other account'
                  '${summary.hiddenCount == 1 ? ' has' : 's have'} nothing '
                  'this month.',
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
  });

  final String title;
  final IconData icon;
  final SummaryGroup group;
  final bool card;

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
                _Figure(labels.left, group.leftCents, title, strong: true),
                if (group.plannedCents > 0)
                  _Figure('To allot', group.plannedCents, title),
              ],
            ),
          ),
          const Divider(height: 1),
          for (final a in group.accounts) _AccountTile(summary: a),
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
  const _AccountTile({required this.summary});

  final AccountSummary summary;

  static const _statusLabels = {
    ItemStatus.planned: 'Planned',
    ItemStatus.allotted: 'Allotted',
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
      if (s.plannedCents > 0) 'To allot ${formatPeso(s.plannedCents)}',
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
            child: Text(
              textAlign: TextAlign.end,
              s.leftCents == 0
                  ? (s.isCard ? 'All settled' : 'All paid')
                  : '${formatPeso(s.leftCents)} ${s.isCard ? 'to settle' : 'left'}',
              style: theme.textTheme.bodyLarge,
            ),
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
            subtitle: Text(_statusLabels[item.status]!),
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

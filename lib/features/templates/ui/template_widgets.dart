import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/providers.dart';
import '../../../core/db/database.dart';
import '../../../core/ui/adaptive.dart';
import '../../budget/data/budget_repository.dart';

/// Templates menu for a month: new template, save the month, fill it,
/// and a link to the Templates page.
class TemplatesMenu extends ConsumerWidget {
  const TemplatesMenu({
    super.key,
    required this.month,
    required this.onMessage,
  });

  final Month month;
  final ValueChanged<String> onMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templates = ref.watch(templatesProvider).value ?? const [];
    final items = ref.watch(itemsProvider(month.id)).value ?? const [];
    final incomes = ref.watch(incomesProvider(month.id)).value ?? const [];
    final monthIsEmpty = items.isEmpty && incomes.isEmpty;
    final repo = ref.read(templateRepositoryProvider);

    Future<void> run(Future<String?> Function() action) async {
      try {
        final message = await action();
        if (message != null) onMessage(message);
      } on BudgetException catch (e) {
        onMessage(e.message);
      }
    }

    return PopupMenuButton<String>(
      key: const Key('templates-menu'),
      tooltip: 'Templates and month',
      icon: const Icon(Icons.copy_all),
      onSelected: (value) {
        final [action, ...rest] = value.split(':');
        final template = templates
            .where((t) => t.id == rest.join(':'))
            .firstOrNull;
        switch (action) {
          case 'manage':
            context.go('/templates');
          case 'clear':
            run(() async {
              final n = items.length;
              final m = incomes.length;
              final ok = await confirmDelete(
                context,
                'everything in ${monthLabel(month.yearMonth)}',
                detail:
                    'Deletes $n expense${n == 1 ? '' : 's'} and $m '
                    'income${m == 1 ? '' : 's'}, with their top-ups and '
                    'this month’s transfers. This can’t be undone. You can '
                    'then start again from a template, last month, or '
                    'scratch.',
              );
              if (!ok) return null;
              await ref.read(budgetRepositoryProvider).clearMonth(month.id);
              return 'Cleared ${monthLabel(month.yearMonth)}';
            });
          case 'new':
            context.go('/templates/new');
          case 'save':
            run(() async {
              final result = await showSaveTemplateDialog(
                context,
                defaultName: templates.length == 1
                    ? templates.single.name
                    : 'Monthly',
                existingNames: [for (final t in templates) t.name],
              );
              if (result == null) return null;
              await repo.saveFromMonth(
                monthId: month.id,
                name: result.name,
                includeSubExpenses: result.includeSubExpenses,
                includeIncomes: result.includeIncomes,
              );
              return 'Saved template “${result.name}”';
            });
          case 'apply' when template != null:
            run(() async {
              final n = await repo.applyTemplate(
                templateId: template.id,
                monthId: month.id,
              );
              return 'Added $n items from “${template.name}”';
            });
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(
          key: Key('new-template'),
          value: 'new',
          child: Text('New template…'),
        ),
        PopupMenuItem(
          key: const Key('save-template'),
          value: 'save',
          enabled: !monthIsEmpty,
          child: const Text('Save this month as template…'),
        ),
        if (templates.isNotEmpty) ...[
          const PopupMenuDivider(),
          for (final t in templates)
            PopupMenuItem(
              value: 'apply:${t.id}',
              enabled: monthIsEmpty,
              child: Text('Fill month from “${t.name}”'),
            ),
          const PopupMenuDivider(),
          const PopupMenuItem(
            key: Key('manage-templates'),
            value: 'manage',
            child: Text('Edit templates…'),
          ),
        ],
        const PopupMenuDivider(),
        PopupMenuItem(
          key: const Key('clear-month'),
          value: 'clear',
          enabled: !monthIsEmpty,
          child: Text(
            'Delete this month…',
            style: TextStyle(
              color: monthIsEmpty ? null : Theme.of(context).colorScheme.error,
            ),
          ),
        ),
      ],
    );
  }
}

/// Shown on an empty month: start from a template or copy last month.
class EmptyMonthBanner extends ConsumerWidget {
  const EmptyMonthBanner({
    super.key,
    required this.month,
    required this.onMessage,
  });

  final Month month;
  final ValueChanged<String> onMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templates = ref.watch(templatesProvider).value ?? const [];
    final repo = ref.read(templateRepositoryProvider);
    final previous = shiftMonth(month.yearMonth, -1);
    return Card(
      key: const Key('empty-month-banner'),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${monthLabel(month.yearMonth)} is empty',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            const Text('Start from a template or last month’s entries.'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in templates)
                  FilledButton.icon(
                    key: Key('use-template-${t.name}'),
                    onPressed: () async {
                      final n = await repo.applyTemplate(
                        templateId: t.id,
                        monthId: month.id,
                      );
                      onMessage('Added $n items from “${t.name}”');
                    },
                    icon: const Icon(Icons.copy_all, size: 18),
                    label: Text(t.name),
                  ),
                if (templates.isEmpty)
                  OutlinedButton.icon(
                    key: const Key('create-template'),
                    onPressed: () => context.go('/templates/new'),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Create a template'),
                  ),
                OutlinedButton.icon(
                  key: const Key('copy-previous'),
                  onPressed: () async {
                    final n = await repo.copyMonth(
                      fromYearMonth: previous,
                      toMonthId: month.id,
                    );
                    onMessage(
                      n == 0
                          ? '${monthLabel(previous)} has nothing to copy'
                          : 'Copied $n items from ${monthLabel(previous)}',
                    );
                  },
                  icon: const Icon(Icons.history, size: 18),
                  label: Text('Copy ${monthLabel(previous)}'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

typedef SaveTemplate = ({
  String name,
  bool includeSubExpenses,
  bool includeIncomes,
});

Future<SaveTemplate?> showSaveTemplateDialog(
  BuildContext context, {
  required String defaultName,
  List<String> existingNames = const [],
}) {
  return showDialog<SaveTemplate>(
    context: context,
    builder: (_) =>
        _SaveTemplateDialog(defaultName: defaultName, existing: existingNames),
  );
}

class _SaveTemplateDialog extends StatefulWidget {
  const _SaveTemplateDialog({
    required this.defaultName,
    required this.existing,
  });

  final String defaultName;
  final List<String> existing;

  @override
  State<_SaveTemplateDialog> createState() => _SaveTemplateDialogState();
}

class _SaveTemplateDialogState extends State<_SaveTemplateDialog> {
  late final _name = TextEditingController(text: widget.defaultName);
  var _includeSubExpenses = false;
  var _includeIncomes = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool get _replaces => widget.existing.any(
    (n) => n.toLowerCase() == _name.text.trim().toLowerCase(),
  );

  void _submit() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Enter a name');
      return;
    }
    Navigator.of(context).pop((
      name: name,
      includeSubExpenses: _includeSubExpenses,
      includeIncomes: _includeIncomes,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Save as template'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Saves accounts, expenses, collections and amounts. New months start '
              'with everything unpaid.',
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('template-name'),
              controller: _name,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Template name',
                errorText: _error,
                helperText: _replaces ? 'Replaces the existing template' : null,
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              key: const Key('include-sub-expenses'),
              contentPadding: EdgeInsets.zero,
              value: _includeSubExpenses,
              onChanged: (v) =>
                  setState(() => _includeSubExpenses = v ?? false),
              title: const Text('Include sub-expenses inside collections'),
              subtitle: const Text(
                'Off keeps collections like Misc and their budget, '
                'but not this month’s individual purchases.',
              ),
            ),
            CheckboxListTile(
              key: const Key('include-incomes'),
              contentPadding: EdgeInsets.zero,
              value: _includeIncomes,
              onChanged: (v) => setState(() => _includeIncomes = v ?? true),
              title: const Text('Include income'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}

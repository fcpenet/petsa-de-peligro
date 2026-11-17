import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/providers.dart';
import '../../../core/db/database.dart';
import '../../../core/money.dart';
import '../../../core/ui/adaptive.dart';
import '../../accounts/ui/account_form.dart';
import '../../budget/data/budget_repository.dart';
import '../../budget/ui/item_form.dart' show itemKindLabels;
import '../domain/month_template.dart';
import '../domain/template_draft.dart';
import 'template_forms.dart';

/// Builds or edits a template without touching any month.
/// Routes: `/templates/new` and `/templates/:id`.
class TemplateEditorPage extends ConsumerWidget {
  const TemplateEditorPage({super.key, this.templateId});

  /// Null for a new template.
  final String? templateId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = templateId;
    if (id == null) return const TemplateEditor();
    return switch (ref.watch(templatesProvider)) {
      AsyncData(:final value) => switch (value
          .where((t) => t.id == id)
          .firstOrNull) {
        final TemplateRow row => TemplateEditor(
          key: ValueKey(row.id),
          row: row,
        ),
        null => Scaffold(
          appBar: AppBar(),
          body: const Center(child: Text('This template no longer exists.')),
        ),
      },
      AsyncError(:final error) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error: $error')),
      ),
      _ => const Scaffold(body: Center(child: CircularProgressIndicator())),
    };
  }
}

class TemplateEditor extends ConsumerStatefulWidget {
  const TemplateEditor({super.key, this.row});

  final TemplateRow? row;

  @override
  ConsumerState<TemplateEditor> createState() => _TemplateEditorState();
}

class _TemplateEditorState extends ConsumerState<TemplateEditor> {
  late final _name = TextEditingController(text: widget.row?.name ?? '');
  late final TemplateDraft _draft;
  String? _loadError;
  String? _nameError;
  bool _dirty = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    try {
      _draft = TemplateDraft(
        widget.row == null
            ? const MonthTemplate()
            : MonthTemplate.decode(widget.row!.payload),
      );
    } on FormatException catch (e) {
      _draft = TemplateDraft();
      _loadError = e.message;
    }
    _name.addListener(() {
      if (!_dirty) setState(() => _dirty = true);
    });
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _toast(String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  void _change(VoidCallback edit) => setState(() {
    edit();
    _dirty = true;
  });

  CollectionChoices _collections() => {
    for (final i in _draft.collectionIndexes)
      i: (name: _draft.items[i].name, accountId: _draft.items[i].accountId),
  };

  void _leave() => context.canPop() ? context.pop() : context.go('/templates');

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      setState(() => _nameError = 'Give the template a name');
      return;
    }
    setState(() {
      _saving = true;
      _nameError = null;
    });
    try {
      await ref
          .read(templateRepositoryProvider)
          .save(id: widget.row?.id, name: _name.text, template: _draft.build());
      if (!mounted) return;
      _dirty = false;
      _toast('Saved template “${_name.text.trim()}”');
      _leave();
    } on BudgetException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _toast(e.message);
    }
  }

  Future<void> _delete() async {
    final row = widget.row!;
    if (!await confirmDelete(context, 'template “${row.name}”')) return;
    if (!mounted) return;
    // Leave first: once the row is gone this page is replaced.
    final repo = ref.read(templateRepositoryProvider);
    setState(() => _dirty = false);
    _leave();
    await repo.delete(row.id);
  }

  Future<bool> _confirmDiscard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('Your changes to this template are not saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep editing'),
          ),
          FilledButton(
            key: const Key('confirm-discard'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return discard ?? false;
  }

  Future<void> _addItem({String? accountId, int? collectionIndex}) async {
    final edit = await showTemplateItemForm(
      context,
      collections: _collections(),
      accountId: accountId,
      collectionIndex: collectionIndex,
    );
    if (edit?.value case final placed?) {
      _change(
        () => _draft.add(placed.item, collectionIndex: placed.collectionIndex),
      );
    }
  }

  Future<void> _editItem(ItemRef ref) async {
    final item = _draft.itemAt(ref);
    final edit = await showTemplateItemForm(
      context,
      collections: {
        for (final MapEntry(:key, :value) in _collections().entries)
          if (ref.child != null || key != ref.index) key: value,
      },
      existing: item,
      collectionIndex: ref.child == null ? null : ref.index,
    );
    if (edit == null) return;
    _change(() {
      if (edit.value case final placed?) {
        _draft.replace(
          ref,
          placed.item,
          collectionIndex: placed.collectionIndex,
        );
      } else {
        _draft.remove(ref);
      }
    });
  }

  Future<void> _editIncome([int? index]) async {
    final edit = await showTemplateIncomeForm(
      context,
      existing: index == null ? null : _draft.incomes[index],
    );
    if (edit == null) return;
    _change(() {
      switch ((edit.value, index)) {
        case (final income?, null):
          _draft.incomes.add(income);
        case (final income?, final i?):
          _draft.incomes[i] = income;
        case (null, final i?):
          _draft.incomes.removeAt(i);
        case (null, null):
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsProvider).value ?? const <Account>[];
    final template = _draft.build();

    // Top-level items by account, in the Accounts page order. Collections
    // without an account get their own card; anything else without a known
    // account is listed under "No account".
    final byAccount = <String, List<int>>{};
    final orphans = <int>[];
    final looseCollections = <int>[];
    for (final (i, item) in _draft.items.indexed) {
      if (item.accountId == null) {
        (item.isCollection ? looseCollections : orphans).add(i);
      } else {
        (byAccount[item.accountId!] ??= []).add(i);
      }
    }
    final known = {for (final a in accounts) a.id: a};
    final accountName = {for (final a in accounts) a.id: a.name};

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmDiscard() && mounted) {
          setState(() => _dirty = false);
          _leave();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.row == null ? 'New template' : 'Edit template'),
          actions: [
            if (widget.row != null)
              IconButton(
                key: const Key('template-delete'),
                tooltip: 'Delete template',
                onPressed: _saving ? null : _delete,
                icon: const Icon(Icons.delete_outline),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: FilledButton(
                key: const Key('template-save'),
                onPressed: _saving ? null : _save,
                child: const Text('Save'),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          key: const Key('add-expense'),
          onPressed: () => _addItem(),
          icon: const Icon(Icons.add),
          label: const Text('Expense'),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
              children: [
                if (_loadError != null)
                  Card(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text('Could not read this template: $_loadError'),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: TextField(
                    key: const Key('template-name'),
                    controller: _name,
                    autofocus: widget.row == null,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Template name',
                      hintText: 'Monthly, 13th month, Christmas…',
                      errorText: _nameError,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _Totals(template: template),
                if (template.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Add the expenses, collections and income every month '
                      'starts with. Months made from this template start '
                      'with everything unpaid.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                for (final a in [
                  ...accounts.where((a) => byAccount.containsKey(a.id)),
                ])
                  _section(
                    key: ValueKey('template-account-${a.id}'),
                    icon: Icon(accountTypeIcons[a.type]),
                    title: a.name,
                    indexes: byAccount[a.id]!,
                    names: accountName,
                    onAdd: () => _addItem(accountId: a.id),
                    addLabel: 'Add to ${a.name}',
                    addKey: 'add-to-${a.id}',
                  ),
                if (looseCollections.isNotEmpty)
                  _section(
                    key: const ValueKey('template-collections'),
                    icon: const Icon(Icons.folder_outlined),
                    title: 'Collections',
                    subtitle: 'Each sub-expense counts toward its own account',
                    indexes: looseCollections,
                    names: accountName,
                  ),
                if ([
                      for (final id in byAccount.keys)
                        if (!known.containsKey(id)) ...byAccount[id]!,
                      ...orphans,
                    ]
                    case final missing when missing.isNotEmpty)
                  _section(
                    key: const ValueKey('template-account-none'),
                    icon: const Icon(Icons.help_outline),
                    title: 'No account',
                    subtitle: 'Tap an expense to choose its account',
                    indexes: missing,
                    names: accountName,
                  ),
                _incomes(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _section({
    Key? key,
    required Widget icon,
    required String title,
    String? subtitle,
    required List<int> indexes,
    required Map<String, String> names,
    VoidCallback? onAdd,
    String? addLabel,
    String? addKey,
  }) {
    final total = indexes.fold(0, (s, i) => s + _draft.items[i].plannedCents);
    return Card(
      key: key,
      child: Column(
        children: [
          ListTile(
            leading: icon,
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: subtitle == null ? null : Text(subtitle),
            trailing: Text(formatPeso(total)),
          ),
          for (final i in indexes)
            if (_draft.items[i].isCollection)
              _collection(i, names)
            else
              _row((index: i, child: null), names, parentAccount: null),
          if (onAdd != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: addKey == null ? null : Key(addKey),
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: Text(addLabel!),
              ),
            ),
        ],
      ),
    );
  }

  Widget _collection(int index, Map<String, String> names) {
    final collection = _draft.items[index];
    final used = collection.children.fold(0, (s, c) => s + c.amountCents);
    final cap = collection.amountCents;
    final theme = Theme.of(context);
    return Padding(
      key: ValueKey('template-collection-$index'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            ListTile(
              key: ValueKey('template-item-$index-null'),
              leading: const Icon(Icons.folder_outlined),
              title: Text(
                collection.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                cap == 0
                    ? 'No budget · adds up sub-expenses'
                    : '${formatPeso(used)} of ${formatPeso(cap)} budget',
              ),
              trailing: Text(
                formatPeso(collection.plannedCents),
                style: theme.textTheme.bodyLarge,
              ),
              onTap: () => _editItem((index: index, child: null)),
            ),
            for (final c in collection.children.indexed.map((e) => e.$1))
              _row(
                (index: index, child: c),
                names,
                parentAccount: collection.accountId,
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 24),
                child: TextButton.icon(
                  key: ValueKey('add-to-collection-$index'),
                  onPressed: () => _addItem(collectionIndex: index),
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

  Widget _row(
    ItemRef ref,
    Map<String, String> names, {
    required String? parentAccount,
  }) {
    final item = _draft.itemAt(ref);
    final details = [
      // A sub-expense paid from another account than its collection's.
      if (ref.child != null &&
          item.accountId != null &&
          item.accountId != parentAccount)
        names[item.accountId] ?? 'Unknown account',
      if (item.kind != ItemKind.expense) itemKindLabels[item.kind]!,
      if (item.dueDay != null) 'Due on the ${item.dueDay}',
      ?item.note,
    ];
    return ListTile(
      key: ValueKey('template-item-${ref.index}-${ref.child}'),
      contentPadding: EdgeInsets.only(
        left: ref.child == null ? 16 : 40,
        right: 16,
      ),
      title: Text(item.name),
      subtitle: details.isEmpty ? null : Text(details.join(' · ')),
      trailing: Text(
        formatPeso(item.amountCents),
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      onTap: () => _editItem(ref),
    );
  }

  Widget _incomes() => Card(
    child: Column(
      children: [
        ListTile(
          leading: const Icon(Icons.payments_outlined),
          title: const Text(
            'Income',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          trailing: Text(formatPeso(_draft.build().incomeCents)),
        ),
        for (final (i, income) in _draft.incomes.indexed)
          ListTile(
            key: ValueKey('template-income-$i'),
            title: Text(income.name),
            trailing: Text(
              formatPeso(income.amountCents),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            onTap: () => _editIncome(i),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            key: const Key('add-income'),
            onPressed: () => _editIncome(),
            icon: const Icon(Icons.add),
            label: const Text('Add income'),
          ),
        ),
      ],
    ),
  );
}

class _Totals extends StatelessWidget {
  const _Totals({required this.template});

  final MonthTemplate template;

  @override
  Widget build(BuildContext context) {
    final unallotted = template.incomeCents - template.expenseCents;
    final theme = Theme.of(context);
    Widget stat(String label, int cents, {Color? color}) => Expanded(
      child: Column(
        key: Key('template-stat-$label'),
        children: [
          Text(label, style: theme.textTheme.labelMedium),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              formatPeso(cents),
              style: theme.textTheme.titleMedium?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            stat('Income', template.incomeCents),
            stat('Expenses', template.expenseCents),
            stat(
              'Unbudgeted',
              unallotted,
              color: unallotted < 0 ? theme.colorScheme.error : null,
            ),
          ],
        ),
      ),
    );
  }
}

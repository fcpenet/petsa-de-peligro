import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/providers.dart';
import '../../../core/db/database.dart';
import '../../../core/money.dart';
import '../../../core/ui/adaptive.dart';
import '../data/budget_repository.dart';

const itemKindLabels = {
  ItemKind.expense: 'Expense',
  ItemKind.savings: 'Savings',
  ItemKind.debt: 'Debt / loan',
};

/// Opens the expense form. With [existing] it edits; otherwise it adds,
/// optionally pre-filled with an account, as a sub-expense of the collection
/// [parentId], or as a new collection.
Future<void> showItemForm(
  BuildContext context, {
  required String monthId,
  BudgetItem? existing,
  String? accountId,
  String? parentId,
  bool collection = false,
}) {
  return showFormSheet(
    context,
    builder: (_) => ItemForm(
      monthId: monthId,
      existing: existing,
      initialAccountId: accountId,
      initialParentId: parentId,
      initialCollection: collection,
    ),
  );
}

class ItemForm extends ConsumerStatefulWidget {
  const ItemForm({
    super.key,
    required this.monthId,
    this.existing,
    this.initialAccountId,
    this.initialParentId,
    this.initialCollection = false,
  });

  final String monthId;
  final BudgetItem? existing;
  final String? initialAccountId;
  final String? initialParentId;
  final bool initialCollection;

  @override
  ConsumerState<ItemForm> createState() => _ItemFormState();
}

class _ItemFormState extends ConsumerState<ItemForm> {
  final _formKey = GlobalKey<FormState>();
  late final BudgetItem? _existing = widget.existing;
  late final _name = TextEditingController(text: _existing?.name);
  late final _amount = TextEditingController(
    text:
        _existing == null ||
            (_existing.isCollection && _existing.amountCents == 0)
        ? ''
        : centsToInput(_existing.amountCents),
  );
  late final _dueDay = TextEditingController(
    text: _existing?.dueDay?.toString() ?? '',
  );
  late final _note = TextEditingController(text: _existing?.note);

  late bool _isSub =
      _existing?.parentId != null ||
      (_existing == null && widget.initialParentId != null);
  late String? _parentId = _existing?.parentId ?? widget.initialParentId;
  late bool _isCollection = _existing?.isCollection ?? widget.initialCollection;
  late String? _accountId = _existing?.accountId ?? widget.initialAccountId;
  late ItemKind _kind = _existing?.kind ?? ItemKind.expense;
  late bool _paid = _existing?.status == ItemStatus.paid;
  late DateTime _paidAt = _existing?.paidAt ?? DateTime.now();

  bool _saving = false;
  String? _error;

  BudgetRepository get _repo => ref.read(budgetRepositoryProvider);

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _dueDay.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final cents = _amount.text.trim().isEmpty
        ? 0
        : parsePesoToCents(_amount.text)!;
    final dueDay = int.tryParse(_dueDay.text.trim());
    final note = _note.text.trim().isEmpty ? null : _note.text.trim();
    final parentId = _isSub ? _parentId : null;
    final collection = _isCollection && !_isSub;
    final existing = _existing;
    try {
      if (existing == null) {
        final id = await _repo.addItem(
          monthId: widget.monthId,
          name: _name.text,
          amountCents: cents,
          accountId: _accountId,
          parentId: parentId,
          kind: _kind,
          dueDay: dueDay,
          note: note,
          isCollection: collection,
        );
        if (_paid && !collection) {
          await _repo.setStatus(id, ItemStatus.paid, paidAt: _paidAt);
        }
      } else {
        await _repo.updateItem(
          existing.id,
          name: _name.text,
          amountCents: cents,
          accountId: Value(_accountId),
          kind: _kind,
          dueDay: Value(dueDay),
          note: Value(note),
          isCollection: collection == existing.isCollection ? null : collection,
        );
        if (parentId != existing.parentId) {
          await _repo.setParent(existing.id, parentId);
        }
        final wasPaid = existing.status == ItemStatus.paid;
        if (!collection &&
            (_paid != wasPaid ||
                (_paid && !_sameDay(_paidAt, existing.paidAt)))) {
          await _repo.setStatus(
            existing.id,
            _paid ? ItemStatus.paid : ItemStatus.allotted,
            paidAt: _paidAt,
          );
        }
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _saving = false;
        _error = e is BudgetException ? e.message : 'Could not save: $e';
      });
    }
  }

  Future<void> _delete() async {
    final existing = _existing!;
    final items = ref.read(itemsProvider(widget.monthId)).value ?? const [];
    final children = items.where((i) => i.parentId == existing.id).length;
    final ok = await confirmDelete(
      context,
      '“${existing.name}”',
      detail: children == 0
          ? null
          : 'Its $children sub-expense${children == 1 ? '' : 's'} will be '
                'deleted too.',
    );
    if (!ok) return;
    setState(() => _saving = true);
    try {
      await _repo.deleteItem(existing.id);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _saving = false;
        _error = 'Could not delete: $e';
      });
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _paidAt,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Date paid',
    );
    if (date != null) setState(() => _paidAt = date);
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsProvider).value ?? const [];
    final items = ref.watch(itemsProvider(widget.monthId)).value ?? const [];
    final accountName = {for (final a in accounts) a.id: a.name};
    final collections = [
      for (final i in items)
        if (i.isCollection && i.parentId == null && i.id != _existing?.id) i,
    ];
    final childCount = _existing == null
        ? 0
        : items.where((i) => i.parentId == _existing.id).length;
    final accountChoices = [
      for (final a in accounts)
        if (!a.archived || a.id == _accountId) a,
    ];
    final parent = collections.where((c) => c.id == _parentId).firstOrNull;
    final collection = _isCollection && !_isSub;

    return Form(
      key: _formKey,
      child: FormLayout(
        title: _existing == null
            ? (collection ? 'Add collection' : 'Add expense')
            : (collection ? 'Edit collection' : 'Edit expense'),
        saving: _saving,
        error: _error,
        onSave: _save,
        onDelete: _existing == null ? null : _delete,
        children: [
          SegmentedButton<bool>(
            segments: [
              const ButtonSegment(
                value: false,
                label: Text('Expense', key: Key('type-item')),
                icon: Icon(Icons.receipt_long),
              ),
              ButtonSegment(
                value: true,
                enabled: collections.isNotEmpty && childCount == 0,
                label: const Text('Sub-expense', key: Key('type-sub')),
                icon: const Icon(Icons.subdirectory_arrow_right),
              ),
            ],
            selected: {_isSub},
            onSelectionChanged: (s) => setState(() {
              _isSub = s.first;
              if (_isSub && _parentId == null && collections.length == 1) {
                _parentId = collections.single.id;
              }
            }),
          ),
          if (collections.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                'Turn on Collection for an expense (like Misc) to add '
                'sub-expenses to it.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          const SizedBox(height: 12),
          if (_isSub) ...[
            DropdownButtonFormField<String>(
              key: const Key('field-parent'),
              initialValue: parent?.id,
              decoration: const InputDecoration(labelText: 'Collection'),
              items: [
                for (final c in collections)
                  DropdownMenuItem(
                    value: c.id,
                    child: Text(
                      [c.name, ?accountName[c.accountId]].join(' · '),
                    ),
                  ),
              ],
              onChanged: (v) => setState(() => _parentId = v),
              validator: (v) => v == null ? 'Choose a collection' : null,
            ),
            const SizedBox(height: 12),
          ] else
            SwitchListTile(
              key: const Key('field-collection'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Collection'),
              subtitle: Text(
                childCount > 0
                    ? 'Has $childCount sub-expense${childCount == 1 ? '' : 's'}'
                    : 'Holds sub-expenses that can be paid from any '
                          'account, like Misc',
              ),
              value: _isCollection,
              onChanged: childCount > 0
                  ? null
                  : (v) => setState(() => _isCollection = v),
            ),
          TextFormField(
            key: const Key('field-name'),
            controller: _name,
            autofocus: _existing == null,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Name'),
            validator: (v) =>
                (v?.trim().isEmpty ?? true) ? 'Enter a name' : null,
          ),
          const SizedBox(height: 12),
          AmountField(
            key: const Key('field-amount'),
            controller: _amount,
            label: collection ? 'Budget (optional)' : 'Amount',
            required: !collection,
            helperText: collection
                ? 'Leave empty to just add up the sub-expenses'
                : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            key: const Key('field-account'),
            initialValue: _accountId,
            decoration: InputDecoration(
              labelText: collection ? 'Account' : 'Paid from',
            ),
            items: [
              if (_isSub)
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text(
                    parent == null
                        ? 'Same as the collection'
                        : 'Same as ${parent.name}'
                              '${accountName[parent.accountId] == null ? '' : ' (${accountName[parent.accountId]})'}',
                  ),
                ),
              for (final a in accountChoices)
                DropdownMenuItem<String?>(value: a.id, child: Text(a.name)),
            ],
            onChanged: (v) => setState(() => _accountId = v),
            validator: (v) => !_isSub && v == null ? 'Choose an account' : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<ItemKind>(
            key: const Key('field-kind'),
            initialValue: _kind,
            decoration: const InputDecoration(labelText: 'Kind'),
            items: [
              for (final MapEntry(:key, :value) in itemKindLabels.entries)
                DropdownMenuItem(value: key, child: Text(value)),
            ],
            onChanged: (v) => setState(() => _kind = v ?? _kind),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  key: const Key('field-due'),
                  controller: _dueDay,
                  decoration: const InputDecoration(
                    labelText: 'Due day (optional)',
                    hintText: '1–31',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    final text = v?.trim() ?? '';
                    if (text.isEmpty) return null;
                    final day = int.tryParse(text);
                    return day == null || day < 1 || day > 31
                        ? 'Use 1–31'
                        : null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: TextFormField(
                  key: const Key('field-note'),
                  controller: _note,
                  decoration: const InputDecoration(
                    labelText: 'Note (optional)',
                  ),
                ),
              ),
            ],
          ),
          if (collection)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                'A collection is paid when all its sub-expenses are. '
                'Ticking it marks them all paid.',
                style: TextStyle(fontSize: 12),
              ),
            )
          else ...[
            const SizedBox(height: 8),
            SwitchListTile(
              key: const Key('field-paid'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Paid'),
              subtitle: _paid
                  ? Text('On ${formatShortDate(_paidAt)}')
                  : const Text('Allotted, not paid yet'),
              value: _paid,
              onChanged: (v) => setState(() => _paid = v),
            ),
            if (_paid)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: const Key('field-paid-date'),
                  onPressed: _pickDate,
                  icon: const Icon(Icons.event),
                  label: const Text('Change payment date'),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

bool _sameDay(DateTime a, DateTime? b) =>
    b != null && a.year == b.year && a.month == b.month && a.day == b.day;

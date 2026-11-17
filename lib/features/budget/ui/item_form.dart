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
/// optionally pre-filled with an account or as a sub-expense of the
/// collection [parentId].
Future<void> showItemForm(
  BuildContext context, {
  required String monthId,
  BudgetItem? existing,
  String? accountId,
  String? parentId,
}) {
  return showFormSheet(
    context,
    builder: (_) => ItemForm(
      monthId: monthId,
      existing: existing,
      initialAccountId: accountId,
      initialParentId: parentId,
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
  });

  final String monthId;
  final BudgetItem? existing;
  final String? initialAccountId;
  final String? initialParentId;

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
  late bool _isCollection = _existing?.isCollection ?? false;
  late String? _accountId = _existing?.accountId ?? widget.initialAccountId;
  late ItemKind _kind = _existing?.kind ?? ItemKind.expense;
  late ItemStatus _status = _existing?.status ?? ItemStatus.planned;
  bool get _paid => _status == ItemStatus.paid;
  late DateTime _paidAt = _existing?.paidAt ?? DateTime.now();
  late String? _paidFrom = _existing?.paidFromAccountId;

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
        if (_status != ItemStatus.planned && !collection) {
          await _repo.setStatus(
            id,
            _status,
            paidAt: _paidAt,
            paidFromAccountId: _paidFrom,
          );
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
        if (!collection &&
            (_status != existing.status ||
                (_paid &&
                    (!_sameDay(_paidAt, existing.paidAt) ||
                        _paidFrom != existing.paidFromAccountId)))) {
          await _repo.setStatus(
            existing.id,
            _status,
            paidAt: _paidAt,
            paidFromAccountId: _paidFrom,
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
        if (!a.archived || a.id == _accountId || a.id == _paidFrom) a,
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
              labelText: collection ? 'Account (optional)' : 'Paid from',
              helperText: collection && _accountId == null
                  ? 'Its sub-expenses each choose their own account'
                  : null,
            ),
            items: [
              if (collection)
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('No account'),
                )
              else if (_isSub && parent?.accountId != null)
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text(
                    'Same as ${parent!.name} (${accountName[parent.accountId] ?? '?'})',
                  ),
                ),
              for (final a in accountChoices)
                DropdownMenuItem<String?>(value: a.id, child: Text(a.name)),
            ],
            onChanged: (v) => setState(() => _accountId = v),
            // Only a collection, or a sub-expense of a collection that has
            // an account, may leave this empty.
            validator: (v) =>
                v == null &&
                    !collection &&
                    !(_isSub && (parent == null || parent.accountId != null))
                ? 'Choose an account'
                : null,
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
                'A collection follows its sub-expenses: paid when all are '
                'paid, planned while any is planned. Ticking it pays them '
                'all.',
                style: TextStyle(fontSize: 12),
              ),
            )
          else ...[
            const SizedBox(height: 8),
            const SizedBox(height: 4),
            SegmentedButton<ItemStatus>(
              key: const Key('field-status'),
              segments: const [
                ButtonSegment(
                  value: ItemStatus.planned,
                  label: Text('Planned', key: Key('status-planned')),
                ),
                ButtonSegment(
                  value: ItemStatus.allotted,
                  label: Text('Allotted', key: Key('status-allotted')),
                ),
                ButtonSegment(
                  value: ItemStatus.paid,
                  label: Text('Paid', key: Key('status-paid')),
                ),
              ],
              selected: {_status},
              onSelectionChanged: (s) => setState(() => _status = s.first),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                switch (_status) {
                  ItemStatus.planned =>
                    'Budgeted; the money isn’t in the '
                        'account yet',
                  ItemStatus.allotted =>
                    'The money is in the account, '
                        'waiting to be paid',
                  ItemStatus.paid => 'Paid on ${formatShortDate(_paidAt)}',
                },
                key: const Key('status-help'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            if (_paid) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: const Key('field-paid-date'),
                  onPressed: _pickDate,
                  icon: const Icon(Icons.event),
                  label: const Text('Change payment date'),
                ),
              ),
              const SizedBox(height: 8),
              Builder(
                builder: (context) {
                  final plannedId =
                      _accountId ?? (_isSub ? parent?.accountId : null);
                  final planned = accountName[plannedId];
                  return DropdownButtonFormField<String?>(
                    key: const Key('field-paid-from'),
                    initialValue: _paidFrom == plannedId ? null : _paidFrom,
                    decoration: const InputDecoration(
                      labelText: 'Actually paid from',
                      helperText:
                          'Pick another account if it didn’t come from the '
                          'planned one',
                    ),
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text(
                          planned == null
                              ? 'As planned'
                              : 'As planned ($planned)',
                        ),
                      ),
                      for (final a in accountChoices)
                        if (a.id != plannedId)
                          DropdownMenuItem<String?>(
                            value: a.id,
                            child: Text(a.name),
                          ),
                    ],
                    onChanged: (v) => setState(() => _paidFrom = v),
                  );
                },
              ),
            ],
          ],
        ],
      ),
    );
  }
}

bool _sameDay(DateTime a, DateTime? b) =>
    b != null && a.year == b.year && a.month == b.month && a.day == b.day;

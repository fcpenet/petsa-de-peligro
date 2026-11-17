import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/providers.dart';
import '../../../core/db/database.dart';
import '../../../core/money.dart';
import '../../../core/ui/adaptive.dart';
import '../../budget/ui/item_form.dart' show itemKindLabels;
import '../domain/month_template.dart';

/// The result of a template form: the edited value, or `null` when the
/// user chose Delete. A cancelled form returns no edit at all.
typedef TemplateEdit<T> = ({T? value});

/// An expense plus where it goes: top level, or into the collection at
/// [collectionIndex].
typedef PlacedItem = ({TemplateItem item, int? collectionIndex});

/// Collections the item form can put a sub-expense into: index → name.
typedef CollectionChoices = Map<int, String>;

// -------------------------------------------------------------------- item

Future<TemplateEdit<PlacedItem>?> showTemplateItemForm(
  BuildContext context, {
  required CollectionChoices collections,
  TemplateItem? existing,
  int? collectionIndex,
  String? accountId,
  bool collection = false,
}) => showFormSheet(
  context,
  builder: (_) => TemplateItemForm(
    collections: collections,
    existing: existing,
    initialCollectionIndex: collectionIndex,
    initialAccountId: accountId,
    initialCollection: collection,
  ),
);

class TemplateItemForm extends ConsumerStatefulWidget {
  const TemplateItemForm({
    super.key,
    required this.collections,
    this.existing,
    this.initialCollectionIndex,
    this.initialAccountId,
    this.initialCollection = false,
  });

  final CollectionChoices collections;
  final TemplateItem? existing;
  final int? initialCollectionIndex;
  final String? initialAccountId;
  final bool initialCollection;

  @override
  ConsumerState<TemplateItemForm> createState() => _TemplateItemFormState();
}

class _TemplateItemFormState extends ConsumerState<TemplateItemForm> {
  final _formKey = GlobalKey<FormState>();
  late final TemplateItem? _existing = widget.existing;
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
  late bool _isSub = widget.initialCollectionIndex != null;
  late int? _collectionIndex = widget.initialCollectionIndex;
  late bool _isCollection = _existing?.isCollection ?? widget.initialCollection;
  late final int _childCount = _existing?.children.length ?? 0;
  late String? _accountId = _existing?.accountId ?? widget.initialAccountId;
  late ItemKind _kind = _existing?.kind ?? ItemKind.expense;

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _dueDay.dispose();
    _note.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final note = _note.text.trim();
    final PlacedItem placed = (
      item: TemplateItem(
        name: _name.text.trim(),
        amountCents: _amount.text.trim().isEmpty
            ? 0
            : parsePesoToCents(_amount.text)!,
        accountId: _accountId,
        kind: _kind,
        dueDay: int.tryParse(_dueDay.text.trim()),
        note: note.isEmpty ? null : note,
        isCollection: _isCollection && !_isSub,
      ),
      collectionIndex: _isSub ? _collectionIndex : null,
    );
    Navigator.of(context).pop((value: placed));
  }

  Future<void> _delete() async {
    final n = _childCount;
    final ok = await confirmDelete(
      context,
      '“${_existing!.name}”',
      detail: n == 0
          ? null
          : 'Its $n sub-expense${n == 1 ? '' : 's'} will be deleted too.',
    );
    if (ok && mounted) Navigator.of(context).pop((value: null));
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsProvider).value ?? const [];
    final collections = widget.collections;
    final collection = _isCollection && !_isSub;
    final accountChoices = [
      for (final a in accounts)
        if (!a.archived || a.id == _accountId) a,
    ];
    return Form(
      key: _formKey,
      child: FormLayout(
        title: _existing == null
            ? (collection ? 'Add collection' : 'Add expense')
            : (collection ? 'Edit collection' : 'Edit expense'),
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
                enabled: collections.isNotEmpty && _childCount == 0,
                label: const Text('Sub-expense', key: Key('type-sub')),
                icon: const Icon(Icons.subdirectory_arrow_right),
              ),
            ],
            selected: {_isSub},
            onSelectionChanged: (s) => setState(() {
              _isSub = s.first;
              if (_isSub &&
                  _collectionIndex == null &&
                  collections.length == 1) {
                _collectionIndex = collections.keys.single;
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
            DropdownButtonFormField<int>(
              key: const Key('field-parent'),
              initialValue: collections.containsKey(_collectionIndex)
                  ? _collectionIndex
                  : null,
              decoration: const InputDecoration(labelText: 'Collection'),
              items: [
                for (final MapEntry(:key, :value) in collections.entries)
                  DropdownMenuItem(value: key, child: Text(value)),
              ],
              onChanged: (v) => setState(() => _collectionIndex = v),
              validator: (v) => v == null ? 'Choose a collection' : null,
            ),
            const SizedBox(height: 12),
          ] else
            SwitchListTile(
              key: const Key('field-collection'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Collection'),
              subtitle: Text(
                _childCount > 0
                    ? 'Has $_childCount sub-expense${_childCount == 1 ? '' : 's'}'
                    : 'Holds sub-expenses that can be paid from any '
                          'account, like Misc',
              ),
              value: _isCollection,
              onChanged: _childCount > 0
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
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Same as the collection'),
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
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ income

Future<TemplateEdit<TemplateIncome>?> showTemplateIncomeForm(
  BuildContext context, {
  TemplateIncome? existing,
}) => showFormSheet(
  context,
  builder: (_) => TemplateIncomeForm(existing: existing),
);

class TemplateIncomeForm extends StatefulWidget {
  const TemplateIncomeForm({super.key, this.existing});

  final TemplateIncome? existing;

  @override
  State<TemplateIncomeForm> createState() => _TemplateIncomeFormState();
}

class _TemplateIncomeFormState extends State<TemplateIncomeForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(
    text: widget.existing?.name ?? 'Salary',
  );
  late final _amount = TextEditingController(
    text: widget.existing == null
        ? ''
        : centsToInput(widget.existing!.amountCents),
  );

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final income = TemplateIncome(
      name: _name.text.trim(),
      amountCents: parsePesoToCents(_amount.text)!,
      accountId: widget.existing?.accountId,
    );
    Navigator.of(context).pop((value: income));
  }

  Future<void> _delete() async {
    if (!await confirmDelete(context, '“${widget.existing!.name}”')) return;
    if (mounted) Navigator.of(context).pop((value: null));
  }

  @override
  Widget build(BuildContext context) => Form(
    key: _formKey,
    child: FormLayout(
      title: widget.existing == null ? 'Add income' : 'Edit income',
      onSave: _save,
      onDelete: widget.existing == null ? null : _delete,
      children: [
        TextFormField(
          key: const Key('field-name'),
          controller: _name,
          decoration: const InputDecoration(labelText: 'Name'),
          validator: (v) => (v?.trim().isEmpty ?? true) ? 'Enter a name' : null,
        ),
        const SizedBox(height: 12),
        AmountField(
          key: const Key('field-amount'),
          controller: _amount,
          label: 'Expected amount',
          helperText: 'Top-ups are recorded on each month',
        ),
      ],
    ),
  );
}

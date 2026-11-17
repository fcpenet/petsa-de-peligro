import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/providers.dart';
import '../../../core/db/database.dart';
import '../../../core/money.dart';
import '../../../core/ui/adaptive.dart';
import '../data/budget_repository.dart';

// ------------------------------------------------------------------ income

Future<void> showIncomeForm(
  BuildContext context, {
  required String monthId,
  Income? existing,
}) => showFormSheet(
  context,
  builder: (_) => IncomeForm(monthId: monthId, existing: existing),
);

class IncomeForm extends ConsumerStatefulWidget {
  const IncomeForm({super.key, required this.monthId, this.existing});

  final String monthId;
  final Income? existing;

  @override
  ConsumerState<IncomeForm> createState() => _IncomeFormState();
}

class _IncomeFormState extends ConsumerState<IncomeForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(
    text: widget.existing?.name ?? 'Salary',
  );
  late final _amount = TextEditingController(
    text: widget.existing == null
        ? ''
        : centsToInput(widget.existing!.amountCents),
  );
  bool _saving = false;
  String? _error;

  BudgetRepository get _repo => ref.read(budgetRepositoryProvider);

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final cents = parsePesoToCents(_amount.text)!;
    try {
      final existing = widget.existing;
      if (existing == null) {
        await _repo.addIncome(
          monthId: widget.monthId,
          name: _name.text,
          amountCents: cents,
        );
      } else {
        await _repo.updateIncome(
          existing.id,
          name: _name.text,
          amountCents: cents,
        );
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
    final existing = widget.existing!;
    if (!await confirmDelete(context, '“${existing.name}”')) return;
    setState(() => _saving = true);
    await _repo.deleteIncome(existing.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => Form(
    key: _formKey,
    child: FormLayout(
      title: widget.existing == null ? 'Add income' : 'Edit income',
      saving: _saving,
      error: _error,
      onSave: _save,
      onDelete: widget.existing == null ? null : _delete,
      children: [
        TextFormField(
          key: const Key('field-name'),
          controller: _name,
          decoration: const InputDecoration(
            labelText: 'Name',
            hintText: 'Salary, 13th month, SL conversion…',
          ),
          validator: (v) => (v?.trim().isEmpty ?? true) ? 'Enter a name' : null,
        ),
        const SizedBox(height: 12),
        AmountField(
          key: const Key('field-amount'),
          controller: _amount,
          label: 'Expected amount',
          helperText: widget.existing == null
              ? 'Record what actually arrives with top-ups'
              : null,
        ),
        if (widget.existing case final income?)
          _TopUpList(monthId: widget.monthId, income: income),
      ],
    ),
  );
}

/// The top-ups of an income, inside its form.
class _TopUpList extends ConsumerWidget {
  const _TopUpList({required this.monthId, required this.income});

  final String monthId;
  final Income income;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topUps = [
      for (final t
          in ref.watch(topUpsProvider(monthId)).value ?? const <TopUp>[])
        if (t.incomeId == income.id) t,
    ];
    final received = topUps.fold(0, (s, t) => s + t.amountCents);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: 12,
          children: [
            Text('Received', style: theme.textTheme.titleSmall),
            Text(
              '${formatPeso(received)} of ${formatPeso(income.amountCents)}',
              key: const Key('received-summary'),
            ),
          ],
        ),
        if (topUps.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Nothing received yet.'),
          ),
        for (final t in topUps)
          ListTile(
            key: ValueKey('top-up-${t.id}'),
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: const Icon(Icons.south_west, size: 20),
            title: Text(formatShortDate(t.receivedAt)),
            subtitle: t.note == null ? null : Text(t.note!),
            trailing: Text(
              formatPeso(t.amountCents),
              style: theme.textTheme.bodyLarge,
            ),
            onTap: () => showTopUpForm(context, income: income, existing: t),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            key: const Key('add-top-up'),
            onPressed: () => showTopUpForm(context, income: income),
            icon: const Icon(Icons.add),
            label: const Text('Add top-up'),
          ),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------------ top-up

Future<void> showTopUpForm(
  BuildContext context, {
  required Income income,
  TopUp? existing,
}) => showFormSheet(
  context,
  builder: (_) => TopUpForm(income: income, existing: existing),
);

/// Money that actually arrived for an income, with the date it came in.
class TopUpForm extends ConsumerStatefulWidget {
  const TopUpForm({super.key, required this.income, this.existing});

  final Income income;
  final TopUp? existing;

  @override
  ConsumerState<TopUpForm> createState() => _TopUpFormState();
}

class _TopUpFormState extends ConsumerState<TopUpForm> {
  final _formKey = GlobalKey<FormState>();
  late final _amount = TextEditingController(
    text: widget.existing == null
        ? ''
        : centsToInput(widget.existing!.amountCents),
  );
  late final _note = TextEditingController(text: widget.existing?.note);
  late DateTime _receivedAt = widget.existing?.receivedAt ?? _today();
  bool _saving = false;
  String? _error;

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  BudgetRepository get _repo => ref.read(budgetRepositoryProvider);

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _receivedAt,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Date received',
    );
    if (date != null) setState(() => _receivedAt = date);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final cents = parsePesoToCents(_amount.text)!;
    try {
      final existing = widget.existing;
      if (existing == null) {
        await _repo.addTopUp(
          incomeId: widget.income.id,
          amountCents: cents,
          receivedAt: _receivedAt,
          note: _note.text,
        );
      } else {
        await _repo.updateTopUp(
          existing.id,
          amountCents: cents,
          receivedAt: _receivedAt,
          note: Value(_note.text),
        );
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
    final existing = widget.existing!;
    final ok = await confirmDelete(
      context,
      'top-up of ${formatPeso(existing.amountCents)}',
    );
    if (!ok) return;
    setState(() => _saving = true);
    await _repo.deleteTopUp(existing.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final monthId = widget.income.monthId;
    final received = [
      for (final t
          in ref.watch(topUpsProvider(monthId)).value ?? const <TopUp>[])
        if (t.incomeId == widget.income.id && t.id != widget.existing?.id)
          t.amountCents,
    ].fold(0, (s, v) => s + v);
    final left = widget.income.amountCents - received;
    return Form(
      key: _formKey,
      child: FormLayout(
        title: widget.existing == null
            ? 'Top up ${widget.income.name}'
            : 'Edit top-up',
        saving: _saving,
        error: _error,
        onSave: _save,
        onDelete: widget.existing == null ? null : _delete,
        children: [
          AmountField(
            key: const Key('field-amount'),
            controller: _amount,
            label: 'Amount received',
            helperText: left > 0
                ? '${formatPeso(left)} of ${formatPeso(widget.income.amountCents)} '
                      'still expected'
                : 'Expected ${formatPeso(widget.income.amountCents)}',
          ),
          const SizedBox(height: 12),
          InputDecorator(
            decoration: const InputDecoration(labelText: 'Date received'),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    formatShortDate(_receivedAt),
                    key: const Key('field-date-text'),
                  ),
                ),
                TextButton.icon(
                  key: const Key('field-date'),
                  onPressed: _pickDate,
                  icon: const Icon(Icons.event),
                  label: const Text('Change'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('field-note'),
            controller: _note,
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
              hintText: '15th payout, after tax…',
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- transfer

Future<void> showTransferForm(
  BuildContext context, {
  required String monthId,
  Transfer? existing,
  String? fromAccountId,
  String? toAccountId,
  int? amountCents,
}) => showFormSheet(
  context,
  builder: (_) => TransferForm(
    monthId: monthId,
    existing: existing,
    initialFrom: fromAccountId,
    initialTo: toAccountId,
    initialAmount: amountCents,
  ),
);

/// Money moved from one account to another.
class TransferForm extends ConsumerStatefulWidget {
  const TransferForm({
    super.key,
    required this.monthId,
    this.existing,
    this.initialFrom,
    this.initialTo,
    this.initialAmount,
  });

  final String monthId;
  final Transfer? existing;
  final String? initialFrom;
  final String? initialTo;
  final int? initialAmount;

  @override
  ConsumerState<TransferForm> createState() => _TransferFormState();
}

class _TransferFormState extends ConsumerState<TransferForm> {
  final _formKey = GlobalKey<FormState>();
  late String? _from = widget.existing?.fromAccountId ?? widget.initialFrom;
  late String? _to = widget.existing?.toAccountId ?? widget.initialTo;
  late final _amount = TextEditingController(
    text: switch (widget.existing?.amountCents ?? widget.initialAmount) {
      final cents? => centsToInput(cents),
      null => '',
    },
  );
  late final _note = TextEditingController(text: widget.existing?.note);
  late DateTime _date = widget.existing?.transferredAt ?? _today();
  bool _saving = false;
  String? _error;

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  BudgetRepository get _repo => ref.read(budgetRepositoryProvider);

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Date moved',
    );
    if (date != null) setState(() => _date = date);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final cents = parsePesoToCents(_amount.text)!;
    try {
      final existing = widget.existing;
      if (existing == null) {
        await _repo.addTransfer(
          monthId: widget.monthId,
          fromAccountId: _from!,
          toAccountId: _to!,
          amountCents: cents,
          transferredAt: _date,
          note: _note.text,
        );
      } else {
        await _repo.updateTransfer(
          existing.id,
          fromAccountId: _from!,
          toAccountId: _to!,
          amountCents: cents,
          transferredAt: _date,
          note: _note.text,
        );
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
    final existing = widget.existing!;
    final ok = await confirmDelete(
      context,
      'transfer of ${formatPeso(existing.amountCents)}',
    );
    if (!ok) return;
    setState(() => _saving = true);
    await _repo.deleteTransfer(existing.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final accounts = [
      for (final a in ref.watch(accountsProvider).value ?? const <Account>[])
        if (!a.archived || a.id == _from || a.id == _to) a,
    ];
    DropdownButtonFormField<String> picker(
      String key,
      String label,
      String? value,
      ValueChanged<String?> onChanged,
    ) => DropdownButtonFormField<String>(
      key: Key(key),
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final a in accounts)
          DropdownMenuItem(value: a.id, child: Text(a.name)),
      ],
      onChanged: onChanged,
      validator: (v) => v == null
          ? 'Choose an account'
          : _from == _to
          ? 'Choose two different accounts'
          : null,
    );

    return Form(
      key: _formKey,
      child: FormLayout(
        title: widget.existing == null ? 'Move money' : 'Edit transfer',
        saving: _saving,
        error: _error,
        onSave: _save,
        onDelete: widget.existing == null ? null : _delete,
        children: [
          picker('field-from', 'From', _from, (v) => setState(() => _from = v)),
          const SizedBox(height: 12),
          picker('field-to', 'To', _to, (v) => setState(() => _to = v)),
          const SizedBox(height: 12),
          AmountField(key: const Key('field-amount'), controller: _amount),
          const SizedBox(height: 12),
          InputDecorator(
            decoration: const InputDecoration(labelText: 'Date moved'),
            child: Row(
              children: [
                Expanded(child: Text(formatShortDate(_date))),
                TextButton.icon(
                  key: const Key('field-date'),
                  onPressed: _pickDate,
                  icon: const Icon(Icons.event),
                  label: const Text('Change'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('field-note'),
            controller: _note,
            decoration: const InputDecoration(labelText: 'Note (optional)'),
          ),
        ],
      ),
    );
  }
}

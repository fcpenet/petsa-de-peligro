import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/providers.dart';
import '../../../core/db/database.dart';
import '../../../core/ui/adaptive.dart';

const accountTypeLabels = {
  AccountType.bank: 'Bank account',
  AccountType.creditCard: 'Credit card',
  AccountType.ewallet: 'E-wallet',
  AccountType.cash: 'Cash',
};

const accountTypeIcons = {
  AccountType.bank: Icons.account_balance,
  AccountType.creditCard: Icons.credit_card,
  AccountType.ewallet: Icons.account_balance_wallet,
  AccountType.cash: Icons.payments,
};

Future<void> showAccountForm(BuildContext context, {Account? existing}) =>
    showFormSheet(context, builder: (_) => AccountForm(existing: existing));

class AccountForm extends ConsumerStatefulWidget {
  const AccountForm({super.key, this.existing});

  final Account? existing;

  @override
  ConsumerState<AccountForm> createState() => _AccountFormState();
}

class _AccountFormState extends ConsumerState<AccountForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.existing?.name);
  late final TextEditingController _bank;
  late AccountType _type = widget.existing?.type ?? AccountType.bank;
  late bool _archived = widget.existing?.archived ?? false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final institutions = ref.read(institutionsProvider).value ?? const [];
    final bank = institutions
        .where((i) => i.id == widget.existing?.institutionId)
        .firstOrNull;
    _bank = TextEditingController(text: bank?.name);
  }

  @override
  void dispose() {
    _name.dispose();
    _bank.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final repo = ref.read(accountRepositoryProvider);
    try {
      final bank = _bank.text.trim();
      final institutionId = bank.isEmpty
          ? null
          : await repo.findOrCreateInstitution(bank);
      final existing = widget.existing;
      if (existing == null) {
        final count = ref.read(accountsProvider).value?.length ?? 0;
        await repo.createAccount(
          name: _name.text,
          type: _type,
          institutionId: institutionId,
          sortOrder: count,
        );
      } else {
        await repo.updateAccount(
          existing.id,
          name: _name.text,
          type: _type,
          institutionId: Value(institutionId),
        );
        if (_archived != existing.archived) {
          await repo.setArchived(existing.id, archived: _archived);
        }
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _saving = false;
        _error = 'Could not save: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) => Form(
    key: _formKey,
    child: FormLayout(
      title: widget.existing == null ? 'Add account' : 'Edit account',
      saving: _saving,
      error: _error,
      onSave: _save,
      children: [
        TextFormField(
          key: const Key('field-name'),
          controller: _name,
          autofocus: widget.existing == null,
          decoration: const InputDecoration(
            labelText: 'Name',
            hintText: 'e.g. UB, RCBC Card, GCash',
          ),
          validator: (v) => (v?.trim().isEmpty ?? true) ? 'Enter a name' : null,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<AccountType>(
          key: const Key('field-type'),
          initialValue: _type,
          decoration: const InputDecoration(labelText: 'Type'),
          items: [
            for (final MapEntry(:key, :value) in accountTypeLabels.entries)
              DropdownMenuItem(
                value: key,
                child: Row(
                  children: [
                    Icon(accountTypeIcons[key], size: 18),
                    const SizedBox(width: 8),
                    Text(value),
                  ],
                ),
              ),
          ],
          onChanged: (t) => setState(() => _type = t ?? _type),
        ),
        const SizedBox(height: 12),
        TextFormField(
          key: const Key('field-bank'),
          controller: _bank,
          decoration: const InputDecoration(
            labelText: 'Bank (optional)',
            hintText: 'e.g. BPI',
          ),
        ),
        if (widget.existing != null) ...[
          const SizedBox(height: 8),
          SwitchListTile(
            key: const Key('field-archived'),
            contentPadding: EdgeInsets.zero,
            title: const Text('Archived'),
            subtitle: const Text(
              'Hidden from new entries. Past months keep it.',
            ),
            value: _archived,
            onChanged: (v) => setState(() => _archived = v),
          ),
        ],
      ],
    ),
  );
}

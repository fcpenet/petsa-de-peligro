import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/providers.dart';
import '../../../core/db/database.dart';
import 'account_form.dart';

class AccountsPage extends ConsumerWidget {
  const AccountsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountsProvider);
    final institutions = ref.watch(institutionsProvider).value ?? const [];
    final bankName = {for (final i in institutions) i.id: i.name};

    Widget tile(Account a) => ListTile(
      key: ValueKey('account-${a.id}'),
      leading: Icon(accountTypeIcons[a.type]),
      title: Text(a.name),
      subtitle: Text(
        [accountTypeLabels[a.type]!, ?bankName[a.institutionId]].join(' · '),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => showAccountForm(context, existing: a),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Accounts')),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('add-account'),
        onPressed: () => showAccountForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Account'),
      ),
      body: switch (accounts) {
        AsyncData(:final value) when value.isEmpty => const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'No accounts yet. Add the banks, cards and wallets you pay from.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        AsyncData(:final value) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
              children: [
                Card(
                  child: Column(
                    children: [
                      for (final a in value.where((a) => !a.archived)) tile(a),
                    ],
                  ),
                ),
                if (value.any((a) => a.archived)) ...[
                  const Padding(
                    padding: EdgeInsets.fromLTRB(8, 16, 8, 4),
                    child: Text('Archived'),
                  ),
                  Card(
                    child: Column(
                      children: [
                        for (final a in value.where((a) => a.archived)) tile(a),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        AsyncError(:final error) => Center(child: Text('Error: $error')),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

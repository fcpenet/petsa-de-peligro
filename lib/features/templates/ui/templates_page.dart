import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/providers.dart';
import '../../../core/money.dart';
import '../domain/month_template.dart';

/// Saved templates. Route: `/templates`.
class TemplatesPage extends ConsumerWidget {
  const TemplatesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templates = ref.watch(templatesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Templates')),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('new-template'),
        onPressed: () => context.push('/templates/new'),
        icon: const Icon(Icons.add),
        label: const Text('Template'),
      ),
      body: switch (templates) {
        AsyncData(:final value) when value.isEmpty => const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'No templates yet. Create one here, or save a month as a '
              'template from the Budget page.',
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
                      for (final row in value)
                        ListTile(
                          key: ValueKey('template-${row.id}'),
                          leading: const Icon(Icons.copy_all),
                          title: Text(row.name),
                          subtitle: Text(_summary(row.payload)),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.push('/templates/${row.id}'),
                        ),
                    ],
                  ),
                ),
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

String _summary(String payload) {
  try {
    final t = MonthTemplate.decode(payload);
    final n = t.itemCount;
    return [
      '$n item${n == 1 ? '' : 's'}',
      '${formatPeso(t.expenseCents)} expenses',
      if (t.incomes.isNotEmpty) '${formatPeso(t.incomeCents)} income',
    ].join(' · ');
  } on FormatException catch (e) {
    return e.message;
  }
}

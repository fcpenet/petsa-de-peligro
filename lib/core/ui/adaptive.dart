import 'package:material_ui/material_ui.dart';

import '../money.dart';

/// Below this width the app uses its phone layout.
const narrowBreakpoint = 640.0;

bool isNarrow(BuildContext context) =>
    MediaQuery.sizeOf(context).width < narrowBreakpoint;

/// Opens a form as a bottom sheet on phones and a dialog on wider screens.
Future<T?> showFormSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  if (isNarrow(context)) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (c) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(c).bottom),
        child: builder(c),
      ),
    );
  }
  return showDialog<T>(
    context: context,
    builder: (c) => Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: builder(c),
      ),
    ),
  );
}

/// Title, scrollable fields and a button row, shared by every form.
class FormLayout extends StatelessWidget {
  const FormLayout({
    super.key,
    required this.title,
    required this.children,
    required this.onSave,
    this.onDelete,
    this.saving = false,
    this.error,
  });

  final String title;
  final List<Widget> children;
  final VoidCallback onSave;
  final VoidCallback? onDelete;
  final bool saving;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          ...children,
          if (error != null) ...[
            const SizedBox(height: 12),
            Text(
              error!,
              key: const Key('form-error'),
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              if (onDelete != null)
                TextButton.icon(
                  key: const Key('form-delete'),
                  onPressed: saving ? null : onDelete,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                ),
              const Spacer(),
              TextButton(
                onPressed: saving ? null : () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                key: const Key('form-save'),
                onPressed: saving ? null : onSave,
                child: saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A peso amount input that validates with [parsePesoToCents].
class AmountField extends StatelessWidget {
  const AmountField({
    super.key,
    required this.controller,
    this.label = 'Amount',
    this.required = true,
    this.helperText,
  });

  final TextEditingController controller;
  final String label;
  final bool required;
  final String? helperText;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    decoration: InputDecoration(
      labelText: label,
      prefixText: '₱ ',
      helperText: helperText,
    ),
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    validator: (v) {
      final text = v?.trim() ?? '';
      if (text.isEmpty) return required ? 'Enter an amount' : null;
      return parsePesoToCents(text) == null
          ? 'Enter an amount like 1,250.50'
          : null;
    },
  );
}

/// Centavos → text for an amount field ("7000", "296.26").
String centsToInput(int cents) {
  final pesos = cents ~/ 100;
  final centavos = cents % 100;
  return centavos == 0
      ? '$pesos'
      : '$pesos.${centavos.toString().padLeft(2, '0')}';
}

const _monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

String monthLabel(String yearMonth, {bool short = false}) {
  final parts = yearMonth.split('-');
  final name = _monthNames[int.parse(parts[1]) - 1];
  return '${short ? name.substring(0, 3) : name} ${parts[0]}';
}

String shiftMonth(String yearMonth, int delta) {
  final parts = yearMonth.split('-');
  final d = DateTime(int.parse(parts[0]), int.parse(parts[1]) + delta);
  return '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}';
}

/// ‹ November 2026 › (‹ Nov 2026 › on phones). Shrinks rather than
/// overflowing when space is tight.
class MonthSwitcher extends StatelessWidget {
  const MonthSwitcher({
    super.key,
    required this.yearMonth,
    required this.onChanged,
  });

  final String yearMonth;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final label = isNarrow(context)
        ? monthLabel(yearMonth, short: true)
        : monthLabel(yearMonth);
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Previous month',
            icon: const Icon(Icons.chevron_left),
            onPressed: () => onChanged(shiftMonth(yearMonth, -1)),
          ),
          Text(
            label,
            key: const Key('month-label'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          IconButton(
            tooltip: 'Next month',
            icon: const Icon(Icons.chevron_right),
            onPressed: () => onChanged(shiftMonth(yearMonth, 1)),
          ),
        ],
      ),
    );
  }
}

Future<bool> confirmDelete(
  BuildContext context,
  String what, {
  String? detail,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Delete $what?'),
      content: detail == null ? null : Text(detail),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('confirm-delete'),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  return result ?? false;
}

const _shortMonths = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String formatShortDate(DateTime d) =>
    '${_shortMonths[d.month - 1]} ${d.day}, ${d.year}';

import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/providers.dart';
import '../../../core/db/database.dart';
import '../../../core/money.dart';
import '../../../core/ui/adaptive.dart';
import '../../budget/data/budget_repository.dart';
import '../../summary/domain/account_summary.dart';
import '../domain/chart_data.dart';

/// Charts for a month or a date range: status, accounts, month by month and
/// where the money goes.
/// Routes: `/charts/:yearMonth` and `/charts/range?from=…&to=…`.
class ChartsPage extends ConsumerWidget {
  const ChartsPage({super.key, required this.yearMonth}) : range = null;

  const ChartsPage.range({super.key, required DayRange this.range})
    : yearMonth = null;

  final String? yearMonth;
  final DayRange? range;

  /// How many months the month-by-month chart shows in month view.
  static const trendMonths = 6;

  /// The most months it shows for a long range (the latest ones).
  static const maxTrendMonths = 24;

  static String rangeLocation(DayRange r) =>
      '/charts/range?from=${_day(r.from)}&to=${_day(r.to)}';

  static String _day(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickRange(BuildContext context) async {
    final current = range;
    final DateTimeRange initial;
    if (current != null) {
      initial = DateTimeRange(start: current.from, end: current.to);
    } else {
      final [y, m] = [for (final p in yearMonth!.split('-')) int.parse(p)];
      initial = DateTimeRange(
        start: DateTime(y, m),
        end: DateTime(y, m + 1, 0),
      );
    }
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Charts for these dates',
    );
    if (picked != null && context.mounted) {
      context.go(rangeLocation((from: picked.start, to: picked.end)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = this.range;
    return Scaffold(
      appBar: AppBar(
        title: range == null
            ? MonthSwitcher(
                yearMonth: yearMonth!,
                onChanged: (ym) => context.go('/charts/$ym'),
              )
            : FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${formatShortDate(range.from)} – '
                  '${formatShortDate(range.to)}',
                  key: const Key('charts-range-label'),
                ),
              ),
        centerTitle: true,
        leading: range == null
            ? null
            : IconButton(
                key: const Key('charts-range-clear'),
                tooltip: 'Back to month view',
                icon: const Icon(Icons.close),
                onPressed: () => context.go(
                  '/charts/${BudgetRepository.yearMonthOf(range.to)}',
                ),
              ),
        actions: [
          IconButton(
            key: const Key('charts-range'),
            tooltip: 'Choose dates',
            icon: const Icon(Icons.date_range),
            onPressed: () => _pickRange(context),
          ),
        ],
      ),
      body: range == null
          ? switch (ref.watch(monthProvider(yearMonth!))) {
              AsyncData(:final value) => _MonthCharts(month: value),
              AsyncError(:final error) => Center(child: Text('Error: $error')),
              _ => const Center(child: CircularProgressIndicator()),
            }
          : _RangeCharts(range: range),
    );
  }
}

class _MonthCharts extends ConsumerWidget {
  const _MonthCharts({required this.month});

  final Month month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(itemsProvider(month.id));
    final accounts = ref.watch(accountsProvider);
    final error = items.error ?? accounts.error;
    if (error != null) return Center(child: Text('Error: $error'));
    if (!items.hasValue || !accounts.hasValue) {
      return const Center(child: CircularProgressIndicator());
    }
    return _ChartList(
      data: chartDataFor(items.requireValue),
      accounts: accounts.requireValue,
      trend: monthsEndingAt(month.yearMonth, ChartsPage.trendMonths),
      emptyText: 'Nothing budgeted this month yet.',
    );
  }
}

class _RangeCharts extends ConsumerWidget {
  const _RangeCharts({required this.range});

  final DayRange range;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = ref.watch(rangeItemsProvider(range));
    final accounts = ref.watch(accountsProvider);
    final error = rows.error ?? accounts.error;
    if (error != null) return Center(child: Text('Error: $error'));
    if (!rows.hasValue || !accounts.hasValue) {
      return const Center(child: CircularProgressIndicator());
    }
    final yearMonthOf = {
      for (final (item, ym) in rows.requireValue) item.monthId: ym,
    };
    final months = monthsBetween(
      BudgetRepository.yearMonthOf(range.from),
      BudgetRepository.yearMonthOf(range.to),
    );
    return _ChartList(
      data: chartDataFor(
        [for (final (item, _) in rows.requireValue) item],
        include: (i) => isInRange(itemDate(i, yearMonthOf[i.monthId]!), range),
      ),
      accounts: accounts.requireValue,
      trend: months.length > ChartsPage.maxTrendMonths
          ? months.sublist(months.length - ChartsPage.maxTrendMonths)
          : months,
      emptyText: 'Nothing paid or due in these dates.',
      note:
          'Paid expenses count on their payment date; unpaid ones on their '
          'due day, or the 1st of their month. Month by month shows whole '
          'months.',
    );
  }
}

// ------------------------------------------------------------------ colors

/// Status is an ordered progression, so one hue from light (planned) to dark
/// (paid). Validated as an ordinal ramp on light and dark surfaces.
const statusColors = {
  ItemStatus.planned: Color(0xFF86B6EF),
  ItemStatus.allotted: Color(0xFF5598E7),
  ItemStatus.charged: Color(0xFF2A78D6),
  ItemStatus.paid: Color(0xFF1C5CAB),
};

const statusLabels = {
  ItemStatus.planned: 'Planned',
  ItemStatus.allotted: 'Allotted',
  ItemStatus.charged: 'Charged',
  ItemStatus.paid: 'Paid',
};

/// Categorical slots in fixed order (never cycled); dark mode uses the same
/// hues stepped for the dark surface.
const _seriesLight = [
  Color(0xFF2A78D6),
  Color(0xFFEB6834),
  Color(0xFF1BAF7A),
  Color(0xFFEDA100),
  Color(0xFFE87BA4),
  Color(0xFF008300),
  Color(0xFF6250D6),
];
const _seriesDark = [
  Color(0xFF3987E5),
  Color(0xFFD95926),
  Color(0xFF199E70),
  Color(0xFFC98500),
  Color(0xFFD55181),
  Color(0xFF0CA30C),
  Color(0xFF9085E9),
];

List<Color> seriesColors(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? _seriesDark
    : _seriesLight;

/// "Other" is neutral, never a series hue.
Color otherColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? const Color(0xFF6B6A66)
    : const Color(0xFFB5B3AC);

/// ₱1.2k, ₱45k, ₱1.3M: for axes, where full amounts don't fit.
String compactPeso(num pesos) {
  final v = pesos.abs();
  final sign = pesos < 0 ? '-' : '';
  String trim(double x) => x >= 10
      ? x.round().toString()
      : x.toStringAsFixed(1).replaceAll('.0', '');
  if (v >= 1e6) return '$sign₱${trim(v / 1e6)}M';
  if (v >= 1e3) return '$sign₱${trim(v / 1e3)}k';
  return '$sign₱${v.round()}';
}

String _percent(int part, int total) =>
    total == 0 ? '0%' : '${(part * 100 / total).round()}%';

// ------------------------------------------------------------------- page

class _ChartList extends StatelessWidget {
  const _ChartList({
    required this.data,
    required this.accounts,
    required this.trend,
    required this.emptyText,
    this.note,
  });

  final ChartData data;
  final List<Account> accounts;
  final List<String> trend;
  final String emptyText;
  final String? note;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: ListView(
          key: const Key('charts-list'),
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 32),
          children: [
            if (note != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
                child: Text(
                  note!,
                  key: const Key('charts-range-note'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            if (data.isEmpty)
              Card(
                key: const Key('charts-empty'),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(emptyText),
                ),
              )
            else ...[
              _StatusCard(data: data),
              _AccountsCard(data: data, accounts: accounts),
            ],
            _TrendCard(yearMonths: trend),
            if (!data.isEmpty) _WhereCard(data: data),
          ],
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.child,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleMedium),
                      if (subtitle != null)
                        Text(subtitle!, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

/// A legend entry: swatch + label (+ value). Text stays in text colors.
class _LegendItem extends StatelessWidget {
  const _LegendItem({
    super.key,
    required this.color,
    required this.label,
    this.value,
  });

  final Color color;
  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: theme.textTheme.bodySmall),
        if (value != null) ...[
          const SizedBox(width: 4),
          Text(
            value!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ],
    );
  }
}

/// A horizontal bar split into status segments with 2px gaps, rounded ends,
/// and a tooltip per segment. [scale] is the cents of a full-width bar.
class _StackedBar extends StatelessWidget {
  const _StackedBar({
    required this.parts,
    required this.scale,
    this.height = 14,
  });

  final Map<ItemStatus, int> parts;
  final int scale;
  final double height;

  @override
  Widget build(BuildContext context) {
    final total = parts.values.fold(0, (s, v) => s + v);
    final segments = [
      for (final s in ItemStatus.values)
        if ((parts[s] ?? 0) > 0) s,
    ];
    final rest = math.max(0, scale - total);
    return SizedBox(
      height: height,
      child: Row(
        children: [
          for (final (n, s) in segments.indexed) ...[
            if (n > 0) const SizedBox(width: 2),
            Expanded(
              flex: parts[s]!,
              child: Tooltip(
                message: '${statusLabels[s]} ${formatPeso(parts[s]!)}',
                child: Container(
                  decoration: BoxDecoration(
                    color: statusColors[s],
                    borderRadius: BorderRadius.horizontal(
                      left: n == 0 ? const Radius.circular(4) : Radius.zero,
                      right: n == segments.length - 1
                          ? const Radius.circular(4)
                          : Radius.zero,
                    ),
                  ),
                ),
              ),
            ),
          ],
          if (rest > 0) Spacer(flex: rest),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------- status

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.data});

  final ChartData data;

  @override
  Widget build(BuildContext context) {
    final total = data.totalCents;
    final paid = data.byStatus[ItemStatus.paid]!;
    return _ChartCard(
      key: const Key('chart-status'),
      title: 'Status',
      subtitle: '${_percent(paid, total)} paid of ${formatPeso(total)}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StackedBar(parts: data.byStatus, scale: total, height: 20),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              for (final s in ItemStatus.values)
                if (data.byStatus[s]! > 0 || s != ItemStatus.charged)
                  _LegendItem(
                    key: Key('status-${s.name}'),
                    color: statusColors[s]!,
                    label: statusLabels[s]!,
                    value: formatPeso(data.byStatus[s]!),
                  ),
            ],
          ),
        ],
      ),
    );
  }
}

// --------------------------------------------------------------- accounts

class _AccountsCard extends StatelessWidget {
  const _AccountsCard({required this.data, required this.accounts});

  final ChartData data;
  final List<Account> accounts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final order = {for (final (i, a) in accounts.indexed) a.id: i};
    final name = {for (final a in accounts) a.id: a.name};
    final rows = data.byAccount.entries.toList()
      ..sort(
        (a, b) => (order[a.key] ?? 1 << 30).compareTo(order[b.key] ?? 1 << 30),
      );
    int sum(Map<ItemStatus, int> m) => m.values.fold(0, (s, v) => s + v);
    final scale = rows.map((e) => sum(e.value)).fold(0, math.max);

    return _ChartCard(
      key: const Key('chart-accounts'),
      title: 'By account',
      subtitle: 'Paid, charged, allotted and planned in each account',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              for (final s in ItemStatus.values)
                _LegendItem(color: statusColors[s]!, label: statusLabels[s]!),
            ],
          ),
          const SizedBox(height: 12),
          for (final MapEntry(key: id, value: parts) in rows)
            Padding(
              key: Key('chart-account-${id ?? 'none'}'),
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name[id] ?? 'No account',
                          style: theme.textTheme.bodyMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        () {
                          final left = sum(parts) - parts[ItemStatus.paid]!;
                          return left == 0
                              ? '${formatPeso(sum(parts))} · all paid'
                              : '${formatPeso(left)} left of '
                                    '${formatPeso(sum(parts))}';
                        }(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  _StackedBar(parts: parts, scale: scale),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ trend

class _TrendCard extends ConsumerStatefulWidget {
  const _TrendCard({required this.yearMonths});

  final List<String> yearMonths;

  @override
  ConsumerState<_TrendCard> createState() => _TrendCardState();
}

class _TrendCardState extends ConsumerState<_TrendCard> {
  bool _table = false;

  static const _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String _label(String ym, {bool year = false}) {
    final [y, m] = [for (final p in ym.split('-')) int.parse(p)];
    return year ? '${_monthNames[m - 1]} $y' : _monthNames[m - 1];
  }

  @override
  Widget build(BuildContext context) {
    final span = (from: widget.yearMonths.first, to: widget.yearMonths.last);
    final items = ref.watch(spanItemsProvider(span));
    final incomes = ref.watch(spanIncomesProvider(span));
    final topUps = ref.watch(spanTopUpsProvider(span));
    final error = items.error ?? incomes.error ?? topUps.error;
    final Widget body;
    if (error != null) {
      body = Text('Error: $error');
    } else if (!items.hasValue || !incomes.hasValue || !topUps.hasValue) {
      body = const SizedBox(
        height: 220,
        child: Center(child: CircularProgressIndicator()),
      );
    } else {
      final points = monthlySeries(
        yearMonths: widget.yearMonths,
        items: items.requireValue,
        incomes: incomes.requireValue,
        topUps: topUps.requireValue,
      );
      body = _table
          ? _trendTable(context, points)
          : _trendChart(context, points);
    }

    return _ChartCard(
      key: const Key('chart-trend'),
      title: 'Month by month',
      subtitle: 'Expenses budgeted and income expected',
      trailing: TextButton(
        key: const Key('trend-table'),
        onPressed: () => setState(() => _table = !_table),
        child: Text(_table ? 'Chart' : 'Table'),
      ),
      child: body,
    );
  }

  Widget _trendChart(BuildContext context, List<MonthPoint> points) {
    final theme = Theme.of(context);
    final colors = seriesColors(context);
    final expenses = colors[0];
    final income = colors[1];
    final top = points
        .expand((p) => [p.expensesCents, p.incomeCents])
        .fold(0, math.max);
    final maxY = top == 0 ? 1000.0 : top / 100 * 1.1;
    final interval = _niceInterval(maxY);
    final muted = theme.colorScheme.onSurfaceVariant;
    final grid = theme.colorScheme.outlineVariant.withValues(alpha: 0.5);
    final barWidth = points.length > 12 ? 5.0 : 10.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 16,
          children: [
            _LegendItem(color: expenses, label: 'Expenses'),
            _LegendItem(color: income, label: 'Income'),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: BarChart(
            key: const Key('trend-bars'),
            BarChartData(
              maxY: maxY,
              alignment: BarChartAlignment.spaceAround,
              borderData: FlBorderData(
                show: true,
                border: Border(bottom: BorderSide(color: grid)),
              ),
              gridData: FlGridData(
                drawVerticalLine: false,
                horizontalInterval: interval,
                getDrawingHorizontalLine: (_) =>
                    FlLine(color: grid, strokeWidth: 1),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(),
                rightTitles: const AxisTitles(),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 44,
                    interval: interval,
                    getTitlesWidget: (value, meta) => value == meta.max
                        ? const SizedBox.shrink()
                        : SideTitleWidget(
                            meta: meta,
                            child: Text(
                              compactPeso(value),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: muted,
                              ),
                            ),
                          ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i >= points.length) {
                        return const SizedBox.shrink();
                      }
                      // Long spans: label every other month.
                      if (points.length > 12 && i.isOdd) {
                        return const SizedBox.shrink();
                      }
                      return SideTitleWidget(
                        meta: meta,
                        child: Text(
                          _label(points[i].yearMonth),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: muted,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => theme.colorScheme.inverseSurface,
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  getTooltipItem: (group, _, rod, rodIndex) {
                    final p = points[group.x];
                    return BarTooltipItem(
                      rodIndex == 0
                          ? '${_label(p.yearMonth, year: true)}\n'
                                'Expenses ${formatPeso(p.expensesCents)}\n'
                                'Paid ${formatPeso(p.paidCents)}'
                          : '${_label(p.yearMonth, year: true)}\n'
                                'Income ${formatPeso(p.incomeCents)}\n'
                                'Received ${formatPeso(p.receivedCents)}',
                      theme.textTheme.bodySmall!.copyWith(
                        color: theme.colorScheme.onInverseSurface,
                      ),
                    );
                  },
                ),
              ),
              barGroups: [
                for (final (i, p) in points.indexed)
                  BarChartGroupData(
                    x: i,
                    barsSpace: 2,
                    barRods: [
                      for (final (cents, color) in [
                        (p.expensesCents, expenses),
                        (p.incomeCents, income),
                      ])
                        BarChartRodData(
                          toY: cents / 100,
                          color: color,
                          width: barWidth,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _trendTable(BuildContext context, List<MonthPoint> points) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodySmall?.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    Widget cell(String text, {bool head = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        text,
        textAlign: head ? TextAlign.left : TextAlign.right,
        style: head ? theme.textTheme.labelMedium : style,
      ),
    );
    return Table(
      key: const Key('trend-table-view'),
      columnWidths: const {0: FlexColumnWidth(1.2)},
      children: [
        TableRow(
          children: [
            cell('Month', head: true),
            for (final h in ['Expenses', 'Paid', 'Income', 'Received'])
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  h,
                  textAlign: TextAlign.right,
                  style: theme.textTheme.labelMedium,
                ),
              ),
          ],
        ),
        for (final p in points)
          TableRow(
            children: [
              cell(_label(p.yearMonth, year: true), head: true),
              cell(formatPeso(p.expensesCents)),
              cell(formatPeso(p.paidCents)),
              cell(formatPeso(p.incomeCents)),
              cell(formatPeso(p.receivedCents)),
            ],
          ),
      ],
    );
  }
}

/// A round step (1, 2 or 5 × 10ⁿ) giving about four gridlines up to [max].
double _niceInterval(double max) {
  final raw = max / 4;
  final mag = math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
  for (final step in [1, 2, 5, 10]) {
    if (raw <= step * mag) return step * mag;
  }
  return 10 * mag;
}

// ---------------------------------------------------------- where it goes

class _WhereCard extends StatefulWidget {
  const _WhereCard({required this.data});

  final ChartData data;

  @override
  State<_WhereCard> createState() => _WhereCardState();
}

class _WhereCardState extends State<_WhereCard> {
  bool _byKind = false;
  int? _touched;

  static const _kindLabels = {
    ItemKind.expense: 'Expenses',
    ItemKind.savings: 'Savings',
    ItemKind.debt: 'Debt',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = seriesColors(context);
    final total = widget.data.totalCents;
    // Up to 7 named slices; the rest fold into a neutral "Other".
    final slices = _byKind
        ? [for (final (k, v) in widget.data.byKind) (_kindLabels[k]!, v)]
        : widget.data.topNames(colors.length + 1);
    Color colorOf(int i, String? name) =>
        name == null ? otherColor(context) : colors[i];

    final donut = SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            key: const Key('where-donut'),
            PieChartData(
              startDegreeOffset: -90,
              sectionsSpace: 2,
              centerSpaceRadius: 64,
              pieTouchData: PieTouchData(
                touchCallback: (event, response) => setState(() {
                  _touched = event.isInterestedForInteractions
                      ? response?.touchedSection?.touchedSectionIndex
                      : null;
                }),
              ),
              sections: [
                for (final (i, (name, cents)) in slices.indexed)
                  PieChartSectionData(
                    value: cents.toDouble(),
                    color: colorOf(i, name),
                    radius: i == _touched ? 34 : 28,
                    showTitle: false,
                  ),
              ],
            ),
          ),
          // The hovered slice, or the total.
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                switch (_touched) {
                  final t? when t >= 0 && t < slices.length =>
                    slices[t].$1 ?? 'Other',
                  _ => 'Total',
                },
                style: theme.textTheme.labelMedium,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                formatPeso(switch (_touched) {
                  final t? when t >= 0 && t < slices.length => slices[t].$2,
                  _ => total,
                }),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    final legend = Column(
      key: const Key('where-legend'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, (name, cents)) in slices.indexed)
          MouseRegion(
            onEnter: (_) => setState(() => _touched = i),
            onExit: (_) => setState(() => _touched = null),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: colorOf(i, name),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      name ?? 'Other',
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: i == _touched ? FontWeight.w600 : null,
                      ),
                    ),
                  ),
                  Text(
                    formatPeso(cents),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  SizedBox(
                    width: 44,
                    child: Text(
                      _percent(cents, total),
                      textAlign: TextAlign.right,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );

    return _ChartCard(
      key: const Key('chart-where'),
      title: 'Where the money goes',
      subtitle: _byKind ? 'By kind' : 'Biggest expenses',
      trailing: SegmentedButton<bool>(
        key: const Key('where-mode'),
        showSelectedIcon: false,
        style: const ButtonStyle(visualDensity: VisualDensity.compact),
        segments: const [
          ButtonSegment(value: false, label: Text('Expense')),
          ButtonSegment(value: true, label: Text('Kind')),
        ],
        selected: {_byKind},
        onSelectionChanged: (s) => setState(() {
          _byKind = s.first;
          _touched = null;
        }),
      ),
      child: LayoutBuilder(
        builder: (context, c) => c.maxWidth < 520
            ? Column(children: [donut, const SizedBox(height: 12), legend])
            : Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  donut,
                  const SizedBox(width: 24),
                  Expanded(child: legend),
                ],
              ),
      ),
    );
  }
}

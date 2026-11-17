import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

import '../../../app/app.dart' show appTheme;
import '../../../app/providers.dart';
import '../../../core/db/database.dart';
import '../../../core/ui/adaptive.dart';
import '../domain/sheet_model.dart';
import 'sheet_style.dart';

/// Blank rows shown below the data so the grid fills the window.
const _minRows = 60;

/// Read-only spreadsheet view of a month. Route: `/overview/:yearMonth`.
/// Selecting a cell shows its value (or payment date) in the fx bar.
class OverviewPage extends ConsumerWidget {
  const OverviewPage({super.key, required this.yearMonth});

  final String yearMonth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(monthProvider(yearMonth));
    // The spreadsheet always uses the light look, like Google Sheets.
    return Theme(
      data: appTheme,
      child: Scaffold(
        backgroundColor: SheetStyle.background,
        appBar: AppBar(
          backgroundColor: SheetStyle.chrome,
          title: MonthSwitcher(
            yearMonth: yearMonth,
            onChanged: (ym) => context.go('/overview/$ym'),
          ),
          centerTitle: true,
        ),
        body: switch (month) {
          AsyncData(:final value) => _OverviewGrid(
            key: ValueKey(value.id),
            month: value,
          ),
          AsyncError(:final error) => Center(child: Text('Error: $error')),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}

class _OverviewGrid extends ConsumerStatefulWidget {
  const _OverviewGrid({super.key, required this.month});

  final Month month;

  @override
  ConsumerState<_OverviewGrid> createState() => _OverviewGridState();
}

class _OverviewGridState extends ConsumerState<_OverviewGrid> {
  final _focus = FocusNode(debugLabel: 'overview-grid');
  (int row, int column)? _selected;

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(itemsProvider(widget.month.id));
    final incomes = ref.watch(incomesProvider(widget.month.id));
    final topUps = ref.watch(topUpsProvider(widget.month.id));
    final accounts = ref.watch(accountsProvider);
    final error =
        items.error ?? incomes.error ?? topUps.error ?? accounts.error;
    if (error != null) return Center(child: Text('Error: $error'));
    if (!items.hasValue ||
        !incomes.hasValue ||
        !topUps.hasValue ||
        !accounts.hasValue) {
      return const Center(child: CircularProgressIndicator());
    }
    final model = buildSheet(
      accounts: accounts.requireValue,
      items: items.requireValue,
      incomes: incomes.requireValue,
      topUps: topUps.requireValue,
    );
    return Column(
      children: [
        _formulaBar(model),
        const Divider(height: 1, color: SheetStyle.grid),
        Expanded(child: _grid(model)),
      ],
    );
  }

  Widget _formulaBar(SheetModel model) {
    final sel = _selected;
    final cell = sel == null ? null : model.cell(sel.$1, sel.$2);
    final ref = sel == null
        ? ''
        : '${SheetStyle.columnLetter(sel.$2)}${sel.$1 + 1}';
    final content = switch (cell) {
      null => '',
      SheetCell(kind: CellKind.checkbox) =>
        cell.tooltip ?? (cell.checked ? 'Paid' : 'Not paid'),
      _ => cell.display,
    };
    return Container(
      height: 30,
      color: SheetStyle.background,
      child: Row(
        children: [
          Container(
            width: 90,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              border: Border(right: BorderSide(color: SheetStyle.grid)),
            ),
            child: Text(ref, key: const Key('name-box')),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              'fx',
              style: TextStyle(
                color: SheetStyle.muted,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          Expanded(
            child: Text(
              content,
              key: const Key('formula-content'),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _grid(SheetModel model) {
    final rows = model.rowCount < _minRows ? _minRows : model.rowCount;
    return Focus(
      focusNode: _focus,
      autofocus: true,
      onKeyEvent: (_, event) {
        if (event is KeyUpEvent) return KeyEventResult.ignored;
        final (dr, dc) = switch (event.logicalKey) {
          LogicalKeyboardKey.arrowDown => (1, 0),
          LogicalKeyboardKey.arrowUp => (-1, 0),
          LogicalKeyboardKey.arrowRight => (0, 1),
          LogicalKeyboardKey.arrowLeft => (0, -1),
          _ => (0, 0),
        };
        if (dr == 0 && dc == 0) return KeyEventResult.ignored;
        final (r, c) = _selected ?? (0, 0);
        setState(() {
          _selected = (
            (r + dr).clamp(0, rows - 1),
            (c + dc).clamp(0, model.columnCount - 1),
          );
        });
        return KeyEventResult.handled;
      },
      child: TableView.builder(
        pinnedRowCount: 1,
        pinnedColumnCount: 1,
        rowCount: rows + 1,
        columnCount: model.columnCount + 1,
        columnBuilder: (i) => TableSpan(
          extent: FixedTableSpanExtent(
            i == 0 ? SheetStyle.rowNumberWidth : model.columns[i - 1].width,
          ),
        ),
        rowBuilder: (i) => TableSpan(
          extent: FixedTableSpanExtent(
            i == 0 ? SheetStyle.letterRowHeight : SheetStyle.rowHeight,
          ),
        ),
        cellBuilder: (context, v) {
          if (v.row == 0 && v.column == 0) {
            return const TableViewCell(child: _ChromeCell(''));
          }
          if (v.row == 0) {
            return TableViewCell(
              child: _ChromeCell(
                SheetStyle.columnLetter(v.column - 1),
                active: _selected?.$2 == v.column - 1,
              ),
            );
          }
          if (v.column == 0) {
            return TableViewCell(
              child: _ChromeCell(
                '${v.row}',
                active: _selected?.$1 == v.row - 1,
              ),
            );
          }
          return TableViewCell(child: _cell(model, v.row - 1, v.column - 1));
        },
      ),
    );
  }

  Widget _cell(SheetModel model, int row, int col) {
    final cell = model.cell(row, col);
    final selected = _selected == (row, col);
    final block = cell.block == null ? null : model.blocks[cell.block!];
    final isHeaderRow = row == 0 && block != null;
    final tinted =
        block != null && (isHeaderRow || cell.kind == CellKind.header);

    Widget content;
    if (cell.kind == CellKind.checkbox) {
      content = Icon(
        cell.checked ? Icons.check_box : Icons.check_box_outline_blank,
        size: 18,
        color: cell.checked ? SheetStyle.selection : SheetStyle.muted,
      );
    } else {
      content = Text(
        cell.display,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: SheetStyle.fontSize,
          color: switch (cell.tone) {
            CellTone.muted => SheetStyle.muted,
            CellTone.negative => SheetStyle.negative,
            CellTone.normal => SheetStyle.text,
          },
          fontWeight: cell.bold ? FontWeight.w600 : FontWeight.normal,
          fontFeatures: cell.isMoney
              ? const [FontFeature.tabularFigures()]
              : null,
        ),
      );
    }
    if (cell.tooltip != null) {
      content = Tooltip(
        message: cell.tooltip!,
        waitDuration: const Duration(milliseconds: 400),
        child: content,
      );
    }

    return GestureDetector(
      key: ValueKey('cell-$row-$col'),
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(() => _selected = (row, col));
        _focus.requestFocus();
      },
      child: Container(
        decoration: BoxDecoration(
          color: selected
              ? SheetStyle.selectionFill
              : tinted
              ? SheetStyle.headerTint(block, cell.block!)
              : SheetStyle.background,
          border: Border(
            left: model.columns[col].startsBlock && col > 0
                ? const BorderSide(color: SheetStyle.blockEdge, width: 1.5)
                : BorderSide.none,
            right: const BorderSide(color: SheetStyle.grid),
            bottom: BorderSide(
              color: isHeaderRow ? SheetStyle.blockEdge : SheetStyle.grid,
              width: isHeaderRow ? 1.5 : 1,
            ),
          ),
        ),
        foregroundDecoration: selected
            ? BoxDecoration(
                border: Border.all(color: SheetStyle.selection, width: 2),
              )
            : null,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        alignment: switch (cell.kind) {
          CellKind.checkbox => Alignment.center,
          CellKind.money => Alignment.centerRight,
          _ => Alignment.centerLeft,
        },
        child: content,
      ),
    );
  }
}

class _ChromeCell extends StatelessWidget {
  const _ChromeCell(this.label, {this.active = false});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) => Container(
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: active ? const Color(0xFFD3E3FD) : SheetStyle.chrome,
      border: const Border(
        right: BorderSide(color: Color(0xFFC4C7C5)),
        bottom: BorderSide(color: Color(0xFFC4C7C5)),
      ),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 11,
        color: SheetStyle.chromeText,
        fontWeight: active ? FontWeight.w600 : FontWeight.normal,
      ),
    ),
  );
}

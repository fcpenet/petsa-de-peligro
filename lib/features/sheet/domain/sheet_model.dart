/// Lays out a month as a spreadsheet grid, mirroring the original Google
/// Sheet: a summary column, an income block and one block per account. A
/// collection (like "Misc") is listed in its account with its sub-expenses
/// underneath.
///
/// Pure: data in, cells out. The Overview page renders it read-only; entries
/// are added and edited through forms on the Budget page.
library;

import '../../../core/db/database.dart';
import '../../../core/money.dart';
import '../../budget/domain/budget_calculator.dart';

enum CellKind { blank, header, label, text, money, checkbox, account }

enum CellTone { normal, muted, negative }

/// What a cell edits or triggers.
enum CellField {
  none,
  itemName,
  itemAmount,
  itemStatus,
  itemAccount,
  incomeName,
  incomeAmount,
  incomeReceived,
}

const _editableFields = {
  CellField.itemName,
  CellField.itemAmount,
  CellField.incomeName,
  CellField.incomeAmount,
};

const _moneyFields = {CellField.itemAmount, CellField.incomeAmount};

class SheetCell {
  const SheetCell({
    this.kind = CellKind.blank,
    this.text,
    this.cents,
    this.checked = false,
    this.field = CellField.none,
    this.itemId,
    this.incomeId,
    this.accountId,
    this.bold = false,
    this.tone = CellTone.normal,
    this.tooltip,
    this.block,
  });

  static const blank = SheetCell();

  final CellKind kind;
  final String? text;
  final int? cents;
  final bool checked;
  final CellField field;
  final String? itemId;
  final String? incomeId;

  /// For account cells: the selected account. For add-item actions: the
  /// account the new item goes into.
  final String? accountId;
  final bool bold;
  final CellTone tone;
  final String? tooltip;

  /// Index into [SheetModel.blocks], or null for padding cells.
  final int? block;

  bool get isEditable => _editableFields.contains(field);
  bool get isMoney => _moneyFields.contains(field) || kind == CellKind.money;

  /// What the cell shows.
  String get display => switch (kind) {
    CellKind.money => cents == null ? '' : formatPeso(cents!),
    CellKind.checkbox => '',
    _ => text ?? '',
  };

  /// Text placed in the editor when the cell is edited.
  String get editText {
    if (!isMoney) return text ?? '';
    final c = cents ?? 0;
    final pesos = c ~/ 100;
    final centavos = c % 100;
    return centavos == 0
        ? '$pesos'
        : '$pesos.${centavos.toString().padLeft(2, '0')}';
  }
}

enum BlockKind { summary, income, account }

class SheetBlock {
  const SheetBlock({
    required this.kind,
    required this.title,
    required this.firstColumn,
    required this.columnCount,
    this.accountId,
    this.itemId,
  });

  final BlockKind kind;
  final String title;
  final int firstColumn;
  final int columnCount;
  final String? accountId;
  final String? itemId;
}

class SheetColumn {
  const SheetColumn(this.width, {this.startsBlock = false});
  final double width;
  final bool startsBlock;
}

class SheetModel {
  SheetModel(this.columns, this.blocks, List<List<SheetCell>> blockColumns)
    : rowCount =
          blockColumns.fold(0, (m, c) => c.length > m ? c.length : m) + 1,
      _columns = blockColumns;

  final List<SheetColumn> columns;
  final List<SheetBlock> blocks;
  final int rowCount;

  /// Cells stored column-major: `_columns[column][row]`.
  final List<List<SheetCell>> _columns;

  int get columnCount => columns.length;

  SheetCell cell(int row, int column) {
    final col = _columns[column];
    return row < col.length ? col[row] : SheetCell.blank;
  }

  /// Finds the first cell matching [test], e.g. to select a new item.
  (int row, int column)? find(bool Function(SheetCell cell) test) {
    for (var c = 0; c < _columns.length; c++) {
      for (var r = 0; r < _columns[c].length; r++) {
        if (test(_columns[c][r])) return (r, c);
      }
    }
    return null;
  }
}

SheetModel buildSheet({
  required List<Account> accounts,
  required List<BudgetItem> items,
  required List<Income> incomes,
  List<TopUp> topUps = const [],
  List<Transfer> transfers = const [],
}) {
  final live = items.where((i) => i.deletedAt == null).toList();
  final liveIncomes = incomes.where((i) => i.deletedAt == null).toList();
  final totals = computeMonthTotals(
    items: live,
    incomes: liveIncomes,
    topUps: topUps,
    transfers: transfers,
  );
  final accountName = {for (final a in accounts) a.id: a.name};

  // Archived accounts only appear when this month still uses them.
  final usedAccounts = {for (final i in live) i.accountId};
  final shownAccounts = [
    for (final a in accounts)
      if (!a.archived || usedAccounts.contains(a.id)) a,
  ];

  final columns = <SheetColumn>[];
  final blocks = <SheetBlock>[];
  final cells = <List<SheetCell>>[];

  void addBlock(
    BlockKind kind,
    String title,
    List<double> widths,
    List<List<SheetCell>> blockColumns, {
    String? accountId,
    String? itemId,
  }) {
    blocks.add(
      SheetBlock(
        kind: kind,
        title: title,
        firstColumn: columns.length,
        columnCount: widths.length,
        accountId: accountId,
        itemId: itemId,
      ),
    );
    for (final (i, w) in widths.indexed) {
      columns.add(SheetColumn(w, startsBlock: i == 0));
    }
    cells.addAll(blockColumns);
  }

  // ---------------------------------------------------------------- summary
  {
    final b = blocks.length;
    final labels = <SheetCell>[];
    final values = <SheetCell>[];
    void row(
      String label,
      int? cents, {
      bool bold = false,
      bool header = false,
    }) {
      labels.add(
        SheetCell(
          kind: header ? CellKind.header : CellKind.label,
          text: label,
          bold: bold || header,
          block: b,
        ),
      );
      values.add(
        header
            ? SheetCell(kind: CellKind.header, block: b)
            : SheetCell(
                kind: CellKind.money,
                cents: cents,
                bold: bold,
                tone: cents == null
                    ? CellTone.normal
                    : cents < 0
                    ? CellTone.negative
                    : cents == 0
                    ? CellTone.muted
                    : CellTone.normal,
                block: b,
              ),
      );
    }

    void spacer() {
      labels.add(SheetCell(block: b));
      values.add(SheetCell(block: b));
    }

    row('Summary', null, header: true);
    row('Total salary', totals.incomeCents);
    row('Salary received', totals.receivedCents);
    row('Total expenses', totals.allottedCents);
    row('Unbudgeted', totals.unbudgetedCents, bold: true);
    row('Paid so far', totals.paidCents);
    row('To allot', totals.plannedCents);
    spacer();
    row('Left to pay', null, header: true);
    for (final a in shownAccounts) {
      row(a.name, totals.byAccount[a.id]?.remainingCents ?? 0);
    }
    if (totals.byAccount.containsKey(null)) {
      row('No account', totals.byAccount[null]!.remainingCents);
    }
    row('Remaining total', totals.remainingCents, bold: true);
    if (totals.slackCents > 0) {
      row('Unused collection budget', totals.slackCents);
    }
    // Expenses paid from another account than planned leave money to move.
    if (totals.suggestedTransfers case final moves when moves.isNotEmpty) {
      spacer();
      row('Rebalance', null, header: true);
      for (final m in moves) {
        row(
          '${accountName[m.fromAccountId] ?? '?'} → '
          '${accountName[m.toAccountId] ?? '?'}',
          m.amountCents,
        );
      }
    }
    addBlock(BlockKind.summary, 'Summary', const [170, 120], [labels, values]);
  }

  // ----------------------------------------------------------------- income
  {
    final b = blocks.length;
    final names = <SheetCell>[
      SheetCell(kind: CellKind.header, text: 'Income', bold: true, block: b),
    ];
    final amounts = <SheetCell>[
      SheetCell(
        kind: CellKind.money,
        cents: totals.incomeCents,
        bold: true,
        tooltip: 'Expected',
        block: b,
      ),
    ];
    final received = <SheetCell>[
      SheetCell(
        kind: CellKind.money,
        cents: totals.receivedCents,
        bold: true,
        tooltip: 'Received',
        block: b,
      ),
    ];
    for (final income in liveIncomes) {
      names.add(
        SheetCell(
          kind: CellKind.text,
          text: income.name,
          field: CellField.incomeName,
          incomeId: income.id,
          block: b,
        ),
      );
      amounts.add(
        SheetCell(
          kind: CellKind.money,
          cents: income.amountCents,
          field: CellField.incomeAmount,
          incomeId: income.id,
          block: b,
        ),
      );
      final got = totals.receivedByIncome[income.id] ?? 0;
      received.add(
        SheetCell(
          kind: CellKind.money,
          cents: got,
          field: CellField.incomeReceived,
          incomeId: income.id,
          tone: got < income.amountCents ? CellTone.muted : CellTone.normal,
          tooltip:
              'Received ${formatPeso(got)} of '
              '${formatPeso(income.amountCents)}',
          block: b,
        ),
      );
    }
    addBlock(
      BlockKind.income,
      'Income',
      const [150, 110, 110],
      [names, amounts, received],
    );
  }

  // --------------------------------------------------------------- accounts
  // Each account lists its expenses; a collection is followed by its
  // sub-expenses (marked ↳, with their account when it differs).
  /// With a null [accountId], [collections] picks account-less collections
  /// (the "Collections" block) or other account-less expenses.
  void accountBlock(
    String title,
    String? accountId, {
    bool collections = false,
  }) {
    final b = blocks.length;
    final rows = [
      for (final i in live)
        if (i.parentId == null &&
            i.accountId == accountId &&
            (accountId != null || i.isCollection == collections))
          i,
    ];
    if (rows.isEmpty && accountId == null) return;
    final childrenOf = <String, List<BudgetItem>>{
      for (final r in rows)
        if (r.isCollection)
          r.id: [
            for (final c in live)
              if (c.parentId == r.id) c,
          ],
    };
    final total = rows.fold(
      0,
      (s, i) =>
          s + (totals.byParent[i.id]?.effectiveAllottedCents ?? i.amountCents),
    );
    final leaves = [
      for (final r in rows) ...childrenOf[r.id] ?? [r],
    ];
    final unpaid = leaves
        .where((i) => i.status != ItemStatus.paid)
        .fold(0, (s, i) => s + i.amountCents);

    final names = <SheetCell>[
      SheetCell(
        kind: CellKind.header,
        text: title,
        bold: true,
        accountId: accountId,
        block: b,
      ),
    ];
    final amounts = <SheetCell>[
      SheetCell(kind: CellKind.money, cents: total, bold: true, block: b),
    ];
    final paid = <SheetCell>[
      SheetCell(kind: CellKind.header, text: 'Paid?', bold: true, block: b),
    ];
    for (final item in rows) {
      final children = childrenOf[item.id];
      if (children == null) {
        names.add(_itemName(item, b));
        amounts.add(_itemAmount(item, b));
        paid.add(
          _itemCheckbox(item, b, paidFrom: accountName[item.paidFromAccountId]),
        );
        continue;
      }
      final parentTotals = totals.byParent[item.id];
      names.add(_itemName(item, b, bold: true));
      amounts.add(_itemAmount(item, b, tooltip: 'Budget', bold: true));
      paid.add(_itemCheckbox(item, b, children: parentTotals));
      for (final child in children) {
        final from = child.accountId == null || child.accountId == accountId
            ? ''
            : ' · ${accountName[child.accountId] ?? '?'}';
        names.add(_itemName(child, b, text: '↳ ${child.name}$from'));
        amounts.add(_itemAmount(child, b));
        paid.add(
          _itemCheckbox(
            child,
            b,
            paidFrom: accountName[child.paidFromAccountId],
          ),
        );
      }
      final left = parentTotals?.leftCents ?? item.amountCents;
      names.add(
        SheetCell(
          kind: CellKind.label,
          text: '↳ left in ${item.name}',
          block: b,
        ),
      );
      amounts.add(
        SheetCell(
          kind: CellKind.money,
          cents: left,
          tone: left < 0 ? CellTone.negative : CellTone.muted,
          block: b,
        ),
      );
      paid.add(SheetCell(block: b));
    }
    names.add(SheetCell(kind: CellKind.label, text: 'Left to pay', block: b));
    amounts.add(
      SheetCell(
        kind: CellKind.money,
        cents: unpaid,
        tone: unpaid == 0 ? CellTone.muted : CellTone.normal,
        block: b,
      ),
    );
    paid.add(SheetCell(block: b));

    addBlock(
      BlockKind.account,
      title,
      const [190, 105, 62],
      [names, amounts, paid],
      accountId: accountId,
    );
  }

  for (final account in shownAccounts) {
    accountBlock(account.name, account.id);
  }
  // Collections without an account; their sub-expenses count toward their
  // own accounts.
  accountBlock('Collections', null, collections: true);
  // Anything else without an account (old data) until one is chosen.
  accountBlock('No account', null);

  return SheetModel(columns, blocks, cells);
}

SheetCell _itemName(
  BudgetItem item,
  int block, {
  String? text,
  bool bold = false,
}) => SheetCell(
  kind: CellKind.text,
  text: text ?? item.name,
  bold: bold,
  field: CellField.itemName,
  itemId: item.id,
  block: block,
);

SheetCell _itemAmount(
  BudgetItem item,
  int block, {
  String? tooltip,
  bool bold = false,
}) => SheetCell(
  kind: CellKind.money,
  cents: item.amountCents,
  bold: bold,
  tooltip: tooltip,
  field: CellField.itemAmount,
  itemId: item.id,
  block: block,
);

SheetCell _itemCheckbox(
  BudgetItem item,
  int block, {
  ParentTotals? children,
  String? paidFrom,
}) => SheetCell(
  kind: CellKind.checkbox,
  checked: item.status == ItemStatus.paid,
  field: CellField.itemStatus,
  itemId: item.id,
  tooltip: _paidTooltip(item, children: children, paidFrom: paidFrom),
  block: block,
);

const _months = [
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

String _formatShortDate(DateTime d) =>
    '${_months[d.month - 1]} ${d.day}, ${d.year}';

String? _paidTooltip(
  BudgetItem item, {
  ParentTotals? children,
  String? paidFrom,
}) {
  final progress = children == null
      ? ''
      : ' · ${children.paidCount}/${children.childCount} paid';
  if (item.status == ItemStatus.paid && item.paidAt != null) {
    final from = paidFrom == null ? '' : ' from $paidFrom';
    return 'Paid ${_formatShortDate(item.paidAt!)}$from$progress';
  }
  final label = item.status == ItemStatus.planned ? 'Planned' : 'Allotted';
  return '$label$progress';
}

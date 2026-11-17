import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:petsa/core/db/database.dart';
import 'package:petsa/features/accounts/data/account_repository.dart';
import 'package:petsa/features/budget/data/budget_repository.dart';
import 'package:petsa/features/sheet/domain/sheet_model.dart';
import 'package:petsa/features/sheet/ui/sheet_style.dart';

import '../../helpers/november.dart';
import '../../helpers/test_db.dart';

void main() {
  late AppDatabase db;
  late NovemberIds ids;
  late SheetModel model;

  Future<SheetModel> build() async {
    final repo = BudgetRepository(db);
    return buildSheet(
      accounts: await AccountRepository(db).accounts(includeArchived: true),
      items: await repo.itemsFor(ids.monthId),
      incomes: await repo.incomesFor(ids.monthId),
    );
  }

  setUp(() async {
    db = createTestDatabase();
    ids = await seedNovember(db);
    model = await build();
  });

  tearDown(() => db.close());

  SheetBlock block(String title) =>
      model.blocks.firstWhere((b) => b.title == title);

  /// Column [offset] of [block], as cells top to bottom.
  List<SheetCell> column(SheetBlock block, int offset) => [
    for (var r = 0; r < model.rowCount; r++)
      model.cell(r, block.firstColumn + offset),
  ];

  List<String> texts(SheetBlock block, int offset) => [
    for (final c in column(block, offset))
      if (c.display.isNotEmpty) c.display,
  ];

  test('blocks follow the sheet: summary, income, accounts', () {
    expect(model.blocks.map((b) => b.title), [
      'Summary',
      'Income',
      'Cash',
      'UB',
      'RCBC Card',
      'BPI',
      'JCB',
    ]);
    expect(model.blocks.map((b) => b.columnCount), [2, 3, 3, 3, 3, 3, 3]);
    expect(model.columnCount, 20);
  });

  test('each block starts with a thick edge', () {
    for (final b in model.blocks) {
      expect(model.columns[b.firstColumn].startsBlock, isTrue);
      for (var i = 1; i < b.columnCount; i++) {
        expect(model.columns[b.firstColumn + i].startsBlock, isFalse);
      }
    }
  });

  test('summary shows salary, totals and per-account left to pay', () {
    final summary = block('Summary');
    final labels = column(summary, 0);
    final values = column(summary, 1);
    int? valueOf(String label) =>
        values[labels.indexWhere((c) => c.text == label)].cents;

    expect(valueOf('Total salary'), php(242122.23));
    // 8000+7000+2000+3000+6000+25000+280 + Misc cap 2200
    expect(valueOf('Total expenses'), php(53480));
    expect(valueOf('Unallotted'), php(242122.23 - 53480));
    expect(valueOf('UB'), php(9000));
    expect(valueOf('RCBC Card'), php(6000));
    expect(valueOf('BPI'), php(280));
    // Misc's unpaid sleeve is charged to Cash.
    expect(valueOf('Cash'), php(296.26));
    expect(valueOf('JCB'), 0);
    expect(valueOf('Remaining total'), php(15576.26));
    expect(valueOf('Unused collection budget'), php(2200 - 845.26));
  });

  test('zero and negative amounts get muted / negative tones', () {
    final summary = block('Summary');
    final labels = column(summary, 0);
    final values = column(summary, 1);
    expect(
      values[labels.indexWhere((c) => c.text == 'JCB')].tone,
      CellTone.muted,
    );
  });

  test('account block lists its items with amounts and paid boxes', () {
    final ub = block('UB');
    expect(texts(ub, 0), ['UB', 'UB Loan', 'Pru', 'Left to pay']);
    expect(texts(ub, 1), ['₱9,000.00', '₱7,000.00', '₱2,000.00', '₱9,000.00']);
    expect(column(ub, 2)[0].text, 'Paid?');

    final rcbc = column(block('RCBC Card'), 2);
    expect(rcbc[1].checked, isTrue); // Cats
    expect(rcbc[2].checked, isFalse); // Electric
    expect(rcbc[1].tooltip, startsWith('Paid '));
  });

  test('account item cells carry what they show', () {
    final ub = block('UB');
    final name = column(ub, 0)[1];
    expect(name.field, CellField.itemName);
    expect(name.itemId, ids.items['UB Loan']);
    expect(name.isEditable, isTrue);
    expect(column(ub, 1)[1].editText, '7000');
  });

  test('a collection sits in its account with its sub-expenses below', () {
    final cash = block('Cash');
    expect(texts(cash, 0), [
      'Cash',
      'Basic',
      'Misc',
      '↳ dental pliers · JCB', // paid from another account
      '↳ sleeve', // same account as Misc
      '↳ left in Misc',
      'Left to pay',
    ]);
    final amounts = column(cash, 1);
    // Basic 8000 + Misc's budget.
    expect(amounts[0].cents, php(8000 + 2200));
    expect(amounts[2].cents, php(2200));
    expect(amounts[2].tooltip, 'Budget');
    expect(amounts[2].field, CellField.itemAmount);
    expect(amounts[5].cents, php(2200 - 845.26));
    // Unpaid here: only the sleeve (Basic and dental pliers are paid).
    expect(amounts[6].cents, php(296.26));
    expect(amounts[4].editText, '296.26');

    final boxes = column(cash, 2);
    expect(boxes[2].field, CellField.itemStatus);
    expect(boxes[2].itemId, ids.misc);
    expect(boxes[2].checked, isFalse);
    expect(boxes[2].tooltip, 'Not paid · 1/2 paid');
    expect(boxes[3].checked, isTrue);
  });

  test('over-budget collections show a negative left amount', () async {
    await BudgetRepository(db).updateItem(ids.misc, amountCents: php(500));
    model = await build();
    final left = column(block('Cash'), 1)[5];
    expect(left.cents, php(500 - 845.26));
    expect(left.tone, CellTone.negative);
  });

  test('expenses without an account get their own block', () async {
    final repo = BudgetRepository(db);
    await repo.updateItem(ids.misc, accountId: const Value(null));
    model = await build();
    expect(model.blocks.last.title, 'No account');
    expect(texts(model.blocks.last, 0), contains('Misc'));
    expect(texts(block('Cash'), 0), isNot(contains('Misc')));
  });

  test('income block lists incomes', () {
    final income = block('Income');
    expect(texts(income, 0), ['Income', 'Salary']);
    expect(column(income, 1)[1].field, CellField.incomeAmount);
  });

  test('archived accounts are hidden unless this month uses them', () async {
    final accounts = AccountRepository(db);
    final spare = await accounts.createAccount(
      name: 'Old card',
      type: AccountType.creditCard,
    );
    await accounts.setArchived(spare, archived: true);
    await accounts.setArchived(ids.accounts['JCB']!, archived: true);
    model = await build();
    final titles = model.blocks.map((b) => b.title);
    expect(titles, isNot(contains('Old card')));
    expect(titles, contains('JCB')); // dental pliers is charged to it
  });

  test('rowCount covers the tallest block plus a spare row', () {
    final tallest = model.blocks
        .map(
          (b) => column(b, 0).lastIndexWhere((c) => c.kind != CellKind.blank),
        )
        .reduce((a, b) => a > b ? a : b);
    expect(model.rowCount, tallest + 2);
    expect(model.cell(model.rowCount + 5, 0).kind, CellKind.blank);
  });

  test('find locates a cell', () {
    final pos = model.find(
      (c) => c.itemId == ids.items['Pru'] && c.field == CellField.itemName,
    );
    expect(pos, (2, block('UB').firstColumn));
  });

  test('column letters', () {
    expect(SheetStyle.columnLetter(0), 'A');
    expect(SheetStyle.columnLetter(25), 'Z');
    expect(SheetStyle.columnLetter(26), 'AA');
    expect(SheetStyle.columnLetter(51), 'AZ');
    expect(SheetStyle.columnLetter(52), 'BA');
  });
}

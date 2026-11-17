import 'package:petsa/core/db/database.dart';
import 'package:petsa/features/accounts/data/account_repository.dart';
import 'package:petsa/features/budget/data/budget_repository.dart';

import 'units.dart';

/// Ids created by [seedNovember], for assertions.
class NovemberIds {
  late String monthId;
  final accounts = <String, String>{};
  final items = <String, String>{};
  late String misc;
  late String salary;
}

/// Seeds a trimmed version of the November 2026 spreadsheet.
Future<NovemberIds> seedNovember(AppDatabase db) async {
  final repo = BudgetRepository(db, clock: () => DateTime(2026, 11, 15, 9));
  final accounts = AccountRepository(db);
  final ids = NovemberIds();
  ids.monthId = (await repo.ensureMonth('2026-11')).id;

  for (final (i, (name, type)) in [
    ('Cash', AccountType.cash),
    ('UB', AccountType.bank),
    ('RCBC Card', AccountType.creditCard),
    ('BPI', AccountType.bank),
    ('JCB', AccountType.creditCard),
  ].indexed) {
    ids.accounts[name] = await accounts.createAccount(
      name: name,
      type: type,
      sortOrder: i,
    );
  }

  ids.salary = await repo.addIncome(
    monthId: ids.monthId,
    name: 'Salary',
    amountCents: php(242122.23),
  );

  var order = 0;
  Future<void> add(
    String name,
    num pesos,
    String account, {
    bool paid = false,
  }) async {
    final id = await repo.addItem(
      monthId: ids.monthId,
      name: name,
      amountCents: php(pesos),
      accountId: ids.accounts[account],
      sortOrder: order++,
    );
    ids.items[name] = id;
    if (paid) await repo.setStatus(id, ItemStatus.paid);
  }

  await add('Basic', 8000, 'Cash', paid: true);
  await add('UB Loan', 7000, 'UB');
  await add('Pru', 2000, 'UB');
  await add('Cats', 3000, 'RCBC Card', paid: true);
  await add('Electric', 6000, 'RCBC Card');
  await add('Rent', 25000, 'BPI', paid: true);
  await add('QR', 280, 'BPI');

  // A collection in Cash whose sub-expenses are paid from different accounts.
  ids.misc = await repo.addItem(
    monthId: ids.monthId,
    name: 'Misc',
    amountCents: php(2200),
    accountId: ids.accounts['Cash'],
    isCollection: true,
    sortOrder: order++,
  );
  for (final (name, pesos, account, paid) in [
    ('dental pliers', 549, 'JCB', true),
    ('sleeve', 296.26, 'Cash', false),
  ]) {
    final id = await repo.addItem(
      monthId: ids.monthId,
      name: name,
      amountCents: php(pesos),
      accountId: ids.accounts[account],
      parentId: ids.misc,
      sortOrder: order++,
    );
    ids.items[name] = id;
    if (paid) await repo.setStatus(id, ItemStatus.paid);
  }
  return ids;
}

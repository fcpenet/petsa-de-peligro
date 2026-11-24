import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petsa/core/db/database.dart';
import 'package:petsa/features/accounts/data/account_repository.dart';
import 'package:petsa/features/budget/data/budget_repository.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

import '../../helpers/legacy_schema.dart';
import '../../helpers/units.dart';

void main() {
  test('version 3 groups become collections', () async {
    final dir = Directory.systemTemp.createTempSync('petsa-v3');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/petsa.db');

    // Build the v3 shape: a group (top-level, no account) with a child, an
    // empty group, and a plain item.
    final seed = AppDatabase(NativeDatabase(file));
    final repo = BudgetRepository(seed);
    final month = (await repo.ensureMonth('2026-11')).id;
    final cash = await AccountRepository(seed)
        .createAccount(name: 'Cash', type: AccountType.cash);
    final rent = await repo.addItem(
      monthId: month,
      name: 'Rent',
      amountCents: php(100),
      accountId: cash,
    );
    final misc = await repo.addItem(
      monthId: month,
      name: 'Misc',
      amountCents: php(50),
      isCollection: true,
    );
    final child = await repo.addItem(
      monthId: month,
      name: 'pliers',
      amountCents: php(10),
      accountId: cash,
      parentId: misc,
    );
    final gifts = await repo.addItem(
      monthId: month,
      name: 'Gifts',
      amountCents: php(20),
      isCollection: true,
    );
    await seed.close();
    final raw = sqlite.sqlite3.open(file.path)..execute('DROP TABLE transfers');
    dropColumns(raw, 'items', [
      'is_collection',
      'paid_from_account_id',
      'charged_at',
    ]);
    raw
      ..execute('PRAGMA user_version = 3')
      ..close();

    final upgraded = AppDatabase(NativeDatabase(file));
    addTearDown(upgraded.close);
    final items = {
      for (final i in await BudgetRepository(upgraded).itemsFor(month)) i.id: i,
    };
    expect(items[misc]!.isCollection, isTrue);
    expect(items[gifts]!.isCollection, isTrue); // empty groups too
    expect(items[rent]!.isCollection, isFalse);
    expect(items[child]!.isCollection, isFalse);
    // Old groups have no account until the user picks one.
    expect(items[misc]!.accountId, isNull);
  });

  test('version 4 gains paid-from and transfers', () async {
    final dir = Directory.systemTemp.createTempSync('petsa-v4');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/petsa.db');

    final seed = AppDatabase(NativeDatabase(file));
    final repo = BudgetRepository(seed);
    final month = (await repo.ensureMonth('2026-11')).id;
    final accounts = AccountRepository(seed);
    final rcbc = await accounts.createAccount(
      name: 'RCBC',
      type: AccountType.creditCard,
    );
    final ub = await accounts.createAccount(name: 'UB', type: AccountType.bank);
    final electric = await repo.addItem(
      monthId: month,
      name: 'Electric',
      amountCents: php(60),
      accountId: rcbc,
    );
    await repo.setStatus(electric, ItemStatus.paid);
    await seed.close();
    final raw = sqlite.sqlite3.open(file.path)..execute('DROP TABLE transfers');
    dropColumns(raw, 'items', ['paid_from_account_id', 'charged_at']);
    raw
      ..execute('PRAGMA user_version = 4')
      ..close();

    final upgraded = AppDatabase(NativeDatabase(file));
    addTearDown(upgraded.close);
    final r = BudgetRepository(upgraded);
    final item = await r.item(electric);
    expect(item.status, ItemStatus.paid);
    expect(item.paidFromAccountId, isNull);
    expect(item.isCollection, isFalse);
    await r.setStatus(electric, ItemStatus.paid, paidFromAccountId: ub);
    await r.addTransfer(
      monthId: month,
      fromAccountId: rcbc,
      toAccountId: ub,
      amountCents: php(60),
      transferredAt: DateTime(2026, 11, 18),
    );
    expect((await r.totalsFor(month)).balanceByAccount, isEmpty);
  });

  test('version 5 gains the charge date', () async {
    final dir = Directory.systemTemp.createTempSync('petsa-v5');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/petsa.db');

    final seed = AppDatabase(NativeDatabase(file));
    final repo = BudgetRepository(seed);
    final month = (await repo.ensureMonth('2026-11')).id;
    final card = await AccountRepository(seed)
        .createAccount(name: 'JCB', type: AccountType.creditCard);
    final netflix = await repo.addItem(
      monthId: month,
      name: 'Netflix',
      amountCents: 1,
      accountId: card,
    );
    await seed.close();
    final raw = sqlite.sqlite3.open(file.path);
    dropColumns(raw, 'items', ['charged_at']);
    raw
      ..execute('PRAGMA user_version = 5')
      ..close();

    final upgraded = AppDatabase(NativeDatabase(file));
    addTearDown(upgraded.close);
    final r = BudgetRepository(upgraded);
    await r.setStatus(
      netflix,
      ItemStatus.charged,
      chargedAt: DateTime(2026, 11, 9),
    );
    expect((await r.item(netflix)).chargedAt, DateTime(2026, 11, 9));
  });
}

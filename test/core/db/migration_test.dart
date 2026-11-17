import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petsa/core/db/database.dart';
import 'package:petsa/features/accounts/data/account_repository.dart';
import 'package:petsa/features/budget/data/budget_repository.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

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
    final raw = sqlite.sqlite3.open(file.path)
      ..execute('ALTER TABLE items DROP COLUMN is_collection')
      ..execute('PRAGMA user_version = 3');
    raw.close();

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
}

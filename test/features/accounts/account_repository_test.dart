import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:petsa/core/db/database.dart';
import 'package:petsa/features/accounts/data/account_repository.dart';

import '../../helpers/test_db.dart';

void main() {
  late AppDatabase db;
  late AccountRepository repo;

  setUp(() {
    db = createTestDatabase();
    repo = AccountRepository(db);
  });

  tearDown(() => db.close());

  test('creates institutions and accounts linked to them', () async {
    final bpi = await repo.createInstitution(' BPI ');
    final savings = await repo.createAccount(
      name: 'BPI Savings',
      type: AccountType.bank,
      institutionId: bpi,
    );

    final institutions = await repo.institutions();
    expect(institutions.single.name, 'BPI');

    final account = (await repo.accounts()).single;
    expect(account.id, savings);
    expect(account.institutionId, bpi);
    expect(account.type, AccountType.bank);
    expect(account.archived, isFalse);
  });

  test('accounts can exist without an institution (cash)', () async {
    await repo.createAccount(name: 'Cash', type: AccountType.cash);
    expect((await repo.accounts()).single.institutionId, isNull);
  });

  test('orders accounts by sortOrder then name', () async {
    await repo.createAccount(name: 'Zeta', type: AccountType.bank);
    await repo.createAccount(name: 'Alpha', type: AccountType.bank);
    await repo.createAccount(
      name: 'First',
      type: AccountType.cash,
      sortOrder: -1,
    );
    expect((await repo.accounts()).map((a) => a.name), [
      'First',
      'Alpha',
      'Zeta',
    ]);
  });

  test('archived accounts are hidden unless requested', () async {
    final jcb = await repo.createAccount(
      name: 'JCB',
      type: AccountType.creditCard,
    );
    await repo.setArchived(jcb, archived: true);

    expect(await repo.accounts(), isEmpty);
    expect((await repo.accounts(includeArchived: true)).single.id, jcb);

    await repo.setArchived(jcb, archived: false);
    expect((await repo.accounts()).single.id, jcb);
  });

  test('updateAccount renames, retypes and changes the bank', () async {
    final id = await repo.createAccount(name: 'Card', type: AccountType.bank);
    final rcbc = await repo.findOrCreateInstitution('RCBC');
    await repo.updateAccount(
      id,
      name: ' RCBC Card ',
      type: AccountType.creditCard,
      institutionId: Value(rcbc),
    );
    final account = (await repo.accounts()).single;
    expect(account.name, 'RCBC Card');
    expect(account.type, AccountType.creditCard);
    expect(account.institutionId, rcbc);

    await repo.updateAccount(id, institutionId: const Value(null));
    expect((await repo.accounts()).single.institutionId, isNull);
    expect(() => repo.updateAccount(id, name: ' '), throwsArgumentError);
  });

  test('findOrCreateInstitution reuses names ignoring case', () async {
    final a = await repo.findOrCreateInstitution('BPI');
    final b = await repo.findOrCreateInstitution(' bpi ');
    expect(b, a);
    expect((await repo.institutions()).length, 1);
  });

  test('watchAccounts emits on changes', () async {
    final stream = repo.watchAccounts().map((a) => a.length);
    expectLater(stream, emitsInOrder([0, 1]));
    await pumpEventQueue();
    await repo.createAccount(name: 'GCash', type: AccountType.ewallet);
  });

  test('rejects an unknown institution (foreign key)', () async {
    expect(
      repo.createAccount(
        name: 'Ghost',
        type: AccountType.bank,
        institutionId: 'missing',
      ),
      throwsA(anything),
    );
  });
}

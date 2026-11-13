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

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:petsa/core/db/database.dart';
import 'package:petsa/features/accounts/data/account_repository.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/november.dart';
import '../../helpers/test_db.dart';

void main() {
  late AppDatabase db;
  late AccountRepository repo;

  setUp(() {
    db = createTestDatabase();
    repo = AccountRepository(db);
  });

  testWidgets('empty state invites adding accounts', (tester) async {
    await pumpApp(tester, db, location: '/accounts');
    expect(find.textContaining('No accounts yet'), findsOneWidget);
    await closeApp(tester, db);
  });

  testWidgets('add an account with a bank', (tester) async {
    await pumpApp(tester, db, location: '/accounts');
    await tester.tap(find.byKey(const Key('add-account')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('field-name')), 'RCBC Card');
    await choose(tester, 'field-type', 'Credit card');
    await tester.enterText(find.byKey(const Key('field-bank')), 'RCBC');
    await save(tester);

    final account = (await repo.accounts()).single;
    expect(account.name, 'RCBC Card');
    expect(account.type, AccountType.creditCard);
    expect((await repo.institutions()).single.name, 'RCBC');
    expect(find.text('Credit card · RCBC'), findsOneWidget);
    await closeApp(tester, db);
  });

  testWidgets('rename and archive an account', (tester) async {
    final ids = await seedNovember(db);
    await pumpApp(tester, db, location: '/accounts');
    await tester.tap(find.byKey(ValueKey('account-${ids.accounts['JCB']}')));
    await tester.pumpAndSettle();
    expect(find.text('Edit account'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('field-name')), 'JCB Card');
    await tester.tap(find.byKey(const Key('field-archived')));
    await tester.pumpAndSettle();
    await save(tester);

    final jcb = (await repo.accounts(includeArchived: true))
        .singleWhere((a) => a.id == ids.accounts['JCB']);
    expect(jcb.name, 'JCB Card');
    expect(jcb.archived, isTrue);
    expect(find.text('Archived'), findsOneWidget);
    await closeApp(tester, db);
  });
}

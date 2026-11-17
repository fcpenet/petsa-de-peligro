import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:petsa/core/db/database.dart';

import '../helpers/app_harness.dart';
import '../helpers/november.dart';
import '../helpers/test_db.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = createTestDatabase();
    await seedNovember(db);
  });

  testWidgets('desktop uses a side rail', (tester) async {
    await pumpApp(tester, db);
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    await closeApp(tester, db);
  });

  testWidgets('phone uses bottom navigation', (tester) async {
    await pumpApp(tester, db, size: phone);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    await closeApp(tester, db);
  });

  testWidgets('switching to Overview keeps the month', (tester) async {
    final router = await pumpApp(tester, db, location: '/budget/2026-10');
    await tester.tap(find.byKey(const Key('nav-overview')));
    await tester.pumpAndSettle();
    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      '/overview/2026-10',
    );
    expect(find.text('October 2026'), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav-accounts')));
    await tester.pumpAndSettle();
    expect(find.text('Accounts'), findsWidgets);

    await tester.tap(find.byKey(const Key('nav-budget')));
    await tester.pumpAndSettle();
    expect(find.text('November 2026'), findsOneWidget); // current month
    await closeApp(tester, db);
  });

  testWidgets('old month links redirect to the budget page', (tester) async {
    final router = await pumpApp(tester, db, location: '/2026-11');
    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      '/budget/2026-11',
    );
    await closeApp(tester, db);
  });

  testWidgets('invalid months fall back to the current month', (tester) async {
    final router = await pumpApp(tester, db, location: '/budget/2026-13');
    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      '/budget/2026-11',
    );
    await closeApp(tester, db);
  });
}

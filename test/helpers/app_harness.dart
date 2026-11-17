import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:petsa/app/app.dart';
import 'package:petsa/app/providers.dart';
import 'package:petsa/core/db/database.dart';

/// Desktop: wide enough for the side rail, tall enough that every section of
/// the budget list is built.
const desktop = Size(1400, 4000);

/// Phone: bottom navigation and bottom-sheet forms.
const phone = Size(400, 2400);

/// Pumps the whole app (router, shell, pages) on [db] at [size], starting at
/// [location]. Today is pinned to 15 Nov 2026.
Future<GoRouter> pumpApp(
  WidgetTester tester,
  AppDatabase db, {
  Size size = desktop,
  String location = '/budget/2026-11',
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = buildRouter(clock: () => DateTime(2026, 11, 15));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: PetsaApp(router: router),
    ),
  );
  if (location != '/budget/2026-11') router.go(location);
  await tester.pumpAndSettle();
  return router;
}

/// Unmounts the app before closing the database so streams shut down.
Future<void> closeApp(WidgetTester tester, AppDatabase db) async {
  await tester.pumpWidget(const SizedBox());
  await db.close();
}

/// Picks [option] from the dropdown with [fieldKey].
Future<void> choose(WidgetTester tester, String fieldKey, String option) async {
  await tester.tap(find.byKey(Key(fieldKey)));
  await tester.pumpAndSettle();
  await tester.tap(find.text(option).last);
  await tester.pumpAndSettle();
}

Future<void> save(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('form-save')));
  await tester.pumpAndSettle();
}

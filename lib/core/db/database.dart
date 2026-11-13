import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

export 'tables.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Institutions, Accounts, Months, Incomes, Items])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// The on-device database used by the app.
  factory AppDatabase.open() => AppDatabase(driftDatabase(name: 'petsa'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}

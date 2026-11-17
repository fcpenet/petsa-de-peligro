import 'package:drift/drift.dart';

import 'connection.dart';
import 'tables.dart';

export 'tables.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    Institutions,
    Accounts,
    Months,
    Incomes,
    IncomeTopUps,
    Items,
    Transfers,
    Templates,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// Turso when configured at build time, otherwise on-device SQLite.
  factory AppDatabase.open() => AppDatabase(defaultExecutor());

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) await m.createTable(templates);
      if (from < 3) await m.createTable(incomeTopUps);
      if (from < 4) {
        await m.addColumn(items, items.isCollection);
        // Groups (top-level, no account) and anything with sub-expenses
        // become collections.
        await customStatement(
          'UPDATE items SET is_collection = 1 '
          'WHERE (parent_id IS NULL AND account_id IS NULL) '
          'OR id IN (SELECT parent_id FROM items WHERE parent_id IS NOT NULL)',
        );
      }
      if (from < 5) {
        await m.addColumn(items, items.paidFromAccountId);
        await m.createTable(transfers);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}

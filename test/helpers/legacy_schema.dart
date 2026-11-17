import 'package:sqlite3/sqlite3.dart' as sqlite;

/// Rebuilds [table] without [columns], to recreate an older schema in
/// migration tests (SQLite can't drop columns that have a foreign key).
void dropColumns(sqlite.Database raw, String table, List<String> columns) {
  final keep = [
    for (final row in raw.select('PRAGMA table_info($table)'))
      if (!columns.contains(row['name'])) row['name'] as String,
  ].join(', ');
  raw
    ..execute('PRAGMA foreign_keys = OFF')
    ..execute('CREATE TABLE _old_$table AS SELECT $keep FROM $table')
    ..execute('DROP TABLE $table')
    ..execute('ALTER TABLE _old_$table RENAME TO $table');
}

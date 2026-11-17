import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:petsa/core/db/database.dart';

export 'units.dart';

/// A fresh in-memory database per test.
AppDatabase createTestDatabase() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return AppDatabase(
    DatabaseConnection(
      NativeDatabase.memory(),
      closeStreamsSynchronously: true,
    ),
  );
}

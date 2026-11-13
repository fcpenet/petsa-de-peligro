import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:petsa/core/db/database.dart';

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

/// Pesos → centavos, to keep test data readable.
int php(num pesos) => (pesos * 100).round();

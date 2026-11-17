import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'turso/turso_database.dart';

/// Turso connection settings, injected at build time with
/// `--dart-define-from-file=.env.local` (never committed).
const tursoUrl = String.fromEnvironment('TURSO_URL');
const tursoToken = String.fromEnvironment('TURSO_TOKEN');

bool get hasTursoConfig => tursoUrl.isNotEmpty && tursoToken.isNotEmpty;

/// Uses Turso when configured, otherwise the on-device SQLite database.
QueryExecutor defaultExecutor() {
  if (hasTursoConfig) {
    return TursoDatabase(url: tursoUrl, authToken: tursoToken);
  }
  return driftDatabase(name: 'petsa');
}

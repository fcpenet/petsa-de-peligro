import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'turso/turso_database.dart';

/// Turso connection settings, injected at build time with
/// `--dart-define-from-file=.env.local` (never committed).
///
/// For the deployed web app, `TURSO_URL=/` and no token: the app talks to the
/// proxy on its own site (web_proxy/), which holds the token.
const tursoUrl = String.fromEnvironment('TURSO_URL');
const tursoToken = String.fromEnvironment('TURSO_TOKEN');

/// Whether [url] points at the same-site proxy rather than Turso itself.
bool usesSameSiteProxy(String url) => url.startsWith('/');

bool hasTursoConfigFor(String url, String token) =>
    url.isNotEmpty && (token.isNotEmpty || usesSameSiteProxy(url));

bool get hasTursoConfig => hasTursoConfigFor(tursoUrl, tursoToken);

/// The absolute URL to connect to; a same-site path is resolved against
/// [base] (the page's address in the browser).
String resolveTursoUrl(String url, Uri base) =>
    usesSameSiteProxy(url) ? base.resolve(url).toString() : url;

/// Uses Turso when configured, otherwise the on-device SQLite database.
QueryExecutor defaultExecutor() {
  if (hasTursoConfig) {
    return TursoDatabase(
      url: resolveTursoUrl(tursoUrl, Uri.base),
      authToken: tursoToken,
    );
  }
  return driftDatabase(name: 'petsa');
}

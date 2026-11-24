import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sqlite3/sqlite3.dart';

/// An in-process stand-in for Turso's `POST /v3/pipeline` endpoint, backed by
/// an in-memory SQLite database. Records every HTTP request so tests can
/// assert on round trips and protocol details.
class FakeTursoServer {
  FakeTursoServer({this.token = 'test-token'}) : _db = sqlite3.openInMemory() {
    _db.execute('PRAGMA foreign_keys = ON');
  }

  final String token;
  final Database _db;
  final Set<String> _openBatons = {};
  var _batonCounter = 0;

  /// Request bodies received, in order.
  final List<Map<String, Object?>> requests = [];

  /// When set, the next request fails with this HTTP status.
  int? failNextWithStatus;

  int get requestCount => requests.length;
  int get openStreams => _openBatons.length;

  late final http.Client client = MockClient(_handle);

  Future<http.Response> _handle(http.Request request) async {
    if (request.method != 'POST' || request.url.path != '/v3/pipeline') {
      return http.Response('not found', 404);
    }
    // An empty token plays the web proxy: it must receive no Authorization.
    final expected = token.isEmpty ? null : 'Bearer $token';
    if (request.headers['Authorization'] != expected) {
      return http.Response(jsonEncode({'error': 'Unauthorized'}), 401);
    }
    final status = failNextWithStatus;
    if (status != null) {
      failNextWithStatus = null;
      return http.Response(jsonEncode({'error': 'boom'}), status);
    }

    final body = jsonDecode(request.body) as Map<String, Object?>;
    requests.add(body);

    final baton = body['baton'] as String?;
    if (baton != null && !_openBatons.remove(baton)) {
      return http.Response(jsonEncode({'error': 'Invalid baton'}), 400);
    }

    final results = <Object?>[];
    var closed = false;
    for (final req in (body['requests'] as List).cast<Map>()) {
      switch (req['type']) {
        case 'execute':
          results.add(_wrap(() => _execute(req['stmt'] as Map), 'execute'));
        case 'batch':
          results.add({
            'type': 'ok',
            'response': {
              'type': 'batch',
              'result': _batch((req['batch'] as Map)['steps'] as List),
            },
          });
        case 'close':
          closed = true;
          results.add({
            'type': 'ok',
            'response': {'type': 'close'},
          });
        default:
          results.add({
            'type': 'error',
            'error': {'message': 'unsupported ${req['type']}'},
          });
      }
    }

    String? nextBaton;
    if (!closed) {
      nextBaton = 'baton-${++_batonCounter}';
      _openBatons.add(nextBaton);
    }
    return http.Response(
      jsonEncode({'baton': nextBaton, 'base_url': null, 'results': results}),
      200,
      headers: {'content-type': 'application/json'},
    );
  }

  Map<String, Object?> _wrap(Map<String, Object?> Function() run, String type) {
    try {
      return {
        'type': 'ok',
        'response': {'type': type, 'result': run()},
      };
    } on SqliteException catch (e) {
      return {
        'type': 'error',
        'error': {'message': e.message, 'code': 'SQLITE_CONSTRAINT'},
      };
    }
  }

  Map<String, Object?> _execute(Map stmt) {
    final args = [for (final a in stmt['args'] as List) _decode(a as Map)];
    final prepared = _db.prepare(stmt['sql'] as String);
    try {
      final rs = prepared.select(args);
      final wantRows = stmt['want_rows'] as bool? ?? true;
      return {
        'cols': [
          for (final name in rs.columnNames) {'name': name, 'decltype': null},
        ],
        'rows': wantRows
            ? [
                for (final row in rs.rows) [for (final v in row) _encode(v)],
              ]
            : <Object?>[],
        'affected_row_count': _db.updatedRows,
        'last_insert_rowid': '${_db.lastInsertRowId}',
      };
    } finally {
      prepared.close();
    }
  }

  Map<String, Object?> _batch(List steps) {
    final stepResults = <Object?>[];
    final stepErrors = <Object?>[];
    for (final step in steps.cast<Map>()) {
      final condition = step['condition'] as Map?;
      if (condition != null && !_check(condition, stepResults, stepErrors)) {
        stepResults.add(null);
        stepErrors.add(null);
        continue;
      }
      try {
        stepResults.add(_execute(step['stmt'] as Map));
        stepErrors.add(null);
      } on SqliteException catch (e) {
        stepResults.add(null);
        stepErrors.add({'message': e.message});
      }
    }
    return {'step_results': stepResults, 'step_errors': stepErrors};
  }

  bool _check(Map cond, List results, List errors) => switch (cond['type']) {
    'ok' => results[cond['step'] as int] != null,
    'error' => errors[cond['step'] as int] != null,
    'not' => !_check(cond['cond'] as Map, results, errors),
    'and' => (cond['conds'] as List).every(
      (c) => _check(c as Map, results, errors),
    ),
    _ => throw ArgumentError('bad condition $cond'),
  };

  Object? _decode(Map v) => switch (v['type']) {
    'null' => null,
    'integer' => int.parse(v['value'] as String),
    'float' => v['value'] as num,
    'text' => v['value'] as String,
    'blob' => base64Decode(v['base64'] as String),
    _ => throw ArgumentError('bad value $v'),
  };

  Map<String, Object?> _encode(Object? v) => switch (v) {
    null => {'type': 'null'},
    final int i => {'type': 'integer', 'value': '$i'},
    final double d => {'type': 'float', 'value': d},
    final String s => {'type': 'text', 'value': s},
    final Uint8List b => {'type': 'blob', 'base64': base64Encode(b)},
    _ => throw ArgumentError('bad sqlite value $v'),
  };

  /// SQL text of every `execute` request and batch step, in order.
  List<String> get executedSql => [
    for (final body in requests)
      for (final req in (body['requests'] as List).cast<Map>())
        if (req['type'] == 'execute')
          (req['stmt'] as Map)['sql'] as String
        else if (req['type'] == 'batch')
          for (final step in ((req['batch'] as Map)['steps'] as List))
            ((step as Map)['stmt'] as Map)['sql'] as String,
  ];

  void dispose() => _db.close();
}

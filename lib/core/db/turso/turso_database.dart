/// A drift executor that talks to Turso over its HTTP API (Hrana v3 pipeline).
///
/// Works on every platform, including the browser: it only uses
/// `POST /v3/pipeline`, which Turso serves with permissive CORS headers.
///
/// Round trips:
/// - A statement outside a transaction is one HTTP request.
/// - A transaction defers its `BEGIN` and sends it with the first statement,
///   then sends `COMMIT` with the stream close. A drift `batch()` therefore
///   costs two requests in total, regardless of how many statements it has.
library;

import 'dart:convert';

import 'package:drift/backends.dart';
import 'package:drift/drift.dart';
import 'package:http/http.dart' as http;

class TursoException implements Exception {
  TursoException(this.message, {this.code, this.statusCode});

  factory TursoException.fromError(Object? error) {
    if (error is Map) {
      return TursoException(
        '${error['message'] ?? error}',
        code: error['code'] as String?,
      );
    }
    return TursoException('$error');
  }

  final String message;
  final String? code;
  final int? statusCode;

  @override
  String toString() => [
    'TursoException',
    if (statusCode != null) '(HTTP $statusCode)',
    if (code != null) '[$code]',
    ': $message',
  ].join();
}

/// Converts `libsql://host` into the `https://host` endpoint for HTTP.
Uri tursoHttpUri(String url) {
  final uri = Uri.parse(url);
  return switch (uri.scheme) {
    'libsql' || 'wss' => uri.replace(scheme: 'https'),
    'ws' => uri.replace(scheme: 'http'),
    'http' || 'https' => uri,
    _ => throw ArgumentError.value(url, 'url', 'Unsupported Turso URL scheme'),
  };
}

final class TursoDatabase extends DelegatedDatabase {
  TursoDatabase._(super.delegate, {super.logStatements});

  /// [url] accepts `libsql://`, `https://` or `http://` URLs. An empty
  /// [authToken] sends no `Authorization` header (for the web proxy).
  factory TursoDatabase({
    required String url,
    required String authToken,
    http.Client? httpClient,
    bool logStatements = false,
  }) {
    final client = _PipelineClient(
      tursoHttpUri(url),
      authToken,
      httpClient ?? http.Client(),
    );
    return TursoDatabase._(_RootDelegate(client), logStatements: logStatements);
  }
}

// ------------------------------------------------------------------ protocol

typedef _Json = Map<String, Object?>;

class _PipelineResponse {
  _PipelineResponse(this.baton, this.baseUrl, this.results);
  final String? baton;
  final String? baseUrl;
  final List<_Json> results;
}

class _PipelineClient {
  _PipelineClient(this.baseUri, this._token, this._http);

  final Uri baseUri;
  final String _token;
  final http.Client _http;

  Future<_PipelineResponse> send({
    required Uri base,
    required String? baton,
    required List<_Json> requests,
  }) async {
    final response = await _http.post(
      base.resolve('/v3/pipeline'),
      headers: {
        // No token when talking to the web proxy, which adds it server-side.
        if (_token.isNotEmpty) 'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'baton': baton, 'requests': requests}),
    );
    if (response.statusCode != 200) {
      Object? error = response.body;
      try {
        final decoded = jsonDecode(response.body);
        error = decoded is Map ? decoded['error'] ?? decoded : decoded;
      } on FormatException {
        // keep the raw body
      }
      throw TursoException(
        error is Map ? '${error['message'] ?? error}' : '$error',
        statusCode: response.statusCode,
      );
    }
    final body = jsonDecode(utf8.decode(response.bodyBytes)) as _Json;
    return _PipelineResponse(
      body['baton'] as String?,
      body['base_url'] as String?,
      (body['results'] as List).cast<_Json>(),
    );
  }

  void close() => _http.close();
}

_Json _stmt(String sql, List<Object?> args, {bool wantRows = true}) => {
  'sql': sql,
  'args': [for (final a in args) _encodeValue(a)],
  'want_rows': wantRows,
};

_Json _encodeValue(Object? value) => switch (value) {
  null => const {'type': 'null'},
  final bool b => {'type': 'integer', 'value': b ? '1' : '0'},
  final int i => {'type': 'integer', 'value': '$i'},
  final BigInt i => {'type': 'integer', 'value': '$i'},
  final double d => {'type': 'float', 'value': d},
  final String s => {'type': 'text', 'value': s},
  final List<int> bytes => {'type': 'blob', 'base64': base64Encode(bytes)},
  _ => throw ArgumentError.value(value, 'value', 'Unsupported SQL argument'),
};

Object? _decodeValue(_Json value) => switch (value['type']) {
  'null' => null,
  'integer' => int.parse(value['value'] as String),
  'float' => (value['value'] as num).toDouble(),
  'text' => value['value'] as String,
  'blob' => Uint8List.fromList(base64Decode(value['base64'] as String)),
  final type => throw TursoException('Unknown value type $type'),
};

_Json _executeRequest(String sql, List<Object?> args) => {
  'type': 'execute',
  'stmt': _stmt(sql, args),
};

const _Json _closeRequest = {'type': 'close'};

/// One Hrana stream: a server-side connection identified by a baton.
class _Stream {
  _Stream(this._client) : _base = _client.baseUri;

  final _PipelineClient _client;
  Uri _base;
  String? _baton;
  bool _closed = false;

  /// Requests sent ahead of the next call (used to defer BEGIN).
  final List<_Json> _deferred = [];

  /// Whether anything has been sent to the server on this stream yet.
  bool get hasStarted => _baton != null || _closed;

  void defer(_Json request) => _deferred.add(request);

  /// Sends [requests] (preceded by any deferred ones) and returns the
  /// responses for [requests] only. Throws on the first failed request.
  Future<List<_Json>> send(List<_Json> requests, {bool close = false}) async {
    if (_closed) throw TursoException('Stream is already closed');
    final deferredCount = _deferred.length;
    final all = [..._deferred, ...requests, if (close) _closeRequest];
    _deferred.clear();

    final response = await _client.send(
      base: _base,
      baton: _baton,
      requests: all,
    );
    _baton = response.baton;
    if (response.baseUrl != null) _base = Uri.parse(response.baseUrl!);
    if (close) _closed = true;

    for (final result in response.results) {
      if (result['type'] == 'error') {
        throw TursoException.fromError(result['error']);
      }
    }
    return [
      for (final result in response.results.sublist(
        deferredCount,
        deferredCount + requests.length,
      ))
        result['response'] as _Json,
    ];
  }
}

// ----------------------------------------------------------------- delegates

mixin _TursoQueries on QueryDelegate {
  /// Sends requests on the appropriate stream and returns their responses.
  Future<List<_Json>> sendRequests(List<_Json> requests);

  Future<_Json> _execute(String sql, List<Object?> args) async {
    final responses = await sendRequests([_executeRequest(sql, args)]);
    return responses.single['result'] as _Json;
  }

  @override
  Future<QueryResult> runSelect(String statement, List<Object?> args) async {
    final result = await _execute(statement, args);
    final columns = [
      for (final col in result['cols'] as List) (col as Map)['name'] as String,
    ];
    final rows = [
      for (final row in result['rows'] as List)
        [for (final value in row as List) _decodeValue(value as _Json)],
    ];
    return QueryResult(columns, rows);
  }

  @override
  Future<int> runUpdate(String statement, List<Object?> args) async {
    final result = await _execute(statement, args);
    return result['affected_row_count'] as int;
  }

  @override
  Future<int> runInsert(String statement, List<Object?> args) async {
    final result = await _execute(statement, args);
    final rowId = result['last_insert_rowid'];
    return rowId == null ? 0 : int.parse('$rowId');
  }

  @override
  Future<void> runCustom(String statement, List<Object?> args) async {
    await _execute(statement, args);
  }

  /// Sends the whole batch as one Hrana `batch` request. Each step only runs
  /// if the previous one succeeded.
  @override
  Future<void> runBatched(BatchedStatements statements) async {
    final steps = <_Json>[];
    for (final (i, arg) in statements.arguments.indexed) {
      steps.add({
        'stmt': _stmt(
          statements.statements[arg.statementIndex],
          arg.arguments,
          wantRows: false,
        ),
        if (i > 0) 'condition': {'type': 'ok', 'step': i - 1},
      });
    }
    if (steps.isEmpty) return;

    final responses = await sendRequests([
      {
        'type': 'batch',
        'batch': {'steps': steps},
      },
    ]);
    final result = responses.single['result'] as _Json;
    for (final error in result['step_errors'] as List) {
      if (error != null) throw TursoException.fromError(error);
    }
  }
}

final class _RootDelegate extends DatabaseDelegate with _TursoQueries {
  _RootDelegate(this._client);

  final _PipelineClient _client;
  bool _open = false;

  @override
  late final DbVersionDelegate versionDelegate = _VersionDelegate(this);

  @override
  late final TransactionDelegate transactionDelegate = _TransactionDelegate(
    _client,
  );

  /// Outside a transaction every call is a fresh stream, opened and closed
  /// within one request.
  @override
  Future<List<_Json>> sendRequests(List<_Json> requests) =>
      _Stream(_client).send(requests, close: true);

  @override
  bool get isOpen => _open;

  @override
  Future<void> open(QueryExecutorUser db) async {
    await (versionDelegate as _VersionDelegate).init();
    _open = true;
  }

  @override
  Future<void> close() async {
    _open = false;
    _client.close();
  }
}

final class _TransactionQueries extends QueryDelegate with _TursoQueries {
  _TransactionQueries(this._stream);

  final _Stream _stream;

  @override
  Future<List<_Json>> sendRequests(List<_Json> requests) =>
      _stream.send(requests);
}

final class _TransactionDelegate extends SupportedTransactionDelegate {
  _TransactionDelegate(this._client);

  final _PipelineClient _client;

  /// Let drift hold its lock so no other statement runs while a transaction
  /// is open, matching local SQLite semantics.
  @override
  bool get managesLockInternally => false;

  @override
  Future<void> startTransaction(Future Function(QueryDelegate) run) async {
    final stream = _Stream(_client)..defer(_executeRequest('BEGIN', const []));
    try {
      await run(_TransactionQueries(stream));
    } catch (_) {
      if (stream.hasStarted) {
        try {
          await stream.send([
            _executeRequest('ROLLBACK', const []),
          ], close: true);
        } catch (_) {
          // The server discards the stream on its own after a timeout.
        }
      }
      rethrow;
    }
    if (!stream.hasStarted) return; // nothing was executed
    await stream.send([_executeRequest('COMMIT', const [])], close: true);
  }
}

/// Turso doesn't persist `PRAGMA user_version`, so the schema version lives
/// in a table (compatible with drift_hrana's `__drift_user_version`).
final class _VersionDelegate extends DynamicVersionDelegate {
  _VersionDelegate(this._root);

  final _RootDelegate _root;

  Future<void> init() async {
    await _root.sendRequests([
      _executeRequest(
        'CREATE TABLE IF NOT EXISTS __drift_user_version '
        '(user_version INTEGER)',
        const [],
      ),
      _executeRequest(
        'INSERT INTO __drift_user_version (user_version) '
        'SELECT 0 WHERE NOT EXISTS (SELECT 1 FROM __drift_user_version)',
        const [],
      ),
    ]);
  }

  @override
  Future<int> get schemaVersion async {
    final result = await _root.runSelect(
      'SELECT user_version FROM __drift_user_version LIMIT 1',
      const [],
    );
    return result.rows.single.single as int;
  }

  @override
  Future<void> setSchemaVersion(int version) => _root.runCustom(
    'UPDATE __drift_user_version SET user_version = ?',
    [version],
  );
}

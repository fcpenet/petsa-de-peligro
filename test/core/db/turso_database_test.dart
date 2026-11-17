import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:petsa/core/db/database.dart';
import 'package:petsa/core/db/turso/turso_database.dart';

import '../../features/budget/budget_repository_suite.dart';
import '../../helpers/fake_turso.dart';

const _url = 'libsql://petsa-test.turso.io';

void main() {
  late FakeTursoServer server;

  setUp(() => server = FakeTursoServer());
  tearDown(() => server.dispose());

  TursoDatabase connect({String token = 'test-token'}) =>
      TursoDatabase(url: _url, authToken: token, httpClient: server.client);

  group('tursoHttpUri', () {
    test('maps libsql and websocket schemes to http(s)', () {
      expect(
        tursoHttpUri('libsql://db.turso.io').toString(),
        'https://db.turso.io',
      );
      expect(tursoHttpUri('wss://db.turso.io').scheme, 'https');
      expect(tursoHttpUri('ws://localhost:8080').scheme, 'http');
      expect(tursoHttpUri('http://localhost:8080').scheme, 'http');
    });

    test('rejects unknown schemes', () {
      expect(() => tursoHttpUri('ftp://x'), throwsArgumentError);
    });
  });

  group('executor', () {
    late TursoDatabase executor;
    late _RawDb db;

    setUp(() async {
      executor = connect();
      db = _RawDb(executor);
      await db.customStatement(
        'CREATE TABLE t (id INTEGER PRIMARY KEY, i INTEGER, r REAL, '
        's TEXT, b BLOB, n TEXT)',
      );
    });

    tearDown(() => db.close());

    test('round-trips every value type', () async {
      await db.customInsert(
        'INSERT INTO t (i, r, s, b, n) VALUES (?, ?, ?, ?, ?)',
        variables: [
          Variable.withInt(9007199254740991),
          Variable.withReal(1.5),
          Variable.withString('₱ unicode ✓'),
          Variable.withBlob(Uint8List.fromList([0, 1, 254, 255])),
          const Variable(null),
        ],
      );
      final row = await db.customSelect('SELECT * FROM t').getSingle();
      expect(row.read<int>('i'), 9007199254740991);
      expect(row.read<double>('r'), 1.5);
      expect(row.read<String>('s'), '₱ unicode ✓');
      expect(row.read<Uint8List>('b'), [0, 1, 254, 255]);
      expect(row.readNullable<String>('n'), isNull);
    });

    test('returns insert row ids and affected row counts', () async {
      final id = await db.customInsert("INSERT INTO t (s) VALUES ('a')");
      expect(id, 1);
      await db.customInsert("INSERT INTO t (s) VALUES ('b')");
      final updated = await db.customUpdate("UPDATE t SET s = 'x'");
      expect(updated, 2);
    });

    test(
      'a statement outside a transaction is one request, then closed',
      () async {
        server.requests.clear();
        await db.customSelect('SELECT 1').get();
        expect(server.requestCount, 1);
        final requests = server.requests.single['requests'] as List;
        expect(requests.last, {'type': 'close'});
        expect(server.openStreams, 0);
      },
    );

    test('a transaction defers BEGIN and commits with the close', () async {
      server.requests.clear();
      await db.transaction(() async {
        await db.customStatement("INSERT INTO t (s) VALUES ('a')");
        await db.customStatement("INSERT INTO t (s) VALUES ('b')");
      });
      // BEGIN+INSERT, INSERT, COMMIT+close
      expect(server.requestCount, 3);
      expect(server.executedSql, [
        'BEGIN',
        "INSERT INTO t (s) VALUES ('a')",
        "INSERT INTO t (s) VALUES ('b')",
        'COMMIT',
      ]);
      expect(server.requests[0]['baton'], isNull);
      expect(server.requests[1]['baton'], isNotNull);
      expect(server.openStreams, 0);
    });

    test('an empty transaction sends nothing', () async {
      server.requests.clear();
      await db.transaction(() async {});
      expect(server.requestCount, 0);
    });

    test('a failing transaction rolls back', () async {
      await expectLater(
        db.transaction(() async {
          await db.customStatement("INSERT INTO t (s) VALUES ('a')");
          throw StateError('abort');
        }),
        throwsStateError,
      );
      expect(server.executedSql.last, 'ROLLBACK');
      expect(server.openStreams, 0);
      expect(await db.customSelect('SELECT * FROM t').get(), isEmpty);
    });

    test('a batch costs two requests and is atomic', () async {
      server.requests.clear();
      await db.batch((b) {
        for (var i = 0; i < 20; i++) {
          b.customStatement('INSERT INTO t (i) VALUES (?)', [i]);
        }
      });
      expect(server.requestCount, 2);
      final count = await db
          .customSelect('SELECT COUNT(*) AS c FROM t')
          .getSingle();
      expect(count.read<int>('c'), 20);
    });

    test('a failing batch step rolls back the whole batch', () async {
      await db.customStatement('CREATE UNIQUE INDEX t_i ON t (i)');
      await expectLater(
        db.batch((b) {
          b.customStatement('INSERT INTO t (i) VALUES (1)');
          b.customStatement('INSERT INTO t (i) VALUES (1)'); // duplicate
          b.customStatement('INSERT INTO t (i) VALUES (2)');
        }),
        throwsA(isA<TursoException>()),
      );
      expect(await db.customSelect('SELECT * FROM t').get(), isEmpty);
    });

    test('SQL errors surface as TursoException', () async {
      await expectLater(
        db.customSelect('SELECT * FROM missing').get(),
        throwsA(isA<TursoException>()),
      );
    });

    test('HTTP errors surface with the status code', () async {
      server.failNextWithStatus = 500;
      await expectLater(
        db.customSelect('SELECT 1').get(),
        throwsA(
          isA<TursoException>().having((e) => e.statusCode, 'status', 500),
        ),
      );
    });
  });

  test('a bad token is rejected', () async {
    final db = _RawDb(connect(token: 'wrong'));
    await expectLater(
      db.customSelect('SELECT 1').get(),
      throwsA(isA<TursoException>().having((e) => e.statusCode, 'status', 401)),
    );
  });

  test('stores the schema version in a table', () async {
    final db = AppDatabase(connect());
    await db.customSelect('SELECT 1').get();
    final row = await db
        .customSelect('SELECT user_version FROM __drift_user_version')
        .getSingle();
    expect(row.read<int>('user_version'), db.schemaVersion);
    await db.close();
  });

  group('round trips per repository operation', () {
    test('setStatus on a sub-expense is 3 requests', () async {
      final db = AppDatabase(connect());
      addTearDown(db.close);
      final ids = await seedMiscWithChildren(db, children: 5);

      server.requests.clear();
      await budgetRepo(db).setStatus(ids.children.first, ItemStatus.paid);
      expect(server.requestCount, 3);
    });

    test('setStatus on a parent with 5 children is 3 requests', () async {
      final db = AppDatabase(connect());
      addTearDown(db.close);
      final ids = await seedMiscWithChildren(db, children: 5);

      server.requests.clear();
      await budgetRepo(db).setStatus(ids.parent, ItemStatus.paid);
      expect(server.requestCount, 3);
    });

    test('totalsFor is 3 parallel requests', () async {
      final db = AppDatabase(connect());
      addTearDown(db.close);
      final ids = await seedMiscWithChildren(db, children: 2);

      server.requests.clear();
      await budgetRepo(db).totalsFor(ids.monthId);
      // items ‖ incomes ‖ top-ups
      expect(server.requestCount, 3);
    });
  });

  // The whole repository suite, over the HTTP protocol.
  group('repository suite over fake Turso', () {
    budgetRepositoryTests(() async {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      return AppDatabase(connect());
    });
  });
}

class _RawDb extends GeneratedDatabase {
  _RawDb(super.executor);

  @override
  Iterable<TableInfo<Table, Object?>> get allTables => const [];

  @override
  int get schemaVersion => 1;
}

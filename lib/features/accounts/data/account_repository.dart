import 'package:drift/drift.dart';

import '../../../core/db/database.dart';

class AccountRepository {
  AccountRepository(this._db);

  final AppDatabase _db;

  Future<String> createInstitution(String name, {int sortOrder = 0}) async {
    final row = await _db
        .into(_db.institutions)
        .insertReturning(
          InstitutionsCompanion.insert(
            name: name.trim(),
            sortOrder: Value(sortOrder),
          ),
        );
    return row.id;
  }

  Future<String> createAccount({
    required String name,
    required AccountType type,
    String? institutionId,
    int sortOrder = 0,
  }) async {
    final row = await _db
        .into(_db.accounts)
        .insertReturning(
          AccountsCompanion.insert(
            name: name.trim(),
            type: type,
            institutionId: Value(institutionId),
            sortOrder: Value(sortOrder),
          ),
        );
    return row.id;
  }

  /// Archived accounts stay attached to past items but are hidden from pickers.
  Future<void> setArchived(String accountId, {required bool archived}) {
    return (_db.update(_db.accounts)..where((a) => a.id.equals(accountId)))
        .write(
          AccountsCompanion(
            archived: Value(archived),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  Future<List<Institution>> institutions() {
    return (_db.select(_db.institutions)
          ..where((i) => i.deletedAt.isNull())
          ..orderBy([(i) => OrderingTerm(expression: i.sortOrder)]))
        .get();
  }

  SimpleSelectStatement<$AccountsTable, Account> _activeAccounts({
    bool includeArchived = false,
  }) {
    final query = _db.select(_db.accounts)
      ..where((a) => a.deletedAt.isNull())
      ..orderBy([
        (a) => OrderingTerm(expression: a.sortOrder),
        (a) => OrderingTerm(expression: a.name),
      ]);
    if (!includeArchived) query.where((a) => a.archived.equals(false));
    return query;
  }

  Future<List<Account>> accounts({bool includeArchived = false}) =>
      _activeAccounts(includeArchived: includeArchived).get();

  Stream<List<Account>> watchAccounts({bool includeArchived = false}) =>
      _activeAccounts(includeArchived: includeArchived).watch();
}

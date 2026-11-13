import 'package:drift/drift.dart';

import '../../../core/db/database.dart';
import '../domain/budget_calculator.dart';

class BudgetException implements Exception {
  BudgetException(this.message);
  final String message;
  @override
  String toString() => 'BudgetException: $message';
}

/// Months, incomes and expense items, including the allotted → paid cascade.
///
/// Cascade rules:
/// - A sub-expense's status is set directly. Its parent then becomes paid
///   when every sub-expense is paid, and allotted otherwise.
/// - Setting a parent's status applies it to all its sub-expenses.
/// - Adding an unpaid sub-expense to a paid parent makes the parent allotted.
/// - Deleting a sub-expense re-derives the parent's status.
class BudgetRepository {
  BudgetRepository(this._db, {DateTime Function()? clock})
    : _now = clock ?? DateTime.now;

  final AppDatabase _db;
  final DateTime Function() _now;

  // ---------------------------------------------------------------- months

  static String yearMonthOf(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}';

  /// Returns the month for 'YYYY-MM', creating it if needed.
  Future<Month> ensureMonth(String yearMonth) {
    if (!RegExp(r'^\d{4}-(0[1-9]|1[0-2])$').hasMatch(yearMonth)) {
      throw BudgetException('Invalid month "$yearMonth", expected YYYY-MM');
    }
    return _db.transaction(() async {
      final existing = await (_db.select(
        _db.months,
      )..where((m) => m.yearMonth.equals(yearMonth))).getSingleOrNull();
      if (existing != null) return existing;
      return _db
          .into(_db.months)
          .insertReturning(MonthsCompanion.insert(yearMonth: yearMonth));
    });
  }

  // --------------------------------------------------------------- incomes

  Future<String> addIncome({
    required String monthId,
    required String name,
    required int amountCents,
    String? accountId,
  }) async {
    _checkAmount(amountCents);
    final row = await _db
        .into(_db.incomes)
        .insertReturning(
          IncomesCompanion.insert(
            monthId: monthId,
            name: name.trim(),
            amountCents: amountCents,
            accountId: Value(accountId),
          ),
        );
    return row.id;
  }

  Future<List<Income>> incomesFor(String monthId) {
    return (_db.select(_db.incomes)
          ..where((i) => i.monthId.equals(monthId) & i.deletedAt.isNull())
          ..orderBy([(i) => OrderingTerm(expression: i.sortOrder)]))
        .get();
  }

  // ----------------------------------------------------------------- items

  /// Adds an expense, or a sub-expense when [parentId] is given.
  Future<String> addItem({
    required String monthId,
    required String name,
    required int amountCents,
    String? accountId,
    String? parentId,
    ItemKind kind = ItemKind.expense,
    int? dueDay,
    String? note,
    int sortOrder = 0,
  }) {
    _checkAmount(amountCents);
    _checkDueDay(dueDay);
    return _db.transaction(() async {
      if (parentId != null) {
        final parent = await _liveItem(parentId);
        if (parent.parentId != null) {
          throw BudgetException('Sub-expenses cannot have sub-expenses');
        }
        if (parent.monthId != monthId) {
          throw BudgetException('Sub-expense must be in the same month');
        }
      }
      final row = await _db
          .into(_db.items)
          .insertReturning(
            ItemsCompanion.insert(
              monthId: monthId,
              name: name.trim(),
              amountCents: amountCents,
              accountId: Value(accountId),
              parentId: Value(parentId),
              kind: Value(kind),
              dueDay: Value(dueDay),
              note: Value(note),
              sortOrder: Value(sortOrder),
            ),
          );
      if (parentId != null) await _rederiveParent(parentId);
      return row.id;
    });
  }

  /// Edits an item's details. Status changes go through [setStatus].
  Future<void> updateItem(
    String id, {
    String? name,
    int? amountCents,
    Value<String?> accountId = const Value.absent(),
    ItemKind? kind,
    Value<int?> dueDay = const Value.absent(),
    Value<String?> note = const Value.absent(),
  }) async {
    if (amountCents != null) _checkAmount(amountCents);
    if (dueDay.present) _checkDueDay(dueDay.value);
    await _liveItem(id);
    await (_db.update(_db.items)..where((i) => i.id.equals(id))).write(
      ItemsCompanion(
        name: name == null ? const Value.absent() : Value(name.trim()),
        amountCents: Value.absentIfNull(amountCents),
        accountId: accountId,
        kind: Value.absentIfNull(kind),
        dueDay: dueDay,
        note: note,
        updatedAt: Value(_now()),
      ),
    );
  }

  /// Marks an item allotted or paid and cascades to its parent/sub-expenses.
  ///
  /// [paidAt] is the date the payment was made (e.g. when a credit card item
  /// was settled); it defaults to now. Sub-expenses that were already paid
  /// keep their original payment date when a parent is marked paid.
  Future<void> setStatus(String id, ItemStatus status, {DateTime? paidAt}) {
    return _db.transaction(() async {
      final item = await _liveItem(id);
      final now = _now();
      final payDate = paidAt ?? now;
      final children = await _liveChildren(id);

      if (children.isNotEmpty) {
        final childQuery = _db.update(_db.items)
          ..where((i) => i.parentId.equals(id) & i.deletedAt.isNull());
        if (status == ItemStatus.paid) {
          childQuery.where((i) => i.status.equalsValue(ItemStatus.allotted));
          await childQuery.write(
            ItemsCompanion(
              status: const Value(ItemStatus.paid),
              paidAt: Value(payDate),
              updatedAt: Value(now),
            ),
          );
        } else {
          await childQuery.write(
            ItemsCompanion(
              status: const Value(ItemStatus.allotted),
              paidAt: const Value(null),
              updatedAt: Value(now),
            ),
          );
        }
      }

      await _writeStatus(
        id,
        status,
        status == ItemStatus.paid ? payDate : null,
        now,
      );
      if (item.parentId != null) await _rederiveParent(item.parentId!);
    });
  }

  /// Soft-deletes an item. Deleting a parent also deletes its sub-expenses.
  Future<void> deleteItem(String id) {
    return _db.transaction(() async {
      final item = await _liveItem(id);
      final now = _now();
      await (_db.update(_db.items)..where(
            (i) => (i.id.equals(id) | i.parentId.equals(id)) &
                i.deletedAt.isNull(),
          ))
          .write(ItemsCompanion(deletedAt: Value(now), updatedAt: Value(now)));
      if (item.parentId != null) await _rederiveParent(item.parentId!);
    });
  }

  Future<List<BudgetItem>> itemsFor(String monthId) => _itemsQuery(monthId).get();

  Stream<List<BudgetItem>> watchItems(String monthId) =>
      _itemsQuery(monthId).watch();

  Future<BudgetItem> item(String id) => _liveItem(id);

  Future<MonthTotals> totalsFor(String monthId) async {
    final results = await Future.wait([
      itemsFor(monthId),
      incomesFor(monthId),
    ]);
    return computeMonthTotals(
      items: results[0] as List<BudgetItem>,
      incomes: results[1] as List<Income>,
    );
  }

  // --------------------------------------------------------------- helpers

  SimpleSelectStatement<$ItemsTable, BudgetItem> _itemsQuery(String monthId) {
    return _db.select(_db.items)
      ..where((i) => i.monthId.equals(monthId) & i.deletedAt.isNull())
      ..orderBy([
        (i) => OrderingTerm(expression: i.sortOrder),
        (i) => OrderingTerm(expression: i.name),
      ]);
  }

  Future<BudgetItem> _liveItem(String id) async {
    final item = await (_db.select(
      _db.items,
    )..where((i) => i.id.equals(id) & i.deletedAt.isNull())).getSingleOrNull();
    if (item == null) throw BudgetException('Item $id not found');
    return item;
  }

  Future<List<BudgetItem>> _liveChildren(String parentId) {
    return (_db.select(
      _db.items,
    )..where((i) => i.parentId.equals(parentId) & i.deletedAt.isNull())).get();
  }

  /// Recomputes a parent's status from its sub-expenses. A parent left with
  /// no sub-expenses keeps its current status.
  Future<void> _rederiveParent(String parentId) async {
    final parent = await _liveItem(parentId);
    final children = await _liveChildren(parentId);
    final derived = deriveParentStatus(children.map((c) => c.status));
    if (derived == null) return;

    DateTime? paidAt;
    if (derived == ItemStatus.paid) {
      // The parent counts as paid on the date its last sub-expense was paid.
      paidAt = children
          .map((c) => c.paidAt ?? _now())
          .reduce((a, b) => a.isAfter(b) ? a : b);
    }
    if (parent.status == derived && parent.paidAt == paidAt) return;
    await _writeStatus(parentId, derived, paidAt, _now());
  }

  Future<void> _writeStatus(
    String id,
    ItemStatus status,
    DateTime? paidAt,
    DateTime now,
  ) {
    return (_db.update(_db.items)..where((i) => i.id.equals(id))).write(
      ItemsCompanion(
        status: Value(status),
        paidAt: Value(paidAt),
        updatedAt: Value(now),
      ),
    );
  }

  void _checkAmount(int cents) {
    if (cents < 0) throw BudgetException('Amount cannot be negative');
  }

  void _checkDueDay(int? day) {
    if (day != null && (day < 1 || day > 31)) {
      throw BudgetException('Due day must be between 1 and 31');
    }
  }
}

import 'package:drift/drift.dart';

import '../../../core/db/database.dart';
import '../domain/budget_calculator.dart';
import '../domain/status_planner.dart';

class BudgetException implements Exception {
  BudgetException(this.message);
  final String message;
  @override
  String toString() => 'BudgetException: $message';
}

/// Months, incomes and expense items, including the allotted → paid cascade.
///
/// Cascade rules (see `status_planner.dart`):
/// - A sub-expense's status is set directly. Its parent then becomes paid
///   when every sub-expense is paid, and allotted otherwise.
/// - Setting a parent's status applies it to all its sub-expenses.
/// - Adding an unpaid sub-expense to a paid parent makes the parent allotted.
/// - Deleting a sub-expense re-derives the parent's status.
///
/// Writes that touch several rows read the affected "family" once, plan the
/// changes in Dart, and apply them in a single atomic batch. Over Turso that
/// is three HTTP requests regardless of how many rows change.
class BudgetRepository {
  BudgetRepository(this._db, {DateTime Function()? clock})
    : _now = clock ?? DateTime.now;

  final AppDatabase _db;
  final DateTime Function() _now;

  // ---------------------------------------------------------------- months

  static String yearMonthOf(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}';

  static final _yearMonthPattern = RegExp(r'^\d{4}-(0[1-9]|1[0-2])$');

  static bool isValidYearMonth(String value) =>
      _yearMonthPattern.hasMatch(value);

  /// Returns the month for 'YYYY-MM' without creating it.
  Future<Month?> findMonth(String yearMonth) => (_db.select(
    _db.months,
  )..where((m) => m.yearMonth.equals(yearMonth))).getSingleOrNull();

  /// Returns the month for 'YYYY-MM', creating it if needed.
  Future<Month> ensureMonth(String yearMonth) async {
    if (!isValidYearMonth(yearMonth)) {
      throw BudgetException('Invalid month "$yearMonth", expected YYYY-MM');
    }
    final query = _db.select(_db.months)
      ..where((m) => m.yearMonth.equals(yearMonth));
    final existing = await query.getSingleOrNull();
    if (existing != null) return existing;

    await _db
        .into(_db.months)
        .insert(
          MonthsCompanion.insert(yearMonth: yearMonth),
          mode: InsertMode.insertOrIgnore,
        );
    return query.getSingle();
  }

  /// Deletes everything in a month — expenses, income, top-ups and
  /// transfers — in one batch, leaving it empty so it can be started again
  /// (from a template, last month, or scratch). Other months are untouched.
  Future<void> clearMonth(String monthId) async {
    final now = _now();
    final deleted = ItemsCompanion(
      deletedAt: Value(now),
      updatedAt: Value(now),
    );
    final incomeIds = _db.selectOnly(_db.incomes)
      ..addColumns([_db.incomes.id])
      ..where(_db.incomes.monthId.equals(monthId));
    await _db.batch((b) {
      b.update(
        _db.items,
        deleted,
        where: (i) => i.monthId.equals(monthId) & i.deletedAt.isNull(),
      );
      b.update(
        _db.incomeTopUps,
        IncomeTopUpsCompanion(deletedAt: Value(now), updatedAt: Value(now)),
        where: (t) => t.incomeId.isInQuery(incomeIds) & t.deletedAt.isNull(),
      );
      b.update(
        _db.incomes,
        IncomesCompanion(deletedAt: Value(now), updatedAt: Value(now)),
        where: (i) => i.monthId.equals(monthId) & i.deletedAt.isNull(),
      );
      b.update(
        _db.transfers,
        TransfersCompanion(deletedAt: Value(now), updatedAt: Value(now)),
        where: (t) => t.monthId.equals(monthId) & t.deletedAt.isNull(),
      );
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
    final id = newId();
    await _db
        .into(_db.incomes)
        .insert(
          IncomesCompanion.insert(
            id: Value(id),
            monthId: monthId,
            name: name.trim(),
            amountCents: amountCents,
            accountId: Value(accountId),
            sortOrder: Value(_nextSortOrder()),
          ),
        );
    return id;
  }

  Future<void> updateIncome(String id, {String? name, int? amountCents}) async {
    if (amountCents != null) _checkAmount(amountCents);
    final updated =
        await (_db.update(
          _db.incomes,
        )..where((i) => i.id.equals(id) & i.deletedAt.isNull())).write(
          IncomesCompanion(
            name: name == null ? const Value.absent() : Value(name.trim()),
            amountCents: Value.absentIfNull(amountCents),
            updatedAt: Value(_now()),
          ),
        );
    if (updated == 0) throw BudgetException('Income $id not found');
  }

  Future<void> deleteIncome(String id) async {
    final now = _now();
    await (_db.update(_db.incomes)..where((i) => i.id.equals(id))).write(
      IncomesCompanion(deletedAt: Value(now), updatedAt: Value(now)),
    );
  }

  SimpleSelectStatement<$IncomesTable, Income> _incomesQuery(String monthId) =>
      _db.select(_db.incomes)
        ..where((i) => i.monthId.equals(monthId) & i.deletedAt.isNull())
        ..orderBy([(i) => OrderingTerm(expression: i.sortOrder)]);

  Future<List<Income>> incomesFor(String monthId) =>
      _incomesQuery(monthId).get();

  Stream<List<Income>> watchIncomes(String monthId) =>
      _incomesQuery(monthId).watch();

  // ---------------------------------------------------------------- top-ups

  /// Records money that actually arrived for an income.
  Future<String> addTopUp({
    required String incomeId,
    required int amountCents,
    required DateTime receivedAt,
    String? note,
  }) async {
    _checkTopUp(amountCents);
    final income =
        await (_db.select(_db.incomes)
              ..where((i) => i.id.equals(incomeId) & i.deletedAt.isNull()))
            .getSingleOrNull();
    if (income == null) throw BudgetException('Income $incomeId not found');
    final id = newId();
    await _db
        .into(_db.incomeTopUps)
        .insert(
          IncomeTopUpsCompanion.insert(
            id: Value(id),
            incomeId: incomeId,
            amountCents: amountCents,
            receivedAt: receivedAt,
            note: Value(_cleanNote(note)),
          ),
        );
    return id;
  }

  Future<void> updateTopUp(
    String id, {
    int? amountCents,
    DateTime? receivedAt,
    Value<String?> note = const Value.absent(),
  }) async {
    if (amountCents != null) _checkTopUp(amountCents);
    final updated =
        await (_db.update(
          _db.incomeTopUps,
        )..where((t) => t.id.equals(id) & t.deletedAt.isNull())).write(
          IncomeTopUpsCompanion(
            amountCents: Value.absentIfNull(amountCents),
            receivedAt: Value.absentIfNull(receivedAt),
            note: note.present ? Value(_cleanNote(note.value)) : note,
            updatedAt: Value(_now()),
          ),
        );
    if (updated == 0) throw BudgetException('Top-up $id not found');
  }

  Future<void> deleteTopUp(String id) async {
    final now = _now();
    await (_db.update(_db.incomeTopUps)..where((t) => t.id.equals(id))).write(
      IncomeTopUpsCompanion(deletedAt: Value(now), updatedAt: Value(now)),
    );
  }

  /// Top-ups of the month's live incomes, oldest first.
  Selectable<TopUp> _topUpsQuery(String monthId) {
    final t = _db.incomeTopUps;
    final i = _db.incomes;
    final query = _db.select(t).join([innerJoin(i, i.id.equalsExp(t.incomeId))])
      ..where(
        i.monthId.equals(monthId) & i.deletedAt.isNull() & t.deletedAt.isNull(),
      )
      ..orderBy([OrderingTerm(expression: t.receivedAt)]);
    return query.map((row) => row.readTable(t));
  }

  Future<List<TopUp>> topUpsFor(String monthId) => _topUpsQuery(monthId).get();

  Stream<List<TopUp>> watchTopUps(String monthId) =>
      _topUpsQuery(monthId).watch();

  void _checkTopUp(int cents) {
    if (cents <= 0) throw BudgetException('A top-up must be more than zero');
  }

  String? _cleanNote(String? note) {
    final trimmed = note?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  // ----------------------------------------------------------------- items

  /// Adds an expense, or a sub-expense of the collection [parentId].
  /// With [isCollection] the expense holds sub-expenses and [amountCents]
  /// is its budget.
  Future<String> addItem({
    required String monthId,
    required String name,
    required int amountCents,
    String? accountId,
    String? parentId,
    ItemKind kind = ItemKind.expense,
    int? dueDay,
    String? note,
    int? sortOrder,
    bool isCollection = false,
  }) async {
    _checkAmount(amountCents);
    _checkDueDay(dueDay);
    if (isCollection && parentId != null) {
      throw BudgetException('A collection cannot be a sub-expense');
    }
    final id = newId();
    final row = ItemsCompanion.insert(
      id: Value(id),
      monthId: monthId,
      name: name.trim(),
      amountCents: amountCents,
      accountId: Value(accountId),
      parentId: Value(parentId),
      kind: Value(kind),
      dueDay: Value(dueDay),
      note: Value(note),
      sortOrder: Value(sortOrder ?? _nextSortOrder()),
      isCollection: Value(isCollection),
      status: const Value(ItemStatus.planned),
    );

    if (parentId == null) {
      await _db.into(_db.items).insert(row);
      return id;
    }

    final family = await _family(parentId);
    final parent = family[parentId];
    if (parent == null) throw BudgetException('Item $parentId not found');
    _checkCollection(parent);
    if (parent.accountId == null && accountId == null) {
      throw BudgetException(
        '“${parent.name}” has no account, so its sub-expenses need one',
      );
    }
    if (parent.monthId != monthId) {
      throw BudgetException('Sub-expense must be in the same month');
    }

    // The new child starts planned, which can only move its parent back.
    final now = _now();
    final newChild = _placeholderItem(id, monthId, parentId, now);
    final patch = planParentRederive(
      ItemFamily([...family.childrenOf(parentId), parent, newChild]),
      parentId,
      now: now,
    );
    await _db.batch((b) {
      b.insert(_db.items, row);
      if (patch != null) _writePatch(b, parentId, patch, now);
    });
    return id;
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
    bool? isCollection,
  }) async {
    if (amountCents != null) _checkAmount(amountCents);
    if (dueDay.present) _checkDueDay(dueDay.value);
    if (isCollection != null) {
      final family = await _family(id);
      final item = family[id];
      if (item == null) throw BudgetException('Item $id not found');
      if (isCollection && item.parentId != null) {
        throw BudgetException('A sub-expense cannot be a collection');
      }
      if (!isCollection && family.childrenOf(id).isNotEmpty) {
        throw BudgetException(
          'Move or delete its sub-expenses before turning off Collection',
        );
      }
    }
    final updated =
        await (_db.update(
          _db.items,
        )..where((i) => i.id.equals(id) & i.deletedAt.isNull())).write(
          ItemsCompanion(
            name: name == null ? const Value.absent() : Value(name.trim()),
            amountCents: Value.absentIfNull(amountCents),
            accountId: accountId,
            kind: Value.absentIfNull(kind),
            dueDay: dueDay,
            note: note,
            isCollection: Value.absentIfNull(isCollection),
            updatedAt: Value(_now()),
          ),
        );
    if (updated == 0) throw BudgetException('Item $id not found');
  }

  /// Moves an item into a collection ([parentId]) or out of it (null). Both
  /// the old and new collection's statuses are re-derived.
  Future<void> setParent(String id, String? parentId) async {
    if (parentId == id) throw BudgetException('An item cannot contain itself');
    final now = _now();
    final (family, target) = await (
      _family(id),
      parentId == null ? Future.value(null) : _family(parentId),
    ).wait;
    final item = family[id];
    if (item == null) throw BudgetException('Item $id not found');
    if (item.parentId == parentId) return;

    BudgetItem? newParent;
    if (parentId != null) {
      newParent = target?[parentId];
      if (newParent == null) throw BudgetException('Collection not found');
      _checkCollection(newParent);
      if (newParent.monthId != item.monthId) {
        throw BudgetException('Sub-expense must be in the same month');
      }
      if (item.isCollection || family.childrenOf(id).isNotEmpty) {
        throw BudgetException(
          'A collection cannot go inside another collection',
        );
      }
    }

    final oldParentId = item.parentId;
    final oldPatch = oldParentId == null
        ? null
        : planParentRederive(
            ItemFamily([
              ...family.childrenOf(oldParentId).where((c) => c.id != id),
              ?family[oldParentId],
            ]),
            oldParentId,
            now: now,
          );
    final newPatch = parentId == null
        ? null
        : planParentRederive(
            ItemFamily([
              ...target!.childrenOf(parentId),
              newParent!,
              item.copyWith(parentId: Value(parentId)),
            ]),
            parentId,
            now: now,
          );

    await _db.batch((b) {
      b.update(
        _db.items,
        ItemsCompanion(parentId: Value(parentId), updatedAt: Value(now)),
        where: (i) => i.id.equals(id),
      );
      if (oldPatch != null) _writePatch(b, oldParentId!, oldPatch, now);
      if (newPatch != null) _writePatch(b, parentId!, newPatch, now);
    });
  }

  /// Marks an item allotted or paid and cascades to its parent/sub-expenses.
  ///
  /// [paidAt] is the date the payment was made (e.g. when a credit card item
  /// was settled); it defaults to now. Sub-expenses that were already paid
  /// keep their original payment date when a parent is marked paid.
  ///
  /// [paidFromAccountId] records that the item was paid from another account
  /// than planned; null (or the planned account) means as planned. Marking
  /// an item allotted clears it.
  Future<void> setStatus(
    String id,
    ItemStatus status, {
    DateTime? paidAt,
    String? paidFromAccountId,
  }) async {
    final now = _now();
    final family = await _family(id);
    final item = family[id];
    if (item == null) throw BudgetException('Item $id not found');
    final planned =
        item.accountId ??
        (item.parentId == null ? null : family[item.parentId!]?.accountId);
    final paidFrom = status == ItemStatus.paid && paidFromAccountId != planned
        ? paidFromAccountId
        : null;
    if (paidFrom != null && family.childrenOf(id).isNotEmpty) {
      throw BudgetException(
        'Set “paid from” on the sub-expenses, not the collection',
      );
    }

    final patches = planStatusChange(
      family,
      targetId: id,
      status: status,
      paidAt: paidAt ?? now,
      now: now,
    );
    await _db.batch((b) {
      for (final MapEntry(key: itemId, value: patch) in patches.entries) {
        _writePatch(b, itemId, patch, now);
      }
      if (status == ItemStatus.paid) {
        b.update(
          _db.items,
          ItemsCompanion(paidFromAccountId: Value(paidFrom)),
          where: (i) => i.id.equals(id),
        );
      }
    });
  }

  /// Marks everything still planned to be paid from [accountId] as allotted
  /// — the money has been moved into the account. Sub-expenses count toward
  /// their own account (or their collection's); collections follow their
  /// sub-expenses. Returns how many expenses changed.
  Future<int> allotAccount(String monthId, String accountId) async {
    final now = _now();
    final items = await itemsFor(monthId);
    final byId = {for (final i in items) i.id: i};
    final hasChildren = {for (final i in items) ?i.parentId};
    final targets = [
      for (final i in items)
        if (i.status == ItemStatus.planned &&
            !i.isCollection &&
            !hasChildren.contains(i.id) &&
            (i.accountId ??
                    (i.parentId == null
                        ? null
                        : byId[i.parentId]?.accountId)) ==
                accountId)
          i,
    ];
    if (targets.isEmpty) return 0;

    final changed = {for (final t in targets) t.id};
    final parents = {for (final t in targets) ?t.parentId};
    final family = ItemFamily([
      for (final i in items)
        changed.contains(i.id) ? i.copyWith(status: ItemStatus.allotted) : i,
    ]);
    await _db.batch((b) {
      b.update(
        _db.items,
        ItemsCompanion(
          status: const Value(ItemStatus.allotted),
          updatedAt: Value(now),
        ),
        where: (i) => i.id.isIn(changed),
      );
      for (final p in parents) {
        final patch = planParentRederive(family, p, now: now);
        if (patch != null) _writePatch(b, p, patch, now);
      }
    });
    return targets.length;
  }

  /// Soft-deletes an item. Deleting a parent also deletes its sub-expenses.
  Future<void> deleteItem(String id) async {
    final now = _now();
    final family = await _family(id);
    final item = family[id];
    if (item == null) throw BudgetException('Item $id not found');

    final parentId = item.parentId;
    StatusPatch? parentPatch;
    if (parentId != null) {
      final remaining = family.childrenOf(parentId).where((c) => c.id != id);
      parentPatch = planParentRederive(
        ItemFamily([...remaining, ?family[parentId]]),
        parentId,
        now: now,
      );
    }

    await _db.batch((b) {
      b.update(
        _db.items,
        ItemsCompanion(deletedAt: Value(now), updatedAt: Value(now)),
        where: (i) =>
            (i.id.equals(id) | i.parentId.equals(id)) & i.deletedAt.isNull(),
      );
      if (parentId != null && parentPatch != null) {
        _writePatch(b, parentId, parentPatch, now);
      }
    });
  }

  Future<List<BudgetItem>> itemsFor(String monthId) =>
      _itemsQuery(monthId).get();

  Stream<List<BudgetItem>> watchItems(String monthId) =>
      _itemsQuery(monthId).watch();

  Future<BudgetItem> item(String id) async {
    final item = await (_db.select(
      _db.items,
    )..where((i) => i.id.equals(id) & i.deletedAt.isNull())).getSingleOrNull();
    if (item == null) throw BudgetException('Item $id not found');
    return item;
  }

  Future<MonthTotals> totalsFor(String monthId) async {
    final (items, incomes, topUps, transfers) = await (
      itemsFor(monthId),
      incomesFor(monthId),
      topUpsFor(monthId),
      transfersFor(monthId),
    ).wait;
    return computeMonthTotals(
      items: items,
      incomes: incomes,
      topUps: topUps,
      transfers: transfers,
    );
  }

  // -------------------------------------------------------------- transfers

  /// Records money moved between two accounts in [monthId].
  Future<String> addTransfer({
    required String monthId,
    required String fromAccountId,
    required String toAccountId,
    required int amountCents,
    required DateTime transferredAt,
    String? note,
  }) async {
    _checkTransfer(fromAccountId, toAccountId, amountCents);
    final id = newId();
    await _db
        .into(_db.transfers)
        .insert(
          TransfersCompanion.insert(
            id: Value(id),
            monthId: monthId,
            fromAccountId: fromAccountId,
            toAccountId: toAccountId,
            amountCents: amountCents,
            transferredAt: transferredAt,
            note: Value(_cleanNote(note)),
          ),
        );
    return id;
  }

  Future<void> updateTransfer(
    String id, {
    required String fromAccountId,
    required String toAccountId,
    required int amountCents,
    required DateTime transferredAt,
    String? note,
  }) async {
    _checkTransfer(fromAccountId, toAccountId, amountCents);
    final updated =
        await (_db.update(
          _db.transfers,
        )..where((t) => t.id.equals(id) & t.deletedAt.isNull())).write(
          TransfersCompanion(
            fromAccountId: Value(fromAccountId),
            toAccountId: Value(toAccountId),
            amountCents: Value(amountCents),
            transferredAt: Value(transferredAt),
            note: Value(_cleanNote(note)),
            updatedAt: Value(_now()),
          ),
        );
    if (updated == 0) throw BudgetException('Transfer $id not found');
  }

  Future<void> deleteTransfer(String id) async {
    final now = _now();
    await (_db.update(_db.transfers)..where((t) => t.id.equals(id))).write(
      TransfersCompanion(deletedAt: Value(now), updatedAt: Value(now)),
    );
  }

  SimpleSelectStatement<$TransfersTable, Transfer> _transfersQuery(
    String monthId,
  ) => _db.select(_db.transfers)
    ..where((t) => t.monthId.equals(monthId) & t.deletedAt.isNull())
    ..orderBy([(t) => OrderingTerm(expression: t.transferredAt)]);

  Future<List<Transfer>> transfersFor(String monthId) =>
      _transfersQuery(monthId).get();

  Stream<List<Transfer>> watchTransfers(String monthId) =>
      _transfersQuery(monthId).watch();

  void _checkTransfer(String from, String to, int cents) {
    if (from == to) {
      throw BudgetException('Choose two different accounts');
    }
    if (cents <= 0) throw BudgetException('Enter an amount above zero');
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

  /// One query: the item, its children, its parent and its siblings.
  Future<ItemFamily> _family(String id) async {
    final rows = await _db
        .customSelect(
          'SELECT * FROM items WHERE deleted_at IS NULL AND ('
          '  id = ?1 OR parent_id = ?1'
          '  OR id = (SELECT parent_id FROM items WHERE id = ?1)'
          '  OR parent_id = (SELECT parent_id FROM items WHERE id = ?1)'
          ')',
          variables: [Variable.withString(id)],
          readsFrom: {_db.items},
        )
        .get();
    return ItemFamily(rows.map((r) => _db.items.map(r.data)));
  }

  void _writePatch(Batch b, String id, StatusPatch patch, DateTime now) {
    b.update(
      _db.items,
      ItemsCompanion(
        status: Value(patch.status),
        paidAt: Value(patch.paidAt),
        // Unpaid items have no "paid from".
        paidFromAccountId: patch.status == ItemStatus.paid
            ? const Value.absent()
            : const Value(null),
        updatedAt: Value(now),
      ),
      where: (i) => i.id.equals(id),
    );
  }

  /// Stand-in for a just-inserted sub-expense when planning the cascade.
  BudgetItem _placeholderItem(
    String id,
    String monthId,
    String parentId,
    DateTime now,
  ) => BudgetItem(
    id: id,
    updatedAt: now,
    monthId: monthId,
    parentId: parentId,
    name: '',
    amountCents: 0,
    kind: ItemKind.expense,
    status: ItemStatus.planned,
    sortOrder: 0,
    isCollection: false,
  );

  void _checkCollection(BudgetItem parent) {
    if (parent.parentId != null) {
      throw BudgetException('Sub-expenses cannot have sub-expenses');
    }
    if (!parent.isCollection) {
      throw BudgetException('“${parent.name}” is not a collection');
    }
  }

  /// New rows go last: seconds since epoch keep insertion order.
  int _nextSortOrder() => _now().millisecondsSinceEpoch ~/ 1000;

  void _checkAmount(int cents) {
    if (cents < 0) throw BudgetException('Amount cannot be negative');
  }

  void _checkDueDay(int? day) {
    if (day != null && (day < 1 || day > 31)) {
      throw BudgetException('Due day must be between 1 and 31');
    }
  }
}

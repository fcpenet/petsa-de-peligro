import 'package:drift/drift.dart';

import '../../../core/db/database.dart';
import '../../budget/data/budget_repository.dart';
import '../domain/month_template.dart';

/// Saves month layouts as templates and starts new months from them.
class TemplateRepository {
  TemplateRepository(this._db, {DateTime Function()? clock})
    : _now = clock ?? DateTime.now;

  final AppDatabase _db;
  final DateTime Function() _now;

  late final _budget = BudgetRepository(_db, clock: _now);

  SimpleSelectStatement<$TemplatesTable, TemplateRow> _query() =>
      _db.select(_db.templates)
        ..where((t) => t.deletedAt.isNull())
        ..orderBy([(t) => OrderingTerm(expression: t.name)]);

  Future<List<TemplateRow>> templates() => _query().get();

  Stream<List<TemplateRow>> watchTemplates() => _query().watch();

  Future<TemplateRow?> template(String id) => (_db.select(
    _db.templates,
  )..where((t) => t.id.equals(id) & t.deletedAt.isNull())).getSingleOrNull();

  Future<TemplateRow?> _byName(String name) =>
      (_db.select(_db.templates)..where(
            (t) =>
                t.name.lower().equals(name.toLowerCase()) &
                t.deletedAt.isNull(),
          ))
          .getSingleOrNull();

  /// Saves a template built in the editor. Without [id] it creates one.
  /// Unlike [saveFromMonth], a name already used by another template is an
  /// error rather than a replacement. Returns the template id.
  Future<String> save({
    String? id,
    required String name,
    required MonthTemplate template,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw BudgetException('Template needs a name');
    if (template.isEmpty) {
      throw BudgetException('Add at least one expense or income');
    }
    final clash = await _byName(trimmed);
    if (clash != null && clash.id != id) {
      throw BudgetException(
        'There is already a template named “${clash.name}”',
      );
    }
    if (id != null) {
      final updated =
          await (_db.update(
            _db.templates,
          )..where((t) => t.id.equals(id) & t.deletedAt.isNull())).write(
            TemplatesCompanion(
              name: Value(trimmed),
              payload: Value(template.encode()),
              updatedAt: Value(_now()),
            ),
          );
      if (updated == 0) throw BudgetException('Template not found');
      return id;
    }
    return _insert(trimmed, template);
  }

  Future<String> _insert(String name, MonthTemplate template) async {
    final id = newId();
    await _db
        .into(_db.templates)
        .insert(
          TemplatesCompanion.insert(
            id: Value(id),
            name: name,
            payload: template.encode(),
          ),
        );
    return id;
  }

  /// Saves [monthId]'s layout under [name]. A template with the same name
  /// (ignoring case) is replaced. Returns the template id.
  Future<String> saveFromMonth({
    required String monthId,
    required String name,
    bool includeSubExpenses = false,
    bool includeIncomes = true,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw BudgetException('Template needs a name');

    final (items, incomes, existing) = await (
      _budget.itemsFor(monthId),
      _budget.incomesFor(monthId),
      _byName(trimmed),
    ).wait;

    final template = templateFromMonth(
      items: items,
      incomes: incomes,
      includeSubExpenses: includeSubExpenses,
      includeIncomes: includeIncomes,
    );
    if (template.isEmpty) {
      throw BudgetException('This month has nothing to save');
    }

    if (existing != null) {
      await (_db.update(
        _db.templates,
      )..where((t) => t.id.equals(existing.id))).write(
        TemplatesCompanion(
          name: Value(trimmed),
          payload: Value(template.encode()),
          updatedAt: Value(_now()),
        ),
      );
      return existing.id;
    }
    return _insert(trimmed, template);
  }

  Future<void> delete(String id) async {
    final now = _now();
    await (_db.update(_db.templates)..where((t) => t.id.equals(id))).write(
      TemplatesCompanion(deletedAt: Value(now), updatedAt: Value(now)),
    );
  }

  /// Fills an empty month from a saved template. Returns the number of
  /// items created.
  Future<int> applyTemplate({
    required String templateId,
    required String monthId,
  }) async {
    final row =
        await (_db.select(_db.templates)
              ..where((t) => t.id.equals(templateId) & t.deletedAt.isNull()))
            .getSingleOrNull();
    if (row == null) throw BudgetException('Template not found');
    return _apply(MonthTemplate.decode(row.payload), monthId);
  }

  /// Fills an empty month with another month's layout, without saving a
  /// template. Returns the number of items created (0 if the source month is
  /// empty or doesn't exist).
  Future<int> copyMonth({
    required String fromYearMonth,
    required String toMonthId,
    bool includeSubExpenses = false,
  }) async {
    final from = await _budget.findMonth(fromYearMonth);
    if (from == null) return 0;
    final (items, incomes) = await (
      _budget.itemsFor(from.id),
      _budget.incomesFor(from.id),
    ).wait;
    final template = templateFromMonth(
      items: items,
      incomes: incomes,
      includeSubExpenses: includeSubExpenses,
    );
    if (template.isEmpty) return 0;
    return _apply(template, toMonthId);
  }

  /// One read to check the month and accounts, then one atomic batch.
  Future<int> _apply(MonthTemplate template, String monthId) async {
    final (counts, accounts) = await (
      _db
          .customSelect(
            'SELECT '
            '(SELECT COUNT(*) FROM items WHERE month_id = ?1 '
            'AND deleted_at IS NULL) AS items, '
            '(SELECT COUNT(*) FROM incomes WHERE month_id = ?1 '
            'AND deleted_at IS NULL) AS incomes',
            variables: [Variable.withString(monthId)],
            readsFrom: {_db.items, _db.incomes},
          )
          .getSingle(),
      (_db.select(
        _db.accounts,
      )..where((a) => a.deletedAt.isNull() & a.archived.equals(false))).get(),
    ).wait;
    if (counts.read<int>('items') > 0 || counts.read<int>('incomes') > 0) {
      throw BudgetException(
        'This month already has entries. Templates only fill empty months.',
      );
    }

    // Accounts that were archived or removed since the template was saved.
    final usable = {for (final a in accounts) a.id};
    String? account(String? id) => usable.contains(id) ? id : null;

    var order = 0;
    var created = 0;
    await _db.batch((b) {
      ItemsCompanion row(TemplateItem t, {String? parentId}) {
        created++;
        return ItemsCompanion.insert(
          id: Value(newId()),
          monthId: monthId,
          parentId: Value(parentId),
          accountId: Value(account(t.accountId)),
          name: t.name,
          amountCents: t.amountCents,
          kind: Value(t.kind),
          dueDay: Value(t.dueDay),
          note: Value(t.note),
          isCollection: Value(t.isCollection && parentId == null),
          sortOrder: Value(order++),
        );
      }

      for (final top in template.items) {
        final parent = row(top);
        b.insert(_db.items, parent);
        for (final child in top.children) {
          b.insert(_db.items, row(child, parentId: parent.id.value));
        }
      }
      for (final income in template.incomes) {
        b.insert(
          _db.incomes,
          IncomesCompanion.insert(
            id: Value(newId()),
            monthId: monthId,
            name: income.name,
            amountCents: income.amountCents,
            accountId: Value(account(income.accountId)),
            sortOrder: Value(order++),
          ),
        );
      }
    });
    return created;
  }
}

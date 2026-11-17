import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();
String newId() => _uuid.v4();

enum AccountType { cash, bank, ewallet, creditCard }

/// Savings (Date fund, Travel fund) and debt (loans) are tracked separately
/// from spending so reports don't treat them as expenses.
enum ItemKind { expense, savings, debt }

/// Only two states by design: money is either set aside (allotted) or paid.
enum ItemStatus { allotted, paid }

/// Every syncable row gets a UUID, an update timestamp and a soft-delete
/// marker so cloud sync can be added later without a schema rewrite.
mixin SyncColumns on Table {
  TextColumn get id => text().clientDefault(newId)();
  DateTimeColumn get updatedAt => dateTime().clientDefault(DateTime.now)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// A bank or wallet provider: UB, RCBC, BPI, GCash, Maya.
class Institutions extends Table with SyncColumns {
  TextColumn get name => text().withLength(min: 1, max: 60)();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

/// Where money sits or is charged: a savings account, wallet, cash, or card.
class Accounts extends Table with SyncColumns {
  TextColumn get institutionId =>
      text().nullable().references(Institutions, #id)();
  TextColumn get name => text().withLength(min: 1, max: 60)();
  TextColumn get type => textEnum<AccountType>()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
}

/// A budgeting period, keyed by 'YYYY-MM'.
class Months extends Table with SyncColumns {
  TextColumn get yearMonth => text().withLength(min: 7, max: 7).unique()();
}

/// Money coming in for a month: salary, 13th month, SL conversion.
/// [amountCents] is the *expected* amount; what actually arrived is the sum
/// of its [IncomeTopUps].
class Incomes extends Table with SyncColumns {
  TextColumn get monthId => text().references(Months, #id)();
  TextColumn get name => text().withLength(min: 1, max: 80)();
  IntColumn get amountCents => integer()();
  TextColumn get accountId => text().nullable().references(Accounts, #id)();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

/// Part of an income that actually arrived, e.g. the 15th and 30th payouts
/// of a salary.
@DataClassName('TopUp')
class IncomeTopUps extends Table with SyncColumns {
  TextColumn get incomeId => text().references(Incomes, #id)();
  IntColumn get amountCents => integer()();
  DateTimeColumn get receivedAt => dateTime()();
  TextColumn get note => text().nullable()();
}

/// An expense line, listed under its account. A row with [parentId] is a
/// sub-expense of a collection. Only one level of nesting is allowed
/// (enforced by BudgetRepository).
///
/// A collection ([isCollection], e.g. Misc) holds sub-expenses that may each
/// be paid from a different account; a sub-expense without an account uses
/// the collection's. The collection's [amountCents] is a budget cap and its
/// [status] is derived from its sub-expenses, kept in sync by
/// BudgetRepository.
@DataClassName('BudgetItem')
class Items extends Table with SyncColumns {
  TextColumn get monthId => text().references(Months, #id)();
  TextColumn get parentId => text().nullable().references(Items, #id)();
  TextColumn get accountId => text().nullable().references(Accounts, #id)();
  TextColumn get name => text().withLength(min: 1, max: 80)();
  IntColumn get amountCents => integer()();
  TextColumn get kind =>
      textEnum<ItemKind>().withDefault(Constant(ItemKind.expense.name))();
  TextColumn get status =>
      textEnum<ItemStatus>().withDefault(Constant(ItemStatus.allotted.name))();
  DateTimeColumn get paidAt => dateTime().nullable()();
  IntColumn get dueDay => integer().nullable()();
  TextColumn get note => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isCollection => boolean().withDefault(const Constant(false))();
}

/// A reusable month layout. The structure is stored as JSON (see
/// `MonthTemplate`) so it can evolve without schema changes.
@DataClassName('TemplateRow')
class Templates extends Table with SyncColumns {
  TextColumn get name => text().withLength(min: 1, max: 80)();
  TextColumn get payload => text()();
}

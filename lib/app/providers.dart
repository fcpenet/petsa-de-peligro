import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/db/database.dart';
import '../features/accounts/data/account_repository.dart';
import '../features/budget/data/budget_repository.dart';
import '../features/templates/data/template_repository.dart';

/// The app database. Overridden in tests with an in-memory database.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase.open();
  ref.onDispose(db.close);
  return db;
});

final budgetRepositoryProvider = Provider<BudgetRepository>(
  (ref) => BudgetRepository(ref.watch(databaseProvider)),
);

final accountRepositoryProvider = Provider<AccountRepository>(
  (ref) => AccountRepository(ref.watch(databaseProvider)),
);

/// All accounts, archived included (the sheet decides what to show).
final accountsProvider = StreamProvider<List<Account>>(
  (ref) =>
      ref.watch(accountRepositoryProvider).watchAccounts(includeArchived: true),
);

/// The month row for 'YYYY-MM', created on first visit.
final monthProvider = FutureProvider.family<Month, String>(
  (ref, yearMonth) =>
      ref.watch(budgetRepositoryProvider).ensureMonth(yearMonth),
);

final itemsProvider = StreamProvider.family<List<BudgetItem>, String>(
  (ref, monthId) => ref.watch(budgetRepositoryProvider).watchItems(monthId),
);

final topUpsProvider = StreamProvider.family<List<TopUp>, String>(
  (ref, monthId) => ref.watch(budgetRepositoryProvider).watchTopUps(monthId),
);

final transfersProvider = StreamProvider.family<List<Transfer>, String>(
  (ref, monthId) => ref.watch(budgetRepositoryProvider).watchTransfers(monthId),
);

final incomesProvider = StreamProvider.family<List<Income>, String>(
  (ref, monthId) => ref.watch(budgetRepositoryProvider).watchIncomes(monthId),
);

final templateRepositoryProvider = Provider<TemplateRepository>(
  (ref) => TemplateRepository(ref.watch(databaseProvider)),
);

final templatesProvider = StreamProvider<List<TemplateRow>>(
  (ref) => ref.watch(templateRepositoryProvider).watchTemplates(),
);

final institutionsProvider = StreamProvider<List<Institution>>(
  (ref) => ref.watch(accountRepositoryProvider).watchInstitutions(),
);

/// Statuses the Budget list shows. Kept while switching months.
class ShownStatuses extends Notifier<Set<ItemStatus>> {
  @override
  Set<ItemStatus> build() => ItemStatus.values.toSet();

  void toggle(ItemStatus status) => state = state.contains(status)
      ? ({...state}..remove(status))
      : {...state, status};

  void showAll() => state = ItemStatus.values.toSet();
}

final shownStatusesProvider = NotifierProvider<ShownStatuses, Set<ItemStatus>>(
  ShownStatuses.new,
);

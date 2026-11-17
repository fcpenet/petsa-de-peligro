import '../../helpers/test_db.dart';
import 'budget_repository_suite.dart';

void main() => budgetRepositoryTests(() async => createTestDatabase());

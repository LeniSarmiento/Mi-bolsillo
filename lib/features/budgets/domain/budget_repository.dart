import 'package:mi_bolsillo/features/budgets/domain/budget_item.dart';

/// Abstract repository contract for category budgets.
abstract class BudgetRepository {
  Future<List<BudgetItem>> getBudgets();
  Future<BudgetItem> addBudget(BudgetItem budget);
  Future<BudgetItem> updateBudget(BudgetItem budget);
  Future<void> deleteBudget(String id);
  Future<void> clearAll();
  Future<void> resetToMockDefaults();
}

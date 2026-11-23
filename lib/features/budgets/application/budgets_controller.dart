import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_bolsillo/app/providers.dart';
import 'package:mi_bolsillo/features/budgets/domain/budget_item.dart';
import 'package:mi_bolsillo/features/transactions/application/transactions_controller.dart';
import 'package:mi_bolsillo/features/transactions/domain/transaction_item.dart';

class BudgetsState {
  const BudgetsState({this.items = const [], this.isLoading = false});

  final List<BudgetItem> items;
  final bool isLoading;

  BudgetsState copyWith({List<BudgetItem>? items, bool? isLoading}) {
    return BudgetsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class BudgetsController extends Notifier<BudgetsState> {
  @override
  BudgetsState build() {
    Future.microtask(loadBudgets);
    return const BudgetsState(isLoading: true);
  }

  Future<void> loadBudgets() async {
    state = state.copyWith(isLoading: true);
    final items = await ref.read(budgetRepositoryProvider).getBudgets();
    state = BudgetsState(items: items, isLoading: false);
  }

  Future<void> saveBudget({
    required String category,
    required int limitCop,
    required BudgetPeriod period,
    required bool alertAt80,
    required bool alertAt100,
  }) async {
    final repo = ref.read(budgetRepositoryProvider);
    await repo.addBudget(
      BudgetItem(
        id: '',
        category: category,
        limitCop: limitCop,
        period: period,
        alertAt80: alertAt80,
        alertAt100: alertAt100,
      ),
    );
    final updated = await repo.getBudgets();
    state = state.copyWith(items: updated);
  }

  Future<void> deleteBudget(String id) async {
    final repo = ref.read(budgetRepositoryProvider);
    await repo.deleteBudget(id);
    final updated = await repo.getBudgets();
    state = state.copyWith(items: updated);
  }

  Future<void> resetDefaults() async {
    final repo = ref.read(budgetRepositoryProvider);
    await repo.resetToMockDefaults();
    final updated = await repo.getBudgets();
    state = BudgetsState(items: updated, isLoading: false);
  }
}

final budgetsControllerProvider =
    NotifierProvider<BudgetsController, BudgetsState>(BudgetsController.new);

/// Combines budgets with live expense totals per category.
final budgetProgressListProvider = Provider<List<BudgetProgress>>((ref) {
  final budgets = ref.watch(budgetsControllerProvider).items;
  final transactions = ref.watch(transactionsControllerProvider).items;

  final spentByCategory = <String, int>{};
  for (final tx in transactions) {
    if (tx.type == TransactionType.expense) {
      spentByCategory[tx.categoryOrOrigin] =
          (spentByCategory[tx.categoryOrOrigin] ?? 0) + tx.amountCop;
    }
  }

  return budgets
      .map(
        (b) => BudgetProgress(
          budget: b,
          spentCop: spentByCategory[b.category] ?? 0,
        ),
      )
      .toList();
});

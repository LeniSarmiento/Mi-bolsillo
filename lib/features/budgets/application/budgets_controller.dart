import '../../profile/application/settings_controller.dart';

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
    String? id,
    required String category,
    required int limitCop,
    required BudgetPeriod period,
    required bool alertAt80,
    required bool alertAt100,
  }) async {
    final repo = ref.read(budgetRepositoryProvider);
    final budget = BudgetItem(
      id: id ?? '',
      category: category,
      limitCop: limitCop,
      period: period,
      alertAt80: alertAt80,
      alertAt100: alertAt100,
    );
    if (id == null) {
      await repo.addBudget(budget);
    } else {
      await repo.updateBudget(budget);
    }
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

  final today = DateTime.now();
  final warnings = ref.watch(
    settingsControllerProvider.select((s) => s.budget80AlertEnabled),
  );
  return budgets
      .map(
        (b) => budgetProgress(b, transactions, today, warningEnabled: warnings),
      )
      .toList();
});

BudgetProgress budgetProgress(
  BudgetItem b,
  Iterable<TransactionItem> movements,
  DateTime today, {
  bool warningEnabled = true,
}) {
  final start = switch (b.period) {
    BudgetPeriod.monthly => DateTime(today.year, today.month),
    BudgetPeriod.weekly => DateTime(
      today.year,
      today.month,
      today.day - today.weekday + 1,
    ),
    BudgetPeriod.biweekly => DateTime(
      today.year,
      today.month,
      today.day < 16 ? 1 : 16,
    ),
  };
  final end = DateTime(today.year, today.month, today.day + 1);
  final spent = movements
      .where(
        (m) =>
            m.status == MovementStatus.confirmed &&
            m.type == TransactionType.expense &&
            m.categoryOrOrigin == b.category &&
            !m.date.isBefore(start) &&
            m.date.isBefore(end),
      )
      .fold<int>(0, (s, m) => s + m.amountCop);
  return BudgetProgress(
    budget: b,
    spentCop: spent,
    warningEnabled: warningEnabled,
  );
}

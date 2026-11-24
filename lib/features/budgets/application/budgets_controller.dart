import '../../profile/application/settings_controller.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_bolsillo/app/providers.dart';
import 'package:mi_bolsillo/features/budgets/domain/budget_item.dart';
import 'package:mi_bolsillo/features/transactions/application/transactions_controller.dart';
import 'package:mi_bolsillo/features/transactions/domain/transaction_item.dart';
import 'package:mi_bolsillo/core/errors/finance_failure.dart';

class BudgetsState {
  const BudgetsState({
    this.items = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.isDeleting = false,
    this.errorMessage,
  });

  final List<BudgetItem> items;
  final bool isLoading;
  final bool isSaving;
  final bool isDeleting;
  final String? errorMessage;

  BudgetsState copyWith({
    List<BudgetItem>? items,
    bool? isLoading,
    bool? isSaving,
    bool? isDeleting,
    String? errorMessage,
    bool clearError = false,
  }) {
    return BudgetsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      isDeleting: isDeleting ?? this.isDeleting,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
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
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final items = await ref.read(budgetRepositoryProvider).getBudgets();
      state = BudgetsState(items: items, isLoading: false);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: FinanceFailure.from(error).message,
      );
    }
  }

  Future<void> saveBudget({
    String? id,
    required String category,
    required int limitCop,
    required BudgetPeriod period,
    required bool alertAt80,
    required bool alertAt100,
  }) async {
    if (state.isSaving) return;
    state = state.copyWith(isSaving: true, clearError: true);
    final repo = ref.read(budgetRepositoryProvider);
    final budget = BudgetItem(
      id: id ?? '',
      category: category,
      limitCop: limitCop,
      period: period,
      alertAt80: alertAt80,
      alertAt100: alertAt100,
    );
    try {
      if (id == null) {
        await repo.addBudget(budget);
      } else {
        await repo.updateBudget(budget);
      }
      final updated = await repo.getBudgets();
      state = state.copyWith(items: updated, isSaving: false);
      final settings = await ref.read(settingsRepositoryProvider).getSettings();
      await ref
          .read(budgetAlertCoordinatorProvider)
          .evaluate(enabled: settings.budget80AlertEnabled);
    } catch (error, stackTrace) {
      final failure = FinanceFailure.from(error);
      state = state.copyWith(isSaving: false, errorMessage: failure.message);
      Error.throwWithStackTrace(failure, stackTrace);
    }
  }

  Future<void> deleteBudget(String id) async {
    if (state.isDeleting) return;
    state = state.copyWith(isDeleting: true, clearError: true);
    final repo = ref.read(budgetRepositoryProvider);
    try {
      await repo.deleteBudget(id);
      final updated = await repo.getBudgets();
      state = state.copyWith(items: updated, isDeleting: false);
    } catch (error, stackTrace) {
      final failure = FinanceFailure.from(error);
      state = state.copyWith(isDeleting: false, errorMessage: failure.message);
      Error.throwWithStackTrace(failure, stackTrace);
    }
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

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_bolsillo/app/providers.dart';
import 'package:mi_bolsillo/features/income/application/income_controller.dart';
import 'package:mi_bolsillo/features/transactions/domain/transaction_item.dart';
import 'package:mi_bolsillo/core/errors/finance_failure.dart';

class TransactionsState {
  const TransactionsState({
    this.items = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.isDeleting = false,
    this.errorMessage,
  });

  final List<TransactionItem> items;
  final bool isLoading;
  final bool isSaving;
  final bool isDeleting;
  final String? errorMessage;

  TransactionsState copyWith({
    List<TransactionItem>? items,
    bool? isLoading,
    bool? isSaving,
    bool? isDeleting,
    String? errorMessage,
    bool clearError = false,
  }) {
    return TransactionsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      isDeleting: isDeleting ?? this.isDeleting,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class TransactionsController extends Notifier<TransactionsState> {
  @override
  TransactionsState build() {
    Future.microtask(loadTransactions);
    return const TransactionsState(isLoading: true);
  }

  Future<void> loadTransactions() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final items = await ref
          .read(transactionRepositoryProvider)
          .getTransactions();
      state = TransactionsState(items: items, isLoading: false);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: FinanceFailure.from(error).message,
      );
    }
  }

  Future<void> addExpense({
    required int amountCop,
    required String description,
    required String category,
    required DateTime date,
    required String paymentMethod,
    required RecurrenceFrequency recurrence,
    String note = '',
    bool isAutomatic = false,
  }) async {
    if (state.isSaving) return;
    state = state.copyWith(isSaving: true, clearError: true);
    final repo = ref.read(transactionRepositoryProvider);
    try {
      await repo.addTransaction(
        TransactionItem(
          id: '',
          description: description,
          amountCop: amountCop,
          type: TransactionType.expense,
          categoryOrOrigin: category,
          date: date,
          paymentMethod: paymentMethod,
          isAutomatic: isAutomatic,
          recurrence: recurrence,
          note: note,
        ),
      );
      final updated = await repo.getTransactions();
      state = state.copyWith(items: updated, isSaving: false);
      await _evaluateBudgetAlerts();
    } catch (error, stackTrace) {
      final failure = FinanceFailure.from(error);
      state = state.copyWith(isSaving: false, errorMessage: failure.message);
      Error.throwWithStackTrace(failure, stackTrace);
    }
  }

  Future<void> updateTransaction(TransactionItem item) async {
    if (state.isSaving) return;
    state = state.copyWith(isSaving: true, clearError: true);
    final repo = ref.read(transactionRepositoryProvider);
    try {
      await repo.updateTransaction(item);
      final updated = await repo.getTransactions();
      state = state.copyWith(items: updated, isSaving: false);
      await _evaluateBudgetAlerts();
    } catch (error, stackTrace) {
      final failure = FinanceFailure.from(error);
      state = state.copyWith(isSaving: false, errorMessage: failure.message);
      Error.throwWithStackTrace(failure, stackTrace);
    }
  }

  Future<void> deleteTransaction(String id) async {
    if (state.isDeleting) return;
    state = state.copyWith(isDeleting: true, clearError: true);
    final repo = ref.read(transactionRepositoryProvider);
    try {
      await repo.deleteTransaction(id);
      final updated = await repo.getTransactions();
      state = state.copyWith(items: updated, isDeleting: false);
    } catch (error, stackTrace) {
      final failure = FinanceFailure.from(error);
      state = state.copyWith(isDeleting: false, errorMessage: failure.message);
      Error.throwWithStackTrace(failure, stackTrace);
    }
  }

  Future<void> clearAll() async {
    await ref.read(transactionRepositoryProvider).clearAll();
    state = const TransactionsState(items: [], isLoading: false);
  }

  Future<void> resetDefaults() async {
    final repo = ref.read(transactionRepositoryProvider);
    await repo.resetToMockDefaults();
    final updated = await repo.getTransactions();
    state = TransactionsState(items: updated, isLoading: false);
  }

  Future<void> _evaluateBudgetAlerts() async {
    final settings = await ref.read(settingsRepositoryProvider).getSettings();
    await ref
        .read(budgetAlertCoordinatorProvider)
        .evaluate(enabled: settings.budget80AlertEnabled);
  }
}

final transactionsControllerProvider =
    NotifierProvider<TransactionsController, TransactionsState>(
      TransactionsController.new,
    );

/// Combines regular movements, base monthly income (aligned to Settings),
/// and confirmed additional incomes into a unified chronological ledger.
final combinedMovementsProvider = Provider<List<TransactionItem>>((ref) {
  final txItems = ref.watch(transactionsControllerProvider).items;
  final incomes = ref.watch(incomeControllerProvider).items;
  final additionalAsTx = incomes.map(
    (inc) => TransactionItem(
      id: 'linked-${inc.id}',
      linkedIncomeId: inc.id,
      description: inc.reason,
      amountCop: inc.amountCop,
      type: TransactionType.additionalIncome,
      categoryOrOrigin: inc.origin,
      date: inc.date,
      paymentMethod: inc.receptionMethod,
      isAutomatic: false,
      recurrence: inc.recurrence,
      note: inc.note,
    ),
  );

  final merged = [...txItems, ...additionalAsTx]
    ..sort((a, b) => b.date.compareTo(a.date));
  return merged;
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_bolsillo/app/providers.dart';
import 'package:mi_bolsillo/features/income/application/income_controller.dart';
import 'package:mi_bolsillo/features/profile/application/settings_controller.dart';
import 'package:mi_bolsillo/features/transactions/domain/transaction_item.dart';

class TransactionsState {
  const TransactionsState({this.items = const [], this.isLoading = false});

  final List<TransactionItem> items;
  final bool isLoading;

  TransactionsState copyWith({List<TransactionItem>? items, bool? isLoading}) {
    return TransactionsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
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
    state = state.copyWith(isLoading: true);
    final items = await ref
        .read(transactionRepositoryProvider)
        .getTransactions();
    state = TransactionsState(items: items, isLoading: false);
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
    final repo = ref.read(transactionRepositoryProvider);
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
    state = state.copyWith(items: updated);
  }

  Future<void> updateTransaction(TransactionItem item) async {
    final repo = ref.read(transactionRepositoryProvider);
    await repo.updateTransaction(item);
    final updated = await repo.getTransactions();
    state = state.copyWith(items: updated);
  }

  Future<void> deleteTransaction(String id) async {
    final repo = ref.read(transactionRepositoryProvider);
    await repo.deleteTransaction(id);
    final updated = await repo.getTransactions();
    state = state.copyWith(items: updated);
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
  final monthlyIncomeCop = ref.watch(
    settingsControllerProvider.select((s) => s.monthlyIncomeCop),
  );

  final adjustedTx = txItems.map((tx) {
    if (tx.type == TransactionType.baseIncome) {
      return tx.copyWith(amountCop: monthlyIncomeCop);
    }
    return tx;
  }).toList();

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

  final merged = [...adjustedTx, ...additionalAsTx]
    ..sort((a, b) => b.date.compareTo(a.date));
  return merged;
});

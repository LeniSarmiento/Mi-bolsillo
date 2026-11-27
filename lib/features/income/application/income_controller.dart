import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_bolsillo/app/providers.dart';
import 'package:mi_bolsillo/features/income/domain/additional_income.dart';
import 'package:mi_bolsillo/features/transactions/domain/transaction_item.dart';
import 'package:mi_bolsillo/core/errors/finance_failure.dart';

import '../../transactions/domain/recurrence_repository.dart';

class IncomeState {
  const IncomeState({
    this.items = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.isDeleting = false,
    this.errorMessage,
  });

  final List<AdditionalIncome> items;
  final bool isLoading;
  final bool isSaving;
  final bool isDeleting;
  final String? errorMessage;

  int get totalCop => items.fold(0, (sum, item) => sum + item.amountCop);

  IncomeState copyWith({
    List<AdditionalIncome>? items,
    bool? isLoading,
    bool? isSaving,
    bool? isDeleting,
    String? errorMessage,
    bool clearError = false,
  }) {
    return IncomeState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      isDeleting: isDeleting ?? this.isDeleting,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class IncomeController extends Notifier<IncomeState> {
  @override
  IncomeState build() {
    Future.microtask(loadIncomes);
    return const IncomeState(isLoading: true);
  }

  Future<void> loadIncomes() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final items = await ref
          .read(incomeRepositoryProvider)
          .getAdditionalIncomes();
      state = state.copyWith(items: items, isLoading: false);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: FinanceFailure.from(error).message,
      );
    }
  }

  Future<void> addIncome({
    required int amountCop,
    required String reason,
    required String origin,
    required DateTime date,
    required String receptionMethod,
    required String note,
    required RecurrenceFrequency recurrence,
  }) async {
    if (state.isSaving || state.isDeleting) return;
    state = state.copyWith(isSaving: true, clearError: true);
    final repo = ref.read(incomeRepositoryProvider);
    try {
      await repo.addAdditionalIncome(
        AdditionalIncome(
          id: '',
          amountCop: amountCop,
          reason: reason,
          origin: origin,
          date: date,
          receptionMethod: receptionMethod,
          note: note,
          recurrence: recurrence,
        ),
      );
      await loadIncomes();
      state = state.copyWith(isSaving: false);
    } catch (error, stackTrace) {
      final failure = FinanceFailure.from(error);
      state = state.copyWith(isSaving: false, errorMessage: failure.message);
      Error.throwWithStackTrace(failure, stackTrace);
    }
  }

  Future<void> updateIncome(
    AdditionalIncome income, {
    bool futureOnly = false,
  }) async {
    if (state.isSaving || state.isDeleting) return;
    state = state.copyWith(isSaving: true, clearError: true);
    final repo = ref.read(incomeRepositoryProvider);
    try {
      if (futureOnly) {
        await (repo as RecurrenceRepository<AdditionalIncome>).reviseFuture(
          income,
        );
      } else {
        await repo.updateAdditionalIncome(income);
      }
      await loadIncomes();
      state = state.copyWith(isSaving: false);
    } catch (error, stackTrace) {
      final failure = FinanceFailure.from(error);
      state = state.copyWith(isSaving: false, errorMessage: failure.message);
      Error.throwWithStackTrace(failure, stackTrace);
    }
  }

  Future<void> deleteIncome(String id) async {
    if (state.isSaving || state.isDeleting) return;
    state = state.copyWith(isDeleting: true, clearError: true);
    final repo = ref.read(incomeRepositoryProvider);
    try {
      await repo.deleteAdditionalIncome(id);
      await loadIncomes();
      state = state.copyWith(isDeleting: false);
    } catch (error, stackTrace) {
      final failure = FinanceFailure.from(error);
      state = state.copyWith(isDeleting: false, errorMessage: failure.message);
      Error.throwWithStackTrace(failure, stackTrace);
    }
  }

  Future<void> stopFuture(String id) async {
    if (state.isSaving || state.isDeleting) return;
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      await (ref.read(
        incomeRepositoryProvider,
      ) as RecurrenceRepository<AdditionalIncome>).stopFuture(id);
      await loadIncomes();
      state = state.copyWith(isSaving: false);
    } catch (error, stackTrace) {
      final failure = FinanceFailure.from(error);
      state = state.copyWith(isSaving: false, errorMessage: failure.message);
      Error.throwWithStackTrace(failure, stackTrace);
    }
  }

  Future<void> clearAll() async {
    await ref.read(incomeRepositoryProvider).clearAll();
    state = const IncomeState(items: [], isLoading: false);
  }

  Future<void> resetDefaults() async {
    final repo = ref.read(incomeRepositoryProvider);
    await repo.resetToMockDefaults();
    final updated = await repo.getAdditionalIncomes();
    state = IncomeState(items: updated, isLoading: false);
  }
}

final incomeControllerProvider =
    NotifierProvider<IncomeController, IncomeState>(IncomeController.new);

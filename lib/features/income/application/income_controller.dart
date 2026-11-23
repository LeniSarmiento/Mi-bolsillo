import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_bolsillo/app/providers.dart';
import 'package:mi_bolsillo/features/income/domain/additional_income.dart';
import 'package:mi_bolsillo/features/transactions/domain/transaction_item.dart';

class IncomeState {
  const IncomeState({this.items = const [], this.isLoading = false});

  final List<AdditionalIncome> items;
  final bool isLoading;

  int get totalCop => items.fold(0, (sum, item) => sum + item.amountCop);

  IncomeState copyWith({List<AdditionalIncome>? items, bool? isLoading}) {
    return IncomeState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
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
    state = state.copyWith(isLoading: true);
    final items = await ref
        .read(incomeRepositoryProvider)
        .getAdditionalIncomes();
    state = IncomeState(items: items, isLoading: false);
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
    final repo = ref.read(incomeRepositoryProvider);
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
    final updated = await repo.getAdditionalIncomes();
    state = state.copyWith(items: updated);
  }

  Future<void> updateIncome(AdditionalIncome income) async {
    final repo = ref.read(incomeRepositoryProvider);
    await repo.updateAdditionalIncome(income);
    final updated = await repo.getAdditionalIncomes();
    state = state.copyWith(items: updated);
  }

  Future<void> deleteIncome(String id) async {
    final repo = ref.read(incomeRepositoryProvider);
    await repo.deleteAdditionalIncome(id);
    final updated = await repo.getAdditionalIncomes();
    state = state.copyWith(items: updated);
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

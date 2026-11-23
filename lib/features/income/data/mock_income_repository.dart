import 'package:mi_bolsillo/features/income/domain/additional_income.dart';
import 'package:mi_bolsillo/features/income/domain/income_repository.dart';
import 'package:mi_bolsillo/features/transactions/domain/transaction_item.dart';

/// In-memory mock repository seeded with +$480.000 COP additional incomes:
/// Horas extras (+$180.000) and Trabajo independiente (+$300.000).
class MockIncomeRepository implements IncomeRepository {
  MockIncomeRepository() : _items = _seedDefaults();

  List<AdditionalIncome> _items;
  int _counter = 100;

  static List<AdditionalIncome> _seedDefaults() {
    final now = DateTime.now();
    return [
      AdditionalIncome(
        id: 'inc-1',
        amountCop: 300000,
        reason: 'Trabajo independiente',
        origin: 'Independiente',
        date: DateTime(now.year, now.month, now.day, 10, 30),
        receptionMethod: 'Nequi',
        note: 'Diseño de marca para cliente local',
        recurrence: RecurrenceFrequency.biweekly,
      ),
      AdditionalIncome(
        id: 'inc-2',
        amountCop: 180000,
        reason: 'Horas extras',
        origin: 'Horas extras',
        date: DateTime(
          now.year,
          now.month,
          now.day,
          17,
          0,
        ).subtract(const Duration(days: 1)),
        receptionMethod: 'Transferencia',
        note: 'Cierre operativo de fin de semana',
        recurrence: RecurrenceFrequency.monthly,
      ),
    ];
  }

  @override
  Future<List<AdditionalIncome>> getAdditionalIncomes() async {
    final copy = List<AdditionalIncome>.from(_items)
      ..sort((a, b) => b.date.compareTo(a.date));
    return copy;
  }

  @override
  Future<AdditionalIncome> addAdditionalIncome(AdditionalIncome income) async {
    final created = income.id.isEmpty
        ? income.copyWith(id: 'inc-${++_counter}')
        : income;
    _items = [created, ..._items];
    return created;
  }

  @override
  Future<AdditionalIncome> updateAdditionalIncome(
    AdditionalIncome income,
  ) async {
    _items = _items.map((e) => e.id == income.id ? income : e).toList();
    return income;
  }

  @override
  Future<void> deleteAdditionalIncome(String id) async {
    _items = _items.where((e) => e.id != id).toList();
  }

  @override
  Future<void> clearAll() async {
    _items = [];
  }

  @override
  Future<void> resetToMockDefaults() async {
    _items = _seedDefaults();
  }
}

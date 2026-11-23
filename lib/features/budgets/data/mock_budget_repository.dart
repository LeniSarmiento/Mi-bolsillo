import 'package:mi_bolsillo/features/budgets/domain/budget_item.dart';
import 'package:mi_bolsillo/features/budgets/domain/budget_repository.dart';

/// In-memory mock repository seeded with healthy, 80% warning, and exhausted states.
class MockBudgetRepository implements BudgetRepository {
  MockBudgetRepository() : _items = _seedDefaults();

  List<BudgetItem> _items;
  int _counter = 50;

  static List<BudgetItem> _seedDefaults() => const [
    BudgetItem(
      id: 'bdg-1',
      category: 'Alimentación',
      limitCop: 500000, // Spent 420.000 => 84% (80% warning state)
      period: BudgetPeriod.monthly,
    ),
    BudgetItem(
      id: 'bdg-2',
      category: 'Ocio',
      limitCop: 140000, // Spent 150.000 => 107% (Exhausted state)
      period: BudgetPeriod.monthly,
    ),
    BudgetItem(
      id: 'bdg-3',
      category: 'Hogar',
      limitCop: 400000, // Spent 280.000 => 70% (Healthy)
      period: BudgetPeriod.monthly,
    ),
    BudgetItem(
      id: 'bdg-4',
      category: 'Transporte',
      limitCop: 220000, // Spent 100.000 => 45% (Healthy)
      period: BudgetPeriod.monthly,
    ),
  ];

  @override
  Future<List<BudgetItem>> getBudgets() async => List<BudgetItem>.from(_items);

  @override
  Future<BudgetItem> addBudget(BudgetItem budget) async {
    final existingIndex = _items.indexWhere(
      (b) => b.category == budget.category,
    );
    if (existingIndex != -1) {
      final updated = budget.copyWith(id: _items[existingIndex].id);
      _items[existingIndex] = updated;
      return updated;
    }
    final created = budget.id.isEmpty
        ? budget.copyWith(id: 'bdg-${++_counter}')
        : budget;
    _items = [..._items, created];
    return created;
  }

  @override
  Future<BudgetItem> updateBudget(BudgetItem budget) async {
    _items = _items.map((e) => e.id == budget.id ? budget : e).toList();
    return budget;
  }

  @override
  Future<void> deleteBudget(String id) async {
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

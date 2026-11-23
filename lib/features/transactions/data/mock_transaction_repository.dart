import 'package:mi_bolsillo/features/transactions/domain/transaction_item.dart';
import 'package:mi_bolsillo/features/transactions/domain/transaction_repository.dart';

/// In-memory mock repository seeded to match Stitch + baseline COP figures:
/// Expenses total -$950.000 COP.
class MockTransactionRepository implements TransactionRepository {
  MockTransactionRepository() : _items = _seedDefaults();

  List<TransactionItem> _items;
  int _counter = 200;

  static List<TransactionItem> _seedDefaults() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, 13, 15);
    final yesterday = today.subtract(const Duration(days: 1));
    final twoDaysAgo = today.subtract(const Duration(days: 2));
    final fourDaysAgo = today.subtract(const Duration(days: 4));

    return [
      TransactionItem(
        id: 'tx-1',
        description: 'Supermercado Éxito',
        amountCop: 260000,
        type: TransactionType.expense,
        categoryOrOrigin: 'Alimentación',
        date: today,
        paymentMethod: 'Nequi / Daviplata',
        isAutomatic: false,
        recurrence: RecurrenceFrequency.none,
      ),
      TransactionItem(
        id: 'tx-2',
        description: 'Almuerzos y Crepes & Waffles',
        amountCop: 160000,
        type: TransactionType.expense,
        categoryOrOrigin: 'Alimentación',
        date: yesterday,
        paymentMethod: 'Tarjeta Bancaria',
        isAutomatic: true,
        recurrence: RecurrenceFrequency.none,
      ),
      TransactionItem(
        id: 'tx-3',
        description: 'Recarga TuLlave y Transporte',
        amountCop: 100000,
        type: TransactionType.expense,
        categoryOrOrigin: 'Transporte',
        date: yesterday.subtract(const Duration(hours: 3)),
        paymentMethod: 'Efectivo',
        isAutomatic: true,
        recurrence: RecurrenceFrequency.weekly,
      ),
      TransactionItem(
        id: 'tx-4',
        description: 'Arriendo y Servicios',
        amountCop: 280000,
        type: TransactionType.expense,
        categoryOrOrigin: 'Hogar',
        date: twoDaysAgo,
        paymentMethod: 'Transferencia',
        isAutomatic: false,
        recurrence: RecurrenceFrequency.monthly,
      ),
      TransactionItem(
        id: 'tx-5',
        description: 'Cine y Streaming',
        amountCop: 150000,
        type: TransactionType.expense,
        categoryOrOrigin: 'Ocio',
        date: fourDaysAgo,
        paymentMethod: 'Tarjeta Bancaria',
        isAutomatic: false,
        recurrence: RecurrenceFrequency.monthly,
      ),
      TransactionItem(
        id: 'tx-base-1',
        description: 'Ingreso mensual base',
        amountCop: 2400000,
        type: TransactionType.baseIncome,
        categoryOrOrigin: 'Nómina mensual',
        date: DateTime(now.year, now.month, 1, 9, 0),
        paymentMethod: 'Transferencia',
        isAutomatic: true,
        recurrence: RecurrenceFrequency.monthly,
      ),
    ];
  }

  @override
  Future<List<TransactionItem>> getTransactions() async {
    final copy = List<TransactionItem>.from(_items)
      ..sort((a, b) => b.date.compareTo(a.date));
    return copy;
  }

  @override
  Future<TransactionItem> addTransaction(TransactionItem item) async {
    final created = item.id.isEmpty
        ? item.copyWith(id: 'tx-${++_counter}')
        : item;
    _items = [created, ..._items];
    return created;
  }

  @override
  Future<TransactionItem> updateTransaction(TransactionItem item) async {
    _items = _items.map((e) => e.id == item.id ? item : e).toList();
    return item;
  }

  @override
  Future<void> deleteTransaction(String id) async {
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

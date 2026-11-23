import 'package:mi_bolsillo/features/transactions/domain/transaction_item.dart';

/// Abstract repository contract for financial movements.
abstract class TransactionRepository {
  Future<List<TransactionItem>> getTransactions();
  Future<TransactionItem> addTransaction(TransactionItem item);
  Future<TransactionItem> updateTransaction(TransactionItem item);
  Future<void> deleteTransaction(String id);
  Future<void> clearAll();
  Future<void> resetToMockDefaults();
}

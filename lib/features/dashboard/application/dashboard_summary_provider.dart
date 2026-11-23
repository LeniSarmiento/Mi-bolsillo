import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_bolsillo/features/transactions/application/transactions_controller.dart';
import 'package:mi_bolsillo/features/transactions/domain/transaction_item.dart';

/// Dashboard summary computed strictly with integer COP amounts:
/// Available = monthlyIncome + confirmedAdditionalIncome - expenses.
@immutable
class DashboardSummary {
  const DashboardSummary({
    required this.monthlyIncomeCop,
    required this.additionalIncomeCop,
    required this.expensesCop,
    required this.availableCop,
    required this.committedPercent,
  });

  final int monthlyIncomeCop;
  final int additionalIncomeCop;
  final int expensesCop;
  final int availableCop;
  final int committedPercent;

  int get totalIncomeCop => monthlyIncomeCop + additionalIncomeCop;
  bool get isNegative => availableCop < 0;
}

final dashboardSummaryProvider = Provider<DashboardSummary>((ref) {
  return summarizeMonth(ref.watch(combinedMovementsProvider), DateTime.now());
});

DashboardSummary summarizeMonth(
  Iterable<TransactionItem> entries,
  DateTime today,
) {
  final end = DateTime(today.year, today.month, today.day + 1);
  final start = DateTime(today.year, today.month);
  final current = entries.where(
    (t) =>
        t.status == MovementStatus.confirmed &&
        !t.date.isBefore(start) &&
        t.date.isBefore(end),
  );
  int total(TransactionType type) =>
      current.where((t) => t.type == type).fold(0, (s, t) => s + t.amountCop);
  final monthlyIncomeCop = total(TransactionType.baseIncome);
  final additionalIncomeCop = total(TransactionType.additionalIncome);
  final expensesCop = total(TransactionType.expense);
  final availableCop = monthlyIncomeCop + additionalIncomeCop - expensesCop;
  final totalIncomeCop = monthlyIncomeCop + additionalIncomeCop;
  final committedPercent = totalIncomeCop <= 0
      ? 0
      : ((expensesCop * 100) / totalIncomeCop).round().clamp(0, 100);

  return DashboardSummary(
    monthlyIncomeCop: monthlyIncomeCop,
    additionalIncomeCop: additionalIncomeCop,
    expensesCop: expensesCop,
    availableCop: availableCop,
    committedPercent: committedPercent,
  );
}

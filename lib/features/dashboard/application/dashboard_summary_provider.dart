import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_bolsillo/features/income/application/income_controller.dart';
import 'package:mi_bolsillo/features/profile/application/settings_controller.dart';
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
  final settings = ref.watch(settingsControllerProvider);
  final incomeState = ref.watch(incomeControllerProvider);
  final txState = ref.watch(transactionsControllerProvider);

  final monthlyIncomeCop = settings.monthlyIncomeCop;
  final additionalIncomeCop = incomeState.totalCop;
  final expensesCop = txState.items
      .where((tx) => tx.type == TransactionType.expense)
      .fold<int>(0, (sum, tx) => sum + tx.amountCop);

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
});

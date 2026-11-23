import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_bolsillo/features/dashboard/application/dashboard_summary_provider.dart';
import 'package:mi_bolsillo/features/transactions/application/transactions_controller.dart';
import 'package:mi_bolsillo/features/transactions/domain/transaction_item.dart';

enum AnalysisPeriod {
  weekly('Semanal'),
  monthly('Mensual'),
  annual('Anual');

  const AnalysisPeriod(this.label);
  final String label;
}

@immutable
class CategoryBreakdown {
  const CategoryBreakdown({
    required this.category,
    required this.amountCop,
    required this.percentage,
  });

  final String category;
  final int amountCop;
  final int percentage;
}

@immutable
class AnalysisReport {
  const AnalysisReport({
    required this.totalIncomeCop,
    required this.totalExpensesCop,
    required this.savedCop,
    required this.freePercent,
    required this.categories,
    required this.topCategory,
    required this.dailyAverageCop,
  });

  final int totalIncomeCop;
  final int totalExpensesCop;
  final int savedCop;
  final int freePercent;
  final List<CategoryBreakdown> categories;
  final CategoryBreakdown? topCategory;
  final int dailyAverageCop;
}

final analysisReportProvider = Provider.family<AnalysisReport, AnalysisPeriod>((
  ref,
  period,
) {
  final summary = ref.watch(dashboardSummaryProvider);
  final txItems = ref.watch(transactionsControllerProvider).items;

  final multiplier = switch (period) {
    AnalysisPeriod.weekly => 1,
    AnalysisPeriod.monthly => 1,
    AnalysisPeriod.annual => 12,
  };
  final divisor = switch (period) {
    AnalysisPeriod.weekly => 4,
    AnalysisPeriod.monthly => 1,
    AnalysisPeriod.annual => 1,
  };

  int scale(int value) => (value * multiplier) ~/ divisor;

  final totalIncome = scale(summary.totalIncomeCop);
  final totalExpenses = scale(summary.expensesCop);
  final saved = totalIncome - totalExpenses;
  final freePercent = totalIncome <= 0
      ? 0
      : ((saved * 100) / totalIncome).round().clamp(0, 100);

  final Map<String, int> byCategory = {};
  for (final tx in txItems) {
    if (tx.type == TransactionType.expense) {
      byCategory[tx.categoryOrOrigin] =
          (byCategory[tx.categoryOrOrigin] ?? 0) + scale(tx.amountCop);
    }
  }

  final categories = byCategory.entries.map((entry) {
    final pct = totalExpenses <= 0
        ? 0
        : ((entry.value * 100) / totalExpenses).round();
    return CategoryBreakdown(
      category: entry.key,
      amountCop: entry.value,
      percentage: pct,
    );
  }).toList()..sort((a, b) => b.amountCop.compareTo(a.amountCop));

  final days = switch (period) {
    AnalysisPeriod.weekly => 7,
    AnalysisPeriod.monthly => 30,
    AnalysisPeriod.annual => 365,
  };

  return AnalysisReport(
    totalIncomeCop: totalIncome,
    totalExpensesCop: totalExpenses,
    savedCop: saved,
    freePercent: freePercent,
    categories: categories,
    topCategory: categories.isEmpty ? null : categories.first,
    dailyAverageCop: totalExpenses ~/ days,
  );
});

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  final now = DateTime.now();
  final start = switch (period) {
    AnalysisPeriod.weekly => DateTime(
      now.year,
      now.month,
      now.day - now.weekday + 1,
    ),
    AnalysisPeriod.monthly => DateTime(now.year, now.month),
    AnalysisPeriod.annual => DateTime(now.year),
  };
  final end = DateTime(now.year, now.month, now.day + 1);
  final txItems = ref
      .watch(combinedMovementsProvider)
      .where((m) => !m.date.isBefore(start) && m.date.isBefore(end));
  final totalIncome = txItems
      .where((m) => m.isIncome)
      .fold<int>(0, (s, m) => s + m.amountCop);
  final totalExpenses = txItems
      .where((m) => !m.isIncome)
      .fold<int>(0, (s, m) => s + m.amountCop);
  final saved = totalIncome - totalExpenses;
  final freePercent = totalIncome <= 0
      ? 0
      : ((saved * 100) / totalIncome).round().clamp(0, 100);

  final Map<String, int> byCategory = {};
  for (final tx in txItems) {
    if (tx.type == TransactionType.expense) {
      byCategory[tx.categoryOrOrigin] =
          (byCategory[tx.categoryOrOrigin] ?? 0) + tx.amountCop;
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

  final days = DateTime.utc(
    end.year,
    end.month,
    end.day,
  ).difference(DateTime.utc(start.year, start.month, start.day)).inDays;

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

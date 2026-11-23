import 'package:material_ui/material_ui.dart';
import 'package:mi_bolsillo/core/widgets/state_feedback_views.dart';

enum BudgetPeriod {
  monthly('Mensual', 30),
  biweekly('Quincenal', 15),
  weekly('Semanal', 7);

  const BudgetPeriod(this.label, this.days);
  final String label;
  final int days;
}

/// Visual/domain model for a category budget limit in integer COP.
@immutable
class BudgetItem {
  const BudgetItem({
    required this.id,
    required this.category,
    required this.limitCop,
    required this.period,
    this.alertAt80 = true,
    this.alertAt100 = true,
  });

  final String id;
  final String category;
  final int limitCop;
  final BudgetPeriod period;
  final bool alertAt80;
  final bool alertAt100;

  BudgetItem copyWith({
    String? id,
    String? category,
    int? limitCop,
    BudgetPeriod? period,
    bool? alertAt80,
    bool? alertAt100,
  }) {
    return BudgetItem(
      id: id ?? this.id,
      category: category ?? this.category,
      limitCop: limitCop ?? this.limitCop,
      period: period ?? this.period,
      alertAt80: alertAt80 ?? this.alertAt80,
      alertAt100: alertAt100 ?? this.alertAt100,
    );
  }
}

/// Computed progress view model for a budget against current expenses.
@immutable
class BudgetProgress {
  const BudgetProgress({
    required this.budget,
    required this.spentCop,
    this.warningEnabled = true,
  });

  final BudgetItem budget;
  final int spentCop;
  final bool warningEnabled;

  int get remainingCop => budget.limitCop - spentCop;

  int get percentUsed {
    if (budget.limitCop <= 0) return 0;
    return (spentCop * 100) ~/ budget.limitCop;
  }

  BudgetAlertLevel get alertLevel {
    if (budget.alertAt100 && spentCop >= budget.limitCop) {
      return BudgetAlertLevel.exhausted;
    }
    if (warningEnabled &&
        budget.alertAt80 &&
        percentUsed >= 80 &&
        spentCop < budget.limitCop) {
      return BudgetAlertLevel.warning80;
    }
    return BudgetAlertLevel.healthy;
  }
}

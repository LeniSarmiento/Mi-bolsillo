import 'package:drift/drift.dart';

import '../../data/finance_database.dart';
import '../../features/budgets/domain/budget_item.dart';
import 'app_notifications.dart';

class BudgetAlertCoordinator {
  BudgetAlertCoordinator(
    this._database,
    this._notifications, {
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final FinanceDatabase _database;
  final AppNotifications _notifications;
  final DateTime Function() _clock;

  Future<void> evaluate({required bool enabled}) async {
    if (!enabled || !_notifications.supported) return;

    final now = _clock();
    final budgets = await _database.select(_database.spendingLimits).get();
    for (final budget in budgets) {
      final period = BudgetPeriod.values.byName(budget.period);
      final start = periodStart(period, now);
      final end = DateTime(now.year, now.month, now.day + 1);
      final movements =
          await (_database.select(_database.movements)..where(
                (movement) =>
                    movement.kind.equals('expense') &
                    movement.status.equals('confirmed') &
                    movement.category.equals(budget.category) &
                    movement.occurred.isBiggerOrEqualValue(start) &
                    movement.occurred.isSmallerThanValue(end),
              ))
              .get();
      final spent = movements.fold<int>(0, (sum, item) => sum + item.amount);
      final percent = budget.amount <= 0 ? 0 : (spent * 100) ~/ budget.amount;
      final exhausted = budget.exhausted && spent >= budget.amount;
      final warning = budget.warn && percent >= 80 && !exhausted;
      if (!exhausted && !warning) continue;

      final level = exhausted ? '100' : '80';
      final receiptKey = [budget.id, start.toIso8601String(), level].join(':');
      final reserved = await _reserve(receiptKey);
      if (!reserved) continue;

      var shown = false;
      try {
        shown = await _notifications.showBudgetAlert(
          id: stableNotificationId(receiptKey),
          category: budget.category,
          percentUsed: percent,
          exhausted: exhausted,
        );
      } catch (_) {
        // A system notification failure must not invalidate saved finance data.
      }
      if (!shown) await _release(receiptKey);
    }
  }

  Future<bool> _reserve(String key) => _database.transaction(() async {
    final existing = await (_database.select(
      _database.budgetAlertReceipts,
    )..where((receipt) => receipt.key.equals(key))).getSingleOrNull();
    if (existing != null) return false;
    await _database
        .into(_database.budgetAlertReceipts)
        .insert(BudgetAlertReceipt(key: key, created: _clock()));
    return true;
  });

  Future<void> _release(String key) => (_database.delete(
    _database.budgetAlertReceipts,
  )..where((receipt) => receipt.key.equals(key))).go();
}

DateTime periodStart(BudgetPeriod period, DateTime date) => switch (period) {
  BudgetPeriod.monthly => DateTime(date.year, date.month),
  BudgetPeriod.weekly => DateTime(
    date.year,
    date.month,
    date.day - date.weekday + 1,
  ),
  BudgetPeriod.biweekly => DateTime(
    date.year,
    date.month,
    date.day < 16 ? 1 : 16,
  ),
};

int stableNotificationId(String value) {
  var hash = 0x811c9dc5;
  for (final unit in value.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0x7fffffff;
  }
  return hash;
}

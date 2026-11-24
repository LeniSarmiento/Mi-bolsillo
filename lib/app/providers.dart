import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/finance_database.dart';
import '../data/ledger.dart';
import '../data/local_detection.dart';
import '../data/local_repositories.dart';
import '../core/notifications/app_notifications.dart';
import '../core/notifications/budget_alert_coordinator.dart';
import '../features/automatic_detection/domain/automatic_detection_repository.dart';
import '../features/budgets/domain/budget_repository.dart';
import '../features/income/domain/income_repository.dart';
import '../features/profile/domain/settings_repository.dart';
import '../features/transactions/domain/transaction_repository.dart';

final databaseProvider = Provider<FinanceDatabase>((ref) {
  final db = FinanceDatabase.local();
  ref.onDispose(db.close);
  return db;
});
final ledgerProvider = Provider((ref) => Ledger(ref.watch(databaseProvider)));
final bridgeProvider = Provider((ref) => NotificationBridge());
final appNotificationsProvider = Provider<AppNotifications>(
  (ref) => LocalAppNotifications(),
);
final budgetAlertCoordinatorProvider = Provider(
  (ref) => BudgetAlertCoordinator(
    ref.watch(databaseProvider),
    ref.watch(appNotificationsProvider),
  ),
);
final transactionRepositoryProvider = Provider<TransactionRepository>(
  (ref) => LocalTransactions(ref.watch(ledgerProvider)),
);
final incomeRepositoryProvider = Provider<IncomeRepository>(
  (ref) => LocalIncomes(ref.watch(ledgerProvider)),
);
final budgetRepositoryProvider = Provider<BudgetRepository>(
  (ref) => LocalBudgets(ref.watch(ledgerProvider)),
);
final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => LocalSettings(ref.watch(ledgerProvider)),
);
final automaticDetectionRepositoryProvider =
    Provider<AutomaticDetectionRepository>(
      (ref) =>
          LocalDetection(ref.watch(ledgerProvider), ref.watch(bridgeProvider)),
    );

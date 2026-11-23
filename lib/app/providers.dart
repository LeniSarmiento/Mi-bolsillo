import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_bolsillo/features/automatic_detection/data/mock_automatic_detection_repository.dart';
import 'package:mi_bolsillo/features/automatic_detection/domain/automatic_detection_repository.dart';
import 'package:mi_bolsillo/features/budgets/data/mock_budget_repository.dart';
import 'package:mi_bolsillo/features/budgets/domain/budget_repository.dart';
import 'package:mi_bolsillo/features/income/data/mock_income_repository.dart';
import 'package:mi_bolsillo/features/income/domain/income_repository.dart';
import 'package:mi_bolsillo/features/profile/data/mock_settings_repository.dart';
import 'package:mi_bolsillo/features/profile/domain/settings_repository.dart';
import 'package:mi_bolsillo/features/transactions/data/mock_transaction_repository.dart';
import 'package:mi_bolsillo/features/transactions/domain/transaction_repository.dart';

/// Dependency-injection providers exposing abstract repository contracts.
/// Swap these overrides when connecting real local persistence or backend APIs.
final transactionRepositoryProvider = Provider<TransactionRepository>(
  (ref) => MockTransactionRepository(),
);

final incomeRepositoryProvider = Provider<IncomeRepository>(
  (ref) => MockIncomeRepository(),
);

final budgetRepositoryProvider = Provider<BudgetRepository>(
  (ref) => MockBudgetRepository(),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => MockSettingsRepository(),
);

final automaticDetectionRepositoryProvider =
    Provider<AutomaticDetectionRepository>(
      (ref) => MockAutomaticDetectionRepository(),
    );

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_bolsillo/app/app.dart';
import 'package:mi_bolsillo/app/providers.dart';
import 'package:mi_bolsillo/data/finance_database.dart';
import 'package:mi_bolsillo/data/ledger.dart';
import 'package:mi_bolsillo/data/local_detection.dart';
import 'package:mi_bolsillo/data/local_repositories.dart';
import 'package:mi_bolsillo/features/budgets/data/mock_budget_repository.dart';
import 'package:mi_bolsillo/features/income/data/mock_income_repository.dart';
import 'package:mi_bolsillo/features/profile/domain/user_settings.dart';
import 'package:mi_bolsillo/features/transactions/data/mock_transaction_repository.dart';
import 'package:mi_bolsillo/features/transactions/domain/transaction_item.dart';

Future<void> pumpFinance(WidgetTester tester, String route) async {
  final db = FinanceDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  final ledger = Ledger(db);
  // The fixture always belongs to the current period, including on its first day.
  final now = DateTime.now();
  await tester.runAsync(() async {
    await LocalSettings(ledger).updateSettings(
      UserSettings.defaults().copyWith(
        monthlyIncomeCop: 2400000,
        onboardingCompleted: true,
      ),
    );
    for (final t in await MockTransactionRepository().getTransactions()) {
      if (t.type == TransactionType.expense) {
        await ledger.save(
          t.copyWith(date: now, recurrence: RecurrenceFrequency.none),
        );
      }
    }
    for (final i in await MockIncomeRepository().getAdditionalIncomes()) {
      await LocalIncomes(ledger).addAdditionalIncome(
        i.copyWith(date: now, recurrence: RecurrenceFrequency.none),
      );
    }
    for (final b in await MockBudgetRepository().getBudgets()) {
      await LocalBudgets(ledger).addBudget(b);
    }
    await LocalDetection(ledger, _SeedBridge()).importQueue();
  });
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        bridgeProvider.overrideWithValue(_OfflineBridge()),
      ],
      child: MiBolsilloApp(initialLocation: route),
    ),
  );
  await tester.pumpAndSettle();
}

class _OfflineBridge extends NotificationBridge {
  @override
  bool get supported => false;
}

class _SeedBridge extends _OfflineBridge {
  @override
  Future<List<Map<String, dynamic>>> peek() async => [
    {
      'id': 'pending-test',
      'app': 'Bancolombia',
      'merchant': 'Éxito Calle 80',
      'amount': 78500,
      'date': DateTime.now().millisecondsSinceEpoch,
    },
  ];
  @override
  Future<void> acknowledge(List<String> ids) async {}
}

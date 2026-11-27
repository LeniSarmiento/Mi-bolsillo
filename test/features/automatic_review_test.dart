import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_bolsillo/app/providers.dart';
import 'package:mi_bolsillo/core/notifications/app_notifications.dart';
import 'package:mi_bolsillo/data/finance_database.dart';
import 'package:mi_bolsillo/data/ledger.dart';
import 'package:mi_bolsillo/data/local_detection.dart';
import 'package:mi_bolsillo/data/local_repositories.dart';
import 'package:mi_bolsillo/features/automatic_detection/application/automatic_detection_controller.dart';
import 'package:mi_bolsillo/features/automatic_detection/domain/pending_movement.dart';
import 'package:mi_bolsillo/features/budgets/domain/budget_item.dart';
import 'package:mi_bolsillo/features/profile/domain/user_settings.dart';
import 'package:mi_bolsillo/features/transactions/domain/transaction_item.dart';

class _Bridge extends NotificationBridge {
  @override
  bool get supported => false;
  @override
  Future<List<Map<String, dynamic>>> peek() async => [
    for (var i = 0; i < 2; i++)
      {
        'id': 'test-$i',
        'merchant': 'Tienda',
        'app': 'Nequi',
        'amount': 10000,
        'date': DateTime.now().millisecondsSinceEpoch,
      },
  ];
  @override
  Future<void> acknowledge(List<String> ids) async {}
}

class _SlowDetection extends LocalDetection {
  _SlowDetection(super.ledger, super.bridge);
  final secondStarted = Completer<void>();
  final finish = Completer<void>();
  int calls = 0;
  @override
  Future<void> confirm(PendingMovement movement, {String? category}) async {
    if (++calls == 2) {
      secondStarted.complete();
      await finish.future;
    }
    await super.confirm(movement, category: category);
  }
}

class _Notifications implements AppNotifications {
  final levels = <int>[];
  @override
  bool get supported => true;
  @override
  Future<void> initialize() async {}
  @override
  Future<bool> requestPermission() async => true;
  @override
  Future<bool> syncDailyReminder(bool enabled) async => true;
  @override
  Future<bool> showBudgetAlert({
    required int id,
    required String category,
    required int percentUsed,
    required bool exhausted,
  }) async {
    levels.add(percentUsed);
    return true;
  }
}

void main() {
  test('confirmación en lote bloquea acciones hasta el final y emite alerta al cruzar 80%', () async {
    final db = FinanceDatabase(NativeDatabase.memory());
    final ledger = Ledger(db);
    final repo = _SlowDetection(ledger, _Bridge());
    final notifications = _Notifications();
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        automaticDetectionRepositoryProvider.overrideWithValue(repo),
        appNotificationsProvider.overrideWithValue(notifications),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await db.close();
    });
    await LocalSettings(ledger).updateSettings(
      UserSettings.defaults().copyWith(budget80AlertEnabled: true),
    );
    await LocalBudgets(ledger).addBudget(
      const BudgetItem(
        id: '',
        category: 'Otros',
        limitCop: 100000,
        period: BudgetPeriod.monthly,
      ),
    );
    await ledger.save(
      TransactionItem(
        id: '',
        description: 'Previo',
        amountCop: 70000,
        type: TransactionType.expense,
        categoryOrOrigin: 'Otros',
        date: DateTime.now(),
        paymentMethod: 'Efectivo',
        isAutomatic: false,
        recurrence: RecurrenceFrequency.none,
      ),
    );
    final controller = container.read(
      automaticDetectionControllerProvider.notifier,
    );
    await Future<void>.delayed(Duration.zero);
    await controller.load();
    final pendingIds = container
        .read(automaticDetectionControllerProvider)
        .pending
        .map((p) => p.id)
        .toSet();
    final saving = controller.confirmAll();
    await repo.secondStarted.future;
    expect(
      container.read(automaticDetectionControllerProvider).isSaving,
      isTrue,
    );
    await controller.discardOne(pendingIds.first);
    repo.finish.complete();
    await saving;
    expect(
      container.read(automaticDetectionControllerProvider).isSaving,
      isFalse,
    );
    expect(
      container.read(automaticDetectionControllerProvider).pending,
      isEmpty,
    );
    expect((await LocalTransactions(ledger).getTransactions()).length, 3);
    expect(notifications.levels, [90]);
    await controller.confirmAll();
    expect(notifications.levels, [90]);
  });
}

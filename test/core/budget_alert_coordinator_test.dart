import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_bolsillo/core/notifications/app_notifications.dart';
import 'package:mi_bolsillo/core/notifications/budget_alert_coordinator.dart';
import 'package:mi_bolsillo/data/finance_database.dart';
import 'package:mi_bolsillo/data/ledger.dart';
import 'package:mi_bolsillo/data/local_repositories.dart';
import 'package:mi_bolsillo/features/budgets/domain/budget_item.dart';
import 'package:mi_bolsillo/features/transactions/domain/transaction_item.dart';

class RecordingNotifications implements AppNotifications {
  bool fail = false;
  final alerts = <({int id, int percent, bool exhausted})>[];

  @override
  bool get supported => true;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<bool> showBudgetAlert({
    required int id,
    required String category,
    required int percentUsed,
    required bool exhausted,
  }) async {
    if (fail) throw StateError('notification unavailable');
    alerts.add((id: id, percent: percentUsed, exhausted: exhausted));
    return true;
  }

  @override
  Future<bool> syncDailyReminder(bool enabled) async => true;
}

void main() {
  late DateTime now;
  late FinanceDatabase database;
  late Ledger ledger;
  late RecordingNotifications notifications;
  late BudgetAlertCoordinator coordinator;

  setUp(() {
    now = DateTime(2026, 11, 24, 12);
    database = FinanceDatabase(NativeDatabase.memory());
    ledger = Ledger(database, clock: () => now);
    notifications = RecordingNotifications();
    coordinator = BudgetAlertCoordinator(
      database,
      notifications,
      clock: () => now,
    );
  });

  tearDown(() => database.close());

  Future<void> addExpense(int amount) => ledger.save(
    TransactionItem(
      id: '',
      description: 'Prueba',
      amountCop: amount,
      type: TransactionType.expense,
      categoryOrOrigin: 'Compras',
      date: now,
      paymentMethod: 'Efectivo',
      isAutomatic: false,
      recurrence: RecurrenceFrequency.none,
    ),
  );

  Future<void> addBudget() => LocalBudgets(ledger).addBudget(
    const BudgetItem(
      id: '',
      category: 'Compras',
      limitCop: 100000,
      period: BudgetPeriod.monthly,
    ),
  );

  test('emite una sola alerta por nivel y periodo', () async {
    await addBudget();
    await addExpense(80000);

    await coordinator.evaluate(enabled: true);
    await coordinator.evaluate(enabled: true);
    expect(notifications.alerts, hasLength(1));
    expect(notifications.alerts.single.percent, 80);
    expect(notifications.alerts.single.exhausted, isFalse);

    await addExpense(20000);
    await coordinator.evaluate(enabled: true);
    await coordinator.evaluate(enabled: true);
    expect(notifications.alerts, hasLength(2));
    expect(notifications.alerts.last.exhausted, isTrue);
  });

  test('un periodo nuevo puede volver a alertar', () async {
    await addBudget();
    await addExpense(80000);
    await coordinator.evaluate(enabled: true);

    now = DateTime(2026, 12, 1, 12);
    await addExpense(80000);
    await coordinator.evaluate(enabled: true);

    expect(notifications.alerts, hasLength(2));
    expect(notifications.alerts[0].id, isNot(notifications.alerts[1].id));
  });

  test('si el sistema falla libera el recibo para reintentar', () async {
    await addBudget();
    await addExpense(80000);
    notifications.fail = true;

    await coordinator.evaluate(enabled: true);
    expect(notifications.alerts, isEmpty);
    expect(await database.select(database.budgetAlertReceipts).get(), isEmpty);

    notifications.fail = false;
    await coordinator.evaluate(enabled: true);
    expect(notifications.alerts, hasLength(1));
  });

  test('desactivada no consulta ni genera recibos', () async {
    await addBudget();
    await addExpense(100000);

    await coordinator.evaluate(enabled: false);

    expect(notifications.alerts, isEmpty);
    expect(await database.select(database.budgetAlertReceipts).get(), isEmpty);
  });

  test('calcula periodos y los ids son estables', () {
    expect(
      periodStart(BudgetPeriod.weekly, DateTime(2026, 11, 24)),
      DateTime(2026, 11, 23),
    );
    expect(
      periodStart(BudgetPeriod.biweekly, DateTime(2026, 11, 16)),
      DateTime(2026, 11, 16),
    );
    expect(stableNotificationId('same'), stableNotificationId('same'));
    expect(stableNotificationId('same'), isNot(stableNotificationId('other')));
  });
}

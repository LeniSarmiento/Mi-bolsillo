import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show ThemeMode;
import 'package:mi_bolsillo/data/finance_database.dart';
import 'package:mi_bolsillo/data/ledger.dart';
import 'package:mi_bolsillo/data/local_detection.dart';
import 'package:mi_bolsillo/data/local_repositories.dart';
import 'package:mi_bolsillo/features/budgets/application/budgets_controller.dart';
import 'package:mi_bolsillo/features/budgets/domain/budget_item.dart';
import 'package:mi_bolsillo/features/dashboard/application/dashboard_summary_provider.dart';
import 'package:mi_bolsillo/features/profile/domain/user_settings.dart';
import 'package:mi_bolsillo/features/transactions/domain/transaction_item.dart';

class QueueDouble extends NotificationBridge {
  bool failAck = true;
  final items = <Map<String, dynamic>>[
    {
      'id': 'stable',
      'app': 'Nequi',
      'date': DateTime(2026, 1, 10).millisecondsSinceEpoch,
      'merchant': 'Tienda',
      'amount': 1250,
    },
  ];
  @override
  Future<List<Map<String, dynamic>>> peek() async => List.of(items);
  @override
  Future<void> acknowledge(List<String> ids) async {
    if (failAck) throw StateError('interrumpido');
    items.removeWhere((i) => ids.contains(i['id']));
  }
}

void main() {
  late DateTime now;
  late FinanceDatabase db;
  late Ledger ledger;
  setUp(() {
    now = DateTime(2026, 1, 31);
    db = FinanceDatabase(NativeDatabase.memory());
    ledger = Ledger(db, clock: () => now);
  });
  tearDown(() => db.close());
  TransactionItem entry(
    TransactionType kind,
    int amount,
    DateTime date, {
    RecurrenceFrequency frequency = RecurrenceFrequency.none,
  }) => TransactionItem(
    id: '',
    description: 'Prueba',
    amountCop: amount,
    type: kind,
    categoryOrOrigin: kind == TransactionType.expense
        ? 'Compras'
        : 'Horas extras',
    date: date,
    paymentMethod: 'Efectivo',
    isAutomatic: false,
    recurrence: frequency,
  );
  Future<List<TransactionItem>> history() async => [
    ...await LocalTransactions(ledger).getTransactions(),
    ...(await LocalIncomes(
      ledger,
    ).getAdditionalIncomes()).map(ledger.incomeEntry),
  ];
  test('Saldo, salario por mes, ingresos adicionales y futuros', () async {
    final settings = LocalSettings(ledger);
    await settings.configureIncome(
      UserSettings.defaults().copyWith(
        monthlyIncomeCop: 2400000,
        onboardingCompleted: true,
      ),
    );
    final bonus = await ledger.save(
      entry(TransactionType.additionalIncome, 480000, now),
    );
    await ledger.save(entry(TransactionType.expense, 950000, now));
    await ledger.save(
      entry(TransactionType.expense, 4000, DateTime(2026, 2, 3)),
    );
    expect(summarizeMonth(await history(), now).availableCop, 1930000);
    expect((await settings.getSettings()).monthlyIncomeCop, 2400000);
    await ledger.save(bonus.copyWith(amountCop: 500000), update: true);
    expect(summarizeMonth(await history(), now).availableCop, 1950000);
    await ledger.remove(bonus.id);
    expect(summarizeMonth(await history(), now).availableCop, 1450000);
    now = DateTime(2026, 2, 1);
    await settings.configureIncome(
      (await settings.getSettings()).copyWith(monthlyIncomeCop: 3000000),
    );
    final rows = await history();
    expect(summarizeMonth(rows, now).availableCop, 3000000);
    expect(summarizeMonth(rows, DateTime(2026, 1, 31)).availableCop, 1450000);
  });
  for (final frequency in [
    RecurrenceFrequency.weekly,
    RecurrenceFrequency.biweekly,
    RecurrenceFrequency.monthly,
  ]) {
    test(
      'Recurrencia ${frequency.name}, reapertura, fin de mes y desactivación',
      () async {
        final template = await ledger.save(
          entry(
            TransactionType.additionalIncome,
            50000,
            now,
            frequency: frequency,
          ),
        );
        expect((await history()).length, 1);
        now = DateTime(2026, 3, 31);
        await Future.wait([ledger.generateDue(), ledger.generateDue()]);
        final dates = (await LocalIncomes(
          ledger,
        ).getAdditionalIncomes()).map((e) => e.date).toSet();
        final expected = {
          RecurrenceFrequency.weekly: 9,
          RecurrenceFrequency.biweekly: 5,
          RecurrenceFrequency.monthly: 3,
        }[frequency];
        expect(dates.length, expected);
        expect((await history()).length, expected);
        if (frequency == RecurrenceFrequency.monthly) {
          expect(
            dates,
            containsAll([DateTime(2026, 2, 28), DateTime(2026, 3, 31)]),
          );
        }
        await ledger.save(
          template.copyWith(recurrence: RecurrenceFrequency.none),
          update: true,
        );
        now = DateTime(2026, 5, 31);
        expect((await history()).length, expected);
      },
    );
  }
  test('Una importación interrumpida o repetida y una doble confirmación producen un solo gasto', () async {
    final queue = QueueDouble();
    final detection = LocalDetection(ledger, queue);
    await expectLater(detection.importQueue(), throwsStateError);
    expect(await history(), isEmpty);
    queue.failAck = false;
    var pending = (await detection.getPendingMovements()).single;
    await detection.editPending(
      pending.copyWith(amountCop: 1500, merchant: 'Otro comercio'),
    );
    pending = (await detection.getPendingMovements()).single;
    expect(pending.amountCop, 1500);
    expect(await history(), isEmpty);
    expect(queue.items, isEmpty);
    await Future.wait([
      detection.confirm(pending, category: 'Hogar'),
      detection.confirm(pending),
    ]);
    expect((await history()).single.amountCop, 1500);
    expect(await detection.getPendingMovements(), isEmpty);
    await ledger.remove('stable');
    queue.items.add({
      'id': 'stable',
      'app': 'Nequi',
      'date': now.millisecondsSinceEpoch,
      'merchant': 'Tienda',
      'amount': 1250,
    });
    expect(await detection.getPendingMovements(), isEmpty);
    queue.items.add({
      'id': 'other',
      'app': 'Nequi',
      'date': now.millisecondsSinceEpoch,
      'merchant': 'Tienda',
      'amount': 1250,
    });
    await detection.importQueue();
    await detection.removePendingMovement('other');
    expect(await history(), isEmpty);
    expect(await detection.getPendingMovements(), isEmpty);
  });
  test('Presupuestos solo consumen gastos de su categoría y periodo', () async {
    final budgets = LocalBudgets(ledger);
    var b = await budgets.addBudget(
      const BudgetItem(
        id: '',
        category: 'Compras',
        limitCop: 100,
        period: BudgetPeriod.monthly,
      ),
    );
    final rows = [
      entry(TransactionType.expense, 70, now),
      entry(TransactionType.expense, 400, DateTime(2025, 12)),
      entry(TransactionType.expense, 120, DateTime(2026, 2)),
    ];
    expect(budgetProgress(b, rows, now).percentUsed, 70);
    rows.add(entry(TransactionType.expense, 10, now));
    expect(budgetProgress(b, rows, now).alertLevel.name, 'warning80');
    rows.add(entry(TransactionType.expense, 20, now));
    expect(budgetProgress(b, rows, now).alertLevel.name, 'exhausted');
    b = await budgets.updateBudget(b.copyWith(limitCop: 200));
    expect((await budgets.getBudgets()).single.limitCop, 200);
    await budgets.deleteBudget(b.id);
    expect(await budgets.getBudgets(), isEmpty);
  });
  test(
    'Ajustes y enteros sobreviven al cierre y a la migración v1 a v2',
    () async {
      await db.close();
      final dir = await Directory.systemTemp.createTemp('bolsillo-test-');
      addTearDown(() => dir.delete(recursive: true));
      final file = File('${dir.path}/finance.db');
      final first = FinanceDatabase(NativeDatabase(file));
      final firstLedger = Ledger(first, clock: () => now);
      await LocalSettings(firstLedger).updateSettings(
        UserSettings.defaults().copyWith(
          monthlyIncomeCop: 1250000,
          onboardingCompleted: true,
          themeMode: ThemeMode.dark,
        ),
      );
      await first.customStatement('DROP TABLE detection_receipts');
      await first.customStatement('PRAGMA user_version=1');
      await first.close();
      final migrated = FinanceDatabase(NativeDatabase(file));
      addTearDown(migrated.close);
      final l = Ledger(migrated, clock: () => now);
      expect(
        (await LocalTransactions(l).getTransactions()).single.amountCop,
        1250000,
      );
      expect((await LocalSettings(l).getSettings()).themeMode, ThemeMode.dark);
      expect(await migrated.select(migrated.detectionReceipts).get(), isEmpty);
      expect(
        (await migrated.customSelect('PRAGMA user_version').getSingle())
            .read<int>('user_version'),
        2,
      );
    },
  );
}

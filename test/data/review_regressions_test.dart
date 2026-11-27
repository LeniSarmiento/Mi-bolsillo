import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_bolsillo/core/formatting/cop_formatter.dart';
import 'package:mi_bolsillo/data/finance_database.dart';
import 'package:mi_bolsillo/data/ledger.dart';
import 'package:mi_bolsillo/data/local_backup.dart';
import 'package:mi_bolsillo/data/local_detection.dart';
import 'package:mi_bolsillo/data/local_repositories.dart';
import 'package:mi_bolsillo/features/budgets/domain/budget_item.dart';
import 'package:mi_bolsillo/features/dashboard/application/dashboard_summary_provider.dart';
import 'package:mi_bolsillo/features/profile/domain/user_settings.dart';
import 'package:mi_bolsillo/features/transactions/domain/transaction_item.dart';

class _Queue extends NotificationBridge {
  @override
  Future<List<Map<String, dynamic>>> peek() async => [
    {
      'id': 'notice-1',
      'app': 'Nequi',
      'merchant': 'Tienda',
      'amount': 20000,
      'date': DateTime(2026, 1, 15).millisecondsSinceEpoch,
    },
  ];
  @override
  Future<void> acknowledge(List<String> ids) async {}
}

void main() {
  late FinanceDatabase db;
  late Ledger ledger;
  late DateTime now;
  setUp(() {
    now = DateTime(2026, 1, 15);
    db = FinanceDatabase(NativeDatabase.memory());
    ledger = Ledger(db, clock: () => now);
  });
  tearDown(() => db.close());
  TransactionItem entry({
    DateTime? date,
    RecurrenceFrequency recurrence = RecurrenceFrequency.none,
    TransactionType type = TransactionType.expense,
  }) => TransactionItem(
    id: '',
    description: 'Prueba',
    amountCop: 100000,
    type: type,
    categoryOrOrigin: type == TransactionType.expense
        ? 'Compras'
        : 'Horas extras',
    date: date ?? now,
    paymentMethod: 'Efectivo',
    isAutomatic: false,
    recurrence: recurrence,
  );

  test('monto pegado con decimales cero conserva los pesos; formatos ambiguos no se guardan', () {
    final formatter = CopFormatter.inputFormatter;
    final formatted = formatter.formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(text: '1.250,00'),
    );
    expect(formatted.text, '1.250');
    expect(CopFormatter.parseDigits(formatted.text), 1250);
    for (final invalid in [
      '1.250,50',
      '-1250',
      '1,250',
      'USD 1250',
      '12abc34',
      '1.25',
      '9007199254740992',
    ]) {
      final result = formatter.formatEditUpdate(
        TextEditingValue.empty,
        TextEditingValue(text: invalid),
      );
      expect(CopFormatter.parseDigits(result.text), isNull, reason: invalid);
    }
    expect(
      formatter
          .formatEditUpdate(
            const TextEditingValue(text: '1.000'),
            const TextEditingValue(text: '1.0000'),
          )
          .text,
      '10.000',
    );
    expect(
      formatter
          .formatEditUpdate(
            const TextEditingValue(text: '1.000'),
            const TextEditingValue(text: '1.00'),
          )
          .text,
      '100',
    );
  });

  test(
    'borrar salario es rechazado y el siguiente mes conserva su programación',
    () async {
      final settings = LocalSettings(ledger);
      await settings.configureIncome(
        UserSettings.defaults().copyWith(
          monthlyIncomeCop: 2400000,
          autoRepeatBaseIncome: true,
        ),
      );
      final repo = LocalTransactions(ledger);
      final salary = (await repo.getTransactions()).single;
      await expectLater(
        repo.deleteTransaction(salary.id),
        throwsFormatException,
      );
      now = DateTime(2026, 2, 1);
      expect(
        (await repo.getTransactions())
            .where((t) => t.date.month == 2)
            .single
            .amountCop,
        2400000,
      );
      expect((await settings.getSettings()).autoRepeatBaseIncome, isTrue);
      await settings.configureIncome(
        (await settings.getSettings()).copyWith(
          monthlyIncomeCop: 0,
          autoRepeatBaseIncome: false,
        ),
      );
      expect(
        (await repo.getTransactions()).where((t) => t.date.month == 2),
        isEmpty,
      );
      expect(
        (await repo.getTransactions()).where((t) => t.date.month == 1),
        hasLength(1),
      );
    },
  );

  test('editar ocurrencia no permite crear una serie paralela; editar plantilla afecta solo futuro', () async {
    final template = await ledger.save(
      entry(
        type: TransactionType.additionalIncome,
        recurrence: RecurrenceFrequency.monthly,
      ),
    );
    now = DateTime(2026, 2, 15);
    final incomes = LocalIncomes(ledger);
    final occurrence = (await incomes.getAdditionalIncomes()).first;
    expect(occurrence.parentId, template.id);
    expect(occurrence.source, MovementSource.recurring);
    await expectLater(
      incomes.updateAdditionalIncome(
        occurrence.copyWith(recurrence: RecurrenceFrequency.monthly),
      ),
      throwsFormatException,
    );
    await incomes.updateAdditionalIncome(
      occurrence.copyWith(amountCop: 120000),
    );
    final original = (await incomes.getAdditionalIncomes()).singleWhere(
      (i) => i.id == template.id,
    );
    await incomes.reviseFuture(
      original.copyWith(amountCop: 150000, date: DateTime(2026, 3, 15)),
    );
    now = DateTime(2026, 3, 15);
    final entries = await incomes.getAdditionalIncomes();
    expect(entries.where((i) => i.date.month == 1).single.amountCop, 100000);
    expect(entries.where((i) => i.date.month == 3).single.amountCop, 150000);
    expect(entries.where((i) => i.date.month == 2).single.amountCop, 120000);
    await ledger.generateDue();
    expect(
      (await incomes.getAdditionalIncomes()).where((i) => i.date.month == 3),
      hasLength(1),
    );
  });

  test('previsualización aplica la misma fecha de corte al gasto nuevo y al editado', () {
    int preview(DateTime date, {TransactionItem? original}) =>
        previewExpenseBalance(
          availableCop: 1000000,
          amountCop: 50000,
          date: date,
          today: now,
          original: original,
        );
    expect(preview(now), 950000);
    expect(preview(DateTime(2026, 2)), 1000000);
    expect(preview(DateTime(2025, 12)), 1000000);
    expect(preview(DateTime(2026, 1, 16)), 1000000);
    expect(preview(now, original: entry(date: DateTime(2025, 12))), 950000);
    expect(preview(DateTime(2026, 2), original: entry()), 1100000);
    expect(preview(now, original: entry()), 1050000);
  });

  test('copia restaura historial, series, pendientes, recibos y presupuestos; avisos quedan apagados', () async {
    await LocalSettings(ledger).configureIncome(
      UserSettings.defaults().copyWith(
        monthlyIncomeCop: 2400000,
        dailyReminderEnabled: true,
      ),
    );
    await ledger.save(
      entry(
        type: TransactionType.additionalIncome,
        recurrence: RecurrenceFrequency.monthly,
      ),
    );
    await LocalBudgets(ledger).addBudget(
      const BudgetItem(
        id: '',
        category: 'Compras',
        limitCop: 300000,
        period: BudgetPeriod.monthly,
      ),
    );
    await LocalDetection(ledger, _Queue()).importQueue();
    final backup = LocalBackup(db);
    final bytes = await backup.export();
    final before = await db.select(db.movements).get();
    await db.erase();
    await backup.restore(backup.prepare(bytes));
    expect(await db.select(db.movements).get(), before);
    expect(await db.select(db.detectionReceipts).get(), hasLength(1));
    expect(await LocalBudgets(ledger).getBudgets(), hasLength(1));
    expect(
      (await LocalSettings(ledger).getSettings()).dailyReminderEnabled,
      isFalse,
    );
    now = DateTime(2026, 2, 15);
    await ledger.generateDue();
    await ledger.generateDue();
    expect(
      (await LocalIncomes(
        ledger,
      ).getAdditionalIncomes()).where((i) => i.date.month == 2),
      hasLength(1),
    );
  });

  test(
    'copia corrupta y error SQL no destruyen los datos existentes',
    () async {
      await ledger.save(entry());
      final backup = LocalBackup(db);
      final bytes = await backup.export();
      final original = await db.select(db.movements).get();
      final json = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      (json['movements'] as List).first['amount'] = 12.5;
      expect(
        () => backup.prepare(Uint8List.fromList(utf8.encode(jsonEncode(json)))),
        throwsFormatException,
      );
      await db.customStatement(
        "CREATE TRIGGER fail_restore BEFORE INSERT ON movements BEGIN SELECT RAISE(ABORT, 'test failure'); END",
      );
      await expectLater(
        backup.restore(backup.prepare(bytes)),
        throwsA(isA<Exception>()),
      );
      expect(await db.select(db.movements).get(), original);
    },
  );
}

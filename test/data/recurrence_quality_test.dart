import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_bolsillo/data/finance_database.dart';
import 'package:mi_bolsillo/data/ledger.dart';
import 'package:mi_bolsillo/data/local_backup.dart';
import 'package:mi_bolsillo/data/local_detection.dart';
import 'package:mi_bolsillo/data/local_repositories.dart';
import 'package:mi_bolsillo/features/transactions/domain/transaction_item.dart';

class _Notices extends NotificationBridge {
  List<Map<String, dynamic>> items = [];
  @override
  Future<List<Map<String, dynamic>>> peek() async => items;
  @override
  Future<void> acknowledge(List<String> ids) async {}
}

void main() {
  late FinanceDatabase db;
  late Ledger ledger;
  late DateTime now;
  setUp(() {
    now = DateTime(2026, 1, 1);
    db = FinanceDatabase(NativeDatabase.memory());
    ledger = Ledger(db, clock: () => now);
  });
  tearDown(() => db.close());
  TransactionItem item(TransactionType type) => TransactionItem(
    id: '',
    description: 'Serie',
    amountCop: 100000,
    type: type,
    categoryOrOrigin: type == TransactionType.expense
        ? 'Compras'
        : 'Horas extras',
    date: now,
    paymentMethod: 'Efectivo',
    isAutomatic: false,
    recurrence: RecurrenceFrequency.monthly,
  );
  Future<List<Movement>> rows() => db.select(db.movements).get();
  Map<String, String> financialHistory(List<Movement> data) => {
    for (final m in data.where((m) => !dayOf(m.occurred).isAfter(dayOf(now))))
      m.id:
          '${m.amount}|${m.description}|${m.occurred}|${m.category}|${m.method}|${m.status}|${m.note}',
  };

  for (final type in [
    TransactionType.expense,
    TransactionType.additionalIncome,
  ]) {
    test(
      '$type: próxima frecuencia semanal conserva historial e idempotencia',
      () async {
        final root = await ledger.save(item(type));
        now = DateTime(2026, 3, 1);
        await ledger.generateDue();
        final history = financialHistory(await rows());
        expect(history.length, 3);
        final future = await ledger.reviseFuture(
          root.copyWith(
            date: DateTime(2026, 3, 8),
            amountCop: 200000,
            recurrence: RecurrenceFrequency.weekly,
          ),
        );
        expect(financialHistory(await rows()), history);
        expect(await rows(), hasLength(4));
        await expectLater(
          ledger.reviseFuture(root.copyWith(date: DateTime(2026, 3, 8))),
          throwsFormatException,
        );
        now = DateTime(2026, 3, 22);
        await ledger.generateDue();
        await ledger.generateDue();
        expect(await rows(), hasLength(6));
        expect(
          (await rows())
              .where((m) => m.occurred.isAfter(DateTime(2026, 3, 1)))
              .map((m) => m.amount),
          everyElement(200000),
        );
        expect(
          (await rows())
              .where((m) => m.id != future.id)
              .every((m) => m.parent == future.id),
          isTrue,
        );
        final backup = LocalBackup(db);
        await backup.restore(backup.prepare(await backup.export()));
        await ledger.generateDue();
        expect(await rows(), hasLength(6));
      },
    );

    test(
      '$type: editar solo la plantilla no cambia próximas ni otras ocurrencias',
      () async {
        final root = await ledger.save(item(type));
        now = DateTime(2026, 3, 1);
        await ledger.generateDue();
        if (type == TransactionType.expense) {
          await LocalTransactions(ledger)
              .updateTransaction(root.copyWith(amountCop: 150000));
        } else {
          final repo = LocalIncomes(ledger);
          final original = (await repo.getAdditionalIncomes()).singleWhere(
            (m) => m.id == root.id,
          );
          await repo.updateAdditionalIncome(
            original.copyWith(amountCop: 150000),
          );
        }
        expect(
          (await rows()).singleWhere((m) => m.id == root.id).amount,
          150000,
        );
        expect(
          (await rows()).where((m) => m.id != root.id).map((m) => m.amount),
          everyElement(100000),
        );
        now = DateTime(2026, 4, 1);
        await ledger.generateDue();
        expect(
          (await rows()).singleWhere((m) => m.occurred.month == 4).amount,
          100000,
        );
      },
    );
  }

  for (final year in [2026, 2028]) {
    test(
      'editar una ocurrencia conserva ancla 31 pasando por febrero de $year',
      () async {
        now = DateTime(year, 1, 31);
        final root = await ledger.save(item(TransactionType.expense));
        await LocalTransactions(ledger)
            .updateTransaction(root.copyWith(amountCop: 120000));
        expect(
          (await rows()).singleWhere((m) => m.parent == null).occurred,
          DateTime(year, 3, 0),
        );
        now = DateTime(year, 3, 31);
        await ledger.generateDue();
        expect(
          (await rows()).map((m) => m.occurred),
          contains(DateTime(year, 3, 31)),
        );
        expect(
          (await rows()).map((m) => m.occurred),
          isNot(contains(DateTime(year, 3, year == 2028 ? 29 : 28))),
        );
      },
    );
  }

  test(
    'revisar una plantilla futura la reemplaza; detener elimina solo futuro',
    () async {
      final root = await ledger.save(item(TransactionType.expense));
      now = DateTime(2026, 3, 1);
      await ledger.generateDue();
      final history = financialHistory(await rows());
      var future = await ledger.reviseFuture(
        root.copyWith(date: DateTime(2026, 4, 1)),
      );
      future = await ledger.reviseFuture(
        future.copyWith(date: DateTime(2026, 4, 5), amountCop: 200000),
      );
      expect(await rows(), hasLength(4));
      expect(financialHistory(await rows()), history);
      await ledger.stopFuture(future.id);
      now = DateTime(2026, 6, 1);
      await ledger.generateDue();
      expect(financialHistory(await rows()), history);
      expect(await rows(), hasLength(3));
      LocalBackup(db).prepare(await LocalBackup(db).export());
    },
  );

  test('editar solo la primera ocurrencia futura mantiene esa ocurrencia y su sucesor', () async {
    final root = await ledger.save(item(TransactionType.expense));
    final future = await ledger.reviseFuture(
      root.copyWith(date: DateTime(2026, 2, 1)),
    );
    await LocalTransactions(ledger)
        .updateTransaction(future.copyWith(amountCop: 50000));
    final data = await rows();
    expect(
      data.singleWhere((m) => m.occurred == DateTime(2026, 2, 1)).amount,
      50000,
    );
    expect(
      data.singleWhere((m) => m.occurred == DateTime(2026, 3, 1)).amount,
      100000,
    );
    expect(data.where((m) => m.nextDue != null), hasLength(1));
    LocalBackup(db).prepare(await LocalBackup(db).export());
  });

  test('fecha pasada y escritura fallida no dejan series parciales', () async {
    final root = await ledger.save(item(TransactionType.expense));
    final before = await rows();
    await expectLater(ledger.reviseFuture(root), throwsFormatException);
    await expectLater(
      ledger.reviseFuture(
        root.copyWith(
          date: DateTime(2026, 2, 1),
          categoryOrOrigin: 'No existe',
        ),
      ),
      throwsA(anything),
    );
    expect(await rows(), before);
  });

  test('cambiar frecuencia mediante escritura de bajo nivel no genera fechas retroactivas', () async {
    final root = await ledger.save(item(TransactionType.additionalIncome));
    now = DateTime(2026, 3, 1);
    await ledger.generateDue();
    await ledger.save(
      root.copyWith(recurrence: RecurrenceFrequency.weekly),
      update: true,
    );
    await ledger.generateDue();
    expect(await rows(), hasLength(3));
    expect(
      (await rows()).singleWhere((m) => m.id == root.id).nextDue!.isAfter(now),
      isTrue,
    );
  });

  test('copias rechazan salarios duplicados, reglas simultáneas y tipos de pendiente inválidos', () async {
    await ledger.configureSalary(2400000, true);
    final backup = LocalBackup(db);
    final encoded = await backup.export();
    Map<String, dynamic> data() =>
        jsonDecode(utf8.decode(encoded)) as Map<String, dynamic>;
    Uint8List bytes(Map<String, dynamic> value) =>
        Uint8List.fromList(utf8.encode(jsonEncode(value)));
    final duplicate = data();
    final salaries = duplicate['movements'] as List;
    salaries.add({
      ...Map<String, dynamic>.from(salaries.single as Map),
      'id': 'duplicate',
    });
    expect(() => backup.prepare(bytes(duplicate)), throwsFormatException);
    final parallel = data();
    final template = Map<String, dynamic>.from(
      (parallel['movements'] as List).single as Map,
    );
    (parallel['movements'] as List).add({
      ...template,
      'id': 'parallel',
      'occurred': DateTime(2026, 2, 1).millisecondsSinceEpoch,
      'nextDue': DateTime(2026, 3, 1).millisecondsSinceEpoch,
    });
    expect(() => backup.prepare(bytes(parallel)), throwsFormatException);
    final invalidPending = data();
    (invalidPending['movements'] as List).single['status'] = 'pending';
    expect(() => backup.prepare(bytes(invalidPending)), throwsFormatException);
    expect((await rows()).single.amount, 2400000);
  });

  test('copias formato 1 siguen siendo legibles; exportaciones nuevas usan formato 2', () async {
    await ledger.save(item(TransactionType.expense));
    final backup = LocalBackup(db);
    final payload =
        jsonDecode(utf8.decode(await backup.export())) as Map<String, dynamic>;
    expect(payload['formatVersion'], 2);
    payload['formatVersion'] = 1;
    final archive = backup.prepare(
      Uint8List.fromList(utf8.encode(jsonEncode(payload))),
    );
    await backup.restore(archive);
    expect((await rows()).single.amount, 100000);
    payload['formatVersion'] = 99;
    expect(
      () =>
          backup.prepare(Uint8List.fromList(utf8.encode(jsonEncode(payload)))),
      throwsFormatException,
    );
  });

  test(
    'las copias rechazan ciclos y relaciones entre gastos e ingresos',
    () async {
      final root = await ledger.save(item(TransactionType.expense));
      now = DateTime(2026, 2, 1);
      await ledger.generateDue();
      final backup = LocalBackup(db);
      final payload = jsonDecode(
        utf8.decode(await backup.export()),
      ) as Map<String, dynamic>;
      final movements = payload['movements'] as List;
      final original = movements.singleWhere(
        (m) => m['id'] == root.id,
      ) as Map<String, dynamic>;
      final child = movements.singleWhere(
        (m) => m['id'] != root.id,
      ) as Map<String, dynamic>;
      child['kind'] = 'additionalIncome';
      expect(
        () => backup.prepare(
          Uint8List.fromList(utf8.encode(jsonEncode(payload))),
        ),
        throwsFormatException,
      );
      child['kind'] = 'expense';
      original['frequency'] = 'none';
      original['nextDue'] = null;
      original['parent'] = child['id'];
      expect(
        () => backup.prepare(
          Uint8List.fromList(utf8.encode(jsonEncode(payload))),
        ),
        throwsFormatException,
      );
    },
  );

  test('huella nueva enlaza recibo antiguo y permanece deduplicada tras descarte y restauración', () async {
    final queue = _Notices();
    final repo = LocalDetection(ledger, queue);
    final notice = {
      'id': 'old',
      'app': 'Nequi',
      'merchant': 'Tienda',
      'amount': 12000,
      'date': now.millisecondsSinceEpoch,
    };
    queue.items = [notice];
    await repo.importQueue();
    queue.items = [
      {...notice, 'id': 'canonical', 'legacyId': 'old'},
    ];
    await repo.importQueue();
    expect(await rows(), hasLength(1));
    await repo.removePendingMovement('old');
    final backup = LocalBackup(db);
    await backup.restore(backup.prepare(await backup.export()));
    queue.items = [
      {...notice, 'id': 'canonical', 'legacyId': 'different-case-old-hash'},
    ];
    await repo.importQueue();
    expect(await rows(), isEmpty);
  });
}

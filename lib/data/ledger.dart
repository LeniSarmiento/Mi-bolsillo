import 'package:drift/drift.dart';

import '../features/income/domain/additional_income.dart';
import '../features/transactions/domain/transaction_item.dart';
import 'finance_database.dart';

DateTime dayOf(DateTime d) => DateTime(d.year, d.month, d.day);
DateTime nextDate(
  DateTime previous,
  RecurrenceFrequency frequency,
  int anchorDay,
) {
  if (frequency == RecurrenceFrequency.monthly) {
    final last = DateTime(previous.year, previous.month + 2, 0).day;
    return DateTime(
      previous.year,
      previous.month + 1,
      anchorDay.clamp(1, last),
    );
  }
  if (frequency == RecurrenceFrequency.none) {
    throw ArgumentError('Frecuencia vacía');
  }
  return DateTime(
    previous.year,
    previous.month,
    previous.day + (frequency == RecurrenceFrequency.weekly ? 7 : 14),
  );
}

class Ledger {
  Ledger(this.db, {DateTime Function()? clock}) : now = clock ?? DateTime.now;
  final FinanceDatabase db;
  final DateTime Function() now;
  Future<String> newId() async =>
      (await db
              .customSelect('SELECT lower(hex(randomblob(16))) AS id')
              .getSingle())
          .read<String>('id');

  Future<void> generateDue() => db.transaction(() async {
    final today = dayOf(now());
    final due = await (db.select(
      db.movements,
    )..where((m) => m.nextDue.isSmallerOrEqualValue(today))).get();
    for (final template in due) {
      final freq = RecurrenceFrequency.values.byName(template.frequency);
      var date = template.nextDue!;
      while (!date.isAfter(today)) {
        await db
            .into(db.movements)
            .insert(
              template
                  .toCompanion(false)
                  .copyWith(
                    id: Value(await newId()),
                    parent: Value(template.id),
                    scheduled: Value(date),
                    occurred: Value(date),
                    created: Value(now()),
                    updated: Value(now()),
                    frequency: const Value('none'),
                    nextDue: const Value(null),
                    source: const Value('recurring'),
                  ),
              mode: InsertMode.insertOrIgnore,
            );
        date = nextDate(date, freq, template.occurred.day);
      }
      await (db.update(db.movements)..where((m) => m.id.equals(template.id)))
          .write(MovementsCompanion(nextDue: Value(date)));
    }
  });

  Future<List<Movement>> confirmed({required bool incomes}) async {
    await generateDue();
    return (db.select(db.movements)
          ..where(
            (m) =>
                m.status.equals('confirmed') &
                (incomes
                    ? m.kind.equals('additionalIncome')
                    : m.kind.equals('additionalIncome').not()),
          )
          ..orderBy([
            (m) => OrderingTerm.desc(m.occurred),
            (m) => OrderingTerm.desc(m.created),
          ]))
        .get();
  }

  Future<TransactionItem> save(
    TransactionItem t, {
    bool update = false,
  }) => db.transaction(() async {
    if (t.amountCop <= 0 || t.description.trim().isEmpty) {
      throw const FormatException('Revisa el monto y la descripción');
    }
    final id = t.id.isEmpty ? await newId() : t.id;
    final selector = db.select(db.movements)..where((m) => m.id.equals(id));
    final previous = update ? await selector.getSingle() : null;
    final scheduleChanged =
        previous == null ||
        previous.frequency != t.recurrence.name ||
        dayOf(previous.occurred) != dayOf(t.date);
    final next = t.recurrence == RecurrenceFrequency.none
        ? null
        : scheduleChanged
        ? nextDate(t.date, t.recurrence, t.date.day)
        : previous.nextDue;
    final row = MovementsCompanion.insert(
      id: id,
      kind: t.type.name,
      amount: t.amountCop,
      description: t.description.trim(),
      category: t.categoryOrOrigin,
      occurred: t.date,
      method: t.paymentMethod,
      source: Value(
        previous?.source ?? (t.isAutomatic ? 'notification' : t.source.name),
      ),
      status: Value(t.status.name),
      note: Value(t.note),
      frequency: Value(t.recurrence.name),
      nextDue: Value(next),
      created: previous?.created ?? now(),
      updated: now(),
    );
    if (update) {
      await (db.update(db.movements)..where((m) => m.id.equals(id))).write(row);
    } else {
      await db.into(db.movements).insert(row);
    }
    return t.copyWith(id: id);
  });

  Future<void> remove(String id) =>
      (db.delete(db.movements)..where((m) => m.id.equals(id))).go();
  TransactionItem asTransaction(Movement m) => TransactionItem(
    createdAt: m.created,
    updatedAt: m.updated,
    status: MovementStatus.values.byName(m.status),
    source: MovementSource.values.byName(m.source),
    id: m.id,
    description: m.description,
    amountCop: m.amount,
    type: TransactionType.values.byName(m.kind),
    categoryOrOrigin: m.category,
    date: m.occurred,
    paymentMethod: m.method,
    isAutomatic: m.source == 'notification',
    recurrence: RecurrenceFrequency.values.byName(m.frequency),
    note: m.note,
  );
  AdditionalIncome asIncome(Movement m) => AdditionalIncome(
    id: m.id,
    amountCop: m.amount,
    reason: m.description,
    origin: m.category,
    date: m.occurred,
    receptionMethod: m.method,
    note: m.note,
    recurrence: RecurrenceFrequency.values.byName(m.frequency),
    nextOccurrence: m.nextDue,
  );
  TransactionItem incomeEntry(AdditionalIncome i) => TransactionItem(
    id: i.id,
    description: i.reason,
    amountCop: i.amountCop,
    type: TransactionType.additionalIncome,
    categoryOrOrigin: i.origin,
    date: i.date,
    paymentMethod: i.receptionMethod,
    isAutomatic: false,
    recurrence: i.recurrence,
    note: i.note,
  );

  /// A base salary is one dated ledger entry per month. Freeze earlier
  /// months before changing the amount or the repeat preference.
  Future<void> configureSalary(int amount, bool repeat) =>
      db.transaction(() async {
        await generateDue();
        final current = now();
        final start = DateTime(current.year, current.month);
        final end = DateTime(current.year, current.month + 1);
        final entries =
            await (db.select(db.movements)..where(
                  (m) =>
                      m.kind.equals('baseIncome') &
                      m.occurred.isBiggerOrEqualValue(start) &
                      m.occurred.isSmallerThanValue(end),
                ))
                .get();
        await (db.update(
          db.movements,
        )..where((m) => m.kind.equals('baseIncome'))).write(
          const MovementsCompanion(
            nextDue: Value(null),
            frequency: Value('none'),
          ),
        );
        if (amount == 0) {
          for (final m in entries) {
            await remove(m.id);
          }
          return;
        }
        final entry = TransactionItem(
          id: entries.firstOrNull?.id ?? '',
          description: 'Ingreso mensual',
          amountCop: amount,
          type: TransactionType.baseIncome,
          categoryOrOrigin: 'Salario',
          date: start,
          paymentMethod: 'Ingreso mensual',
          isAutomatic: false,
          recurrence: repeat
              ? RecurrenceFrequency.monthly
              : RecurrenceFrequency.none,
        );
        await save(entry, update: entries.isNotEmpty);
      });
}

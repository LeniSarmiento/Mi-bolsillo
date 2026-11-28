import 'package:drift/drift.dart';

import '../features/income/domain/additional_income.dart';
import '../features/transactions/domain/transaction_item.dart';
import 'finance_database.dart';
import 'recurrence_limits.dart';

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
    var planned = 0;
    for (final template in due) {
      planned += RecurrenceLimits.catchUp(
        template.nextDue!,
        RecurrenceFrequency.values.byName(template.frequency),
        today,
      );
      RecurrenceLimits.totals(due.length, planned);
    }
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
        date = nextDate(
          date,
          freq,
          (template.scheduled ?? template.occurred).day,
        );
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
    RecurrenceLimits.date(t.date, now());
    if (t.amountCop <= 0 ||
        t.amountCop > 9007199254740991 ||
        t.description.trim().isEmpty) {
      throw const FormatException('Revisa el monto y la descripción');
    }
    final id = t.id.isEmpty ? await newId() : t.id;
    final selector = db.select(db.movements)..where((m) => m.id.equals(id));
    final previous = update ? await selector.getSingle() : null;
    if (previous?.parent != null &&
        t.type != TransactionType.baseIncome &&
        t.recurrence != RecurrenceFrequency.none) {
      throw const FormatException(
        'Edita la programación original para cambiar próximas repeticiones',
      );
    }
    final scheduleChanged =
        previous == null ||
        previous.frequency != t.recurrence.name ||
        dayOf(previous.occurred) != dayOf(t.date);
    var next = t.recurrence == RecurrenceFrequency.none
        ? null
        : scheduleChanged
        ? nextDate(t.date, t.recurrence, t.date.day)
        : previous.nextDue;
    // Editing a date/frequency never creates newly confirmed backdated entries.
    // Creation may intentionally catch up a user-specified historical series.
    if (update && scheduleChanged && next != null) {
      while (!next!.isAfter(dayOf(now()))) {
        next = nextDate(next, t.recurrence, t.date.day);
      }
    }
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
      parent: t.type == TransactionType.baseIncome
          ? const Value(null)
          : const Value.absent(),
      scheduled:
          t.type == TransactionType.baseIncome ||
              (previous?.parent == null && scheduleChanged)
          ? const Value(null)
          : const Value.absent(),
    );
    if (update) {
      await (db.update(db.movements)..where((m) => m.id.equals(id))).write(row);
    } else {
      await db.into(db.movements).insert(row);
    }
    if (t.recurrence != RecurrenceFrequency.none) {
      final rules = await (db.select(
        db.movements,
      )..where((m) => m.nextDue.isNotNull())).get();
      var planned = 0;
      for (final rule in rules) {
        planned += RecurrenceLimits.catchUp(
          rule.nextDue!,
          RecurrenceFrequency.values.byName(rule.frequency),
          now(),
        );
      }
      RecurrenceLimits.totals(rules.length, planned);
    }
    return t.copyWith(id: id);
  });

  Future<Movement> _movement(String id) async {
    final row = await (db.select(
      db.movements,
    )..where((m) => m.id.equals(id))).getSingleOrNull();
    if (row == null) {
      throw const FormatException('El movimiento cambió. Recarga la lista.');
    }
    return row;
  }

  /// A series is represented by a dated template. Forking schedules a new
  /// future template and freezes the previous one without rewriting its money
  /// or date. All historical members keep a link to the active template.
  Future<TransactionItem> _fork(
    Movement original,
    TransactionItem future, {
    bool retainOriginal = false,
  }) async {
    final id = await newId();
    final replacement = TransactionItem(
      id: id,
      description: future.description,
      amountCop: future.amountCop,
      type: future.type,
      categoryOrOrigin: future.categoryOrOrigin,
      date: dayOf(future.date),
      paymentMethod: future.paymentMethod,
      isAutomatic: false,
      recurrence: future.recurrence,
      note: future.note,
      source: MovementSource.recurring,
    );
    // Replacement consumes the same rule slot; rollback restores the original
    // if any later validation or write fails.
    await (db.update(
      db.movements,
    )..where((m) => m.id.equals(original.id))).write(
      const MovementsCompanion(frequency: Value('none'), nextDue: Value(null)),
    );
    await save(replacement);
    final sameSchedule =
        original.frequency == future.recurrence.name &&
        (dayOf(future.date) == dayOf(original.nextDue!) ||
            dayOf(future.date) == dayOf(original.occurred));
    final anchor = sameSchedule
        ? original.scheduled ?? original.occurred
        : dayOf(future.date);
    await (db.update(db.movements)..where((m) => m.id.equals(id))).write(
      MovementsCompanion(
        scheduled: Value(anchor),
        nextDue: Value(nextDate(future.date, future.recurrence, anchor.day)),
      ),
    );
    await (db.update(db.movements)..where((m) => m.parent.equals(original.id)))
        .write(MovementsCompanion(parent: Value(id)));
    if (!retainOriginal && dayOf(original.occurred).isAfter(dayOf(now()))) {
      await remove(original.id);
    } else {
      await (db.update(
        db.movements,
      )..where((m) => m.id.equals(original.id))).write(
        MovementsCompanion(
          parent: Value(id),
          scheduled: const Value(null),
          frequency: const Value('none'),
          nextDue: const Value(null),
          updated: Value(now()),
        ),
      );
    }
    return asTransaction(await _movement(id));
  }

  Future<TransactionItem> reviseFuture(TransactionItem future) =>
      db.transaction(() async {
        if (!dayOf(future.date).isAfter(dayOf(now()))) {
          throw const FormatException(
            'La primera repetición debe ser posterior a hoy',
          );
        }
        if (future.recurrence == RecurrenceFrequency.none) {
          throw const FormatException(
            'Elige una frecuencia o detén las próximas repeticiones',
          );
        }
        await generateDue();
        final original = await _movement(future.id);
        if (original.kind == 'baseIncome' ||
            original.kind != future.type.name ||
            original.parent != null ||
            original.frequency == 'none') {
          throw const FormatException(
            'La programación cambió. Recarga los movimientos.',
          );
        }
        return _fork(original, future);
      });

  Future<void> stopFuture(String id) => db.transaction(() async {
    await generateDue();
    final original = await _movement(id);
    if (original.kind == 'baseIncome' ||
        original.parent != null ||
        original.frequency == 'none') {
      throw const FormatException(
        'La programación cambió. Recarga los movimientos.',
      );
    }
    if (dayOf(original.occurred).isAfter(dayOf(now()))) {
      await remove(id);
    } else {
      await (db.update(db.movements)..where((m) => m.id.equals(id))).write(
        MovementsCompanion(
          frequency: const Value('none'),
          nextDue: const Value(null),
          updated: Value(now()),
        ),
      );
    }
  });

  Future<TransactionItem> editOccurrence(
    TransactionItem item,
  ) => db.transaction(() async {
    await generateDue();
    final original = await _movement(item.id);
    if (original.kind != item.type.name || original.kind == 'baseIncome') {
      throw const FormatException('Modifica el ingreso base desde Perfil');
    }
    var edited = item;
    if (original.frequency != 'none') {
      // Keep this occurrence even when it is itself scheduled in the future.
      // The successor begins at the old nextDue, preserving its anchor date.
      final future = asTransaction(original).copyWith(date: original.nextDue!);
      await _fork(original, future, retainOriginal: true);
      edited = item.copyWith(recurrence: RecurrenceFrequency.none);
    }
    await save(edited, update: true);
    return asTransaction(await _movement(item.id));
  });

  Future<void> remove(String id) =>
      (db.delete(db.movements)..where((m) => m.id.equals(id))).go();
  TransactionItem asTransaction(Movement m) => TransactionItem(
    createdAt: m.created,
    updatedAt: m.updated,
    status: MovementStatus.values.byName(m.status),
    source: MovementSource.values.byName(m.source),
    parentId: m.parent,
    nextOccurrence: m.nextDue,
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
    parentId: m.parent,
    source: MovementSource.values.byName(m.source),
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
    parentId: i.parentId,
    source: i.source,
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

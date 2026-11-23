import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../features/transactions/domain/transaction_item.dart';
import '../features/income/domain/additional_income.dart';

part 'finance_database.g.dart';

class Categories extends Table {
  TextColumn get label => text()();
  @override
  Set<Column> get primaryKey => {label};
}

@TableIndex(name: 'movement_period', columns: {#kind, #status, #occurred})
class Movements extends Table {
  TextColumn get id => text()();
  TextColumn get kind => text()();
  IntColumn get amount =>
      integer().customConstraint('NOT NULL CHECK (amount > 0)')();
  TextColumn get description => text()();
  TextColumn get category => text().references(Categories, #label)();
  DateTimeColumn get occurred => dateTime()();
  TextColumn get method => text()();
  TextColumn get source => text().withDefault(const Constant('manual'))();
  TextColumn get status => text().withDefault(const Constant('confirmed'))();
  TextColumn get note => text().withDefault(const Constant(''))();
  TextColumn get frequency => text().withDefault(const Constant('none'))();
  DateTimeColumn get nextDue => dateTime().nullable()();
  TextColumn get parent => text().nullable()();
  DateTimeColumn get scheduled => dateTime().nullable()();
  DateTimeColumn get created => dateTime()();
  DateTimeColumn get updated => dateTime()();
  @override
  Set<Column> get primaryKey => {id};
  @override
  List<Set<Column>> get uniqueKeys => [
    {parent, scheduled},
  ];
}

class SpendingLimits extends Table {
  TextColumn get id => text()();
  TextColumn get category => text().references(Categories, #label)();
  IntColumn get amount =>
      integer().customConstraint('NOT NULL CHECK (amount > 0)')();
  TextColumn get period => text()();
  BoolColumn get warn => boolean()();
  BoolColumn get exhausted => boolean()();
  @override
  Set<Column> get primaryKey => {id};
}

class Preferences extends Table {
  IntColumn get id => integer()();
  TextColumn get payload => text()();
  @override
  Set<Column> get primaryKey => {id};
}

/// Receipts survive dismissal and deletion of an imported transaction.
class DetectionReceipts extends Table {
  TextColumn get fingerprint => text()();
  TextColumn get sourceApp => text()();
  @override
  Set<Column> get primaryKey => {fingerprint};
}

@DriftDatabase(
  tables: [
    Categories,
    Movements,
    SpendingLimits,
    Preferences,
    DetectionReceipts,
  ],
)
class FinanceDatabase extends _$FinanceDatabase {
  FinanceDatabase(super.e);
  FinanceDatabase.local()
    : super(
        driftDatabase(
          name: 'mi_bolsillo',
          web: DriftWebOptions(
            onResult: (result) {
              if (result.chosenImplementation.name == 'inMemory') {
                throw StateError('Almacenamiento persistente no disponible');
              }
            },
            sqlite3Wasm: Uri.parse('sqlite3.wasm'),
            driftWorker: Uri.parse('drift_worker.js'),
          ),
        ),
      );
  @override
  int get schemaVersion => 2;
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      for (final label in {
        ...ExpenseCategory.values.map((c) => c.label),
        ...IncomeOrigins.all,
        'Salario',
      }) {
        await into(categories).insert(Category(label: label));
      }
    },
    onUpgrade: (m, from, to) async {
      if (from == 1 && to == 2) {
        await m.createTable(detectionReceipts);
        return;
      }
      throw StateError('Versión de base de datos incompatible');
    },
    beforeOpen: (_) async => customStatement('PRAGMA foreign_keys = ON'),
  );
  Future<void> erase() => transaction(() async {
    await delete(movements).go();
    await delete(spendingLimits).go();
    await delete(preferences).go();
    await delete(detectionReceipts).go();
  });
}

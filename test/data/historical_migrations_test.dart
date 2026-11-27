import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_bolsillo/data/finance_database.dart';

// Frozen v1 schema: no detection or budget-alert receipt tables existed yet.
const _v1 = '''
CREATE TABLE categories (label TEXT NOT NULL PRIMARY KEY);
CREATE TABLE movements (
 id TEXT NOT NULL PRIMARY KEY, kind TEXT NOT NULL, amount INTEGER NOT NULL CHECK(amount > 0),
 description TEXT NOT NULL, category TEXT NOT NULL REFERENCES categories(label),
 occurred INTEGER NOT NULL, method TEXT NOT NULL, source TEXT NOT NULL DEFAULT 'manual',
 status TEXT NOT NULL DEFAULT 'confirmed', note TEXT NOT NULL DEFAULT '',
 frequency TEXT NOT NULL DEFAULT 'none', next_due INTEGER, parent TEXT, scheduled INTEGER,
 created INTEGER NOT NULL, updated INTEGER NOT NULL, UNIQUE(parent, scheduled));
CREATE INDEX movement_period ON movements(kind, status, occurred);
CREATE TABLE spending_limits (id TEXT NOT NULL PRIMARY KEY, category TEXT NOT NULL REFERENCES categories(label),
 amount INTEGER NOT NULL CHECK(amount > 0), period TEXT NOT NULL, warn INTEGER NOT NULL, exhausted INTEGER NOT NULL);
CREATE TABLE preferences (id INTEGER NOT NULL PRIMARY KEY, payload TEXT NOT NULL);
INSERT INTO categories VALUES ('Compras');
INSERT INTO movements (id,kind,amount,description,category,occurred,method,created,updated)
 VALUES ('old','expense',1250,'Histórico','Compras',1767225600,'Efectivo',1767225600,1767225600);
INSERT INTO spending_limits VALUES ('budget','Compras',90000,'monthly',1,1);
INSERT INTO preferences VALUES (1,'{"salary":0,"hide":true}');
''';

void main() {
  for (final version in [1, 2]) {
    test(
      'migración auténtica v$version a v3 crea tablas faltantes y conserva datos',
      () async {
        final db = FinanceDatabase(
          NativeDatabase.memory(
            setup: (raw) {
              for (final statement
                  in _v1.split(';').where((s) => s.trim().isNotEmpty)) {
                raw.execute(statement);
              }
              if (version == 2) {
                raw.execute(
                  'CREATE TABLE detection_receipts (fingerprint TEXT NOT NULL PRIMARY KEY, source_app TEXT NOT NULL)',
                );
                raw.execute(
                  "INSERT INTO detection_receipts VALUES ('old-notice','Nequi')",
                );
              }
              raw.execute('PRAGMA user_version=$version');
            },
          ),
        );
        addTearDown(db.close);
        expect((await db.select(db.movements).get()).single.amount, 1250);
        expect((await db.select(db.spendingLimits).get()).single.amount, 90000);
        expect(
          (await db.select(db.preferences).get()).single.payload,
          contains('"hide":true'),
        );
        expect(
          await db.select(db.detectionReceipts).get(),
          hasLength(version == 2 ? 1 : 0),
        );
        expect(await db.select(db.budgetAlertReceipts).get(), isEmpty);
        await db
            .into(db.budgetAlertReceipts)
            .insert(BudgetAlertReceipt(key: 'new', created: DateTime(2026)));
        expect(
          (await db.customSelect('PRAGMA user_version').getSingle()).read<int>(
            'user_version',
          ),
          3,
        );
        expect(
          (await db.customSelect('PRAGMA foreign_keys').getSingle()).read<int>(
            'foreign_keys',
          ),
          1,
        );
      },
    );
  }
}

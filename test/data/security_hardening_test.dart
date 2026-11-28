import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:mi_bolsillo/core/security/backup_cipher.dart';
import 'package:mi_bolsillo/data/encrypted_database_files.dart';
import 'package:mi_bolsillo/data/finance_database.dart';
import 'package:mi_bolsillo/data/ledger.dart';
import 'package:mi_bolsillo/data/local_backup.dart';
import 'package:mi_bolsillo/data/recurrence_limits.dart';
import 'package:mi_bolsillo/features/transactions/domain/transaction_item.dart';

const _marker = 'SECURITY_TEST_SYNTHETIC_12456';
const _password = 'Una contraseña de prueba 2026';
final _key = List.filled(32, 'ab').join();

TransactionItem _entry() => TransactionItem(
  id: '',
  description: _marker,
  amountCop: 1000,
  type: TransactionType.expense,
  categoryOrOrigin: 'Compras',
  date: DateTime(2026, 1, 1),
  paymentMethod: 'Efectivo',
  isAutomatic: false,
  recurrence: RecurrenceFrequency.none,
);

void main() {
  test('editing a series at the rule cap preserves its slot and rejects an extra rule', () async {
    final db = FinanceDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final now = DateTime(2026, 1, 1);
    final ledger = Ledger(db, clock: () => now);
    final original = await ledger.save(
      _entry().copyWith(recurrence: RecurrenceFrequency.monthly),
    );
    await db.transaction(() async {
      for (var i = 1; i < RecurrenceLimits.maxRules; i++) {
        await ledger.save(
          _entry().copyWith(recurrence: RecurrenceFrequency.monthly),
        );
      }
    });
    final replacement = await ledger.reviseFuture(
      original.copyWith(date: DateTime(2026, 2, 1), amountCop: 2000),
    );
    expect(replacement.id, isNot(original.id));
    await expectLater(
      ledger.save(_entry().copyWith(recurrence: RecurrenceFrequency.monthly)),
      throwsFormatException,
    );
    expect(
      (await db.select(db.movements).get()).where((r) => r.nextDue != null),
      hasLength(RecurrenceLimits.maxRules),
    );
  });

  test('empty encrypted destination never causes deletion of a valid legacy database', () async {
    final dir = await Directory.systemTemp.createTemp(
      'mi_bolsillo_migration_retry_',
    );
    addTearDown(() => dir.delete(recursive: true));
    final oldPath = '${dir.path}/legacy.sqlite';
    final newPath = '${dir.path}/secure.sqlite';
    final db = FinanceDatabase(NativeDatabase(File(oldPath)));
    await Ledger(db).save(_entry());
    await db.close();
    final original = await File(oldPath).readAsBytes();
    await File(newPath).writeAsBytes([]);
    await expectLater(
      migrateEncryptedDatabase(oldPath, newPath, _key),
      throwsStateError,
    );
    expect(await File(oldPath).readAsBytes(), original);
    await File(newPath).delete();
    await migrateEncryptedDatabase(oldPath, newPath, _key);
    // Simulate publication succeeding but cleanup being interrupted.
    await File(oldPath).writeAsBytes(original);
    await migrateEncryptedDatabase(oldPath, newPath, _key);
    expect(await File(oldPath).exists(), isFalse);
    final check = sqlite3.open(newPath);
    configureEncryptedDatabase(check, _key);
    expect(
      check.select('SELECT description FROM movements').single['description'],
      _marker,
    );
    check.close();
  });
  test(
    'authenticated backup round trip rejects wrong password and altered bytes',
    () async {
      final cipher = BackupCipher();
      final plain = Uint8List.fromList(utf8.encode(_marker));
      final file = await cipher.encrypt(plain, _password);
      expect(BackupCipher.isEncrypted(file), isTrue);
      expect(latin1.decode(file), isNot(contains(_marker)));
      expect(await cipher.decrypt(file, _password), plain);
      await expectLater(
        cipher.decrypt(file, 'Contraseña equivocada'),
        throwsFormatException,
      );
      final changed = Uint8List.fromList(file)..[file.length - 1] ^= 1;
      await expectLater(
        cipher.decrypt(changed, _password),
        throwsFormatException,
      );
      final second = await cipher.encrypt(plain, _password);
      expect(second, isNot(file));
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

  test(
    'hostile KDF, truncation and weak passwords are rejected before decryption',
    () async {
      expect(
        () => BackupCipher.validatePassword('short'),
        throwsFormatException,
      );
      final file = Uint8List(100)..setRange(0, 8, ascii.encode('MBSAFE01'));
      ByteData.sublistView(file, 8, 12).setUint32(0, 0xffffffff);
      await expectLater(
        BackupCipher().decrypt(file, _password),
        throwsFormatException,
      );
      await expectLater(
        BackupCipher().decrypt(Uint8List(4), _password),
        throwsFormatException,
      );
    },
  );

  test(
    'ancient schedules and excessive catch-up are rejected before restore',
    () async {
      final db = FinanceDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final ledger = Ledger(db, clock: () => DateTime(2026, 1, 1));
      await ledger.save(_entry());
      final backup = LocalBackup(db);
      final data = jsonDecode(
        utf8.decode(await backup.export()),
      ) as Map<String, dynamic>;
      final row = (data['movements'] as List).single as Map<String, dynamic>;
      row['occurred'] = DateTime(1).millisecondsSinceEpoch;
      row['nextDue'] = DateTime(1, 1, 8).millisecondsSinceEpoch;
      row['frequency'] = 'weekly';
      expect(
        () => backup.prepare(Uint8List.fromList(utf8.encode(jsonEncode(data)))),
        throwsFormatException,
      );
      expect((await db.select(db.movements).getSingle()).description, _marker);
      expect(() => RecurrenceLimits.totals(201, 10), throwsFormatException);
      expect(() => RecurrenceLimits.totals(1, 10001), throwsFormatException);
      await expectLater(
        ledger.save(_entry().copyWith(date: DateTime(1))),
        throwsFormatException,
      );
    },
  );

  test(
    'generation preflight rejects oversized workload without partial writes',
    () async {
      final db = FinanceDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final ledger = Ledger(db, clock: () => DateTime(2026, 1, 1));
      final saved = await ledger.save(_entry());
      await db.customStatement(
        "UPDATE movements SET occurred = ?, next_due = ?, frequency = 'weekly' WHERE id = ?",
        [
          DateTime(1).millisecondsSinceEpoch ~/ 1000,
          DateTime(1, 1, 8).millisecondsSinceEpoch ~/ 1000,
          saved.id,
        ],
      );
      await expectLater(ledger.generateDue(), throwsFormatException);
      expect(await db.select(db.movements).get(), hasLength(1));
    },
  );

  test('plaintext migration preserves schema and records, wrong key cannot open', () async {
    final dir = await Directory.systemTemp.createTemp(
      'mi_bolsillo_cipher_test_',
    );
    addTearDown(() => dir.delete(recursive: true));
    final oldPath = '${dir.path}/legacy.sqlite';
    final newPath = '${dir.path}/secure.sqlite';
    final oldDb = FinanceDatabase(NativeDatabase(File(oldPath)));
    await Ledger(oldDb).save(_entry());
    await oldDb.close();
    expect(latin1.decode(await File(oldPath).readAsBytes()), contains(_marker));
    await migrateEncryptedDatabase(oldPath, newPath, _key);
    expect(await File(oldPath).exists(), isFalse);
    expect(
      latin1.decode(await File(newPath).readAsBytes()),
      isNot(contains(_marker)),
    );
    final raw = sqlite3.open(newPath);
    expect(
      () => raw.select('SELECT * FROM movements'),
      throwsA(isA<SqliteException>()),
    );
    raw.close();
    final wrong = sqlite3.open(newPath);
    expect(
      () => configureEncryptedDatabase(wrong, List.filled(32, 'cd').join()),
      throwsA(isA<SqliteException>()),
    );
    wrong.close();
    final restored = FinanceDatabase(
      NativeDatabase(
        File(newPath),
        setup: (db) => configureEncryptedDatabase(db, _key),
      ),
    );
    expect(
      (await restored.select(restored.movements).getSingle()).description,
      _marker,
    );
    expect(
      await restored
          .customSelect('PRAGMA user_version')
          .getSingle()
          .then((r) => r.read<int>('user_version')),
      3,
    );
    await restored.close();
    // Idempotent reopen completes cleanup without recopying or replacing data.
    await migrateEncryptedDatabase(oldPath, newPath, _key);
  });

  test(
    'failed migration retains original and secure deletion removes SQL residue',
    () async {
      final dir = await Directory.systemTemp.createTemp(
        'mi_bolsillo_delete_test_',
      );
      addTearDown(() => dir.delete(recursive: true));
      final path = '${dir.path}/legacy.sqlite';
      final db = FinanceDatabase(NativeDatabase(File(path)));
      await Ledger(db).save(_entry());
      await db.close();
      await expectLater(
        migrateEncryptedDatabase(path, '${dir.path}/secure.sqlite', 'invalid'),
        throwsArgumentError,
      );
      expect(latin1.decode(await File(path).readAsBytes()), contains(_marker));
      final reopened = FinanceDatabase(NativeDatabase(File(path)));
      await reopened.erase();
      await reopened.close();
      expect(
        latin1.decode(await File(path).readAsBytes()),
        isNot(contains(_marker)),
      );
    },
  );
}

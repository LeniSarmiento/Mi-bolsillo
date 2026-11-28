import 'dart:io';
import 'dart:typed_data';

import 'package:sqlite3/sqlite3.dart';

void configureEncryptedDatabase(Database db, String key) {
  if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(key)) {
    throw ArgumentError('Invalid local key');
  }
  if (db.select('PRAGMA cipher').isEmpty) {
    throw StateError('Encryption support is required');
  }
  db.execute("PRAGMA cipher = 'chacha20'");
  // Only a fixed-size random hexadecimal string is interpolated, never user input.
  db.execute("PRAGMA key = '$key'");
  db.execute('PRAGMA secure_delete = ON');
  db.execute('PRAGMA temp_store = MEMORY');
  db.select('SELECT count(*) FROM sqlite_master'); // Wrong key fails closed.
}

void _verify(Database db, {bool requireSchema = false}) {
  if (db.select('PRAGMA integrity_check').single.values.single != 'ok') {
    throw StateError('Database verification failed');
  }
  if (requireSchema &&
      db
          .select(
            "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'movements'",
          )
          .isEmpty) {
    throw StateError('The migrated database is incomplete');
  }
}

/// Best-effort physical cleanup. Flash wear levelling cannot guarantee erasure;
/// new financial writes are encrypted, and secure_delete clears freed SQL pages.
Future<void> _removePrivateFile(File file) async {
  if (!await file.exists()) return;
  final handle = await file.open(mode: FileMode.append);
  try {
    final size = await handle.length();
    await handle.setPosition(0);
    final zeros = Uint8List(65536);
    for (var written = 0; written < size; written += zeros.length) {
      await handle.writeFrom(zeros, 0, (size - written).clamp(0, zeros.length));
    }
    await handle.flush();
    await handle.truncate(0);
  } finally {
    await handle.close();
  }
  await file.delete();
}

Future<void> _removeFamily(String path) async {
  for (final suffix in ['', '-wal', '-shm', '-journal']) {
    await _removePrivateFile(File('$path$suffix'));
  }
}

/// Copy -> encrypt -> verify -> publish -> scrub legacy. A failed migration never
/// removes the original. A retry after publication only cleans the old files.
Future<void> migrateEncryptedDatabase(
  String legacy,
  String encrypted,
  String key,
) async {
  final destination = File(encrypted);
  if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(key)) {
    throw ArgumentError('Invalid local key');
  }
  if (await destination.exists()) {
    final hasLegacy = await File(legacy).exists();
    final db = sqlite3.open(encrypted);
    try {
      configureEncryptedDatabase(db, key);
      _verify(db, requireSchema: hasLegacy);
    } finally {
      db.close();
    }
    await _removeFamily(legacy);
    await _removeFamily('$encrypted.migrating');
    return;
  }
  if (!await File(legacy).exists()) return;
  final temporary = '$encrypted.migrating';
  await _removeFamily(temporary);
  final source = sqlite3.open(legacy, mode: OpenMode.readOnly);
  final copy = sqlite3.open(temporary);
  try {
    if (copy.select('PRAGMA cipher').isEmpty) {
      throw StateError('Encryption support is required');
    }
    await source.backup(copy).drain<void>();
    copy.execute('PRAGMA journal_mode = DELETE');
    copy.execute('PRAGMA temp_store = MEMORY');
    copy.execute("PRAGMA cipher = 'chacha20'");
    if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(key)) {
      throw ArgumentError('Invalid local key');
    }
    copy.execute("PRAGMA rekey = '$key'");
    _verify(copy, requireSchema: true);
  } finally {
    copy.close();
    source.close();
  }
  // Reopen with the same cipher/key before removing or renaming anything.
  final check = sqlite3.open(temporary);
  try {
    configureEncryptedDatabase(check, key);
    _verify(check, requireSchema: true);
  } finally {
    check.close();
  }
  await File(temporary).rename(encrypted);
  await _removeFamily(legacy);
  await _removeFamily(temporary);
}

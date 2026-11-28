import 'dart:io';
import 'dart:isolate';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/security/device_security.dart';
import 'encrypted_database_files.dart';

QueryExecutor openFinanceConnection() {
  if (!Platform.isAndroid) return driftDatabase(name: 'mi_bolsillo');
  return LazyDatabase(() async {
    final key = await DeviceSecurity.channel.invokeMethod<String>(
      'databaseKey',
    );
    if (key == null || !RegExp(r'^[a-f0-9]{64}$').hasMatch(key)) {
      throw StateError('No se pudo abrir la clave local');
    }
    final directory = await getApplicationDocumentsDirectory();
    final legacy = p.join(directory.path, 'mi_bolsillo.sqlite');
    final encrypted = p.join(directory.path, 'mi_bolsillo.secure.sqlite');
    await Isolate.run(() => migrateEncryptedDatabase(legacy, encrypted, key));
    return NativeDatabase.createInBackground(
      File(encrypted),
      setup: (db) => configureEncryptedDatabase(db, key),
    );
  });
}

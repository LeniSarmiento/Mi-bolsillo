import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

QueryExecutor openFinanceConnection() => driftDatabase(
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
);

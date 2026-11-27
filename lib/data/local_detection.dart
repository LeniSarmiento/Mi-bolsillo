import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../features/automatic_detection/domain/automatic_detection_repository.dart';
import '../features/automatic_detection/domain/pending_movement.dart';
import 'finance_database.dart';
import 'ledger.dart';

class NotificationBridge {
  static const channel = MethodChannel('com.mibolsillo.app/detections');
  bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  Future<bool> enabled() async =>
      supported && (await channel.invokeMethod<bool>('enabled') ?? false);
  Future<void> setEnabled(bool value) async {
    if (supported) await channel.invokeMethod<void>('setEnabled', value);
  }

  Future<List<Map<String, dynamic>>> peek() async {
    if (!supported) return [];
    final items = await channel.invokeListMethod<dynamic>('peek') ?? [];
    return items.map((v) => Map<String, dynamic>.from(v as Map)).toList();
  }

  Future<void> acknowledge(List<String> ids) async {
    if (supported && ids.isNotEmpty) {
      await channel.invokeMethod<void>('ack', ids);
    }
  }

  Future<void> erase() async {
    if (supported) await channel.invokeMethod<void>('erase');
  }
}

class LocalDetection
    implements AutomaticDetectionRepository, PendingReviewRepository {
  LocalDetection(this.ledger, this.bridge);
  final Ledger ledger;
  final NotificationBridge bridge;
  FinanceDatabase get db => ledger.db;
  @override
  Future<bool> isEnabled() => bridge.enabled();
  @override
  Future<void> setEnabled(bool enabled) => bridge.setEnabled(enabled);
  Future<void> importQueue() async {
    final ids = await db.transaction(() async {
      final items = await bridge.peek();
      for (final v in items) {
        final id = v['id'] as String;
        final legacy = v['legacyId'];
        final aliases = {id, if (legacy is String && legacy.isNotEmpty) legacy};
        final already = await (db.select(
          db.detectionReceipts,
        )..where((r) => r.fingerprint.isIn(aliases))).get();
        for (final alias in aliases) {
          await db
              .into(db.detectionReceipts)
              .insert(
                DetectionReceipt(
                  fingerprint: alias,
                  sourceApp: v['app'] as String,
                ),
                mode: InsertMode.insertOrIgnore,
              );
        }
        if (already.isNotEmpty) continue;
        await db
            .into(db.movements)
            .insert(
              MovementsCompanion.insert(
                id: id,
                kind: 'expense',
                amount: v['amount'] as int,
                description: v['merchant'] as String,
                category: 'Otros',
                occurred: DateTime.fromMillisecondsSinceEpoch(v['date'] as int),
                method: 'Tarjeta Bancaria',
                source: const Value('notification'),
                status: const Value('pending'),
                created: ledger.now(),
                updated: ledger.now(),
              ),
            );
      }
      return items.map((v) => v['id'] as String).toList();
    });
    await bridge.acknowledge(ids);
  }

  @override
  Future<List<PendingMovement>> getPendingMovements() async {
    await importQueue();
    final query =
        db.select(db.movements).join([
            innerJoin(
              db.detectionReceipts,
              db.detectionReceipts.fingerprint.equalsExp(db.movements.id),
            ),
          ])
          ..where(db.movements.status.equals('pending'))
          ..orderBy([OrderingTerm.desc(db.movements.occurred)]);
    return (await query.get()).map((row) {
      final m = row.readTable(db.movements);
      return PendingMovement(
        id: m.id,
        merchant: m.description,
        amountCop: m.amount,
        sourceApp: row.readTable(db.detectionReceipts).sourceApp,
        paymentMethod: m.method,
        suggestedCategory: m.category,
        confidencePercent: 0,
        detectedAt: m.occurred,
        notificationPreview: 'Posible compra detectada en este dispositivo',
      );
    }).toList();
  }

  @override
  Future<void> editPending(PendingMovement p) async {
    await (db.update(
      db.movements,
    )..where((m) => m.id.equals(p.id) & m.status.equals('pending'))).write(
      MovementsCompanion(
        category: Value(p.suggestedCategory),
        amount: Value(p.amountCop),
        description: Value(p.merchant),
        updated: Value(ledger.now()),
      ),
    );
  }

  @override
  Future<void> confirm(PendingMovement p, {String? category}) async {
    await (db.update(
      db.movements,
    )..where((m) => m.id.equals(p.id) & m.status.equals('pending'))).write(
      MovementsCompanion(
        status: const Value('confirmed'),
        category: Value(category ?? p.suggestedCategory),
        amount: Value(p.amountCop),
        description: Value(p.merchant),
        updated: Value(ledger.now()),
      ),
    );
  }

  @override
  Future<void> removePendingMovement(String id) => (db.delete(
    db.movements,
  )..where((m) => m.id.equals(id) & m.status.equals('pending'))).go();
  @override
  Future<void> clearPending() =>
      (db.delete(db.movements)..where((m) => m.status.equals('pending'))).go();
  @override
  Future<void> resetToMockDefaults() => clearPending();
}

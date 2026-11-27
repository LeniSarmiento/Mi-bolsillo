import 'dart:convert';
import 'dart:typed_data';

import '../features/budgets/domain/budget_item.dart';
import '../features/income/domain/additional_income.dart';
import '../features/transactions/domain/transaction_item.dart';
import 'finance_database.dart';

/// Portable local backup. Never uploads data; the user chooses the file location.
class LocalBackup {
  LocalBackup(this.db);
  final FinanceDatabase db;
  static const maxBytes = 20 * 1024 * 1024;

  Future<Uint8List> export() => db.transaction(() async {
    final data = <String, dynamic>{
      'application': 'mi_bolsillo',
      'formatVersion': 2,
      'schemaVersion': 3,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'categories': (await db.select(db.categories).get())
          .map((r) => r.toJson())
          .toList(),
      'movements': (await db.select(db.movements).get())
          .map((r) => r.toJson())
          .toList(),
      'budgets': (await db.select(db.spendingLimits).get())
          .map((r) => r.toJson())
          .toList(),
      'preferences': (await db.select(db.preferences).get())
          .map((r) => r.toJson())
          .toList(),
      'detectionReceipts': (await db.select(db.detectionReceipts).get())
          .map((r) => r.toJson())
          .toList(),
      'budgetAlertReceipts': (await db.select(db.budgetAlertReceipts).get())
          .map((r) => r.toJson())
          .toList(),
    };
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(data)));
    // A backup offered to the user must also be restorable by this version.
    prepare(bytes);
    return bytes;
  });

  BackupArchive prepare(Uint8List bytes) {
    try {
      if (bytes.length > maxBytes) throw const FormatException();
      final data = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      if (data['application'] != 'mi_bolsillo' ||
          !const [1, 2].contains(data['formatVersion']) ||
          data['schemaVersion'] != 3) {
        throw const FormatException();
      }
      List<T> rows<T>(String name, T Function(Map<String, dynamic>) parse) {
        final source = data[name] as List;
        if (source.length > 100000) throw const FormatException();
        return List.unmodifiable(
          source.map((r) => parse(Map<String, dynamic>.from(r as Map))),
        );
      }

      void require(bool ok) {
        if (!ok) throw const FormatException();
      }

      bool money(Object? v) => v is int && v > 0 && v <= 9007199254740991;
      final categories = rows('categories', (r) => Category.fromJson(r));
      final labels = categories.map((c) => c.label).toSet();
      require(
        labels.length == categories.length &&
            labels.every((s) => s.trim().isNotEmpty),
      );
      final movements = rows('movements', (r) {
        require(money(r['amount']));
        final m = Movement.fromJson(r);
        require(
          m.id.isNotEmpty &&
              m.description.trim().isNotEmpty &&
              labels.contains(m.category),
        );
        require(TransactionType.values.any((v) => v.name == m.kind));
        require(MovementStatus.values.any((v) => v.name == m.status));
        require(MovementSource.values.any((v) => v.name == m.source));
        require(RecurrenceFrequency.values.any((v) => v.name == m.frequency));
        require((m.frequency == 'none') == (m.nextDue == null));
        require(
          m.parent != m.id && (m.parent == null || m.frequency == 'none'),
        );
        require(m.nextDue == null || m.nextDue!.isAfter(m.occurred));
        return m;
      });
      require(movements.map((m) => m.id).toSet().length == movements.length);
      final byId = {for (final m in movements) m.id: m};
      final salaryMonths = <String>{};
      var activeSalaries = 0;
      for (final m in movements) {
        if (m.kind == 'baseIncome') {
          require(m.status == 'confirmed' && m.category == 'Salario');
          require(m.occurred.day == 1);
          require(m.frequency == 'none' || m.frequency == 'monthly');
          require(salaryMonths.add('${m.occurred.year}-${m.occurred.month}'));
          if (m.nextDue != null) {
            activeSalaries++;
            require(m.nextDue!.day == 1);
          }
        }
        if (m.status == 'pending') {
          require(
            m.kind == 'expense' &&
                m.source == 'notification' &&
                m.parent == null &&
                m.frequency == 'none',
          );
        }
        if (m.nextDue != null) require(m.status == 'confirmed');
        final parent = byId[m.parent];
        // An orphan is legitimate after a user deletes a template. A present
        // parent must be a root of the same kind, never a cycle or another type.
        if (parent != null) {
          require(
            parent.parent == null &&
                parent.kind == m.kind &&
                parent.status == 'confirmed',
          );
        }
      }
      require(activeSalaries <= 1);
      final schedules = movements
          .where((m) => m.parent != null && m.scheduled != null)
          .toList();
      require(
        schedules
                .map((m) => '${m.parent}/${m.scheduled!.toIso8601String()}')
                .toSet()
                .length ==
            schedules.length,
      );
      final budgets = rows('budgets', (r) {
        require(money(r['amount']));
        final b = SpendingLimit.fromJson(r);
        require(b.id.isNotEmpty && labels.contains(b.category));
        require(BudgetPeriod.values.any((v) => v.name == b.period));
        return b;
      });
      require(budgets.map((b) => b.id).toSet().length == budgets.length);
      require(
        budgets.map((b) => '${b.category}/${b.period}').toSet().length ==
            budgets.length,
      );
      final preferences = rows('preferences', (r) {
        final p = Preference.fromJson(r);
        require(p.id == 1);
        final settings = jsonDecode(p.payload) as Map<String, dynamic>;
        final salary = settings['salary'];
        require(salary is int && salary >= 0 && salary <= 9007199254740991);
        // Restoring a file never grants Android permissions or enables reminders.
        settings['daily'] = false;
        settings['budget'] = false;
        return Preference(id: 1, payload: jsonEncode(settings));
      });
      require(preferences.length <= 1);
      final detections = rows(
        'detectionReceipts',
        (r) => DetectionReceipt.fromJson(r),
      );
      require(
        detections.map((r) => r.fingerprint).toSet().length ==
            detections.length,
      );
      final alerts = rows(
        'budgetAlertReceipts',
        (r) => BudgetAlertReceipt.fromJson(r),
      );
      require(alerts.map((r) => r.key).toSet().length == alerts.length);
      final receiptIds = detections.map((r) => r.fingerprint).toSet();
      require(
        movements
            .where((m) => m.status == 'pending')
            .every((m) => receiptIds.contains(m.id)),
      );
      return BackupArchive._(
        categories,
        movements,
        budgets,
        preferences,
        detections,
        alerts,
      );
    } catch (_) {
      throw const FormatException(
        'Copia inválida o incompatible. Usa un respaldo JSON completo de Mi Bolsillo (máximo 20 MB).',
      );
    }
  }

  Future<void> restore(BackupArchive archive) => db.transaction(() async {
    await db.erase();
    await db.delete(db.categories).go();
    final labels = {
      ...archive.categories.map((r) => r.label),
      ...ExpenseCategory.values.map((c) => c.label),
      ...IncomeOrigins.all,
      'Salario',
    };
    for (final label in labels) {
      await db.into(db.categories).insert(Category(label: label));
    }
    for (final row in archive.movements) {
      await db.into(db.movements).insert(row);
    }
    for (final row in archive.budgets) {
      await db.into(db.spendingLimits).insert(row);
    }
    for (final row in archive.preferences) {
      await db.into(db.preferences).insert(row);
    }
    for (final row in archive.detections) {
      await db.into(db.detectionReceipts).insert(row);
    }
    for (final row in archive.alerts) {
      await db.into(db.budgetAlertReceipts).insert(row);
    }
  });
}

class BackupArchive {
  BackupArchive._(
    this.categories,
    this.movements,
    this.budgets,
    this.preferences,
    this.detections,
    this.alerts,
  );
  final List<Category> categories;
  final List<Movement> movements;
  final List<SpendingLimit> budgets;
  final List<Preference> preferences;
  final List<DetectionReceipt> detections;
  final List<BudgetAlertReceipt> alerts;
}

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:material_ui/material_ui.dart' show ThemeMode;

import '../features/budgets/domain/budget_item.dart';
import '../features/budgets/domain/budget_repository.dart';
import '../features/income/domain/additional_income.dart';
import '../features/income/domain/income_repository.dart';
import '../features/profile/domain/user_settings.dart';
import '../features/profile/domain/settings_repository.dart';
import '../features/transactions/domain/transaction_item.dart';
import '../features/transactions/domain/transaction_repository.dart';
import '../features/transactions/domain/recurrence_repository.dart';
import 'finance_database.dart';
import 'ledger.dart';

class LocalTransactions
    implements TransactionRepository, RecurrenceRepository<TransactionItem> {
  LocalTransactions(this.ledger);
  final Ledger ledger;
  @override
  Future<List<TransactionItem>> getTransactions() async =>
      (await ledger.confirmed(incomes: false))
          .map(ledger.asTransaction)
          .toList();
  @override
  Future<TransactionItem> addTransaction(TransactionItem item) =>
      ledger.save(item);
  @override
  Future<TransactionItem> updateTransaction(TransactionItem item) =>
      ledger.editOccurrence(item);
  @override
  Future<TransactionItem> reviseFuture(TransactionItem item) =>
      ledger.reviseFuture(item);
  @override
  Future<void> stopFuture(String templateId) => ledger.stopFuture(templateId);
  @override
  Future<void> deleteTransaction(String id) async {
    final entry = await (ledger.db.select(
      ledger.db.movements,
    )..where((m) => m.id.equals(id))).getSingleOrNull();
    if (entry?.kind == 'baseIncome') {
      throw const FormatException(
        'Modifica el ingreso base desde Perfil; no se elimina del historial',
      );
    }
    await ledger.remove(id);
  }

  @override
  Future<void> clearAll() => (ledger.db.delete(
    ledger.db.movements,
  )..where((m) => m.kind.equals('additionalIncome').not())).go();
  @override
  Future<void> resetToMockDefaults() => clearAll();
}

class LocalIncomes
    implements IncomeRepository, RecurrenceRepository<AdditionalIncome> {
  LocalIncomes(this.ledger);
  final Ledger ledger;
  @override
  Future<List<AdditionalIncome>> getAdditionalIncomes() async =>
      (await ledger.confirmed(incomes: true)).map(ledger.asIncome).toList();
  Future<AdditionalIncome> _save(AdditionalIncome i, bool update) =>
      ledger.db.transaction(() async {
        final tx = update
            ? await ledger.editOccurrence(ledger.incomeEntry(i))
            : await ledger.save(ledger.incomeEntry(i));
        return ledger.asIncome(
          await (ledger.db.select(
            ledger.db.movements,
          )..where((m) => m.id.equals(tx.id))).getSingle(),
        );
      });

  @override
  Future<AdditionalIncome> reviseFuture(AdditionalIncome income) =>
      ledger.db.transaction(() async {
        final saved = await ledger.reviseFuture(ledger.incomeEntry(income));
        return ledger.asIncome(
          await (ledger.db.select(
            ledger.db.movements,
          )..where((m) => m.id.equals(saved.id))).getSingle(),
        );
      });
  @override
  Future<void> stopFuture(String templateId) => ledger.stopFuture(templateId);

  @override
  Future<AdditionalIncome> addAdditionalIncome(AdditionalIncome income) =>
      _save(income, false);
  @override
  Future<AdditionalIncome> updateAdditionalIncome(AdditionalIncome income) =>
      _save(income, true);
  @override
  Future<void> deleteAdditionalIncome(String id) => ledger.remove(id);
  @override
  Future<void> clearAll() => (ledger.db.delete(
    ledger.db.movements,
  )..where((m) => m.kind.equals('additionalIncome'))).go();
  @override
  Future<void> resetToMockDefaults() => clearAll();
}

class LocalBudgets implements BudgetRepository {
  LocalBudgets(this.ledger);
  final Ledger ledger;
  FinanceDatabase get db => ledger.db;
  @override
  Future<List<BudgetItem>> getBudgets() async =>
      (await db.select(db.spendingLimits).get())
          .map(
            (b) => BudgetItem(
              id: b.id,
              category: b.category,
              limitCop: b.amount,
              period: BudgetPeriod.values.byName(b.period),
              alertAt80: b.warn,
              alertAt100: b.exhausted,
            ),
          )
          .toList();
  Future<BudgetItem> _save(BudgetItem b, bool update) =>
      db.transaction(() async {
        final sameCategoryAndPeriod =
            await (db.select(db.spendingLimits)..where(
                  (row) =>
                      row.category.equals(b.category) &
                      row.period.equals(b.period.name),
                ))
                .get();
        final conflicting = sameCategoryAndPeriod
            .where((row) => row.id != b.id)
            .firstOrNull;
        if (update && conflicting != null) {
          throw const FormatException(
            'Ya existe un presupuesto para esa categoría y periodo',
          );
        }

        final existing = update ? null : sameCategoryAndPeriod.firstOrNull;
        final id = existing?.id ?? (b.id.isEmpty ? await ledger.newId() : b.id);
        final row = SpendingLimit(
          id: id,
          category: b.category,
          amount: b.limitCop,
          period: b.period.name,
          warn: b.alertAt80,
          exhausted: b.alertAt100,
        );
        if (update || existing != null) {
          if (!await db.update(db.spendingLimits).replace(row)) {
            throw StateError('Presupuesto inexistente');
          }
        } else {
          await db.into(db.spendingLimits).insert(row);
        }
        if (existing != null && sameCategoryAndPeriod.length > 1) {
          final duplicateIds = sameCategoryAndPeriod
              .skip(1)
              .map((duplicate) => duplicate.id)
              .toList();
          await (db.delete(
            db.spendingLimits,
          )..where((entry) => entry.id.isIn(duplicateIds))).go();
        }
        return b.copyWith(id: id);
      });

  @override
  Future<BudgetItem> addBudget(BudgetItem b) => _save(b, false);
  @override
  Future<BudgetItem> updateBudget(BudgetItem b) => _save(b, true);
  @override
  Future<void> deleteBudget(String id) =>
      (db.delete(db.spendingLimits)..where((b) => b.id.equals(id))).go();
  @override
  Future<void> clearAll() => db.delete(db.spendingLimits).go();
  @override
  Future<void> resetToMockDefaults() => clearAll();
}

class LocalSettings implements SettingsRepository {
  LocalSettings(this.ledger);
  final Ledger ledger;
  FinanceDatabase get db => ledger.db;
  @override
  Future<UserSettings> getSettings() async {
    final row = await db.select(db.preferences).getSingleOrNull();
    if (row == null) return UserSettings.defaults();
    final defaults = UserSettings.defaults();
    late final Map<String, dynamic> map;
    try {
      final decoded = jsonDecode(row.payload);
      if (decoded is! Map<String, dynamic>) return defaults;
      map = decoded;
    } catch (_) {
      return defaults;
    }

    T enumValue<T extends Enum>(Iterable<T> values, Object? name, T fallback) =>
        values.where((value) => value.name == name).firstOrNull ?? fallback;
    final storedSalary = map['salary'];
    final salary = storedSalary is int && storedSalary >= 0
        ? storedSalary
        : defaults.monthlyIncomeCop;
    final storedName = map['name'];
    final name = storedName is String && storedName.trim().isNotEmpty
        ? storedName.trim()
        : defaults.userName;

    return UserSettings(
      userName: name,
      monthlyIncomeCop: salary,
      payFrequency: enumValue(
        PayFrequency.values,
        map['frequency'],
        defaults.payFrequency,
      ),
      autoRepeatBaseIncome: map['repeat'] is bool
          ? map['repeat'] as bool
          : defaults.autoRepeatBaseIncome,
      autoDetectionBannerVisible: map['banner'] is bool
          ? map['banner'] as bool
          : defaults.autoDetectionBannerVisible,
      dailyReminderEnabled: map['daily'] is bool
          ? map['daily'] as bool
          : defaults.dailyReminderEnabled,
      budget80AlertEnabled: map['budget'] is bool
          ? map['budget'] as bool
          : defaults.budget80AlertEnabled,
      themeMode: enumValue(ThemeMode.values, map['theme'], defaults.themeMode),
      hideBalances: map['hide'] is bool
          ? map['hide'] as bool
          : defaults.hideBalances,
      onboardingCompleted: map['onboarded'] is bool
          ? map['onboarded'] as bool
          : defaults.onboardingCompleted,
    );
  }

  @override
  Future<UserSettings> updateSettings(UserSettings s) => _persist(s, false);
  Future<UserSettings> configureIncome(UserSettings s) => _persist(s, true);
  Future<UserSettings> _persist(UserSettings s, bool configure) =>
      db.transaction(() async {
        final old = await getSettings();
        if (configure ||
            s.monthlyIncomeCop != old.monthlyIncomeCop ||
            s.autoRepeatBaseIncome != old.autoRepeatBaseIncome ||
            s.onboardingCompleted != old.onboardingCompleted) {
          await ledger.configureSalary(
            s.monthlyIncomeCop,
            s.autoRepeatBaseIncome,
          );
        }
        await db
            .into(db.preferences)
            .insertOnConflictUpdate(
              Preference(
                id: 1,
                payload: jsonEncode({
                  'name': s.userName,
                  'salary': s.monthlyIncomeCop,
                  'frequency': s.payFrequency.name,
                  'repeat': s.autoRepeatBaseIncome,
                  'banner': s.autoDetectionBannerVisible,
                  'daily': s.dailyReminderEnabled,
                  'budget': s.budget80AlertEnabled,
                  'theme': s.themeMode.name,
                  'hide': s.hideBalances,
                  'onboarded': s.onboardingCompleted,
                }),
              ),
            );
        return s;
      });
  @override
  Future<UserSettings> resetSettings() =>
      updateSettings(UserSettings.defaults());
}

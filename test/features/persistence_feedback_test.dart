import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mi_bolsillo/app/providers.dart';
import 'package:mi_bolsillo/features/profile/application/settings_controller.dart';
import 'package:mi_bolsillo/features/profile/data/mock_settings_repository.dart';
import 'package:mi_bolsillo/features/profile/domain/user_settings.dart';
import 'package:mi_bolsillo/features/income/application/income_controller.dart';
import 'package:mi_bolsillo/features/income/data/mock_income_repository.dart';
import 'package:mi_bolsillo/features/income/domain/additional_income.dart';
import 'package:mi_bolsillo/features/transactions/domain/transaction_item.dart';

class _SlowSettings extends MockSettingsRepository {
  final started = Completer<void>();
  final finish = Completer<void>();
  int calls = 0;
  @override
  Future<UserSettings> updateSettings(UserSettings settings) async {
    if (++calls == 1) {
      started.complete();
      await finish.future;
    }
    return super.updateSettings(settings);
  }
}

class _FailingReadIncome extends MockIncomeRepository {
  bool fail = false;
  int saves = 0;
  @override
  Future<AdditionalIncome> addAdditionalIncome(AdditionalIncome income) async {
    final saved = await super.addAdditionalIncome(income);
    saves++;
    fail = true;
    return saved;
  }

  @override
  Future<List<AdditionalIncome>> getAdditionalIncomes() async {
    if (fail) throw StateError('Synthetic read failure');
    return super.getAdditionalIncomes();
  }
}

void main() {
  test('Cambios simultáneos de ajustes conservan ambos valores', () async {
    final repo = _SlowSettings();
    final container = ProviderContainer(
      overrides: [settingsRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    final controller = container.read(settingsControllerProvider.notifier);
    final first = controller.toggleThemeMode(true);
    await repo.started.future;
    final second = controller.toggleHideBalances();
    repo.finish.complete();
    await Future.wait([first, second]);
    final saved = await repo.getSettings();
    expect(saved.themeMode, ThemeMode.dark);
    expect(saved.hideBalances, isTrue);
  });

  test(
    'Error al recargar no convierte un ingreso guardado en guardado fallido',
    () async {
      final repo = _FailingReadIncome();
      await repo.clearAll();
      final container = ProviderContainer(
        overrides: [incomeRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);
      final controller = container.read(incomeControllerProvider.notifier);
      await Future<void>.delayed(Duration.zero);
      await controller.addIncome(
        amountCop: 15000,
        reason: 'Horas extras',
        origin: 'Otros',
        date: DateTime.now(),
        receptionMethod: 'Efectivo',
        note: '',
        recurrence: RecurrenceFrequency.none,
      );
      expect(repo.saves, 1);
      expect(container.read(incomeControllerProvider).errorMessage, isNotNull);
      expect(container.read(incomeControllerProvider).isSaving, isFalse);
      repo.fail = false;
      await controller.loadIncomes();
      expect(
        container
            .read(incomeControllerProvider)
            .items
            .where((i) => i.reason == 'Horas extras')
            .length,
        1,
      );
    },
  );
}

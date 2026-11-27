import '../../../data/local_repositories.dart';
import '../../transactions/application/transactions_controller.dart';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_bolsillo/app/providers.dart';
import 'package:mi_bolsillo/features/profile/domain/user_settings.dart';

class SettingsController extends Notifier<UserSettings> {
  Future<void> _pending = Future.value();

  Future<void> whenIdle() => _pending;

  @override
  UserSettings build() {
    _pending = _hydrate().catchError((Object _) {});
    return UserSettings.defaults();
  }

  // Apply each change to the latest persisted settings, including when several
  // switches are tapped before an earlier write or initial hydration completes.
  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final next = _pending.then((_) async {
      state = await ref.read(settingsRepositoryProvider).getSettings();
      return operation();
    });
    _pending = next.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return next;
  }

  Future<void> _hydrate() async {
    final loaded = await ref.read(settingsRepositoryProvider).getSettings();
    state = loaded;
  }

  Future<void> completeOnboarding({
    required int monthlyIncomeCop,
    required PayFrequency payFrequency,
    required bool autoRepeatBaseIncome,
  }) => _enqueue(() async {
    final updated = state.copyWith(
      monthlyIncomeCop: monthlyIncomeCop,
      payFrequency: payFrequency,
      autoRepeatBaseIncome: autoRepeatBaseIncome,
      onboardingCompleted: true,
    );
    final repo = ref.read(settingsRepositoryProvider);
    state = repo is LocalSettings
        ? await repo.configureIncome(updated)
        : await repo.updateSettings(updated);
    await ref.read(transactionsControllerProvider.notifier).loadTransactions();
  });

  Future<void> updateMonthlyIncome(int monthlyIncomeCop) => _enqueue(() async {
    final updated = state.copyWith(monthlyIncomeCop: monthlyIncomeCop);
    state = await ref.read(settingsRepositoryProvider).updateSettings(updated);
    await ref.read(transactionsControllerProvider.notifier).loadTransactions();
  });

  Future<void> toggleThemeMode(bool isDark) => _enqueue(() async {
    final updated = state.copyWith(
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
    );
    state = await ref.read(settingsRepositoryProvider).updateSettings(updated);
  });

  Future<void> toggleHideBalances() => _enqueue(() async {
    final updated = state.copyWith(hideBalances: !state.hideBalances);
    state = await ref.read(settingsRepositoryProvider).updateSettings(updated);
  });

  Future<void> dismissAutoDetectionBanner() => _enqueue(() async {
    final updated = state.copyWith(autoDetectionBannerVisible: false);
    state = await ref.read(settingsRepositoryProvider).updateSettings(updated);
  });

  Future<bool> toggleDailyReminder(bool enabled) => _enqueue(() async {
    final notifications = ref.read(appNotificationsProvider);
    try {
      if (enabled && !await notifications.requestPermission()) return false;
      if (!await notifications.syncDailyReminder(enabled)) return false;
    } catch (_) {
      return false;
    }
    final updated = state.copyWith(dailyReminderEnabled: enabled);
    state = await ref.read(settingsRepositoryProvider).updateSettings(updated);
    return true;
  });

  Future<bool> toggleBudget80Alert(bool enabled) => _enqueue(() async {
    final notifications = ref.read(appNotificationsProvider);
    try {
      if (enabled && !await notifications.requestPermission()) return false;
    } catch (_) {
      return false;
    }
    final updated = state.copyWith(budget80AlertEnabled: enabled);
    state = await ref.read(settingsRepositoryProvider).updateSettings(updated);
    if (enabled) {
      await ref
          .read(transactionsControllerProvider.notifier)
          .evaluateBudgetAlerts();
    }
    return true;
  });

  Future<void> resetDefaults() => _enqueue(() async {
    try {
      await ref.read(appNotificationsProvider).syncDailyReminder(false);
    } catch (_) {
      // Resetting local settings remains possible if Android is unavailable.
    }
    state = await ref.read(settingsRepositoryProvider).resetSettings();
  });
}

final settingsControllerProvider =
    NotifierProvider<SettingsController, UserSettings>(SettingsController.new);

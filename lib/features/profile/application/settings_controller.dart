import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_bolsillo/app/providers.dart';
import 'package:mi_bolsillo/features/profile/domain/user_settings.dart';

class SettingsController extends Notifier<UserSettings> {
  @override
  UserSettings build() {
    _hydrate();
    return UserSettings.defaults();
  }

  Future<void> _hydrate() async {
    final loaded = await ref.read(settingsRepositoryProvider).getSettings();
    state = loaded;
  }

  Future<void> completeOnboarding({
    required int monthlyIncomeCop,
    required PayFrequency payFrequency,
    required bool autoRepeatBaseIncome,
  }) async {
    final updated = state.copyWith(
      monthlyIncomeCop: monthlyIncomeCop,
      payFrequency: payFrequency,
      autoRepeatBaseIncome: autoRepeatBaseIncome,
      onboardingCompleted: true,
    );
    state = await ref.read(settingsRepositoryProvider).updateSettings(updated);
  }

  Future<void> updateMonthlyIncome(int monthlyIncomeCop) async {
    final updated = state.copyWith(monthlyIncomeCop: monthlyIncomeCop);
    state = await ref.read(settingsRepositoryProvider).updateSettings(updated);
  }

  Future<void> toggleThemeMode(bool isDark) async {
    final updated = state.copyWith(
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
    );
    state = await ref.read(settingsRepositoryProvider).updateSettings(updated);
  }

  Future<void> toggleHideBalances() async {
    final updated = state.copyWith(hideBalances: !state.hideBalances);
    state = await ref.read(settingsRepositoryProvider).updateSettings(updated);
  }

  Future<void> dismissAutoDetectionBanner() async {
    final updated = state.copyWith(autoDetectionBannerVisible: false);
    state = await ref.read(settingsRepositoryProvider).updateSettings(updated);
  }

  Future<void> toggleDailyReminder(bool enabled) async {
    final updated = state.copyWith(dailyReminderEnabled: enabled);
    state = await ref.read(settingsRepositoryProvider).updateSettings(updated);
  }

  Future<void> toggleBudget80Alert(bool enabled) async {
    final updated = state.copyWith(budget80AlertEnabled: enabled);
    state = await ref.read(settingsRepositoryProvider).updateSettings(updated);
  }

  Future<void> resetDefaults() async {
    state = await ref.read(settingsRepositoryProvider).resetSettings();
  }
}

final settingsControllerProvider =
    NotifierProvider<SettingsController, UserSettings>(SettingsController.new);

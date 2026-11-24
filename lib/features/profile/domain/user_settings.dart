import 'package:material_ui/material_ui.dart';

enum PayFrequency {
  biweekly('Cada 15 y 30 · Quincenal'),
  monthly('Fin de mes · Mensual'),
  weekly('Cada semana'),
  other('Otro día');

  const PayFrequency(this.label);
  final String label;
}

/// Visual/domain model for user financial profile and app preferences.
@immutable
class UserSettings {
  const UserSettings({
    required this.userName,
    required this.monthlyIncomeCop,
    required this.payFrequency,
    required this.autoRepeatBaseIncome,
    required this.autoDetectionBannerVisible,
    required this.dailyReminderEnabled,
    required this.budget80AlertEnabled,
    required this.themeMode,
    required this.hideBalances,
    required this.onboardingCompleted,
  });

  factory UserSettings.defaults() => const UserSettings(
    userName: 'Mi perfil',
    monthlyIncomeCop: 0,
    payFrequency: PayFrequency.biweekly,
    autoRepeatBaseIncome: true,
    autoDetectionBannerVisible: true,
    dailyReminderEnabled: false,
    budget80AlertEnabled: false,
    themeMode: ThemeMode.light,
    hideBalances: false,
    onboardingCompleted: false,
  );

  final String userName;
  final int monthlyIncomeCop;
  final PayFrequency payFrequency;
  final bool autoRepeatBaseIncome;
  final bool autoDetectionBannerVisible;
  final bool dailyReminderEnabled;
  final bool budget80AlertEnabled;
  final ThemeMode themeMode;
  final bool hideBalances;
  final bool onboardingCompleted;

  String get firstName => userName.split(' ').first;

  UserSettings copyWith({
    String? userName,
    int? monthlyIncomeCop,
    PayFrequency? payFrequency,
    bool? autoRepeatBaseIncome,
    bool? autoDetectionBannerVisible,
    bool? dailyReminderEnabled,
    bool? budget80AlertEnabled,
    ThemeMode? themeMode,
    bool? hideBalances,
    bool? onboardingCompleted,
  }) {
    return UserSettings(
      userName: userName ?? this.userName,
      monthlyIncomeCop: monthlyIncomeCop ?? this.monthlyIncomeCop,
      payFrequency: payFrequency ?? this.payFrequency,
      autoRepeatBaseIncome: autoRepeatBaseIncome ?? this.autoRepeatBaseIncome,
      autoDetectionBannerVisible:
          autoDetectionBannerVisible ?? this.autoDetectionBannerVisible,
      dailyReminderEnabled: dailyReminderEnabled ?? this.dailyReminderEnabled,
      budget80AlertEnabled: budget80AlertEnabled ?? this.budget80AlertEnabled,
      themeMode: themeMode ?? this.themeMode,
      hideBalances: hideBalances ?? this.hideBalances,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }
}

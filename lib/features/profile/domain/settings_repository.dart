import 'package:mi_bolsillo/features/profile/domain/user_settings.dart';

/// Abstract repository contract for local user settings and preferences.
abstract class SettingsRepository {
  Future<UserSettings> getSettings();
  Future<UserSettings> updateSettings(UserSettings settings);
  Future<UserSettings> resetSettings();
}

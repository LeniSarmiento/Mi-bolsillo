import 'package:mi_bolsillo/features/profile/domain/settings_repository.dart';
import 'package:mi_bolsillo/features/profile/domain/user_settings.dart';

/// In-memory mock repository for user settings (no definitive persistence).
class MockSettingsRepository implements SettingsRepository {
  UserSettings _settings = UserSettings.defaults();

  @override
  Future<UserSettings> getSettings() async => _settings;

  @override
  Future<UserSettings> updateSettings(UserSettings settings) async {
    _settings = settings;
    return _settings;
  }

  @override
  Future<UserSettings> resetSettings() async {
    _settings = UserSettings.defaults();
    return _settings;
  }
}

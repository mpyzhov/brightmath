import 'package:shared_preferences/shared_preferences.dart';

import '../domain/user_settings.dart';

class SettingsRepository {
  static const _languageKey = 'settings.languageCode';
  static const _soundKey = 'settings.soundEnabled';
  static const _hapticsKey = 'settings.hapticsEnabled';

  Future<UserSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return UserSettings(
      languageCode: prefs.getString(_languageKey) ?? 'en',
      soundEnabled: prefs.getBool(_soundKey) ?? true,
      hapticsEnabled: prefs.getBool(_hapticsKey) ?? true,
    );
  }

  Future<void> save(UserSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, settings.languageCode);
    await prefs.setBool(_soundKey, settings.soundEnabled);
    await prefs.setBool(_hapticsKey, settings.hapticsEnabled);
  }
}

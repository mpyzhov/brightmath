import 'package:brightmath/features/settings/data/settings_repository.dart';
import 'package:brightmath/features/settings/domain/user_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SettingsRepository repository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repository = SettingsRepository();
  });

  test('load returns default settings when preferences are empty', () async {
    final settings = await repository.load();

    expect(settings.languageCode, 'en');
    expect(settings.soundEnabled, isTrue);
    expect(settings.hapticsEnabled, isTrue);
  });

  test('save persists settings and load returns saved values', () async {
    const updated = UserSettings(
      languageCode: 'uk',
      soundEnabled: false,
      hapticsEnabled: false,
    );

    await repository.save(updated);

    final loaded = await repository.load();

    expect(loaded.languageCode, updated.languageCode);
    expect(loaded.soundEnabled, updated.soundEnabled);
    expect(loaded.hapticsEnabled, updated.hapticsEnabled);
  });
}

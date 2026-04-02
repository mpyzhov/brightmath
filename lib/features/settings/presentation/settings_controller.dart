import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/settings_repository.dart';
import '../domain/user_settings.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository();
});

class SettingsController extends AsyncNotifier<UserSettings> {
  @override
  Future<UserSettings> build() async {
    return ref.read(settingsRepositoryProvider).load();
  }

  Future<void> updateLanguage(String languageCode) async {
    final current = state.asData?.value ?? UserSettings.defaults();
    final updated = current.copyWith(languageCode: languageCode);
    state = AsyncData(updated);
    await ref.read(settingsRepositoryProvider).save(updated);
  }

  Future<void> toggleSound(bool enabled) async {
    final current = state.asData?.value ?? UserSettings.defaults();
    final updated = current.copyWith(soundEnabled: enabled);
    state = AsyncData(updated);
    await ref.read(settingsRepositoryProvider).save(updated);
  }

  Future<void> toggleHaptics(bool enabled) async {
    final current = state.asData?.value ?? UserSettings.defaults();
    final updated = current.copyWith(hapticsEnabled: enabled);
    state = AsyncData(updated);
    await ref.read(settingsRepositoryProvider).save(updated);
  }
}

final settingsControllerProvider =
    AsyncNotifierProvider<SettingsController, UserSettings>(
      SettingsController.new,
    );

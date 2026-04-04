import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_providers.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/localization/language_native_names.dart';
import '../../chapters/presentation/chapters_controller.dart';
import 'settings_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final settings = ref.watch(settingsControllerProvider);
    final loaded = settings.asData?.value;

    return loaded == null
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text(strings.t('language')),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Align(
                                alignment: AlignmentDirectional.centerEnd,
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  value: loaded.languageCode,
                                  alignment: AlignmentDirectional.centerEnd,
                                  onChanged: (value) {
                                    if (value != null) {
                                      ref
                                          .read(
                                            settingsControllerProvider.notifier,
                                          )
                                          .updateLanguage(value);
                                    }
                                  },
                                  items: AppStrings.supportedLocales
                                      .map(
                                        (locale) => DropdownMenuItem(
                                          value: locale.languageCode,
                                          child: Text(
                                            LanguageNativeNames.labelFor(
                                              locale.languageCode,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(growable: false),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(strings.t('sound')),
                          value: loaded.soundEnabled,
                          onChanged: (v) => ref
                              .read(settingsControllerProvider.notifier)
                              .toggleSound(v),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(strings.t('haptics')),
                          value: loaded.hapticsEnabled,
                          onChanged: (v) => ref
                              .read(settingsControllerProvider.notifier)
                              .toggleHaptics(v),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red.shade100,
                    foregroundColor: Colors.red.shade900,
                  ),
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: Text(strings.t('confirmResetTitle')),
                        content: Text(strings.t('confirmResetMessage')),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(strings.t('cancel')),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text(strings.t('confirm')),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      await ref
                          .read(chaptersRepositoryProvider)
                          .resetProgress();
                      ref.invalidate(chaptersListProvider);
                      ref.invalidate(startStatsProvider);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(strings.t('progressReset'))),
                        );
                      }
                    }
                  },
                  child: Text(strings.t('resetProgress')),
                ),
              ],
            ),
          );
  }
}

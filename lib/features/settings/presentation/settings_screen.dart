import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_providers.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/localization/language_native_names.dart';
import '../../../core/theme/app_theme.dart';
import '../../chapters/presentation/chapters_controller.dart';
import 'settings_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static TextStyle _rowLabelStyle(BuildContext context) {
    final theme = Theme.of(context);
    return theme.textTheme.titleMedium!.copyWith(
      color: AppTheme.navyDark,
      fontWeight: FontWeight.w600,
      fontSize: 16,
      height: 1.25,
    );
  }

  static TextStyle _sheetTitleStyle(BuildContext context) {
    final theme = Theme.of(context);
    return theme.textTheme.titleLarge!.copyWith(
      color: AppTheme.navyDark,
      fontWeight: FontWeight.w800,
      fontSize: 20,
      letterSpacing: -0.2,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final settings = ref.watch(settingsControllerProvider);
    final loaded = settings.asData?.value;

    if (loaded == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final labelStyle = _rowLabelStyle(context);

    return Theme(
      data: Theme.of(context).copyWith(
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.white;
            }
            return Colors.grey.shade400;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppTheme.teal;
            }
            return Colors.grey.shade300;
          }),
          trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 2,
                shadowColor: Colors.black26,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SettingsTile(
                      icon: Icons.translate_rounded,
                      label: strings.t('language'),
                      labelStyle: labelStyle,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            LanguageNativeNames.labelFor(loaded.languageCode),
                            style: labelStyle.copyWith(
                              color: AppTheme.teal,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: AppTheme.navy.withValues(alpha: 0.65),
                            size: 22,
                          ),
                        ],
                      ),
                      onTap: () => _openLanguagePicker(
                        context,
                        ref,
                        loaded.languageCode,
                        labelStyle,
                      ),
                    ),
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: Colors.grey.shade200,
                    ),
                    _SettingsSwitchTile(
                      icon: Icons.volume_up_rounded,
                      label: strings.t('sound'),
                      labelStyle: labelStyle,
                      value: loaded.soundEnabled,
                      onChanged: (v) => ref
                          .read(settingsControllerProvider.notifier)
                          .toggleSound(v),
                    ),
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: Colors.grey.shade200,
                    ),
                    _SettingsSwitchTile(
                      icon: Icons.vibration_rounded,
                      label: strings.t('haptics'),
                      labelStyle: labelStyle,
                      value: loaded.hapticsEnabled,
                      onChanged: (v) => ref
                          .read(settingsControllerProvider.notifier)
                          .toggleHaptics(v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _confirmReset(context, ref, strings),
                  icon: Icon(
                    Icons.delete_forever_rounded,
                    color: Colors.red.shade800,
                    size: 22,
                  ),
                  label: Text(
                    strings.t('resetProgress'),
                    style: labelStyle.copyWith(
                      color: Colors.red.shade900,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: Colors.red.shade300, width: 1.5),
                    backgroundColor: Colors.red.shade50,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openLanguagePicker(
    BuildContext context,
    WidgetRef ref,
    String currentCode,
    TextStyle labelStyle,
  ) async {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final locales = AppStrings.supportedLocales;
        return SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.max,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
                child: Text(
                  strings.t('language'),
                  style: _sheetTitleStyle(ctx),
                  textAlign: TextAlign.center,
                ),
              ),
              Divider(height: 1, color: Colors.grey.shade200),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.only(bottom: 8),
                  itemCount: locales.length,
                  separatorBuilder: (_, _) =>
                      Divider(height: 1, color: Colors.grey.shade200),
                  itemBuilder: (context, index) {
                    final locale = locales[index];
                    final code = locale.languageCode;
                    final name = LanguageNativeNames.labelFor(code);
                    final selected = code == currentCode;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 4,
                      ),
                      leading: Icon(
                        selected
                            ? Icons.check_circle_rounded
                            : Icons.circle_outlined,
                        color: selected ? AppTheme.teal : Colors.grey.shade400,
                        size: 24,
                      ),
                      title: Text(
                        name,
                        style: labelStyle.copyWith(
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: selected ? AppTheme.navyDark : AppTheme.navy,
                        ),
                      ),
                      onTap: () {
                        ref
                            .read(settingsControllerProvider.notifier)
                            .updateLanguage(code);
                        Navigator.of(ctx).pop();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmReset(
    BuildContext context,
    WidgetRef ref,
    AppStrings strings,
  ) async {
    final labelStyle = _rowLabelStyle(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          strings.t('confirmResetTitle'),
          style: labelStyle.copyWith(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        content: Text(
          strings.t('confirmResetMessage'),
          style: labelStyle.copyWith(
            fontWeight: FontWeight.w500,
            color: const Color(0xFF4D5F73),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              strings.t('cancel'),
              style: labelStyle.copyWith(
                color: AppTheme.navy,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: Text(
              strings.t('confirm'),
              style: labelStyle.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(chaptersRepositoryProvider).resetProgress();
      ref.invalidate(chaptersListProvider);
      ref.invalidate(startStatsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              strings.t('progressReset'),
              style: labelStyle.copyWith(color: Colors.white),
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.labelStyle,
    required this.trailing,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final TextStyle labelStyle;
  final Widget trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: AppTheme.navy, size: 24),
              const SizedBox(width: 14),
              Expanded(child: Text(label, style: labelStyle)),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  const _SettingsSwitchTile({
    required this.icon,
    required this.label,
    required this.labelStyle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final TextStyle labelStyle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(icon, color: AppTheme.navy, size: 24),
              const SizedBox(width: 14),
              Expanded(child: Text(label, style: labelStyle)),
              Switch(
                value: value,
                onChanged: onChanged,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

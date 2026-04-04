import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import 'chapters_controller.dart';

class StartScreen extends ConsumerWidget {
  const StartScreen({
    super.key,
    required this.onStart,
    required this.onSettings,
  });

  final VoidCallback onStart;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final stats = ref.watch(startStatsProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  onPressed: onSettings,
                  icon: const Icon(
                    Icons.settings_rounded,
                    color: AppTheme.navy,
                    size: 28,
                  ),
                ),
              ),
              const Spacer(flex: 2),
              Text(
                strings.t('appTitle'),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 48,
                  color: AppTheme.navyDark,
                ),
              ),
              const SizedBox(height: 32),
              stats.when(
                data: (value) => Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 16,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _StatItem(
                          icon: Icons.check_circle_rounded,
                          label: strings.t('completedChapters'),
                          value: '${value.completedChapters}',
                        ),
                        const SizedBox(width: 24),
                        Container(
                          width: 1,
                          height: 44,
                          color: const Color(0xFFE8EDF3),
                        ),
                        const SizedBox(width: 24),
                        _StatItem(
                          icon: Icons.star_rounded,
                          label: strings.t('totalStars'),
                          value: '${value.totalStars}',
                          iconColor: AppTheme.gold,
                        ),
                      ],
                    ),
                  ),
                ),
                loading: () => const CircularProgressIndicator(),
                error: (e, _) => Text('$e'),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.teal,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                  ),
                  onPressed: onStart,
                  child: Text(
                    strings.t('startGame'),
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor = AppTheme.teal,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 24,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, textAlign: TextAlign.center),
      ],
    );
  }
}

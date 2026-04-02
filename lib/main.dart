import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/root_flow.dart';
import 'core/localization/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/presentation/settings_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const ProviderScope(child: BrightMathApp()));
}

class BrightMathApp extends ConsumerWidget {
  const BrightMathApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final localeCode = settings.asData?.value.languageCode ?? 'en';

    return MaterialApp(
      title: 'BrightMath',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(),
      locale: Locale(localeCode),
      localizationsDelegates: const [
        AppStringsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppStrings.supportedLocales,
      home: const RootFlow(),
    );
  }
}

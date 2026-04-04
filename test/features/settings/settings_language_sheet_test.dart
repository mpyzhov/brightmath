import 'package:brightmath/core/localization/app_strings.dart';
import 'package:brightmath/features/settings/domain/user_settings.dart';
import 'package:brightmath/features/settings/presentation/settings_controller.dart';
import 'package:brightmath/features/settings/presentation/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSettingsController extends SettingsController {
  @override
  Future<UserSettings> build() async => UserSettings.defaults();
}

void main() {
  testWidgets('language picker bottom sheet scrolls without overflow', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsControllerProvider.overrideWith(_FakeSettingsController.new),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: const [
            AppStringsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppStrings.supportedLocales,
          home: const SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Language'));
    await tester.pumpAndSettle();

    expect(find.byType(ListTile), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}

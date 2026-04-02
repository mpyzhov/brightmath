import 'package:brightmath/app/root_flow.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:brightmath/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('start to chapter trail flow', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: BrightMathApp()));
    await tester.pumpAndSettle();

    expect(find.text('Start Game'), findsOneWidget);

    await tester.tap(find.text('Start Game'));
    await tester.pumpAndSettle();

    expect(find.text('Chapter Trail'), findsOneWidget);
  });

  testWidgets('restores chapter trail from saved session', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'root_flow_page': RootPage.trail.index,
    });

    await tester.pumpWidget(const ProviderScope(child: BrightMathApp()));
    await tester.pumpAndSettle();

    expect(find.text('Chapter Trail'), findsOneWidget);
  });

  testWidgets('saved results session falls back to chapter trail', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'root_flow_page': RootPage.results.index,
    });

    await tester.pumpWidget(const ProviderScope(child: BrightMathApp()));
    await tester.pumpAndSettle();

    expect(find.text('Chapter Trail'), findsOneWidget);
  });
}

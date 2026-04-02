import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brightmath/main.dart';

void main() {
  testWidgets('start to chapter trail flow', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: BrightMathApp()));
    await tester.pumpAndSettle();

    expect(find.text('Start Game'), findsOneWidget);

    await tester.tap(find.text('Start Game'));
    await tester.pumpAndSettle();

    expect(find.text('Chapter Trail'), findsOneWidget);
  });
}

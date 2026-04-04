import 'package:brightmath/core/localization/app_strings.dart';
import 'package:brightmath/features/quiz/domain/question_models.dart';
import 'package:brightmath/features/results/presentation/results_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildTestApp({
    required QuizRunResult result,
    required bool showSkipHard,
    VoidCallback? onRerun,
    VoidCallback? onTrail,
    VoidCallback? onHome,
    VoidCallback? onNextChapter,
    VoidCallback? onSkipHard,
  }) {
    return MaterialApp(
      localizationsDelegates: const [
        AppStringsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppStrings.supportedLocales,
      home: ResultsScreen(
        result: result,
        showSkipHard: showSkipHard,
        onRerun: onRerun ?? () {},
        onTrail: onTrail ?? () {},
        onHome: onHome ?? () {},
        onNextChapter: onNextChapter ?? () {},
        onSkipHard: onSkipHard ?? () {},
      ),
    );
  }

  testWidgets('shows next chapter and skip actions when eligible', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      buildTestApp(
        result: const QuizRunResult(
          chapterId: 3,
          correctCount: 18,
          totalCount: 20,
          starsEarned: 2,
          results: [
            QuestionResult(
              questionId: 1,
              prompt: '1 + 1',
              userAnswer: '3',
              correctAnswer: '2',
              isCorrect: false,
            ),
          ],
        ),
        showSkipHard: true,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Next Chapter'), findsOneWidget);
    expect(find.text('Skip Hard Chapter'), findsOneWidget);
    expect(find.text('Show Correct Results (Ad)'), findsOneWidget);
  });

  testWidgets('hides gated actions when they are not applicable', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      buildTestApp(
        result: const QuizRunResult(
          chapterId: 1,
          correctCount: 20,
          totalCount: 20,
          starsEarned: 0,
          results: [],
        ),
        showSkipHard: false,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Next Chapter'), findsNothing);
    expect(find.text('Skip Hard Chapter'), findsNothing);
    expect(find.text('Show Correct Results'), findsNothing);
  });

  testWidgets('invokes navigation callbacks from action buttons', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var rerunTapped = 0;
    var trailTapped = 0;
    var homeTapped = 0;

    await tester.pumpWidget(
      buildTestApp(
        result: const QuizRunResult(
          chapterId: 1,
          correctCount: 15,
          totalCount: 20,
          starsEarned: 1,
          results: [],
        ),
        showSkipHard: false,
        onRerun: () => rerunTapped++,
        onTrail: () => trailTapped++,
        onHome: () => homeTapped++,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Rerun Chapter'));
    await tester.pump();
    await tester.tap(find.text('Chapter Trail'));
    await tester.pump();
    await tester.tap(find.text('Home'));
    await tester.pump();

    expect(rerunTapped, 1);
    expect(trailTapped, 1);
    expect(homeTapped, 1);
  });
}

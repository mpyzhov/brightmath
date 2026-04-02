import 'package:brightmath/features/chapters/domain/progression_logic.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('best-ever policy keeps best score and stars', () {
    final merged = mergeBestProgress(
      oldBestScore: 19,
      oldBestStars: 2,
      oldCompleted: true,
      runScore: 16,
      runStars: 1,
    );

    expect(merged.bestScore, 19);
    expect(merged.bestStars, 2);
    expect(merged.completed, true);
  });

  test('run with 1+ star marks completion', () {
    final merged = mergeBestProgress(
      oldBestScore: 10,
      oldBestStars: 0,
      oldCompleted: false,
      runScore: 15,
      runStars: 1,
    );

    expect(merged.completed, true);
  });
}

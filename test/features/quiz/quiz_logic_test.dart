import 'dart:math';

import 'package:brightmath/features/quiz/domain/quiz_logic.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('starsForCorrectCount', () {
    test('returns expected stars by thresholds', () {
      expect(starsForCorrectCount(14), 0);
      expect(starsForCorrectCount(15), 1);
      expect(starsForCorrectCount(17), 1);
      expect(starsForCorrectCount(18), 2);
      expect(starsForCorrectCount(19), 2);
      expect(starsForCorrectCount(20), 3);
    });
  });

  group('pickRandomUnique', () {
    test('returns deterministic selection with same seed', () {
      final source = List.generate(100, (i) => i);
      final a = pickRandomUnique(source, 20, Random(123));
      final b = pickRandomUnique(source, 20, Random(123));
      expect(a, b);
    });

    test('never duplicates when count is within source length', () {
      final source = List.generate(100, (i) => i);
      final selected = pickRandomUnique(source, 20, Random(321));
      expect(selected.toSet().length, selected.length);
    });
  });
}

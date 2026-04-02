import 'dart:math';

int starsForCorrectCount(int correctCount) {
  if (correctCount >= 20) {
    return 3;
  }
  if (correctCount >= 18) {
    return 2;
  }
  if (correctCount >= 15) {
    return 1;
  }
  return 0;
}

List<T> pickRandomUnique<T>(List<T> source, int count, Random random) {
  final copy = List<T>.from(source);
  copy.shuffle(random);
  return copy.take(count).toList(growable: false);
}

class ProgressSnapshot {
  const ProgressSnapshot({
    required this.bestScore,
    required this.bestStars,
    required this.completed,
  });

  final int bestScore;
  final int bestStars;
  final bool completed;
}

ProgressSnapshot mergeBestProgress({
  required int oldBestScore,
  required int oldBestStars,
  required bool oldCompleted,
  required int runScore,
  required int runStars,
}) {
  return ProgressSnapshot(
    bestScore: runScore > oldBestScore ? runScore : oldBestScore,
    bestStars: runStars > oldBestStars ? runStars : oldBestStars,
    completed: oldCompleted || runStars >= 1,
  );
}

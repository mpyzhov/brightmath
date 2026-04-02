import '../../chapters/domain/chapter_models.dart';

class QuizQuestion {
  const QuizQuestion({
    required this.id,
    required this.chapterId,
    required this.prompt,
    required this.mode,
    required this.correctAnswer,
    required this.options,
    this.rightExpression,
  });

  final int id;
  final int chapterId;
  final String prompt;
  final QuizMode mode;
  final String correctAnswer;
  final List<String> options;
  final String? rightExpression;
}

class QuestionResult {
  const QuestionResult({
    required this.questionId,
    required this.prompt,
    required this.userAnswer,
    required this.correctAnswer,
    required this.isCorrect,
  });

  final int questionId;
  final String prompt;
  final String userAnswer;
  final String correctAnswer;
  final bool isCorrect;
}

class QuizRunResult {
  const QuizRunResult({
    required this.chapterId,
    required this.correctCount,
    required this.totalCount,
    required this.starsEarned,
    required this.results,
  });

  final int chapterId;
  final int correctCount;
  final int totalCount;
  final int starsEarned;
  final List<QuestionResult> results;

  bool get isCompleted => starsEarned >= 1;
}

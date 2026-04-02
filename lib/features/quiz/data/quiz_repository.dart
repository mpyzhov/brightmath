import 'dart:math';

import '../../../core/database/app_database.dart';
import '../domain/question_models.dart';

class QuizRepository {
  QuizRepository(this._database);

  final AppDatabase _database;

  Future<List<QuizQuestion>> startRun(int chapterId, {Random? random}) {
    return _database.fetchRandomQuestions(chapterId, random: random);
  }

  Future<void> saveRun(QuizRunResult result) {
    return _database.saveRunResult(result);
  }
}

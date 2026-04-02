import 'dart:math';

import 'package:sqflite/sqflite.dart';

import '../../features/chapters/domain/chapter_models.dart';
import '../../features/chapters/domain/progression_logic.dart';
import '../../features/quiz/domain/question_models.dart';
import '../../features/quiz/domain/quiz_logic.dart';

class QuizDao {
  Future<List<QuizQuestion>> fetchRandomQuestions(
    Database db,
    int chapterId, {
    int count = 20,
    Random? random,
  }) async {
    final rows = await db.query(
      'questions',
      where: 'chapter_id = ?',
      whereArgs: [chapterId],
      columns: [
        'id',
        'chapter_id',
        'prompt',
        'right_expr',
        'correct_answer',
        'options',
      ],
    );
    final rng = random ?? Random();
    final picked = pickRandomUnique(rows, count, rng);
    final chapter = chapterDefinitions.firstWhere((c) => c.id == chapterId);
    return picked
        .map((row) {
          return QuizQuestion(
            id: row['id'] as int,
            chapterId: row['chapter_id'] as int,
            prompt: row['prompt'] as String,
            rightExpression: row['right_expr'] as String?,
            mode: chapter.quizMode,
            correctAnswer: row['correct_answer'] as String,
            options: (row['options'] as String).split('|'),
          );
        })
        .toList(growable: false);
  }

  Future<void> saveRunResult(Database db, QuizRunResult result) async {
    await db.transaction((txn) async {
      final progressRows = await txn.query(
        'progress',
        where: 'chapter_id = ?',
        whereArgs: [result.chapterId],
      );
      final current = progressRows.single;
      final oldBestScore = current['best_score'] as int;
      final oldBestStars = current['best_stars'] as int;
      final oldCompleted = (current['is_completed'] as int) == 1;
      final oldSkipped = (current['is_skipped'] as int? ?? 0) == 1;

      final merged = mergeBestProgress(
        oldBestScore: oldBestScore,
        oldBestStars: oldBestStars,
        oldCompleted: oldCompleted,
        runScore: result.correctCount,
        runStars: result.starsEarned,
      );

      await txn.update(
        'progress',
        {
          'best_score': merged.bestScore,
          'best_stars': merged.bestStars,
          'is_completed': merged.completed ? 1 : 0,
          'is_skipped': (merged.completed || !oldSkipped) ? 0 : 1,
        },
        where: 'chapter_id = ?',
        whereArgs: [result.chapterId],
      );

      final attemptId = await txn.insert('attempts', {
        'chapter_id': result.chapterId,
        'correct_count': result.correctCount,
        'total_count': result.totalCount,
        'stars': result.starsEarned,
        'created_at': DateTime.now().toIso8601String(),
      });

      for (final entry in result.results) {
        await txn.insert('attempt_answers', {
          'attempt_id': attemptId,
          'question_id': entry.questionId,
          'prompt': entry.prompt,
          'user_answer': entry.userAnswer,
          'correct_answer': entry.correctAnswer,
          'is_correct': entry.isCorrect ? 1 : 0,
        });
      }

      if (result.isCompleted) {
        final nextId = await _nextChapterIdInTxn(txn, result.chapterId);
        if (nextId != null) {
          await txn.update(
            'progress',
            {'is_unlocked': 1},
            where: 'chapter_id = ?',
            whereArgs: [nextId],
          );
        }
      }
    });
  }

  Future<int?> _nextChapterIdInTxn(
    DatabaseExecutor executor,
    int chapterId,
  ) async {
    final chapterRow = await executor.query(
      'chapters',
      columns: ['order_index'],
      where: 'id = ?',
      whereArgs: [chapterId],
    );
    if (chapterRow.isEmpty) {
      return null;
    }
    final order = chapterRow.single['order_index'] as int;
    final nextRow = await executor.query(
      'chapters',
      columns: ['id'],
      where: 'order_index = ?',
      whereArgs: [order + 1],
      limit: 1,
    );
    return nextRow.isEmpty ? null : nextRow.single['id'] as int;
  }
}

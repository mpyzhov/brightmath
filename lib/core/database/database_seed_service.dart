import 'dart:math';

import 'package:sqflite/sqflite.dart';

import '../../features/chapters/domain/chapter_models.dart';
import 'question_bank_generator.dart';

class DatabaseSeedService {
  DatabaseSeedService(this._questionBankGenerator);

  final QuestionBankGenerator _questionBankGenerator;

  Future<void> seedInitialContent(Database db) async {
    await _syncChapters(db);
    await _seedQuestions(db, onlyMissing: false);
    await _seedProgress(db, onlyMissing: false);
  }

  Future<void> syncExistingContent(Database db) async {
    await _syncChapters(db);
    await _seedQuestions(db, onlyMissing: true);
    await _seedProgress(db, onlyMissing: true);
  }

  Future<void> repairQuestionBank(Database db) async {
    await _repairZeroZeroQuestions(db);
    await _repairEasySubtractionQuestions(db);
    await _repairSubtractionSecondArgument(db);
  }

  Future<void> _syncChapters(Database db) async {
    final batch = db.batch();
    for (final chapter in chapterDefinitions) {
      batch.insert(
        'chapters',
        _chapterValues(chapter),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> _seedQuestions(Database db, {required bool onlyMissing}) async {
    for (final chapter in chapterDefinitions) {
      if (onlyMissing) {
        final countRow = await db.rawQuery(
          'SELECT COUNT(*) AS c FROM questions WHERE chapter_id = ?',
          [chapter.id],
        );
        final existing = (countRow.single['c'] as int?) ?? 0;
        if (existing > 0) {
          continue;
        }
      }

      final generated = _questionBankGenerator.generateQuestions(chapter, 500);
      final batch = db.batch();
      if (!onlyMissing) {
        batch.delete(
          'questions',
          where: 'chapter_id = ?',
          whereArgs: [chapter.id],
        );
      }
      for (final question in generated) {
        batch.insert('questions', _questionValues(chapter.id, question));
      }
      await batch.commit(noResult: true);
    }
  }

  Future<void> _seedProgress(Database db, {required bool onlyMissing}) async {
    if (!onlyMissing) {
      final batch = db.batch();
      for (final chapter in chapterDefinitions) {
        batch.insert(
          'progress',
          _initialProgressValues(chapter),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
      return;
    }

    for (final chapter in chapterDefinitions) {
      final existing = await db.query(
        'progress',
        columns: ['chapter_id'],
        where: 'chapter_id = ?',
        whereArgs: [chapter.id],
        limit: 1,
      );
      if (existing.isNotEmpty) {
        continue;
      }
      await db.insert('progress', _initialProgressValues(chapter));
    }
  }

  Future<void> _repairZeroZeroQuestions(Database db) async {
    final rows = await db.query(
      'questions',
      columns: ['id', 'chapter_id', 'prompt', 'right_expr'],
    );
    if (rows.isEmpty) {
      return;
    }
    final chapterMap = {for (final c in chapterDefinitions) c.id: c};
    final batch = db.batch();
    var replaced = 0;
    for (final row in rows) {
      final prompt = row['prompt'] as String;
      final rightExpr = row['right_expr'] as String?;
      if (!_questionBankGenerator.isZeroZeroQuestion(prompt, rightExpr)) {
        continue;
      }
      final chapterId = row['chapter_id'] as int;
      final chapter = chapterMap[chapterId];
      if (chapter == null) {
        continue;
      }
      var replacement = _questionBankGenerator.generateQuestion(
        chapter,
        Random(chapterId * 9001 + replaced),
      );
      var guard = 0;
      while (_questionBankGenerator.isZeroZeroQuestion(
            replacement.prompt,
            replacement.rightExpression,
          ) &&
          guard < 10) {
        replacement = _questionBankGenerator.generateQuestion(
          chapter,
          Random(chapterId * 9001 + replaced + guard + 1),
        );
        guard++;
      }
      batch.update(
        'questions',
        _questionValues(chapterId, replacement),
        where: 'id = ?',
        whereArgs: [row['id'] as int],
      );
      replaced++;
    }
    if (replaced > 0) {
      await batch.commit(noResult: true);
    }
  }

  Future<void> _repairEasySubtractionQuestions(Database db) async {
    final rows = await db.rawQuery(
      '''
      SELECT q.id, q.chapter_id, q.correct_answer
      FROM questions q
      JOIN chapters c ON c.id = q.chapter_id
      WHERE c.kind = ? AND c.difficulty = ?
      ''',
      [ChapterKind.subtractionWhole.name, ChapterDifficulty.easy.name],
    );
    if (rows.isEmpty) {
      return;
    }

    final chapterMap = {for (final c in chapterDefinitions) c.id: c};
    final batch = db.batch();
    var replaced = 0;
    for (final row in rows) {
      final correctAnswer = row['correct_answer'] as String;
      final value = int.tryParse(correctAnswer);
      if (value != null && value > 0) {
        continue;
      }

      final chapterId = row['chapter_id'] as int;
      final chapter = chapterMap[chapterId];
      if (chapter == null) {
        continue;
      }

      var replacement = _questionBankGenerator.generateQuestion(
        chapter,
        Random(chapterId * 7001 + replaced),
      );
      var guard = 0;
      while ((int.tryParse(replacement.correctAnswer) == null ||
              int.parse(replacement.correctAnswer) <= 0) &&
          guard < 20) {
        replacement = _questionBankGenerator.generateQuestion(
          chapter,
          Random(chapterId * 7001 + replaced + guard + 1),
        );
        guard++;
      }

      batch.update(
        'questions',
        _questionValues(chapterId, replacement),
        where: 'id = ?',
        whereArgs: [row['id'] as int],
      );
      replaced++;
    }
    if (replaced > 0) {
      await batch.commit(noResult: true);
    }
  }

  Future<void> _repairSubtractionSecondArgument(Database db) async {
    final rows = await db.rawQuery(
      '''
      SELECT q.id, q.chapter_id, q.prompt
      FROM questions q
      JOIN chapters c ON c.id = q.chapter_id
      WHERE c.kind = ?
      ''',
      [ChapterKind.subtractionWhole.name],
    );
    if (rows.isEmpty) {
      return;
    }

    final chapterMap = {for (final c in chapterDefinitions) c.id: c};
    final batch = db.batch();
    var replaced = 0;
    for (final row in rows) {
      final prompt = row['prompt'] as String;
      if (!_questionBankGenerator.hasNegativeSubtractionSecondArgument(
        prompt,
      )) {
        continue;
      }

      final chapterId = row['chapter_id'] as int;
      final chapter = chapterMap[chapterId];
      if (chapter == null) {
        continue;
      }

      var replacement = _questionBankGenerator.generateQuestion(
        chapter,
        Random(chapterId * 8009 + replaced),
      );
      var guard = 0;
      while (_questionBankGenerator.hasNegativeSubtractionSecondArgument(
            replacement.prompt,
          ) &&
          guard < 20) {
        replacement = _questionBankGenerator.generateQuestion(
          chapter,
          Random(chapterId * 8009 + replaced + guard + 1),
        );
        guard++;
      }

      batch.update(
        'questions',
        _questionValues(chapterId, replacement),
        where: 'id = ?',
        whereArgs: [row['id'] as int],
      );
      replaced++;
    }
    if (replaced > 0) {
      await batch.commit(noResult: true);
    }
  }

  Map<String, Object?> _chapterValues(ChapterDefinition chapter) {
    return {
      'id': chapter.id,
      'order_index': chapter.orderIndex,
      'topic_code': chapter.topicCode,
      'difficulty': chapter.difficulty.name,
      'title': chapter.titleKey,
      'description': chapter.descriptionKey,
      'kind': chapter.kind.name,
      'quiz_mode': chapter.quizMode.name,
    };
  }

  Map<String, Object?> _questionValues(
    int chapterId,
    GeneratedQuestion question,
  ) {
    return {
      'chapter_id': chapterId,
      'prompt': question.prompt,
      'right_expr': question.rightExpression,
      'correct_answer': question.correctAnswer,
      'options': question.options.join('|'),
    };
  }

  Map<String, Object?> _initialProgressValues(ChapterDefinition chapter) {
    return {
      'chapter_id': chapter.id,
      'is_unlocked': chapter.orderIndex == 1 ? 1 : 0,
      'is_completed': 0,
      'is_skipped': 0,
      'best_score': 0,
      'best_stars': 0,
    };
  }
}

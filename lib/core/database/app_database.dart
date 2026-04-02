import 'dart:math';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../features/chapters/domain/chapter_models.dart';
import '../../features/chapters/domain/progression_logic.dart';
import '../../features/quiz/domain/question_models.dart';
import '../../features/quiz/domain/quiz_logic.dart';

class StartStats {
  const StartStats({required this.completedChapters, required this.totalStars});

  final int completedChapters;
  final int totalStars;
}

class AppDatabase {
  Database? _db;
  bool _repairedQuestionBank = false;

  Future<Database> get database async {
    if (_db != null) {
      return _db!;
    }
    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      p.join(dbPath, 'brightmath.db'),
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    if (!_repairedQuestionBank) {
      await _repairZeroZeroQuestions(_db!);
      await _repairEasySubtractionQuestions(_db!);
      await _repairSubtractionSecondArgument(_db!);
      _repairedQuestionBank = true;
    }
    return _db!;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE chapters (
        id INTEGER PRIMARY KEY,
        order_index INTEGER NOT NULL,
        topic_code TEXT NOT NULL,
        difficulty TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        kind TEXT NOT NULL,
        quiz_mode TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE questions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        chapter_id INTEGER NOT NULL,
        prompt TEXT NOT NULL,
        right_expr TEXT,
        correct_answer TEXT NOT NULL,
        options TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE progress (
        chapter_id INTEGER PRIMARY KEY,
        is_unlocked INTEGER NOT NULL,
        is_completed INTEGER NOT NULL,
        is_skipped INTEGER NOT NULL,
        best_score INTEGER NOT NULL,
        best_stars INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE attempts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        chapter_id INTEGER NOT NULL,
        correct_count INTEGER NOT NULL,
        total_count INTEGER NOT NULL,
        stars INTEGER NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE attempt_answers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        attempt_id INTEGER NOT NULL,
        question_id INTEGER NOT NULL,
        prompt TEXT NOT NULL,
        user_answer TEXT NOT NULL,
        correct_answer TEXT NOT NULL,
        is_correct INTEGER NOT NULL
      )
    ''');

    await _seedChaptersAndQuestions(db);
    await _seedProgress(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Keep user progress and attempts across upgrades.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS chapters (
        id INTEGER PRIMARY KEY,
        order_index INTEGER NOT NULL,
        topic_code TEXT NOT NULL,
        difficulty TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        kind TEXT NOT NULL,
        quiz_mode TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS questions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        chapter_id INTEGER NOT NULL,
        prompt TEXT NOT NULL,
        right_expr TEXT,
        correct_answer TEXT NOT NULL,
        options TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS progress (
        chapter_id INTEGER PRIMARY KEY,
        is_unlocked INTEGER NOT NULL,
        is_completed INTEGER NOT NULL,
        is_skipped INTEGER NOT NULL,
        best_score INTEGER NOT NULL,
        best_stars INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS attempts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        chapter_id INTEGER NOT NULL,
        correct_count INTEGER NOT NULL,
        total_count INTEGER NOT NULL,
        stars INTEGER NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS attempt_answers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        attempt_id INTEGER NOT NULL,
        question_id INTEGER NOT NULL,
        prompt TEXT NOT NULL,
        user_answer TEXT NOT NULL,
        correct_answer TEXT NOT NULL,
        is_correct INTEGER NOT NULL
      )
    ''');

    await _addColumnIfMissing(
      db,
      table: 'chapters',
      column: 'topic_code',
      declaration: "TEXT NOT NULL DEFAULT ''",
    );
    await _addColumnIfMissing(
      db,
      table: 'chapters',
      column: 'difficulty',
      declaration: "TEXT NOT NULL DEFAULT 'easy'",
    );
    await _addColumnIfMissing(
      db,
      table: 'progress',
      column: 'is_skipped',
      declaration: 'INTEGER NOT NULL DEFAULT 0',
    );

    await _syncChapters(db);
    await _seedMissingQuestions(db);
    await _seedMissingProgress(db);
  }

  Future<void> _addColumnIfMissing(
    Database db, {
    required String table,
    required String column,
    required String declaration,
  }) async {
    final info = await db.rawQuery('PRAGMA table_info($table)');
    final exists = info.any((row) => row['name'] == column);
    if (!exists) {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $declaration');
    }
  }

  Future<void> _syncChapters(Database db) async {
    final batch = db.batch();
    for (final chapter in chapterDefinitions) {
      batch.insert('chapters', {
        'id': chapter.id,
        'order_index': chapter.orderIndex,
        'topic_code': chapter.topicCode,
        'difficulty': chapter.difficulty.name,
        'title': chapter.titleKey,
        'description': chapter.descriptionKey,
        'kind': chapter.kind.name,
        'quiz_mode': chapter.quizMode.name,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> _seedMissingQuestions(Database db) async {
    for (final chapter in chapterDefinitions) {
      final countRow = await db.rawQuery(
        'SELECT COUNT(*) AS c FROM questions WHERE chapter_id = ?',
        [chapter.id],
      );
      final existing = (countRow.single['c'] as int?) ?? 0;
      if (existing > 0) {
        continue;
      }
      final generated = _generateQuestions(chapter, 500);
      final batch = db.batch();
      for (final question in generated) {
        batch.insert('questions', {
          'chapter_id': chapter.id,
          'prompt': question.prompt,
          'right_expr': question.rightExpression,
          'correct_answer': question.correctAnswer,
          'options': question.options.join('|'),
        });
      }
      await batch.commit(noResult: true);
    }
  }

  Future<void> _seedMissingProgress(Database db) async {
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
      await db.insert('progress', {
        'chapter_id': chapter.id,
        'is_unlocked': chapter.orderIndex == 1 ? 1 : 0,
        'is_completed': 0,
        'is_skipped': 0,
        'best_score': 0,
        'best_stars': 0,
      });
    }
  }

  Future<void> _seedChaptersAndQuestions(Database db) async {
    final batch = db.batch();
    for (final chapter in chapterDefinitions) {
      batch.insert('chapters', {
        'id': chapter.id,
        'order_index': chapter.orderIndex,
        'topic_code': chapter.topicCode,
        'difficulty': chapter.difficulty.name,
        'title': chapter.titleKey,
        'description': chapter.descriptionKey,
        'kind': chapter.kind.name,
        'quiz_mode': chapter.quizMode.name,
      });
      final generated = _generateQuestions(chapter, 500);
      for (final question in generated) {
        batch.insert('questions', {
          'chapter_id': chapter.id,
          'prompt': question.prompt,
          'right_expr': question.rightExpression,
          'correct_answer': question.correctAnswer,
          'options': question.options.join('|'),
        });
      }
    }
    await batch.commit(noResult: true);
  }

  Future<void> _seedProgress(Database db) async {
    final batch = db.batch();
    for (final chapter in chapterDefinitions) {
      batch.insert('progress', {
        'chapter_id': chapter.id,
        'is_unlocked': chapter.orderIndex == 1 ? 1 : 0,
        'is_completed': 0,
        'is_skipped': 0,
        'best_score': 0,
        'best_stars': 0,
      });
    }
    await batch.commit(noResult: true);
  }

  Future<List<ChapterView>> fetchChapterViews() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT c.id, c.order_index, c.title, c.description, c.kind, c.quiz_mode,
             c.topic_code, c.difficulty,
             p.is_unlocked, p.is_completed, p.is_skipped, p.best_score, p.best_stars
      FROM chapters c
      JOIN progress p ON p.chapter_id = c.id
      ORDER BY c.order_index ASC
    ''');

    return rows
        .map((row) {
          final chapter = ChapterDefinition(
            id: row['id'] as int,
            orderIndex: row['order_index'] as int,
            topicCode: row['topic_code'] as String,
            difficulty: ChapterDifficulty.values.byName(
              row['difficulty'] as String,
            ),
            titleKey: row['title'] as String,
            descriptionKey: row['description'] as String,
            kind: ChapterKind.values.byName(row['kind'] as String),
            quizMode: QuizMode.values.byName(row['quiz_mode'] as String),
          );
          final progress = ChapterProgress(
            chapterId: row['id'] as int,
            isUnlocked: (row['is_unlocked'] as int) == 1,
            isCompleted: (row['is_completed'] as int) == 1,
            isSkipped: (row['is_skipped'] as int? ?? 0) == 1,
            bestScore: row['best_score'] as int,
            bestStars: row['best_stars'] as int,
          );
          return ChapterView(definition: chapter, progress: progress);
        })
        .toList(growable: false);
  }

  Future<StartStats> fetchStartStats() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT
        SUM(CASE WHEN is_completed = 1 THEN 1 ELSE 0 END) AS completed_count,
        SUM(best_stars) AS stars_total
      FROM progress
    ''');
    final row = result.single;
    return StartStats(
      completedChapters: (row['completed_count'] as int?) ?? 0,
      totalStars: (row['stars_total'] as int?) ?? 0,
    );
  }

  Future<List<QuizQuestion>> fetchRandomQuestions(
    int chapterId, {
    int count = 20,
    Random? random,
  }) async {
    final db = await database;
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

  Future<void> saveRunResult(QuizRunResult result) async {
    final db = await database;
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
        final unlocks = await _chaptersToUnlockAfterCompletion(
          txn,
          result.chapterId,
        );
        for (final id in unlocks) {
          await txn.update(
            'progress',
            {'is_unlocked': 1},
            where: 'chapter_id = ?',
            whereArgs: [id],
          );
        }
      }
    });
  }

  Future<int?> nextChapterId(int chapterId) async {
    final db = await database;
    return _nextChapterIdInTxn(db, chapterId);
  }

  Future<void> skipHardChapter(int chapterId) async {
    final db = await database;
    await db.transaction((txn) async {
      final row = await txn.query(
        'chapters',
        columns: ['difficulty'],
        where: 'id = ?',
        whereArgs: [chapterId],
        limit: 1,
      );
      if (row.isEmpty) {
        return;
      }
      final difficulty = ChapterDifficulty.values.byName(
        row.single['difficulty'] as String,
      );
      if (difficulty != ChapterDifficulty.hard) {
        return;
      }
      final progressRows = await txn.query(
        'progress',
        columns: ['is_completed'],
        where: 'chapter_id = ?',
        whereArgs: [chapterId],
        limit: 1,
      );
      if (progressRows.isEmpty) {
        return;
      }
      final isCompleted = (progressRows.single['is_completed'] as int) == 1;
      if (isCompleted) {
        return;
      }
      await txn.update(
        'progress',
        {'is_skipped': 1},
        where: 'chapter_id = ?',
        whereArgs: [chapterId],
      );
      final next = await _nextChapterIdInTxn(txn, chapterId);
      if (next != null) {
        await txn.update(
          'progress',
          {'is_unlocked': 1},
          where: 'chapter_id = ?',
          whereArgs: [next],
        );
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

  Future<List<int>> _chaptersToUnlockAfterCompletion(
    DatabaseExecutor executor,
    int chapterId,
  ) async {
    final currentRows = await executor.query(
      'chapters',
      columns: ['order_index', 'topic_code', 'difficulty'],
      where: 'id = ?',
      whereArgs: [chapterId],
      limit: 1,
    );
    if (currentRows.isEmpty) {
      return const [];
    }
    final current = currentRows.single;
    final currentOrder = current['order_index'] as int;
    final difficulty = ChapterDifficulty.values.byName(
      current['difficulty'] as String,
    );

    final unlockIds = <int>{};
    Future<void> unlockByOrder(int orderIndex) async {
      final rows = await executor.query(
        'chapters',
        columns: ['id'],
        where: 'order_index = ?',
        whereArgs: [orderIndex],
        limit: 1,
      );
      if (rows.isNotEmpty) {
        unlockIds.add(rows.single['id'] as int);
      }
    }

    switch (difficulty) {
      case ChapterDifficulty.easy:
        await unlockByOrder(currentOrder + 1);
      case ChapterDifficulty.medium:
        await unlockByOrder(currentOrder + 1);
      case ChapterDifficulty.hard:
        await unlockByOrder(currentOrder + 1);
    }
    return unlockIds.toList(growable: false);
  }

  Future<void> resetProgress() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('attempt_answers');
      await txn.delete('attempts');
      for (final chapter in chapterDefinitions) {
        await txn.update(
          'progress',
          {
            'is_unlocked': chapter.orderIndex == 1 ? 1 : 0,
            'is_completed': 0,
            'is_skipped': 0,
            'best_score': 0,
            'best_stars': 0,
          },
          where: 'chapter_id = ?',
          whereArgs: [chapter.id],
        );
      }
    });
  }

  List<_GeneratedQuestion> _generateQuestions(
    ChapterDefinition chapter,
    int count,
  ) {
    final questions = <_GeneratedQuestion>[];
    for (var i = 0; i < count; i++) {
      final rng = Random(chapter.id * 5000 + i * 11);
      var generated = _generateForKind(
        chapter.kind,
        chapter.quizMode,
        chapter.difficulty,
        rng,
      );
      var guard = 0;
      while (_isZeroZeroQuestion(generated.prompt, generated.rightExpression) &&
          guard < 10) {
        generated = _generateForKind(
          chapter.kind,
          chapter.quizMode,
          chapter.difficulty,
          rng,
        );
        guard++;
      }
      questions.add(generated);
    }
    return questions;
  }

  _GeneratedQuestion _generateForKind(
    ChapterKind kind,
    QuizMode mode,
    ChapterDifficulty difficulty,
    Random rng,
  ) {
    switch (kind) {
      case ChapterKind.additionWhole:
        final pair = _nonZeroPair(
          rng,
          _minForDifficulty(difficulty),
          _spanForDifficulty(difficulty),
        );
        final a = pair.$1;
        final b = pair.$2;
        return _mc('$a + $b', (a + b).toString(), rng);
      case ChapterKind.subtractionWhole:
        final (a, b) = _subtractionWholePair(difficulty, rng);
        return _mc('$a - $b', (a - b).toString(), rng);
      case ChapterKind.multiplicationWhole:
        final pair = _nonZeroPair(
          rng,
          _mulMinForDifficulty(difficulty),
          _mulSpanForDifficulty(difficulty),
        );
        final a = pair.$1;
        final b = pair.$2;
        return _mc('$a × $b', (a * b).toString(), rng);
      case ChapterKind.divisionWhole:
        if (rng.nextInt(10) < 7) {
          final b = _divisorForDifficulty(difficulty, rng);
          final q = _quotientForDifficulty(difficulty, rng);
          final a = b * q;
          return _mc('$a ÷ $b', q.toString(), rng);
        }
        final b = _divisorForDifficulty(difficulty, rng);
        final a =
            rng.nextInt(_spanForDifficulty(difficulty)) +
            _minForDifficulty(difficulty);
        final value = (a / b);
        return _mc(
          '$a ÷ $b',
          value.toStringAsFixed(value.abs() >= 10 ? 1 : 2),
          rng,
        );
      case ChapterKind.compareWholeFractions:
        if (rng.nextBool()) {
          final pair = _nonZeroPair(
            rng,
            _minForDifficulty(difficulty),
            _spanForDifficulty(difficulty),
          );
          final left = pair.$1;
          final right = pair.$2;
          return _compare('$left', '$right');
        }
        final a = rng.nextInt(_fractionMaxForDifficulty(difficulty)) + 1;
        final b = rng.nextInt(_fractionMaxForDifficulty(difficulty)) + 2;
        final c = rng.nextInt(_fractionMaxForDifficulty(difficulty)) + 1;
        final d = rng.nextInt(_fractionMaxForDifficulty(difficulty)) + 2;
        return _compare('$a/$b', '$c/$d');
      case ChapterKind.additionFractions:
        return _fractionOp(rng, '+', difficulty);
      case ChapterKind.subtractionFractions:
        return _fractionOp(rng, '-', difficulty);
      case ChapterKind.multiplicationFractions:
        return _fractionMultiply(rng, difficulty);
      case ChapterKind.fractionConvertCompare:
        final maxNum = difficulty == ChapterDifficulty.easy
            ? 20
            : (difficulty == ChapterDifficulty.medium ? 71 : 500);
        final numerator = rng.nextInt(maxNum) + 5;
        final denominator =
            rng.nextInt(_fractionMaxForDifficulty(difficulty)) + 2;
        final whole = numerator ~/ denominator;
        final rem = numerator % denominator;
        final correct = rem == 0 ? '$whole' : '$whole $rem/$denominator';
        return _mc(
          'Convert $numerator/$denominator to mixed form',
          correct,
          rng,
        );
      case ChapterKind.fractionSimplify:
        final g = rng.nextInt(_fractionMaxForDifficulty(difficulty)) + 2;
        final n = (rng.nextInt(_fractionMaxForDifficulty(difficulty)) + 1) * g;
        final d = (rng.nextInt(_fractionMaxForDifficulty(difficulty)) + 1) * g;
        final reduced = _reduceFraction(n, d);
        return _mc('Simplify $n/$d', reduced, rng);
      case ChapterKind.compareOperations:
        var l1 =
            rng.nextInt(_spanForDifficulty(difficulty)) +
            _minForDifficulty(difficulty);
        var l2 =
            rng.nextInt(_spanForDifficulty(difficulty)) +
            _minForDifficulty(difficulty);
        var r1 =
            rng.nextInt(_spanForDifficulty(difficulty)) +
            _minForDifficulty(difficulty);
        var r2 =
            rng.nextInt(_spanForDifficulty(difficulty)) +
            _minForDifficulty(difficulty);
        var guard = 0;
        while ((l1 + l2 == 0 && r1 + r2 == 0) && guard < 10) {
          l1 =
              rng.nextInt(_spanForDifficulty(difficulty)) +
              _minForDifficulty(difficulty);
          l2 =
              rng.nextInt(_spanForDifficulty(difficulty)) +
              _minForDifficulty(difficulty);
          r1 =
              rng.nextInt(_spanForDifficulty(difficulty)) +
              _minForDifficulty(difficulty);
          r2 =
              rng.nextInt(_spanForDifficulty(difficulty)) +
              _minForDifficulty(difficulty);
          guard++;
        }
        return _compare('$l1 + $l2', '$r1 + $r2');
      case ChapterKind.percentage:
        final percent = (rng.nextInt(19) + 1) * 5;
        final value =
            ((rng.nextInt(
                      difficulty == ChapterDifficulty.easy
                          ? 20
                          : (difficulty == ChapterDifficulty.medium ? 71 : 500),
                    ) +
                    1) ~/
                5) *
            5;
        final answer = (percent / 100 * value);
        final display = answer == answer.roundToDouble()
            ? answer.toInt().toString()
            : answer.toStringAsFixed(1);
        return _mc('$percent% of $value', display, rng);
      case ChapterKind.power:
        final base = difficulty == ChapterDifficulty.easy
            ? rng.nextInt(7) + 2
            : (difficulty == ChapterDifficulty.medium
                  ? rng.nextInt(12) + 2
                  : rng.nextInt(22) - 10);
        final exp = difficulty == ChapterDifficulty.hard
            ? rng.nextInt(4) + 2
            : rng.nextInt(3) + 2;
        return _mc('$base^$exp', pow(base, exp).toInt().toString(), rng);
      case ChapterKind.squareRoot:
        final root = difficulty == ChapterDifficulty.easy
            ? rng.nextInt(12) + 1
            : (difficulty == ChapterDifficulty.medium
                  ? rng.nextInt(25) + 1
                  : rng.nextInt(70) + 1);
        final square = root * root;
        return _mc('√$square', root.toString(), rng);
      case ChapterKind.parenthesis:
        final a =
            rng.nextInt(_spanForDifficulty(difficulty)) +
            _minForDifficulty(difficulty);
        final b =
            rng.nextInt(_spanForDifficulty(difficulty)) +
            _minForDifficulty(difficulty);
        final c =
            rng.nextInt(difficulty == ChapterDifficulty.hard ? 80 : 20) +
            (difficulty == ChapterDifficulty.hard ? -20 : 1);
        return _mc('($a + $b) × $c', ((a + b) * c).toString(), rng);
      case ChapterKind.nestedParenthesis:
        final a =
            rng.nextInt(_spanForDifficulty(difficulty)) +
            _minForDifficulty(difficulty);
        final b =
            rng.nextInt(_spanForDifficulty(difficulty)) +
            _minForDifficulty(difficulty);
        final c =
            rng.nextInt(difficulty == ChapterDifficulty.hard ? 80 : 16) +
            (difficulty == ChapterDifficulty.hard ? -20 : 2);
        final d =
            rng.nextInt(_spanForDifficulty(difficulty)) +
            _minForDifficulty(difficulty);
        return _mc(
          '(($a + $b) × $c) - $d',
          (((a + b) * c) - d).toString(),
          rng,
        );
      case ChapterKind.compareParenthesis:
        final a =
            rng.nextInt(_spanForDifficulty(difficulty)) +
            _minForDifficulty(difficulty);
        final b =
            rng.nextInt(_spanForDifficulty(difficulty)) +
            _minForDifficulty(difficulty);
        final c =
            rng.nextInt(_spanForDifficulty(difficulty)) +
            _minForDifficulty(difficulty);
        final d =
            rng.nextInt(_spanForDifficulty(difficulty)) +
            _minForDifficulty(difficulty);
        return _compare('($a + $b) × 2', '($c + $d) × 2');
      case ChapterKind.mixedBasic:
      case ChapterKind.mixedAdvanced:
      case ChapterKind.mixedFinal:
        final pool = ChapterKind.values
            .where((k) {
              return k.index < kind.index &&
                  k != ChapterKind.compareWholeFractions &&
                  k != ChapterKind.compareOperations &&
                  k != ChapterKind.compareParenthesis;
            })
            .toList(growable: false);
        final chosen = pool[rng.nextInt(pool.length)];
        return _generateForKind(chosen, mode, difficulty, rng);
    }
  }

  _GeneratedQuestion _mc(String prompt, String correct, Random rng) {
    final options = <String>{correct};
    while (options.length < 4) {
      final delta = rng.nextInt(9) - 4;
      final value = int.tryParse(correct);
      if (value != null) {
        options.add((value + delta).toString());
      } else {
        options.add('$correct${rng.nextInt(4) + 1}');
      }
    }
    final optionList = options.toList()..shuffle(rng);
    return _GeneratedQuestion(
      prompt: prompt,
      rightExpression: null,
      correctAnswer: correct,
      options: optionList,
    );
  }

  _GeneratedQuestion _compare(String left, String right) {
    final leftValue = _eval(left);
    final rightValue = _eval(right);
    final sign = leftValue == rightValue
        ? '='
        : (leftValue > rightValue ? '>' : '<');
    return _GeneratedQuestion(
      prompt: left,
      rightExpression: right,
      correctAnswer: sign,
      options: const ['>', '<', '='],
    );
  }

  (int, int) _easyPositiveSubtractionPair(Random rng) {
    // Keep easy subtraction answers strictly positive.
    final a = rng.nextInt(20) + 1;
    final b = rng.nextInt(a);
    return (a, b);
  }

  (int, int) _subtractionWholePair(ChapterDifficulty difficulty, Random rng) {
    if (difficulty == ChapterDifficulty.easy) {
      return _easyPositiveSubtractionPair(rng);
    }
    final a =
        rng.nextInt(_spanForDifficulty(difficulty)) +
        _minForDifficulty(difficulty);
    final secondMax = difficulty == ChapterDifficulty.medium ? 71 : 500;
    final b = rng.nextInt(secondMax + 1);
    if (a == 0 && b == 0) {
      return _subtractionWholePair(difficulty, rng);
    }
    return (a, b);
  }

  (int, int) _nonZeroPair(
    Random rng,
    int min,
    int span, {
    int? secondMin,
    int? secondSpan,
  }) {
    var a = rng.nextInt(span) + min;
    var b = rng.nextInt(secondSpan ?? span) + (secondMin ?? min);
    var guard = 0;
    while (a == 0 && b == 0 && guard < 10) {
      a = rng.nextInt(span) + min;
      b = rng.nextInt(secondSpan ?? span) + (secondMin ?? min);
      guard++;
    }
    return (a, b);
  }

  bool _isZeroZeroQuestion(String prompt, String? rightExpr) {
    if (rightExpr != null) {
      final leftValue = _eval(prompt);
      final rightValue = _eval(rightExpr);
      return leftValue == 0 && rightValue == 0;
    }
    final numbers = RegExp(r'-?\d+')
        .allMatches(prompt)
        .map((m) => int.parse(m.group(0)!))
        .toList(growable: false);
    if (numbers.length < 2) {
      return false;
    }
    return numbers.every((n) => n == 0);
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
      if (!_isZeroZeroQuestion(prompt, rightExpr)) {
        continue;
      }
      final chapterId = row['chapter_id'] as int;
      final chapter = chapterMap[chapterId];
      if (chapter == null) {
        continue;
      }
      var replacement = _generateForKind(
        chapter.kind,
        chapter.quizMode,
        chapter.difficulty,
        Random(chapterId * 9001 + replaced),
      );
      var guard = 0;
      while (_isZeroZeroQuestion(
            replacement.prompt,
            replacement.rightExpression,
          ) &&
          guard < 10) {
        replacement = _generateForKind(
          chapter.kind,
          chapter.quizMode,
          chapter.difficulty,
          Random(chapterId * 9001 + replaced + guard + 1),
        );
        guard++;
      }
      batch.update(
        'questions',
        {
          'prompt': replacement.prompt,
          'right_expr': replacement.rightExpression,
          'correct_answer': replacement.correctAnswer,
          'options': replacement.options.join('|'),
        },
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

      var replacement = _generateForKind(
        chapter.kind,
        chapter.quizMode,
        chapter.difficulty,
        Random(chapterId * 7001 + replaced),
      );
      var guard = 0;
      while ((int.tryParse(replacement.correctAnswer) == null ||
              int.parse(replacement.correctAnswer) <= 0) &&
          guard < 20) {
        replacement = _generateForKind(
          chapter.kind,
          chapter.quizMode,
          chapter.difficulty,
          Random(chapterId * 7001 + replaced + guard + 1),
        );
        guard++;
      }

      batch.update(
        'questions',
        {
          'prompt': replacement.prompt,
          'right_expr': replacement.rightExpression,
          'correct_answer': replacement.correctAnswer,
          'options': replacement.options.join('|'),
        },
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
      if (!_hasNegativeSubtractionSecondArg(prompt)) {
        continue;
      }
      final chapterId = row['chapter_id'] as int;
      final chapter = chapterMap[chapterId];
      if (chapter == null) {
        continue;
      }
      var replacement = _generateForKind(
        chapter.kind,
        chapter.quizMode,
        chapter.difficulty,
        Random(chapterId * 8009 + replaced),
      );
      var guard = 0;
      while (_hasNegativeSubtractionSecondArg(replacement.prompt) &&
          guard < 20) {
        replacement = _generateForKind(
          chapter.kind,
          chapter.quizMode,
          chapter.difficulty,
          Random(chapterId * 8009 + replaced + guard + 1),
        );
        guard++;
      }
      batch.update(
        'questions',
        {
          'prompt': replacement.prompt,
          'right_expr': replacement.rightExpression,
          'correct_answer': replacement.correctAnswer,
          'options': replacement.options.join('|'),
        },
        where: 'id = ?',
        whereArgs: [row['id'] as int],
      );
      replaced++;
    }
    if (replaced > 0) {
      await batch.commit(noResult: true);
    }
  }

  bool _hasNegativeSubtractionSecondArg(String prompt) {
    final match = RegExp(r'^\s*-?\d+\s-\s(-?\d+)\s*$').firstMatch(prompt);
    if (match == null) {
      return false;
    }
    final second = int.tryParse(match.group(1)!);
    return second != null && second < 0;
  }

  _GeneratedQuestion _fractionOp(
    Random rng,
    String op,
    ChapterDifficulty difficulty,
  ) {
    final max = _fractionMaxForDifficulty(difficulty);
    final a = rng.nextInt(max) + 1;
    final b = rng.nextInt(max) + 2;
    final c = rng.nextInt(max) + 1;
    final d = rng.nextInt(max) + 2;
    final numerator = op == '+' ? (a * d + c * b) : (a * d - c * b);
    final denominator = b * d;
    final reduced = _reduceFraction(numerator, denominator);
    return _mc('$a/$b $op $c/$d', reduced, rng);
  }

  _GeneratedQuestion _fractionMultiply(
    Random rng,
    ChapterDifficulty difficulty,
  ) {
    final max = _fractionMaxForDifficulty(difficulty);
    final a = rng.nextInt(max) + 1;
    final b = rng.nextInt(max) + 2;
    final c = rng.nextInt(max) + 1;
    final d = rng.nextInt(max) + 2;
    final reduced = _reduceFraction(a * c, b * d);
    return _mc('$a/$b × $c/$d', reduced, rng);
  }

  int _minForDifficulty(ChapterDifficulty difficulty) {
    switch (difficulty) {
      case ChapterDifficulty.easy:
        return 0;
      case ChapterDifficulty.medium:
        return 0;
      case ChapterDifficulty.hard:
        return -500;
    }
  }

  int _spanForDifficulty(ChapterDifficulty difficulty) {
    switch (difficulty) {
      case ChapterDifficulty.easy:
        return 21;
      case ChapterDifficulty.medium:
        return 72;
      case ChapterDifficulty.hard:
        return 1001;
    }
  }

  int _mulMinForDifficulty(ChapterDifficulty difficulty) {
    switch (difficulty) {
      case ChapterDifficulty.easy:
        return 0;
      case ChapterDifficulty.medium:
        return 0;
      case ChapterDifficulty.hard:
        return -50;
    }
  }

  int _mulSpanForDifficulty(ChapterDifficulty difficulty) {
    switch (difficulty) {
      case ChapterDifficulty.easy:
        return 13;
      case ChapterDifficulty.medium:
        return 32;
      case ChapterDifficulty.hard:
        return 101;
    }
  }

  int _fractionMaxForDifficulty(ChapterDifficulty difficulty) {
    switch (difficulty) {
      case ChapterDifficulty.easy:
        return 9;
      case ChapterDifficulty.medium:
        return 20;
      case ChapterDifficulty.hard:
        return 50;
    }
  }

  int _divisorForDifficulty(ChapterDifficulty difficulty, Random rng) {
    switch (difficulty) {
      case ChapterDifficulty.easy:
        return rng.nextInt(8) + 2;
      case ChapterDifficulty.medium:
        return rng.nextInt(15) + 2;
      case ChapterDifficulty.hard:
        return rng.nextInt(30) + 2;
    }
  }

  int _quotientForDifficulty(ChapterDifficulty difficulty, Random rng) {
    switch (difficulty) {
      case ChapterDifficulty.easy:
        return rng.nextInt(21);
      case ChapterDifficulty.medium:
        return rng.nextInt(72);
      case ChapterDifficulty.hard:
        return rng.nextInt(1001) - 500;
    }
  }

  String _reduceFraction(int n, int d) {
    if (n == 0) {
      return '0';
    }
    final sign = n * d < 0 ? '-' : '';
    final nn = n.abs();
    final dd = d.abs();
    final g = _gcd(nn, dd);
    final rn = nn ~/ g;
    final rd = dd ~/ g;
    if (rd == 1) {
      return '$sign$rn';
    }
    return '$sign$rn/$rd';
  }

  int _gcd(int a, int b) {
    var x = a;
    var y = b;
    while (y != 0) {
      final t = x % y;
      x = y;
      y = t;
    }
    return x;
  }

  double _eval(String expr) {
    if (expr.contains('/')) {
      final parts = expr.split('/');
      if (parts.length == 2) {
        return int.parse(parts[0]) / int.parse(parts[1]);
      }
    }
    if (expr.contains('+')) {
      final parts = expr.split('+');
      return parts.map((e) => _eval(e.trim())).reduce((a, b) => a + b);
    }
    if (expr.contains('×')) {
      final parts = expr.split('×');
      return parts.map((e) => _eval(e.trim())).reduce((a, b) => a * b);
    }
    if (expr.contains('÷')) {
      final parts = expr.split('÷');
      return _eval(parts[0].trim()) / _eval(parts[1].trim());
    }
    if (expr.contains('^')) {
      final parts = expr.split('^');
      return pow(_eval(parts[0].trim()), _eval(parts[1].trim())).toDouble();
    }
    return double.parse(expr.replaceAll('(', '').replaceAll(')', '').trim());
  }
}

class _GeneratedQuestion {
  const _GeneratedQuestion({
    required this.prompt,
    required this.rightExpression,
    required this.correctAnswer,
    required this.options,
  });

  final String prompt;
  final String? rightExpression;
  final String correctAnswer;
  final List<String> options;
}

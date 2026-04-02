import 'package:sqflite/sqflite.dart';

import '../../features/chapters/domain/chapter_models.dart';

class StartStats {
  const StartStats({required this.completedChapters, required this.totalStars});

  final int completedChapters;
  final int totalStars;
}

class ChaptersDao {
  Future<List<ChapterView>> fetchChapterViews(Database db) async {
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

  Future<ChapterView?> fetchChapterViewById(Database db, int chapterId) async {
    final chapters = await fetchChapterViews(db);
    for (final chapter in chapters) {
      if (chapter.definition.id == chapterId) {
        return chapter;
      }
    }
    return null;
  }

  Future<StartStats> fetchStartStats(Database db) async {
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

  Future<int?> nextChapterId(Database db, int chapterId) {
    return _nextChapterIdInTxn(db, chapterId);
  }

  Future<void> skipHardChapter(Database db, int chapterId) async {
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

  Future<void> resetProgress(Database db) async {
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

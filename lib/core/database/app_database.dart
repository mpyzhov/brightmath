import 'dart:math';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../features/chapters/domain/chapter_models.dart';
import '../../features/quiz/domain/question_models.dart';
import 'chapters_dao.dart';
import 'database_initializer.dart';
import 'database_seed_service.dart';
import 'quiz_dao.dart';

class AppDatabase {
  AppDatabase({
    DatabaseInitializer? initializer,
    DatabaseSeedService? seedService,
    ChaptersDao? chaptersDao,
    QuizDao? quizDao,
  }) : _initializer = initializer ?? DatabaseInitializer(),
       _seedService = seedService ?? DatabaseSeedService(),
       _chaptersDao = chaptersDao ?? ChaptersDao(),
       _quizDao = quizDao ?? QuizDao();

  final DatabaseInitializer _initializer;
  final DatabaseSeedService _seedService;
  final ChaptersDao _chaptersDao;
  final QuizDao _quizDao;

  Database? _db;

  Future<Database> get database async {
    if (_db != null) {
      return _db!;
    }
    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      p.join(dbPath, 'brightmath.db'),
      version: 9,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    return _db!;
  }

  Future<void> _onCreate(Database db, int version) async {
    await _initializer.initialize(db);
    await _seedService.seedInitialContent(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    await _initializer.upgrade(db, oldVersion, newVersion);
    await _seedService.syncExistingContent(db);
  }

  Future<List<ChapterView>> fetchChapterViews() async {
    return _chaptersDao.fetchChapterViews(await database);
  }

  Future<ChapterView?> fetchChapterViewById(int chapterId) async {
    return _chaptersDao.fetchChapterViewById(await database, chapterId);
  }

  Future<StartStats> fetchStartStats() async {
    return _chaptersDao.fetchStartStats(await database);
  }

  Future<List<QuizQuestion>> fetchRandomQuestions(
    int chapterId, {
    int count = 20,
    Random? random,
  }) async {
    return _quizDao.fetchRandomQuestions(
      await database,
      chapterId,
      count: count,
      random: random,
    );
  }

  Future<void> saveRunResult(QuizRunResult result) async {
    await _quizDao.saveRunResult(await database, result);
  }

  Future<int?> nextChapterId(int chapterId) async {
    return _chaptersDao.nextChapterId(await database, chapterId);
  }

  Future<void> skipHardChapter(int chapterId) async {
    await _chaptersDao.skipHardChapter(await database, chapterId);
  }

  Future<void> resetProgress() async {
    await _chaptersDao.resetProgress(await database);
  }
}

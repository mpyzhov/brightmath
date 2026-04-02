import '../../../core/database/app_database.dart';
import '../../../core/database/chapters_dao.dart';
import '../domain/chapter_models.dart';

class ChaptersRepository {
  ChaptersRepository(this._database);

  final AppDatabase _database;

  Future<List<ChapterView>> loadChapterViews() {
    return _database.fetchChapterViews();
  }

  Future<StartStats> loadStartStats() {
    return _database.fetchStartStats();
  }

  Future<ChapterView?> loadChapterViewById(int chapterId) {
    return _database.fetchChapterViewById(chapterId);
  }

  Future<int?> nextChapterId(int chapterId) {
    return _database.nextChapterId(chapterId);
  }

  Future<void> skipHardChapter(int chapterId) {
    return _database.skipHardChapter(chapterId);
  }

  Future<void> resetProgress() {
    return _database.resetProgress();
  }
}

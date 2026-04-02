import '../../../core/database/app_database.dart';
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
}

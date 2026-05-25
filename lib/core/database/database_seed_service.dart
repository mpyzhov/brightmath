import 'package:sqflite/sqflite.dart';

import 'database_manifest.dart';
import 'database_script_runner.dart';

class DatabaseSeedService {
  DatabaseSeedService({
    DatabaseScriptRunner? scriptRunner,
    Future<DatabaseManifest> Function()? loadManifest,
  }) : _scriptRunner = scriptRunner ?? DatabaseScriptRunner(),
       _loadManifest = loadManifest ?? DatabaseManifest.load;

  final DatabaseScriptRunner _scriptRunner;
  final Future<DatabaseManifest> Function() _loadManifest;

  Future<void> seedInitialContent(Database db) async {
    await _runInitialContent(db);
    await _seedProgress(db, onlyMissing: false);
  }

  Future<void> syncExistingContent(Database db) async {
    await _replaceStaticContent(db);
    await _seedProgress(db, onlyMissing: true);
  }

  Future<void> _runInitialContent(Database db) async {
    final manifest = await _loadManifest();
    await _scriptRunner.runFiles(db, manifest.initialContentScripts);
  }

  Future<void> _replaceStaticContent(Database db) async {
    await db.delete('questions');
    await _runInitialContent(db);
  }

  Future<void> _seedProgress(Database db, {required bool onlyMissing}) async {
    if (!onlyMissing) {
      await db.delete('progress');
      await db.execute('''
        INSERT INTO progress (
          chapter_id,
          is_unlocked,
          is_completed,
          is_skipped,
          best_score,
          best_stars
        )
        SELECT
          id,
          CASE WHEN order_index = 1 THEN 1 ELSE 0 END,
          0,
          0,
          0,
          0
        FROM chapters
        ORDER BY order_index ASC
      ''');
      return;
    }

    await db.execute('''
      INSERT INTO progress (
        chapter_id,
        is_unlocked,
        is_completed,
        is_skipped,
        best_score,
        best_stars
      )
      SELECT
        c.id,
        CASE WHEN c.order_index = 1 THEN 1 ELSE 0 END,
        0,
        0,
        0,
        0
      FROM chapters c
      LEFT JOIN progress p ON p.chapter_id = c.id
      WHERE p.chapter_id IS NULL
      ORDER BY c.order_index ASC
    ''');
  }
}

import 'package:sqflite/sqflite.dart';

import 'database_manifest.dart';
import 'database_script_runner.dart';

class DatabaseInitializer {
  DatabaseInitializer({
    DatabaseScriptRunner? scriptRunner,
    Future<DatabaseManifest> Function()? loadManifest,
  }) : _scriptRunner = scriptRunner ?? DatabaseScriptRunner(),
       _loadManifest = loadManifest ?? DatabaseManifest.load;

  final DatabaseScriptRunner _scriptRunner;
  final Future<DatabaseManifest> Function() _loadManifest;

  Future<void> initialize(Database db) async {
    final manifest = await _loadManifest();
    await _scriptRunner.runFiles(db, manifest.createScripts);
  }

  Future<void> upgrade(Database db, int oldVersion, int newVersion) async {
    await initialize(db);

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
    await _addColumnIfMissing(
      db,
      table: 'questions',
      column: 'question_key',
      declaration: 'TEXT',
    );
    await _addColumnIfMissing(
      db,
      table: 'questions',
      column: 'content_version',
      declaration: 'INTEGER NOT NULL DEFAULT 1',
    );

    final manifest = await _loadManifest();
    await _scriptRunner.runFiles(
      db,
      manifest.upgradeScriptsFor(oldVersion, newVersion),
    );
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
}

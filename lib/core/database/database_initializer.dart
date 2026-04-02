import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseInitializer {
  static const _schemaAssetPath =
      'lib/core/database/migrations/001_initial_schema.sql';

  String? _cachedSchema;

  Future<void> initialize(Database db) async {
    for (final statement in await _schemaStatements()) {
      await db.execute(statement);
    }
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
  }

  Future<List<String>> _schemaStatements() async {
    final script = _cachedSchema ??= await rootBundle.loadString(
      _schemaAssetPath,
    );
    final buffer = StringBuffer();
    for (final line in script.split('\n')) {
      final trimmed = line.trimLeft();
      if (trimmed.startsWith('--')) {
        continue;
      }
      buffer.writeln(line);
    }

    return buffer
        .toString()
        .split(';')
        .map((statement) => statement.trim())
        .where((statement) => statement.isNotEmpty)
        .toList(growable: false);
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

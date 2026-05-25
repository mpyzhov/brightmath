import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseScriptRunner {
  DatabaseScriptRunner({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;

  Future<void> runFiles(
    DatabaseExecutor executor,
    Iterable<String> assetPaths,
  ) async {
    for (final path in assetPaths) {
      await runFile(executor, path);
    }
  }

  Future<void> runFile(DatabaseExecutor executor, String assetPath) async {
    final script = await _bundle.loadString(assetPath);
    for (final statement in _splitStatements(script)) {
      await executor.execute(statement);
    }
  }

  List<String> _splitStatements(String script) {
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
}

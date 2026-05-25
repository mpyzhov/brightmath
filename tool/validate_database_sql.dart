import 'dart:convert';
import 'dart:io';

const _manifestPath = 'assets/database/manifest.json';

void main() async {
  final manifest =
      jsonDecode(await File(_manifestPath).readAsString())
          as Map<String, Object?>;
  final scripts = ((manifest['initialContentScripts'] as List<Object?>?) ?? [])
      .cast<String>()
      .where((path) => path.contains('/questions/'))
      .toList(growable: false);

  final scriptPaths = <String>{};
  final globalKeys = <String>{};

  for (final path in scripts) {
    _expect(scriptPaths.add(path), 'Duplicate question script path: $path.');
    final questions = _readQuestions(path);

    final localKeys = <String>{};
    final localQuestions = <String>{};
    for (final question in questions) {
      _expect(
        localKeys.add(question.questionKey),
        '$path contains duplicate key ${question.questionKey}.',
      );
      _expect(
        globalKeys.add('${question.chapterId}:${question.questionKey}'),
        'Duplicate global question key '
        '${question.chapterId}:${question.questionKey}.',
      );
      _expect(
        localQuestions.add(question.identity),
        '$path contains duplicate question ${question.questionKey}.',
      );
    }
  }
}

List<_SqlQuestion> _readQuestions(String path) {
  final regex = RegExp(
    r"^\s*\((\d+), '([^']+)', '((?:''|[^'])*)', "
    r"(NULL|'(?:''|[^'])*'), '((?:''|[^'])*)', "
    r"'((?:''|[^'])*)', 1\)[,;]$",
  );
  final questions = <_SqlQuestion>[];
  for (final line in File(path).readAsLinesSync()) {
    final match = regex.firstMatch(line);
    if (match == null) {
      continue;
    }
    final rightExprRaw = match.group(4)!;
    questions.add(
      _SqlQuestion(
        chapterId: int.parse(match.group(1)!),
        questionKey: _unescape(match.group(2)!),
        prompt: _unescape(match.group(3)!),
        rightExpr: rightExprRaw == 'NULL'
            ? null
            : _unescape(rightExprRaw.substring(1, rightExprRaw.length - 1)),
        correctAnswer: _unescape(match.group(5)!),
        options: _unescape(match.group(6)!).split('|'),
      ),
    );
  }
  return questions;
}

String _unescape(String value) => value.replaceAll("''", "'");

void _expect(bool condition, String message) {
  if (!condition) {
    throw StateError(message);
  }
}

class _SqlQuestion {
  const _SqlQuestion({
    required this.chapterId,
    required this.questionKey,
    required this.prompt,
    required this.rightExpr,
    required this.correctAnswer,
    required this.options,
  });

  final int chapterId;
  final String questionKey;
  final String prompt;
  final String? rightExpr;
  final String correctAnswer;
  final List<String> options;

  String get identity => [prompt, rightExpr ?? ''].join('\u0001');
}

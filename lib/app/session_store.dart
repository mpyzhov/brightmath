import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../features/chapters/domain/chapter_models.dart';
import '../features/quiz/domain/question_models.dart';

class RootSession {
  const RootSession({required this.pageIndex, this.chapterId});

  final int pageIndex;
  final int? chapterId;
}

class QuizRunSnapshot {
  const QuizRunSnapshot({
    required this.chapterId,
    required this.currentIndex,
    required this.selectedAnswer,
    required this.isLocked,
    required this.remainingMillis,
    required this.answers,
    required this.questions,
  });

  final int chapterId;
  final int currentIndex;
  final String? selectedAnswer;
  final bool isLocked;
  final int remainingMillis;
  final Map<int, String> answers;
  final List<QuizQuestion> questions;

  Map<String, dynamic> toJson() {
    return {
      'chapterId': chapterId,
      'currentIndex': currentIndex,
      'selectedAnswer': selectedAnswer,
      'isLocked': isLocked,
      'remainingMillis': remainingMillis,
      'answers': answers.map((key, value) => MapEntry('$key', value)),
      'questions': questions
          .map(
            (question) => <String, dynamic>{
              'id': question.id,
              'chapterId': question.chapterId,
              'prompt': question.prompt,
              'mode': question.mode.name,
              'rightExpression': question.rightExpression,
              'options': question.options,
              'correctAnswer': question.correctAnswer,
            },
          )
          .toList(growable: false),
    };
  }

  static QuizRunSnapshot? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      return null;
    }

    final chapterId = json['chapterId'];
    final currentIndex = json['currentIndex'];
    final selectedAnswer = json['selectedAnswer'];
    final isLocked = json['isLocked'];
    final remainingMillis = json['remainingMillis'];
    final answersRaw = json['answers'];
    final questionsRaw = json['questions'];

    if (chapterId is! int ||
        currentIndex is! int ||
        isLocked is! bool ||
        remainingMillis is! int ||
        answersRaw is! Map<String, dynamic> ||
        questionsRaw is! List) {
      return null;
    }

    final questions = <QuizQuestion>[];
    for (final item in questionsRaw) {
      if (item is! Map<String, dynamic>) {
        return null;
      }
      final id = item['id'];
      final itemChapterId = item['chapterId'];
      final prompt = item['prompt'];
      final modeName = item['mode'];
      final options = item['options'];
      final correctAnswer = item['correctAnswer'];
      final rightExpression = item['rightExpression'];
      if (id is! int ||
          itemChapterId is! int ||
          prompt is! String ||
          modeName is! String ||
          options is! List ||
          correctAnswer is! String) {
        return null;
      }
      final mode = QuizMode.values.firstWhere(
        (value) => value.name == modeName,
        orElse: () => QuizMode.multipleChoice,
      );
      questions.add(
        QuizQuestion(
          id: id,
          chapterId: itemChapterId,
          prompt: prompt,
          mode: mode,
          rightExpression: rightExpression is String ? rightExpression : null,
          options: options.whereType<String>().toList(growable: false),
          correctAnswer: correctAnswer,
        ),
      );
    }

    if (questions.isEmpty ||
        currentIndex < 0 ||
        currentIndex >= questions.length) {
      return null;
    }

    final answers = <int, String>{};
    answersRaw.forEach((key, value) {
      final id = int.tryParse(key);
      if (id != null && value is String) {
        answers[id] = value;
      }
    });

    return QuizRunSnapshot(
      chapterId: chapterId,
      currentIndex: currentIndex,
      selectedAnswer: selectedAnswer is String ? selectedAnswer : null,
      isLocked: isLocked,
      remainingMillis: remainingMillis,
      answers: answers,
      questions: questions,
    );
  }
}

class SessionStore {
  static const _sessionPageKey = 'root_flow_page';
  static const _sessionChapterIdKey = 'root_flow_chapter_id';

  Future<void> saveRootSession(RootSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_sessionPageKey, session.pageIndex);
    if (session.chapterId == null) {
      await prefs.remove(_sessionChapterIdKey);
    } else {
      await prefs.setInt(_sessionChapterIdKey, session.chapterId!);
    }
  }

  Future<RootSession?> loadRootSession() async {
    final prefs = await SharedPreferences.getInstance();
    final pageIndex = prefs.getInt(_sessionPageKey);
    if (pageIndex == null) {
      return null;
    }
    return RootSession(
      pageIndex: pageIndex,
      chapterId: prefs.getInt(_sessionChapterIdKey),
    );
  }

  Future<void> saveQuizSnapshot(QuizRunSnapshot snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _snapshotKey(snapshot.chapterId),
      jsonEncode(snapshot.toJson()),
    );
  }

  Future<QuizRunSnapshot?> loadQuizSnapshot(int chapterId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_snapshotKey(chapterId));
    if (raw == null) {
      return null;
    }

    try {
      return QuizRunSnapshot.fromJson(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  Future<void> clearQuizSnapshot(int chapterId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_snapshotKey(chapterId));
  }

  String _snapshotKey(int chapterId) => 'quiz_snapshot_chapter_$chapterId';
}

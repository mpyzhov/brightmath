import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:state_notifier/state_notifier.dart';

import '../../../app/app_providers.dart';
import '../../../app/session_store.dart';
import '../data/quiz_repository.dart';
import '../domain/question_models.dart';
import '../domain/quiz_logic.dart';

const _unset = Object();

class QuizRunState {
  const QuizRunState({
    required this.isLoading,
    required this.questions,
    required this.currentIndex,
    required this.selectedAnswer,
    required this.isLocked,
    required this.remainingMillis,
    required this.answers,
    required this.isAdvancing,
    required this.completedResult,
  });

  factory QuizRunState.initial() {
    return const QuizRunState(
      isLoading: true,
      questions: [],
      currentIndex: 0,
      selectedAnswer: null,
      isLocked: false,
      remainingMillis: QuizController.countdownDurationMs,
      answers: {},
      isAdvancing: false,
      completedResult: null,
    );
  }

  final bool isLoading;
  final List<QuizQuestion> questions;
  final int currentIndex;
  final String? selectedAnswer;
  final bool isLocked;
  final int remainingMillis;
  final Map<int, String> answers;
  final bool isAdvancing;
  final QuizRunResult? completedResult;

  QuizQuestion? get currentQuestion {
    if (questions.isEmpty || currentIndex >= questions.length) {
      return null;
    }
    return questions[currentIndex];
  }

  QuizRunState copyWith({
    bool? isLoading,
    List<QuizQuestion>? questions,
    int? currentIndex,
    Object? selectedAnswer = _unset,
    bool? isLocked,
    int? remainingMillis,
    Map<int, String>? answers,
    bool? isAdvancing,
    Object? completedResult = _unset,
  }) {
    return QuizRunState(
      isLoading: isLoading ?? this.isLoading,
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      selectedAnswer: identical(selectedAnswer, _unset)
          ? this.selectedAnswer
          : selectedAnswer as String?,
      isLocked: isLocked ?? this.isLocked,
      remainingMillis: remainingMillis ?? this.remainingMillis,
      answers: answers ?? this.answers,
      isAdvancing: isAdvancing ?? this.isAdvancing,
      completedResult: identical(completedResult, _unset)
          ? this.completedResult
          : completedResult as QuizRunResult?,
    );
  }
}

class QuizController extends StateNotifier<QuizRunState> {
  QuizController({
    required QuizRepository repository,
    required SessionStore sessionStore,
    required int chapterId,
  }) : _repository = repository,
       _sessionStore = sessionStore,
       _chapterId = chapterId,
       super(QuizRunState.initial()) {
    unawaited(_initialize());
  }

  static const countdownDurationMs = 3000;
  static const _tickInterval = Duration(milliseconds: 100);

  final QuizRepository _repository;
  final SessionStore _sessionStore;
  final int _chapterId;

  Timer? _countdownTimer;

  Future<void> _initialize() async {
    final restored = await _sessionStore.loadQuizSnapshot(_chapterId);
    if (restored != null) {
      state = state.copyWith(
        isLoading: false,
        questions: restored.questions,
        currentIndex: restored.currentIndex,
        selectedAnswer: restored.selectedAnswer,
        isLocked: restored.isLocked,
        remainingMillis: restored.remainingMillis.clamp(0, countdownDurationMs),
        answers: restored.answers,
      );
      _resumeCountdownIfNeeded();
      return;
    }

    final loaded = await _repository.startRun(_chapterId);
    state = state.copyWith(
      isLoading: false,
      questions: loaded,
      currentIndex: 0,
      selectedAnswer: null,
      isLocked: false,
      remainingMillis: countdownDurationMs,
      answers: const {},
    );
    await persistSnapshot();
  }

  Future<void> selectAnswer(String answer) async {
    if (state.isLoading || state.isLocked || state.currentQuestion == null) {
      return;
    }

    final question = state.currentQuestion!;
    final answers = Map<int, String>.from(state.answers)
      ..[question.id] = answer;
    state = state.copyWith(
      selectedAnswer: answer,
      isLocked: true,
      remainingMillis: countdownDurationMs,
      answers: answers,
    );
    await persistSnapshot();
    _startCountdown(countdownDurationMs);
  }

  Future<void> nextOrFinish() async {
    await _advanceOrFinish();
  }

  Future<void> persistSnapshot() async {
    if (state.isLoading ||
        state.questions.isEmpty ||
        state.completedResult != null) {
      return;
    }

    await _sessionStore.saveQuizSnapshot(
      QuizRunSnapshot(
        chapterId: _chapterId,
        currentIndex: state.currentIndex,
        selectedAnswer: state.selectedAnswer,
        isLocked: state.isLocked,
        remainingMillis: state.remainingMillis,
        answers: state.answers,
        questions: state.questions,
      ),
    );
  }

  Future<void> clearSnapshot() async {
    await _sessionStore.clearQuizSnapshot(_chapterId);
  }

  void _resumeCountdownIfNeeded() {
    if (!state.isLocked) {
      return;
    }
    if (state.remainingMillis <= 0) {
      Future<void>.microtask(_advanceOrFinish);
      return;
    }
    _startCountdown(state.remainingMillis);
  }

  void _startCountdown(int fromMillis) {
    _countdownTimer?.cancel();
    final start = DateTime.now();
    _countdownTimer = Timer.periodic(_tickInterval, (timer) {
      if (!state.isLocked) {
        timer.cancel();
        return;
      }

      final elapsed = DateTime.now().difference(start).inMilliseconds;
      final remaining = (fromMillis - elapsed).clamp(0, countdownDurationMs);
      if (remaining != state.remainingMillis) {
        state = state.copyWith(remainingMillis: remaining);
      }
      if (remaining == 0) {
        timer.cancel();
        unawaited(_advanceOrFinish());
      }
    });
  }

  Future<void> _advanceOrFinish() async {
    if (state.isLoading ||
        !state.isLocked ||
        state.isAdvancing ||
        state.currentQuestion == null) {
      return;
    }

    _countdownTimer?.cancel();
    state = state.copyWith(isAdvancing: true);

    if (state.currentIndex < state.questions.length - 1) {
      state = state.copyWith(
        currentIndex: state.currentIndex + 1,
        selectedAnswer: null,
        isLocked: false,
        remainingMillis: countdownDurationMs,
        isAdvancing: false,
      );
      await persistSnapshot();
      return;
    }

    final results = <QuestionResult>[];
    var correct = 0;
    for (final question in state.questions) {
      final userAnswer = state.answers[question.id] ?? '';
      final isCorrect = userAnswer == question.correctAnswer;
      if (isCorrect) {
        correct++;
      }
      final prompt = question.rightExpression == null
          ? question.prompt
          : '${question.prompt} ? ${question.rightExpression}';
      results.add(
        QuestionResult(
          questionId: question.id,
          prompt: prompt,
          userAnswer: userAnswer,
          correctAnswer: question.correctAnswer,
          isCorrect: isCorrect,
        ),
      );
    }

    final result = QuizRunResult(
      chapterId: _chapterId,
      correctCount: correct,
      totalCount: state.questions.length,
      starsEarned: starsForCorrectCount(correct),
      results: results,
    );
    await _repository.saveRun(result);
    await clearSnapshot();
    state = state.copyWith(
      isAdvancing: false,
      remainingMillis: 0,
      completedResult: result,
    );
  }
}

final quizControllerProvider = StateNotifierProvider.autoDispose
    .family<QuizController, QuizRunState, int>((ref, chapterId) {
      return QuizController(
        repository: ref.read(quizRepositoryProvider),
        sessionStore: ref.read(sessionStoreProvider),
        chapterId: chapterId,
      );
    });

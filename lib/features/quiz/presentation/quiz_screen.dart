import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../chapters/domain/chapter_models.dart';
import '../../chapters/presentation/chapters_controller.dart';
import '../data/quiz_repository.dart';
import '../domain/question_models.dart';

class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({
    super.key,
    required this.chapterId,
    required this.chapterTitle,
    required this.onBack,
    required this.onFinish,
  });

  final int chapterId;
  final String chapterTitle;
  final VoidCallback onBack;
  final void Function(QuizRunResult result) onFinish;

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  static const int _maxOptionSlots = 4;
  static const int _countdownSeconds = 3;
  static const double _nextButtonAreaHeight = 56;
  static const double _optionSlotHeight = 66;
  static const double _optionsGridHeight = 148;
  List<QuizQuestion>? _questions;
  int _currentIndex = 0;
  String? _selectedAnswer;
  bool _isLocked = false;
  int _secondsLeft = _countdownSeconds;
  final Map<int, String> _answers = <int, String>{};
  bool _isAdvancing = false;
  late final AnimationController _countdownController;
  late final Animation<double> _countdownCurve;

  QuizRepository get _repository =>
      QuizRepository(ref.read(appDatabaseProvider));

  String get _snapshotKey => 'quiz_snapshot_chapter_${widget.chapterId}';

  @override
  void initState() {
    super.initState();
    _countdownController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: _countdownSeconds),
    );
    _countdownCurve = CurvedAnimation(
      parent: _countdownController,
      curve: Curves.easeOutCubic,
    );
    _countdownController.addStatusListener((status) {
      if (status == AnimationStatus.completed && _isLocked) {
        _secondsLeft = 0;
        unawaited(_persistRunSnapshot());
        unawaited(_nextOrFinish());
      }
    });
    WidgetsBinding.instance.addObserver(this);
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    final restored = await _restoreRunSnapshot();
    if (restored) {
      return;
    }
    final loaded = await _repository.startRun(widget.chapterId);
    if (mounted) {
      setState(() => _questions = loaded);
      unawaited(_persistRunSnapshot());
    }
  }

  void _selectAnswer(String answer) {
    if (_isLocked || _questions == null) {
      return;
    }
    final question = _questions![_currentIndex];
    _answers[question.id] = answer;
    setState(() {
      _selectedAnswer = answer;
      _isLocked = true;
      _secondsLeft = _countdownSeconds;
    });
    unawaited(_persistRunSnapshot());
    _startCountdown(fromSeconds: _countdownSeconds);
  }

  void _startCountdown({required int fromSeconds}) {
    _countdownController.stop();
    final clamped = fromSeconds.clamp(0, _countdownSeconds);
    _secondsLeft = clamped;
    if (clamped == 0) {
      unawaited(_nextOrFinish());
      return;
    }
    final startValue = (_countdownSeconds - clamped) / _countdownSeconds;
    _countdownController.value = startValue;
    _countdownController.forward();
  }

  Future<void> _nextOrFinish() async {
    if (!_isLocked || _questions == null || _isAdvancing) {
      return;
    }
    _isAdvancing = true;
    _countdownController.stop();
    if (_currentIndex < _questions!.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedAnswer = null;
        _isLocked = false;
        _secondsLeft = _countdownSeconds;
      });
      unawaited(_persistRunSnapshot());
      _isAdvancing = false;
      return;
    }

    final results = <QuestionResult>[];
    var correct = 0;
    for (final q in _questions!) {
      final userAnswer = _answers[q.id] ?? '';
      final isCorrect = userAnswer == q.correctAnswer;
      if (isCorrect) {
        correct++;
      }
      final prompt = q.rightExpression == null
          ? q.prompt
          : '${q.prompt} ? ${q.rightExpression}';
      results.add(
        QuestionResult(
          questionId: q.id,
          prompt: prompt,
          userAnswer: userAnswer,
          correctAnswer: q.correctAnswer,
          isCorrect: isCorrect,
        ),
      );
    }
    final result = QuizRunResult(
      chapterId: widget.chapterId,
      correctCount: correct,
      totalCount: _questions!.length,
      starsEarned: correct >= 20
          ? 3
          : (correct >= 18 ? 2 : (correct >= 15 ? 1 : 0)),
      results: results,
    );
    await _repository.saveRun(result);
    await _clearRunSnapshot();
    _isAdvancing = false;
    widget.onFinish(result);
  }

  Future<void> _persistRunSnapshot() async {
    final questions = _questions;
    if (questions == null) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final payload = <String, dynamic>{
      'chapterId': widget.chapterId,
      'currentIndex': _currentIndex,
      'selectedAnswer': _selectedAnswer,
      'isLocked': _isLocked,
      'secondsLeft': _secondsLeftForSnapshot(),
      'answers': _answers.map((k, v) => MapEntry('$k', v)),
      'questions': questions
          .map(
            (q) => <String, dynamic>{
              'id': q.id,
              'chapterId': q.chapterId,
              'prompt': q.prompt,
              'mode': q.mode.name,
              'rightExpression': q.rightExpression,
              'options': q.options,
              'correctAnswer': q.correctAnswer,
            },
          )
          .toList(),
    };
    await prefs.setString(_snapshotKey, jsonEncode(payload));
  }

  Future<bool> _restoreRunSnapshot() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_snapshotKey);
    if (raw == null) {
      return false;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return false;
      }

      final chapterId = decoded['chapterId'];
      final currentIndex = decoded['currentIndex'];
      final selectedAnswer = decoded['selectedAnswer'];
      final isLocked = decoded['isLocked'];
      final secondsLeft = decoded['secondsLeft'];
      final answersRaw = decoded['answers'];
      final questionsRaw = decoded['questions'];

      if (chapterId != widget.chapterId ||
          currentIndex is! int ||
          isLocked is! bool ||
          secondsLeft is! int ||
          answersRaw is! Map<String, dynamic> ||
          questionsRaw is! List) {
        return false;
      }

      final restoredQuestions = <QuizQuestion>[];
      for (final item in questionsRaw) {
        if (item is! Map<String, dynamic>) {
          return false;
        }
        final id = item['id'];
        final chapterId = item['chapterId'];
        final prompt = item['prompt'];
        final modeName = item['mode'];
        final options = item['options'];
        final correctAnswer = item['correctAnswer'];
        final rightExpression = item['rightExpression'];
        if (id is! int ||
            chapterId is! int ||
            prompt is! String ||
            modeName is! String ||
            options is! List ||
            correctAnswer is! String) {
          return false;
        }
        final mode = QuizMode.values.firstWhere(
          (value) => value.name == modeName,
          orElse: () => QuizMode.multipleChoice,
        );
        restoredQuestions.add(
          QuizQuestion(
            id: id,
            chapterId: chapterId,
            prompt: prompt,
            mode: mode,
            rightExpression: rightExpression is String ? rightExpression : null,
            options: options.whereType<String>().toList(growable: false),
            correctAnswer: correctAnswer,
          ),
        );
      }
      if (restoredQuestions.isEmpty ||
          currentIndex < 0 ||
          currentIndex >= restoredQuestions.length) {
        return false;
      }

      final restoredAnswers = <int, String>{};
      answersRaw.forEach((key, value) {
        final id = int.tryParse(key);
        if (id != null && value is String) {
          restoredAnswers[id] = value;
        }
      });

      if (!mounted) {
        return true;
      }
      setState(() {
        _questions = restoredQuestions;
        _currentIndex = currentIndex;
        _selectedAnswer = selectedAnswer is String ? selectedAnswer : null;
        _isLocked = isLocked;
        _secondsLeft = secondsLeft.clamp(0, _countdownSeconds);
        _answers
          ..clear()
          ..addAll(restoredAnswers);
      });
      if (_isLocked && _secondsLeft > 0) {
        _startCountdown(fromSeconds: _secondsLeft);
      } else if (_isLocked && _secondsLeft == 0) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => unawaited(_nextOrFinish()),
        );
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _clearRunSnapshot() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_snapshotKey);
  }

  @override
  void dispose() {
    _countdownController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(_persistRunSnapshot());
    }
  }

  Future<void> _handleBack() async {
    _countdownController.stop();
    await _clearRunSnapshot();
    widget.onBack();
  }

  int _secondsLeftForUi() {
    if (!_isLocked) {
      return _secondsLeft;
    }
    final remaining = (_countdownSeconds * (1 - _countdownCurve.value)).ceil();
    return remaining.clamp(0, _countdownSeconds);
  }

  int _secondsLeftForSnapshot() {
    if (!_isLocked) {
      return _secondsLeft;
    }
    return _secondsLeftForUi();
  }

  Widget _buildCountdownCircle() {
    return AnimatedBuilder(
      animation: _countdownController,
      builder: (context, _) {
        final progress = (1 - _countdownCurve.value).clamp(0.0, 1.0);
        final seconds = _secondsLeftForUi();
        return SizedBox(
          width: 26,
          height: 26,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: progress,
                strokeWidth: 2.6,
                strokeCap: StrokeCap.round,
                color: Colors.white,
                backgroundColor: Colors.white.withValues(alpha: 0.28),
              ),
              Text(
                '$seconds',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final questions = _questions;
    if (questions == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final q = questions[_currentIndex];
    final prompt = q.rightExpression == null
        ? q.prompt
        : '${q.prompt} ? ${q.rightExpression}';
    final total = questions.length;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: _handleBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(strings.t('quiz')),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.volume_up_rounded),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.settings_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: 320,
                height: 100,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFD9E5ED)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.ad_units_rounded, size: 16, color: Colors.grey),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Ad banner • clearly separated',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 14,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(total, (index) {
                      final current = index == _currentIndex;
                      final answer = _answers[questions[index].id];
                      final answered = answer != null;
                      final correct = answered
                          ? answer == questions[index].correctAnswer
                          : false;
                      final color = current
                          ? AppTheme.navy
                          : (!answered
                                ? Colors.grey.shade400
                                : (correct
                                      ? AppTheme.correctGreen
                                      : AppTheme.incorrectRed));
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        width: 15,
                        height: 15,
                        alignment: Alignment.center,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: current ? 15 : 9,
                          height: current ? 15 : 9,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: current
                                ? Border.all(color: Colors.white, width: 1.2)
                                : null,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 150,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: Card(
                    key: ValueKey('question_$_currentIndex'),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          prompt,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(
                            context,
                          ).textTheme.headlineMedium?.copyWith(fontSize: 32),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: _optionsGridHeight,
                child: Column(
                  children: List.generate(2, (row) {
                    return Expanded(
                      child: Row(
                        children: List.generate(2, (col) {
                          final index = row * 2 + col;
                          final option = index < q.options.length
                              ? q.options[index]
                              : null;
                          final isSelected =
                              option != null && _selectedAnswer == option;
                          final isCorrect =
                              option != null && option == q.correctAnswer;
                          Color? background;
                          if (_isLocked && isSelected) {
                            background = isCorrect
                                ? AppTheme.correctGreen
                                : AppTheme.incorrectRed;
                          }
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                left: col == 1 ? 6 : 0,
                                right: col == 0 ? 6 : 0,
                                top: row == 1 ? 6 : 0,
                                bottom: row == 0 ? 6 : 0,
                              ),
                              child: option == null
                                  ? Container(
                                      key: ValueKey(
                                        'option_placeholder_${_currentIndex}_$index',
                                      ),
                                    )
                                  : AnimatedScale(
                                      key: ValueKey(
                                        'option_slot_${_currentIndex}_$index',
                                      ),
                                      duration: const Duration(
                                        milliseconds: 170,
                                      ),
                                      scale: isSelected ? 1.03 : 1.0,
                                      child: SizedBox(
                                        width: double.infinity,
                                        height: _optionSlotHeight,
                                        child: FilledButton(
                                          style: FilledButton.styleFrom(
                                            backgroundColor:
                                                background ?? AppTheme.teal,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            side: BorderSide(
                                              color: isSelected
                                                  ? Colors.white.withValues(
                                                      alpha: 0.85,
                                                    )
                                                  : Colors.transparent,
                                              width: 1.2,
                                            ),
                                          ),
                                          onPressed: _isLocked
                                              ? () {}
                                              : () => _selectAnswer(option),
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 170,
                                            ),
                                            curve: Curves.easeOut,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 2,
                                            ),
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Text(
                                                option,
                                                style: const TextStyle(
                                                  fontSize: 28,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                            ),
                          );
                        }),
                      ),
                    );
                  }),
                ),
              ),
              const Spacer(),
              SizedBox(
                height: _nextButtonAreaHeight,
                width: double.infinity,
                child: IgnorePointer(
                  ignoring: !_isLocked,
                  child: AnimatedOpacity(
                    opacity: _isLocked ? 1 : 0,
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    child: FilledButton(
                      onPressed: _nextOrFinish,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.navy,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(strings.t('next')),
                          const SizedBox(width: 10),
                          _buildCountdownCircle(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

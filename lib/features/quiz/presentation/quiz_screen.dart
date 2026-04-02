import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/question_models.dart';
import 'quiz_controller.dart';

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
    with WidgetsBindingObserver {
  static const double _nextButtonAreaHeight = 56;
  static const double _optionSlotHeight = 66;
  static const double _optionsGridHeight = 148;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(
        ref
            .read(quizControllerProvider(widget.chapterId).notifier)
            .persistSnapshot(),
      );
    }
  }

  Future<void> _handleBack() async {
    await ref
        .read(quizControllerProvider(widget.chapterId).notifier)
        .clearSnapshot();
    widget.onBack();
  }

  Widget _buildCountdownCircle(int remainingMillis) {
    final progress = remainingMillis / QuizController.countdownDurationMs;
    final seconds = (remainingMillis / 1000).ceil().clamp(0, 3);
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
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<QuizRunState>(quizControllerProvider(widget.chapterId), (
      previous,
      next,
    ) {
      if (previous?.completedResult == null && next.completedResult != null) {
        widget.onFinish(next.completedResult!);
      }
    });

    final strings = AppStrings.of(context);
    final controller = ref.read(
      quizControllerProvider(widget.chapterId).notifier,
    );
    final runState = ref.watch(quizControllerProvider(widget.chapterId));
    final questions = runState.questions;
    final currentQuestion = runState.currentQuestion;
    if (runState.isLoading || currentQuestion == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final prompt = currentQuestion.rightExpression == null
        ? currentQuestion.prompt
        : '${currentQuestion.prompt} ? ${currentQuestion.rightExpression}';
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
                child: Row(
                  children: [
                    const Icon(
                      Icons.ad_units_rounded,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        strings.t('quizAdBannerPlaceholder'),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
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
                      final current = index == runState.currentIndex;
                      final answer = runState.answers[questions[index].id];
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
                    key: ValueKey('question_${runState.currentIndex}'),
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
                          final option = index < currentQuestion.options.length
                              ? currentQuestion.options[index]
                              : null;
                          final isSelected =
                              option != null &&
                              runState.selectedAnswer == option;
                          final isCorrect =
                              option != null &&
                              option == currentQuestion.correctAnswer;
                          Color? background;
                          if (runState.isLocked && isSelected) {
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
                                        'option_placeholder_${runState.currentIndex}_$index',
                                      ),
                                    )
                                  : AnimatedScale(
                                      key: ValueKey(
                                        'option_slot_${runState.currentIndex}_$index',
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
                                          onPressed: runState.isLocked
                                              ? () {}
                                              : () => unawaited(
                                                  controller.selectAnswer(
                                                    option,
                                                  ),
                                                ),
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
                  ignoring: !runState.isLocked,
                  child: AnimatedOpacity(
                    opacity: runState.isLocked ? 1 : 0,
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    child: FilledButton(
                      onPressed: () => unawaited(controller.nextOrFinish()),
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
                          _buildCountdownCircle(runState.remainingMillis),
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

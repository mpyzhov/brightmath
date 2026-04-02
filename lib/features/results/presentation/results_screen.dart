import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../quiz/domain/question_models.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({
    super.key,
    required this.result,
    required this.showSkipHard,
    required this.onRerun,
    required this.onTrail,
    required this.onHome,
    required this.onNextChapter,
    required this.onSkipHard,
  });

  final QuizRunResult result;
  final bool showSkipHard;
  final VoidCallback onRerun;
  final VoidCallback onTrail;
  final VoidCallback onHome;
  final VoidCallback onNextChapter;
  final VoidCallback onSkipHard;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final hasIncorrect = result.correctCount < result.totalCount;
    return Scaffold(
      appBar: AppBar(title: Text(strings.t('results'))),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.emoji_events_rounded,
                        color: AppTheme.gold,
                      ),
                      const SizedBox(height: 6),
                      Text(strings.t('score')),
                      const SizedBox(height: 8),
                      Text(
                        '${result.correctCount} / ${result.totalCount}',
                        style: Theme.of(
                          context,
                        ).textTheme.headlineMedium?.copyWith(fontSize: 48),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        strings.t('questionsCorrect'),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          3,
                          (index) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.8, end: 1),
                              duration: Duration(
                                milliseconds: 250 + (index * 150),
                              ),
                              curve: Curves.easeOutBack,
                              builder: (context, value, child) {
                                return Transform.scale(
                                  scale: value,
                                  child: child,
                                );
                              },
                              child: Icon(
                                Icons.star_rounded,
                                size: 44,
                                color: index < result.starsEarned
                                    ? AppTheme.gold
                                    : Colors.grey.shade400,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (result.starsEarned >= 1)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.teal,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: onNextChapter,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(strings.t('nextChapter')),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
                  ),
                ),
              if (showSkipHard) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonal(
                    onPressed: onSkipHard,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.fast_forward_rounded, size: 18),
                        const SizedBox(width: 8),
                        Text(strings.t('skipHardChapter')),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onTrail,
                      icon: const Icon(Icons.map_rounded, size: 18),
                      label: Text(strings.t('chapterTrail')),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onHome,
                      icon: const Icon(Icons.home_rounded, size: 18),
                      label: Text(strings.t('home')),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onRerun,
                  icon: const Icon(Icons.replay_rounded, size: 18),
                  label: Text(strings.t('rerunChapter')),
                ),
              ),
              const SizedBox(height: 10),
              if (hasIncorrect)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonal(
                    onPressed: null,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(strings.t('correctResults')),
                        const SizedBox(width: 8),
                        const Icon(Icons.lock_rounded, size: 16),
                      ],
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

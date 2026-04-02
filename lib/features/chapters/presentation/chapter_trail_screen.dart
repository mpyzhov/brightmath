import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/chapter_models.dart';
import 'chapters_controller.dart';

class ChapterTrailScreen extends ConsumerWidget {
  const ChapterTrailScreen({
    super.key,
    required this.onOpenChapter,
    required this.onBack,
  });

  final void Function(ChapterView chapter) onOpenChapter;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final chaptersState = ref.watch(chaptersListProvider);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(strings.t('chapterTrail')),
      ),
      body: chaptersState.when(
        data: (chapters) => ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          itemBuilder: (context, index) {
            final chapter = chapters[index];
            final progress = chapter.progress;
            final locked = !progress.isUnlocked;
            final skipped = progress.isSkipped && !progress.isCompleted;
            final difficulty = chapter.definition.difficulty.name.toUpperCase();
            final cardColor = skipped ? const Color(0xFFF1F3F6) : Colors.white;
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.92, end: 1),
              duration: Duration(milliseconds: 180 + (index * 35)),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, (1 - value) * 14),
                    child: child,
                  ),
                );
              },
              child: Card(
                color: cardColor,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: locked ? null : () => onOpenChapter(chapter),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Column(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: locked
                                  ? Colors.grey.shade300
                                  : (skipped
                                        ? const Color(0xFFB7C0CB)
                                        : AppTheme.teal),
                              child: locked
                                  ? const Icon(Icons.lock_rounded)
                                  : (skipped
                                        ? const Icon(
                                            Icons.fast_forward_rounded,
                                            color: Colors.white,
                                          )
                                        : Text(
                                            '${chapter.definition.orderIndex}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          )),
                            ),
                            if (index < chapters.length - 1)
                              Container(
                                width: 4,
                                height: 24,
                                margin: const EdgeInsets.only(top: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFCFE3E8),
                                  borderRadius: BorderRadius.circular(99),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                chapter.definition.titleKey,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          chapter.definition.difficulty ==
                                              ChapterDifficulty.easy
                                          ? const Color(0xFFE7F8EE)
                                          : (chapter.definition.difficulty ==
                                                    ChapterDifficulty.medium
                                                ? const Color(0xFFEAF4FF)
                                                : const Color(0xFFFFEFEA)),
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                    child: Text(
                                      difficulty,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  if (skipped) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFD7DDE5),
                                        borderRadius: BorderRadius.circular(99),
                                      ),
                                      child: const Text(
                                        'SKIPPED',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF4C5A69),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                chapter.definition.descriptionKey,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: List.generate(
                                  3,
                                  (star) => Padding(
                                    padding: const EdgeInsets.only(right: 2),
                                    child: Icon(
                                      Icons.star_rounded,
                                      size: 18,
                                      color: star < progress.bestStars
                                          ? AppTheme.gold
                                          : Colors.grey.shade400,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          locked
                              ? Icons.lock_rounded
                              : (skipped
                                    ? Icons.fast_forward_rounded
                                    : Icons.play_circle_fill_rounded),
                          color: locked
                              ? Colors.grey
                              : (skipped
                                    ? const Color(0xFF6E7B88)
                                    : AppTheme.navy),
                          size: 28,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemCount: chapters.length,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}

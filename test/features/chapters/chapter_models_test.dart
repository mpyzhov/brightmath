import 'package:brightmath/features/chapters/domain/chapter_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('chapter definitions cover every topic in easy-medium-hard order', () {
    expect(chapterDefinitions, hasLength(60));

    final grouped = <String, List<ChapterDefinition>>{};
    for (final chapter in chapterDefinitions) {
      grouped
          .putIfAbsent(chapter.topicCode, () => <ChapterDefinition>[])
          .add(chapter);
    }

    expect(grouped, hasLength(20));

    for (final entry in grouped.entries) {
      final chapters = entry.value;
      expect(
        chapters,
        hasLength(3),
        reason: 'Topic ${entry.key} should have 3 chapters',
      );
      expect(
        chapters.map((chapter) => chapter.difficulty).toList(),
        [
          ChapterDifficulty.easy,
          ChapterDifficulty.medium,
          ChapterDifficulty.hard,
        ],
        reason: 'Topic ${entry.key} should stay ordered easy -> medium -> hard',
      );
    }
  });

  test('chapter ids and order indexes stay consecutive', () {
    for (var index = 0; index < chapterDefinitions.length; index++) {
      final expected = index + 1;
      final chapter = chapterDefinitions[index];

      expect(chapter.id, expected);
      expect(chapter.orderIndex, expected);
    }
  });
}

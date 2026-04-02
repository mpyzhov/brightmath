import 'package:flutter/material.dart';

enum QuizMode { multipleChoice, comparison }

enum ChapterDifficulty { easy, medium, hard }

enum ChapterKind {
  additionWhole,
  subtractionWhole,
  multiplicationWhole,
  divisionWhole,
  compareWholeFractions,
  additionFractions,
  subtractionFractions,
  multiplicationFractions,
  fractionConvertCompare,
  fractionSimplify,
  compareOperations,
  percentage,
  power,
  squareRoot,
  parenthesis,
  nestedParenthesis,
  compareParenthesis,
  mixedBasic,
  mixedAdvanced,
  mixedFinal,
}

@immutable
class ChapterDefinition {
  const ChapterDefinition({
    required this.id,
    required this.orderIndex,
    required this.topicCode,
    required this.difficulty,
    required this.titleKey,
    required this.descriptionKey,
    required this.kind,
    required this.quizMode,
  });

  final int id;
  final int orderIndex;
  final String topicCode;
  final ChapterDifficulty difficulty;
  final String titleKey;
  final String descriptionKey;
  final ChapterKind kind;
  final QuizMode quizMode;
}

@immutable
class ChapterProgress {
  const ChapterProgress({
    required this.chapterId,
    required this.isUnlocked,
    required this.isCompleted,
    required this.isSkipped,
    required this.bestScore,
    required this.bestStars,
  });

  final int chapterId;
  final bool isUnlocked;
  final bool isCompleted;
  final bool isSkipped;
  final int bestScore;
  final int bestStars;
}

@immutable
class ChapterView {
  const ChapterView({required this.definition, required this.progress});

  final ChapterDefinition definition;
  final ChapterProgress progress;
}

class _TopicSpec {
  const _TopicSpec({
    required this.code,
    required this.baseTitle,
    required this.baseDescription,
    required this.kind,
    required this.quizMode,
  });

  final String code;
  final String baseTitle;
  final String baseDescription;
  final ChapterKind kind;
  final QuizMode quizMode;
}

const _topicSpecs = <_TopicSpec>[
  _TopicSpec(
    code: 'add_whole',
    baseTitle: 'Addition',
    baseDescription: 'Train whole-number addition speed and accuracy.',
    kind: ChapterKind.additionWhole,
    quizMode: QuizMode.multipleChoice,
  ),
  _TopicSpec(
    code: 'sub_whole',
    baseTitle: 'Subtraction',
    baseDescription: 'Build whole-number subtraction confidence.',
    kind: ChapterKind.subtractionWhole,
    quizMode: QuizMode.multipleChoice,
  ),
  _TopicSpec(
    code: 'mul_whole',
    baseTitle: 'Multiplication',
    baseDescription: 'Practice multiplication fluency.',
    kind: ChapterKind.multiplicationWhole,
    quizMode: QuizMode.multipleChoice,
  ),
  _TopicSpec(
    code: 'div_whole',
    baseTitle: 'Division',
    baseDescription: 'Solve whole-number division questions.',
    kind: ChapterKind.divisionWhole,
    quizMode: QuizMode.multipleChoice,
  ),
  _TopicSpec(
    code: 'compare_whole_frac',
    baseTitle: 'Compare Numbers',
    baseDescription: 'Choose >, <, or = for whole/fraction values.',
    kind: ChapterKind.compareWholeFractions,
    quizMode: QuizMode.comparison,
  ),
  _TopicSpec(
    code: 'add_frac',
    baseTitle: 'Fraction Addition',
    baseDescription: 'Add fractions with different denominators.',
    kind: ChapterKind.additionFractions,
    quizMode: QuizMode.multipleChoice,
  ),
  _TopicSpec(
    code: 'sub_frac',
    baseTitle: 'Fraction Subtraction',
    baseDescription: 'Subtract fractions accurately.',
    kind: ChapterKind.subtractionFractions,
    quizMode: QuizMode.multipleChoice,
  ),
  _TopicSpec(
    code: 'mul_frac',
    baseTitle: 'Fraction Multiplication',
    baseDescription: 'Multiply fractions and simplify.',
    kind: ChapterKind.multiplicationFractions,
    quizMode: QuizMode.multipleChoice,
  ),
  _TopicSpec(
    code: 'frac_convert',
    baseTitle: 'Fraction Convert/Compare',
    baseDescription: 'Convert and compare mixed/improper fractions.',
    kind: ChapterKind.fractionConvertCompare,
    quizMode: QuizMode.multipleChoice,
  ),
  _TopicSpec(
    code: 'frac_simplify',
    baseTitle: 'Fraction Simplification',
    baseDescription: 'Reduce fractions to lowest terms.',
    kind: ChapterKind.fractionSimplify,
    quizMode: QuizMode.multipleChoice,
  ),
  _TopicSpec(
    code: 'compare_ops',
    baseTitle: 'Compare Operations',
    baseDescription: 'Compare operation-based expressions.',
    kind: ChapterKind.compareOperations,
    quizMode: QuizMode.comparison,
  ),
  _TopicSpec(
    code: 'percent',
    baseTitle: 'Percentages',
    baseDescription: 'Compute percentage expressions.',
    kind: ChapterKind.percentage,
    quizMode: QuizMode.multipleChoice,
  ),
  _TopicSpec(
    code: 'power',
    baseTitle: 'Powers',
    baseDescription: 'Evaluate powers of numbers.',
    kind: ChapterKind.power,
    quizMode: QuizMode.multipleChoice,
  ),
  _TopicSpec(
    code: 'sqrt',
    baseTitle: 'Square Roots',
    baseDescription: 'Solve square-root questions.',
    kind: ChapterKind.squareRoot,
    quizMode: QuizMode.multipleChoice,
  ),
  _TopicSpec(
    code: 'paren',
    baseTitle: 'Parenthesis Basics',
    baseDescription: 'Solve expressions with parentheses.',
    kind: ChapterKind.parenthesis,
    quizMode: QuizMode.multipleChoice,
  ),
  _TopicSpec(
    code: 'nested_paren',
    baseTitle: 'Nested Parentheses',
    baseDescription: 'Use order of operations in nested forms.',
    kind: ChapterKind.nestedParenthesis,
    quizMode: QuizMode.multipleChoice,
  ),
  _TopicSpec(
    code: 'compare_paren',
    baseTitle: 'Compare Parentheses',
    baseDescription: 'Compare parenthesized expressions.',
    kind: ChapterKind.compareParenthesis,
    quizMode: QuizMode.comparison,
  ),
  _TopicSpec(
    code: 'mixed_1',
    baseTitle: 'Mixed I',
    baseDescription: 'Mixed questions from introduced topics.',
    kind: ChapterKind.mixedBasic,
    quizMode: QuizMode.multipleChoice,
  ),
  _TopicSpec(
    code: 'mixed_2',
    baseTitle: 'Mixed II',
    baseDescription: 'Harder mixed-topic questions.',
    kind: ChapterKind.mixedAdvanced,
    quizMode: QuizMode.multipleChoice,
  ),
  _TopicSpec(
    code: 'mixed_final',
    baseTitle: 'Mixed Final',
    baseDescription: 'Final mixed challenge chapter.',
    kind: ChapterKind.mixedFinal,
    quizMode: QuizMode.multipleChoice,
  ),
];

final chapterDefinitions = _buildChapterDefinitions();

List<ChapterDefinition> _buildChapterDefinitions() {
  final chapters = <ChapterDefinition>[];
  var id = 1;
  for (final topic in _topicSpecs) {
    for (final difficulty in ChapterDifficulty.values) {
      chapters.add(
        ChapterDefinition(
          id: id,
          orderIndex: id,
          topicCode: topic.code,
          difficulty: difficulty,
          titleKey: topic.baseTitle,
          descriptionKey: topic.baseDescription,
          kind: topic.kind,
          quizMode: topic.quizMode,
        ),
      );
      id++;
    }
  }
  return chapters;
}

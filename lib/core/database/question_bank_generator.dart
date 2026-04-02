import 'dart:math';

import '../../features/chapters/domain/chapter_models.dart';

class GeneratedQuestion {
  const GeneratedQuestion({
    required this.prompt,
    required this.rightExpression,
    required this.correctAnswer,
    required this.options,
  });

  final String prompt;
  final String? rightExpression;
  final String correctAnswer;
  final List<String> options;
}

class QuestionBankGenerator {
  List<GeneratedQuestion> generateQuestions(
    ChapterDefinition chapter,
    int count,
  ) {
    final questions = <GeneratedQuestion>[];
    for (var i = 0; i < count; i++) {
      final rng = Random(chapter.id * 5000 + i * 11);
      var generated = generateQuestion(chapter, rng);
      var guard = 0;
      while (isZeroZeroQuestion(generated.prompt, generated.rightExpression) &&
          guard < 10) {
        generated = generateQuestion(chapter, rng);
        guard++;
      }
      questions.add(generated);
    }
    return questions;
  }

  GeneratedQuestion generateQuestion(ChapterDefinition chapter, Random rng) {
    return _generateForKind(chapter.kind, chapter.difficulty, rng);
  }

  bool isZeroZeroQuestion(String prompt, String? rightExpr) {
    if (rightExpr != null) {
      final leftValue = _eval(prompt);
      final rightValue = _eval(rightExpr);
      return leftValue == 0 && rightValue == 0;
    }
    final numbers = RegExp(r'-?\d+')
        .allMatches(prompt)
        .map((m) => int.parse(m.group(0)!))
        .toList(growable: false);
    if (numbers.length < 2) {
      return false;
    }
    return numbers.every((n) => n == 0);
  }

  bool hasNegativeSubtractionSecondArgument(String prompt) {
    final match = RegExp(r'^\s*-?\d+\s-\s(-?\d+)\s*$').firstMatch(prompt);
    if (match == null) {
      return false;
    }
    final second = int.tryParse(match.group(1)!);
    return second != null && second < 0;
  }

  GeneratedQuestion _generateForKind(
    ChapterKind kind,
    ChapterDifficulty difficulty,
    Random rng,
  ) {
    switch (kind) {
      case ChapterKind.additionWhole:
        final pair = _nonZeroPair(
          rng,
          _minForDifficulty(difficulty),
          _spanForDifficulty(difficulty),
        );
        final a = pair.$1;
        final b = pair.$2;
        return _mc('$a + $b', (a + b).toString(), rng);
      case ChapterKind.subtractionWhole:
        final (a, b) = _subtractionWholePair(difficulty, rng);
        return _mc('$a - $b', (a - b).toString(), rng);
      case ChapterKind.multiplicationWhole:
        final pair = _nonZeroPair(
          rng,
          _mulMinForDifficulty(difficulty),
          _mulSpanForDifficulty(difficulty),
        );
        final a = pair.$1;
        final b = pair.$2;
        return _mc('$a × $b', (a * b).toString(), rng);
      case ChapterKind.divisionWhole:
        if (rng.nextInt(10) < 7) {
          final b = _divisorForDifficulty(difficulty, rng);
          final q = _quotientForDifficulty(difficulty, rng);
          final a = b * q;
          return _mc('$a ÷ $b', q.toString(), rng);
        }
        final b = _divisorForDifficulty(difficulty, rng);
        final a =
            rng.nextInt(_spanForDifficulty(difficulty)) +
            _minForDifficulty(difficulty);
        final value = (a / b);
        return _mc(
          '$a ÷ $b',
          value.toStringAsFixed(value.abs() >= 10 ? 1 : 2),
          rng,
        );
      case ChapterKind.compareWholeFractions:
        if (rng.nextBool()) {
          final pair = _nonZeroPair(
            rng,
            _minForDifficulty(difficulty),
            _spanForDifficulty(difficulty),
          );
          final left = pair.$1;
          final right = pair.$2;
          return _compare('$left', '$right');
        }
        final a = rng.nextInt(_fractionMaxForDifficulty(difficulty)) + 1;
        final b = rng.nextInt(_fractionMaxForDifficulty(difficulty)) + 2;
        final c = rng.nextInt(_fractionMaxForDifficulty(difficulty)) + 1;
        final d = rng.nextInt(_fractionMaxForDifficulty(difficulty)) + 2;
        return _compare('$a/$b', '$c/$d');
      case ChapterKind.additionFractions:
        return _fractionOp(rng, '+', difficulty);
      case ChapterKind.subtractionFractions:
        return _fractionOp(rng, '-', difficulty);
      case ChapterKind.multiplicationFractions:
        return _fractionMultiply(rng, difficulty);
      case ChapterKind.fractionConvertCompare:
        final maxNum = difficulty == ChapterDifficulty.easy
            ? 20
            : (difficulty == ChapterDifficulty.medium ? 71 : 500);
        final numerator = rng.nextInt(maxNum) + 5;
        final denominator =
            rng.nextInt(_fractionMaxForDifficulty(difficulty)) + 2;
        final whole = numerator ~/ denominator;
        final rem = numerator % denominator;
        final correct = rem == 0 ? '$whole' : '$whole $rem/$denominator';
        return _mc(
          'Convert $numerator/$denominator to mixed form',
          correct,
          rng,
        );
      case ChapterKind.fractionSimplify:
        final g = rng.nextInt(_fractionMaxForDifficulty(difficulty)) + 2;
        final n = (rng.nextInt(_fractionMaxForDifficulty(difficulty)) + 1) * g;
        final d = (rng.nextInt(_fractionMaxForDifficulty(difficulty)) + 1) * g;
        final reduced = _reduceFraction(n, d);
        return _mc('Simplify $n/$d', reduced, rng);
      case ChapterKind.compareOperations:
        var l1 =
            rng.nextInt(_spanForDifficulty(difficulty)) +
            _minForDifficulty(difficulty);
        var l2 =
            rng.nextInt(_spanForDifficulty(difficulty)) +
            _minForDifficulty(difficulty);
        var r1 =
            rng.nextInt(_spanForDifficulty(difficulty)) +
            _minForDifficulty(difficulty);
        var r2 =
            rng.nextInt(_spanForDifficulty(difficulty)) +
            _minForDifficulty(difficulty);
        var guard = 0;
        while ((l1 + l2 == 0 && r1 + r2 == 0) && guard < 10) {
          l1 =
              rng.nextInt(_spanForDifficulty(difficulty)) +
              _minForDifficulty(difficulty);
          l2 =
              rng.nextInt(_spanForDifficulty(difficulty)) +
              _minForDifficulty(difficulty);
          r1 =
              rng.nextInt(_spanForDifficulty(difficulty)) +
              _minForDifficulty(difficulty);
          r2 =
              rng.nextInt(_spanForDifficulty(difficulty)) +
              _minForDifficulty(difficulty);
          guard++;
        }
        return _compare('$l1 + $l2', '$r1 + $r2');
      case ChapterKind.percentage:
        final percent = (rng.nextInt(19) + 1) * 5;
        final value =
            ((rng.nextInt(
                      difficulty == ChapterDifficulty.easy
                          ? 20
                          : (difficulty == ChapterDifficulty.medium ? 71 : 500),
                    ) +
                    1) ~/
                5) *
            5;
        final answer = (percent / 100 * value);
        final display = answer == answer.roundToDouble()
            ? answer.toInt().toString()
            : answer.toStringAsFixed(1);
        return _mc('$percent% of $value', display, rng);
      case ChapterKind.power:
        final base = difficulty == ChapterDifficulty.easy
            ? rng.nextInt(7) + 2
            : (difficulty == ChapterDifficulty.medium
                  ? rng.nextInt(12) + 2
                  : rng.nextInt(22) - 10);
        final exp = difficulty == ChapterDifficulty.hard
            ? rng.nextInt(4) + 2
            : rng.nextInt(3) + 2;
        return _mc('$base^$exp', pow(base, exp).toInt().toString(), rng);
      case ChapterKind.squareRoot:
        final root = difficulty == ChapterDifficulty.easy
            ? rng.nextInt(12) + 1
            : (difficulty == ChapterDifficulty.medium
                  ? rng.nextInt(25) + 1
                  : rng.nextInt(70) + 1);
        final square = root * root;
        return _mc('√$square', root.toString(), rng);
      case ChapterKind.parenthesis:
        final a =
            rng.nextInt(_spanForDifficulty(difficulty)) +
            _minForDifficulty(difficulty);
        final b =
            rng.nextInt(_spanForDifficulty(difficulty)) +
            _minForDifficulty(difficulty);
        final c =
            rng.nextInt(difficulty == ChapterDifficulty.hard ? 80 : 20) +
            (difficulty == ChapterDifficulty.hard ? -20 : 1);
        return _mc('($a + $b) × $c', ((a + b) * c).toString(), rng);
      case ChapterKind.nestedParenthesis:
        final a =
            rng.nextInt(_spanForDifficulty(difficulty)) +
            _minForDifficulty(difficulty);
        final b =
            rng.nextInt(_spanForDifficulty(difficulty)) +
            _minForDifficulty(difficulty);
        final c =
            rng.nextInt(difficulty == ChapterDifficulty.hard ? 80 : 16) +
            (difficulty == ChapterDifficulty.hard ? -20 : 2);
        final d =
            rng.nextInt(_spanForDifficulty(difficulty)) +
            _minForDifficulty(difficulty);
        return _mc(
          '(($a + $b) × $c) - $d',
          (((a + b) * c) - d).toString(),
          rng,
        );
      case ChapterKind.compareParenthesis:
        final a =
            rng.nextInt(_spanForDifficulty(difficulty)) +
            _minForDifficulty(difficulty);
        final b =
            rng.nextInt(_spanForDifficulty(difficulty)) +
            _minForDifficulty(difficulty);
        final c =
            rng.nextInt(_spanForDifficulty(difficulty)) +
            _minForDifficulty(difficulty);
        final d =
            rng.nextInt(_spanForDifficulty(difficulty)) +
            _minForDifficulty(difficulty);
        return _compare('($a + $b) × 2', '($c + $d) × 2');
      case ChapterKind.mixedBasic:
      case ChapterKind.mixedAdvanced:
      case ChapterKind.mixedFinal:
        final pool = ChapterKind.values
            .where((k) {
              return k.index < kind.index &&
                  k != ChapterKind.compareWholeFractions &&
                  k != ChapterKind.compareOperations &&
                  k != ChapterKind.compareParenthesis;
            })
            .toList(growable: false);
        final chosen = pool[rng.nextInt(pool.length)];
        return _generateForKind(chosen, difficulty, rng);
    }
  }

  GeneratedQuestion _mc(String prompt, String correct, Random rng) {
    final options = <String>{correct};
    while (options.length < 4) {
      final delta = rng.nextInt(9) - 4;
      final value = int.tryParse(correct);
      if (value != null) {
        options.add((value + delta).toString());
      } else {
        options.add('$correct${rng.nextInt(4) + 1}');
      }
    }
    final optionList = options.toList()..shuffle(rng);
    return GeneratedQuestion(
      prompt: prompt,
      rightExpression: null,
      correctAnswer: correct,
      options: optionList,
    );
  }

  GeneratedQuestion _compare(String left, String right) {
    final leftValue = _eval(left);
    final rightValue = _eval(right);
    final sign = leftValue == rightValue
        ? '='
        : (leftValue > rightValue ? '>' : '<');
    return GeneratedQuestion(
      prompt: left,
      rightExpression: right,
      correctAnswer: sign,
      options: const ['>', '<', '='],
    );
  }

  (int, int) _easyPositiveSubtractionPair(Random rng) {
    final a = rng.nextInt(20) + 1;
    final b = rng.nextInt(a);
    return (a, b);
  }

  (int, int) _subtractionWholePair(ChapterDifficulty difficulty, Random rng) {
    if (difficulty == ChapterDifficulty.easy) {
      return _easyPositiveSubtractionPair(rng);
    }
    final a =
        rng.nextInt(_spanForDifficulty(difficulty)) +
        _minForDifficulty(difficulty);
    final secondMax = difficulty == ChapterDifficulty.medium ? 71 : 500;
    final b = rng.nextInt(secondMax + 1);
    if (a == 0 && b == 0) {
      return _subtractionWholePair(difficulty, rng);
    }
    return (a, b);
  }

  (int, int) _nonZeroPair(
    Random rng,
    int min,
    int span, {
    int? secondMin,
    int? secondSpan,
  }) {
    var a = rng.nextInt(span) + min;
    var b = rng.nextInt(secondSpan ?? span) + (secondMin ?? min);
    var guard = 0;
    while (a == 0 && b == 0 && guard < 10) {
      a = rng.nextInt(span) + min;
      b = rng.nextInt(secondSpan ?? span) + (secondMin ?? min);
      guard++;
    }
    return (a, b);
  }

  GeneratedQuestion _fractionOp(
    Random rng,
    String op,
    ChapterDifficulty difficulty,
  ) {
    final max = _fractionMaxForDifficulty(difficulty);
    final a = rng.nextInt(max) + 1;
    final b = rng.nextInt(max) + 2;
    final c = rng.nextInt(max) + 1;
    final d = rng.nextInt(max) + 2;
    final numerator = op == '+' ? (a * d + c * b) : (a * d - c * b);
    final denominator = b * d;
    final reduced = _reduceFraction(numerator, denominator);
    return _mc('$a/$b $op $c/$d', reduced, rng);
  }

  GeneratedQuestion _fractionMultiply(
    Random rng,
    ChapterDifficulty difficulty,
  ) {
    final max = _fractionMaxForDifficulty(difficulty);
    final a = rng.nextInt(max) + 1;
    final b = rng.nextInt(max) + 2;
    final c = rng.nextInt(max) + 1;
    final d = rng.nextInt(max) + 2;
    final reduced = _reduceFraction(a * c, b * d);
    return _mc('$a/$b × $c/$d', reduced, rng);
  }

  int _minForDifficulty(ChapterDifficulty difficulty) {
    switch (difficulty) {
      case ChapterDifficulty.easy:
        return 0;
      case ChapterDifficulty.medium:
        return 0;
      case ChapterDifficulty.hard:
        return -500;
    }
  }

  int _spanForDifficulty(ChapterDifficulty difficulty) {
    switch (difficulty) {
      case ChapterDifficulty.easy:
        return 21;
      case ChapterDifficulty.medium:
        return 72;
      case ChapterDifficulty.hard:
        return 1001;
    }
  }

  int _mulMinForDifficulty(ChapterDifficulty difficulty) {
    switch (difficulty) {
      case ChapterDifficulty.easy:
        return 0;
      case ChapterDifficulty.medium:
        return 0;
      case ChapterDifficulty.hard:
        return -50;
    }
  }

  int _mulSpanForDifficulty(ChapterDifficulty difficulty) {
    switch (difficulty) {
      case ChapterDifficulty.easy:
        return 13;
      case ChapterDifficulty.medium:
        return 32;
      case ChapterDifficulty.hard:
        return 101;
    }
  }

  int _fractionMaxForDifficulty(ChapterDifficulty difficulty) {
    switch (difficulty) {
      case ChapterDifficulty.easy:
        return 9;
      case ChapterDifficulty.medium:
        return 20;
      case ChapterDifficulty.hard:
        return 50;
    }
  }

  int _divisorForDifficulty(ChapterDifficulty difficulty, Random rng) {
    switch (difficulty) {
      case ChapterDifficulty.easy:
        return rng.nextInt(8) + 2;
      case ChapterDifficulty.medium:
        return rng.nextInt(15) + 2;
      case ChapterDifficulty.hard:
        return rng.nextInt(30) + 2;
    }
  }

  int _quotientForDifficulty(ChapterDifficulty difficulty, Random rng) {
    switch (difficulty) {
      case ChapterDifficulty.easy:
        return rng.nextInt(21);
      case ChapterDifficulty.medium:
        return rng.nextInt(72);
      case ChapterDifficulty.hard:
        return rng.nextInt(1001) - 500;
    }
  }

  String _reduceFraction(int n, int d) {
    if (n == 0) {
      return '0';
    }
    final sign = n * d < 0 ? '-' : '';
    final nn = n.abs();
    final dd = d.abs();
    final g = _gcd(nn, dd);
    final rn = nn ~/ g;
    final rd = dd ~/ g;
    if (rd == 1) {
      return '$sign$rn';
    }
    return '$sign$rn/$rd';
  }

  int _gcd(int a, int b) {
    var x = a;
    var y = b;
    while (y != 0) {
      final t = x % y;
      x = y;
      y = t;
    }
    return x;
  }

  double _eval(String expr) {
    if (expr.contains('/')) {
      final parts = expr.split('/');
      if (parts.length == 2) {
        return int.parse(parts[0]) / int.parse(parts[1]);
      }
    }
    if (expr.contains('+')) {
      final parts = expr.split('+');
      return parts.map((e) => _eval(e.trim())).reduce((a, b) => a + b);
    }
    if (expr.contains('×')) {
      final parts = expr.split('×');
      return parts.map((e) => _eval(e.trim())).reduce((a, b) => a * b);
    }
    if (expr.contains('÷')) {
      final parts = expr.split('÷');
      return _eval(parts[0].trim()) / _eval(parts[1].trim());
    }
    if (expr.contains('^')) {
      final parts = expr.split('^');
      return pow(_eval(parts[0].trim()), _eval(parts[1].trim())).toDouble();
    }
    return double.parse(expr.replaceAll('(', '').replaceAll(')', '').trim());
  }
}

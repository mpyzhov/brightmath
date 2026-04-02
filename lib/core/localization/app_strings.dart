import 'package:flutter/widgets.dart';

class AppStrings {
  AppStrings(this.locale);

  final Locale locale;

  static const supportedLocales = <Locale>[
    Locale('en'),
    Locale('uk'),
    Locale('es'),
    Locale('pt'),
    Locale('ko'),
    Locale('it'),
    Locale('fr'),
    Locale('de'),
  ];

  static AppStrings of(BuildContext context) {
    final strings = Localizations.of<AppStrings>(context, AppStrings);
    assert(strings != null, 'No AppStrings found in context');
    return strings!;
  }

  static const _localized = <String, Map<String, String>>{
    'en': {
      'appTitle': 'BrightMath',
      'startGame': 'Start Game',
      'settings': 'Settings',
      'completedChapters': 'Completed Chapters',
      'totalStars': 'Total Stars',
      'chapterTrail': 'Chapter Trail',
      'locked': 'Locked',
      'quiz': 'Quiz',
      'next': 'Next',
      'timeLeft': 'Time left',
      'question': 'Question',
      'results': 'Results',
      'score': 'Score',
      'questionsCorrect': 'Questions Correct',
      'rerunChapter': 'Rerun Chapter',
      'home': 'Home',
      'nextChapter': 'Next Chapter',
      'skipHardChapter': 'Skip Hard Chapter',
      'language': 'Language',
      'sound': 'Sound',
      'haptics': 'Haptics',
      'resetProgress': 'Reset Progress',
      'progressReset': 'Progress reset',
      'confirmResetTitle': 'Reset all progress?',
      'confirmResetMessage':
          'All chapter progress, stars, scores, and history will be lost.',
      'cancel': 'Cancel',
      'confirm': 'Reset',
      'correctResults': 'Show Correct Results',
      'quizAdBannerPlaceholder': 'Ad banner • clearly separated',
    },
  };

  String t(String key) {
    final lang = locale.languageCode;
    final selected = _localized[lang] ?? _localized['en']!;
    return selected[key] ?? _localized['en']![key] ?? key;
  }
}

class AppStringsDelegate extends LocalizationsDelegate<AppStrings> {
  const AppStringsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppStrings.supportedLocales.any(
      (supported) => supported.languageCode == locale.languageCode,
    );
  }

  @override
  Future<AppStrings> load(Locale locale) async {
    return AppStrings(locale);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppStrings> old) => false;
}

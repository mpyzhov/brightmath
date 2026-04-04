/// Endonyms for the in-app language picker: each language written in itself.
class LanguageNativeNames {
  LanguageNativeNames._();

  static const Map<String, String> _byCode = {
    'en': 'English',
    'uk': 'Українська',
    'es': 'Español',
    'pt': 'Português',
    'ko': '한국어',
    'it': 'Italiano',
    'fr': 'Français',
    'de': 'Deutsch',
  };

  /// Full native name for [languageCode], or [languageCode] if unknown.
  static String labelFor(String languageCode) =>
      _byCode[languageCode] ?? languageCode;
}

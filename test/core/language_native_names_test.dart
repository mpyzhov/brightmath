import 'package:brightmath/core/localization/language_native_names.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('labelFor returns endonyms for supported codes', () {
    expect(LanguageNativeNames.labelFor('en'), 'English');
    expect(LanguageNativeNames.labelFor('uk'), 'Українська');
    expect(LanguageNativeNames.labelFor('de'), 'Deutsch');
    expect(LanguageNativeNames.labelFor('ko'), '한국어');
  });

  test('labelFor falls back to code for unknown', () {
    expect(LanguageNativeNames.labelFor('xx'), 'xx');
  });
}

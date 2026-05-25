import 'package:brightmath/core/database/database_manifest.dart';
import 'package:brightmath/features/chapters/domain/chapter_models.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'database manifest lists schema and one question seed per chapter',
    () async {
      final manifest = await DatabaseManifest.load();
      final questionScripts = manifest.initialContentScripts
          .where((path) => path.contains('/questions/'))
          .toList(growable: false);

      expect(manifest.databaseVersion, 9);
      expect(manifest.createScripts, [
        'assets/database/migrations/001_initial_schema.sql',
      ]);
      expect(questionScripts, hasLength(chapterDefinitions.length));
      expect(manifest.upgradeScriptsFor(4, 9), [
        'assets/database/migrations/005_static_question_bank.sql',
        'assets/database/migrations/006_refresh_option_pools.sql',
        'assets/database/migrations/007_refresh_easy_non_negative.sql',
        'assets/database/migrations/008_refresh_zero_free_questions.sql',
        'assets/database/migrations/009_refresh_addition_positive_options.sql',
      ]);

      await rootBundle.loadString(manifest.createScripts.single);
      await rootBundle.loadString('assets/database/init/chapters.sql');
      await rootBundle.loadString(questionScripts.first);
      await rootBundle.loadString(questionScripts.last);
    },
  );
}

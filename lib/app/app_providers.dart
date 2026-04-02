import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database/app_database.dart';
import '../features/chapters/data/chapters_repository.dart';
import '../features/settings/data/settings_repository.dart';
import '../features/quiz/data/quiz_repository.dart';
import 'session_store.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) => AppDatabase());

final sessionStoreProvider = Provider<SessionStore>((ref) => SessionStore());

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository();
});

final chaptersRepositoryProvider = Provider<ChaptersRepository>((ref) {
  return ChaptersRepository(ref.read(appDatabaseProvider));
});

final quizRepositoryProvider = Provider<QuizRepository>((ref) {
  return QuizRepository(ref.read(appDatabaseProvider));
});

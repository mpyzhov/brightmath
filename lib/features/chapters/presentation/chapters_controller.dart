import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../settings/presentation/settings_controller.dart';
import '../data/chapters_repository.dart';
import '../domain/chapter_models.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) => AppDatabase());

final chaptersRepositoryProvider = Provider<ChaptersRepository>((ref) {
  return ChaptersRepository(ref.read(appDatabaseProvider));
});

final startStatsProvider = FutureProvider<StartStats>((ref) async {
  ref.watch(settingsControllerProvider);
  return ref.read(chaptersRepositoryProvider).loadStartStats();
});

final chaptersListProvider = FutureProvider<List<ChapterView>>((ref) async {
  ref.watch(settingsControllerProvider);
  return ref.read(chaptersRepositoryProvider).loadChapterViews();
});

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_providers.dart';
import '../../../core/database/chapters_dao.dart';
import '../../settings/presentation/settings_controller.dart';
import '../domain/chapter_models.dart';

final startStatsProvider = FutureProvider<StartStats>((ref) async {
  ref.watch(settingsControllerProvider);
  return ref.read(chaptersRepositoryProvider).loadStartStats();
});

final chaptersListProvider = FutureProvider<List<ChapterView>>((ref) async {
  ref.watch(settingsControllerProvider);
  return ref.read(chaptersRepositoryProvider).loadChapterViews();
});

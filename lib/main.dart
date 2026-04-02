import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/localization/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'features/chapters/domain/chapter_models.dart';
import 'features/chapters/presentation/chapter_trail_screen.dart';
import 'features/chapters/presentation/chapters_controller.dart';
import 'features/chapters/presentation/start_screen.dart';
import 'features/quiz/domain/question_models.dart';
import 'features/quiz/presentation/quiz_screen.dart';
import 'features/results/presentation/results_screen.dart';
import 'features/settings/presentation/settings_controller.dart';
import 'features/settings/presentation/settings_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const ProviderScope(child: BrightMathApp()));
}

class BrightMathApp extends ConsumerWidget {
  const BrightMathApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final localeCode = settings.asData?.value.languageCode ?? 'en';

    return MaterialApp(
      title: 'BrightMath',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(),
      locale: Locale(localeCode),
      localizationsDelegates: const [
        AppStringsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppStrings.supportedLocales,
      home: const RootFlow(),
    );
  }
}

enum RootPage { start, trail, quiz, results, settings }

class RootFlow extends ConsumerStatefulWidget {
  const RootFlow({super.key});

  @override
  ConsumerState<RootFlow> createState() => _RootFlowState();
}

class _RootFlowState extends ConsumerState<RootFlow>
    with WidgetsBindingObserver {
  static const _sessionPageKey = 'root_flow_page';
  static const _sessionChapterIdKey = 'root_flow_chapter_id';

  RootPage _page = RootPage.start;
  ChapterView? _selectedChapter;
  QuizRunResult? _lastResult;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_restoreSession());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(_persistSession());
    }
  }

  void _goToPage(
    RootPage page, {
    ChapterView? chapter,
    QuizRunResult? result,
    bool clearSelectedChapter = false,
  }) {
    setState(() {
      _page = page;
      if (clearSelectedChapter) {
        _selectedChapter = null;
      }
      if (chapter != null) {
        _selectedChapter = chapter;
      }
      _lastResult = result;
    });
    unawaited(_persistSession());
  }

  Future<void> _persistSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_sessionPageKey, _page.index);
    final chapterId = _selectedChapter?.definition.id;
    if (chapterId == null) {
      await prefs.remove(_sessionChapterIdKey);
    } else {
      await prefs.setInt(_sessionChapterIdKey, chapterId);
    }
  }

  Future<void> _restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPageIndex = prefs.getInt(_sessionPageKey);
    final savedChapterId = prefs.getInt(_sessionChapterIdKey);

    if (savedPageIndex == null ||
        savedPageIndex < 0 ||
        savedPageIndex >= RootPage.values.length) {
      return;
    }
    final savedPage = RootPage.values[savedPageIndex];

    // Results depend on ephemeral in-memory state, so restore to trail instead.
    if (savedPage == RootPage.results) {
      if (mounted) {
        _goToPage(RootPage.trail);
      }
      return;
    }

    if (savedPage == RootPage.quiz) {
      if (savedChapterId == null) {
        if (mounted) {
          _goToPage(RootPage.trail);
        }
        return;
      }
      final chapter = await _findChapterById(savedChapterId);
      if (mounted && chapter != null) {
        _goToPage(RootPage.quiz, chapter: chapter);
      } else if (mounted) {
        _goToPage(RootPage.trail);
      }
      return;
    }

    if (mounted) {
      _goToPage(savedPage);
    }
  }

  Future<ChapterView?> _findChapterById(int chapterId) async {
    final chapters = await ref
        .read(chaptersRepositoryProvider)
        .loadChapterViews();
    for (final chapter in chapters) {
      if (chapter.definition.id == chapterId) {
        return chapter;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    switch (_page) {
      case RootPage.start:
        return StartScreen(
          onStart: () => _goToPage(RootPage.trail),
          onSettings: () => _goToPage(RootPage.settings),
        );
      case RootPage.trail:
        return ChapterTrailScreen(
          onBack: () => _goToPage(RootPage.start, clearSelectedChapter: true),
          onOpenChapter: (chapter) =>
              _goToPage(RootPage.quiz, chapter: chapter),
        );
      case RootPage.quiz:
        final chapter = _selectedChapter!;
        return QuizScreen(
          chapterId: chapter.definition.id,
          chapterTitle: chapter.definition.titleKey,
          onBack: () => _goToPage(RootPage.trail),
          onFinish: (result) {
            ref.invalidate(chaptersListProvider);
            ref.invalidate(startStatsProvider);
            _goToPage(RootPage.results, result: result);
          },
        );
      case RootPage.results:
        if (_lastResult == null) {
          return ChapterTrailScreen(
            onBack: () => _goToPage(RootPage.start, clearSelectedChapter: true),
            onOpenChapter: (chapter) =>
                _goToPage(RootPage.quiz, chapter: chapter),
          );
        }
        final result = _lastResult!;
        final isHardChapter =
            _selectedChapter?.definition.difficulty == ChapterDifficulty.hard;
        return ResultsScreen(
          result: result,
          showSkipHard: isHardChapter && result.starsEarned == 0,
          onRerun: () => _goToPage(RootPage.quiz),
          onTrail: () => _goToPage(RootPage.trail),
          onHome: () => _goToPage(RootPage.start, clearSelectedChapter: true),
          onSkipHard: () async {
            final currentId = _selectedChapter!.definition.id;
            await ref.read(appDatabaseProvider).skipHardChapter(currentId);
            ref.invalidate(chaptersListProvider);
            ref.invalidate(startStatsProvider);
            if (mounted) {
              _goToPage(RootPage.trail);
            }
          },
          onNextChapter: () async {
            final currentId = _selectedChapter!.definition.id;
            final nextId = await ref
                .read(appDatabaseProvider)
                .nextChapterId(currentId);
            if (nextId == null) {
              if (mounted) {
                _goToPage(RootPage.trail);
              }
              return;
            }
            final chapters = await ref
                .read(chaptersRepositoryProvider)
                .loadChapterViews();
            final next = chapters.firstWhere((c) => c.definition.id == nextId);
            if (mounted) {
              _goToPage(RootPage.quiz, chapter: next);
            }
          },
        );
      case RootPage.settings:
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              onPressed: () =>
                  _goToPage(RootPage.start, clearSelectedChapter: true),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            title: Text(AppStrings.of(context).t('settings')),
          ),
          body: const SettingsScreen(),
        );
    }
  }
}

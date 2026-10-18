import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/archive/game_archive.dart';
import 'package:rokko/game/game_page.dart';
import 'package:rokko/guide/guide_controller.dart';
import 'package:rokko/guide/guide_host.dart';
import 'package:rokko/home/home_shell.dart';
import 'package:rokko/l10n/app_localizations.dart';
import 'package:rokko/path/path_controller.dart';
import 'package:rokko/progress/progress_controller.dart';
import 'package:rokko/progress/progress_store.dart';
import 'package:rokko/puzzles/puzzle.dart';
import 'package:rokko/puzzles/puzzle_library.dart';
import 'package:rokko/puzzles/puzzle_trainer.dart';
import 'package:rokko/settings/settings.dart';
import 'package:rokko/settings/settings_page.dart';
import 'package:rokko/storage/key_value_store.dart';
import 'package:rokko/story/story_controller.dart';
import 'package:rokko/story/story_page.dart';

Widget _app(GuideController guides, SettingsController settings, Widget home) =>
    MaterialApp(
      locale: const Locale('it'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => SettingsScope(
        controller: settings,
        child: GuideScope(controller: guides, child: child!),
      ),
      home: home,
    );

void main() {
  late Directory dir;
  late ProgressController progress;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('guide_screens');
    progress = ProgressController(ProgressStore(File('${dir.path}/p.json')));
    await progress.load();
  });
  tearDown(() => dir.deleteSync(recursive: true));

  Future<void> phone(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(1179, 2556)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  late PuzzleTrainer trainer;

  setUp(() async {
    trainer = await PuzzleTrainer.load(
      PuzzleLibrary([
        Puzzle.parseCsv(
          'a,7k/6pp/8/8/1n6/8/8/RR4K1 b - - 0 1,b4c2 a1a8,1500,mateIn1',
        ),
      ]),
      MemoryStore(),
    );
  });

  HomeShell shell(SettingsController settings) => HomeShell(
    settings: settings,
    puzzleTrainer: () async => trainer,
    progress: () async => progress,
    path: () async => PathController(File('${dir.path}/path.json')),
    story: () async => StoryController(File('${dir.path}/story.json')),
    archive: () async => GameArchive(File('${dir.path}/games.json')),
    reminderScheduler: () => null,
    computerAvailable: true,
  );

  Finder tab(String label) => find.descendant(
    of: find.byType(NavigationBar),
    matching: find.text(label),
  );

  Future<List<String>> walk(WidgetTester tester) async {
    final texts = <String>[];
    while (find.byKey(const Key('guide-next')).evaluate().isNotEmpty) {
      texts.add(tester.widget<Text>(find.byKey(const Key('guide-text'))).data!);
      await tester.tap(find.byKey(const Key('guide-next')));
      await tester.pumpAndSettle();
    }
    return texts;
  }

  testWidgets('la Home spiega le sue funzioni la prima volta, poi tace', (
    tester,
  ) async {
    await phone(tester);
    final guides = GuideController.memory();
    final settings = SettingsController.defaults();
    await tester.pumpWidget(_app(guides, settings, shell(settings)));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('guide-skip')), findsOneWidget);
    final steps = await walk(tester);
    expect(steps, contains(startsWith('Nelle Impostazioni')));
    expect(steps, contains(startsWith('Cerca una funzione')));
    expect(steps.any((t) => t.startsWith('«Nuova partita»')), isTrue);
    expect(steps.any((t) => t.contains('Home, Puzzle, Impara e Tu')), isTrue);
    expect(guides.isSeen('home'), isTrue);
    // Tornando sulla Home la guida non riparte.
    await tester.tap(tab('Impara'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('guide-skip')));
    await tester.pumpAndSettle();
    await tester.tap(tab('Home'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('guide-skip')), findsNothing);
  });

  testWidgets('ogni scheda ha la sua guida, che parte quando la si apre', (
    tester,
  ) async {
    await phone(tester);
    final guides = GuideController.memory(seen: {'home'});
    final settings = SettingsController.defaults();
    await tester.pumpWidget(_app(guides, settings, shell(settings)));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('guide-skip')), findsNothing);
    for (final (label, id) in [
      ('Puzzle', 'puzzles'),
      ('Impara', 'learn'),
      ('Tu', 'you'),
    ]) {
      await tester.tap(tab(label));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('guide-skip')), findsOneWidget, reason: id);
      await tester.tap(find.byKey(const Key('guide-skip')));
      await tester.pumpAndSettle();
      expect(guides.isSeen(id), isTrue, reason: id);
    }
  });

  testWidgets(
    'nel profilo bambino la Home usa frasi semplici e niente ricerca',
    (tester) async {
      await phone(tester);
      final guides = GuideController.memory();
      final settings = SettingsController.defaults()
        ..value = AppSettings(kidMode: true);
      await tester.pumpWidget(_app(guides, settings, shell(settings)));
      await tester.pumpAndSettle();
      final steps = await walk(tester);
      expect(steps, isNotEmpty);
      expect(steps.any((t) => t.startsWith('Cerca')), isFalse);
      expect(steps, contains('Tocca qui per giocare una nuova partita.'));
    },
  );

  testWidgets('le Impostazioni hanno la guida e il modo di rivederla', (
    tester,
  ) async {
    await phone(tester);
    final guides = GuideController.memory(seen: {'home'});
    final settings = SettingsController.defaults();
    await tester.pumpWidget(
      _app(guides, settings, SettingsPage(controller: settings)),
    );
    await tester.pumpAndSettle();
    final steps = await walk(tester);
    expect(steps.length, greaterThanOrEqualTo(5));
    expect(guides.isSeen('settings'), isTrue);

    await tester.tap(find.byKey(const Key('section-accessibility')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('guideReplay')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.byKey(const Key('guideReplay')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('guideReplay')));
    await tester.pump();
    expect(find.text('Le guide ricompariranno.'), findsOneWidget);
    expect(guides.isSeen('settings'), isFalse);
    expect(guides.isSeen('home'), isFalse);
  });

  testWidgets('l\'interruttore nelle Impostazioni spegne tutte le guide', (
    tester,
  ) async {
    await phone(tester);
    final guides = GuideController.memory(seen: {'settings'});
    final settings = SettingsController.defaults();
    await tester.pumpWidget(
      _app(guides, settings, SettingsPage(controller: settings)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('section-accessibility')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('guideEnabled')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.byKey(const Key('guideEnabled')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('guideEnabled')));
    await tester.pumpAndSettle();
    expect(guides.enabled, isFalse);
  });

  testWidgets('la partita spiega scacchiera e comandi', (tester) async {
    await phone(tester);
    final guides = GuideController.memory();
    final settings = SettingsController.defaults();
    final store = MemoryStore();
    await store.write('gameTips', '99');
    await tester.pumpWidget(
      _app(guides, settings, GamePage(settings: settings, store: store)),
    );
    await tester.pumpAndSettle();
    final steps = await walk(tester);
    expect(steps.any((t) => t.startsWith('Questa è la scacchiera')), isTrue);
    expect(steps.any((t) => t.startsWith('Annulla')), isTrue);
    expect(steps.any((t) => t.startsWith('Abbandona')), isTrue);
    expect(guides.isSeen('game'), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('la scelta della partita ha la sua guida', (tester) async {
    await phone(tester);
    final guides = GuideController.memory(seen: {'game'});
    final settings = SettingsController.defaults();
    final store = MemoryStore();
    await tester.pumpWidget(
      _app(
        guides,
        settings,
        GamePage(
          settings: settings,
          store: store,
          openSetup: true,
          computerAvailable: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final steps = await walk(tester);
    expect(steps.any((t) => t.contains('tempo di gioco')), isTrue);
    expect(steps.any((t) => t.contains('amico')), isTrue);
    expect(guides.isSeen('newGame'), isTrue);
  });

  testWidgets('la Storia spiega il cammino, il capitolo e «Continua»', (
    tester,
  ) async {
    await phone(tester);
    final guides = GuideController.memory();
    final settings = SettingsController.defaults();
    await tester.pumpWidget(
      _app(
        guides,
        settings,
        StoryPage(
          path: PathController(File('${dir.path}/path.json')),
          story: StoryController(File('${dir.path}/story.json')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final steps = await walk(tester);
    expect(steps.length, 3);
    expect(steps.last, contains('Continua'));
    expect(guides.isSeen('story'), isTrue);
  });
}

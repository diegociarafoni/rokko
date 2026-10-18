@Tags(['golden'])
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/archive/game_archive.dart';
import 'package:rokko/guide/guide_controller.dart';
import 'package:rokko/guide/guide_host.dart';
import 'package:rokko/home/home_shell.dart';
import 'package:rokko/l10n/app_localizations.dart';
import 'package:rokko/path/path_controller.dart';
import 'package:rokko/progress/progress_controller.dart';
import 'package:rokko/progress/progress_store.dart';
import 'package:rokko/settings/settings.dart';
import 'package:rokko/story/story_controller.dart';
import 'package:rokko/theme/rokko_theme.dart';

import '../support/devices.dart';

// I riferimenti sono generati su Linux: altrove il rendering dei caratteri differisce.
final _skip = Platform.isLinux ? null : 'riferimenti generati solo su Linux';

void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('golden-guide'));
  tearDown(() => dir.deleteSync(recursive: true));

  /// La Home con la guida aperta; [next] passi avanti dal primo.
  Future<void> home(
    WidgetTester tester,
    Device device, {
    Brightness brightness = Brightness.light,
    bool kid = false,
    double textScale = 1,
    int next = 0,
  }) async {
    device.apply(tester);
    final progress = ProgressController(
      ProgressStore(File('${dir.path}/p.json')),
      clock: () => DateTime(2026, 10, 5, 12),
    );
    await tester.runAsync(progress.load);
    final settings = SettingsController.defaults()
      ..value = AppSettings(kidMode: kid);
    await tester.pumpWidget(
      SettingsScope(
        controller: settings,
        child: MaterialApp(
          theme: brightness == Brightness.dark
              ? RokkoTheme.dark()
              : RokkoTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('it'),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: GuideScope(
              controller: GuideController.memory(),
              child: child!,
            ),
          ),
          home: HomeShell(
            settings: settings,
            computerAvailable: true,
            progress: () async => progress,
            path: () async => PathController(File('${dir.path}/path.json')),
            story: () async => StoryController(File('${dir.path}/story.json')),
            archive: () async => GameArchive(File('${dir.path}/games.json')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    for (var i = 0; i < next; i++) {
      await tester.tap(find.byKey(const Key('guide-next')));
      await tester.pumpAndSettle();
    }
  }

  Future<void> golden(String name) => expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('goldens/$name.png'),
  );

  testWidgets('guida della Home, primo passo', skip: _skip != null, (
    tester,
  ) async {
    await home(tester, Device.phoneMedium);
    await golden('guida-home-telefono-medio');
  });

  testWidgets(
    'guida della Home, pulsante di gioco, tema scuro',
    skip: _skip != null,
    (tester) async {
      await home(
        tester,
        Device.phoneMedium,
        brightness: Brightness.dark,
        next: 5,
      );
      await golden('guida-home-scuro-telefono-medio');
    },
  );

  testWidgets('guida della Home col testo al 130%', skip: _skip != null, (
    tester,
  ) async {
    await home(tester, Device.phoneSmall, textScale: 1.3, next: 2);
    await golden('guida-home-testo-130-telefono-piccolo');
  });

  testWidgets('guida della Home, profilo bambino', skip: _skip != null, (
    tester,
  ) async {
    await home(tester, Device.phoneMedium, kid: true);
    await golden('guida-home-bambino-telefono-medio');
  });
}

import 'package:dartchess/dartchess.dart' show Side;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/archive/saved_game.dart';
import 'package:rokko/engine/computer_player.dart';
import 'package:rokko/game/game_page.dart';
import 'package:rokko/l10n/app_localizations.dart';
import 'package:rokko/progress/activity.dart';
import 'package:rokko/progress/progress_state.dart';
import 'package:rokko/progress/progress_tracker.dart';
import 'package:rokko/settings/settings.dart';

import '../computer_fakes.dart';
import '../game_actions.dart';
import 'game_progress_test.dart' show tapMove;

final _activities = <Activity>[];
final _saved = <SavedGame>[];

Future<SettingsController> _open(
  WidgetTester tester, {
  required bool training,
  bool kid = false,
}) async {
  _activities.clear();
  _saved.clear();
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final settings = SettingsController.defaults();
  await settings.update(settings.value.copyWith(trainingMode: training));
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('it'),
      home: GamePage(
        settings: settings,
        computerAvailable: true,
        now: () => DateTime(2026, 10, 11, 12),
        createComputer: () =>
            ComputerPlayer(connect: () async => FirstLegalMoveEngine()),
        onActivity: (a) async {
          _activities.add(a);
          return const ProgressUpdate(
            state: ProgressState.initial,
            xpGained: 10,
          );
        },
        onSave: (g) async => _saved.add(g),
      ),
    ),
  );
  await startComputerGame(tester, side: 'Bianco');
  await tester.pumpAndSettle(const Duration(seconds: 1));
  if (kid) {
    await settings.update(settings.value.copyWith(kidMode: true));
    await tester.pumpAndSettle();
  }
  return settings;
}

Future<void> _playAndResign(WidgetTester tester) async {
  await tapMove(tester, 'e2e4');
  await tester.pumpAndSettle(const Duration(seconds: 2));
  await tapMove(tester, 'd2d4');
  await tester.pumpAndSettle(const Duration(seconds: 2));
  await tapGameAction(tester, 'Abbandona');
  await tester.pumpAndSettle();
  await tester.tap(find.text('Abbandona').last);
  await tester.pumpAndSettle();
}

bool _enabled(WidgetTester tester, String id) {
  final finder = find.byKey(ValueKey('gameAction-$id'));
  if (finder.evaluate().isEmpty) return false;
  return tester.widget<InkWell>(finder).onTap != null;
}

void main() {
  testWidgets('RF-22 in Sfida si annulla ma non ci sono aiuti', (tester) async {
    await _open(tester, training: false);
    await tapMove(tester, 'e2e4');
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(_enabled(tester, 'undo'), isTrue);
    // Senza aiuti il pannello «Altro» non offre né suggerimento né minacce.
    expect(find.byKey(const ValueKey('gameAction-more')), findsNothing);
    expect(find.text('Suggerimento'), findsNothing);
  });

  testWidgets('RF-22 in Allenamento si annulla e ci sono gli aiuti', (
    tester,
  ) async {
    await _open(tester, training: true);
    await tapMove(tester, 'e2e4');
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(_enabled(tester, 'undo'), isTrue);
    await tester.tap(find.byKey(const ValueKey('gameAction-more')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('gameAction-hint')), findsOneWidget);
  });

  testWidgets('RF-22 la Sfida conta per Elo e vittorie', (tester) async {
    await _open(tester, training: false);
    await _playAndResign(tester);
    final activity = _activities.single as GamePlayed;
    expect(activity.playerSide, Side.white);
    expect(activity.opponentElo, isNotNull);
    expect(_saved.last.opponentElo, isNotNull);
  });

  testWidgets('RF-22 l\'Allenamento non conta per Elo né vittorie', (
    tester,
  ) async {
    await _open(tester, training: true);
    await _playAndResign(tester);
    final activity = _activities.single as GamePlayed;
    expect(activity.result, GameResult.local);
    expect(activity.opponentElo, isNull);
    expect(_saved.last.opponentElo, isNull);
  });

  testWidgets('RF-22 il profilo bambino parte in Allenamento', (tester) async {
    await _open(tester, training: false, kid: true);
    await tapMove(tester, 'e2e4');
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(_enabled(tester, 'undo'), isTrue);
  });
}

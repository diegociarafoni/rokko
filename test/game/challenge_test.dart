import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart' show Side;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/engine/computer_player.dart';
import 'package:rokko/game/challenge.dart';
import 'package:rokko/game/game_page.dart';
import 'package:rokko/progress/activity.dart';
import 'package:rokko/settings/settings.dart';

import '../computer_fakes.dart';
import '../game_actions.dart';

void main() {
  group('challengeStars', () {
    test('una vittoria rapida vale tre stelle', () {
      expect(challengeStars(GameResult.win, moves: 25), 3);
      expect(challengeStars(GameResult.win, moves: 40), 3);
    });

    test('più la partita è lunga, meno stelle, ma almeno una', () {
      expect(challengeStars(GameResult.win, moves: 41), 2);
      expect(challengeStars(GameResult.win, moves: 60), 2);
      expect(challengeStars(GameResult.win, moves: 61), 1);
      expect(challengeStars(GameResult.win, moves: 200), 1);
    });

    test('senza vittoria non ci sono stelle', () {
      expect(challengeStars(GameResult.draw, moves: 30), isNull);
      expect(challengeStars(GameResult.loss, moves: 30), isNull);
    });
  });

  group('partita sfida', () {
    final results = <GameResult>[];

    Future<void> open(
      WidgetTester tester, {
      Side side = Side.white,
      bool pushed = false,
      bool allowUndo = false,
      bool allowHints = false,
    }) async {
      results.clear();
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      Widget game() => GamePage(
        settings: SettingsController.defaults(),
        computerAvailable: true,
        now: () => DateTime(2026, 10, 11, 12),
        createComputer: () =>
            ComputerPlayer(connect: () async => FirstLegalMoveEngine()),
        challenge: GameChallenge(
          title: 'Il guardiano',
          levelId: 2,
          side: side,
          allowUndo: allowUndo,
          allowHints: allowHints,
        ),
        onFinished: (result, _) => results.add(result),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: pushed
              ? Builder(
                  builder: (context) => TextButton(
                    onPressed: () => Navigator.of(context)
                        .push(MaterialPageRoute<void>(builder: (_) => game())),
                    child: const Text('apri'),
                  ),
                )
              : game(),
        ),
      );
      if (pushed) {
        await tester.tap(find.text('apri'));
      }
      await tester.pumpAndSettle(const Duration(seconds: 1));
    }

    testWidgets('parte subito contro il livello richiesto', (tester) async {
      await open(tester);
      expect(find.text('Il guardiano'), findsOneWidget);
      expect(find.textContaining('Computer, livello 2'), findsOneWidget);
      expect(find.text('Muove il Bianco.'), findsOneWidget);
    });

    testWidgets('con il Nero il computer muove per primo', (tester) async {
      await open(tester, side: Side.black);
      expect(find.text('Muove il Nero.'), findsOneWidget);
      expect(find.textContaining('1. '), findsOneWidget);
    });

    testWidgets('non si può ricominciare né annullare', (tester) async {
      await open(tester);
      final newGame = tester.widget<InkWell>(
        find.byKey(const ValueKey('gameAction-new')),
      );
      expect(newGame.onTap, isNull);
      expect(find.byTooltip('Altre azioni'), findsNothing);
    });

    testWidgets('con allowHints c\'è Suggerisci ma non l\'allenatore', (
      tester,
    ) async {
      await open(tester, allowUndo: true, allowHints: true);
      expect(find.text('Suggerisci'), findsOneWidget);
      expect(find.byTooltip('Altre azioni'), findsNothing);
    });

    testWidgets('l\'abbandono comunica la sconfitta una sola volta', (
      tester,
    ) async {
      await open(tester);
      await tapGameAction(tester, 'Abbandona');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Abbandona').last);
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(results, [GameResult.loss]);
      expect(find.byType(Chessboard), findsOneWidget);
    });

    Future<void> playE4(WidgetTester tester) async {
      final rect = tester.getRect(find.byType(Chessboard));
      final size = rect.width / 8;
      Offset square(int file, int rank) =>
          rect.topLeft + Offset((file + 0.5) * size, (8 - rank + 0.5) * size);
      await tester.tapAt(square(4, 2));
      await tester.pump();
      await tester.tapAt(square(4, 4));
      await tester.pumpAndSettle(const Duration(seconds: 1));
    }

    String fen(WidgetTester tester) =>
        tester.widget<Chessboard>(find.byType(Chessboard)).controller.game.fen;

    testWidgets('annulla funziona se la sfida lo consente', (tester) async {
      await open(tester, allowUndo: true);
      final start = fen(tester);
      await playE4(tester);
      expect(fen(tester), isNot(start));
      await tester.tap(find.text('Annulla'));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(fen(tester), start);
    });

    testWidgets('annulla non c\'è nelle sfide competitive', (tester) async {
      await open(tester);
      await playE4(tester);
      final played = fen(tester);
      await tester.tap(find.text('Annulla'), warnIfMissed: false);
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(fen(tester), played);
    });

    testWidgets('uscire a partita in corso chiede conferma', (tester) async {
      await open(tester, pushed: true);
      // Una mossa sulla scacchiera, poi si prova a uscire.
      final rect = tester.getRect(find.byType(Chessboard));
      final size = rect.width / 8;
      Offset square(int file, int rank) =>
          rect.topLeft + Offset((file + 0.5) * size, (8 - rank + 0.5) * size);
      await tester.tapAt(square(4, 2));
      await tester.pump();
      await tester.tapAt(square(4, 4));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Lasciare la sfida?'), findsOneWidget);
      await tester.tap(find.text('Continua'));
      await tester.pumpAndSettle();
      expect(find.byType(Chessboard), findsOneWidget);
      expect(results, isEmpty);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Esci'));
      await tester.pumpAndSettle();
      expect(find.text('apri'), findsOneWidget);
      expect(results, [GameResult.loss]);
    });

    testWidgets('niente aiuti durante la sfida', (tester) async {
      await open(tester);
      expect(find.text('Aiuto'), findsNothing);
      expect(find.text('Suggerisci'), findsNothing);
      expect(find.text('Coach'), findsNothing);
      expect(find.byTooltip('Altre azioni'), findsNothing);
    });
  });
}

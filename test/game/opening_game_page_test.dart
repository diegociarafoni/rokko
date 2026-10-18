import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/engine/computer_player.dart';
import 'package:rokko/game/challenge.dart';
import 'package:rokko/game/game_page.dart';
import 'package:rokko/settings/settings.dart';

import '../computer_fakes.dart';

List<Move> uci(String moves) =>
    moves.isEmpty ? [] : moves.split(' ').map((m) => Move.parse(m)!).toList();

void main() {
  Future<void> open(
    WidgetTester tester, {
    required String start,
    Side side = Side.white,
    String? line,
    List<String> reply = const [],
  }) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: GamePage(
          settings: SettingsController.defaults(),
          computerAvailable: true,
          now: () => DateTime(2026, 10, 12, 9),
          createComputer: () => ComputerPlayer(
            connect: () async => FirstLegalMoveEngine(script: reply),
          ),
          challenge: GameChallenge(
            title: 'Gioca un\'apertura',
            levelId: 2,
            side: side,
            startMoves: uci(start),
            line: line == null ? null : uci(line),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 1));
  }

  String fen(WidgetTester tester) =>
      tester.widget<Chessboard>(find.byType(Chessboard)).controller.game.fen;

  Future<void> tapMove(WidgetTester tester, String from, String to) async {
    final rect = tester.getRect(find.byType(Chessboard));
    final size = rect.width / 8;
    Offset square(String s) =>
        rect.topLeft +
        Offset(
          (s.codeUnitAt(0) - 97 + 0.5) * size,
          (8 - int.parse(s[1]) + 0.5) * size,
        );
    await tester.tapAt(square(from));
    await tester.pump();
    await tester.tapAt(square(to));
    await tester.pumpAndSettle(const Duration(seconds: 1));
  }

  testWidgets('RF-94 la partita parte dopo le mosse scelte', (tester) async {
    await open(tester, start: 'e2e4 e7e5');
    expect(
      fen(tester).split(' ').first,
      'rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR',
    );
    expect(find.text('Muove il Bianco.'), findsOneWidget);
    expect(find.text('1. e4'), findsOneWidget);
    expect(find.text('e5'), findsOneWidget);
  });

  testWidgets('RF-94 se tocca al computer risponde subito', (tester) async {
    await open(tester, start: 'e2e4', reply: ['c7c5']);
    expect(find.text('1. e4'), findsOneWidget);
    expect(find.text('c5'), findsOneWidget);
    expect(find.text('Muove il Bianco.'), findsOneWidget);
  });

  testWidgets('RF-94 il computer che esce dalla linea viene segnalato', (
    tester,
  ) async {
    await open(tester, start: '', line: 'e2e4 e7e5 g1f3', reply: ['c7c5']);
    await tapMove(tester, 'e2', 'e4');
    expect(
      find.text('Il computer è uscito dalla linea del repertorio.'),
      findsOneWidget,
    );
  });

  testWidgets('RF-94 il computer che segue la linea non è segnalato', (
    tester,
  ) async {
    await open(tester, start: '', line: 'e2e4 e7e5', reply: ['e7e5']);
    await tapMove(tester, 'e2', 'e4');
    expect(find.textContaining('uscito dalla linea'), findsNothing);
    expect(find.text('e5'), findsOneWidget);
  });

  testWidgets('RF-94 anche l\'utente che esce dalla linea viene avvisato', (
    tester,
  ) async {
    await open(tester, start: '', line: 'e2e4 e7e5', reply: ['d7d5']);
    await tapMove(tester, 'd2', 'd4');
    expect(find.text('Sei uscito dalla linea del repertorio.'), findsOneWidget);
  });

  testWidgets('RF-94 senza linea non compaiono segnalazioni', (tester) async {
    await open(tester, start: 'e2e4 e7e5');
    await tapMove(tester, 'g1', 'f3');
    expect(find.textContaining('uscito dalla linea'), findsNothing);
  });

  testWidgets('RF-94 dopo annulla una nuova uscita dalla linea si segnala', (
    tester,
  ) async {
    await open(tester, start: '', line: 'e2e4 e7e5', reply: ['d7d5', 'd7d5']);
    await tapMove(tester, 'd2', 'd4');
    expect(find.text('Sei uscito dalla linea del repertorio.'), findsOneWidget);
    await tester.tap(find.text('Annulla'));
    await tester.pumpAndSettle(const Duration(seconds: 5));
    expect(find.textContaining('uscito dalla linea'), findsNothing);
    await tapMove(tester, 'd2', 'd4');
    expect(find.text('Sei uscito dalla linea del repertorio.'), findsOneWidget);
  });
}

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/engine/computer_player.dart';
import 'package:rokko/game/challenge.dart';
import 'package:rokko/game/game_page.dart';
import 'package:rokko/l10n/app_localizations.dart';
import 'package:rokko/openings/explorer_page.dart';
import 'package:rokko/openings/opening_book.dart';
import 'package:rokko/openings/opening_stats.dart';
import 'package:rokko/settings/settings.dart';

import '../computer_fakes.dart';

final book = OpeningBook.parseTsv(
  'eco\tname\tuci\n'
  'C44\tKing\'s Pawn Game\te2e4 e7e5 g1f3\n'
  'B20\tSicilian Defense\te2e4 c7c5\n',
);

String key(String uci) {
  Position pos = Chess.initial;
  for (final m in uci.split(' ').where((s) => s.isNotEmpty)) {
    pos = pos.play(Move.parse(m)!);
  }
  return OpeningStats.keyOf(pos);
}

final stats = OpeningStats.parseTsv(
  'chiave\tmosse\n'
  '${key('')}\te4:1000:450:350,d4:800:400:280\n'
  '${key('e2e4')}\tc5:600:240:210,e5:400:180:120\n',
);

void main() {
  Future<void> open(WidgetTester tester, {String? reply}) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('it'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: GamePage(
          settings: SettingsController.defaults(),
          computerAvailable: true,
          now: () => DateTime(2026, 10, 12, 9),
          openingBook: Future.value(book),
          openingStats: Future.value(stats),
          createComputer: () => ComputerPlayer(
            connect: () async => FirstLegalMoveEngine(forcedMove: reply),
          ),
          challenge: const GameChallenge(
            title: 'Istruttore',
            levelId: 2,
            side: Side.white,
            instructor: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 1));
  }

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

  testWidgets('all\'inizio l\'istruttore propone le mosse più giocate', (
    tester,
  ) async {
    await open(tester);
    expect(find.textContaining('Le mosse più giocate qui: e4 (56%)'), findsOne);
  });

  testWidgets('dopo la mossa dice l\'apertura raggiunta', (tester) async {
    await open(tester, reply: 'c7c5');
    await tapMove(tester, 'e2', 'e4');
    expect(find.textContaining('Siamo nella Difesa siciliana'), findsOne);
  });

  testWidgets('segnala l\'uscita dal libro', (tester) async {
    await open(tester, reply: 'a7a6');
    await tapMove(tester, 'e2', 'e4');
    expect(find.textContaining('Il computer esce dal libro con a6'), findsOne);
  });

  testWidgets('dall\'icona si apre l\'esploratore sulla posizione', (
    tester,
  ) async {
    await open(tester, reply: 'e7e5');
    await tapMove(tester, 'e2', 'e4');
    await tester.tap(find.byTooltip('Apri nell\'esploratore'));
    await tester.pumpAndSettle();
    final page = tester.widget<ExplorerPage>(find.byType(ExplorerPage));
    expect(page.initialMoves.length, 2);
  });

  testWidgets('annullando il commento segue la posizione', (tester) async {
    await open(tester, reply: 'a7a6');
    await tapMove(tester, 'e2', 'e4');
    expect(find.textContaining('Il computer esce dal libro'), findsOne);
    await tester.tap(find.text('Annulla'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.textContaining('Il computer esce dal libro'), findsNothing);
  });
}

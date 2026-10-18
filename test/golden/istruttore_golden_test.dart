@Tags(['golden'])
library;

import 'dart:io';

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart' hide File;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/engine/computer_player.dart';
import 'package:rokko/game/challenge.dart';
import 'package:rokko/game/game_page.dart';
import 'package:rokko/l10n/app_localizations.dart';
import 'package:rokko/openings/opening_book.dart';
import 'package:rokko/openings/opening_stats.dart';
import 'package:rokko/settings/notation.dart';
import 'package:rokko/settings/settings.dart';
import 'package:rokko/theme/rokko_theme.dart';

import '../computer_fakes.dart';
import '../support/devices.dart';

// I riferimenti sono generati su Linux: altrove il rendering dei caratteri differisce.
final _skip = Platform.isLinux ? null : 'riferimenti generati solo su Linux';

// Numeri di prova: il test controlla la grafica, non i dati reali.
const _rows = 'c5:60000:24000:21000,e5:40000:18000:12000,e6:9000:3600:3000';

void main() {
  for (final device in Device.phones) {
    testWidgets(
      'partita con l\'istruttore su ${device.name}',
      skip: _skip != null,
      (tester) async {
        device.apply(tester);
        await tester.runAsync(
          () => ChessgroundImages.instance.loadAll(
            const ChessboardSettings().pieceAssets,
          ),
        );
        final book = OpeningBook.parseTsv(
          File('assets/openings/openings.tsv').readAsStringSync(),
        );
        final after = Chess.initial.play(Move.parse('e2e4')!);
        final stats = OpeningStats.parseTsv(
          'chiave\tmosse\n${OpeningStats.keyOf(after)}\t$_rows\n',
        );
        await tester.pumpWidget(
          SettingsScope(
            controller: SettingsController.defaults()
              ..value = AppSettings(notation: MoveNotation.italian),
            child: MaterialApp(
              theme: RokkoTheme.light(),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: const Locale('it'),
              home: GamePage(
                settings: SettingsController.defaults(),
                computerAvailable: true,
                now: () => DateTime(2026, 10, 12, 9),
                openingBook: Future.value(book),
                openingStats: Future.value(stats),
                createComputer: () =>
                    ComputerPlayer(connect: () async => FirstLegalMoveEngine()),
                challenge: GameChallenge(
                  title: 'Gioca con l\'istruttore',
                  levelId: 2,
                  side: Side.black,
                  startMoves: [Move.parse('e2e4')!],
                  instructor: true,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle(const Duration(seconds: 1));
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/istruttore-${device.name}.png'),
        );
      },
    );
  }
}

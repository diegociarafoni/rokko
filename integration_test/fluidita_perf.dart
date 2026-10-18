import 'dart:convert';
import 'dart:io';

import 'package:chessground/chessground.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rokko/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test/game_actions.dart';
import '../test/support/italian_device.dart';

Offset _square(WidgetTester tester, String name) {
  final rect = tester.getRect(find.byType(Chessboard));
  final size = rect.width / 8;
  final file = name.codeUnitAt(0) - 'a'.codeUnitAt(0);
  final rank = int.parse(name[1]);
  return rect.topLeft + Offset((file + 0.5) * size, (8 - rank + 0.5) * size);
}

const _moves = ['e2e4', 'e7e5', 'g1f3', 'b8c6', 'f1c4', 'g8f6', 'd2d3', 'f8c5'];

/// Misura l'avvio e i tempi di costruzione dei fotogrammi in una partita e tra le schede;
/// il rapporto va in build/performance.json per `tool/check_performance.dart`.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  useItalianDevice();

  testWidgets('fluidità: partita e navigazione', (tester) async {
    SharedPreferences.setMockInitialValues({'guideEnabled': false});
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    // Avvio: dal lancio alla Home con la barra di navigazione, pronta a giocare.
    final startup = Stopwatch()..start();
    await tester.pumpWidget(const RokkoApp());
    while (find.byType(NavigationBar).evaluate().isEmpty) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    startup.stop();
    await tester.pumpAndSettle();
    await openBoard(tester);

    // Un rapporto vecchio non deve passare per quello di questa esecuzione.
    final out = File('build/performance.json');
    if (out.existsSync()) out.deleteSync();

    Future<void> play(String m) async {
      await tester.tapAt(_square(tester, m.substring(0, 2)));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tapAt(_square(tester, m.substring(2, 4)));
      await tester.pumpAndSettle();
    }

    // Una mossa di riscaldamento fuori dalla misura: compilazione JIT e primi fotogrammi.
    await play(_moves.first);

    await binding.watchPerformance(() async {
      for (final m in _moves.skip(1)) {
        await play(m);
      }
      // Le mosse sono state giocate davvero (tocchi fuori dalla scacchiera non contano).
      expect(find.text('Muove il Bianco.'), findsOneWidget);
      expect(find.text('4. d3'), findsOneWidget);
      // Si torna alla Home per passare alla scheda Tu.
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Tu'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.fling(
        find.byType(Scrollable).first,
        const Offset(0, -600),
        1500,
      );
      await tester.pumpAndSettle();
    });

    final report = binding.reportData!['performance'] as Map<String, dynamic>;
    out
      ..createSync(recursive: true)
      ..writeAsStringSync(
        jsonEncode({...report, 'startup_ms': startup.elapsedMilliseconds}),
      );
  });
}

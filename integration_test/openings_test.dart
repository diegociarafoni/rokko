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

Future<void> _tapMove(WidgetTester tester, String uci) async {
  await tester.tapAt(_square(tester, uci.substring(0, 2)));
  await tester.pump();
  await tester.tapAt(_square(tester, uci.substring(2, 4)));
  await tester.pumpAndSettle();
}

/// Apre dalla Home la funzione [id], portando in vista la sua scheda.
Future<void> _openFeature(WidgetTester tester, String id) async {
  final tile = find.byKey(Key('home-feature-$id'));
  await tester.scrollUntilVisible(
    tile,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.tap(tile);
  await tester.pumpAndSettle();
}

Future<void> _start(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({'guideEnabled': false});
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const RokkoApp());
  await tester.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  useItalianDevice();

  testWidgets('RF-90 la partita mostra il nome dell\'apertura', (tester) async {
    await _start(tester);
    await openBoard(tester);
    await _tapMove(tester, 'e2e4');
    await _tapMove(tester, 'c7c5');
    // Il libro si carica in un isolate: si attende che il nome compaia.
    for (
      var i = 0;
      i < 50 && find.text('Difesa siciliana').evaluate().isEmpty;
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Difesa siciliana'), findsOneWidget);
  });

  testWidgets('RF-92 l\'explorer segue le mosse del libro', (tester) async {
    await _start(tester);
    await _openFeature(tester, 'openings');
    await tester.tap(find.text('Esplora aperture'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('e4'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('c5'));
    await tester.pumpAndSettle();
    expect(find.text('Difesa siciliana'), findsOneWidget);
    await _tapMove(tester, 'a2a3');
    expect(find.textContaining('Difesa siciliana'), findsWidgets);
  });

  testWidgets('RF-93 una linea dell\'explorer si ripassa dal repertorio', (
    tester,
  ) async {
    await _start(tester);
    await _openFeature(tester, 'openings');
    await tester.tap(find.text('Esplora aperture'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('e4'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('c5'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Aggiungi al repertorio'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aggiungi'));
    await tester.pumpAndSettle();
    // pageBack cerca il tooltip inglese "Back"; l'app è in italiano.
    await tester.tap(
      find.byTooltip(
        MaterialLocalizations.of(tester.element(find.byType(Scaffold).last))
            .backButtonTooltip,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Repertorio con il Nero'));
    await tester.pumpAndSettle();
    expect(find.text('1. e4 c5'), findsWidgets);
  });

  testWidgets('RF-96 le tue aperture partono vuote e si raggiungono dalla '
      'scheda Aperture', (tester) async {
    await _start(tester);
    await _openFeature(tester, 'openings');
    await tester.tap(find.text('Le tue aperture'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Gioca qualche partita'), findsOneWidget);
  });
}

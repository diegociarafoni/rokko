import 'package:chessground/chessground.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rokko/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test/game_actions.dart';
import '../test/support/italian_device.dart';

Offset _square(WidgetTester tester, Type board, String name) {
  final rect = tester.getRect(find.byType(board));
  final size = rect.width / 8;
  final file = name.codeUnitAt(0) - 'a'.codeUnitAt(0);
  final rank = int.parse(name[1]);
  return rect.topLeft + Offset((file + 0.5) * size, (8 - rank + 0.5) * size);
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  useItalianDevice();

  testWidgets('RF-53 si costruisce un finale e lo si gioca fino al matto', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'guideEnabled': false});
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const RokkoApp());
    await tester.pumpAndSettle();
    await openBoard(tester);

    await openPositionEditor(tester);
    await tester.pumpAndSettle();
    await _tap(tester, find.text('Svuota'));
    expect(find.text('La scacchiera è vuota.'), findsOneWidget);

    // Re e torre contro re: Ra8 è matto.
    for (final (piece, square) in [('wK', 'g6'), ('wR', 'a1'), ('bK', 'g8')]) {
      await _tap(tester, find.byKey(Key('editor-piece-$piece')));
      await tester.tapAt(_square(tester, StaticChessboard, square));
      await tester.pump();
    }
    await _tap(tester, find.text('Gioca da qui'));
    final play = find.widgetWithText(FilledButton, 'Gioca');
    if (play.evaluate().isNotEmpty) await _tap(tester, play);
    expect(find.text('Muove il Bianco.'), findsOneWidget);

    await tester.tapAt(_square(tester, Chessboard, 'a1'));
    await tester.pump();
    await tester.tapAt(_square(tester, Chessboard, 'a8'));
    await tester.pumpAndSettle();
    expect(find.text('Scacco matto. Vince il Bianco.'), findsOneWidget);
  });
}

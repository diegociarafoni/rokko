import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rokko/main.dart';
import 'package:rokko/physical/photo_source.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test/support/italian_device.dart';

Future<void> _type(WidgetTester tester, String move) async {
  await tester.enterText(find.byKey(const Key('physical-input')), move);
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  useItalianDevice();

  testWidgets('la partita su scacchiera fisica si registra fino al matto', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'guideEnabled': false});
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const RokkoApp());
    await tester.pumpAndSettle();

    // La Home è una lista pigra: la tessera va cercata scorrendo.
    final tile = find.byKey(const Key('home-feature-physical'));
    await tester.scrollUntilVisible(
      tile,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(tile);
    await tester.pumpAndSettle();
    await tester.tap(tile);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Senza tempo'));
    await tester.tap(find.text('Inizia la partita'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('physical-photo')),
      kPhotoMove ? findsOneWidget : findsNothing,
    );
    for (final move in ['f3', 'e5', 'g4', 'Dh4']) {
      await _type(tester, move);
    }
    expect(find.textContaining('Scacco matto'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('physical-moves'))).data,
      '1. f3 e5 2. g4 Qh4#',
    );
  });
}

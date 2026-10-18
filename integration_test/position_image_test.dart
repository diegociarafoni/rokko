import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rokko/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test/game_actions.dart';
import '../test/support/italian_device.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  useItalianDevice();

  testWidgets('RF-104 l\'editor apre l\'anteprima da condividere', (
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
    await tester.tap(find.byTooltip('Esporta come immagine'));
    await tester.pumpAndSettle();

    expect(find.text('Esporta come immagine'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('position-image-caption')),
      'Posizione iniziale',
    );
    await tester.pumpAndSettle();
    expect(find.text('Posizione iniziale'), findsWidgets);
    expect(find.widgetWithText(FilledButton, 'Condividi'), findsOneWidget);
  });
}

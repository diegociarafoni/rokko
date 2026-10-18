import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rokko/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test/support/italian_device.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  useItalianDevice();

  testWidgets('il riepilogo settimanale si apre dalla scheda Tu', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'guideEnabled': false});
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const RokkoApp());
    // I contenuti si caricano da asset: si attende che la barra compaia.
    for (var i = 0; i < 100 && find.text('Tu').evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tu'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('La tua settimana'), 200);
    await tester.pumpAndSettle();
    await tester.tap(find.text('La tua settimana'));
    await tester.pumpAndSettle();

    // Con attività recenti compare la scheda, altrimenti la spiegazione.
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Text &&
            (w.data?.contains('il riepilogo si riempie da solo') == true ||
                w.data == 'I tuoi progressi'),
      ),
      findsOneWidget,
    );
  });
}

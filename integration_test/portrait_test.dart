import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rokko/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test/support/italian_device.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  useItalianDevice();

  testWidgets('la scheda della settimana si apre dal profilo', (tester) async {
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
    final share = find.byIcon(Icons.ios_share);
    await tester.scrollUntilVisible(
      share,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(share);
    await tester.pumpAndSettle();

    // Senza partite recenti compare la spiegazione, altrimenti la scheda.
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Text &&
            (w.data?.startsWith('Nessuna partita') ??
                w.data == 'La mia settimana a scacchi'),
      ),
      findsOneWidget,
    );
  });
}

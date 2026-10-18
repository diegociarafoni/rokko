import 'dart:async';

import 'package:rokko/engine/uci_transport.dart';

import 'package:rokko/guide/guide_controller.dart';

import '../content_support.dart';
import '../support/golden_fonts.dart';
import '../support/italian_device.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // I riferimenti mostrano il computer disponibile: non dipendono dal motore installato.
  StockfishTransport.debugSupported = true;
  GuideController.defaultEnabled = false;
  useContent();
  useItalianDevice();
  await loadGoldenFonts();
  await testMain();
}

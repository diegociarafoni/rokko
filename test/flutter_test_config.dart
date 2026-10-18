import 'dart:async';

import 'package:rokko/guide/guide_controller.dart';

import 'content_support.dart';
import 'support/italian_device.dart';

/// Ogni test parte con il telefono in italiano e i contenuti già caricati,
/// come nell'app.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  GuideController.defaultEnabled = false;
  useItalianDevice();
  useContent();
  await testMain();
}

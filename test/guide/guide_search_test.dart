import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/l10n/app_localizations.dart';
import 'package:rokko/settings/settings_page.dart';
import 'package:rokko/settings/settings_search.dart';

void main() {
  test(
    'la ricerca nelle Impostazioni trova le guide in Accessibilità',
    () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('it'));
      final hits = settingsHits(l10n, 'guide', hasProgress: false);
      expect(hits.map((h) => h.title), contains('Rivedi le guide'));
      expect(
        hits.every((h) => h.section == SettingsSection.accessibility),
        isTrue,
      );
    },
  );
}

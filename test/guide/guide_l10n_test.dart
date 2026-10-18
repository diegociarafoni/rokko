import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/guide/guide_steps.dart';
import 'package:rokko/l10n/app_localizations.dart';

void main() {
  final screens = {
    'home': homeGuide,
    'puzzles': puzzlesGuide,
    'learn': learnGuide,
    'you': youGuide,
    'settings': settingsGuide,
    'newGame': newGameGuide,
    'game': gameGuide,
    'story': storyGuide,
  };

  test('ogni guida ha passi con elementi diversi', () {
    for (final MapEntry(:key, :value) in screens.entries) {
      final anchors = value.map((s) => s.anchor).toList();
      expect(anchors.toSet().length, anchors.length, reason: key);
    }
  });

  // I testi stanno nei file della lingua, non nel codice: ogni lingua dell'app
  // li ha tutti, per adulti e per il profilo bambino.
  for (final locale in AppLocalizations.supportedLocales) {
    test('guida tradotta in ${locale.languageCode}', () async {
      final l10n = await AppLocalizations.delegate.load(locale);
      for (final MapEntry(:key, :value) in screens.entries) {
        for (final step in value) {
          for (final kid in [false, true]) {
            final text = step.text(l10n, kid);
            expect(text.trim(), isNotEmpty, reason: '$key ${step.anchor}');
            expect(text, isNot(contains('{')), reason: step.anchor);
          }
        }
      }
      expect(l10n.guideSkip, isNotEmpty);
      expect(l10n.guideNext, isNotEmpty);
      expect(l10n.guideDone, isNotEmpty);
      expect(l10n.guideStepCounter(2, 5), '2/5');
    });
  }

  test('nelle altre lingue i testi sono davvero tradotti', () async {
    final it = await AppLocalizations.delegate.load(const Locale('it'));
    for (final locale in AppLocalizations.supportedLocales) {
      if (locale.languageCode == 'it') continue;
      final l10n = await AppLocalizations.delegate.load(locale);
      expect(l10n.guideHomePlay, isNot(it.guideHomePlay), reason: '$locale');
      expect(l10n.guideGameBoard, isNot(it.guideGameBoard), reason: '$locale');
      expect(l10n.guideSkip, isNot(it.guideSkip), reason: '$locale');
    }
  });
}

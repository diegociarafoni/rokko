import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/guide/guide_controller.dart';
import 'package:rokko/guide/guide_host.dart';
import 'package:rokko/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _steps = <GuideStep>[
  GuideStep('a', (l, _) => l.guideHomeSearch),
  GuideStep('missing', (l, _) => l.guideHomeStats),
  GuideStep('b', (l, kid) => kid ? l.guideHomePlayKid : l.guideHomePlay),
];

Widget _app(GuideController? guides, {bool enabled = true, Widget? extra}) {
  final screen = GuideHost(
    screen: 'demo',
    steps: _steps,
    enabled: enabled,
    child: Scaffold(
      body: Column(
        children: [
          const GuideAnchor(id: 'a', child: Text('Elemento A')),
          const GuideAnchor(id: 'b', child: Text('Elemento B')),
          ?extra,
        ],
      ),
    ),
  );
  return MaterialApp(
    locale: const Locale('it'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, child) =>
        guides == null ? child! : GuideScope(controller: guides, child: child!),
    home: screen,
  );
}

void main() {
  group('GuideController', () {
    setUp(() => GuideController.defaultEnabled = true);
    tearDown(() => GuideController.defaultEnabled = false);

    test('ricorda le guide viste e le riattiva con reset', () async {
      SharedPreferences.setMockInitialValues({});
      final guides = await GuideController.load();
      expect(guides.shouldShow('home'), isTrue);
      await guides.markSeen('home');
      expect(guides.shouldShow('home'), isFalse);
      expect((await GuideController.load()).isSeen('home'), isTrue);
      await guides.reset();
      expect((await GuideController.load()).shouldShow('home'), isTrue);
    });

    test('disattivate non compaiono, e il valore resta salvato', () async {
      SharedPreferences.setMockInitialValues({});
      final guides = await GuideController.load();
      await guides.setEnabled(false);
      expect(guides.shouldShow('home'), isFalse);
      expect((await GuideController.load()).enabled, isFalse);
      await guides.reset();
      expect(guides.enabled, isTrue);
    });
  });

  group('guida di una schermata', () {
    testWidgets('compare la prima volta e salta i passi senza elemento', (
      tester,
    ) async {
      final guides = GuideController.memory();
      await tester.pumpWidget(_app(guides));
      await tester.pumpAndSettle();
      expect(find.text('1/2'), findsOneWidget);
      expect(find.textContaining('Cerca una funzione'), findsOneWidget);
      await tester.tap(find.byKey(const Key('guide-next')));
      await tester.pumpAndSettle();
      expect(find.text('2/2'), findsOneWidget);
      expect(find.text('Fine'), findsOneWidget);
      expect(find.textContaining('rating'), findsNothing);
      await tester.tap(find.byKey(const Key('guide-next')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('guide-next')), findsNothing);
      expect(guides.isSeen('demo'), isTrue);
    });

    testWidgets('«Salta» la chiude subito e non ricompare', (tester) async {
      final guides = GuideController.memory();
      await tester.pumpWidget(_app(guides));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('guide-skip')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('guide-skip')), findsNothing);
      expect(guides.isSeen('demo'), isTrue);
      await tester.pumpWidget(_app(guides, extra: const SizedBox()));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('guide-skip')), findsNothing);
    });

    testWidgets('il tasto indietro chiude la guida e non la schermata', (
      tester,
    ) async {
      final guides = GuideController.memory();
      await tester.pumpWidget(_app(guides));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('guide-skip')), findsNothing);
      expect(find.text('Elemento A'), findsOneWidget);
      expect(guides.isSeen('demo'), isTrue);
    });

    testWidgets('disattivata o già vista non compare', (tester) async {
      await tester.pumpWidget(_app(GuideController.memory(enabled: false)));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('guide-skip')), findsNothing);
      await tester.pumpWidget(
        _app(GuideController.memory(seen: {'demo'}), extra: const SizedBox()),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('guide-skip')), findsNothing);
    });

    testWidgets('senza guide nell\'albero (test, anteprime) non fa nulla', (
      tester,
    ) async {
      await tester.pumpWidget(_app(null));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('guide-skip')), findsNothing);
      expect(find.text('Elemento A'), findsOneWidget);
    });

    testWidgets('con enabled falso aspetta, poi parte', (tester) async {
      final guides = GuideController.memory();
      await tester.pumpWidget(_app(guides, enabled: false));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('guide-skip')), findsNothing);
      await tester.pumpWidget(_app(guides));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('guide-skip')), findsOneWidget);
    });

    testWidgets('i tocchi sotto la guida non arrivano alla schermata', (
      tester,
    ) async {
      var taps = 0;
      final guides = GuideController.memory();
      await tester.pumpWidget(
        _app(
          guides,
          extra: TextButton(
            onPressed: () => taps++,
            child: const Text('Tocca'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 300));
      await tester.pump();
      expect(taps, 0);
    });

    testWidgets('con testo al 200% e telefono piccolo non va in overflow', (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(320, 480)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 480),
            textScaler: TextScaler.linear(2),
          ),
          child: _app(GuideController.memory()),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('guide-next')), findsOneWidget);
    });

    testWidgets('annuncia il testo ai lettori di schermo', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_app(GuideController.memory()));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel(RegExp('Cerca una funzione')), findsWidgets);
      expect(
        tester.getSemantics(find.byKey(const Key('guide-next'))),
        matchesSemantics(
          label: 'Avanti',
          isButton: true,
          isEnabled: true,
          hasEnabledState: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      handle.dispose();
    });
  });
}

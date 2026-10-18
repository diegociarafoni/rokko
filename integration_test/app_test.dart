import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart' show Side;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rokko/main.dart';
import 'package:rokko/settings/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test/computer_fakes.dart' show openCustomSheet;
import '../test/game_actions.dart';
import '../test/support/italian_device.dart';

Offset _square(WidgetTester tester, String name) {
  final rect = tester.getRect(find.byType(Chessboard));
  final size = rect.width / 8;
  final file = name.codeUnitAt(0) - 'a'.codeUnitAt(0);
  final rank = int.parse(name[1]);
  return rect.topLeft + Offset((file + 0.5) * size, (8 - rank + 0.5) * size);
}

Future<void> _tapMove(WidgetTester tester, String uci) async {
  await tester.tapAt(_square(tester, uci.substring(0, 2)));
  await tester.pump();
  await tester.tapAt(_square(tester, uci.substring(2, 4)));
  await tester.pumpAndSettle();
}

Future<void> _dragMove(WidgetTester tester, String uci) async {
  final from = _square(tester, uci.substring(0, 2));
  final to = _square(tester, uci.substring(2, 4));
  final gesture = await tester.startGesture(from);
  await tester.pump();
  await gesture.moveTo(Offset.lerp(from, to, 0.5)!);
  await tester.pump();
  await gesture.moveTo(to);
  await tester.pump();
  await gesture.up();
  await tester.pumpAndSettle();
}

/// Porta in vista [finder] nell'elenco delle impostazioni, partendo dall'alto.
Future<void> _reveal(WidgetTester tester, Finder finder) async {
  await tester.drag(find.byType(ListView).first, const Offset(0, 10000));
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find
        .descendant(
          of: find.byType(ListView),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.pumpAndSettle();
}

/// Pagina di sezione aperta nelle Impostazioni, `null` se si è nel menu.
String? _page;

/// Apre il menu delle Impostazioni.
Future<void> _openSettings(WidgetTester tester) async {
  _page = null;
  await tester.tap(find.byTooltip('Impostazioni'));
  await tester.pumpAndSettle();
}

/// Porta nella pagina di [name] (`board`, `game`, `style`, `accessibility`...),
/// tornando prima al menu se ne è aperta un'altra.
Future<void> _section(WidgetTester tester, String name) async {
  if (_page == name) return;
  if (_page != null) await _pop(tester);
  await tester.tap(find.byKey(Key('section-$name')));
  await tester.pumpAndSettle();
  _page = name;
}

/// Nella pagina Stile apre la scheda [tab] e sceglie la voce con chiave [key].
Future<void> _styleChoose(WidgetTester tester, String tab, Key key) async {
  await tester.tap(find.widgetWithText(Tab, tab));
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.byKey(key));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(key));
  await tester.pumpAndSettle();
}

Future<void> _tapSetting(WidgetTester tester, String label) async {
  final finder = find.text(label);
  await _reveal(tester, finder);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _pop(WidgetTester tester) async {
  final context = tester.element(find.byType(Scaffold).last);
  await tester.tap(
    find.byTooltip(MaterialLocalizations.of(context).backButtonTooltip),
  );
  await tester.pumpAndSettle();
}

/// Esce dalle Impostazioni, anche da una pagina di sezione.
Future<void> _back(WidgetTester tester) async {
  if (_page != null) await _pop(tester);
  _page = null;
  await _pop(tester);
}

/// [dragging] attiva anche il trascinamento: sul telefono il modo
/// predefinito usa solo i due tocchi.
Future<void> _start(WidgetTester tester, {bool dragging = false}) async {
  SharedPreferences.setMockInitialValues({
    'guideEnabled': false,
    if (dragging) 'moveMethod': 'both',
  });
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const RokkoApp());
  await tester.pumpAndSettle();
  await openBoard(tester);
}

const _scholarsMate = ['e2e4', 'e7e5', 'f1c4', 'b8c6', 'd1h5', 'g8f6', 'h5f7'];

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  useItalianDevice();

  testWidgets('RF-01 muove con due tocchi e con trascinamento', (tester) async {
    await _start(tester, dragging: true);
    expect(find.text('Muove il Bianco.'), findsOneWidget);
    await _tapMove(tester, 'e2e4');
    expect(find.text('Muove il Nero.'), findsOneWidget);
    await _dragMove(tester, 'e7e5');
    expect(find.text('Muove il Bianco.'), findsOneWidget);
    expect(find.text('1. e4'), findsOneWidget);
    expect(find.text('e5'), findsOneWidget);
  });

  testWidgets('RF-01 ignora una mossa illegale', (tester) async {
    await _start(tester);
    await _tapMove(tester, 'e2e5');
    expect(find.text('Muove il Bianco.'), findsOneWidget);
    expect(find.text('1. e5'), findsNothing);
  });

  testWidgets('RF-25 scacco matto, poi annullamento', (tester) async {
    await _start(tester);
    for (final m in _scholarsMate) {
      await _tapMove(tester, m);
    }
    expect(find.text('Scacco matto. Vince il Bianco.'), findsOneWidget);
    expect(find.text('4. ♛xf7#'), findsOneWidget);

    // Tra due persone chi ha il turno deve acconsentire.
    await tester.tap(find.text('Annulla'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Accetta'));
    await tester.pumpAndSettle();
    expect(find.text('Muove il Bianco.'), findsOneWidget);
    expect(find.text('4. ♛xf7#'), findsNothing);
  });

  testWidgets('RF-25 abbandono con conferma', (tester) async {
    await _start(tester);
    await _tapMove(tester, 'e2e4');
    await tapGameAction(tester, 'Abbandona');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Abbandona'));
    await tester.pumpAndSettle();
    expect(find.text('Abbandono. Vince il Bianco.'), findsOneWidget);
  });

  testWidgets('RF-32 patta concordata', (tester) async {
    await _start(tester);
    await _tapMove(tester, 'e2e4');
    await tapGameAction(tester, 'Patta');
    await tester.pumpAndSettle();
    expect(find.text('Il Bianco accetta la patta?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Accetta'));
    await tester.pumpAndSettle();
    expect(find.text('Patta concordata.'), findsOneWidget);
  });

  testWidgets('RF-06 gira la scacchiera', (tester) async {
    await _start(tester);
    Chessboard board() => tester.widget<Chessboard>(find.byType(Chessboard));
    expect(board().orientation.name, 'white');
    await tester.tap(find.text('Gira'));
    await tester.pumpAndSettle();
    expect(board().orientation.name, 'black');
  });

  testWidgets('RF-31 rotazione automatica a ogni turno', (tester) async {
    await _start(tester);
    Chessboard board() => tester.widget<Chessboard>(find.byType(Chessboard));
    await _openSettings(tester);
    await _section(tester, 'game');
    await _tapSetting(tester, 'Ruota a ogni turno');
    await _back(tester);
    await tester.pumpAndSettle();
    await _tapMove(tester, 'e2e4');
    expect(board().orientation.name, 'black');
  });

  testWidgets('un tocco fuori chiude il selettore di promozione', (
    tester,
  ) async {
    await _start(tester);
    for (final m in [
      'b2b4',
      'a7a5',
      'b4a5',
      'b7b6',
      'a5b6',
      'c7c6',
      'b6b7',
      'h7h6',
    ]) {
      await _tapMove(tester, m);
    }
    final selector = find.byWidgetPredicate(
      (w) => w.runtimeType.toString() == 'PromotionSelector',
    );
    await _tapMove(tester, 'b7a8');
    expect(selector, findsOneWidget);
    // Il selettore si chiude toccando fuori dai pezzi proposti.
    await tester.tapAt(_square(tester, 'h1'));
    await tester.pumpAndSettle();
    expect(selector, findsNothing);
  });

  testWidgets('RF-11 mostra i pezzi catturati e il vantaggio', (tester) async {
    await _start(tester);
    expect(find.byKey(const ValueKey('advantage-white')), findsNothing);
    for (final m in ['e2e4', 'd7d5', 'e4d5']) {
      await _tapMove(tester, m);
    }
    expect(find.byKey(const ValueKey('advantage-black')), findsNothing);
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('advantage-white'))).data,
      '+1',
    );
    expect(find.byKey(const ValueKey('captured-black-pawn-0')), findsOneWidget);
  });

  testWidgets('RP-04 impostazioni della scacchiera', (tester) async {
    await _start(tester);
    ChessboardSettings board() =>
        tester.widget<Chessboard>(find.byType(Chessboard)).settings;
    expect(board().enableCoordinates, isTrue);
    expect(board().showValidMoves, isTrue);

    await _openSettings(tester);
    await _section(tester, 'board');
    await _tapSetting(tester, 'Coordinate');
    await _tapSetting(tester, 'Mostra le mosse legali');
    await _reveal(tester, find.text('Nessuna'));
    await tester.tap(find.text('Nessuna'));
    await _section(tester, 'game');
    await _tapSetting(tester, 'Promuovi sempre a donna');
    await tester.pumpAndSettle();
    await _section(tester, 'style');
    await _styleChoose(tester, 'Scacchiera', const Key('theme-swatch-blue'));
    await _styleChoose(tester, 'Pezzi', const Key('piece-tile-merida'));
    await _back(tester);
    await tester.pumpAndSettle();

    expect(board().enableCoordinates, isFalse);
    expect(board().showValidMoves, isFalse);
    expect(board().autoQueenPromotion, isTrue);
    expect(board().colorScheme, BoardTheme.blue.colorScheme);
    expect(board().pieceAssets, PieceSet.meridaAssets);
    expect(board().animationDuration, Duration.zero);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('showCoordinates'), isFalse);
    expect(prefs.getString('boardTheme'), 'blue');
  });

  testWidgets('RP-04 anteprima delle impostazioni', (tester) async {
    await _start(tester);
    await _openSettings(tester);
    await _section(tester, 'style');
    final preview = find.byKey(const Key('board-preview'));
    StaticChessboard board() => tester.widget<StaticChessboard>(
      find.descendant(of: preview, matching: find.byType(StaticChessboard)),
    );
    expect(board().settings.colorScheme, BoardTheme.spazio.colorScheme);
    final top = tester.getTopLeft(preview);

    await _styleChoose(tester, 'Scacchiera', const Key('theme-swatch-blue'));
    expect(board().settings.colorScheme, BoardTheme.blue.colorScheme);
    await _styleChoose(tester, 'Pezzi', const Key('piece-tile-merida'));
    expect(board().settings.pieceAssets, PieceSet.meridaAssets);
    expect(tester.getTopLeft(preview), top);

    final start = board().fen;
    await tester.tap(preview);
    await tester.pumpAndSettle();
    expect(board().fen, isNot(start));
    await tester.tap(preview);
    await tester.pumpAndSettle();
    expect(board().fen, start);
  });

  testWidgets('RF-06 cambiare il tema non annulla il capovolgimento', (
    tester,
  ) async {
    await _start(tester);
    Chessboard board() => tester.widget<Chessboard>(find.byType(Chessboard));
    await _openSettings(tester);
    await _section(tester, 'game');
    await _tapSetting(tester, 'Ruota a ogni turno');
    await _back(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gira'));
    await tester.pumpAndSettle();
    expect(board().orientation.name, 'black');
    await _openSettings(tester);
    await _section(tester, 'style');
    await _styleChoose(tester, 'Scacchiera', const Key('theme-swatch-blue'));
    await _back(tester);
    await tester.pumpAndSettle();
    expect(board().orientation.name, 'black');
  });

  testWidgets('RF-40 nuova partita con orologio', (tester) async {
    await _start(tester);
    expect(find.byKey(const ValueKey('clock-white')), findsNothing);
    await tapGameAction(tester, 'Nuova');
    await tester.pumpAndSettle();
    await openCustomSheet(tester, two: true);
    expect(find.text('Senza tempo'), findsOneWidget);
    await tester.tap(find.text('3+2'));
    await tester.pumpAndSettle();
    Text clock(Side side) =>
        tester.widget<Text>(find.byKey(ValueKey('clock-${side.name}')));
    expect(clock(Side.white).data, '3:00');
    expect(clock(Side.black).data, '3:00');
    expect(find.byKey(const ValueKey('clock-active')), findsNothing);

    await _tapMove(tester, 'e2e4');
    final active = find.byKey(const ValueKey('clock-active'));
    expect(
      find.descendant(
        of: active,
        matching: find.byKey(const ValueKey('clock-black')),
      ),
      findsOneWidget,
    );
    await tester.pump(const Duration(milliseconds: 300));

    await tapGameAction(tester, 'Nuova');
    await tester.pumpAndSettle();
    await openCustomSheet(tester, two: true);
    await tester.tap(find.text('Senza tempo'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('clock-white')), findsNothing);
  });

  testWidgets('RF-31 RP-03 modalità tavolo, suoni e vibrazione', (
    tester,
  ) async {
    await _start(tester);
    ChessboardSettings board() =>
        tester.widget<Chessboard>(find.byType(Chessboard)).settings;
    expect(
      board().pieceOrientationBehavior,
      PieceOrientationBehavior.facingUser,
    );
    await _openSettings(tester);
    await _section(tester, 'game');
    await _tapSetting(tester, 'Modalità tavolo');
    await _section(tester, 'board');
    await _reveal(tester, find.text('Suoni'));
    await tester.ensureVisible(find.text('Suoni'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Suoni'));
    await tester.pumpAndSettle();
    await _reveal(tester, find.text('Vibrazione'));
    await tester.ensureVisible(find.text('Vibrazione'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vibrazione'));
    await tester.pumpAndSettle();
    await _back(tester);
    await tester.pumpAndSettle();
    expect(
      board().pieceOrientationBehavior,
      PieceOrientationBehavior.opponentUpsideDown,
    );
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('sound'), isFalse);
    expect(prefs.getBool('haptics'), isFalse);
    await _tapMove(tester, 'e2e4');
    expect(find.text('Muove il Nero.'), findsOneWidget);
  });

  testWidgets('RF-09 conferma della mossa', (tester) async {
    await _start(tester);
    await _openSettings(tester);
    await _section(tester, 'accessibility');
    await _reveal(tester, find.text('Conferma la mossa'));
    await tester.tap(find.text('Conferma la mossa'));
    await tester.pumpAndSettle();
    await _back(tester);
    await tester.pumpAndSettle();

    await _tapMove(tester, 'e2e4');
    expect(find.text('Conferma'), findsOneWidget);
    expect(find.text('1. e4'), findsNothing);
    await tester.tap(find.text('Scarta'));
    await tester.pumpAndSettle();
    expect(find.text('Conferma'), findsNothing);
    expect(find.text('Muove il Bianco.'), findsOneWidget);

    await _tapMove(tester, 'd2d4');
    await tester.tap(find.text('Conferma'));
    await tester.pumpAndSettle();
    expect(find.text('Muove il Nero.'), findsOneWidget);
    expect(find.text('1. d4'), findsOneWidget);

    await _tapMove(tester, 'd7d5');
    await tester.tap(find.text('Annulla'));
    await tester.pumpAndSettle();
    expect(find.text('Conferma'), findsNothing);
    expect(find.text('1. d4'), findsOneWidget);
    expect(find.text('Muove il Nero.'), findsOneWidget);

    await _tapMove(tester, 'd7d5');
    await tapGameAction(tester, 'Abbandona');
    await tester.pumpAndSettle();
    expect(find.text('Abbandonare la partita?'), findsNothing);
  });

  testWidgets('RNF-07 evidenziazioni per daltonici', (tester) async {
    await _start(tester);
    ChessboardColorScheme scheme() =>
        tester.widget<Chessboard>(find.byType(Chessboard)).settings.colorScheme;
    final safe = BoardTheme.spazio.colorBlindScheme;
    expect(scheme().lastMove, isNot(safe.lastMove));
    await _openSettings(tester);
    await _section(tester, 'accessibility');
    await _reveal(tester, find.text('Colori per daltonici'));
    await tester.ensureVisible(find.text('Colori per daltonici'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Colori per daltonici'));
    await tester.pumpAndSettle();
    await _back(tester);
    await _tapMove(tester, 'e2e4');
    expect(scheme(), same(safe));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('colorBlind'), isTrue);
  });

  testWidgets('RF-10 scorrimento orizzontale sulla scacchiera', (tester) async {
    await _start(tester, dragging: true);
    await _tapMove(tester, 'e2e4');
    await _tapMove(tester, 'e7e5');
    await _tapMove(tester, 'g1f3');

    Future<void> swipe(double dx) async {
      await tester.dragFrom(_square(tester, 'd5'), Offset(dx, 0));
      await tester.pumpAndSettle();
    }

    await swipe(150);
    expect(find.text('Posizione dopo 1... e5'), findsOneWidget);
    await swipe(150);
    expect(find.text('Posizione dopo 1. e4'), findsOneWidget);
    await swipe(-150);
    await swipe(-150);
    expect(find.text('Posizione dopo 2. ♞f3'), findsOneWidget);
    await swipe(-150);
    expect(find.textContaining('Posizione dopo'), findsNothing);
    expect(find.text('Muove il Nero.'), findsOneWidget);

    // Partendo dal pezzo da muovere si trascina il pezzo, senza scorrere.
    await _dragMove(tester, 'b8c6');
    expect(find.textContaining('Posizione dopo'), findsNothing);
    expect(find.text('Muove il Bianco.'), findsOneWidget);
  });

  testWidgets('RF-10 navigazione nella lista delle mosse', (tester) async {
    await _start(tester);
    for (final m in ['e2e4', 'e7e5', 'g1f3']) {
      await _tapMove(tester, m);
    }
    String fen() =>
        tester.widget<Chessboard>(find.byType(Chessboard)).controller.game.fen;
    final live = fen();

    await tester.tap(find.text('1. e4'));
    await tester.pumpAndSettle();
    expect(find.text('Posizione dopo 1. e4'), findsOneWidget);
    expect(
      fen(),
      startsWith('rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b'),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(find.text('Posizione dopo 1... e5'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(find.text('Posizione iniziale'), findsOneWidget);

    await _tapMove(tester, 'd2d4');
    expect(find.text('Posizione iniziale'), findsOneWidget);

    await tester.tap(find.text('Torna alla partita'));
    await tester.pumpAndSettle();
    expect(fen(), live);
    expect(find.text('Muove il Nero.'), findsOneWidget);

    await tester.tap(find.text('1. e4'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.pumpAndSettle();
    expect(find.text('Muove il Nero.'), findsOneWidget);

    await tester.tap(find.text('2. ♞f3'));
    await tester.pumpAndSettle();
    expect(find.text('Posizione dopo 2. ♞f3'), findsOneWidget);
    await tester.tap(find.text('Annulla'));
    await tester.pumpAndSettle();
    expect(fen(), live);
    expect(find.text('2. ♞f3'), findsOneWidget);
  });

  testWidgets('RNF-07 mossa scritta da tastiera', (tester) async {
    await _start(tester);
    Future<void> type(String text) async {
      await tester.tap(find.byTooltip('Altre azioni'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mossa da tastiera'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), text);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
    }

    await type('e4');
    expect(find.text('1. e4'), findsOneWidget);
    await type('Cf6');
    expect(find.text('♞f6'), findsOneWidget);

    await type('e6');
    expect(find.text('Mossa non valida'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'e5');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text('2. e5'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);

    await type('');
    await tester.tap(find.text('Annulla').last);
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
    expect(find.text('Muove il Nero.'), findsOneWidget);
  });

  testWidgets('RF-30 nomi dei giocatori', (tester) async {
    await _start(tester);
    await tapGameAction(tester, 'Nuova');
    await tester.pumpAndSettle();
    await openCustomSheet(tester, two: true);
    await tester.enterText(
      find.widgetWithText(TextField, 'Nome del Bianco'),
      'Anna',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Nome del Nero'),
      'Bruno',
    );
    await tester.tap(find.text('Senza tempo'));
    await tester.pumpAndSettle();
    expect(find.text('Muove Anna (Bianco).'), findsOneWidget);
    String nameAt(String side) =>
        tester.widget<Text>(find.byKey(ValueKey('player-$side'))).data!;
    expect(nameAt('white'), 'Anna');
    expect(nameAt('black'), 'Bruno');
    final boardTop = tester.getTopLeft(find.byType(Chessboard)).dy;
    expect(
      tester.getCenter(find.byKey(const ValueKey('player-black'))).dy,
      lessThan(boardTop),
    );
    expect(
      tester.getCenter(find.byKey(const ValueKey('player-white'))).dy,
      greaterThan(boardTop),
    );

    for (final m in _scholarsMate) {
      await _tapMove(tester, m);
    }
    expect(find.text('Scacco matto. Vince Anna (Bianco).'), findsOneWidget);

    await tapGameAction(tester, 'Nuova');
    await tester.pumpAndSettle();
    await openCustomSheet(tester, two: true);
    expect(
      tester
          .widget<TextField>(find.widgetWithText(TextField, 'Nome del Nero'))
          .controller!
          .text,
      'Bruno',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Nome del Bianco'),
      '',
    );
    await tester.enterText(find.widgetWithText(TextField, 'Nome del Nero'), '');
    await tester.tap(find.text('Senza tempo'));
    await tester.pumpAndSettle();
    expect(find.text('Muove il Bianco.'), findsOneWidget);
    expect(find.byKey(const ValueKey('player-white')), findsNothing);
  });

  testWidgets('RP-02 tema scuro scelto nelle impostazioni', (tester) async {
    await _start(tester);
    Brightness brightness() =>
        Theme.of(tester.element(find.byType(Chessboard))).brightness;
    expect(brightness(), Brightness.light);

    await _openSettings(tester);
    await _section(tester, 'accessibility');
    await _tapSetting(tester, 'Scuro');
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.text('Accessibilità').last)).brightness,
      Brightness.dark,
    );
    await _back(tester);
    await tester.pumpAndSettle();
    expect(brightness(), Brightness.dark);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('themeMode'), 'dark');
  });
}

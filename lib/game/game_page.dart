import 'dart:async';
import 'dart:math' as math;

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../analysis/analysis_page.dart';
import '../archive/pgn.dart';
import '../archive/saved_game.dart';
import '../bot_gallery/game_options.dart';
import '../coach/coach_session.dart';
import '../coach/explain_why.dart';
import '../coach/hint_text.dart';
import '../coach/opening_coach.dart';
import '../editor/position_editor_page.dart';
import '../engine/adaptive.dart';
import '../engine/bot_collection.dart';
import '../engine/bots.dart';
import '../engine/computer_player.dart';
import '../engine/levels.dart';
import '../engine/uci.dart';
import '../engine/uci_transport.dart';
import '../engine/variant_engine.dart';
import '../exchange/qr_l10n.dart';
import '../exchange/qr_receive_page.dart';
import '../exchange/qr_send_page.dart';
import '../exchange/qr_transfer.dart';
import '../guide/guide_host.dart';
import '../guide/guide_steps.dart';
import '../l10n/app_localizations.dart';
import '../multiplayer/multiplayer_page.dart';
import '../openings/explorer_page.dart';
import '../openings/opening_assets.dart';
import '../openings/opening_book.dart';
import '../openings/opening_game.dart';
import '../openings/opening_game_dialog.dart';
import '../openings/opening_name.dart';
import '../openings/opening_stats.dart';
import '../progress/activity.dart';
import '../progress/avatar.dart';
import '../progress/game_activity.dart';
import '../progress/progress_controller.dart';
import '../progress/progress_feedback.dart';
import '../puzzles/activity_recorder.dart';
import '../review/board_utils.dart';
import '../review/engine_evaluator.dart';
import '../review/eval_bar.dart';
import '../review/game_review.dart';
import '../review/move_classification.dart';
import '../review/personal_puzzles.dart';
import '../review/review_activity.dart';
import '../review/review_page.dart';
import '../review/win_probability.dart';
import '../settings/board_frame.dart';
import '../settings/notation.dart';
import '../settings/settings.dart';
import '../settings/settings_page.dart';
import '../share/position_image.dart';
import '../share/position_image_page.dart';
import '../storage/key_value_store.dart';
import '../tablebase/shared_tablebase.dart';
import '../theme/motion.dart';
import '../theme/rokko_icons.dart';
import '../theme/rokko_mascot.dart';
import '../theme/rokko_theme.dart';
import '../theme/sheets.dart';
import 'board_drawing.dart';
import 'board_swipe.dart';
import 'challenge.dart';
import 'chess_game.dart';
import 'clock.dart';
import 'clock_l10n.dart';
import 'custom_clock_dialog.dart';
import 'handicap.dart';
import 'material.dart';
import 'move_input.dart';
import 'move_label.dart';
import 'move_speech.dart';
import 'opponent_picker.dart';
import 'sounds.dart';
import 'speech_bubble.dart';
import 'tap_assist.dart';
import 'variant.dart';

/// Semimosse minime perché una partita valga XP: abbandonare subito non deve
/// far guadagnare nulla.
const _minPliesForProgress = 4;

/// Tempo massimo di una partita che conta per l'obiettivo a minuti, per non
/// gonfiarlo con le pause (app in background, finestre aperte).
const _maxCountedPlay = Duration(hours: 1);

/// Partita tra due persone sullo stesso dispositivo o contro il computer.
class GamePage extends StatefulWidget {
  GamePage({
    super.key,
    required this.settings,
    this.chess960Id = randomChess960Id,
    bool? computerAvailable,
    this.createComputer,
    this.createVariantEngine,
    this.now,
    this.random,
    this.onActivity,
    this.onSave,
    this.resume,
    this.progress,
    this.challenge,
    this.openingBook,
    this.openingStats,
    this.onFinished,
    this.store,
    this.qrScanner = zxingScanner,
    this.keepAwake,
    this.onSavePuzzles,
    this.openSetup = false,
    this.initialSetup,
    this.tournamentPage,
    this.physicalPage,
    this.openingGame,
  }) : computerAvailable = computerAvailable ?? StockfishTransport.isSupported;

  final SettingsController settings;
  final bool computerAvailable;

  /// Pagine dei tornei e della scacchiera fisica, offerte dal foglio «Nuova
  /// partita»; senza, quelle voci non ci sono.
  final Future<Widget> Function()? tournamentPage;
  final Widget Function()? physicalPage;

  /// Avvia la partita con l'istruttore (come dal menu Aperture); senza, la voce
  /// «Gioca con l'istruttore» del foglio accende l'allenatore nella partita.
  final Future<void> Function(BuildContext, OpeningGameRequest)? openingGame;
  final ComputerPlayer Function()? createComputer;

  /// Avversario di Chess960, Re della collina e Tre scacchi (RF-123).
  final VariantEngine Function()? createVariantEngine;

  /// Archivio della stima dell'avversario adattivo; quello su file se assente.
  final KeyValueStore? store;

  /// Ora corrente per l'orologio; quella di sistema se assente.
  final DateTime Function()? now;

  /// Fonte del caso per le battute del bot; fissa nei golden.
  final math.Random? random;

  /// Registra la partita finita nei progressi; senza, nessun XP.
  final ActivityRecorder? onActivity;

  /// Salva la partita finita nell'archivio; senza, nessun salvataggio.
  final Future<void> Function(SavedGame game)? onSave;

  /// Partita non conclusa dell'archivio da riprendere: si rimette in campo
  /// con lo stesso `id`, senza orologio, e il computer risponde se tocca a lui.
  final SavedGame? resume;

  /// Partita già impostata da un'altra schermata: parte subito e non si può
  /// ricominciare.
  final GameChallenge? challenge;

  /// Libro e statistiche delle aperture per l'istruttore; di default quelli
  /// inclusi nell'app.
  final Future<OpeningBook>? openingBook;
  final Future<OpeningStats?>? openingStats;

  /// Esito per l'utente e mosse complete giocate, a fine partita contro il
  /// computer, una volta per partita (sfide).
  final void Function(GameResult result, int moves)? onFinished;

  /// Progressi da mostrare nelle impostazioni (temi e ricompense da sbloccare).
  final Future<ProgressController> Function()? progress;

  /// Salva i puzzle ricavati dagli errori della revisione.
  final Future<int> Function(List<MistakePuzzle> puzzles)? onSavePuzzles;

  /// Apre subito la scelta di «Nuova partita», per chi arriva dal pulsante
  /// «Nuova partita» della Home.
  final bool openSetup;

  /// Scelta dell'avversario già selezionata nel foglio di «Nuova partita».
  final GameSetup? initialSetup;

  /// Sceglie la posizione Chess960; sostituibile nei test.
  final int Function() chess960Id;

  /// Lettore QR per continuare una partita passata da un altro telefono.
  final QrScannerBuilder qrScanner;

  /// Tiene lo schermo acceso; di default il blocco dello schermo del sistema.
  final Future<void> Function(bool awake)? keepAwake;

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> with WidgetsBindingObserver {
  /// La guida alla prima apertura è aperta sopra la partita.
  bool _guideOpen = false;

  ChessGame _game = ChessGame();

  /// Vero mentre si disegna una freccia, per non scambiarla per uno scorrimento.
  final _drawing = ValueNotifier(false);
  late final ChessboardController _board = ChessboardController(
    game: _gameData(),
  );
  Side _orientation = Side.white;

  /// Partita i cui XP sono già stati assegnati, per farlo una volta sola.
  ChessGame? _recordedGame;

  /// Esito già comunicato a [GamePage.onFinished]; dopo un annulla la partita
  /// riprende e l'esito nuovo sostituisce il precedente.
  String? _reportedEnding;

  /// Ultimo stato salvato nell'archivio (partita, esito, mosse).
  String? _archivedKey;

  /// Ultima revisione, legata alla partita e al numero di semimosse: i
  /// salvataggi successivi della stessa partita non perdono la precisione.
  ({String id, int plies, GameReview review})? _reviewed;
  late DateTime _startedAt = _clockNow();
  late String _gameId = 'game-${_startedAt.microsecondsSinceEpoch}';
  var _fromEditor = false;
  late GameSetup _setup = widget.initialSetup ?? const GameSetup();
  AdaptiveOpponent _adaptive = const AdaptiveOpponent();

  /// Stima prima dell'esito della partita in corso, per ripristinarla se si annulla.
  AdaptiveOpponent _adaptiveBefore = const AdaptiveOpponent();
  Future<KeyValueStore>? _store;

  /// Suggerimenti del primo uso già visti; [_tipsDone] li spegne per sempre.
  int _tipsSeen = 0;
  bool _tipsDone = false;
  bool _reviewInviteDone = false;

  /// Livello della partita in corso contro il computer.
  int _gameLevel = defaultEngineLevel;
  bool _resultRecorded = false;

  /// Bot della partita in corso, `null` contro il computer o tra due persone.
  Bot? _bot;
  BotCollection _collection = const BotCollection();
  BotCollection _collectionBefore = const BotCollection();
  bool _botResultRecorded = false;

  /// Profilo bambino all'inizio della partita: bot, titolo e frasi restano
  /// coerenti anche se l'impostazione cambia a partita in corso.
  bool _kidGame = false;

  /// Handicap della partita in corso (RF-27) e colore di chi gioca, da cui
  /// dipende chi lo concede.
  Handicap? _handicap;
  Side _handicapHuman = Side.white;

  /// Ultima variante scelta nel pannello Nuova, con persone o contro il computer.
  Variant _chosenVariant = Variant.standard;
  late final math.Random _random = widget.random ?? math.Random();

  /// Lato giocato dal computer; `null` nella partita tra due persone.
  Side? _computerSide;
  ComputerPlayer? _computer;
  VariantEngine? _variantEngine;

  /// Allenatore in partita (RF-73): giudica le mosse dell'utente.
  bool _coachOn = false;

  /// Giudizio dell'allenatore sull'ultima mossa dell'utente (RF-72): il
  /// simbolo sulla casa d'arrivo, come nella revisione.
  ({int ply, Square square, MoveClass verdict})? _badge;
  String? _hintedFen;
  Set<Shape> _hintShapes = const {};
  String? _threatFen;
  Set<Shape> _threatShapes = const {};
  late CoachSession _coach = _newCoach();

  CoachSession _newCoach() => CoachSession(
    evaluate: (fen) => _computerPlayer.analyse(fen, depth: 12, multiPv: 2),
  );
  _ComputerTask _task = _ComputerTask.none;
  bool get _thinking => _task != _ComputerTask.none;

  /// Invalida le risposte del computer per posizioni non più attuali.
  int _generation = 0;

  /// Orologio all'inizio della riflessione del computer in corso.
  Map<Side, Duration>? _searchClock;

  /// Sospensioni attive (finestre aperte, app in background).
  int _suspensions = 0;
  bool _clockBeforeSuspension = false;
  bool _inBackground = false;
  ChessClock? _clock;
  Timer? _ticker;
  final List<Map<Side, Duration>> _clockHistory = [];
  final ValueNotifier<int> _tick = ValueNotifier(0);
  final SoundPlayer _sounds = SoundPlayer();
  final LowTimeAlarm _lowTime = LowTimeAlarm();
  Move? _pendingMove;

  /// Semimossa visualizzata (-1 = posizione iniziale), null = partita in corso.
  int? _viewPly;

  AppSettings get _settings => widget.settings.value;

  /// Modalità zen (RP-07): niente Elo, materiale, stato, avvisi e commenti.
  bool get _zen => _settings.zenMode;

  /// L'allenatore giudica solo fuori dalla modalità zen; lo stato resta.
  bool get _coaching => _coachOn && !_zen;

  late bool _autoFlip;

  /// Profilo bambino (RP-06): testi semplici e comandi essenziali.
  bool get _kid => _settings.kidMode;

  /// Avversario a inizio frase nei testi del profilo bambino.
  String _kidOpponent(AppLocalizations l) => _bot?.name ?? l.kidGameComputer;

  /// Stato della partita da annunciare, semplice nel profilo bambino.
  String _statusMessage() => _kid
      ? _kidStatus(_l10n(context)).text
      : statusText(_l10n(context), _game, _nameOf);

  /// Frase breve sullo stato; [celebrate] quando vince il giocatore (o
  /// chiunque, tra due persone), per la festa solo a schermo.
  ({String text, bool celebrate}) _kidStatus(AppLocalizations l) {
    final game = _game;
    final player = _computerSide?.opposite;
    final opponent = _kidOpponent(l);
    final turn = game.position.turn;
    final reason = game.endReason;
    if (reason == null) {
      final check = game.position.isCheck;
      final text = player != null
          ? (check
                ? (turn == player ? l.kidGameCheckYou : l.kidGameCheckOpponent)
                : (turn == player
                      ? l.kidGameYourTurn
                      : l.kidGameOpponentTurn(opponent)))
          : switch (_nameOf(turn)) {
              null when check => l.kidGameCheckSide(turn.name),
              null => l.kidGameTurnSide(turn.name),
              final name when check => l.kidGameCheckName(name),
              final name => l.kidGameTurnName(name),
            };
      return (text: text, celebrate: false);
    }
    final winner = game.outcome?.winner;
    if (winner == null) {
      final text = switch (reason) {
        GameEndReason.stalemate => l.kidGameStalemate,
        GameEndReason.insufficientMaterial => l.kidGameInsufficientMaterial,
        GameEndReason.threefoldRepetition => l.kidGameRepetition,
        GameEndReason.fiftyMoveRule => l.kidGameFiftyMoves,
        GameEndReason.agreement => l.kidGameAgreedDraw,
        GameEndReason.timeout => l.kidGameTimeUpDraw,
        _ => l.kidGameOver,
      };
      return (text: text, celebrate: false);
    }
    final loser = winner.opposite;
    final cause = switch (reason) {
      GameEndReason.checkmate => l.kidGameCheckmate,
      GameEndReason.timeout => l.kidGameTimeUp,
      GameEndReason.resignation =>
        player != null
            ? (loser == player ? l.kidGameYouResigned : l.kidGameOver)
            : switch (_nameOf(loser)) {
                null => l.kidGameResignedSide(loser.name),
                final name => l.kidGameResignedName(name),
              },
      GameEndReason.variantEnd => switch (game.variant) {
        Variant.kingOfTheHill => l.kidGameKingOfTheHill,
        Variant.threeCheck => l.kidGameThirdCheck,
        Variant.standard || Variant.chess960 => l.kidGameOver,
      },
      _ => l.kidGameOver,
    };
    final result = player != null
        ? (winner == player ? l.kidGameYouWon : l.kidGameOpponentWon(opponent))
        : switch (_nameOf(winner)) {
            null => l.kidGameWinnerSide(winner.name),
            final name => l.kidGameWinnerName(name),
          };
    return (
      text: '$cause $result',
      celebrate: player == null || winner == player,
    );
  }

  /// Nomi dei giocatori: solo nella partita tra due persone.
  String? _nameOf(Side side) =>
      _computerSide == null ? _settings.nameOf(side) : null;

  @override
  void initState() {
    super.initState();
    _autoFlip = _settings.autoFlip;
    _training = _trainingDefault;
    widget.settings.addListener(_onSettingsChanged);
    WidgetsBinding.instance.addObserver(this);
    unawaited(_loadProfile());
    // Il libro serve a fine partita per i libri delle aperture.
    openingBook().ignore();
    if (_isChallenge) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _startChallenge());
    } else if (widget.resume != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _resumeSaved());
    } else if (widget.openSetup) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        final before = _game;
        await _newGame();
        // Chiusa la scelta senza partita, si torna da dove si era partiti.
        if (mounted && identical(before, _game)) {
          unawaited(Navigator.of(context).maybePop());
        }
      });
    }
  }

  /// Rimette in campo la partita salvata. Il livello del computer è quello più
  /// vicino all'Elo registrato; i bot con personalità non si ripristinano.
  void _resumeSaved() {
    final saved = widget.resume;
    if (!mounted || saved == null) return;
    final game = importPgn(saved.pgn).games.firstOrNull?.game;
    if (game == null || game.isOver) return;
    final side = saved.playerSide;
    // L'archivio non ricorda la modalità: si riprende con l'ultima scelta.
    _training = _trainingDefault;
    final setup = _applySetup(
      side == null
          ? const GameSetup()
          : GameSetup(
              opponent: Opponent.computer,
              sideChoice: side == Side.white
                  ? SideChoice.white
                  : SideChoice.black,
              level: engineLevelForElo(saved.opponentElo ?? 1200).id,
            ),
    );
    _beginGame(game, setup, null, resumeOf: saved);
  }

  bool get _isChallenge => widget.challenge != null;

  /// Partita con l'istruttore: aiuti accesi e commento sull'apertura.
  bool get _instructor => widget.challenge?.instructor ?? false;

  /// Allenamento (RF-22) contro i bot: aiuti, ma niente Elo né vittorie. Fuori
  /// dall'Allenamento è Sfida. Il profilo bambino si allena sempre.
  bool _training = false;

  bool get _trainingDefault => _settings.kidMode || _settings.trainingMode;

  /// Le sfide del percorso non hanno modalità: contano sempre.
  bool get _inTraining => !_isChallenge && (_training || _kid);

  /// Niente aiuti nelle sfide (tranne con l'istruttore) né nella Sfida.
  bool get _helpAllowed =>
      _instructor || (!_isChallenge && (_inTraining || _computerSide == null));

  /// Suggerisci anche nelle sfide che lo concedono (guardiani, custodi).
  bool get _hintAllowed =>
      _helpAllowed || (widget.challenge?.allowHints ?? false);

  OpeningBook? _instructorBook;
  OpeningStats? _instructorStats;

  Future<void> _loadInstructor() async {
    final OpeningBook book;
    final OpeningStats? stats;
    try {
      book = await (widget.openingBook ?? openingBook());
      stats = await (widget.openingStats ?? openingStatsOrNull());
    } on Object {
      // Senza libro l'istruttore resta il solo allenatore.
      return;
    }
    if (!mounted) return;
    _instructorBook = book;
    _instructorStats = stats;
    _instructorSay();
  }

  /// Commento dell'istruttore sull'apertura: nome, mosse più giocate, uscita
  /// dal libro.
  void _instructorSay() {
    final book = _instructorBook;
    if (!_instructor ||
        book == null ||
        _zen ||
        _game.variant != Variant.standard) {
      return;
    }
    final note = openingNote(book, _instructorStats, [
      for (final m in _game.moves) m.move,
    ]);
    if (note == null) return;
    final l = _l10n(context);
    String list(List<OpeningChoice> choices) =>
        [for (final c in choices) '${c.san} (${c.percent}%)'].join(', ');
    final text = switch (note) {
      InBookNote(:final opening, :final choices) =>
        opening != null && choices.isNotEmpty
            ? l.instructorInBookNamed(opening.localName, list(choices))
            : opening != null
            ? l.instructorInBookNameOnly(opening.localName)
            : choices.isNotEmpty
            ? l.instructorInBook(list(choices))
            : null,
      LeftBookNote(:final playedSan, :final by, :final expected) =>
        by == _computerSide
            ? l.instructorLeftComputer(playedSan)
            : expected.isEmpty
            ? l.instructorLeftYouBare(playedSan)
            : l.instructorLeftYou(playedSan, list(expected)),
    };
    if (text == null) return;
    _say(
      Speech(
        text,
        expression: note is LeftBookNote
            ? AvatarExpression.surprised
            : AvatarExpression.encouraging,
      ),
      duration: const Duration(seconds: 12),
    );
  }

  /// Apre l'esploratore sulla posizione raggiunta.
  void _openExplorer() {
    final moves = [for (final m in _game.moves) m.move];
    // Con l'esploratore aperto orologio e computer restano fermi.
    unawaited(
      _whileSuspended<void>(
        () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ExplorerPage(
              book: widget.openingBook,
              stats: widget.openingStats ?? openingStatsOrNull(),
              initialMoves: moves,
            ),
          ),
        ),
      ),
    );
  }

  /// Una sfida non ha ancora iniziato la partita: fino ad allora la scacchiera
  /// non accetta mosse.
  late bool _awaitingChallenge = _isChallenge;

  void _startChallenge() {
    final challenge = widget.challenge;
    if (!mounted || challenge == null) return;
    _awaitingChallenge = false;
    final setup = _applySetup(
      GameSetup(
        opponent: Opponent.computer,
        sideChoice: challenge.side == Side.white
            ? SideChoice.white
            : SideChoice.black,
        level: challenge.levelId,
      ),
    );
    // Mosse iniziali non valide: si parte dalla posizione iniziale.
    final game = challenge.startMoves.isEmpty
        ? null
        : ChessGame.replay(Chess.initial, challenge.startMoves);
    _beginGame(game ?? ChessGame(), setup, null);
    if (_instructor && _engineGame && !_zen) {
      setState(() => _coachOn = true);
      unawaited(_loadInstructor());
    }
  }

  int? _lineDeviationNow() {
    final line = widget.challenge?.line;
    return line == null
        ? null
        : lineDeviation(line, [for (final m in _game.moves) m.move]);
  }

  /// Semimossa già segnalata come uscita dalla linea del repertorio.
  int? _reportedDeviation;

  /// Segnala una volta l'uscita dalla linea del repertorio (RF-94); dopo un
  /// annulla che rientra nella linea la segnalazione si riarma.
  void _checkLine() {
    if (_zen) return;
    final ply = _lineDeviationNow();
    if (ply == _reportedDeviation) return;
    _reportedDeviation = ply;
    if (ply == null) return;
    final by = ply.isEven ? Side.white : Side.black;
    final notice = _showMessage(
      by == _computerSide
          ? _l10n(context).gameLineLeftComputer
          : _l10n(context).gameLineLeftYou,
    );
    _lineNotice = notice;
    // Il messaggio dell'utente deve restare visibile anche se subito dopo
    // risponde il computer.
    unawaited(
      notice.closed.then((_) {
        if (identical(_lineNotice, notice)) _lineNotice = null;
      }),
    );
  }

  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? _lineNotice;

  Future<void> _saveTips(int value) async {
    setState(() {
      _tipsSeen = value;
      _tipsDone = value >= _tipsDoneMark;
    });
    await (await _openStore()).write(_tipsKey, '$value');
  }

  Future<void> _dismissReviewInvite() async {
    setState(() => _reviewInviteDone = true);
    await (await _openStore()).write(_reviewInviteKey, '1');
  }

  /// Invito alla revisione a fine prima partita, altrimenti il suggerimento
  /// del primo uso; `null` quando non serve niente.
  Widget? _banner(BuildContext context) {
    final l10n = _l10n(context);
    if (_kid || _isChallenge || _zen) return null;
    if (_game.isOver) {
      if (_reviewInviteDone ||
          !widget.computerAvailable ||
          _game.variant != Variant.standard ||
          _game.moves.length < 4) {
        return null;
      }
      return _TipCard(
        key: const ValueKey('reviewInvite'),
        text: l10n.gameReviewInvite,
        actionLabel: l10n.gameReviewInviteAction,
        onAction: () {
          unawaited(_dismissReviewInvite());
          _openReview();
        },
        closeLabel: l10n.gameTipClose,
        onClose: _dismissReviewInvite,
      );
    }
    if (_tipsDone || _game.moves.isEmpty) return null;
    // Il numero salvato è la posizione nell'elenco completo (aiuto, altro,
    // menu): un suggerimento che non vale per questa partita non sposta gli altri.
    final tips = <(int, String)>[
      if (_computerSide != null && _engineGame) (0, l10n.gameTipHint),
      (1, l10n.gameTipMore),
      if (widget.computerAvailable) (2, l10n.gameTipMenu),
    ].where((t) => t.$1 >= _tipsSeen).toList();
    if (tips.isEmpty) return null;
    final tip = tips.first;
    return _TipCard(
      key: const ValueKey('gameTip'),
      text: tip.$2,
      actionLabel: tips.length == 1 ? null : l10n.gameTipNext,
      onAction: () => unawaited(_saveTips(tip.$1 + 1)),
      closeLabel: l10n.gameTipClose,
      onClose: () => unawaited(_saveTips(_tipsDoneMark)),
    );
  }

  Future<KeyValueStore> _openStore() => _store ??= () async {
    if (widget.store != null) return widget.store!;
    try {
      return await JsonFileStore.open();
    } on Object catch (_) {
      return MemoryStore();
    }
  }();

  Future<void> _loadProfile() async {
    final store = await _openStore();
    final adaptive = await AdaptiveOpponent.load(store)
        .catchError((_) => const AdaptiveOpponent());
    final collection = await BotCollection.load(store)
        .catchError((_) => const BotCollection());
    final tips =
        int.tryParse(
          await store.read(_tipsKey).catchError((_) => null) ?? '',
        ) ??
        0;
    final invited =
        await store.read(_reviewInviteKey).catchError((_) => null) != null;
    if (!mounted) return;
    setState(() {
      _tipsSeen = tips;
      _tipsDone = tips >= _tipsDoneMark;
      _reviewInviteDone = invited;
      if (!_resultRecorded && _adaptive.games == 0) _adaptive = adaptive;
      if (!_botResultRecorded && _collection.beaten.isEmpty) {
        _collection = collection;
      }
    });
  }

  /// Aggiorna la stima a fine partita adattiva, una sola volta; se la partita
  /// viene riaperta (annulla) ripristina quella precedente. Le partite chiuse
  /// senza mosse non contano.
  void _recordAdaptiveResult() {
    final side = _computerSide;
    if (side == null || _bot != null || !_setup.adaptive || !_standardStart) {
      return;
    }
    if (_resultRecorded && !_game.isOver) {
      _resultRecorded = false;
      _adaptive = _adaptiveBefore;
      _saveAdaptive();
      return;
    }
    if (_resultRecorded || !_game.isOver || _game.moves.isEmpty) return;
    _resultRecorded = true;
    _adaptiveBefore = _adaptive;
    final winner = _game.outcome?.winner;
    final score = winner == null ? 0.5 : (winner == side ? 0.0 : 1.0);
    _adaptive = _adaptive.record(score, level: _gameLevel);
    _saveAdaptive();
  }

  /// A fine partita contro un bot lo aggiunge alla collezione se ha vinto il
  /// giocatore e fa commentare il bot; una partita riaperta (annulla) si può
  /// registrare di nuovo.
  void _recordBotResult() {
    final bot = _bot;
    final side = _computerSide;
    if (bot == null || side == null) return;
    if (_botResultRecorded && !_game.isOver) {
      _botResultRecorded = false;
      if (!identical(_collection, _collectionBefore)) {
        _collection = _collectionBefore;
        final restored = _collection;
        unawaited(_openStore().then(restored.save).catchError((_) {}));
      }
      return;
    }
    if (_botResultRecorded || !_game.isOver || _game.moves.isEmpty) return;
    _botResultRecorded = true;
    final winner = _game.outcome?.winner;
    _collectionBefore = _collection;
    if (_standardStart && winner != null && winner != side) {
      final updated = _collection.beat(bot.id, DateTime.now());
      if (!identical(updated, _collection)) {
        _collection = updated;
        unawaited(_openStore().then(updated.save).catchError((_) {}));
      }
    }
    _botSay(
      winner == null
          ? BotEvent.draw
          : (winner == side ? BotEvent.win : BotEvent.loss),
    );
  }

  /// Il bot commenta il proprio scacco e, ogni tanto, le proprie catture.
  void _botReact() {
    if (_game.position.isCheck) {
      _botSay(BotEvent.check);
    } else if (_game.moves.last.san.contains('x') && _random.nextInt(3) == 0) {
      _botSay(BotEvent.capture);
    } else if (_speech == null &&
        _game.moves.length >= 4 &&
        _random.nextInt(6) == 0) {
      _botSay(BotEvent.chat);
    }
  }

  void _botSay(BotEvent event) {
    final bot = _bot;
    if (bot == null || !mounted || _zen) return;
    // Le battute di compagnia non meritano una fascia che copre la scacchiera.
    if (event == BotEvent.chat && !_speechRoom) return;
    final text = bot.phrase(event, _random, friendly: _kidGame);
    _say(
      Speech(
        text,
        bot: bot,
        expression: switch (event) {
          BotEvent.start => AvatarExpression.greeting,
          BotEvent.win || BotEvent.capture => AvatarExpression.happy,
          BotEvent.loss => AvatarExpression.surprised,
          BotEvent.check => AvatarExpression.challenge,
          BotEvent.mistake => AvatarExpression.encouraging,
          _ => AvatarExpression.neutral,
        },
      ),
    );
  }

  Speech? _speech;
  Timer? _speechTimer;

  /// Dove c'è spazio sopra la scacchiera, impostato dal layout.
  bool _speechRoom = false;

  Widget _strip() =>
      SpeechStrip(opponent: _bot, speech: _speech, onDismiss: _clearSpeech);

  void _clearSpeech() {
    _speechTimer?.cancel();
    if (_speech != null && mounted) setState(() => _speech = null);
  }

  /// Fumetto sopra la scacchiera; senza spazio (schermo basso o orizzontale)
  /// resta la fascia in basso.
  void _say(Speech speech, {Duration? duration}) {
    if (!_speechRoom) {
      final bot = speech.bot;
      final text = bot == null
          ? speech.text
          : '${bot.avatar} ${bot.name}: ${speech.text}';
      if (duration == null) {
        _showMessage(text);
      } else {
        _showMessage(text, duration: duration);
      }
      return;
    }
    _speechTimer?.cancel();
    setState(() => _speech = speech);
    _speechTimer = Timer(duration ?? const Duration(seconds: 8), _clearSpeech);
  }

  void _saveAdaptive() {
    final adaptive = _adaptive;
    unawaited(_openStore().then(adaptive.save).catchError((_) {}));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!_inBackground) return;
      _inBackground = false;
      _resume();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      if (_inBackground) return;
      _inBackground = true;
      _suspend();
    }
  }

  /// Ferma orologio e computer; la ricerca interrotta non costa tempo al computer.
  void _suspend() {
    if (_suspensions++ > 0) return;
    final clock = _clock;
    _clockBeforeSuspension = clock?.isRunning ?? false;
    final searchStart = _searchClock;
    _cancelComputerMove();
    if (clock != null && searchStart != null) {
      clock.restore(searchStart, null);
    } else {
      clock?.pause();
    }
    _syncClock();
    _tick.value++;
  }

  /// Chiude una sospensione; all'ultima, se [restart], riparte da dove era.
  void _resume({bool restart = true}) {
    if (_suspensions == 0 || --_suspensions > 0 || !restart) return;
    if (!mounted || _game.isOver) return;
    if (_clockBeforeSuspension) _clock?.start(_game.position.turn);
    _syncClock();
    _tick.value++;
    unawaited(_computerMove());
  }

  /// Esegue [action] con orologio e computer fermi; riparte se [restart] lo consente.
  Future<T?> _whileSuspended<T>(
    Future<T?> Function() action, {
    bool Function(T? result)? restart,
  }) async {
    _suspend();
    T? result;
    try {
      result = await action();
    } finally {
      if (mounted) _resume(restart: restart?.call(result) ?? true);
    }
    return result;
  }

  Future<T?> _suspendedDialog<T>(
    WidgetBuilder builder, {
    bool Function(T? result)? restart,
  }) => _whileSuspended(
    () => showDialog<T>(
      context: context,
      animationStyle: motionStyle(context),
      builder: builder,
    ),
    restart: restart,
  );

  @override
  void didUpdateWidget(GamePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings != widget.settings) {
      oldWidget.settings.removeListener(_onSettingsChanged);
      widget.settings.addListener(_onSettingsChanged);
      _onSettingsChanged();
    }
  }

  @override
  void dispose() {
    widget.settings.removeListener(_onSettingsChanged);
    _generation++;
    _computer?.dispose().ignore();
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _speechTimer?.cancel();
    _tick.dispose();
    _sounds.dispose();
    _board.dispose();
    _syncAwake(disposing: true);
    _drawing.dispose();
    super.dispose();
  }

  bool _awake = false;

  /// Schermo acceso finché la partita è in corso e l'impostazione è attiva;
  /// si controlla a ogni costruzione, così vale per qualunque modo in cui la
  /// partita cambia o finisce.
  void _syncAwake({bool disposing = false}) {
    final want = !disposing && _settings.keepAwake && !_game.isOver;
    if (want == _awake) return;
    _awake = want;
    final set = widget.keepAwake ?? _systemKeepAwake;
    // Non è essenziale: senza il servizio lo schermo si spegne come di solito.
    unawaited(set(want).catchError((_) {}));
  }

  static Future<void> _systemKeepAwake(bool on) =>
      WakelockPlus.toggle(enable: on);

  void _onSettingsChanged() {
    _syncAwake();
    setState(() {
      final turnedOn = _settings.autoFlip && !_autoFlip;
      _autoFlip = _settings.autoFlip;
      if (turnedOn && _computerSide == null) {
        _orientation = _game.position.turn;
      }
    });
  }

  PlayerSide get _playerSide {
    // Mentre il computer pensa la scacchiera resta aperta solo alla premossa.
    final premoving =
        _task == _ComputerTask.move &&
        _settings.premove &&
        !_settings.kidMode &&
        !_settings.confirmMove &&
        _pendingMove == null;
    if (_game.isOver || (_thinking && !premoving) || _awaitingChallenge) {
      return PlayerSide.none;
    }
    return switch (_computerSide) {
      null => PlayerSide.both,
      Side.white => PlayerSide.black,
      Side.black => PlayerSide.white,
    };
  }

  /// Valutazione della posizione per la barra, dal punto di vista del Bianco.
  EngineScore? _evalScore;
  double? _evalWhiteWin;
  String? _evalFen;
  String? _evalGameId;
  bool _evalBusy = false;

  bool get _showEvalBar =>
      _settings.evalBar &&
      _helpAllowed &&
      _engineGame &&
      widget.computerAvailable;

  void _scheduleEval() {
    if (!_showEvalBar) return;
    if (_evalGameId != _gameId) {
      _evalGameId = _gameId;
      _evalFen = _evalScore = _evalWhiteWin = null;
    }
    if (_evalBusy || _evalFen == _game.position.fen) return;
    _evalBusy = true;
    unawaited(_refreshEval());
  }

  Future<void> _refreshEval() async {
    final position = _game.position;
    EngineScore? score;
    double? win;
    if (_game.isOver) {
      final outcome = _game.outcome;
      win = switch (outcome) {
        Outcome(winner: Side.white) => 100.0,
        Outcome(winner: Side.black) => 0.0,
        _ => 50.0,
      };
      score = position.isCheckmate
          ? const EngineScore.mate(0)
          : const EngineScore.cp(0);
    } else {
      try {
        final lines = await _computerPlayer.analyse(position.fen, depth: 10);
        final raw = lines.firstOrNull?.score;
        if (raw != null) {
          score = position.turn == Side.white ? raw : raw.negated;
          win = position.turn == Side.white
              ? winPercent(raw)
              : 100 - winPercent(raw);
        }
      } on Object {
        // Senza valutazione la barra resta com'era.
      }
    }
    _evalBusy = false;
    if (!mounted) return;
    // Il risultato di una posizione ormai lasciata non va sulla barra.
    if (score == null || !identical(position, _game.position)) {
      if (score != null) setState(_scheduleEval);
      return;
    }
    setState(() {
      _evalFen = position.fen;
      _evalScore = score;
      _evalWhiteWin = win;
    });
  }

  bool get _humanToMove => _playerSide != PlayerSide.none && !_computerToMove;

  ComputerPlayer get _computerPlayer =>
      _computer ??= widget.createComputer?.call() ?? ComputerPlayer();

  /// Le varianti non passano da Stockfish, che non ne conosce le regole.
  bool get _engineGame => _game.variant == Variant.standard;

  /// Posizioni già comparse prima di quella da muovere, per le ripetizioni.
  List<Position> get _priorPositions {
    final moves = _game.moves;
    return moves.isEmpty
        ? const []
        : [
            _game.initial,
            for (final m in moves.take(moves.length - 1)) m.after,
          ];
  }

  VariantEngine get _variantPlayer =>
      _variantEngine ??= widget.createVariantEngine?.call() ?? VariantEngine();

  GameData _gameData() {
    final pos = _game.position;
    return GameData(
      fen: pos.fen,
      lastMove: _game.lastMove,
      playerSide: _playerSide,
      sideToMove: pos.turn,
      kingSquareInCheck: pos.isCheck ? pos.board.kingOf(pos.turn) : null,
      validMoves: makeLegalMoves(pos),
    );
  }

  /// Posizione da mostrare senza poter muovere.
  GameData _staticData(Position pos, Move? lastMove) => GameData(
    fen: pos.fen,
    lastMove: lastMove,
    playerSide: PlayerSide.none,
    sideToMove: pos.turn,
    kingSquareInCheck: pos.isCheck ? pos.board.kingOf(pos.turn) : null,
    validMoves: const {},
  );

  var _openingSettings = false;

  Future<void> _openSettings() async {
    if (_openingSettings) return;
    _openingSettings = true;
    try {
      ProgressController? progress;
      try {
        progress = await widget.progress?.call();
      } on Object catch (e) {
        // Senza progressi le impostazioni restano utilizzabili, senza i blocchi.
        debugPrint('Progressi non disponibili: $e'); // l10n-ok
      }
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              SettingsPage(controller: widget.settings, progress: progress),
        ),
      );
    } finally {
      _openingSettings = false;
    }
  }

  DateTime _clockNow() => (widget.now ?? DateTime.now)();

  /// Inizia una nuova partita per progressi e archivio. Una posizione
  /// preparata con l'editor si archivia ma non vale XP.
  void _startRecording({bool fromEditor = false, SavedGame? resumeOf}) {
    _startedAt = resumeOf?.createdAt ?? _clockNow();
    _gameId = resumeOf?.id ?? 'game-${_startedAt.microsecondsSinceEpoch}';
    _fromEditor = fromEditor;
  }

  /// A fine partita la salva nell'archivio e la registra nei progressi.
  ///
  /// Dopo un annulla dell'abbandono o del tempo scaduto la partita riprende e
  /// può finire in altro modo: l'archivio si aggiorna (stesso `id`), gli XP si
  /// assegnano una volta sola per partita.
  void _finishGame() {
    final game = _game;
    if (!game.isOver) {
      _saveInProgress(game);
      return;
    }
    final (side, elo) = _playerAndElo;
    final ending =
        '${identityHashCode(game)}:${game.endReason}:${game.moves.length}';
    if (side != null && ending != _reportedEnding) {
      _reportedEnding = ending;
      final winner = game.outcome?.winner;
      widget.onFinished?.call(
        winner == null
            ? GameResult.draw
            : (winner == side ? GameResult.win : GameResult.loss),
        (game.moves.length + 1) ~/ 2,
      );
    }
    if (game.moves.isEmpty) return;
    final now = _clockNow();
    final key =
        '${identityHashCode(game)}:${game.endReason}:${game.moves.length}';
    if (key != _archivedKey) {
      _archivedKey = key;
      _archive(game, side, now, elo);
    }
    if (identical(game, _recordedGame) ||
        _fromEditor ||
        game.moves.length < _minPliesForProgress) {
      return;
    }
    _recordedGame = game;
    final elapsed = now.difference(_startedAt);
    unawaited(
      _record(
        gameActivity(
          game,
          // L'Allenamento vale come partita giocata, non come vittoria o Elo.
          player: _inTraining ? null : side,
          opponentElo: elo,
          book: loadedOpeningBook,
          duration: elapsed.isNegative
              ? Duration.zero
              : elapsed > _maxCountedPlay
              ? _maxCountedPlay
              : elapsed,
        ),
      ),
    );
  }

  /// A ogni mossa la partita in corso si salva nell'archivio (risultato `*`):
  /// chiudere l'app non la perde e si può riprendere. Le partite senza mosse
  /// non si salvano.
  void _saveInProgress(ChessGame game) {
    if (game.moves.isEmpty) return;
    final key = '${identityHashCode(game)}:${game.moves.length}:open';
    if (key == _archivedKey) return;
    _archivedKey = key;
    final (side, elo) = _playerAndElo;
    _archive(game, side, _clockNow(), elo);
  }

  /// Salvataggio e progressi vanno avanti da soli: uno lento o fallito non
  /// ferma l'altro.
  void _archive(ChessGame game, Side? side, DateTime now, int? elo) {
    _persist(_savedGame(game, side, now, elo));
  }

  void _persist(SavedGame saved) {
    final save = widget.onSave;
    if (save == null) return;
    unawaited(
      save(saved).onError(
        (Object e, _) => debugPrint('Partita non salvata: $e'), // l10n-ok
      ),
    );
  }

  SavedGame _savedGame(ChessGame game, Side? side, DateTime now, int? elo) {
    String name(Side s) => side == null
        ? (_settings.nameOf(s) ??
              (s == Side.white ? SavedGame.nameWhite : SavedGame.nameBlack))
        : (s == side
              ? SavedGame.nameYou
              : (_bot?.name ?? SavedGame.nameComputer));
    final reviewed = _reviewed;
    final saved = SavedGame.fromGame(
      game,
      id: _gameId,
      white: name(Side.white),
      black: name(Side.black),
      mode: side == null ? SavedGame.local : SavedGame.computer,
      createdAt: _startedAt,
      updatedAt: now,
      playerSide: side,
      timeControl: _clock?.control.label,
      opponentElo: elo,
      headers: {'Handicap': ?_handicap?.pgnValue(_handicapHuman)},
    );
    return reviewed != null &&
            reviewed.id == _gameId &&
            reviewed.plies == game.moves.length
        ? saved.withReview(reviewed.review)
        : saved;
  }

  /// Colore dell'utente ed Elo dell'avversario; `null` tra due persone.
  (Side?, int?) get _playerAndElo {
    final side = _computerSide?.opposite;
    // Un handicap falsa il confronto: senza Elo non entra nel rating locale.
    return (
      side,
      side == null || _handicap != null || !_engineGame || _inTraining
          ? null
          : (_bot?.elo ?? engineLevel(_gameLevel).approxElo),
    );
  }

  /// Mostra la partita, anche in corso, come QR per un altro telefono.
  Future<void> _sendQr() async {
    final (side, elo) = _playerAndElo;
    final saved = _savedGame(_game, side, _clockNow(), elo);
    final frames = encodeTransfer(saved.pgn);
    await _whileSuspended(
      () => Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => QrSendPage(
            title: saved.titleIn(AppLocalizations.of(context)),
            frames: frames,
          ),
        ),
      ),
    );
  }

  /// Continua qui, tra due persone e senza orologio, una partita ricevuta.
  /// I nomi delle impostazioni non cambiano: quelli del PGN possono essere
  /// "Tu" o il nome di un bot sull'altro telefono.
  Future<void> _receiveQr() async {
    final l10n = qrL10n(context);
    // Riprende la partita corrente se quella ricevuta non si continua.
    final games = await _whileSuspended(() async {
      final text = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (_) => QrReceivePage(scanner: widget.qrScanner),
        ),
      );
      return text == null ? null : receivedGames(text);
    }, restart: (games) => games?.firstOrNull?.game.isOver ?? true);
    if (!mounted || games == null) return;
    if (games.isEmpty) {
      _showMessage(l10n.qrInvalidGame);
      return;
    }
    final game = games.first.game;
    if (game.isOver) {
      _showMessage(l10n.qrFinishedGame);
      return;
    }
    _bot = null;
    _resultRecorded = false;
    _botResultRecorded = false;
    _chosenVariant = game.variant;
    // Come per l'editor: si archivia, ma non vale XP una partita iniziata altrove.
    _beginGame(
      game,
      _setup.copyWith(opponent: Opponent.human),
      null,
      fromEditor: true,
    );
  }

  Future<void> _record(GamePlayed activity) async {
    try {
      final update = await widget.onActivity?.call(activity);
      if (update != null && mounted) {
        final message = progressMessage(update, _l10n(context));
        if (message != null) _showMessage(message);
      }
    } on Object catch (e) {
      debugPrint('Progressi non registrati: $e'); // l10n-ok
    }
  }

  void _refresh({bool animate = true}) {
    _pendingMove = null;
    _viewPly = null;
    _syncClock();
    _finishGame();
    _board.updatePosition(_gameData(), animate: animate, resetPremove: true);
    _recordAdaptiveResult();
    _recordBotResult();
    setState(() {
      if (_settings.autoFlip && _computerSide == null) {
        _orientation = _game.position.turn;
      }
    });
  }

  void _onMove(Move move, {bool? viaDragAndDrop}) {
    if (!_humanToMove) return;
    if (!_settings.confirmMove) {
      _commitMove(move, animate: viaDragAndDrop != true);
      return;
    }
    if (!_game.position.isLegal(move)) return;
    final (preview, san) = _game.position.makeSan(move);
    final turn = _game.position.turn;
    final l10n = _l10n(context);
    _announce(
      l10n.gameToConfirm(describeSan(l10n, san, turn, name: _nameOf(turn))),
    );
    _board.updatePosition(
      _staticData(preview, move),
      animate: viaDragAndDrop != true,
    );
    setState(() => _pendingMove = move);
  }

  void _confirmPending() {
    final move = _pendingMove;
    if (move == null) return;
    setState(() => _pendingMove = null);
    _commitMove(move, animate: false);
  }

  void _discardPending() {
    _clearBoardInteraction();
    _refresh(animate: false);
  }

  void _commitMove(Move move, {required bool animate}) {
    final before = _game.position;
    final played = _apply(move);
    if (!played && !_game.isOver) return;
    _refresh(animate: played && animate);
    if (played) unawaited(_afterHumanMove(before, move));
  }

  /// Il giudizio resta sulla casa finché è la mossa dell'utente o la risposta
  /// del computer non la occupa; non si mostra sfogliando la cronologia.
  /// Il suggerimento resta finché la posizione è quella per cui è stato dato.
  Set<Shape> _visibleHint() {
    if (_viewPly != null) return const {};
    final fen = _game.position.fen;
    return {
      if (_hintedFen == fen) ..._hintShapes,
      if (_threatFen == fen) ..._threatShapes,
    };
  }

  Map<Square, Annotation> _badgeAnnotations() {
    final badge = _badge;
    if (badge == null || _viewPly != null || !_coaching) return const {};
    final length = _game.moves.length;
    if (length != badge.ply + 1 && length != badge.ply + 2) return const {};
    if (length == badge.ply + 2 && _lastMoveTo() == badge.square) {
      return const {};
    }
    return {
      badge.square: Annotation(
        symbol: badge.verdict.symbol,
        color: moveClassColor(badge.verdict),
      ),
    };
  }

  /// Casa d'arrivo dell'ultima mossa giocata.
  Square? _lastMoveTo() {
    final move = _game.lastMove;
    return move is NormalMove ? move.to : null;
  }

  /// Con l'allenatore acceso, giudica la mossa prima della risposta del
  /// computer; un errore offre di riprenderla.
  Future<void> _afterHumanMove(Position before, Move move) async {
    if (!_coaching || _computerSide == null || _game.isOver) {
      return _computerMove();
    }
    final plies = _game.moves.length;
    _showMessage(
      _l10n(context).gameCoachChecking,
      duration: const Duration(seconds: 2),
    );
    final kid = _kid;
    final retry = await _whileSuspended<bool>(() async {
      final MoveVerdict verdict;
      try {
        verdict = await _coach.judge(before, move, kid: kid);
      } on Object {
        return false;
      }
      if (!mounted ||
          _game.isOver ||
          _game.moves.length != plies ||
          !_coaching) {
        return false;
      }
      final text = verdict.comment?.text(_l10n(context));
      final played = verdict.review.move;
      // Se nel frattempo l'allenatore è stato spento, il giudizio non serve.
      if (played is NormalMove && _coaching) {
        setState(
          () => _badge = (
            ply: plies - 1,
            square: kingDestination(before, played).to,
            verdict: verdict.review.classification,
          ),
        );
      }
      if (!verdict.shouldWarn) {
        if (text != null) _announce(text);
        return false;
      }
      return showDialog<bool>(
        context: context,
        animationStyle: motionStyle(context),
        builder: (context) {
          final l10n = _l10n(context);
          return AlertDialog(
            title: Text(l10n.gameCoachTitle),
            content: Text(text ?? l10n.gameCoachWorse),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.gameContinue),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(l10n.gameRetry),
              ),
            ],
          );
        },
      );
    }, restart: (retry) => retry != true);
    if (retry == true && mounted && _game.moves.length == plies) _undo();
  }

  /// Freccia rossa con la mossa che l'avversario giocherebbe se toccasse a lui
  /// (RF-56).
  Future<void> _showThreat() async {
    final position = _game.position;
    NormalMove? threat;
    try {
      threat = await _whileSuspended(() => _coach.threat(position));
    } on Object {
      threat = null;
    }
    if (!mounted || !identical(position, _game.position)) return;
    if (threat == null) {
      _say(Speech(_l10n(context).gameThreatNone));
      return;
    }
    final fen = threatFen(position);
    final flipped = fen == null ? null : Chess.fromSetup(Setup.parseFen(fen));
    final move = flipped == null ? null : parseEngineMove(flipped, threat.uci);
    final san = move == null ? null : flipped!.makeSan(move).$2;
    setState(() {
      _threatFen = position.fen;
      _threatShapes = _settings.marks.arrow(
        _settings.threatColor,
        threat!.from,
        threat.to,
      );
    });
    final l10n = _l10n(context);
    _say(
      Speech(
        san == null
            ? l10n.gameThreatArrow
            : l10n.gameThreatMove(
                formatSan(san, AppSettings.of(context).notation),
              ),
      ),
    );
  }

  /// Suggerimento a livelli: prima il pezzo, poi la mossa.
  Future<void> _giveHint() async {
    if (!_hintAllowed) return;
    final position = _game.position;
    final level = _hintedFen == position.fen ? HintLevel.move : HintLevel.piece;
    CoachHint? hint;
    try {
      hint = await _whileSuspended(() => _coach.hint(position, level));
    } on Object {
      hint = null;
    }
    if (!mounted || !identical(position, _game.position)) return;
    if (hint == null) {
      _say(Speech(_l10n(context).gameHintNone));
      return;
    }
    final marks = _settings.marks;
    final color = marks.hint;
    final to = hint.to;
    final text = to == null
        ? describeHintPiece(_l10n(context), position, hint.from)
        : describeHintMove(
            _l10n(context),
            position,
            NormalMove(from: hint.from, to: to, promotion: hint.promotion),
            showSquare: !_kid,
          );
    _hintedFen = position.fen;
    setState(
      () => _hintShapes = to == null
          ? marks.circle(color, hint!.from)
          : {
              // Prima la freccia: il suo contorno non deve coprire i cerchi.
              ...marks.arrow(color, hint!.from, to),
              ...marks.circle(color, hint.from),
              ...marks.circle(color, to),
            },
    );
    _say(Speech(text, expression: AvatarExpression.encouraging));
  }

  /// Gioca [move] con orologio, suono e annuncio; con il tempo scaduto chiude la partita.
  bool _apply(Move move) {
    final clock = _clock;
    final flagged = clock?.flagged;
    if (flagged != null) {
      _game.flag(flagged);
      _playSound(GameSound.gameEnd);
      _announce(_statusMessage());
      return false;
    }
    final before = clock?.snapshot();
    final position = _game.position;
    // Tempo residuo di chi muove dopo la mossa, incremento compreso (RF-67);
    // la prima mossa avvia l'orologio e non lo incrementa.
    final left = clock?.remainingAfterMove(
      position.turn,
      moves: _movesOf(_game.moves.length + 1),
    );
    if (!_game.play(move, clock: left)) return false;
    final spoken = describeSan(
      _l10n(context),
      _game.moves.last.san,
      position.turn,
      name: _nameOf(position.turn),
    );
    _announce(_game.isOver ? '$spoken. ${_statusMessage()}' : spoken);
    final sound = soundForLastMove(_game, position);
    if (sound != null) _playSound(sound);
    if (clock != null) {
      _clockHistory.add(before!);
      if (clock.isRunning) {
        clock.switchAfterMove(moves: _movesOf(_game.moves.length));
      } else {
        clock.start(_game.position.turn);
      }
    }
    _checkLine();
    _instructorSay();
    return true;
  }

  /// Mosse fatte da chi gioca la semimossa [ply] (da 1), questa compresa.
  int _movesOf(int ply) => (ply + 1) ~/ 2;

  Future<void> _computerMove() async {
    final side = _computerSide;
    if (_thinking || side == null || _game.isOver || _suspensions > 0) return;
    if (_game.position.turn != side) return;
    final messenger = ScaffoldMessenger.of(context);
    if (_lineNotice == null) {
      messenger.hideCurrentSnackBar();
    }
    final generation = _generation;
    _task = _ComputerTask.move;
    final clock = _clock;
    if (clock != null && !clock.isRunning && _game.moves.isNotEmpty) {
      clock.start(side);
    }
    _searchClock = clock?.snapshot();
    var level = _bot?.level ?? engineLevel(_gameLevel);
    if (clock != null) {
      level = level.withinClock(
        clock.remaining(side),
        Duration(seconds: clock.control.increment + clock.control.delay),
      );
    }
    _refresh(animate: false);
    EngineMove? reply;
    Object? error;
    try {
      final book = _bookMove();
      if (book != null) {
        await Future<void>.delayed(level.minReply);
        reply = EngineMove(move: book, pv: const []);
      } else {
        reply = _engineGame
            ? await _computerPlayer.bestMove(
                _game.initial.fen,
                _moveHistory,
                level,
              )
            : await _variantPlayer.bestMove(
                _game.position,
                level,
                history: _priorPositions,
              );
      }
    } on Object catch (e) {
      error = e;
    }
    if (!mounted || generation != _generation) return;
    _task = _ComputerTask.none;
    final searchStart = _searchClock;
    _searchClock = null;
    final before = _game.position;
    final played = reply != null && _apply(reply.move);
    if (reply == null ? !_game.isOver : !played && !_game.isOver) {
      error ??= reply ?? 'nessuna mossa'; // l10n-ok
      if (searchStart != null) clock?.restore(searchStart, null);
    }
    final viewing = _viewPly;
    final premove = played ? _board.premove : null;
    _refresh();
    if (viewing != null) _showPly(viewing);
    if (played && !_game.isOver) _botReact();
    // Una premossa giocata cambia la posizione: la spiegazione non sarebbe più
    // attuale.
    final premoved =
        premove != null && viewing == null && _playPremove(premove);
    if (played &&
        !premoved &&
        !_game.isOver &&
        _settings.explainWhy &&
        !_isChallenge &&
        !_zen) {
      unawaited(_explainReply(before, reply.move));
    }
    if (error != null) {
      final l10n = _l10n(context);
      _showMessage(
        l10n.gameComputerNoReply,
        duration: const Duration(days: 1),
        action: SnackBarAction(label: l10n.gameRetry, onPressed: _computerMove),
      );
    }
  }

  /// Gioca la premossa se nella nuova posizione è ancora legale (RF-08);
  /// altrimenti la scarta. Un pedone che arriva all'ultima traversa promuove a
  /// donna, senza il selettore.
  bool _playPremove(Move premove) {
    if (_game.isOver || !_humanToMove) return false;
    final position = _game.position;
    var move = premove;
    if (move is NormalMove && move.promotion == null) {
      final lastRank = position.turn == Side.white ? Rank.eighth : Rank.first;
      if (position.board.roleAt(move.from) == Role.pawn &&
          move.to.rank == lastRank) {
        move = move.withPromotion(Role.queen);
      }
    }
    if (move is NormalMove) move = position.normalizeMove(move);
    if (!position.isLegal(move)) return false;
    _commitMove(move, animate: true);
    return true;
  }

  /// «Spiegami perché» (RF-122): una riga su cosa fa o minaccia la mossa del
  /// computer, con la minaccia ricavata come per la freccia di RF-56.
  Future<void> _explainReply(Position before, Move move) async {
    final after = _game.position;
    NormalMove? followUp;
    // Con l'orologio acceso l'analisi della minaccia fermerebbe il tempo
    // dell'utente: si spiega solo la mossa.
    try {
      followUp = _clock != null || !_engineGame
          ? null
          : await _whileSuspended(() => _coach.threat(after));
    } on Object {
      followUp = null;
    }
    if (!mounted || _zen || !identical(after, _game.position)) return;
    final text = explainComputerMove(
      _l10n(context),
      before,
      move,
      followUp: followUp,
      showSquares: !_kid,
    );
    if (text == null) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    _say(Speech(text), duration: const Duration(seconds: 8));
  }

  /// Partita di scacchi classici dalla posizione iniziale: solo queste contano
  /// per la stima adattiva e per la collezione dei bot.
  bool get _standardStart =>
      _handicap == null &&
      _game.variant == Variant.standard &&
      _game.initial.fen == Chess.initial.fen;

  /// Mossa del libro d'apertura del bot, solo negli scacchi classici.
  Move? _bookMove() {
    final bot = _bot;
    if (bot == null || !_standardStart) return null;
    return bot.bookMoveFor(_game.initial, _moveHistory, _random);
  }

  List<Move> get _moveHistory => [for (final m in _game.moves) m.move];

  /// Posizione sulla scacchiera, anche mentre si scorrono le mosse.
  Position get _shownPosition {
    final ply = _viewPly;
    if (ply == null) return _game.position;
    return ply == -1 ? _game.initial : _game.moves[ply].after;
  }

  void _cancelComputerMove() {
    _generation++;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    if (_thinking) {
      _computer?.stop();
      _variantEngine?.stop();
    }
    _task = _ComputerTask.none;
    _searchClock = null;
  }

  /// Mostra la posizione dopo la semimossa [ply] (-1 = iniziale); `null` o
  /// oltre l'ultima mossa torna alla partita in corso.
  void _showPly(int? ply) {
    if (_pendingMove != null || _game.moves.isEmpty) return;
    if (ply == null || ply >= _game.moves.length) {
      if (_viewPly != null) {
        _clearBoardInteraction();
        _refresh(animate: false);
      }
      return;
    }
    final target = ply < -1 ? -1 : ply;
    _board.updatePosition(
      target == -1
          ? _staticData(_game.initial, null)
          : _staticData(_game.moves[target].after, _game.moves[target].move),
      animate: false,
    );
    setState(() => _viewPly = target);
  }

  /// Vero se da [square] parte un trascinamento di pezzo, non uno scorrimento.
  bool _canDragFrom(Square square) {
    if (_viewPly != null || _game.isOver || !_humanToMove) return false;
    final position = _game.position;
    return position.board.sideAt(square) == position.turn;
  }

  /// Case dove può andare il pezzo su [from], senza le promozioni, che hanno
  /// bisogno del selettore.
  Set<Square> _tapTargets(Square from) {
    final position = _game.position;
    final moves = makeLegalMoves(position)[from];
    if (moves == null || position.board.sideAt(from) != position.turn) {
      return const {};
    }
    final pawn = position.board.roleAt(from) == Role.pawn;
    return {
      for (final to in moves)
        if (!(pawn && (to.rank == Rank.first || to.rank == Rank.eighth))) to,
    };
  }

  /// Scorrimento sulla scacchiera: a sinistra avanti, a destra indietro.
  void _swipe(int direction) =>
      _showPly((_viewPly ?? _game.moves.length - 1) + direction);

  KeyEventResult _onKey(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final current = _viewPly ?? _game.moves.length - 1;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowLeft) {
      _showPly(current - 1);
    } else if (key == LogicalKeyboardKey.arrowRight) {
      _showPly(current + 1);
    } else if (key == LogicalKeyboardKey.home) {
      _showPly(-1);
    } else if (key == LogicalKeyboardKey.end) {
      _showPly(null);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  /// Ferma l'orologio a fine partita e aggiorna il timer di visualizzazione.
  void _syncClock() {
    final clock = _clock;
    if (clock != null && _game.isOver) clock.pause();
    if (clock != null && clock.isRunning) {
      _ticker ??= Timer.periodic(const Duration(milliseconds: 100), _onTick);
    } else {
      _ticker?.cancel();
      _ticker = null;
    }
  }

  void _onTick(Timer _) {
    final clock = _clock;
    final flagged = clock?.flagged;
    if (flagged != null && !_game.isOver) {
      _cancelComputerMove();
      _game.flag(flagged);
      _playSound(GameSound.gameEnd);
      _announce(_statusMessage());
      _refresh(animate: false);
      return;
    }
    final active = clock?.active;
    if (active != null &&
        active != _computerSide &&
        _lowTime.check(active, clock!.remaining(active))) {
      _playSound(GameSound.lowTime);
    }
    _tick.value++;
  }

  void _announce(String message) {
    unawaited(
      SemanticsService.sendAnnouncement(
        View.of(context),
        message,
        Directionality.of(context),
      ),
    );
  }

  void _playSound(GameSound sound) {
    final s = _settings;
    unawaited(
      _sounds.play(
        sound,
        enabled: s.sound,
        volume: s.volume,
        haptics: s.haptics,
      ),
    );
  }

  /// Chiude selezione e selettore di promozione rimasti aperti sulla scacchiera.
  void _clearBoardInteraction() {
    _board.updatePosition(
      _staticData(_game.position, _game.lastMove),
      animate: false,
    );
  }

  /// Distanza dal fondo dei messaggi: sopra la scacchiera, che altrimenti
  /// resterebbe coperta dalla fascia, sotto i comandi.
  double _messageBottom = _actionsHeight + 8;

  /// Messaggio sopra la barra dei comandi, per non coprirla.
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> _showMessage(
    String text, {
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(text),
      duration: duration,
      action: action,
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.fromLTRB(16, 0, 16, _messageBottom),
    ),
  );

  /// Memorizza la scelta dell'avversario; un bot bloccato diventa il primo
  /// della scala, quello amichevole nel profilo bambino.
  GameSetup _applySetup(GameSetup chosen) {
    _kidGame = _settings.kidMode;
    var setup = _kidGame ? chosen.forKids() : chosen;
    var bot = setup.opponent == Opponent.bot ? botById(setup.botId) : null;
    if (bot != null && !_collection.isUnlocked(bot)) {
      bot = _kidGame ? friendlyBots.first : botById('pino')!;
      setup = setup.copyWith(botId: bot.id);
    }
    _setup = setup;
    _bot = bot;
    _gameLevel = setup.adaptive ? _adaptive.level : setup.level;
    _resultRecorded = false;
    _botResultRecorded = false;
    return setup;
  }

  Future<void> _newGame() async {
    final picked = await _whileSuspended<_TimeChoice>(() async {
      final result = await showRokkoSheet<Object>(
        context: context,
        builder: (context) => _TimeControlSheet(
          kid: _kid,
          variant: _kid ? Variant.standard : _chosenVariant,
          whiteName: _settings.whiteName,
          blackName: _settings.blackName,
          setup: _setup,
          adaptiveLevel: _adaptive.level,
          collection: _collection,
          computerAvailable: widget.computerAvailable,
          kidMode: _settings.kidMode,
          training: _trainingDefault,
          tournamentPage: widget.tournamentPage,
          physicalPage: widget.physicalPage,
          openingGame: widget.openingGame,
          onActivity: widget.onActivity,
        ),
      );
      // Tornei e scacchiera fisica prendono il posto della partita, che
      // resta ferma finché non si torna.
      if (result is _SheetRun && mounted) {
        await result.run(context);
        return null;
      }
      return result as _TimeChoice?;
    }, restart: (choice) => choice == null);
    if (!mounted || picked == null) return;
    final choice = picked;

    final setup = _applySetup(choice.setup);
    final vsComputer = setup.opponent != Opponent.human;
    final chosenTraining = choice.training;
    if (chosenTraining != null &&
        !_kid &&
        chosenTraining != _settings.trainingMode) {
      unawaited(
        widget.settings.update(
          _settings.copyWith(trainingMode: chosenTraining),
        ),
      );
    }
    _training = _kid || (chosenTraining ?? _settings.trainingMode);
    // Il profilo bambino gioca solo la classica: la variante scelta prima
    // resta per quando il profilo si spegne.
    if (!_kid) _chosenVariant = choice.variant;
    final variant = _kid ? Variant.standard : choice.variant;
    final control = choice.control;
    final human = vsComputer ? setup.resolveHumanSide(_random) : Side.white;
    final handicap = _kid
        ? null
        : choice.handicap?.usable(
            control: control,
            standard: variant == Variant.standard,
          );
    final pieceOdds = handicap?.piece != null;
    _beginGame(
      ChessGame(
        initial: pieceOdds
            ? handicap!.startPosition(human)
            : initialPosition(
                variant,
                chess960Id: variant == Variant.chess960
                    ? widget.chess960Id()
                    : null,
              ),
        variant: variant,
      ),
      setup,
      control == null
          ? null
          : ChessClock(
              control,
              now: widget.now,
              startTimes: handicap?.startTimes(control, human),
            ),
      handicap: handicap,
      humanSide: human,
    );
    if (choice.coach && vsComputer && _engineGame && !_zen) {
      setState(() => _coachOn = true);
    }
    if (vsComputer) return;
    unawaited(
      widget.settings.update(
        _settings.copyWith(
          whiteName: choice.whiteName,
          blackName: choice.blackName,
        ),
      ),
    );
  }

  /// La rivincita ripete la partita appena finita: stesso avversario, stessa
  /// cadenza e stessa variante, con i colori invertiti contro il computer.
  /// Non c'è per sfide, vantaggi e posizioni scelte a mano.
  bool get _canRematch =>
      _game.isOver &&
      !_isChallenge &&
      _handicap == null &&
      (_game.variant != Variant.standard ||
          _game.initial.fen == Chess.initial.fen);

  void _rematch() {
    // L'avversario è quello della partita appena finita, non l'ultimo scelto.
    final setup = _applySetup(
      _computerSide == null
          ? _setup.copyWith(opponent: Opponent.human)
          : _setup,
    );
    final vsComputer = setup.opponent != Opponent.human;
    // Il computer prende il colore che aveva chi ha giocato.
    final human = _computerSide ?? Side.white;
    final variant = _game.variant;
    final control = _clock?.control;
    final coach = _coachOn;
    _beginGame(
      ChessGame(
        initial: initialPosition(
          variant,
          chess960Id: variant == Variant.chess960 ? widget.chess960Id() : null,
        ),
        variant: variant,
      ),
      setup,
      control == null ? null : ChessClock(control, now: widget.now),
      humanSide: human,
    );
    if (coach && vsComputer && _engineGame && !_zen) {
      setState(() => _coachOn = true);
    }
  }

  /// Avvia [game] contro l'avversario di [setup]: azzera orologio e cronologia,
  /// dispone i lati e fa muovere subito chi tocca.
  void _beginGame(
    ChessGame game,
    GameSetup setup,
    ChessClock? clock, {
    bool fromEditor = false,
    Handicap? handicap,
    Side? humanSide,
    SavedGame? resumeOf,
  }) {
    assert(
      handicap == null || humanSide != null,
      'chi concede dipende dal colore di chi gioca', // l10n-ok
    );
    _cancelComputerMove();
    _clockBeforeSuspension = false;
    _coachOn = false;
    _badge = null;
    _hintedFen = null;
    _threatFen = null;
    _speechTimer?.cancel();
    _speech = null;
    _coach = _newCoach();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    _game = game;
    _clock = clock;
    _handicap = handicap;
    _clockHistory.clear();
    _lowTime.reset();
    _clearBoardInteraction();
    _startRecording(fromEditor: fromEditor, resumeOf: resumeOf);
    if (setup.opponent != Opponent.human) {
      final human = humanSide ?? setup.resolveHumanSide(_random);
      _handicapHuman = human;
      _computerSide = human.opposite;
      _orientation = human;
      if (_engineGame) _computerPlayer.newGame().ignore();
    } else {
      _handicapHuman = Side.white;
      if (_computerSide != null) _orientation = Side.white;
      _computerSide = null;
      _computer?.dispose().ignore();
      _computer = null;
    }
    _refresh(animate: false);
    unawaited(_computerMove());
    if (_bot != null) _botSay(BotEvent.start);
  }

  /// Apre l'editor sulla posizione mostrata e gioca senza orologio quella scelta.
  Future<void> _editPosition() async {
    final shown = _shownPosition;
    // Editor e scelta dell'avversario sono un'unica sospensione: chiudere uno
    // dei due lascia la partita, orologio compreso, com'era.
    final result = await _whileSuspended<(Position, GameSetup)>(() async {
      final position = await Navigator.of(context).push<Position>(
        MaterialPageRoute(
          builder: (_) => PositionEditorPage(
            initialFen: shown.fen,
            board: _settings.editorBoard,
          ),
        ),
      );
      if (position == null || !mounted) return null;
      var chosen = _setup.copyWith(opponent: Opponent.human);
      if (widget.computerAvailable) {
        final picked = await showRokkoSheet<GameSetup>(
          context: context,
          builder: (context) => _PositionSheet(
            setup: chosen,
            adaptiveLevel: _adaptive.level,
            collection: _collection,
            kidMode: _settings.kidMode,
          ),
        );
        if (picked == null) return null;
        chosen = picked;
      }
      return (position, chosen);
    }, restart: (result) => result == null);
    if (!mounted || result == null) return;
    final (position, chosen) = result;
    // Contro una persona restano le scelte fatte per il computer.
    if (chosen.opponent == Opponent.human) {
      _bot = null;
      _resultRecorded = false;
      _botResultRecorded = false;
    }
    final setup = chosen.opponent == Opponent.human
        ? chosen
        : _applySetup(chosen);
    _beginGame(ChessGame(initial: position), setup, null, fromEditor: true);
  }

  String get _title {
    final l10n = _l10n(context);
    return switch (_game.variant) {
      Variant.standard => l10n.gameTitleStandard,
      Variant.chess960 => switch (chess960IdOf(_game.initial)) {
        null => l10n.gameTitleChess960,
        final id => l10n.gameTitleChess960Id(id),
      },
      Variant.kingOfTheHill => Variant.kingOfTheHill.label(l10n),
      // Non "1-0": si confonderebbe con un risultato.
      Variant.threeCheck => l10n.gameTitleThreeCheck(
        _checksGiven(Side.white),
        _checksGiven(Side.black),
      ),
    };
  }

  int _checksGiven(Side side) {
    final pos = _game.position;
    if (pos is! ThreeCheck) return 0;
    final (white, black) = pos.remainingChecks;
    return 3 - (side == Side.white ? white : black);
  }

  Future<void> _typeMove() async {
    final position = _game.position;
    final move = await showDialog<Move>(
      context: context,
      animationStyle: motionStyle(context),
      builder: (_) => _MoveInputDialog(position: position),
    );
    if (move == null || !mounted || _viewPly != null || _game.isOver) return;
    if (!_humanToMove) return;
    if (_pendingMove != null || !identical(position, _game.position)) return;
    _onMove(move);
  }

  /// Tra due persone annullare una mossa chiede il consenso di chi non l'ha
  /// giocata (RF-32). Contro il computer, nelle sfide, per le azioni locali
  /// (uscire dalla revisione, scartare una mossa da confermare) e per
  /// revocare un abbandono o una patta, che non toglie mosse, basta il tocco.
  Future<void> _requestUndo() async {
    final needsConsent =
        _computerSide == null &&
        !_isChallenge &&
        _viewPly == null &&
        _pendingMove == null &&
        !_endedByChoice &&
        _game.moves.isNotEmpty;
    if (!needsConsent) return _undo();
    final game = _game;
    final plies = game.moves.length;
    final consenting = game.position.turn;
    final accepted = await _suspendedDialog<bool>((context) {
      final l10n = _l10n(context);
      if (_kid) {
        return _yesNoDialog(
          context,
          title: switch (_nameOf(consenting)) {
            null => l10n.kidGameUndoOfferSide(consenting.name),
            final name => l10n.kidGameUndoOfferName(name),
          },
          no: l10n.kidGameDrawNo,
          yes: l10n.kidGameUndoYes,
        );
      }
      return _yesNoDialog(
        context,
        title: switch (_nameOf(consenting)) {
          null => l10n.gameUndoOfferSide(consenting.name),
          final name => l10n.gameUndoOfferNamed(name, consenting.name),
        },
        no: l10n.gameDrawDecline,
        yes: l10n.gameDrawAccept,
      );
    }, restart: (accepted) => accepted != true);
    if (!mounted || !identical(game, _game) || game.moves.length != plies) {
      return;
    }
    if (accepted == true) {
      _undo();
    } else {
      _showMessage(_l10n(context).gameUndoRefused);
    }
  }

  void _undo() {
    if (_viewPly != null) {
      _showPly(null);
      return;
    }
    if (_pendingMove != null) {
      _discardPending();
      return;
    }
    _cancelComputerMove();
    _badge = null;
    final revokeOnly = _endedByChoice;
    final timedOut = _game.endReason == GameEndReason.timeout;
    _game.undo();
    if (timedOut) _game.undo();
    if (revokeOnly) {
      if (_game.moves.isNotEmpty) _clock?.start(_game.position.turn);
    } else {
      _restoreClock();
      if (_computerToMove && _game.canUndo) {
        _game.undo();
        _restoreClock();
      }
    }
    _clearBoardInteraction();
    // Dopo un annulla l'uscita già segnalata vale solo se resta nella partita.
    _reportedDeviation = _lineDeviationNow();
    _refresh(animate: false);
    // Il commento sull'apertura segue la posizione tornata in campo.
    _clearSpeech();
    _instructorSay();
    unawaited(_computerMove());
  }

  bool get _endedByChoice => switch (_game.endReason) {
    GameEndReason.resignation || GameEndReason.agreement => true,
    _ => false,
  };

  void _restoreClock() {
    final clock = _clock;
    if (clock == null || _clockHistory.isEmpty) return;
    clock.restore(
      _clockHistory.removeLast(),
      _game.moves.isEmpty ? null : _game.position.turn,
    );
  }

  bool get _computerToMove => _computerSide == _game.position.turn;

  bool get _canUndo {
    if (!_game.canUndo) return false;
    if (_computerSide != Side.white || _endedByChoice) return true;
    if (_game.endReason == GameEndReason.timeout) return true;
    return _game.moves.length > 1;
  }

  Future<void> _resign() async {
    final side = _computerSide?.opposite ?? _game.position.turn;
    final confirmed = await _suspendedDialog<bool>((context) {
      if (!_kid) {
        final l10n = _l10n(context);
        return _yesNoDialog(
          context,
          title: l10n.gameResignTitle,
          content: l10n.gameResignBody(_player(l10n, side, _nameOf)),
          no: l10n.gameCancel,
          yes: l10n.gameResignYes,
        );
      }
      final l = _l10n(context);
      return _yesNoDialog(
        context,
        title: _computerSide != null
            ? l.kidGameResignTitle
            : switch (_nameOf(side)) {
                null => l.kidGameResignTitleSide(side.name),
                final name => l.kidGameResignTitleName(name),
              },
        content: l.kidGameResignBody,
        no: l.kidGameResignNo,
        yes: l.kidGameResignYes,
      );
    }, restart: (confirmed) => confirmed != true);
    if (!mounted) return;
    if (confirmed == true) {
      _game.resign(side);
      _endByChoice();
    }
  }

  /// Chiude la partita dopo resa o patta concordata: il cambio di stato non
  /// arriva da una mossa, quindi l'esito va annunciato qui.
  void _endByChoice() {
    _playSound(GameSound.gameEnd);
    _refresh(animate: false);
    _announce(_statusMessage());
  }

  /// Domanda sì/no di resa e patta; il "sì" chiude il dialogo con `true`.
  AlertDialog _yesNoDialog(
    BuildContext context, {
    required String title,
    String? content,
    required String no,
    required String yes,
  }) => AlertDialog(
    title: Text(title),
    content: content == null ? null : Text(content),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        child: Text(no),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, true),
        child: Text(yes),
      ),
    ],
  );

  /// Il computer accetta la patta solo se si valuta in svantaggio.
  Future<void> _offerDrawToComputer() async {
    if (_thinking) return;
    final turn = _game.position.turn;
    int? computerScore;
    Object? error;
    var current = false;
    await _whileSuspended<void>(() async {
      final generation = _generation;
      _task = _ComputerTask.draw;
      _refresh(animate: false);
      try {
        final score = _engineGame
            ? await _computerPlayer.evaluate(_game.initial.fen, _moveHistory)
            : await _variantPlayer.evaluate(
                _game.position,
                history: _priorPositions,
              );
        if (score != null) {
          computerScore = turn == _computerSide
              ? score.comparable
              : -score.comparable;
        }
      } on Object catch (e) {
        error = e;
      }
      current = mounted && generation == _generation;
      if (current) {
        _task = _ComputerTask.none;
        _refresh(animate: false);
      }
    }, restart: (_) => !(current && _accepts(computerScore)));
    if (!mounted || !current || _game.isOver) return;
    if (error != null) {
      _showMessage(_l10n(context).gameComputerNoReply);
      return;
    }
    final l10n = _l10n(context);
    final l = _kid ? l10n : null;
    if (_accepts(computerScore)) {
      _game.agreeDraw();
      _endByChoice();
      _showMessage(
        l?.kidGameDrawAccepted(_kidOpponent(l)) ?? l10n.gameComputerAcceptsDraw,
      );
    } else {
      _showMessage(
        l?.kidGameDrawRefused(_kidOpponent(l)) ?? l10n.gameComputerDeclinesDraw,
      );
    }
  }

  bool _accepts(int? computerScore) =>
      computerScore != null && computerScore <= -_drawAcceptanceCp;

  Future<void> _offerDraw() async {
    if (_computerSide != null) return _offerDrawToComputer();
    final opponent = _game.position.turn.opposite;
    final accepted = await _suspendedDialog<bool>((context) {
      if (!_kid) {
        final l10n = _l10n(context);
        return _yesNoDialog(
          context,
          title: switch (_nameOf(opponent)) {
            null => l10n.gameDrawOfferSide(opponent.name),
            final name => l10n.gameDrawOfferNamed(name, opponent.name),
          },
          no: l10n.gameDrawDecline,
          yes: l10n.gameDrawAccept,
        );
      }
      final l = _l10n(context);
      return _yesNoDialog(
        context,
        title: switch (_nameOf(opponent)) {
          null => l.kidGameDrawOfferSide(opponent.name),
          final name => l.kidGameDrawOfferName(name),
        },
        no: l.kidGameDrawNo,
        yes: l.kidGameDrawYes,
      );
    }, restart: (accepted) => accepted != true);
    if (!mounted) return;
    if (accepted == true) {
      _game.agreeDraw();
      _endByChoice();
    }
  }

  LiveAnalysis _liveAnalysis(ComputerPlayer player) =>
      (fen, multiPv) => player.analyseLive(fen, multiPv: multiPv);

  /// Esporta come immagine la posizione mostrata, anche scorrendo le mosse.
  void _exportImage() {
    final ply = _viewPly;
    final Move? last = ply == null
        ? _game.lastMove
        : (ply == -1 ? null : _game.moves[ply].move);
    unawaited(
      openPositionImage(
        context,
        PositionImage(
          fen: _shownPosition.fen,
          orientation: _orientation,
          lastMove: last,
        ),
      ),
    );
  }

  /// Analisi della posizione mostrata con orologio e computer fermi.
  void _openAnalysis() {
    final position = _shownPosition;
    unawaited(
      _withEngine(
        (player) => AnalysisPage(
          initial: position,
          analyse: _liveAnalysis(player),
          orientation: _orientation,
          tablebase: sharedTablebase(),
        ),
      ),
    );
  }

  /// Revisione della partita con orologio e computer fermi.
  void _openReview() {
    final moves = _moveHistory;
    final computer = _computerSide;
    // Contro il computer contano gli errori di chi ha giocato, non quelli
    // del motore.
    final players = computer == null
        ? {Side.white, Side.black}
        : {computer.opposite};
    unawaited(
      _withEngine(
        (player) => ReviewPage(
          initial: _game.initial,
          moves: moves,
          evaluate: engineEvaluator(player),
          onCancel: player.stopAnalysis,
          analyseLive: _liveAnalysis(player),
          onReviewed: (review) => _recordReview(review, players, moves),
          onResult: _saveAccuracy,
          onSavePuzzles: widget.onSavePuzzles,
          puzzlePlayers: players,
          clocks: [for (final m in _game.moves) m.clock],
          timeControl: _clock?.control,
          startTimes: _clock?.startTimes,
        ),
      ),
    );
  }

  /// La precisione della revisione entra nella partita archiviata, così la
  /// scheda delle fasi la trova senza riaprire la partita dall'archivio.
  void _saveAccuracy(GameReview review) {
    final (side, elo) = _playerAndElo;
    final plies = _game.moves.length;
    final known = _reviewed;
    if (side == null || plies == 0) return;
    if (known != null &&
        known.id == _gameId &&
        known.plies == plies &&
        known.review.accuracy(side) == review.accuracy(side)) {
      return;
    }
    _reviewed = (id: _gameId, plies: plies, review: review);
    _archive(_game, side, _clockNow(), elo);
  }

  /// Una revisione nuova vale XP; con due giocatori la precisione non è di
  /// nessuno in particolare e non si registra.
  Future<void> _recordReview(
    GameReview review,
    Set<Side> players,
    List<Move> moves,
  ) async {
    final record = widget.onActivity;
    if (record == null) return;
    final update = await record(
      reviewActivity(review, players, initial: _game.initial, moves: moves),
    );
    if (update != null && mounted) showProgressFeedback(context, update);
  }

  /// Apre una pagina che usa il motore. Nella partita tra due persone il
  /// motore serve solo a quella pagina e si chiude al ritorno.
  Future<void> _withEngine(Widget Function(ComputerPlayer player) page) async {
    final player = _computerPlayer;
    await _whileSuspended(
      () =>
          Navigator.of(context)
              .push(MaterialPageRoute<void>(builder: (_) => page(player))),
    );
    if (_computerSide == null && identical(_computer, player)) {
      _computer = null;
      player.dispose().ignore();
    }
  }

  Widget _statusLine(AppLocalizations? l) {
    final l10n = _l10n(context);
    final (:text, :celebrate) = switch (_task) {
      _ComputerTask.none =>
        l == null
            ? (text: statusText(l10n, _game, _nameOf), celebrate: false)
            : _kidStatus(l),
      _ComputerTask.move => (
        text: l == null
            ? l10n.gameComputerThinking
            : l.kidGameThinking(_kidOpponent(l)),
        celebrate: false,
      ),
      _ComputerTask.draw => (
        text: l == null
            ? l10n.gameComputerEvaluatingDraw
            : l.kidGameDrawThinking(_kidOpponent(l)),
        celebrate: false,
      ),
    };
    return _StatusLine(
      text: text,
      celebrate: celebrate && !_zen,
      mascot:
          _task == _ComputerTask.none &&
          !_zen &&
          showsEndMascot(_game.outcome, _game.endReason, _computerSide),
    );
  }

  Widget? _clockView(Side side) {
    final clock = _clock;
    if (clock == null) return null;
    return ListenableBuilder(
      listenable: _tick,
      builder: (context, _) => _ClockView(
        side: side,
        name: _nameOf(side),
        remaining: clock.remaining(side),
        active: clock.active == side,
      ),
    );
  }

  /// Uscire da una sfida in corso la fa perdere: prima si chiede conferma.
  Future<void> _confirmLeaveChallenge() async {
    final leave = await _suspendedDialog<bool>((context) {
      final l10n = _l10n(context);
      return AlertDialog(
        title: Text(l10n.gameLeaveChallengeTitle),
        content: Text(l10n.gameLeaveChallengeBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.gameContinue),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.gameLeave),
          ),
        ],
      );
    }, restart: (leave) => leave != true);
    if (leave != true || !mounted) return;
    // L'uscita vale una resa: l'esito arriva a chi ha lanciato la sfida.
    final side = _computerSide?.opposite;
    if (side != null && !_game.isOver) {
      _cancelComputerMove();
      _game.resign(side);
      _refresh(animate: false);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    _syncAwake();
    final inProgress = _isChallenge && !_game.isOver && _game.moves.isNotEmpty;
    return PopScope(
      canPop: !inProgress,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_guideOpen) unawaited(_confirmLeaveChallenge());
      },
      child: GuideHost(
        screen: 'game',
        steps: gameGuide,
        // Orologio e computer fermi finché si legge la guida.
        onStart: () {
          _guideOpen = true;
          _suspend();
        },
        onEnd: () {
          // Dopo il tasto indietro che ha chiuso la guida, il gestore della
          // partita non deve aprire anche la conferma di uscita.
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _guideOpen = false,
          );
          _resume();
        },
        child: _buildScaffold(context),
      ),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    // La valutazione della patta è breve: nel frattempo la partita resta com'è.
    final evaluating = _task == _ComputerTask.draw;
    // Solo nel profilo bambino: fuori servono i delegati di localizzazione.
    final l = _kid ? _l10n(context) : null;
    final l10n = _l10n(context);
    final actions = _GameActions(
      kid: l != null,
      labels: l == null
          ? _ActionLabels.adult(l10n)
          : _ActionLabels(
              newGame: l.kidGameNew,
              undo: l.kidGameUndo,
              flip: l.kidGameFlip,
              draw: l.kidGameDraw,
              resign: l.kidGameResign,
              coach: l.kidGameCoach,
              hint: l.kidGameHint,
              rematch: l10n.gameActionRematch,
              review: l10n.gameActionReview,
              threat: l10n.gameActionThreat,
              more: l10n.gameActionMore,
              panelTitle: l10n.gamePanelTitle,
              coachTip: l10n.gameCoachTip,
              threatTip: l10n.gameThreatTip,
              hintTip: l10n.gameHintTip,
            ),
      onNewGame: evaluating || _isChallenge ? null : _newGame,
      onUndo:
          !evaluating && (_canUndo || _pendingMove != null || _viewPly != null)
          ? _requestUndo
          : null,
      onFlip: () => setState(() => _orientation = _orientation.opposite),
      onDraw:
          _game.isOver || _pendingMove != null || _thinking || _computerToMove
          ? null
          : _offerDraw,
      onResign: _game.isOver || _pendingMove != null || evaluating
          ? null
          : _resign,
      over: _game.isOver,
      onRematch: _canRematch ? _rematch : null,
      onReview:
          _game.isOver &&
              !_isChallenge &&
              widget.computerAvailable &&
              _engineGame &&
              !_kid
          ? _openReview
          : null,
      // Nelle sfide niente allenatore; il suggerimento solo se la sfida lo dà.
      coachOn: _computerSide == null || !_helpAllowed || _zen || !_engineGame
          ? null
          : _coachOn,
      onCoach: () {
        setState(() {
          _coachOn = !_coachOn;
          if (!_coachOn) _badge = null;
        });
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        _showMessage(_coachOn ? l10n.gameCoachOn : l10n.gameCoachOff);
      },
      hintAvailable: _computerSide != null && _hintAllowed && _engineGame,
      onHint: _humanToMove && _pendingMove == null ? _giveHint : null,
      onThreat: _humanToMove && _pendingMove == null ? _showThreat : null,
    );
    final keyboardInBar =
        _isChallenge ||
        l != null ||
        MediaQuery.of(context).accessibleNavigation;
    // Il libro delle aperture vale solo per gli scacchi classici; ai bambini
    // i nomi delle aperture non dicono nulla, quelli delle varianti sì (una
    // variante iniziata prima del profilo mostra ancora il conteggio).
    final title = _isChallenge
        ? Text(widget.challenge!.title)
        : _game.variant != Variant.standard
        ? Text(_title)
        : _handicap != null
        ? Text(_l10n(context).handicapGameTitle)
        : l != null
        ? Text(l.appTitle)
        : OpeningName(
            positions: [_game.initial, for (final m in _game.moves) m.after],
            fallback: 'Rokko',
            fallbackWidget: const RokkoWordmark(),
          );
    return Scaffold(
      appBar: AppBar(
        title: _computerSide == null || _zen
            ? title
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  title,
                  Text(
                    // Niente Elo né livelli finché il profilo bambino è attivo
                    // o la partita è iniziata con il profilo.
                    _bot != null
                        ? _kid || _kidGame
                              ? '${_bot!.avatar} ${_bot!.name}'
                              : '${_bot!.avatar} ${_bot!.name} (${_bot!.elo} Elo)'
                        : l != null
                        ? l.kidGameComputer
                        : l10n.gameComputerLevel(
                            _gameLevel,
                            engineLevel(_gameLevel).name,
                          ),
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ],
              ),
        actions: [
          // Una sfida (guardiano, torneo) non si sostituisce con un'altra
          // partita; nel profilo bambino restano nascosti gli strumenti adulti.
          if (!_isChallenge && l == null)
            PopupMenuButton<String>(
              tooltip: l10n.gameMenuTooltip,
              onSelected: (value) {
                if (value == 'review') _openReview();
                if (value == 'analysis') _openAnalysis();
                if (value == 'qrSend') unawaited(_sendQr());
                if (value == 'qrReceive') unawaited(_receiveQr());
                if (value == 'image') _exportImage();
                if (value == 'editor') unawaited(_editPosition());
                if (value == 'typing') unawaited(_typeMove());
              },
              itemBuilder: (context) {
                final l10n = qrL10n(context);
                return [
                  // Stockfish analizza solo gli scacchi classici.
                  if (widget.computerAvailable &&
                      _game.variant == Variant.standard) ...[
                    PopupMenuItem(
                      value: 'analysis',
                      enabled: _task != _ComputerTask.draw,
                      child: Text(_l10n(context).gameMenuAnalysis),
                    ),
                    PopupMenuItem(
                      value: 'review',
                      enabled: _game.moves.isNotEmpty && !_thinking,
                      child: Text(_l10n(context).gameMenuReview),
                    ),
                  ],
                  PopupMenuItem(
                    value: 'image',
                    child: Text(shareImageL10n(context).shareImageTitle),
                  ),
                  PopupMenuItem(
                    value: 'qrSend',
                    // Una posizione dell'editor si può passare anche senza mosse.
                    enabled:
                        (_game.moves.isNotEmpty || _fromEditor) && !_thinking,
                    child: Text(l10n.qrSendTitle),
                  ),
                  PopupMenuItem(
                    value: 'qrReceive',
                    enabled: !_thinking,
                    child: Text(l10n.qrReceiveTitle),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'editor',
                    child: Text(_l10n(context).gameEditorAction),
                  ),
                  if (!keyboardInBar)
                    PopupMenuItem(
                      value: 'typing',
                      enabled:
                          _humanToMove &&
                          _pendingMove == null &&
                          _viewPly == null,
                      child: Text(_l10n(context).gameKeyboardAction),
                    ),
                ];
              },
            ),
          if (_instructor)
            IconButton(
              tooltip: _l10n(context).instructorExplorer,
              icon: const Icon(RokkoIcons.explorer),
              onPressed: _openExplorer,
            ),
          if (keyboardInBar)
            IconButton(
              tooltip: _l10n(context).gameKeyboardAction,
              icon: const Icon(RokkoIcons.keyboard),
              onPressed:
                  !_humanToMove || _pendingMove != null || _viewPly != null
                  ? null
                  : _typeMove,
            ),
          IconButton(
            key: const Key('zenToggle'),
            tooltip: qrL10n(context).settingsZenMode,
            isSelected: _zen,
            icon: const Icon(RokkoIcons.zen),
            selectedIcon: const Icon(RokkoIcons.zenOn),
            onPressed: () {
              // Entrando in zen sparisce anche il commento già a schermo.
              if (!_zen) ScaffoldMessenger.of(context).hideCurrentSnackBar();
              unawaited(
                widget.settings.update(_settings.copyWith(zenMode: !_zen)),
              );
            },
          ),
          IconButton(
            tooltip: l10n.gameSettings,
            icon: const Icon(RokkoIcons.settings),
            onPressed: _openSettings,
          ),
        ],
      ),
      body: Focus(
        autofocus: true,
        onKeyEvent: _onKey,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final landscape =
                  constraints.maxWidth > constraints.maxHeight * 1.2;
              final viewPly = _viewPly;
              // In zen lo stato si vede a fine partita o quando serve un
              // comando; il suo spazio resta riservato perché la scacchiera
              // non cambi misura. Il materiale lascia posto al solo orologio.
              final showStatus =
                  !_zen ||
                  _game.isOver ||
                  viewPly != null ||
                  _pendingMove != null;
              final showMaterial = !_zen || _clock != null;
              final chromeHeight =
                  _moveStripHeight +
                  _statusHeight +
                  _actionsHeight +
                  (showMaterial ? 2 * _materialHeight : 0);
              final showEval = _showEvalBar;
              if (showEval && !_evalBusy && _evalFen != _game.position.fen) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) _scheduleEval();
                });
              }
              final barSpace = showEval ? evalBarWidth + 8 : 0.0;
              final boardSize = landscape
                  ? math.max(
                      0.0,
                      math.min(
                        constraints.maxHeight,
                        constraints.maxWidth * 0.6 - barSpace,
                      ),
                    )
                  : math.max(
                      0.0,
                      math.min(
                        constraints.maxWidth - barSpace,
                        constraints.maxHeight - chromeHeight,
                      ),
                    );
              _messageBottom = landscape
                  ? _actionsHeight + 8
                  : math.min(
                      _actionsHeight +
                          (showMaterial ? 2 * _materialHeight : 0) +
                          boardSize +
                          _statusHeight +
                          8,
                      math.max(
                        _actionsHeight + 8,
                        constraints.maxHeight - 2 * _moveStripHeight,
                      ),
                    );
              final boardSettings = _settings.boardFor(
                phone:
                    MediaQuery.sizeOf(context).shortestSide <
                    MoveMethod.phoneWidth,
              );
              final rawBoard = BoardFrame.of(
                _settings,
                size: boardSize,
                orientation: _orientation,
                builder: (size) => BoardDrawing(
                  size: size,
                  orientation: _orientation,
                  color: _settings.markColor.color,
                  enabled: _settings.drawShapes,
                  canStartAt: _canDragFrom,
                  resetKey: (_game.position.fen, _viewPly),
                  drawing: _drawing,
                  shapeOf: (color, orig, dest) => dest == null
                      ? _settings.marks.circle(color, orig)
                      : _settings.marks.arrow(color, orig, dest),
                  builder: (marks) => TapAssist(
                    size: size,
                    orientation: _orientation,
                    enabled:
                        boardSettings.pieceShiftMethod !=
                            PieceShiftMethod.drag &&
                        _humanToMove &&
                        _viewPly == null &&
                        _pendingMove == null,
                    resetKey: _game.position.fen,
                    destinations: _tapTargets,
                    onMove: (from, to) =>
                        _onMove(NormalMove(from: from, to: to)),
                    child: BoardSwipe(
                      enabled: _pendingMove == null && _game.moves.isNotEmpty,
                      size: size,
                      orientation: _orientation,
                      canStartAt: _canDragFrom,
                      blocked: _drawing,
                      onSwipe: _swipe,
                      child: Chessboard(
                        size: size,
                        controller: _board,
                        orientation: _orientation,
                        onMove: _onMove,
                        settings: boardSettings,
                        annotations: _badgeAnnotations(),
                        shapes: {..._visibleHint(), ...marks},
                      ),
                    ),
                  ),
                ),
              );
              final board = GuideAnchor(id: 'game.board', child: rawBoard);
              final Widget boardArea = !showEval
                  ? board
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        EvalBar(
                          height: boardSize,
                          score: _evalScore,
                          whiteWin: _evalWhiteWin,
                        ),
                        const SizedBox(width: 8),
                        board,
                      ],
                    );
              final Widget status = !showStatus
                  ? const SizedBox(height: _statusHeight)
                  : viewPly != null
                  ? _ViewBar(
                      text: viewPly == -1
                          ? l10n.gameViewStart
                          : l10n.gameViewAfter(
                              moveLabel(
                                _game,
                                viewPly,
                                number: true,
                                notation: AppSettings.of(context).notation,
                              ),
                            ),
                      onPrevious: viewPly > -1
                          ? () => _showPly(viewPly - 1)
                          : null,
                      onNext: () => _showPly(viewPly + 1),
                      onBack: () => _showPly(null),
                    )
                  : _pendingMove == null
                  ? _statusLine(l)
                  : _ConfirmBar(
                      onConfirm: _confirmPending,
                      onDiscard: _discardPending,
                    );
              final moves = _MoveList(
                game: _game,
                horizontal: !landscape,
                selected: viewPly,
                onSelect: _showPly,
              );
              final balance = MaterialBalance.of(
                viewPly == null
                    ? _game
                    : ChessGame.replay(
                            _game.initial,
                            _game.moves.take(viewPly + 1).map((m) => m.move),
                            variant: _game.variant,
                          ) ??
                          _game,
              );
              final topMaterial = _MaterialRow(
                balance: balance,
                side: _orientation.opposite,
                name: _nameOf(_orientation.opposite),
                pieceAssets: _settings.pieceAssets,
                zen: _zen,
                clock: _clockView(_orientation.opposite),
              );
              final bottomMaterial = _MaterialRow(
                balance: balance,
                side: _orientation,
                name: _nameOf(_orientation),
                pieceAssets: _settings.pieceAssets,
                zen: _zen,
                clock: _clockView(_orientation),
              );
              if (landscape) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    boardArea,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          topMaterial,
                          status,
                          Expanded(child: moves),
                          bottomMaterial,
                          actions,
                        ],
                      ),
                    ),
                  ],
                );
              }
              // Il blocco scacchiera sta contro i comandi; lo spazio che resta
              // sopra serve alle mosse e, la prima volta, ai suggerimenti.
              return Column(
                children: [
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, box) {
                        _speechRoom =
                            !_zen &&
                            box.maxHeight >=
                                _moveStripHeight + speechStripHeight;
                        final tip =
                            box.maxHeight >= _moveStripHeight + _bannerHeight
                            ? _banner(context)
                            : null;
                        // Il fumetto ha la precedenza sul suggerimento; lo
                        // sfidante resta in vista quando non c'è altro.
                        final banner = _speechRoom && _speech != null
                            ? _strip()
                            : tip ??
                                  (_speechRoom && _bot != null
                                      ? _strip()
                                      : null);
                        return Column(
                          children: [
                            ?banner,
                            Expanded(
                              child: GuideAnchor(
                                id: 'game.moves',
                                child:
                                    _game.moves.isEmpty &&
                                        !_game.isOver &&
                                        !_computerToMove
                                    ? _FirstMoveHint(
                                        text: _l10n(context).gameFirstMoveHint,
                                      )
                                    : LayoutBuilder(
                                        builder: (context, area) => _MoveList(
                                          game: _game,
                                          horizontal:
                                              area.maxHeight <
                                              2 * _moveStripHeight,
                                          selected: viewPly,
                                          onSelect: _showPly,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  status,
                  topMaterial,
                  boardArea,
                  bottomMaterial,
                  actions,
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Operazione in corso del computer.
enum _ComputerTask { none, move, draw }

const int _drawAcceptanceCp = 50;
const String _tipsKey = 'gameTips';
const String _reviewInviteKey = 'gameReviewInvite';
const int _tipsDoneMark = 99;
const double _moveStripHeight = 40;
const double _bannerHeight = 112;
const double _statusHeight = 48;
const double _actionsHeight = 72;
const double _materialHeight = 36;

/// "il Bianco", oppure "Anna (Bianco)" se il giocatore ha un nome.
String _player(
  AppLocalizations l10n,
  Side side,
  String? Function(Side)? nameOf,
) {
  final name = nameOf?.call(side);
  return name == null
      ? l10n.gamePlayerSide(side.name)
      : l10n.gamePlayerNamed(name, side.name);
}

/// La torre sorridente accompagna la fine di una partita, tranne quando il
/// giocatore perde contro il computer.
bool showsEndMascot(Outcome? outcome, GameEndReason? reason, Side? computer) =>
    reason != null &&
    (outcome?.winner == null ||
        computer == null ||
        outcome?.winner != computer);

/// Stato della partita; [nameOf] affianca al colore il nome scelto.
String statusText(
  AppLocalizations l10n,
  ChessGame game, [
  String? Function(Side)? nameOf,
]) {
  String player(Side side) => _player(l10n, side, nameOf);
  final named =
      nameOf?.call(Side.white) != null || nameOf?.call(Side.black) != null;

  final turn = game.position.turn;
  return switch (game.endReason) {
    null =>
      game.position.isCheck
          ? named
                ? l10n.gameStatusCheckNamed(player(turn))
                : l10n.gameStatusCheckSide(turn.name, player(turn))
          : l10n.gameStatusMove(player(turn)),
    GameEndReason.checkmate => l10n.gameStatusCheckmate(player(turn.opposite)),
    GameEndReason.resignation => l10n.gameStatusResignation(
      player(game.outcome!.winner!),
    ),
    GameEndReason.stalemate => l10n.gameStatusStalemate,
    GameEndReason.insufficientMaterial => l10n.gameStatusInsufficientMaterial,
    GameEndReason.threefoldRepetition => l10n.gameStatusRepetition,
    GameEndReason.fiftyMoveRule => l10n.gameStatusFiftyMoves,
    GameEndReason.agreement => l10n.gameStatusAgreedDraw,
    GameEndReason.variantEnd => switch (game.variant) {
      Variant.kingOfTheHill => l10n.gameStatusKingOfTheHill(
        game.outcome!.winner!.name,
      ),
      Variant.threeCheck => l10n.gameStatusThirdCheck(
        game.outcome!.winner!.name,
      ),
      // Senza una vittoria propria della variante non si arriva qui.
      Variant.standard || Variant.chess960 => l10n.gameStatusOver,
    },
    GameEndReason.timeout =>
      game.outcome!.winner == null
          ? l10n.gameStatusTimeoutDraw
          : l10n.gameStatusTimeout(player(game.outcome!.winner!)),
  };
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({
    required this.text,
    this.celebrate = false,
    this.mascot = false,
  });

  final String text;

  /// Aggiunge una festa visiva che il lettore di schermo non legge.
  final bool celebrate;

  /// La torre accanto all'esito, a partita finita.
  final bool mascot;

  @override
  Widget build(BuildContext context) {
    Widget line(String s) => Text(
      s,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.titleMedium,
    );
    return SizedBox(
      height: _statusHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              if (mascot) ...[
                const RokkoMascot(size: _statusHeight - 12),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: celebrate
                    ? Semantics(
                        label: text,
                        excludeSemantics: true,
                        child: line('$text 🎉'),
                      )
                    : line(text),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Prima mossa: al posto della lista vuota dice cosa fare, vicino al pezzo.
class _FirstMoveHint extends StatelessWidget {
  const _FirstMoveHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) => box.maxHeight < _moveStripHeight
        ? const SizedBox.shrink()
        : Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Text(
                text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
  );
}

class _MoveList extends StatelessWidget {
  const _MoveList({
    required this.game,
    required this.horizontal,
    required this.selected,
    required this.onSelect,
  });

  final ChessGame game;
  final bool horizontal;
  final int? selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final moves = game.moves;
    final theme = Theme.of(context);
    Widget item(int i) {
      final isSelected = i == selected;
      final chip = InkWell(
        key: ValueKey('move-$i'),
        borderRadius: BorderRadius.circular(4),
        onTap: () => onSelect(i),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: isSelected
              ? BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(4),
                )
              : null,
          child: Text(
            moveLabel(game, i, notation: AppSettings.of(context).notation),
            style: theme.textTheme.bodyLarge,
          ),
        ),
      );
      return isSelected ? _KeepVisible(child: chip) : chip;
    }

    if (horizontal) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        // Ancorata a destra: l'ultima mossa resta visibile.
        reverse: true,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            for (var i = 0; i < moves.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              item(i),
            ],
          ],
        ),
      );
    }
    return SingleChildScrollView(
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [for (var i = 0; i < moves.length; i++) item(i)],
      ),
    );
  }
}

/// Etichette dei comandi; nel profilo bambino cambiano alcune parole.
class _ActionLabels {
  const _ActionLabels({
    required this.newGame,
    required this.undo,
    required this.flip,
    required this.draw,
    required this.resign,
    required this.coach,
    required this.hint,
    required this.rematch,
    required this.review,
    required this.threat,
    required this.more,
    required this.panelTitle,
    required this.coachTip,
    required this.threatTip,
    required this.hintTip,
  });

  factory _ActionLabels.adult(AppLocalizations l) => _ActionLabels(
    newGame: l.gameActionNew,
    undo: l.gameActionUndo,
    flip: l.gameActionFlip,
    draw: l.gameActionDraw,
    resign: l.gameActionResign,
    coach: l.gameActionCoach,
    hint: l.gameActionHint,
    rematch: l.gameActionRematch,
    review: l.gameActionReview,
    threat: l.gameActionThreat,
    more: l.gameActionMore,
    panelTitle: l.gamePanelTitle,
    coachTip: l.gameCoachTip,
    threatTip: l.gameThreatTip,
    hintTip: l.gameHintTip,
  );

  final String newGame;
  final String undo;
  final String flip;
  final String draw;
  final String resign;
  final String coach;
  final String hint;
  final String threat;
  final String more;
  final String rematch;
  final String review;
  final String panelTitle;
  final String coachTip;
  final String threatTip;
  final String hintTip;
}

/// Barra dei comandi in vista; il pannello «Partita» tiene gli altri.
///
/// Gli adulti hanno in barra anche Nuova, Patta e Abbandona; ai bambini
/// restano tre comandi grandi e il resto nel pannello.
class _GameActions extends StatelessWidget {
  const _GameActions({
    required this.kid,
    required this.labels,
    required this.onNewGame,
    required this.onUndo,
    required this.onFlip,
    required this.onDraw,
    required this.onResign,
    required this.over,
    required this.onRematch,
    required this.onReview,
    required this.coachOn,
    required this.onCoach,
    required this.hintAvailable,
    required this.onHint,
    required this.onThreat,
  });

  final bool kid;
  final _ActionLabels labels;
  final VoidCallback? onNewGame;
  final VoidCallback? onUndo;
  final VoidCallback onFlip;
  final VoidCallback? onDraw;
  final VoidCallback? onResign;

  /// A partita finita Patta e Abbandona non servono più: al loro posto
  /// Rivincita e, dove c'è il motore, Rivedi.
  final bool over;
  final VoidCallback? onRematch;
  final VoidCallback? onReview;

  /// `null` nella partita tra due persone, dove l'allenatore non c'è.
  final bool? coachOn;
  final VoidCallback onCoach;

  /// Il suggerimento non dipende dall'allenatore, ma non c'è nelle sfide.
  final bool hintAvailable;
  final VoidCallback? onHint;

  /// Solo con l'allenatore acceso.
  final VoidCallback? onThreat;

  /// Nel profilo bambino «Gira» cede il posto al suggerimento.
  bool get _flipInPanel => kid && hintAvailable;

  /// Sotto questa larghezza i pulsanti scenderebbero sotto i 48 dp.
  static const double _fullBarWidth = 7 * 48;

  /// Gli adulti hanno Nuova, Patta e Abbandona sempre in vista.
  bool get _gameInBar => !kid;

  void _openPanel(BuildContext context, {required bool flipInPanel}) {
    final theme = Theme.of(context);
    void pick(BuildContext sheet, VoidCallback? action) {
      Navigator.of(sheet).pop();
      action?.call();
    }

    unawaited(
      showRokkoSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (sheet) => SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                  child: Semantics(
                    header: true,
                    child: Text(
                      labels.panelTitle,
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                ),
                if (!_gameInBar)
                  _PanelTile(
                    RokkoIcons.newGame,
                    labels.newGame,
                    onNewGame,
                    kid: kid,
                    pick: pick,
                  ),
                if (!_gameInBar && over && onRematch != null)
                  _PanelTile(
                    RokkoIcons.rematch,
                    labels.rematch,
                    onRematch,
                    kid: kid,
                    pick: pick,
                  ),
                if (flipInPanel)
                  _PanelTile(
                    RokkoIcons.flip,
                    labels.flip,
                    onFlip,
                    kid: kid,
                    pick: pick,
                  ),
                if (!_gameInBar && !over) ...[
                  _PanelTile(
                    RokkoIcons.draw,
                    labels.draw,
                    onDraw,
                    kid: kid,
                    pick: pick,
                  ),
                  _PanelTile(
                    RokkoIcons.resign,
                    labels.resign,
                    onResign,
                    kid: kid,
                    pick: pick,
                  ),
                ],
                if (coachOn != null)
                  SwitchListTile(
                    secondary: const Icon(RokkoIcons.coach),
                    title: Text(labels.coach),
                    subtitle: Text(labels.coachTip),
                    value: coachOn!,
                    onChanged: (_) => pick(sheet, onCoach),
                  ),
                if (coachOn ?? false)
                  _PanelTile(
                    RokkoIcons.threat,
                    labels.threat,
                    onThreat,
                    kid: kid,
                    pick: pick,
                    subtitle: labels.threatTip,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _actionsHeight,
      child: LayoutBuilder(
        builder: (context, box) {
          // Su schermi stretti «Gira» passa nel pannello per non schiacciare
          // i pulsanti.
          final flipInPanel =
              _flipInPanel || (_gameInBar && box.maxWidth < _fullBarWidth);
          final hasPanel = !_gameInBar || coachOn != null || flipInPanel;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (hintAvailable)
                _ActionButton(
                  'hint',
                  RokkoIcons.hint,
                  labels.hint,
                  onHint,
                  tooltip: labels.hintTip,
                ),
              _ActionButton('undo', RokkoIcons.undo, labels.undo, onUndo),
              if (!flipInPanel)
                _ActionButton('flip', RokkoIcons.flip, labels.flip, onFlip),
              if (_gameInBar) ...[
                _ActionButton(
                  'new',
                  RokkoIcons.newGame,
                  labels.newGame,
                  onNewGame,
                ),
                if (over) ...[
                  if (onRematch != null)
                    _ActionButton(
                      'rematch',
                      RokkoIcons.rematch,
                      labels.rematch,
                      onRematch,
                    ),
                  if (onReview != null)
                    _ActionButton(
                      'review',
                      RokkoIcons.review,
                      labels.review,
                      onReview,
                    ),
                ] else ...[
                  _ActionButton('draw', RokkoIcons.draw, labels.draw, onDraw),
                  _ActionButton(
                    'resign',
                    RokkoIcons.resign,
                    labels.resign,
                    onResign,
                  ),
                ],
              ],
              if (hasPanel)
                _ActionButton(
                  'more',
                  RokkoIcons.more,
                  labels.more,
                  () => _openPanel(context, flipInPanel: flipInPanel),
                  dot: coachOn ?? false,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _PanelTile extends StatelessWidget {
  const _PanelTile(
    this.icon,
    this.label,
    this.onTap, {
    required this.kid,
    required this.pick,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool kid;
  final void Function(BuildContext, VoidCallback?) pick;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final tokens = RokkoTokens.of(context);
    return ListTile(
      minTileHeight: kid ? tokens.kidTouch : tokens.minTouch,
      leading: Icon(icon),
      title: Text(label),
      subtitle: subtitle == null ? null : Text(subtitle!),
      enabled: onTap != null,
      onTap: onTap == null ? null : () => pick(context, onTap),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton(
    this.id,
    this.icon,
    this.label,
    this.onPressed, {
    this.tooltip,
    this.dot = false,
  });

  /// Punto sull'icona: un comando del pannello è acceso, come l'allenatore.
  final bool dot;
  final String id;
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = onPressed == null
        ? Theme.of(context).disabledColor
        : scheme.onSurface;
    // Senza Semantics il lettore di schermo non annuncia un pulsante né il suo stato.
    Widget button = GuideAnchor(
      id: 'game.action.$id',
      child: Semantics(
        button: true,
        enabled: onPressed != null,
        child: InkWell(
          key: ValueKey('gameAction-$id'),
          onTap: onPressed,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Badge(
                smallSize: 8,
                isLabelVisible: dot,
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.labelMedium
                        ?.copyWith(color: color),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (tooltip != null && onPressed != null) {
      button = Tooltip(message: tooltip, child: button);
    }
    return Expanded(child: button);
  }
}

/// Suggerimento o invito sopra la scacchiera, sempre ignorabile.
class _TipCard extends StatelessWidget {
  const _TipCard({
    super.key,
    required this.text,
    required this.closeLabel,
    required this.onClose,
    this.actionLabel,
    this.onAction,
  });

  final String text;
  final String closeLabel;
  final VoidCallback onClose;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8, right: 8),
                child: Text(
                  text,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              Wrap(
                alignment: WrapAlignment.end,
                children: [
                  if (actionLabel != null)
                    TextButton(onPressed: onAction, child: Text(actionLabel!)),
                  TextButton(
                    key: const ValueKey('gameTipClose'),
                    onPressed: onClose,
                    child: Text(closeLabel),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MaterialRow extends StatelessWidget {
  const _MaterialRow({
    required this.balance,
    required this.side,
    required this.name,
    required this.pieceAssets,
    this.zen = false,
    this.clock,
  });

  final MaterialBalance balance;
  final Side side;
  final String? name;
  final PieceAssets pieceAssets;

  /// In zen restano solo l'orologio, se c'è.
  final bool zen;
  final Widget? clock;

  @override
  Widget build(BuildContext context) {
    if (zen) {
      return clock == null
          ? const SizedBox.shrink()
          : SizedBox(
              height: _materialHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Align(alignment: Alignment.centerRight, child: clock),
              ),
            );
    }
    final advantage = balance.advantage(side);
    final opponent = side.opposite;
    final captured = balance.capturedBy(side);
    final l10n = _l10n(context);
    final description = l10n.gameMaterial(
      name == null
          ? l10n.gameSideName(side.name)
          : l10n.gameMaterialWho(name!, side.name),
      captured.isEmpty ? 'none' : 'some',
      captured.map((r) => l10n.gamePieceName(r.name)).join(', '),
      math.max(0, advantage),
    );
    final material = Semantics(
      label: description,
      excludeSemantics: true,
      child: Align(
        alignment: Alignment.centerLeft,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            children: [
              for (final (i, role) in captured.indexed)
                // Nel tema scuro un pezzo nero sullo sfondo scuro sparisce:
                // un fondo grigio medio tiene almeno 3:1 con nero e bianco.
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF8A8A8A)
                        : null,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Image(
                    key: ValueKey('captured-${opponent.name}-${role.name}-$i'),
                    image:
                        pieceAssets[Piece(color: opponent, role: role).kind]!,
                    width: 20,
                    height: 20,
                  ),
                ),
              if (advantage > 0) ...[
                const SizedBox(width: 6),
                Text(
                  '+$advantage',
                  key: ValueKey('advantage-${side.name}'),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ],
            ],
          ),
        ),
      ),
    );
    return SizedBox(
      height: _materialHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            if (name != null) ...[
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 120),
                // Già letto nella descrizione del materiale.
                child: ExcludeSemantics(
                  child: Text(
                    name!,
                    key: ValueKey('player-${side.name}'),
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(child: material),
            ?clock,
          ],
        ),
      ),
    );
  }
}

class _ClockView extends StatelessWidget {
  const _ClockView({
    required this.side,
    required this.name,
    required this.remaining,
    required this.active,
  });

  final Side side;
  final String? name;
  final Duration remaining;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final low = active && isLowTime(remaining);
    final background = low
        ? scheme.error
        : active
        ? scheme.primary
        : scheme.surfaceContainerHighest;
    final foreground = low
        ? scheme.onError
        : active
        ? scheme.onPrimary
        : scheme.onSurfaceVariant;
    final l10n = _l10n(context);
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;
    return Semantics(
      label: name == null
          ? l10n.gameClockOfSide(side.name, minutes, seconds)
          : l10n.gameClockOfName(name!, minutes, seconds),
      excludeSemantics: true,
      child: Container(
        key: active ? const ValueKey('clock-active') : null,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          formatClock(remaining),
          key: ValueKey('clock-${side.name}'),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: foreground,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}

class _TimeChoice {
  const _TimeChoice(
    this.control,
    this.variant,
    this.whiteName,
    this.blackName,
    this.setup,
    this.handicap, {
    this.coach = false,
    this.training,
  });

  final TimeControl? control;
  final Variant variant;
  final String whiteName;
  final String blackName;
  final GameSetup setup;
  final Handicap? handicap;

  /// Allenatore acceso dall'inizio, scelto nella galleria dei bot.
  final bool coach;

  /// Allenamento scelto nella galleria dei bot; `null` tiene l'ultima scelta.
  final bool? training;
}

/// Testi della schermata; in italiano se la pagina è montata senza i
/// delegati di localizzazione (per esempio nei test della home).
AppLocalizations _l10n(BuildContext context) =>
    Localizations.of<AppLocalizations>(context, AppLocalizations) ??
    lookupAppLocalizations(const Locale('it'));

/// Cadenza lenta del profilo bambino: 15+10, l'unica Rapid con incremento,
/// così una mossa pensata a lungo restituisce un po' di tempo.
final _kidClock = TimeControl.presets.firstWhere(
  (t) => t.minutes == 15 && t.increment == 10,
);

/// Scelta dell'avversario per una posizione creata con l'editor (RF-24).
class _PositionSheet extends StatefulWidget {
  const _PositionSheet({
    required this.setup,
    required this.adaptiveLevel,
    required this.collection,
    required this.kidMode,
  });

  final GameSetup setup;
  final int adaptiveLevel;
  final BotCollection collection;
  final bool kidMode;

  @override
  State<_PositionSheet> createState() => _PositionSheetState();
}

class _PositionSheetState extends State<_PositionSheet> {
  late GameSetup _setup = widget.setup;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          _l10n(context).gamePositionPlayTitle,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        OpponentPicker(
          setup: _setup,
          adaptiveLevel: widget.adaptiveLevel,
          collection: widget.collection,
          computerAvailable: true,
          kidMode: widget.kidMode,
          onChanged: (setup) => setState(() => _setup = setup),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => Navigator.pop(context, _setup),
          child: Text(_l10n(context).gamePlay),
        ),
      ],
    ),
  );
}

/// Pagina del foglio «Nuova partita»: il menu, la sfida a un amico (dove si
/// gioca, poi come ci si raggiunge) e la scelta completa.
enum _SheetView { menu, friend, friendApart, custom }

/// Voce del menu che apre un'altra pagina al posto della partita.
class _SheetRun {
  const _SheetRun(this.run);

  final Future<void> Function(BuildContext context) run;
}

/// Scelta di avversario, variante, nomi e cadenza: toccare una cadenza avvia
/// la partita.
class _TimeControlSheet extends StatefulWidget {
  const _TimeControlSheet({
    required this.kid,
    required this.variant,
    required this.whiteName,
    required this.blackName,
    required this.setup,
    required this.adaptiveLevel,
    required this.collection,
    required this.computerAvailable,
    required this.kidMode,
    required this.training,
    this.tournamentPage,
    this.physicalPage,
    this.openingGame,
    this.onActivity,
  });

  /// Registra nei progressi le partite a due telefoni.
  final ActivityRecorder? onActivity;

  /// Profilo bambino: solo classica, senza tempo o con una cadenza lenta.
  final bool kid;
  final Variant variant;
  final String whiteName;
  final String blackName;
  final GameSetup setup;
  final int adaptiveLevel;
  final BotCollection collection;
  final bool computerAvailable;
  final bool kidMode;

  /// Ultima scelta tra Allenamento e Sfida, proposta nella galleria dei bot.
  final bool training;

  /// Pagine dei tornei e della scacchiera fisica, se la home le offre.
  final Future<Widget> Function()? tournamentPage;
  final Widget Function()? physicalPage;

  /// Avvia la partita con l'istruttore (come dal menu Aperture); senza, la voce
  /// «Gioca con l'istruttore» del foglio accende l'allenatore nella partita.
  final Future<void> Function(BuildContext, OpeningGameRequest)? openingGame;

  @override
  State<_TimeControlSheet> createState() => _TimeControlSheetState();
}

class _TimeControlSheetState extends State<_TimeControlSheet> {
  late Variant _variant = widget.variant;
  // Il profilo bambino ha subito la scelta completa; gli altri partono dal menu.
  late _SheetView _view = widget.kid || widget.kidMode
      ? _SheetView.custom
      : _SheetView.menu;
  TimeControl? _quickControl;
  // Si parte dal bot adattivo, del livello del giocatore; il computer a livello
  // fisso non ha più una scelta nel foglio e ripiega sul bot.
  late GameSetup _setup = !widget.computerAvailable
      ? widget.setup.copyWith(opponent: Opponent.human)
      : widget.setup.opponent == Opponent.computer && !widget.setup.adaptive
      ? widget.setup.copyWith(opponent: Opponent.bot)
      : widget.setup.opponent == Opponent.human &&
            !widget.kid &&
            !widget.kidMode
      ? widget.setup.copyWith(opponent: Opponent.computer, adaptive: true)
      : widget.setup;
  late final _white = TextEditingController(text: widget.whiteName);
  late final _black = TextEditingController(text: widget.blackName);
  HandicapPiece? _handicapPiece;
  int? _handicapMinutes;
  var _handicapGiver = HandicapGiver.player;
  bool get _fromMenu => !(widget.kid || widget.kidMode);

  Handicap? get _handicap => _handicapPiece == null && _handicapMinutes == null
      ? null
      : Handicap(
          piece: _handicapPiece,
          giverMinutes: _handicapMinutes,
          giver: _handicapGiver,
        );

  @override
  void dispose() {
    _white.dispose();
    _black.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GuideHost(
    screen: 'newGame',
    steps: newGameGuide,
    child: SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: ListView(
          // Ogni pagina riparte dall'alto.
          key: ValueKey(_view),
          shrinkWrap: true,
          padding: const EdgeInsets.all(16),
          children: switch (_view) {
            _SheetView.menu => _menuChildren(context),
            _SheetView.friend => _friendChildren(context),
            _SheetView.friendApart => _friendApartChildren(context),
            _SheetView.custom => _customChildren(context),
          },
        ),
      ),
    ),
  );

  List<Widget> _customChildren(BuildContext context) {
    final theme = Theme.of(context);
    // Fuori dal profilo bambino i testi restano fissi: i test montano la
    // pagina anche senza delegati di localizzazione.
    final l10n = _l10n(context);
    final l = widget.kid ? l10n : null;
    final noClock = l?.kidGameNoClock ?? l10n.gameNoClock;
    final groups = TimeControl.presetsByCategory;
    Widget chip(String label, TimeControl? control) => ActionChip(
      label: Text(label),
      onPressed: () => Navigator.pop(
        context,
        _TimeChoice(
          control,
          _variant,
          _white.text,
          _black.text,
          _setup,
          _handicap,
        ),
      ),
    );
    Widget nameField(TextEditingController controller, String label) =>
        Expanded(
          child: TextField(
            controller: controller,
            maxLength: AppSettings.maxNameLength,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: label,
              hintText: l?.kidGameNameHint ?? l10n.gameNameHint,
              counterText: '',
            ),
          ),
        );
    return [
      _header(
        context,
        l?.kidGameNew ??
            (_setup.opponent == Opponent.human
                ? l10n.gameCustomTwoPlayers
                : l10n.gameMenuCustomTitle),
        back: _fromMenu ? _SheetView.menu : null,
      ),
      const SizedBox(height: 8),
      OpponentPicker(
        setup: _setup,
        adaptiveLevel: widget.adaptiveLevel,
        collection: widget.collection,
        computerAvailable: widget.computerAvailable,
        kidMode: widget.kidMode,
        onChanged: (setup) => setState(() => _setup = setup),
        galleryOptions: GameOptions(
          variant: _variant,
          handicap: _handicap,
          training: widget.training,
        ),
        onGalleryPlay: (result) => Navigator.pop(
          context,
          _TimeChoice(
            result.options.control,
            result.options.variant,
            _white.text,
            _black.text,
            result.applyTo(widget.kidMode ? _setup.forKids() : _setup),
            result.options.handicap,
            coach: result.options.coach,
            training: result.options.training,
          ),
        ),
      ),
      if (_setup.opponent == Opponent.human) ...[
        const SizedBox(height: 8),
        Row(
          children: [
            nameField(_white, l?.kidGameWhiteName ?? l10n.gameWhiteName),
            const SizedBox(width: 12),
            nameField(_black, l?.kidGameBlackName ?? l10n.gameBlackName),
          ],
        ),
      ],
      if (l == null) ...[
        const SizedBox(height: 16),
        Text(l10n.gameVariantTitle, style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final v in Variant.values)
              ChoiceChip(
                label: Text(v.label(l10n)),
                selected: v == _variant,
                onSelected: (_) => setState(() {
                  _variant = v;
                  // Il pezzo in meno vale solo negli scacchi classici.
                  if (v != Variant.standard) _handicapPiece = null;
                }),
              ),
          ],
        ),
        if (_variant.description(l10n).isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(_variant.description(l10n)),
        ],
      ],
      ...[
        if (l == null) ..._handicapSection(context),
        const SizedBox(height: 12),
        if (l != null) ...[
          Text(l.kidGameTimeTitle, style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          // Bullet e Blitz mettono fretta: ai bambini solo tempi lunghi.
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              chip(noClock, null),
              chip(l.kidGameSlowClock, _kidClock),
            ],
          ),
        ] else ...[
          Text(l10n.gameTimeControlTitle, style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          chip(noClock, null),
          const SizedBox(height: 8),
          ActionChip(
            key: const ValueKey('clock-custom'),
            avatar: const Icon(Icons.tune, size: 18),
            label: Text(l10n.gameClockCustom),
            onPressed: () async {
              final control = await showCustomClockDialog(context);
              if (control == null || !context.mounted) return;
              Navigator.pop(
                context,
                _TimeChoice(
                  control,
                  _variant,
                  _white.text,
                  _black.text,
                  _setup,
                  _handicap,
                ),
              );
            },
          ),
          for (final entry in groups.entries) ...[
            const SizedBox(height: 12),
            Text(
              timeCategoryName(l10n, entry.key),
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [for (final t in entry.value) chip(t.label, t)],
            ),
          ],
        ],
      ],
    ];
  }

  Widget _header(BuildContext context, String title, {_SheetView? back}) {
    final text = Text(title, style: Theme.of(context).textTheme.titleLarge);
    if (back == null) return text;
    return Row(
      children: [
        IconButton(
          tooltip: _l10n(context).gameBack,
          icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() => _view = back),
        ),
        Expanded(child: text),
      ],
    );
  }

  Widget _tile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    Key? key,
    String? anchor,
  }) {
    final tile = Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Card(
        key: key,
        margin: EdgeInsets.zero,
        child: ListTile(
          minVerticalPadding: 12,
          leading: Icon(icon, size: 32),
          title: Text(title, style: Theme.of(context).textTheme.titleMedium),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      ),
    );
    return anchor == null ? tile : GuideAnchor(id: anchor, child: tile);
  }

  /// Partita contro il computer del livello del giocatore, o in due se manca
  /// il motore.
  GameSetup get _quickSetup => widget.computerAvailable
      ? _setup.copyWith(opponent: Opponent.computer, adaptive: true)
      : _setup.copyWith(opponent: Opponent.human);

  _TimeChoice _quickChoice({bool coach = false}) => _TimeChoice(
    _quickControl,
    Variant.standard,
    _white.text,
    _black.text,
    _quickSetup,
    null,
    coach: coach,
  );

  List<Widget> _menuChildren(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = _l10n(context);
    final engine = widget.computerAvailable;
    final level = engineLevel(widget.adaptiveLevel);
    final tournaments = widget.tournamentPage;
    final physical = widget.physicalPage;
    return [
      _header(context, l10n.gameNewTitle),
      const SizedBox(height: 12),
      GuideAnchor(
        id: 'newGame.clock',
        child: DropdownButtonFormField<TimeControl?>(
          key: const ValueKey('quick-clock'),
          initialValue: _quickControl,
          isExpanded: true,
          decoration: InputDecoration(labelText: l10n.gameQuickClock),
          items: [
            DropdownMenuItem(child: Text(l10n.gameNoClock)),
            for (final c in TimeControl.presets)
              DropdownMenuItem(
                value: c,
                child: Text(
                  '${timeCategoryName(l10n, c.category)} · ${c.label}',
                ),
              ),
          ],
          onChanged: (v) => setState(() => _quickControl = v),
        ),
      ),
      const SizedBox(height: 12),
      GuideAnchor(
        id: 'newGame.quick',
        child: FilledButton(
          key: const ValueKey('quick-start'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(76),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onPressed: () => Navigator.pop(context, _quickChoice()),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.gameQuickStart,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onPrimary,
                ),
              ),
              Text(
                engine
                    ? l10n.gameQuickVsComputer(level.id, level.approxElo)
                    : l10n.gameQuickTwoPlayers,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 8),
      _tile(
        Icons.people_outline,
        l10n.gameMenuFriendTitle,
        l10n.gameMenuFriendSubtitle,
        () => setState(() => _view = _SheetView.friend),
        key: const ValueKey('menu-friend'),
        anchor: 'newGame.friend',
      ),
      if (engine) ...[
        _tile(
          Icons.emoji_people_outlined,
          l10n.gameMenuBotsTitle,
          l10n.gameMenuBotsSubtitle,
          () async {
            final result = await openBotGallery(
              context,
              collection: widget.collection,
              setup: _setup,
              adaptiveLevel: widget.adaptiveLevel,
              kidMode: false,
              options: GameOptions(
                control: _quickControl,
                training: widget.training,
              ),
            );
            if (result == null || !context.mounted) return;
            Navigator.pop(
              context,
              _TimeChoice(
                result.options.control,
                result.options.variant,
                _white.text,
                _black.text,
                result.applyTo(_setup),
                result.options.handicap,
                coach: result.options.coach,
                training: result.options.training,
              ),
            );
          },
          key: const Key('open-bot-gallery'), // l10n-ok
          anchor: 'newGame.bots',
        ),
        _tile(
          Icons.school_outlined,
          l10n.gameMenuInstructorTitle,
          l10n.gameMenuInstructorSubtitle,
          () {
            final play = widget.openingGame;
            if (play == null) {
              Navigator.pop(context, _quickChoice(coach: true));
              return;
            }
            final title = AppLocalizations.of(context).instructorTitle;
            Navigator.pop(
              context,
              _SheetRun((context) async {
                final choice = await askOpeningGame(context, Side.white);
                if (choice == null || !context.mounted) return;
                await play(
                  context,
                  OpeningGameRequest.explorer(
                    title,
                    const [],
                    choice.side,
                    levelId: choice.levelId,
                    instructor: true,
                  ),
                );
              }),
            );
          },
          key: const ValueKey('menu-coach'),
        ),
        if (tournaments != null)
          _tile(
            Icons.emoji_events_outlined,
            l10n.gameMenuTournamentsTitle,
            l10n.gameMenuTournamentsSubtitle,
            () => Navigator.pop(
              context,
              _SheetRun((context) async {
                final page = await tournaments();
                if (!context.mounted) return;
                await Navigator.of(context)
                    .push<void>(MaterialPageRoute(builder: (_) => page));
              }),
            ),
            key: const ValueKey('menu-tournaments'),
          ),
      ],
      const SizedBox(height: 8),
      ExpansionTile(
        key: const ValueKey('menu-more'),
        tilePadding: EdgeInsets.zero,
        title: Text(l10n.gameMenuMoreModes),
        children: [
          if (engine)
            _tile(
              Icons.tune,
              l10n.gameMenuCustomTitle,
              l10n.gameMenuCustomSubtitle,
              () => setState(() => _view = _SheetView.custom),
              key: const ValueKey('menu-custom'),
            ),
          _tile(
            Icons.phone_android_outlined,
            l10n.gameMenuTwoTitle,
            l10n.gameMenuTwoSubtitle,
            () => setState(() {
              _setup = _setup.copyWith(opponent: Opponent.human);
              _view = _SheetView.custom;
            }),
            key: const ValueKey('menu-two'),
          ),
          if (physical != null)
            _tile(
              Icons.timer_outlined,
              l10n.gameMenuPhysicalTitle,
              l10n.gameMenuPhysicalSubtitle,
              () => Navigator.pop(
                context,
                _SheetRun(
                  (context) => Navigator.of(
                    context,
                  ).push<void>(MaterialPageRoute(builder: (_) => physical())),
                ),
              ),
              key: const ValueKey('menu-physical'),
            ),
        ],
      ),
    ];
  }

  List<Widget> _friendChildren(BuildContext context) => [
    _header(context, _l10n(context).gameMenuFriendTitle, back: _SheetView.menu),
    _tile(
      Icons.phone_android_outlined,
      _l10n(context).gameFriendSameTitle,
      _l10n(context).gameFriendSameSubtitle,
      () => setState(() {
        _setup = _setup.copyWith(opponent: Opponent.human);
        _view = _SheetView.custom;
      }),
      key: const ValueKey('friend-same'),
    ),
    _tile(
      Icons.smartphone_outlined,
      _l10n(context).gameFriendApartTitle,
      _l10n(context).gameFriendApartSubtitle,
      () => setState(() => _view = _SheetView.friendApart),
      key: const ValueKey('friend-apart'),
    ),
  ];

  List<Widget> _friendApartChildren(BuildContext context) => [
    _header(
      context,
      _l10n(context).gameFriendApartTitle,
      back: _SheetView.friend,
    ),
    const SizedBox(height: 16),
    FriendGamePanel(
      inCard: false,
      clockBuilder: _friendClock,
      onActivity: widget.onActivity,
      // La partita a due telefoni prende il posto del foglio.
      onGameClosed: () {
        if (ModalRoute.of(context)?.isCurrent ?? false) Navigator.pop(context);
      },
    ),
  ];

  /// Cadenza della partita con un amico in presenza: si sceglie qui e la
  /// partita parte dai comandi, non toccando una cadenza.
  Widget _friendClock(
    BuildContext context, {
    required bool enabled,
    required TimeControl? control,
    required ValueChanged<TimeControl?> onChanged,
  }) {
    final theme = Theme.of(context);
    Widget chip(String label, TimeControl? value) => ChoiceChip(
      label: Text(label),
      selected: control == value,
      onSelected: enabled ? (_) => onChanged(value) : null,
    );
    final groups = TimeControl.presetsByCategory;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _l10n(context).gameTimeControlTitle,
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 4),
        chip(_l10n(context).gameNoClock, null),
        for (final entry in groups.entries) ...[
          const SizedBox(height: 12),
          Text(
            timeCategoryName(_l10n(context), entry.key),
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final t in entry.value) chip(t.label, t)],
          ),
        ],
      ],
    );
  }

  /// Scelta dell'handicap (RF-27): pezzo in meno e tempo di chi concede.
  List<Widget> _handicapSection(BuildContext context) {
    final theme = Theme.of(context);
    final l = _l10n(context);
    final human = _setup.opponent == Opponent.human;
    final standard = _variant == Variant.standard;
    final pieces = {
      HandicapPiece.fPawn: l.handicapPieceFPawn,
      HandicapPiece.knight: l.handicapPieceKnight,
      HandicapPiece.rook: l.handicapPieceRook,
      HandicapPiece.queen: l.handicapPieceQueen,
    };
    final summary = _handicap == null
        ? null
        : [
            if (_handicapPiece != null) pieces[_handicapPiece]!,
            if (_handicapMinutes != null)
              l.handicapTimeMinutes(_handicapMinutes!),
          ].join(' · ');
    final children = [
      Text(l.handicapHint, style: theme.textTheme.bodySmall),
      const SizedBox(height: 8),
      Text(l.handicapPieceTitle, style: theme.textTheme.labelLarge),
      const SizedBox(height: 4),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ChoiceChip(
            key: const ValueKey('handicap-piece-none'),
            label: Text(l.handicapNone),
            selected: _handicapPiece == null,
            onSelected: (_) => setState(() => _handicapPiece = null),
          ),
          for (final MapEntry(:key, :value) in pieces.entries)
            ChoiceChip(
              key: ValueKey('handicap-piece-${key.name}'),
              label: Text(value),
              selected: _handicapPiece == key,
              onSelected: standard
                  ? (_) => setState(() => _handicapPiece = key)
                  : null,
            ),
        ],
      ),
      const SizedBox(height: 8),
      Text(l.handicapTimeTitle, style: theme.textTheme.labelLarge),
      const SizedBox(height: 4),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ChoiceChip(
            key: const ValueKey('handicap-time-none'),
            label: Text(l.handicapTimeEqual),
            selected: _handicapMinutes == null,
            onSelected: (_) => setState(() => _handicapMinutes = null),
          ),
          for (final m in Handicap.timeOptions)
            ChoiceChip(
              key: ValueKey('handicap-time-$m'),
              label: Text(l.handicapTimeMinutes(m)),
              selected: _handicapMinutes == m,
              onSelected: (_) => setState(() => _handicapMinutes = m),
            ),
        ],
      ),
      Text(l.handicapTimeHint, style: theme.textTheme.bodySmall),
      if (_handicap != null) ...[
        const SizedBox(height: 8),
        Text(l.handicapGiverTitle, style: theme.textTheme.labelLarge),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final g in HandicapGiver.values)
              ChoiceChip(
                key: ValueKey('handicap-giver-${g.name}'),
                label: Text(switch ((g, human)) {
                  (HandicapGiver.player, true) => l.handicapGiverWhite,
                  (HandicapGiver.opponent, true) => l.handicapGiverBlack,
                  (HandicapGiver.player, false) => l.handicapGiverYou,
                  (HandicapGiver.opponent, false) => l.handicapGiverOpponent,
                }),
                selected: _handicapGiver == g,
                onSelected: (_) => setState(() => _handicapGiver = g),
              ),
          ],
        ),
      ],
    ];
    // Chiuso per default: la scelta più comune resta una nuova partita normale.
    return [
      const SizedBox(height: 8),
      ExpansionTile(
        key: const ValueKey('handicap-section'),
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 8),
        shape: const Border(),
        collapsedShape: const Border(),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        title: Text(l.handicapTitle, style: theme.textTheme.titleSmall),
        subtitle: summary == null ? null : Text(summary),
        children: children,
      ),
    ];
  }
}

class _ConfirmBar extends StatelessWidget {
  const _ConfirmBar({required this.onConfirm, required this.onDiscard});

  final VoidCallback onConfirm;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _statusHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onDiscard,
                icon: const Icon(Icons.close),
                label: Text(_l10n(context).gameDiscard),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: onConfirm,
                icon: const Icon(Icons.check),
                label: Text(_l10n(context).gameConfirm),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ViewBar extends StatelessWidget {
  const _ViewBar({
    required this.text,
    required this.onPrevious,
    required this.onNext,
    required this.onBack,
  });

  final String text;
  final VoidCallback? onPrevious;
  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _statusHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            IconButton(
              tooltip: _l10n(context).gameViewPrevious,
              onPressed: onPrevious,
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Text(
                text,
                style: Theme.of(context).textTheme.titleSmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              tooltip: _l10n(context).gameViewNext,
              onPressed: onNext,
              icon: const Icon(Icons.chevron_right),
            ),
            TextButton(
              onPressed: onBack,
              child: Text(_l10n(context).gameViewBack),
            ),
          ],
        ),
      ),
    );
  }
}

/// Porta il figlio nella parte visibile della lista che lo contiene.
class _KeepVisible extends StatefulWidget {
  const _KeepVisible({required this.child});

  final Widget child;

  @override
  State<_KeepVisible> createState() => _KeepVisibleState();
}

class _KeepVisibleState extends State<_KeepVisible> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Scrollable.ensureVisible(
          context,
          alignment: 0.5,
          duration: const Duration(milliseconds: 150),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _MoveInputDialog extends StatefulWidget {
  const _MoveInputDialog({required this.position});

  final Position position;

  @override
  State<_MoveInputDialog> createState() => _MoveInputDialogState();
}

class _MoveInputDialogState extends State<_MoveInputDialog> {
  final _text = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _submit() {
    switch (parseMoveInput(widget.position, _text.text)) {
      case MoveInputOk(:final move):
        Navigator.of(context).pop(move);
      case MoveInputAmbiguous():
        setState(() => _error = _l10n(context).gameMoveInputAmbiguous);
      case MoveInputInvalid():
        setState(() => _error = _l10n(context).gameMoveInputInvalid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = _l10n(context);
    return AlertDialog(
      title: Text(l10n.gameKeyboardAction),
      content: TextField(
        controller: _text,
        autofocus: true,
        autocorrect: false,
        enableSuggestions: false,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(
          labelText: l10n.gameMoveInputLabel,
          hintText: l10n.gameMoveInputHint,
          errorText: _error,
        ),
        onChanged: (_) {
          if (_error != null) setState(() => _error = null);
        },
        // Mantiene la tastiera aperta dopo una mossa non valida.
        onEditingComplete: _submit,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.gameCancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.gamePlay)),
      ],
    );
  }
}

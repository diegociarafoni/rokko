import 'dart:async';

import 'package:dartchess/dartchess.dart' show Side;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../analysis/analysis_page.dart';
import '../archive/archive_page.dart';
import '../archive/game_archive.dart';
import '../archive/pgn.dart';
import '../archive/saved_game.dart';
import '../badges/badge_def.dart';
import '../badges/badge_sources.dart';
import '../badges/badges_l10n.dart';
import '../badges/badges_page.dart';
import '../endgames/endgame_controller.dart';
import '../endgames/endgames_page.dart';
import '../engine/bots.dart';
import '../engine/computer_player.dart';
import '../engine/levels.dart';
import '../engine/uci_transport.dart';
import '../game/challenge.dart';
import '../game/clock.dart';
import '../game/game_page.dart';
import '../game/handicap.dart';
import '../game/opponent_picker.dart';
import '../game/variant.dart';
import '../guide/guide_host.dart';
import '../guide/guide_steps.dart';
import '../l10n/app_localizations.dart';
import '../masters/masters_controller.dart';
import '../masters/masters_page.dart';
import '../minigames/minigames_page.dart';
import '../multiplayer/multiplayer_page.dart';
import '../openings/opening_assets.dart';
import '../openings/opening_game.dart';
import '../openings/openings_hub_page.dart';
import '../openings/repertoire.dart';
import '../path/curriculum.dart';
import '../path/path_controller.dart';
import '../path/stage_page.dart';
import '../physical/physical_game_page.dart';
import '../progress/activity.dart';
import '../progress/avatar.dart';
import '../progress/profile_page.dart';
import '../progress/progress_controller.dart';
import '../progress/progress_tracker.dart';
import '../puzzles/mode_guide.dart';
import '../puzzles/puzzle_assets.dart';
import '../puzzles/puzzle_hub_page.dart';
import '../puzzles/puzzle_page.dart';
import '../puzzles/puzzle_trainer.dart';
import '../reminders/local_notification_scheduler.dart';
import '../reminders/reminder.dart';
import '../reminders/reminder_controller.dart';
import '../review/engine_evaluator.dart';
import '../review/personal_puzzles.dart';
import '../review/review_activity.dart';
import '../review/review_page.dart';
import '../review/review_store.dart';
import '../settings/settings.dart';
import '../settings/settings_page.dart';
import '../stats/local_rating.dart';
import '../stats/stats_page.dart';
import '../storage/key_value_store.dart';
import '../story/guardian_says.dart';
import '../story/story.dart';
import '../story/story_controller.dart';
import '../story/story_feed.dart';
import '../story/story_l10n.dart';
import '../story/story_page.dart';
import '../summary/weekly_summary_page.dart';
import '../tablebase/shared_tablebase.dart';
import '../theme/adaptive.dart';
import '../theme/motion.dart';
import '../tournament/bot_game.dart';
import '../tournament/tournament.dart';
import '../tournament/tournament_controller.dart';
import '../tournament/tournament_page.dart';
import 'home_page.dart';
import 'learn_page.dart';
import 'you_page.dart';

/// Navigazione principale con la barra in basso, nella zona del pollice.
class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.settings,
    this.puzzleTrainer,
    this.progress,
    this.repertoire,
    this.archive,
    this.reminderScheduler,
    this.path,
    this.computerAvailable,
    this.createComputer,
    this.tournaments,
    this.endgames,
    this.masters,
    this.story,
  });

  final SettingsController settings;

  /// Sostituibile nei test; di default carica i puzzle inclusi nell'app.
  final Future<PuzzleTrainer> Function()? puzzleTrainer;

  /// Sostituibile nei test; di default apre i progressi salvati.
  final Future<ProgressController> Function()? progress;

  /// Sostituibile nei test; di default il repertorio salvato.
  final Future<RepertoireTrainer> Function()? repertoire;

  /// Sostituibile nei test; di default l'archivio delle partite salvato.
  final Future<GameArchive> Function()? archive;

  /// Sostituibile nei test; di default le notifiche locali dove esistono
  /// (Android e iOS), altrimenti nessun promemoria.
  final ReminderScheduler? Function()? reminderScheduler;

  /// Sostituibile nei test; di default il percorso salvato.
  final Future<PathController> Function()? path;

  /// Sostituibili nei test; di default il motore c'è dove Stockfish è
  /// supportato (Android e iOS).
  final bool? computerAvailable;
  final ComputerPlayer Function()? createComputer;

  /// Sostituibile nei test; di default i tornei salvati.
  final Future<TournamentController> Function()? tournaments;

  /// Sostituibile nei test; di default i progressi salvati dei finali.
  final Future<EndgameController> Function()? endgames;

  /// Sostituibile nei test; di default i risultati salvati di «Indovina la
  /// mossa».
  final Future<MastersController> Function()? masters;

  /// Sostituibile nei test; di default i progressi salvati della storia.
  final Future<StoryController> Function()? story;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;
  Future<PuzzleTrainer>? _trainer;
  Future<ProgressController>? _progress;
  Future<RepertoireTrainer>? _repertoire;
  ReminderController? _reminders;
  ReminderScheduler? _scheduler;
  Future<PathController>? _path;
  Future<TournamentController>? _tournaments;
  Future<EndgameController>? _endgames;
  Future<MastersController>? _masters;
  Future<StoryController>? _story;
  StreamSubscription<List<BadgeDef>>? _badgeSub;
  final _badgeSources = <Listenable, VoidCallback>{};

  /// Le schede Impara e Tu si costruiscono alla prima apertura, poi restano
  /// in memoria.
  var _learnVisited = false;

  /// Avvisa la Home quando torna in vista, per rileggere partite e progressi.
  final _homeRefresh = ValueNotifier<int>(0);
  // Conserva lo stato delle schede quando la barra diventa colonna e viceversa.
  final _stackKey = GlobalKey();
  var _youVisited = false;

  late bool _kidMode = widget.settings.value.kidMode;
  String? _localeName;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Cambiata la lingua (dalle Impostazioni o dal telefono), il promemoria
    // si riscrive nella nuova.
    final name = AppLocalizations.of(context).localeName;
    if (_localeName != null && name != _localeName) _reminders?.sync().ignore();
    _localeName = name;
  }

  Future<RepertoireTrainer> _loadRepertoire() =>
      (widget.repertoire ??
              () async => RepertoireTrainer.load(await JsonFileStore.open()))()
          .catchError((Object e, StackTrace st) {
            _repertoire = null;
            Error.throwWithStackTrace(e, st);
          });

  @override
  void initState() {
    super.initState();
    widget.settings.addListener(_onSettings);
    // Caricamento anticipato in background, per il nome dell'apertura in partita.
    openingBook().ignore();
    // Revisioni su disco (RF-66); se la cartella dati non c'è, solo memoria.
    ReviewStore.openDefault()
        .then((store) => ReviewCache.store ??= store)
        .ignore();
    _scheduler =
        (widget.reminderScheduler ??
        () => LocalNotificationScheduler.supported
            ? LocalNotificationScheduler()
            : null)();
    if (_scheduler != null) {
      // Il promemoria si allinea ai progressi fin dall'avvio.
      _progressController().ignore();
    }
  }

  @override
  void dispose() {
    widget.settings.removeListener(_onSettings);
    unawaited(_badgeSub?.cancel());
    _badgeSources.forEach(
      (source, listener) => source.removeListener(listener),
    );
    _reminders?.dispose();
    _homeRefresh.dispose();
    _botEngineIdle?.cancel();
    _closeBotEngine();
    super.dispose();
  }

  Future<ProgressController> _progressController() =>
      _progress ??= (widget.progress ?? ProgressController.open)().then(
        (p) {
          final scheduler = _scheduler;
          if (scheduler != null && _reminders == null && mounted) {
            setState(
              () => _reminders = ReminderController(
                p,
                scheduler,
                () => AppLocalizations.of(context),
              ),
            );
          }
          _watchBadges(p);
          return p;
        },
        onError: (Object e, StackTrace st) {
          // Si riprova alla prossima richiesta invece di restare bloccati.
          _progress = null;
          debugPrint('Progressi non disponibili: $e'); // l10n-ok
          Error.throwWithStackTrace(e, st);
        },
      );

  /// Avvisa dei nuovi badge e li allinea ai salvataggi di Percorso, finali,
  /// maestri e Storia, che ne conservano l'avanzamento.
  void _watchBadges(ProgressController p) {
    if (_badgeSub != null || !mounted) return;
    _badgeSub = p.badgeUnlocks.listen(_announceBadges);
    unawaited(_syncBadgeSources(p));
  }

  Future<void> _syncBadgeSources(ProgressController p) async {
    Future<T?> quiet<T>(Future<T> source) => source.then<T?>(
      (v) => v,
      onError: (Object e) {
        if (kDebugMode) {
          debugPrint('Avanzamento dei badge non disponibile: $e'); // l10n-ok
        }
        return null;
      },
    );
    final (path, endgames, masters, story) = await (
      quiet(_pathController()),
      quiet(_endgameController()),
      quiet(_mastersController()),
      quiet(_storyController()),
    ).wait;
    if (!mounted) return;
    void push() => unawaited(
      p
          .updateBadgeSources(
            BadgeSources.fromStores(
              path: path?.progress,
              endgames: endgames?.progress,
              masters: masters?.progress,
              story: story?.state,
            ),
          )
          .onError((Object e, _) {
            if (kDebugMode) debugPrint('Badge non aggiornati: $e'); // l10n-ok
          }),
    );
    for (final source in <ChangeNotifier?>[path, endgames, masters, story]) {
      if (source == null) continue;
      _badgeSources[source] = push;
      source.addListener(push);
    }
    push();
  }

  /// Nel profilo bambino i badge non compaiono, quindi nemmeno l'avviso.
  void _announceBadges(List<BadgeDef> fresh) {
    if (_kidMode || !mounted || fresh.isEmpty) return;
    final l = badgesL10n(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          fresh.length > 3
              ? l.badgesUnlockedMany(fresh.length)
              : l.badgesUnlocked(
                  [for (final b in fresh) badgeName(l, b)].join(', '),
                ),
        ),
        action: SnackBarAction(
          label: l.badgesSeeAction,
          onPressed: _openBadges,
        ),
      ),
    );
  }

  Future<void> _openBadges() async {
    final p = await _progressController();
    if (!mounted) return;
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => BadgesPage(controller: p)));
  }

  /// Un solo percorso in memoria, per non sovrascrivere le stelle tra due
  /// schermate aperte insieme.
  Future<PathController> _pathController() => _path ??=
      (widget.path ?? () => PathController.open(recordActivity: _record))()
          .catchError((Object e, StackTrace st) {
            _path = null;
            Error.throwWithStackTrace(e, st);
          });

  /// Un solo torneo in memoria, salvato a ogni partita.
  Future<TournamentController> _tournamentController() => _tournaments ??=
      (widget.tournaments ??
              () => TournamentController.open(
                recordActivity: _record,
                playBotGame: _playBotGame,
              ))()
          .catchError((Object e, StackTrace st) {
            _tournaments = null;
            Error.throwWithStackTrace(e, st);
          });

  /// Un solo allenatore dei finali in memoria, salvato a ogni prova.
  Future<EndgameController> _endgameController() => _endgames ??=
      (widget.endgames ??
              () => EndgameController.open(recordActivity: _record))()
          .catchError((Object e, StackTrace st) {
            _endgames = null;
            Error.throwWithStackTrace(e, st);
          });

  /// Un solo controller delle partite dei maestri in memoria.
  Future<MastersController> _mastersController() => _masters ??=
      (widget.masters ??
              () => MastersController.open(recordActivity: _record))()
          .catchError((Object e, StackTrace st) {
            _masters = null;
            Error.throwWithStackTrace(e, st);
          });

  Future<Widget> _mastersPage() async =>
      MastersPage(controller: await _mastersController(), simple: _kidMode);

  Future<Widget> _endgamesPage() async => EndgamesPage(
    controller: await _endgameController(),
    createComputer: widget.createComputer ?? ComputerPlayer.new,
    simple: _kidMode,
    tablebase: sharedTablebase(),
  );

  /// Una sola storia in memoria, salvata a ogni passo.
  Future<StoryController> _storyController() =>
      _story ??= (widget.story ?? StoryController.open)().catchError((
        Object e,
        StackTrace st,
      ) {
        _story = null;
        Error.throwWithStackTrace(e, st);
      });

  Future<Widget> _storyPage() async => StoryPage(
    path: await _pathController(),
    story: await _storyController(),
    playGuardian: _computerAvailable ? _playGuardian : null,
    playBoss: _computerAvailable ? _playStoryBoss : null,
    playPuzzles: _playStoryPuzzles,
    onChaptersDone: (n) async {
      final progress = await _progressController();
      if (n > (progress.state.tally['story'] ?? 0)) {
        await _record(StoryChapterDone(chapters: n));
      }
    },
  );

  /// Sfida del capitolo contro [bot]: vale come allenamento, con Annulla.
  /// Uscire a partita in corso vale una sconfitta.
  Future<bool> _playStoryBoss(BuildContext context, Bot bot) async {
    GameResult? result;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GamePage(
          settings: widget.settings,
          computerAvailable: true,
          createComputer: widget.createComputer,
          challenge: GameChallenge(
            title: '${bot.avatar} ${bot.name}',
            levelId: bot.levelId,
            side: Side.white,
            allowHints: true,
          ),
          onFinished: (r, _) => result = r,
          onActivity: _record,
          onSave: _saveGame,
          progress: _progressController,
        ),
      ),
    );
    return result == GameResult.win;
  }

  /// Puzzle del tema del capitolo fino a [remaining] risolti al primo
  /// tentativo; `null` se la raccolta non si carica.
  Future<int?> _playStoryPuzzles(
    BuildContext context,
    StoryChapter chapter,
    int remaining,
  ) async {
    final PuzzleTrainer trainer;
    try {
      trainer = await (_trainer ??= _loadTrainer());
    } on Object catch (e) {
      if (kDebugMode) debugPrint('Puzzle non disponibili: $e'); // l10n-ok
      return null;
    }
    if (!context.mounted) return 0;
    final theme = (await _storyController()).state.themeFor(chapter);
    if (!context.mounted) return 0;
    final feed = StoryPuzzleFeed(
      trainer,
      theme: theme,
      goal: remaining,
      maxRating: chapter.puzzleRating,
      onHelp: () => _helpSnack(context),
    );
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PuzzlePage(
          trainer: trainer,
          theme: theme,
          feed: feed,
          title: storyL10n(context).chapterTitle(chapter),
          onActivity: _record,
          companionBuilder: (_, {required solved}) =>
              _guardianLine(chapter, solved),
          continueWhenFinished: true,
        ),
      ),
    );
    // L'avviso dell'ultimo puzzle non resta sopra la Storia.
    if (context.mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();
    return feed.solved;
  }

  /// Dopo due errori di fila: si passa a puzzle più facili (S6).
  void _helpSnack(BuildContext context) {
    if (!context.mounted) return;
    // Dopo l'avviso del custode, che parte nello stesso istante.
    Future<void>.delayed(const Duration(milliseconds: 200), () {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(AppLocalizations.of(context).storyHelpEasier),
          ),
        );
    });
  }

  /// Il custode commenta il puzzle appena concluso, dentro la scheda
  /// dell'esito: un fumetto a parte coprirebbe i pulsanti.
  Widget _guardianLine(StoryChapter chapter, bool solved) => GuardianSays(
    chapter: chapter,
    moment: solved ? GuardianMoment.puzzleOk : GuardianMoment.puzzleRetry,
    expression: solved ? AvatarExpression.happy : AvatarExpression.encouraging,
    size: 36,
    style: const TextStyle(fontStyle: FontStyle.italic),
  );

  /// Bot del torneo: un avversario per ogni livello del motore.
  static final _bots = [
    for (final l in engineLevels)
      Player(name: l.name, elo: l.approxElo, levelId: l.id),
  ];

  Future<Widget> _tournamentPage() async {
    final controller = await _tournamentController();
    // Riprende le partite tra bot rimaste a metà alla chiusura dell'app.
    unawaited(
      controller.resumeBots().catchError((Object e) {
        if (kDebugMode) {
          debugPrint(
            'Ripresa delle partite tra bot non riuscita: $e', // l10n-ok
          );
        }
      }),
    );
    final games = await (await _archive()).list();
    return TournamentPage(
      controller: controller,
      bots: _bots,
      userElo: LocalRating.from(games).rating,
      play: _playTournamentGame,
    );
  }

  ComputerPlayer? _botGamePlayer;
  Timer? _botEngineIdle;

  /// Fa giocare al motore una partita tra due bot del torneo; `null` dove il
  /// motore non c'è o non risponde: la partita si simula. Il motore si chiude
  /// dopo qualche secondo senza partite, per non restare in memoria.
  Future<double?> _playBotGame(Player white, Player black, int seed) async {
    if (!_computerAvailable) return null;
    _botEngineIdle?.cancel();
    try {
      final engine = _botGamePlayer ??=
          widget.createComputer?.call() ?? ComputerPlayer();
      await engine.newGame();
      return await playBotGame(
        white: _botLevel(white),
        black: _botLevel(black),
        move: (fen, moves, level) async =>
            (await engine.bestMove(fen, moves, level))?.move,
      );
    } on Object catch (e) {
      if (kDebugMode) {
        debugPrint('Partita tra bot non riuscita: $e'); // l10n-ok
      }
      return null;
    } finally {
      _botEngineIdle = Timer(const Duration(seconds: 20), _closeBotEngine);
    }
  }

  void _closeBotEngine() {
    _botGamePlayer?.dispose().ignore();
    _botGamePlayer = null;
  }

  EngineLevel _botLevel(Player bot) => bot.levelId != null
      ? engineLevel(bot.levelId!)
      : engineLevelForElo(bot.elo);

  /// Gioca la partita del torneo e restituisce i punti, o `null` se non si è
  /// conclusa. L'uscita dalla partita vale una sconfitta.
  Future<double?> _playTournamentGame(
    BuildContext context,
    UserGame game,
  ) async {
    GameResult? result;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GamePage(
          settings: widget.settings,
          computerAvailable: true,
          createComputer: widget.createComputer,
          challenge: GameChallenge(
            title: AppLocalizations.of(context)
                .homeTournamentGameTitle(game.opponent.name),
            levelId:
                game.opponent.levelId ??
                engineLevelForElo(game.opponent.elo).id,
            side: game.color,
          ),
          onFinished: (r, _) => result = r,
          onActivity: _record,
          onSave: _saveGame,
          progress: _progressController,
        ),
      ),
    );
    // Uscire prima di muovere vale una sconfitta: non si rilancia la partita.
    return tournamentPoints(result ?? GameResult.loss, game);
  }

  bool get _computerAvailable =>
      widget.computerAvailable ?? StockfishTransport.isSupported;

  /// Gioca il guardiano di [stage] e restituisce le stelle, o `null` se non si
  /// è vinto.
  Future<int?> _playGuardian(BuildContext context, Stage stage) async {
    GameResult? result;
    var moves = 0;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GamePage(
          settings: widget.settings,
          computerAvailable: true,
          createComputer: widget.createComputer,
          challenge: GameChallenge(
            title: AppLocalizations.of(context).homeGuardianTitle,
            levelId: engineLevelForElo(stage.guardianElo!).id,
            side: Side.white,
            allowHints: true,
          ),
          onFinished: (r, m) {
            result = r;
            moves = m;
          },
          onActivity: _record,
          onSave: _saveGame,
          progress: _progressController,
        ),
      ),
    );
    final r = result;
    return r == null ? null : challengeStars(r, moves: moves);
  }

  /// Gioca contro il computer a partire da un'apertura (RF-94).
  Future<void> _playOpening(BuildContext context, OpeningGameRequest request) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => GamePage(
            settings: widget.settings,
            computerAvailable: true,
            createComputer: widget.createComputer,
            challenge: GameChallenge(
              title: request.title,
              levelId: request.levelId,
              side: request.side,
              startMoves: request.startMoves,
              line: request.line,
              instructor: request.instructor,
            ),
            onActivity: _record,
            onSave: _saveGame,
            progress: _progressController,
          ),
        ),
      );

  /// Apre nell'analisi una partita o un'analisi dell'archivio, con le sue
  /// varianti (RF-52). Salvando da una partita nasce una nuova analisi.
  Future<void> _openSavedAnalysis(BuildContext context, SavedGame saved) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final l10n = AppLocalizations.of(context);
    final tree = saved.toTree();
    if (tree == null) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.homeGameCannotOpen)));
      return;
    }
    // Il motore conosce solo le regole classiche.
    final variant = importPgn(saved.pgn).games.firstOrNull?.game.variant;
    if (!_computerAvailable ||
        (variant != null && variant != Variant.standard)) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.homeReviewNoEngine)));
      return;
    }
    final player = widget.createComputer?.call() ?? ComputerPlayer();
    try {
      await navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => AnalysisPage(
            initial: tree.root.position,
            tree: tree,
            saved: saved.mode == SavedGame.analysis ? saved : null,
            analyse: (fen, multiPv) =>
                player.analyseLive(fen, multiPv: multiPv),
            onSave: _saveGame,
            tablebase: sharedTablebase(),
          ),
        ),
      );
    } finally {
      player.dispose().ignore();
    }
  }

  /// Apre nella revisione una partita dell'archivio.
  Future<void> _openSavedGame(BuildContext context, SavedGame saved) async {
    if (saved.mode == SavedGame.analysis) {
      return _openSavedAnalysis(context, saved);
    }
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final l10n = AppLocalizations.of(context);
    final imported = importPgn(saved.pgn).games;
    if (imported.isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.homeGameCannotOpen)));
      return;
    }
    // Una partita sulla scacchiera fisica non si riprende sull'app.
    if (!saved.finished &&
        saved.mode != SavedGame.imported &&
        saved.mode != SavedGame.physical) {
      final choice = await showDialog<String>(
        context: context,
        animationStyle: motionStyle(context),
        builder: (context) => SimpleDialog(
          title: Text(l10n.homeGameInProgress),
          children: [
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'resume'),
              child: Text(l10n.homeGameResume),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'review'),
              child: Text(l10n.homeGameReview),
            ),
          ],
        ),
      );
      if (choice == null) return;
      if (choice == 'resume') {
        if (saved.mode == SavedGame.computer && !_computerAvailable) {
          messenger.showSnackBar(
            SnackBar(content: Text(l10n.homeResumeNoEngine)),
          );
          return;
        }
        await navigator.push(
          MaterialPageRoute<void>(
            builder: (_) => GamePage(
              settings: widget.settings,
              computerAvailable: _computerAvailable,
              createComputer: widget.createComputer,
              resume: saved,
              onActivity: _record,
              onSavePuzzles: _savePersonalPuzzles,
              onSave: _saveGame,
              progress: _progressController,
            ),
          ),
        );
        return;
      }
    }
    final game = imported.first.game;
    // Stockfish non conosce le varianti: niente revisione con regole classiche.
    if (!_computerAvailable || game.variant != Variant.standard) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.homeReviewNoEngine)));
      return;
    }
    final player = widget.createComputer?.call() ?? ComputerPlayer();
    final side = saved.playerSide;
    final players = side == null ? {Side.white, Side.black} : {side};
    // Le note e la precisione si salvano sulla voce più recente, non su quella
    // letta all'apertura.
    var current = saved;
    try {
      await navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => ReviewPage(
            initial: game.initial,
            moves: [for (final m in game.moves) m.move],
            onResult: (review) {
              if (side == null) return;
              final next = current.withReview(review);
              // Una revisione già salvata (cache) non riscrive l'archivio.
              if (next.accuracy == current.accuracy &&
                  mapEquals(next.phaseAccuracy, current.phaseAccuracy)) {
                return;
              }
              current = next;
              unawaited(_saveGame(current).catchError((Object _) {}));
            },
            evaluate: engineEvaluator(player),
            onCancel: player.stopAnalysis,
            analyseLive: (fen, multiPv) =>
                player.analyseLive(fen, multiPv: multiPv),
            onReviewed: (review) => _record(
              reviewActivity(
                review,
                players,
                initial: game.initial,
                moves: [for (final m in game.moves) m.move],
              ),
            ),
            onSavePuzzles: _savePersonalPuzzles,
            puzzlePlayers: players,
            clocks: [for (final m in game.moves) m.clock],
            notes: [for (final m in game.moves) m.note],
            onNoteChanged: (ply, note) {
              imported.first.annotate(ply, note);
              current = current.copyWith(pgn: imported.first.toPgn());
              return _saveGame(current);
            },
            timeControl: TimeControl.parse(saved.timeControl ?? ''),
            startTimes: Handicap.startTimesFromPgn(
              imported.first.headers['Handicap'],
              TimeControl.parse(saved.timeControl ?? ''),
            ),
          ),
        ),
      );
    } finally {
      player.dispose().ignore();
    }
  }

  Future<void> _saveGame(SavedGame game) async => (await _archive()).save(game);

  Future<GameArchive> _archive() => (widget.archive ?? GameArchive.open)();

  Future<ProgressUpdate?> _record(Activity activity) async {
    try {
      return await (await _progressController()).record(activity);
    } on Object catch (e) {
      debugPrint('Progressi non disponibili: $e'); // l10n-ok
      return null;
    }
  }

  /// Mette i puzzle dagli errori nel ripasso. Il caricamento dei puzzle è lo
  /// stesso della scheda Puzzle: un solo archivio in memoria.
  Future<int> _savePersonalPuzzles(List<MistakePuzzle> puzzles) async {
    final trainer = await (_trainer ??= _loadTrainer());
    return trainer.addPersonal([for (final p in puzzles) p.toPuzzle()]);
  }

  /// Puzzle di un tema, aperti dal consiglio del riepilogo settimanale.
  Future<Widget> _puzzlesPage(String theme, String title) async {
    final trainer = await (_trainer ??= _loadTrainer());
    return PuzzlePage(
      trainer: trainer,
      theme: theme,
      guide: PuzzleGuide.theme,
      title: title,
      onActivity: _record,
    );
  }

  Future<PuzzleTrainer>
  _loadTrainer() => (widget.puzzleTrainer ?? loadPuzzleTrainer)().catchError((
    Object e,
    StackTrace st,
  ) {
    // Un errore di caricamento si riprova alla prossima apertura della scheda.
    _trainer = null;
    Error.throwWithStackTrace(e, st);
  });

  /// Ricostruisce solo quando cambia il profilo bambino, non a ogni
  /// impostazione.
  void _onSettings() {
    final kidMode = widget.settings.value.kidMode;
    if (kidMode == _kidMode) return;
    setState(() => _kidMode = kidMode);
  }

  Future<void> _push(Widget page) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

  /// Apre [build] quando è pronta, con un messaggio se non si carica.
  Future<void> _openPage(Future<Widget> Function() build) async {
    try {
      final page = await build();
      if (mounted) await _push(page);
    } on Object catch (e) {
      if (kDebugMode) debugPrint('Sezione non disponibile: $e'); // l10n-ok
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).youLoadError)),
      );
    }
  }

  GamePage _gamePage({
    bool openSetup = false,
    GameSetup? initialSetup,
    SavedGame? resume,
  }) => GamePage(
    settings: widget.settings,
    openSetup: openSetup,
    initialSetup: initialSetup,
    resume: resume,
    onActivity: _record,
    onSavePuzzles: _savePersonalPuzzles,
    onSave: _saveGame,
    progress: _progressController,
    computerAvailable: widget.computerAvailable,
    createComputer: widget.createComputer,
    tournamentPage: _computerAvailable ? _tournamentPage : null,
    physicalPage: () => PhysicalGamePage(archive: _archive),
    openingGame: _computerAvailable ? _playOpening : null,
  );

  /// «Nuova partita»: la scacchiera con la scelta già aperta.
  Future<void> _newGame([GameSetup? setup]) =>
      _push(_gamePage(openSetup: true, initialSetup: setup));

  Future<void> _resumeGame(SavedGame saved) async {
    if (saved.mode == SavedGame.computer && !_computerAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).homeResumeNoEngine),
        ),
      );
      return;
    }
    await _push(_gamePage(resume: saved));
  }

  Future<void> _openOpenings() async {
    final repertoire = _repertoire ??= _loadRepertoire();
    await _push(
      OpeningsHubPage(
        repertoire: repertoire,
        onPlay: _computerAvailable ? _playOpening : null,
        archive: _archive,
        onActivity: _record,
      ),
    );
  }

  Future<void> _openDaily() async {
    try {
      final trainer = await (_trainer ??= _loadTrainer());
      if (!mounted) return;
      await _push(
        PuzzlePage(
          trainer: trainer,
          puzzle: trainer.library.daily(DateTime.now()),
          guide: PuzzleGuide.daily,
          title: AppLocalizations.of(context).puzzleDailyTitle,
          onActivity: _record,
        ),
      );
    } on Object catch (e) {
      if (kDebugMode) {
        debugPrint('Puzzle del giorno non disponibile: $e'); // l10n-ok
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).youLoadError)),
      );
    }
  }

  /// Svolge una lezione consigliata e ne salva le stelle come nel Percorso.
  void _playLesson(BuildContext context, Stage stage) {
    unawaited(() async {
      final controller = await _pathController();
      if (!context.mounted) return;
      final started = DateTime.now();
      final stars = await openStage(context, controller, stage);
      if (stars != null && stars > 0) {
        await controller.complete(
          stage,
          stars,
          DateTime.now().difference(started),
        );
      }
    }());
  }

  void _openThemePuzzles(BuildContext context, String theme, String title) {
    unawaited(_openPage(() => _puzzlesPage(theme, title)));
  }

  /// Le funzioni raggiungibili dalla Home e da Impara, per id. Quelle che
  /// non servono al profilo o non funzionano senza motore mancano.
  Map<String, HomeAction> _features() {
    final adult = !_kidMode;
    return {
      if (adult && _computerAvailable)
        'bots': () => _newGame(const GameSetup(opponent: Opponent.bot)),
      if (adult) 'friend': () => _push(MultiplayerPage(onActivity: _record)),
      if (adult && _computerAvailable)
        'tournaments': () => _openPage(_tournamentPage),
      if (adult) 'physical': () => _push(PhysicalGamePage(archive: _archive)),
      'story': () => _openPage(_storyPage),
      if (adult) 'openings': _openOpenings,
      if (_computerAvailable) 'endgames': () => _openPage(_endgamesPage),
      'masters': () => _openPage(_mastersPage),
      'daily': _openDaily,
      'puzzles': () async => setState(() => _tab = 1),
      'minigames': () => _openPage(
        () async => MinigamesPage(progress: await _progressController()),
      ),
      if (adult) ...{
        'stats': () =>
            _openPage(() async => StatsPage(archive: await _archive())),
        'badges': () => _openPage(
          () async => BadgesPage(controller: await _progressController()),
        ),
        'archive': () => _openPage(
          () async => ArchivePage(
            archive: await _archive(),
            onOpen: (g) => unawaited(_openSavedGame(context, g)),
            onAnalyse: _computerAvailable
                ? (g) => unawaited(_openSavedAnalysis(context, g))
                : null,
          ),
        ),
      },
      'week': () => _openPage(() async {
        final p = await _progressController();
        return WeeklySummaryPage(
          log: p.weekLog,
          openLesson: _playLesson,
          openPuzzles: _openThemePuzzles,
        );
      }),
      'profile': () => _openPage(
        () async => ProfilePage(
          controller: await _progressController(),
          reminders: _reminders,
        ),
      ),
    };
  }

  /// Riprende dalla Storia, che propone il passo giusto.
  Future<void> _continueStory(Stage stage) => _openPage(_storyPage);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (_tab == 1) _trainer ??= _loadTrainer();
    if (_tab == 2) _learnVisited = true;
    if (_tab == 3) _youVisited = true;
    final features = _features();
    final stack = KeyedSubtree(
      key: _stackKey,
      child: IndexedStack(
        index: _tab,
        children: [
          HomePage(
            progress: _progressController,
            path: _pathController,
            story: _storyController,
            games: () async => (await _archive()).list(),
            features: features,
            simple: _kidMode,
            refresh: _homeRefresh,
            onNewGame: _newGame,
            onSettings: _openSettings,
            onResume: _resumeGame,
            onOpenGame: (g) => _openSavedGame(context, g),
            onContinueStory: _continueStory,
            onPlayBot: _computerAvailable
                ? (bot) =>
                      _newGame(GameSetup(opponent: Opponent.bot, botId: bot.id))
                : null,
          ),
          if (_trainer != null)
            PuzzleHubPage(trainer: _trainer!, onActivity: _record)
          else
            const SizedBox.shrink(),
          if (_learnVisited)
            LearnPage(
              path: _pathController,
              story: _storyController,
              features: features,
              onContinueStory: _continueStory,
            )
          else
            const SizedBox.shrink(),
          if (_tab == 3 || _youVisited)
            YouPage(
              progress: _progressController,
              path: _pathController,
              archive: _archive,
              reminders: () => _reminders,
              simple: _kidMode,
              playGuardian: _computerAvailable ? _playGuardian : null,
              storyPage: _storyPage,
              openGame: _openSavedGame,
              openAnalysis: _computerAvailable ? _openSavedAnalysis : null,
              puzzlesPage: _puzzlesPage,
            )
          else
            const SizedBox.shrink(),
        ],
      ),
    );
    final destinations = [
      NavigationDestination(
        icon: const Icon(Icons.home_outlined),
        selectedIcon: const Icon(Icons.home),
        label: l.homeNavHome,
      ),
      NavigationDestination(
        icon: const Icon(Icons.extension_outlined),
        selectedIcon: const Icon(Icons.extension),
        label: l.homeNavPuzzles,
      ),
      NavigationDestination(
        icon: const Icon(Icons.school_outlined),
        selectedIcon: const Icon(Icons.school),
        label: l.homeNavLearn,
      ),
      NavigationDestination(
        icon: const Icon(Icons.person_outline),
        selectedIcon: const Icon(Icons.person),
        label: l.youTitle,
      ),
    ];
    void select(int i) {
      setState(() => _tab = i);
      if (i == 0) _homeRefresh.value++;
    }

    return GuideHost(
      screen: 'home',
      steps: homeGuide,
      // Le altre schede hanno la loro guida.
      enabled: _tab == 0,
      child: _scaffold(context, stack, destinations, select),
    );
  }

  Widget _scaffold(
    BuildContext context,
    Widget stack,
    List<NavigationDestination> destinations,
    ValueChanged<int> select,
  ) {
    // Su schermi larghi la barra passa a lato e il contenuto resta stretto.
    if (WindowSize.of(context) == WindowSize.expanded &&
        MediaQuery.sizeOf(context).height >= 480) {
      return Scaffold(
        body: Row(
          children: [
            SafeArea(
              right: false,
              child: GuideAnchor(
                id: 'home.nav',
                child: NavigationRail(
                  selectedIndex: _tab,
                  onDestinationSelected: select,
                  labelType: NavigationRailLabelType.all,
                  destinations: [
                    for (final d in destinations)
                      NavigationRailDestination(
                        icon: d.icon,
                        selectedIcon: d.selectedIcon,
                        label: Text(d.label),
                      ),
                  ],
                ),
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: contentMaxWidth),
                  child: stack,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Scaffold(
      body: stack,
      bottomNavigationBar: GuideAnchor(
        id: 'home.nav',
        child: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: select,
          destinations: destinations,
        ),
      ),
    );
  }

  Future<void> _openSettings() async {
    ProgressController? progress;
    try {
      progress = await _progressController();
    } on Object catch (e) {
      // Senza progressi le impostazioni restano utilizzabili, senza i blocchi.
      if (kDebugMode) debugPrint('Progressi non disponibili: $e'); // l10n-ok
    }
    if (!mounted) return;
    await _push(SettingsPage(controller: widget.settings, progress: progress));
  }
}

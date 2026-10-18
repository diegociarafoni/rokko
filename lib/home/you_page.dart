import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;

import '../archive/archive_page.dart';
import '../archive/game_archive.dart';
import '../archive/saved_game.dart';
import '../badges/badges_l10n.dart';
import '../badges/badges_page.dart';
import '../guide/guide_host.dart';
import '../guide/guide_steps.dart';
import '../kids/kid_display.dart';
import '../l10n/app_localizations.dart';
import '../path/curriculum.dart';
import '../path/path_controller.dart';
import '../path/path_page.dart' show PlayGuardian;
import '../path/stage_page.dart';
import '../progress/profile_page.dart';
import '../progress/progress_controller.dart';
import '../progress/xp.dart';
import '../reminders/reminder_controller.dart';
import '../stats/portrait_page.dart';
import '../stats/stats_page.dart';
import '../story/story.dart';
import '../summary/weekly_summary_page.dart';
import '../theme/rokko_theme.dart';
import '../theme/sheets.dart';
import 'review_invite.dart';

/// Scheda "Tu": solo i dati del giocatore; le funzioni stanno nella Home.
class YouPage extends StatefulWidget {
  const YouPage({
    super.key,
    required this.progress,
    required this.path,
    required this.archive,
    this.reminders,
    this.simple = false,
    this.playGuardian,
    this.storyPage,
    this.puzzlesPage,
    this.openGame,
    this.openAnalysis,
  });

  /// Fonti dei dati: chiamate a ogni apertura, così un errore si riprova.
  final Future<ProgressController> Function() progress;
  final Future<PathController> Function() path;
  final Future<GameArchive> Function() archive;

  /// Promemoria giornaliero, se il dispositivo ha le notifiche programmate;
  /// letto all'apertura del Profilo perché nasce dopo i progressi.
  final ReminderController? Function()? reminders;

  /// Profilo bambino (RP-06): niente statistiche, badge e archivio, solo
  /// profilo e settimana.
  final bool simple;

  /// Partita contro il guardiano; la Storia la riceve da HomeShell.
  final PlayGuardian? playGuardian;

  /// Percorso a storia (RG-13), per «Continua da dove eri».
  final Future<Widget> Function()? storyPage;

  /// Puzzle di un tema, per il consiglio del riepilogo settimanale; senza, il
  /// pulsante dei puzzle non compare.
  final Future<Widget> Function(String theme, String title)? puzzlesPage;

  /// Apre una partita dell'archivio; senza, le righe non sono toccabili.
  final void Function(BuildContext context, SavedGame game)? openGame;

  /// Apre una partita o un'analisi dell'archivio nell'analisi (RF-52).
  final void Function(BuildContext context, SavedGame game)? openAnalysis;

  @override
  State<YouPage> createState() => _YouPageState();
}

class _YouPageState extends State<YouPage> {
  // Un'unica lettura per apertura della scheda: la voce «Continua» non
  // ricarica il percorso a ogni ricostruzione.
  late final Future<PathController> _pathFuture = widget.path();

  // Invito a rivedere la prima partita (U10): solo se si può aprire una
  // partita e fuori dal profilo bambino.
  late Future<SavedGame?> _invite = _loadInvite();

  @override
  void didUpdateWidget(YouPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // La scheda resta viva tra un cambio di scheda e l'altro: l'invito si
    // rilegge ogni volta che la Home si ricostruisce.
    _invite = _loadInvite();
  }

  Future<SavedGame?> _loadInvite() async {
    if (widget.simple || widget.openGame == null) return null;
    try {
      return await reviewInviteGame(await widget.archive());
    } on Object {
      return null;
    }
  }

  YouPage get _w => widget;

  void _push(BuildContext context, Widget page) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

  /// Apre [page] quando [source] è pronto, con un messaggio se non lo è.
  Future<void> _open<T>(
    BuildContext context,
    Future<T> source,
    Widget Function(T value) page,
  ) async {
    try {
      final value = await source;
      if (context.mounted) _push(context, page(value));
    } on Object catch (e) {
      debugPrint('Sezione non disponibile: $e'); // l10n-ok
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).youLoadError)),
      );
    }
  }

  /// Svolge una lezione consigliata e ne salva le stelle come nel Percorso.
  Future<void> _playLesson(BuildContext context, Stage stage) async {
    try {
      final controller = await _w.path();
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
    } on Object catch (e) {
      if (kDebugMode) debugPrint('Lezione non disponibile: $e'); // l10n-ok
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).youLoadError)),
      );
    }
  }

  Future<void> _openPuzzles(
    BuildContext context,
    String theme,
    String title,
  ) async {
    final source = _w.puzzlesPage?.call(theme, title);
    if (source != null) await _open(context, source, (w) => w);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final w = widget;
    return GuideHost(
      screen: 'you',
      steps: youGuide,
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.youTitle)),
        body: FutureBuilder(
          future: w.progress(),
          builder: (context, snapshot) {
            final controller = snapshot.data;
            final data = <Widget>[
              _Entry(
                icon: Icons.person_outline,
                title: l10n.youProfile,
                subtitle: l10n.youProfileSubtitle,
                onTap: () => _open(
                  context,
                  w.progress(),
                  (p) => ProfilePage(
                    controller: p,
                    reminders: w.reminders?.call(),
                  ),
                ),
              ),
              if (!w.simple)
                _Entry(
                  icon: Icons.military_tech_outlined,
                  title: badgesL10n(context).badgesTitle,
                  subtitle: badgesL10n(context).badgesEntrySubtitle,
                  onTap: () => _open(
                    context,
                    w.progress(),
                    (p) => BadgesPage(controller: p),
                  ),
                ),
              if (!w.simple)
                _Entry(
                  icon: Icons.insights_outlined,
                  title: l10n.youStats,
                  subtitle: l10n.youStatsSubtitle,
                  onTap: () =>
                      _open(context, w.archive(), (a) => StatsPage(archive: a)),
                ),
              // Una sola voce per la settimana; l'immagine da condividere, per
              // gli adulti, è il pulsante a destra.
              _Entry(
                icon: Icons.event_note_outlined,
                title: l10n.youWeek,
                subtitle: l10n.youWeekSubtitle,
                onTap: () => _open(
                  context,
                  w.progress(),
                  (p) => WeeklySummaryPage(
                    log: p.weekLog,
                    openLesson: _playLesson,
                    openPuzzles: w.puzzlesPage == null ? null : _openPuzzles,
                  ),
                ),
                action: w.simple
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.ios_share),
                        tooltip: l10n.youWeekShare,
                        onPressed: () => _open(
                          context,
                          w.archive(),
                          (a) => PortraitPage(archive: a),
                        ),
                      ),
              ),
              if (!w.simple)
                _Entry(
                  icon: Icons.inventory_2_outlined,
                  title: l10n.youArchive,
                  subtitle: l10n.youArchiveSubtitle,
                  onTap: () => _open(
                    context,
                    w.archive(),
                    (a) => ArchivePage(
                      archive: a,
                      onOpen: w.openGame == null
                          ? null
                          : (g) => w.openGame!(context, g),
                      onAnalyse: w.openAnalysis == null
                          ? null
                          : (g) => w.openAnalysis!(context, g),
                    ),
                  ),
                ),
            ];
            return ListView(
              // Tutta la scheda costruita, per la guida (vedi la Home).
              scrollCacheExtent: const ScrollCacheExtent.pixels(4000),
              padding: context.withSystemBottom(
                const EdgeInsets.only(bottom: 24),
              ),
              children: [
                if (controller != null)
                  ListenableBuilder(
                    listenable: controller,
                    builder: (context, _) => controller.settings.enabled
                        ? GuideAnchor(
                            id: 'you.header',
                            child: _Header(
                              controller: controller,
                              simple: w.simple,
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                GuideAnchor(
                  id: 'you.continue',
                  child: _ContinueCard(path: _pathFuture, onOpen: _continue),
                ),
                FutureBuilder<SavedGame?>(
                  future: _invite,
                  builder: (context, snapshot) {
                    final game = snapshot.data;
                    if (game == null || w.simple || w.openGame == null) {
                      return const SizedBox.shrink();
                    }
                    return ReviewInviteCard(
                      game: game,
                      onReview: (g) {
                        // Aperta la revisione l'invito ha fatto il suo.
                        unawaited(dismissReviewInvite());
                        setState(() {
                          _invite = Future<SavedGame?>.value();
                        });
                        w.openGame?.call(context, g);
                      },
                      onDismiss: () {
                        unawaited(dismissReviewInvite());
                        setState(() {
                          _invite = Future<SavedGame?>.value();
                        });
                      },
                    );
                  },
                ),
                GuideAnchor(
                  id: 'you.data',
                  child: _Group(title: l10n.youGroupData, children: data),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Riprende dalla Storia, che propone il passo giusto; senza storia le
  /// lezioni si aprono da sole.
  Future<void> _continue(Stage stage) async {
    final story = widget.storyPage;
    if (story != null) return _open(context, story(), (p) => p);
    if (!stage.isGuardian) return _playLesson(context, stage);
  }
}

/// Avatar, livello e serie in testa alla scheda.
class _Header extends StatelessWidget {
  const _Header({required this.controller, required this.simple});

  final ProgressController controller;
  final bool simple;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final level = levelForXp(controller.state.xp);
    return ListTile(
      contentPadding: const EdgeInsets.all(16),
      leading: ProfileAvatar(
        avatar: controller.settings.avatar,
        frame: controller.settings.frame,
        photo: simple ? null : controller.activePhoto,
        size: 48,
      ),
      // Profilo bambino (RP-06): stelle e fiamma come nel Profilo, senza
      // livello né giorni in cifre.
      title: simple
          ? KidStars(count: level, label: l10n.kidLevelStarsLabel)
          : Text(
              l10n.youLevel(level),
              style: Theme.of(context).textTheme.titleLarge,
            ),
      subtitle: simple
          ? KidFlame(lit: controller.streak > 0)
          : Text(
              '${l10n.youStreak(controller.streak)}'
              ' · ${controller.streakInfo(l10n).summary}',
            ),
    );
  }
}

/// Scheda in evidenza: l'unico invito dominante della pagina.
class _ContinueCard extends StatelessWidget {
  const _ContinueCard({required this.path, required this.onOpen});

  final Future<PathController> path;
  final Future<void> Function(Stage stage) onOpen;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PathController>(
      future: path,
      builder: (context, snapshot) {
        final controller = snapshot.data;
        if (controller == null) return const SizedBox.shrink();
        return ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final stage = nextStoryStage(controller.progress);
            if (stage == null) return const SizedBox.shrink();
            final l10n = AppLocalizations.of(context);
            final scheme = Theme.of(context).colorScheme;
            final tokens = RokkoTokens.of(context);
            final text = stage.isGuardian
                ? l10n.youContinueGuardian(stage.title)
                : l10n.youContinueStage(stage.title);
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Semantics(
                button: true,
                label: '${l10n.youContinueTitle}. $text',
                excludeSemantics: true,
                onTap: () => onOpen(stage),
                child: Material(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(tokens.radiusLarge),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => onOpen(stage),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: tokens.kidTouch),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.play_circle_fill,
                              size: 40,
                              color: scheme.onPrimaryContainer,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.youContinueTitle,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: scheme.onPrimaryContainer,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  Text(
                                    text,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: scheme.onPrimaryContainer,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Gruppo di voci con intestazione; senza voci non compare.
class _Group extends StatelessWidget {
  const _Group({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          clipBehavior: Clip.antiAlias,
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _Entry extends StatelessWidget {
  const _Entry({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.action,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  /// Pulsante secondario al posto della freccia.
  final Widget? action;

  @override
  Widget build(BuildContext context) => ListTile(
    minTileHeight: RokkoTokens.of(context).minTouch,
    leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
    title: Text(title),
    subtitle: Text(subtitle),
    trailing: action ?? const Icon(Icons.chevron_right),
    onTap: onTap,
  );
}

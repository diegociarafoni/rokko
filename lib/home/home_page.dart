import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../archive/saved_game.dart';
import '../engine/bot_collection.dart';
import '../engine/bots.dart';
import '../guide/guide_host.dart';
import '../l10n/app_localizations.dart';
import '../path/curriculum.dart';
import '../path/path_controller.dart';
import '../path/path_progress.dart';
import '../progress/avatar.dart';
import '../progress/guardian_avatar.dart';
import '../progress/profile_page.dart';
import '../progress/progress_controller.dart';
import '../progress/xp.dart';
import '../stats/local_rating.dart';
import '../storage/key_value_store.dart';
import '../story/story.dart';
import '../story/story_controller.dart';
import '../story/story_l10n.dart';
import '../theme/rokko_theme.dart';
import 'home_logic.dart';
import 'home_widgets.dart';

/// Azione di una funzione: l'apertura di una schermata. La Home si aggiorna
/// quando la schermata si chiude.
typedef HomeAction = Future<void> Function();

enum _Group { play, learn, train, progress }

class _Spec {
  const _Spec(this.id, this.icon, this.group);

  final String id;
  final IconData icon;
  final _Group group;
}

const _specs = [
  _Spec('bots', Icons.smart_toy_outlined, _Group.play),
  _Spec('friend', Icons.people_alt_outlined, _Group.play),
  _Spec('tournaments', Icons.emoji_events_outlined, _Group.play),
  _Spec('physical', Icons.timer_outlined, _Group.play),
  _Spec('story', Icons.auto_stories_outlined, _Group.learn),
  _Spec('openings', Icons.menu_book_outlined, _Group.learn),
  _Spec('endgames', Icons.flag_outlined, _Group.learn),
  _Spec('masters', Icons.workspace_premium_outlined, _Group.learn),
  _Spec('daily', Icons.today_outlined, _Group.train),
  _Spec('puzzles', Icons.extension_outlined, _Group.train),
  _Spec('minigames', Icons.videogame_asset_outlined, _Group.train),
  _Spec('stats', Icons.insights_outlined, _Group.progress),
  _Spec('badges', Icons.military_tech_outlined, _Group.progress),
  _Spec('archive', Icons.inventory_2_outlined, _Group.progress),
  _Spec('week', Icons.event_note_outlined, _Group.progress),
];

HomeHue _hue(_Group g) => switch (g) {
  _Group.play => HomeHue.play,
  _Group.learn => HomeHue.learn,
  _Group.train => HomeHue.train,
  _Group.progress => HomeHue.progress,
};

/// Etichetta e parole chiave di una funzione.
(String, List<String>) _text(AppLocalizations l, String id) => switch (id) {
  'bots' => (l.homeFeatureBots, const []),
  'friend' => (l.multiplayerTitle, [l.multiplayerEntrySubtitle]),
  'tournaments' => (l.youTournaments, [l.youTournamentsSubtitle]),
  'physical' => (l.physicalTitle, [l.physicalEntrySubtitle]),
  'story' => (l.storyTitle, [l.storyEntrySubtitle]),
  'openings' => (l.homeFeatureOpenings, [l.homeOpeningsSubtitle]),
  'endgames' => (l.youEndgames, [l.youEndgamesSubtitle]),
  'masters' => (l.youMasters, [l.youMastersSubtitle]),
  'daily' => (l.homeFeatureDaily, [l.homeDailySubtitle]),
  'puzzles' => (l.homeFeaturePuzzles, const []),
  'minigames' => (l.youMinigames, [l.youMinigamesSubtitle]),
  'stats' => (l.youStats, [l.youStatsSubtitle]),
  'badges' => (l.badgesTitle, [l.badgesEntrySubtitle]),
  'archive' => (l.youArchive, [l.youArchiveSubtitle]),
  'week' => (l.youWeek, [l.youWeekSubtitle]),
  _ => (l.youProfile, [l.youProfileSubtitle]),
};

class _Data {
  const _Data({
    this.progress,
    this.path,
    this.story,
    this.games = const [],
    this.collection = const BotCollection(),
  });

  final ProgressController? progress;
  final PathController? path;
  final StoryController? story;
  final List<SavedGame> games;
  final BotCollection collection;

  _Data copyWith({
    ProgressController? progress,
    PathController? path,
    StoryController? story,
    List<SavedGame>? games,
    BotCollection? collection,
  }) => _Data(
    progress: progress ?? this.progress,
    path: path ?? this.path,
    story: story ?? this.story,
    games: games ?? this.games,
    collection: collection ?? this.collection,
  );
}

/// Prima scheda: dice che cosa fare adesso e porta a ogni funzione con un
/// tocco. Usa solo dati che l'app ha già.
class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.progress,
    required this.path,
    required this.story,
    required this.games,
    required this.features,
    required this.onNewGame,
    required this.onSettings,
    this.collection,
    this.onResume,
    this.onOpenGame,
    this.onPlayBot,
    this.onContinueStory,
    this.simple = false,
    this.refresh,
  });

  /// Fonti dei dati, lette a ogni apertura: un errore si riprova.
  final Future<ProgressController> Function() progress;
  final Future<PathController> Function() path;
  final Future<StoryController> Function() story;
  final Future<List<SavedGame>> Function() games;

  /// Bot già battuti; quelli salvati se assente.
  final Future<BotCollection> Function()? collection;

  /// Funzioni raggiungibili, per id; quelle assenti non compaiono (per
  /// esempio i tornei senza motore).
  final Map<String, HomeAction> features;

  /// Apre «Nuova partita».
  final HomeAction onNewGame;
  final HomeAction onSettings;

  /// Riprende una partita lasciata a metà.
  final Future<void> Function(SavedGame game)? onResume;

  /// Apre una partita finita nella revisione.
  final Future<void> Function(SavedGame game)? onOpenGame;

  /// Parte contro il bot consigliato; assente senza motore.
  final Future<void> Function(Bot bot)? onPlayBot;

  /// Apre la Storia alla lezione proposta.
  final Future<void> Function(Stage stage)? onContinueStory;

  /// Profilo bambino: niente numeri, una scheda in testa e il gioco.
  final bool simple;

  /// Notifica quando la Home torna in vista dopo altre schede: i dati si
  /// rileggono.
  final Listenable? refresh;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // I dati arrivano uno alla volta: la Home si disegna subito e si completa
  // man mano, senza attese su schermo vuoto.
  var _data = const _Data();
  final _search = TextEditingController();

  // Ogni lettura ha un numero: una risposta in ritardo di una lettura
  // superata non cancella i dati più recenti.
  var _generation = 0;

  @override
  void initState() {
    super.initState();
    widget.refresh?.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    widget.refresh?.removeListener(_load);
    _search.dispose();
    super.dispose();
  }

  void _fetch<T>(
    int generation,
    Future<T> source,
    _Data Function(_Data data, T value) apply,
  ) {
    unawaited(
      source.then(
        (value) {
          if (mounted && generation == _generation) {
            setState(() => _data = apply(_data, value));
          }
        },
        onError: (Object e) {
          if (kDebugMode) {
            debugPrint('Home: dato non disponibile: $e'); // l10n-ok
          }
        },
      ),
    );
  }

  void _load() {
    final g = ++_generation;
    _fetch(g, widget.progress(), (d, v) => d.copyWith(progress: v));
    _fetch(g, widget.path(), (d, v) => d.copyWith(path: v));
    _fetch(g, widget.story(), (d, v) => d.copyWith(story: v));
    _fetch(g, widget.games(), (d, v) => d.copyWith(games: v));
    _fetch(
      g,
      (widget.collection ??
          () async => BotCollection.load(await JsonFileStore.open()))(),
      (d, v) => d.copyWith(collection: v),
    );
  }

  /// Esegue [action] e poi rilegge i dati: tornando dalla schermata aperta
  /// la Home mostra già i cambiamenti.
  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } finally {
      if (mounted) _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: _TopBar(
          progress: _data.progress,
          simple: widget.simple,
          onProfile: widget.features['profile'] == null
              ? null
              : () => _run(widget.features['profile']!),
        ),
        actions: [
          GuideAnchor(
            id: 'home.settings',
            child: IconButton(
              tooltip: l.homeSettings,
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => _run(widget.onSettings),
            ),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([
          ?_data.progress,
          ?_data.path,
          ?_data.story,
        ]),
        builder: (context, _) => _content(context, _data),
      ),
      bottomNavigationBar: GuideAnchor(
        id: 'home.play',
        child: _PlayButton(
          label: widget.simple ? l.homeKidPlay : l.homePlay,
          onTap: () => _run(widget.onNewGame),
        ),
      ),
    );
  }

  Widget _content(BuildContext context, _Data data) {
    final l = AppLocalizations.of(context);
    final query = _search.text;
    final searching = query.trim().isNotEmpty;
    final available = [
      for (final s in _specs)
        if (widget.features.containsKey(s.id)) s,
    ];
    final children = <Widget>[
      if (!widget.simple) _searchField(l),
      if (searching)
        ..._results(context, l, available, query)
      else ...[
        const SizedBox(height: 4),
        ?_hero(context, l, data),
        if (!widget.simple) ?_recommended(context, l, data),
        for (final g in _Group.values)
          ..._group(context, l, g, [
            for (final s in available)
              if (s.group == g) s,
          ]),
        if (!widget.simple) ...[
          ..._stats(context, l, data),
          ..._recent(context, l, data),
        ],
      ],
    ];
    return ListView(
      scrollCacheExtent: guideCacheExtent(context, 'home'),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: children,
    );
  }

  Widget _searchField(AppLocalizations l) => GuideAnchor(
    id: 'home.search',
    child: Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        key: const Key('home-search'),
        controller: _search,
        textInputAction: TextInputAction.search,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: l.homeSearchHint,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _search.text.isEmpty
              ? null
              : IconButton(
                  tooltip: l.homeSearchClear,
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(_search.clear),
                ),
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    ),
  );

  List<Widget> _results(
    BuildContext context,
    AppLocalizations l,
    List<_Spec> available,
    String query,
  ) {
    final byId = {for (final s in available) s.id: s};
    final found = searchFeatures([
      for (final s in available)
        HomeFeature(
          id: s.id,
          label: _text(l, s.id).$1,
          keywords: _text(l, s.id).$2,
        ),
    ], query);
    if (found.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            l.homeSearchEmpty,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ];
    }
    return [
      _grid([for (final f in found) _tile(l, byId[f.id]!)]),
    ];
  }

  Widget _tile(AppLocalizations l, _Spec s) => FeatureTile(
    key: Key('home-feature-${s.id}'),
    icon: s.icon,
    label: _text(l, s.id).$1,
    hue: _hue(s.group),
    onTap: () => _run(widget.features[s.id]!),
  );

  Widget _grid(List<Widget> tiles) => LayoutBuilder(
    builder: (context, box) {
      // Le colonne seguono il testo ingrandito: l'etichetta non si taglia.
      final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.0);
      final columns = (box.maxWidth / (84 * scale)).floor().clamp(2, 6);
      return GridView.count(
        crossAxisCount: columns,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 6,
        crossAxisSpacing: 4,
        childAspectRatio: 84 / (104 + 14 * (scale - 1)),
        children: tiles,
      );
    },
  );

  List<Widget> _group(
    BuildContext context,
    AppLocalizations l,
    _Group group,
    List<_Spec> specs,
  ) {
    if (specs.isEmpty) return const [];
    final title = switch (group) {
      _Group.play => l.homeGroupPlay,
      _Group.learn => l.homeGroupLearn,
      _Group.train => l.homeGroupTrain,
      _Group.progress => l.homeGroupProgress,
    };
    return [
      GroupHeader(title: title, hue: _hue(group)),
      if (group == _Group.play)
        GuideAnchor(
          id: 'home.games',
          child: _grid([for (final s in specs) _tile(l, s)]),
        )
      else
        _grid([for (final s in specs) _tile(l, s)]),
    ];
  }

  Widget? _hero(BuildContext context, AppLocalizations l, _Data data) {
    final open = unfinishedGame(data.games);
    final stage = data.path == null
        ? null
        : nextStoryStage(data.path!.progress);
    final storyOpen = widget.onContinueStory == null ? null : stage;
    final step = chooseNextStep(
      openGame: widget.onResume == null ? null : open,
      storyStage: storyOpen,
    );
    switch (step.kind) {
      case NextStepKind.resumeGame:
        final game = step.game!;
        return _heroPadding(
          HeroCard(
            key: const Key('home-hero-resume'),
            label: l.homeNextLabel,
            title: l.homeResumeTitle,
            subtitle: l.homeResumeSubtitle(opponentOf(game, l)),
            action: l.homeResumeAction,
            onTap: () => _run(() => widget.onResume!(game)),
            art: const ArtDisc(
              child: Icon(
                Icons.sports_esports_rounded,
                size: 56,
                color: Colors.white,
              ),
            ),
          ),
        );
      case NextStepKind.story:
        return _heroPadding(
          StoryHeroCard(
            key: const Key('home-hero-story'),
            path: data.path!.progress,
            story: data.story?.state ?? const StoryState(),
            stage: step.stage!,
            onTap: () => _run(() => widget.onContinueStory!(step.stage!)),
          ),
        );
      case NextStepKind.dailyPuzzle:
        final daily = widget.features['daily'];
        if (daily == null) return null;
        return _heroPadding(
          HeroCard(
            key: const Key('home-hero-daily'),
            label: l.homeNextLabel,
            title: l.homeDailyTitle,
            subtitle: l.homeDailySubtitle,
            action: l.homeDailyAction,
            onTap: () => _run(daily),
            art: const ArtDisc(
              child: Icon(
                Icons.extension_rounded,
                size: 56,
                color: Colors.white,
              ),
            ),
          ),
        );
    }
  }

  Widget _heroPadding(Widget child) => GuideAnchor(
    id: 'home.hero',
    child: Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: child,
    ),
  );

  Widget? _recommended(BuildContext context, AppLocalizations l, _Data data) {
    final play = widget.onPlayBot;
    if (play == null) return null;
    final rating = LocalRating.from(data.games).rating;
    final bot = recommendedBot(rating, data.collection);
    final theme = Theme.of(context);
    final tokens = RokkoTokens.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Card(
        key: const Key('home-recommended'),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _run(() => play(bot)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                GuardianAvatar(bot: bot),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.homeRecommendedTitle,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        bot.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (!widget.simple)
                        Text(
                          l.homeRecommendedElo(bot.elo),
                          style: theme.textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
                Semantics(
                  label: l.homeRecommendedAction(bot.name),
                  button: true,
                  excludeSemantics: true,
                  onTap: () => _run(() => play(bot)),
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: tokens.action,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: tokens.onAction,
                      size: 32,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _stats(BuildContext context, AppLocalizations l, _Data data) {
    final progress = data.progress;
    final rating = LocalRating.from(data.games).rating;
    final stats = widget.features['stats'];
    return [
      _SectionTitle(
        title: l.homeStatsTitle,
        action: stats == null ? null : l.homeSeeAll,
        onAction: stats == null ? null : () => _run(stats),
      ),
      GuideAnchor(
        id: 'home.stats',
        child: Row(
          children: [
            _StatTile(
              icon: Icons.trending_up_rounded,
              value: '$rating',
              label: l.homeStatsRating,
            ),
            const SizedBox(width: 8),
            _StatTile(
              icon: Icons.local_fire_department_rounded,
              value: '${progress?.streak ?? 0}',
              label: l.homeStatsStreak,
            ),
            const SizedBox(width: 8),
            _StatTile(
              icon: Icons.military_tech_rounded,
              value: '${progress?.badges.length ?? 0}',
              label: l.homeStatsBadges,
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _recent(BuildContext context, AppLocalizations l, _Data data) {
    final games = recentGames(data.games);
    final archive = widget.features['archive'];
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final format = NumberFormat('0.0', locale);
    return [
      _SectionTitle(
        title: l.homeRecentTitle,
        action: archive == null || games.isEmpty ? null : l.homeSeeAll,
        onAction: archive == null ? null : () => _run(archive),
        trailing: games.any((g) => g.accuracy != null)
            ? l.homeRecentAccuracy
            : null,
      ),
      if (games.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            l.homeRecentEmpty,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        )
      else
        Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (final g in games)
                _RecentRow(
                  game: g,
                  accuracy: g.accuracy == null
                      ? null
                      : format.format(g.accuracy),
                  onTap: widget.onOpenGame == null
                      ? null
                      : () => _run(() => widget.onOpenGame!(g)),
                ),
            ],
          ),
        ),
    ];
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.progress,
    required this.simple,
    required this.onProfile,
  });

  final ProgressController? progress;
  final bool simple;
  final VoidCallback? onProfile;

  @override
  Widget build(BuildContext context) {
    final p = progress;
    if (p == null || !p.settings.enabled) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: p,
      builder: (context, _) {
        final level = levelForXp(p.state.xp);
        return Row(
          children: [
            GuideAnchor(
              id: 'home.profile',
              child: InkResponse(
                key: const Key('home-profile'),
                onTap: onProfile,
                radius: 28,
                child: SizedBox.square(
                  dimension: 48,
                  child: Center(
                    child: ProfileAvatar(
                      avatar: p.settings.avatar,
                      frame: p.settings.frame,
                      photo: simple ? null : p.activePhoto,
                      size: 40,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            if (!simple) ...[
              _Chip(
                icon: Icons.local_fire_department_rounded,
                text: '${p.streak}',
                semantics: l.youStreak(p.streak),
              ),
              const SizedBox(width: 6),
              _Chip(
                icon: Icons.star_rounded,
                text: '$level',
                semantics: l.youLevel(level),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.icon,
    required this.text,
    required this.semantics,
  });

  final IconData icon;
  final String text;
  final String semantics;

  @override
  Widget build(BuildContext context) {
    final tokens = RokkoTokens.of(context);
    final theme = Theme.of(context);
    return Semantics(
      label: semantics,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: tokens.star),
            const SizedBox(width: 4),
            Text(
              text,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    this.action,
    this.onAction,
    this.trailing,
  });

  final String title;
  final String? action;
  final VoidCallback? onAction;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 0, 8),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          if (action != null)
            TextButton(onPressed: onAction, child: Text(action!))
          else if (trailing != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(
                trailing!,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = RokkoTokens.of(context);
    return Expanded(
      child: Semantics(
        label: '$label: $value',
        excludeSemantics: true,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(tokens.radiusLarge),
          ),
          child: Column(
            children: [
              Icon(icon, color: tokens.star),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentRow extends StatelessWidget {
  const _RecentRow({required this.game, required this.accuracy, this.onTap});

  final SavedGame game;
  final String? accuracy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final tokens = RokkoTokens.of(context);
    final score = game.playerScore;
    final (icon, color, result) = switch (score) {
      1.0 => (Icons.check_circle_rounded, tokens.success, l.homeResultWin),
      0.5 => (Icons.handshake_rounded, tokens.warning, l.homeResultDraw),
      0.0 => (
        Icons.cancel_rounded,
        Theme.of(context).colorScheme.error,
        l.homeResultLoss,
      ),
      _ => (Icons.circle_outlined, Theme.of(context).colorScheme.outline, ''),
    };
    final opponent = opponentOf(game, l);
    final label = accuracy == null
        ? l.homeRecentSemanticsNoAccuracy(result, opponent)
        : l.homeRecentSemantics(result, opponent, accuracy!);
    return Semantics(
      button: onTap != null,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: tokens.minTouch),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    opponent,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                if (accuracy != null)
                  Text(
                    accuracy!,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Il grande pulsante fisso in basso: apre «Nuova partita».
class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.scaffoldBackgroundColor,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        onTap: onTap,
        child: DecoratedBox(
          // Il bordo inferiore scuro dà il rilievo; sta fuori dal Material.
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(color: Color(0xFF3B5E28), offset: Offset(0, 4)),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: Ink(
              key: const Key('home-play'),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF6FA24D), Color(0xFF4F7F36)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: onTap,
                child: SizedBox(
                  height: 60,
                  child: Center(
                    child: Text(
                      label,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Scheda «Continua la Storia»: il capitolo in corso con il suo custode e
/// l'avanzamento complessivo. La usano la Home e la scheda Impara.
class StoryHeroCard extends StatelessWidget {
  const StoryHeroCard({
    super.key,
    required this.path,
    required this.story,
    required this.stage,
    required this.onTap,
    this.label,
  });

  final PathProgress path;
  final StoryState story;

  /// Lezione o guardiano da cui riprendere.
  final Stage stage;
  final VoidCallback onTap;

  /// Etichetta sopra il titolo; «Prossimo passo per te» se assente.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final progress = StoryProgress(path, story);
    final index = progress.currentChapterIndex;
    final chapter = index == null ? null : storyChapters[index];
    return HeroCard(
      label: label ?? l.homeNextLabel,
      title: l.homeStoryTitle,
      subtitle: chapter == null
          ? stage.title
          : storyL10n(context).chapterTitle(chapter),
      action: l.homeStoryAction,
      progress: progress.completedChapters / storyChapters.length,
      onTap: onTap,
      art: ArtDisc(
        child: chapter == null
            ? const Icon(
                Icons.auto_stories_rounded,
                size: 56,
                color: Colors.white,
              )
            : GuardianAvatar(
                bot: chapter.bot,
                size: 84,
                expression: AvatarExpression.greeting,
              ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../exchange/qr_l10n.dart';
import '../guide/guide_host.dart';
import '../guide/guide_steps.dart';
import '../kids/kid_display.dart';
import '../l10n/app_localizations.dart';
import '../settings/settings.dart';
import '../theme/rokko_theme.dart';
import '../theme/sheets.dart';
import 'activity_recorder.dart';
import 'friend_challenge_page.dart';
import 'mistake_path_page.dart';
import 'mode_guide.dart';
import 'puzzle_feed.dart';
import 'puzzle_page.dart';
import 'puzzle_run.dart';
import 'puzzle_run_page.dart';
import 'puzzle_trainer.dart';
import 'themes.dart';

/// Punto di ingresso dei puzzle: punteggio e modalità.
class PuzzleHubPage extends StatefulWidget {
  const PuzzleHubPage({
    super.key,
    required this.trainer,
    this.today,
    this.onActivity,
  });

  final Future<PuzzleTrainer> trainer;
  final ActivityRecorder? onActivity;

  /// Data usata per il puzzle del giorno; di default oggi.
  final DateTime? today;

  @override
  State<PuzzleHubPage> createState() => _PuzzleHubPageState();
}

class _PuzzleHubPageState extends State<PuzzleHubPage> {
  Future<void> _open(Widget page) async {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => page));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return GuideHost(
      screen: 'puzzles',
      steps: puzzlesGuide,
      child: Scaffold(
        appBar: AppBar(title: Text(l.puzzleHubTitle)),
        body: FutureBuilder<PuzzleTrainer>(
          future: widget.trainer,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text(l.puzzleHubLoadError));
            }
            final trainer = snapshot.data;
            if (trainer == null) {
              return const Center(child: CircularProgressIndicator());
            }
            final daily = trainer.library.daily(widget.today ?? DateTime.now());
            final due = trainer.dueReviews().length;
            // Profilo bambino (RP-06): niente punteggio, conteggi e difficoltà;
            // i puzzle risolti diventano stelle.
            final kid = AppSettings.of(context).kidMode;
            final text = Theme.of(context).textTheme;
            return ListView(
              scrollCacheExtent: guideCacheExtent(context, 'puzzles'),
              padding: context.withSystemBottom(
                const EdgeInsets.only(bottom: 24),
              ),
              children: [
                if (kid)
                  _KidHeader(solved: trainer.solvedCount)
                else
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(
                            l.puzzleHubRating(trainer.rating.rating.round()),
                            style: text.headlineMedium,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l.puzzleHubStats(
                            trainer.solvedCount,
                            trainer.failedCount,
                            trainer.library.puzzles.length,
                          ),
                          style: text.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                GuideAnchor(
                  id: 'puzzles.daily',
                  child: _DailyCard(
                    title: l.puzzleDailyTitle,
                    subtitle: kid
                        ? l.kidPuzzleDaily
                        : l.puzzleDailySubtitle(daily.rating),
                    onTap: () => _open(
                      PuzzlePage(
                        trainer: trainer,
                        puzzle: daily,
                        guide: PuzzleGuide.daily,
                        title: l.puzzleDailyTitle,
                        onActivity: widget.onActivity,
                      ),
                    ),
                  ),
                ),
                _Section(
                  anchor: 'puzzles.practice',
                  title: l.puzzleSectionPractice,
                  children: [
                    _HubTile(
                      icon: Icons.extension_outlined,
                      title: l.puzzleTraining,
                      subtitle: kid
                          ? l.kidPuzzleTraining
                          : l.puzzleTrainingSubtitle,
                      onTap: () => _open(
                        PuzzlePage(
                          trainer: trainer,
                          guide: PuzzleGuide.training,
                          onActivity: widget.onActivity,
                        ),
                      ),
                    ),
                    _HubTile(
                      icon: Icons.category_outlined,
                      title: l.puzzleByTheme,
                      subtitle: l.puzzleByThemeSubtitle,
                      onTap: () => _open(
                        _ThemeListPage(
                          trainer: trainer,
                          onActivity: widget.onActivity,
                        ),
                      ),
                    ),
                    // Gli errori e i temi sbagliati sono una misura del giocatore:
                    // il profilo bambino non li mostra.
                    if (!kid)
                      _HubTile(
                        icon: Icons.route_outlined,
                        title: l.puzzleMistakePath,
                        subtitle: l.puzzleMistakePathSubtitle,
                        onTap: () => _open(
                          MistakePathPage(
                            trainer: trainer,
                            onActivity: widget.onActivity,
                          ),
                        ),
                      ),
                    _HubTile(
                      icon: Icons.replay_outlined,
                      title: l.puzzleReview,
                      subtitle: kid
                          ? (due == 0
                                ? l.kidPuzzleReviewNone
                                : l.kidPuzzleReviewDue)
                          : (due == 0
                                ? l.puzzleReviewNone
                                : l.puzzleReviewDue(due)),
                      onTap: due == 0
                          ? null
                          : () => _open(
                              PuzzlePage(
                                trainer: trainer,
                                feed: ReviewFeed(trainer),
                                guide: PuzzleGuide.review,
                                title: l.puzzleReviewTitle,
                                onActivity: widget.onActivity,
                              ),
                            ),
                    ),
                  ],
                ),
                // Le modalità a tempo e la sfida ruotano attorno a punti, errori,
                // record e confronto: nel profilo bambino non compaiono.
                if (!kid)
                  _Section(
                    anchor: 'puzzles.timed',
                    title: l.puzzleSectionTimed,
                    children: [
                      for (final mode in PuzzleRunMode.values)
                        _HubTile(
                          icon: Icons.bolt_outlined,
                          title: l.puzzleRunLabel(mode.name),
                          subtitle: l.puzzleRunDescription(mode.name),
                          trailing: Text(
                            l.puzzleRecord(trainer.records.best(mode)),
                            style: text.labelLarge,
                          ),
                          onTap: () => _open(
                            PuzzleRunPage(
                              trainer: trainer,
                              mode: mode,
                              onActivity: widget.onActivity,
                            ),
                          ),
                        ),
                      _HubTile(
                        icon: Icons.people_outline,
                        title: qrL10n(context).challengeTitle,
                        subtitle: qrL10n(context).challengeSubtitle,
                        onTap: () => _open(
                          FriendChallengePage(
                            trainer: trainer,
                            onActivity: widget.onActivity,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Puzzle del giorno: la scheda più grande e colorata, è l'invito principale.
class _DailyCard extends StatelessWidget {
  const _DailyCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = RokkoTokens.of(context);
    final text = Theme.of(context).textTheme;
    final onColor = scheme.onPrimaryContainer;
    return Card(
      key: const Key('puzzle-hub-daily'),
      color: scheme.primaryContainer,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: tokens.kidTouch + 24),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ExcludeSemantics(
                  child: Icon(Icons.today, size: 40, color: onColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: text.titleLarge?.copyWith(color: onColor),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: text.bodyMedium?.copyWith(color: onColor),
                      ),
                    ],
                  ),
                ),
                ExcludeSemantics(
                  child: Icon(Icons.arrow_forward, color: onColor),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Gruppo di voci con un titolo, in una scheda.
class _Section extends StatelessWidget {
  const _Section({
    required this.anchor,
    required this.title,
    required this.children,
  });

  final String anchor;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
          child: Semantics(
            header: true,
            child: Text(
              title,
              style: text.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
        GuideAnchor(
          id: anchor,
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            clipBehavior: Clip.antiAlias,
            child: Column(children: children),
          ),
        ),
      ],
    );
  }
}

/// Voce della scheda: tocco di almeno 48 dp (56 nel profilo bambino).
class _HubTile extends StatelessWidget {
  const _HubTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final tokens = RokkoTokens.of(context);
    final kid = AppSettings.of(context).kidMode;
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: trailing,
      enabled: onTap != null,
      minTileHeight: kid ? tokens.kidTouch : tokens.minTouch,
      onTap: onTap,
    );
  }
}

/// Intestazione del profilo bambino: una stella per puzzle risolto, fino a
/// [kidMaxStars], così si vede crescere la raccolta senza contare.
class _KidHeader extends StatelessWidget {
  const _KidHeader({required this.solved});

  final int solved;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ListTile(
      title: Text(
        l.kidPuzzleHubTitle,
        style: Theme.of(context).textTheme.titleLarge,
      ),
      subtitle: KidStars(
        key: const Key('kid-puzzle-stars'),
        count: solved,
        label: l.kidPuzzleStarsLabel,
      ),
    );
  }
}

class _ThemeListPage extends StatelessWidget {
  const _ThemeListPage({required this.trainer, this.onActivity});

  final PuzzleTrainer trainer;
  final ActivityRecorder? onActivity;

  @override
  Widget build(BuildContext context) {
    final kid = AppSettings.of(context).kidMode;
    final l10n = AppLocalizations.of(context);
    final themes = [
      for (final id in puzzleThemeIds)
        if (trainer.library.countFor(id) > 0) (id, puzzleThemeLabel(l10n, id)!),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l10n.puzzleThemesTitle)),
      body: ListView.builder(
        itemCount: themes.length,
        itemBuilder: (context, i) {
          final t = themes[i];
          return ListTile(
            title: Text(t.$2),
            trailing: kid ? null : Text('${trainer.library.countFor(t.$1)}'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => PuzzlePage(
                  trainer: trainer,
                  theme: t.$1,
                  guide: PuzzleGuide.theme,
                  title: t.$2,
                  onActivity: onActivity,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;

import '../engine/bots.dart';
import '../guide/guide_host.dart';
import '../guide/guide_steps.dart';
import '../path/curriculum.dart';
import '../path/path_controller.dart';
import '../path/path_page.dart';
import '../path/path_widgets.dart';
import '../path/stage_page.dart';
import '../progress/avatar.dart';
import '../progress/guardian_avatar.dart';
import '../puzzles/themes.dart';
import '../settings/settings.dart';
import '../theme/rokko_theme.dart';
import '../theme/sheets.dart';
import 'guardian_says.dart';
import 'journey_map.dart';
import 'story.dart';
import 'story_controller.dart';
import 'story_l10n.dart';

/// Gioca la sfida contro [bot] e dice se è stata vinta.
typedef PlayStoryBoss = Future<bool> Function(BuildContext context, Bot bot);

/// Svolge una lezione e restituisce le stelle ottenute, o `null` se uscita
/// senza finire; di norma apre [StagePage].
typedef PlayStoryLesson = Future<int?> Function(
  BuildContext context,
  Stage stage,
);

/// Apre i puzzle del capitolo e restituisce quanti ne ha risolti al primo
/// tentativo (al massimo [remaining]); `null` se i puzzle non si caricano.
typedef PlayStoryPuzzles = Future<int?> Function(
  BuildContext context,
  StoryChapter chapter,
  int remaining,
);

/// Percorso a storia (RG-13): capitoli con racconto, lezioni, puzzle,
/// guardiano e un bot da battere. Vedi docs/storia.md.
class StoryPage extends StatefulWidget {
  const StoryPage({
    super.key,
    required this.path,
    required this.story,
    this.playGuardian,
    this.playBoss,
    this.onChaptersDone,
    this.playPuzzles,
    this.playLesson,
  });

  final PathController path;
  final StoryController story;
  final PlayGuardian? playGuardian;
  final PlayStoryBoss? playBoss;

  /// Chiamata con il totale dei capitoli conclusi, all'apertura e quando
  /// battere il bot ne conclude uno.
  final void Function(int chapters)? onChaptersDone;
  final PlayStoryPuzzles? playPuzzles;
  final PlayStoryLesson? playLesson;

  @override
  State<StoryPage> createState() => _StoryPageState();
}

class _StoryPageState extends State<StoryPage> {
  /// Evita di aprire due passi con un doppio tocco.
  bool _busy = false;

  /// Un riferimento per capitolo, per portarci la lista dalla mappa.
  final _cardKeys = [for (final _ in storyChapters) GlobalKey()];

  StoryProgress get _progress =>
      StoryProgress(widget.path.progress, widget.story.state);

  @override
  void initState() {
    super.initState();
    // Chi aveva già dei capitoli conclusi li vede riconosciuti subito.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _reportChapters();
    });
  }

  /// Dice quanti capitoli sono conclusi, se almeno uno.
  void _reportChapters() {
    final progress = _progress;
    final done = storyChapters.where(progress.isChapterDone).length;
    if (done > 0) widget.onChaptersDone?.call(done);
  }

  Future<T?> _run<T>(Future<T> Function() action) async {
    if (_busy) return null;
    _busy = true;
    try {
      return await action();
    } finally {
      _busy = false;
    }
  }

  void _say(String text, {Duration? duration}) => ScaffoldMessenger.of(context)
      .showSnackBar(
        SnackBar(
          content: Text(text),
          duration: duration ?? const Duration(seconds: 4),
        ),
      );

  Future<void> _open(
    StoryChapter chapter,
    StoryStepKind kind, {
    bool announced = false,
  }) async {
    final follow = await _run(() async {
      final wasDone = _progress
          .steps(chapter)
          .firstWhere((s) => s.kind == kind)
          .done;
      switch (kind) {
        case StoryStepKind.lessons:
          await _lesson(chapter);
        case StoryStepKind.puzzles:
          await _puzzles(chapter);
        case StoryStepKind.guardian:
          await _guardian(chapter);
        case StoryStepKind.boss:
          await _boss(chapter, announced: announced || wasDone);
      }
      if (!mounted || wasDone) return null;
      return _passage(chapter, kind);
    });
    // Il passo successivo si apre fuori dal blocco, che altrimenti lo rifiuta.
    if (follow != null && mounted) {
      await _open(
        follow.$1,
        follow.$2,
        announced: follow.$2 == StoryStepKind.boss,
      );
    }
  }

  /// Foglio di passaggio: celebra il passo appena concluso e propone il
  /// successivo. Restituisce quello da aprire subito, se scelto.
  Future<(StoryChapter, StoryStepKind)?> _passage(
    StoryChapter chapter,
    StoryStepKind kind,
  ) async {
    final progress = _progress;
    final step = progress.steps(chapter).firstWhere((s) => s.kind == kind);
    if (!step.done) return null;
    final l10n = storyL10n(context);
    final index = storyChapters.indexOf(chapter);
    (StoryChapter, StoryStepKind)? target;
    final String title;
    String? subtitle;
    final String body;
    String? action;
    var icon = Icons.check;
    AvatarExpression? expression;
    String? line;
    if (progress.isChapterDone(chapter)) {
      final hasNext = index + 1 < storyChapters.length;
      final nextChapter = hasNext ? storyChapters[index + 1] : null;
      icon = Icons.emoji_events_outlined;
      title = hasNext
          ? l10n.storyPassageChapterTitle(index)
          : l10n.storyPassageStoryDone;
      if (kind == StoryStepKind.boss) {
        subtitle = l10n.storyBossWon(chapter.bot.name);
        expression = AvatarExpression.surprised;
        line = l10n.guardianLine(chapter, GuardianMoment.bossWon);
      }
      body = nextChapter == null
          ? l10n.chapterOutro(chapter)
          : '${l10n.chapterOutro(chapter)}\n\n'
                '${l10n.storyPassageChapterNext(index + 1, l10n.chapterTitle(nextChapter))}';
      if (nextChapter != null) {
        action = l10n.storyPassageGoChapter;
        target = (nextChapter, StoryStepKind.lessons);
      }
    } else {
      final next = progress.steps(chapter).firstWhere((s) => !s.done).kind;
      target = (chapter, next);
      title = switch (kind) {
        StoryStepKind.lessons => l10n.storyPassageLessonsTitle,
        StoryStepKind.puzzles => l10n.storyPassagePuzzlesTitle,
        _ => l10n.storyPassageGuardianTitle,
      };
      body = switch (next) {
        StoryStepKind.puzzles => l10n.storyPassageNextPuzzles,
        StoryStepKind.guardian => l10n.storyPassageNextGuardian,
        _ => l10n.storyPassageNextBoss(chapter.bot.name),
      };
      action = switch (next) {
        StoryStepKind.puzzles => l10n.storyPassageGoPuzzles,
        StoryStepKind.guardian => l10n.storyPassageGoGuardian,
        _ => l10n.storyPassageGoBoss(chapter.bot.name),
      };
      if (next == StoryStepKind.boss) {
        expression = AvatarExpression.challenge;
        line = l10n.guardianLine(chapter, GuardianMoment.boss);
      } else if (kind == StoryStepKind.lessons) {
        expression = AvatarExpression.happy;
        line = l10n.guardianLine(chapter, GuardianMoment.lessonDone);
      }
    }
    final go = await showRokkoSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (_) => _PassageSheet(
        icon: icon,
        guardian: expression == null
            ? null
            : GuardianAvatar(
                bot: chapter.bot,
                expression: expression,
                size: 88,
              ),
        guardianLine: line == null
            ? null
            : l10n.storyGuardianSays(chapter.bot.name, line),
        title: title,
        subtitle: subtitle,
        body: body,
        action: action,
        dismiss: action == null
            ? l10n.storyPassageClose
            : l10n.storyPassageLater,
      ),
    );
    return go == true ? target : null;
  }

  Future<void> _lesson(StoryChapter chapter) async {
    final stage = chapter.pathChapter.stages
        .where((s) => !s.isGuardian && !widget.path.progress.isCompleted(s.id))
        .firstOrNull;
    if (stage == null) return;
    final started = DateTime.now();
    final play = widget.playLesson;
    final stars = play != null
        ? await play(context, stage)
        : await openStage(context, widget.path, stage);
    if (stars != null && stars > 0) {
      await widget.path.complete(
        stage,
        stars,
        DateTime.now().difference(started),
      );
    }
  }

  Future<void> _puzzles(StoryChapter chapter) async {
    final play = widget.playPuzzles;
    if (play == null) return;
    final remaining =
        chapter.puzzleCount - widget.story.state.puzzlesSolved(chapter.id);
    final solved = await play(context, chapter, remaining);
    if (!mounted) return;
    if (solved == null) return _say(storyL10n(context).storyPuzzlesNone);
    if (solved > 0) await widget.story.puzzlesSolved(chapter, solved);
  }

  Future<void> _guardian(StoryChapter chapter) async {
    final play = widget.playGuardian;
    if (play == null) return _say(storyL10n(context).storyEngineMissing);
    final stage = chapter.pathChapter.stages
        .where((s) => s.isGuardian)
        .firstOrNull;
    if (stage == null) return;
    final stars = await play(context, stage);
    if (stars != null && stars > 0) {
      await widget.path.complete(stage, stars, Duration.zero);
    }
  }

  /// Foglio che presenta la sfida al custode; salta se il foglio di
  /// passaggio l'ha già annunciata.
  Future<bool> _challengeAccepted(StoryChapter chapter) async {
    final l10n = storyL10n(context);
    final go = await showRokkoSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (_) => _PassageSheet(
        icon: Icons.sports_esports_outlined,
        guardian: GuardianAvatar(
          bot: chapter.bot,
          expression: AvatarExpression.challenge,
          size: 88,
        ),
        guardianLine: l10n.storyGuardianSays(
          chapter.bot.name,
          l10n.guardianLine(chapter, GuardianMoment.boss),
        ),
        title: l10n.storyChallengeTitle(chapter.bot.name),
        body: l10n.chapterBoss(chapter),
        action: l10n.storyPassageGoBoss(chapter.bot.name),
        dismiss: l10n.storyPassageLater,
      ),
    );
    return go == true;
  }

  Future<void> _boss(StoryChapter chapter, {bool announced = false}) async {
    final play = widget.playBoss;
    if (play == null) return _say(storyL10n(context).storyEngineMissing);
    if (!announced && !await _challengeAccepted(chapter)) return;
    if (!mounted) return;
    final won = await play(context, chapter.bot);
    if (!mounted) return;
    if (won) {
      await widget.story.bossBeaten(chapter);
      if (mounted) _reportChapters();
    } else {
      final l10n = storyL10n(context);
      final line = l10n.guardianLine(chapter, GuardianMoment.bossLost);
      _say(
        '${l10n.storyBossLost(chapter.bot.name)}\n'
        '${l10n.storyGuardianSays(chapter.bot.name, line)}',
        duration: const Duration(seconds: 8),
      );
    }
  }

  /// Primo passo da fare nel capitolo corrente.
  (StoryChapter, StoryStepKind)? get _next {
    final index = _progress.currentChapterIndex;
    if (index == null) return null;
    final chapter = storyChapters[index];
    final step = _progress.steps(chapter).firstWhere((s) => !s.done);
    return (chapter, step.kind);
  }

  /// Porta in vista il capitolo [index].
  void _goTo(int index) {
    final target = _cardKeys[index].currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      alignment: 0.05,
      duration:
          AppSettings.of(context).reduceMotion ||
              MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = storyL10n(context);
    return GuideHost(
      screen: 'story',
      steps: storyGuide,
      child: ListenableBuilder(
        listenable: Listenable.merge([widget.path, widget.story]),
        builder: (context, _) {
          final progress = _progress;
          final next = _next;
          return Scaffold(
            appBar: AppBar(title: Text(l10n.storyTitle)),
            // Barra fissa e non pulsante flottante: così non copre i capitoli.
            bottomNavigationBar: next == null
                ? null
                : SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: GuideAnchor(
                        id: 'story.continue',
                        child: FilledButton.icon(
                          onPressed: () => _open(next.$1, next.$2),
                          icon: const Icon(Icons.play_arrow),
                          label: Text(l10n.storyContinue),
                        ),
                      ),
                    ),
                  ),
            body: ListView(
              // I nove capitoli sono pochi: tutti costruiti, così la mappa può
              // portare a ciascuno.
              scrollCacheExtent: const ScrollCacheExtent.pixels(20000),
              // Con la barra «Continua» l'ingombro è già assorbito da lei.
              padding: next == null
                  ? context.withSystemBottom(
                      const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    )
                  : const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: [
                GuideAnchor(
                  id: 'story.summary',
                  child: _Summary(
                    progress: progress,
                    current: _progress.currentChapterIndex,
                    onSelect: _goTo,
                  ),
                ),
                const SizedBox(height: 12),
                for (final (i, chapter) in storyChapters.indexed)
                  _guideChapter(
                    current: next?.$1.id == chapter.id,
                    first: i == 0 && next == null,
                    child: _ChapterCard(
                      key: _cardKeys[i],
                      index: i,
                      chapter: chapter,
                      progress: progress,
                      current: next?.$1.id == chapter.id,
                      last: i == storyChapters.length - 1,
                      onOpen: (kind) => _open(chapter, kind),
                      onFork: (theme) =>
                          widget.story.chooseFork(chapter, theme),
                    ),
                  ),
                if (next == null)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      l10n.storyFinished,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// La guida evidenzia il capitolo in corso, o il primo a storia finita.
  Widget _guideChapter({
    required bool current,
    required bool first,
    required Widget child,
  }) =>
      current || first ? GuideAnchor(id: 'story.chapter', child: child) : child;
}

/// Capitoli conclusi, in cima alla storia.
class _Summary extends StatelessWidget {
  const _Summary({
    required this.progress,
    required this.current,
    required this.onSelect,
  });

  final StoryProgress progress;
  final int? current;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = storyL10n(context);
    final kid = AppSettings.of(context).kidMode;
    final done = progress.completedChapters;
    return Card(
      key: const ValueKey('story-summary'),
      margin: const EdgeInsets.only(top: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              // Il profilo bambino non conta i capitoli: resta la barra.
              kid
                  ? l10n.storyKidProgress
                  : l10n.storyProgress(done, storyChapters.length),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            // La barra legge la percentuale: ai bambini non si dice.
            ExcludeSemantics(
              excluding: kid,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                  RokkoTokens.of(context).radiusSmall,
                ),
                child: LinearProgressIndicator(
                  value: done / storyChapters.length,
                  minHeight: 10,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Semantics(
              header: true,
              child: Text(
                l10n.storyMapTitle,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            const SizedBox(height: 8),
            JourneyMap(
              progress: progress,
              current: current,
              onSelect: onSelect,
            ),
          ],
        ),
      ),
    );
  }
}

/// Binario verticale che unisce i capitoli: pieno fino al capitolo aperto,
/// tratteggiato oltre.
class _RailPainter extends CustomPainter {
  const _RailPainter({
    required this.color,
    required this.dashed,
    required this.top,
  });

  final Color color;
  final bool dashed;

  /// Altezza del badge, da cui parte il binario.
  final double top;

  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..color = color;
    var y = top;
    while (y < size.height) {
      final end = dashed ? (y + 7).clamp(0, size.height) : size.height;
      canvas.drawLine(Offset(x, y), Offset(x, end.toDouble()), paint);
      if (!dashed) break;
      y += 13;
    }
  }

  @override
  bool shouldRepaint(_RailPainter old) =>
      old.color != color || old.dashed != dashed || old.top != top;
}

class _ChapterCard extends StatelessWidget {
  const _ChapterCard({
    super.key,
    required this.index,
    required this.chapter,
    required this.progress,
    required this.current,
    required this.last,
    required this.onOpen,
    required this.onFork,
  });

  final int index;
  final StoryChapter chapter;
  final StoryProgress progress;
  final bool current;
  final bool last;
  final void Function(StoryStepKind kind) onOpen;
  final void Function(String theme) onFork;

  static const _badge = 48.0;

  @override
  Widget build(BuildContext context) {
    final l10n = storyL10n(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = RokkoTokens.of(context);
    final unlocked = progress.isChapterUnlocked(index);
    final done = progress.isChapterDone(chapter);
    final title = l10n.chapterTitle(chapter);
    final steps = progress.steps(chapter);
    final kid = AppSettings.of(context).kidMode;
    final stepsDone = steps.where((s) => s.done).length;
    final cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(tokens.radiusLarge),
      side: current
          ? BorderSide(color: tokens.action, width: 2)
          : BorderSide.none,
    );
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: _badge,
              child: CustomPaint(
                painter: _RailPainter(
                  color: done ? scheme.primary : scheme.outlineVariant,
                  dashed: !done,
                  top: last ? double.infinity : _badge,
                ),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: _Badge(
                    key: ValueKey('story-badge-${chapter.id}'),
                    number: index,
                    unlocked: unlocked,
                    done: done,
                    value: stepsDone / steps.length,
                    size: _badge,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Stack(
                children: [
                  Card(
                    key: ValueKey('story-chapter-${chapter.id}'),
                    margin: EdgeInsets.zero,
                    color: unlocked ? null : scheme.surface,
                    elevation: unlocked ? null : 0,
                    shape: cardShape,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Semantics(
                            container: true,
                            header: true,
                            label:
                                '${l10n.storyChapterNumber(index)}: $title'
                                '${done ? ', ${l10n.storyChapterDone}' : ''}'
                                '${current ? ', ${l10n.storyChapterCurrent}' : ''}'
                                '${unlocked ? '' : ', ${l10n.storyStepLocked}'}',
                            excludeSemantics: true,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.storyChapterNumber(index),
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                                Text(
                                  title,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    color: unlocked
                                        ? null
                                        : scheme.onSurfaceVariant,
                                  ),
                                ),
                                if (current)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      l10n.storyChapterCurrent,
                                      style: theme.textTheme.labelLarge
                                          ?.copyWith(color: scheme.primary),
                                    ),
                                  ),
                                if (unlocked && !kid)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      l10n.storyChapterSteps(
                                        stepsDone,
                                        steps.length,
                                      ),
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (!unlocked)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(l10n.storyChapterLocked),
                            )
                          else ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(l10n.chapterIntro(chapter)),
                            ),
                            GuardianSays(
                              key: ValueKey('story-welcome-${chapter.id}'),
                              chapter: chapter,
                              moment: GuardianMoment.welcome,
                              expression: AvatarExpression.greeting,
                            ),
                            const SizedBox(height: 8),
                            for (final step in steps) ...[
                              _StepTile(
                                chapter: chapter,
                                step: step,
                                unlocked: progress.isStepUnlocked(
                                  chapter,
                                  step.kind,
                                ),
                                onTap: () => onOpen(step.kind),
                              ),
                              if (step.kind == StoryStepKind.puzzles &&
                                  !step.done &&
                                  step.value == 0 &&
                                  progress.isStepUnlocked(chapter, step.kind))
                                _ForkChoice(
                                  chapter: chapter,
                                  selected: progress.state.themeFor(chapter),
                                  onChoose: onFork,
                                ),
                            ],
                            if (done)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  l10n.chapterOutro(chapter),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (!unlocked)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          key: ValueKey('story-dashed-${chapter.id}'),
                          painter: DashedShapePainter(
                            shape: cardShape,
                            color: scheme.outline,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Numero del capitolo dentro un anello di avanzamento; spunta a capitolo
/// concluso, lucchetto se chiuso.
class _Badge extends StatelessWidget {
  const _Badge({
    super.key,
    required this.number,
    required this.unlocked,
    required this.done,
    required this.value,
    required this.size,
  });

  final int number;
  final bool unlocked;
  final bool done;
  final double value;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return ExcludeSemantics(
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? scheme.primary : scheme.surface,
              ),
              child: SizedBox.expand(
                child: CircularProgressIndicator(
                  value: done ? 1 : value,
                  strokeWidth: 5,
                  backgroundColor: scheme.outlineVariant,
                ),
              ),
            ),
            if (done)
              Icon(Icons.check, color: scheme.onPrimary)
            else if (!unlocked)
              Icon(Icons.lock_outline, color: scheme.onSurfaceVariant)
            else
              Text(
                '$number',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Bivio del capitolo: due temi per i puzzle, da scegliere prima del primo.
class _ForkChoice extends StatelessWidget {
  const _ForkChoice({
    required this.chapter,
    required this.selected,
    required this.onChoose,
  });

  final StoryChapter chapter;
  final String selected;
  final void Function(String theme) onChoose;

  @override
  Widget build(BuildContext context) {
    final l10n = storyL10n(context);
    return Padding(
      padding: const EdgeInsets.only(left: 40, bottom: 8),
      key: ValueKey('story-fork-${chapter.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.storyForkTitle,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final id in [chapter.puzzleTheme, chapter.forkTheme])
                ChoiceChip(
                  key: ValueKey('story-fork-${chapter.id}-$id'),
                  label: Text(puzzleThemeLabel(l10n, id) ?? id),
                  selected: selected == id,
                  onSelected: (_) => onChoose(id),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({
    required this.chapter,
    required this.step,
    required this.unlocked,
    required this.onTap,
  });

  final StoryChapter chapter;
  final StoryStep step;
  final bool unlocked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = storyL10n(context);
    final kid = AppSettings.of(context).kidMode;
    final title = switch (step.kind) {
      StoryStepKind.lessons =>
        kid
            ? l10n.storyKidStepLessons
            : l10n.storyStepLessons(step.value, step.total),
      StoryStepKind.puzzles =>
        kid
            ? l10n.storyKidStepPuzzles
            : l10n.storyStepPuzzles(step.value, step.total),
      StoryStepKind.guardian => l10n.storyStepGuardian,
      StoryStepKind.boss => l10n.storyStepBoss(chapter.bot.name),
    };
    final state = step.done
        ? l10n.storyStepDone
        : unlocked
        ? l10n.storyStepTodo
        : l10n.storyStepLocked;
    final counted =
        step.kind == StoryStepKind.lessons ||
        step.kind == StoryStepKind.puzzles;
    final active = unlocked && !step.done;
    final theme = Theme.of(context);
    final muted = active
        ? theme.colorScheme.onSurfaceVariant
        : theme.disabledColor;
    return Semantics(
      container: true,
      button: active,
      enabled: active,
      label: '$title, $state',
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(
          RokkoTokens.of(context).radiusSmall,
        ),
        onTap: active ? onTap : null,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: RokkoTokens.of(context).minTouch,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  child: step.kind == StoryStepKind.boss
                      ? ExcludeSemantics(
                          child: Text(
                            chapter.bot.avatar,
                            style: const TextStyle(fontSize: 28),
                          ),
                        )
                      : Icon(switch (step.kind) {
                          StoryStepKind.lessons => Icons.school_outlined,
                          StoryStepKind.puzzles => Icons.extension_outlined,
                          _ => Icons.shield_outlined,
                        }, color: muted),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: active ? null : muted,
                        ),
                      ),
                      Text(
                        step.kind == StoryStepKind.boss && active
                            ? l10n.chapterBoss(chapter)
                            : state,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (counted)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              key: ValueKey(
                                'story-step-progress-'
                                '${chapter.id}-${step.kind.name}',
                              ),
                              value: step.total == 0
                                  ? 0
                                  : step.value / step.total,
                              minHeight: 6,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  step.done
                      ? Icons.check_circle
                      : unlocked
                      ? Icons.chevron_right
                      : Icons.lock_outline,
                  color: step.done ? theme.colorScheme.primary : muted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Foglio di passaggio fra un passo e l'altro: icona che compare con un
/// piccolo rimbalzo (ferma se l'utente ha disattivato le animazioni), cosa è
/// stato fatto e cosa viene dopo.
class _PassageSheet extends StatelessWidget {
  const _PassageSheet({
    required this.icon,
    required this.title,
    required this.body,
    required this.dismiss,
    this.guardian,
    this.guardianLine,
    this.subtitle,
    this.action,
  });

  /// Avatar del custode al posto dell'icona e la sua battuta, già
  /// nella forma «{nome} dice: …».
  final Widget? guardian;
  final String? guardianLine;
  final IconData icon;
  final String title;
  final String? subtitle;
  final String body;
  final String? action;
  final String dismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = RokkoTokens.of(context);
    final still = MediaQuery.disableAnimationsOf(context);
    return SafeArea(
      child: SingleChildScrollView(
        key: const ValueKey('story-passage'),
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ExcludeSemantics(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: still ? 1 : 0, end: 1),
                duration: still
                    ? Duration.zero
                    : const Duration(milliseconds: 700),
                curve: Curves.elasticOut,
                builder: (context, t, _) => Transform.scale(
                  scale: t,
                  child: Column(
                    children: [
                      guardian ??
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: tokens.action,
                            ),
                            child: Icon(icon, size: 40, color: tokens.onAction),
                          ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (final size in const [18.0, 26.0, 18.0])
                            Icon(Icons.star, size: size, color: tokens.star),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Semantics(
              header: true,
              liveRegion: true,
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall,
              ),
            ),
            if (subtitle != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium,
                ),
              ),
            const SizedBox(height: 12),
            Text(
              body,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            if (guardianLine != null) ...[
              const SizedBox(height: 12),
              Text(
                guardianLine!,
                key: const ValueKey('story-passage-guardian'),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 24),
            if (action != null)
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(action!),
              ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              style: TextButton.styleFrom(
                minimumSize: Size.fromHeight(tokens.minTouch),
              ),
              child: Text(dismiss),
            ),
          ],
        ),
      ),
    );
  }
}

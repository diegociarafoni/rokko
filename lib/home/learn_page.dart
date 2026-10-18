import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../guide/guide_host.dart';
import '../guide/guide_steps.dart';
import '../l10n/app_localizations.dart';
import '../path/curriculum.dart';
import '../path/path_controller.dart';
import '../story/story.dart';
import '../story/story_controller.dart';
import '../theme/sheets.dart';
import 'home_page.dart';
import 'home_widgets.dart';

/// Scheda «Impara»: riprendere da dove eri e le quattro vie dello studio.
class LearnPage extends StatefulWidget {
  const LearnPage({
    super.key,
    required this.path,
    required this.story,
    required this.features,
    this.onContinueStory,
  });

  final Future<PathController> Function() path;
  final Future<StoryController> Function() story;

  /// Voci disponibili, per id: `story`, `openings`, `endgames`, `masters`,
  /// `minigames`; le assenti non compaiono.
  final Map<String, HomeAction> features;

  final Future<void> Function(Stage stage)? onContinueStory;

  @override
  State<LearnPage> createState() => _LearnPageState();
}

class _LearnPageState extends State<LearnPage> {
  PathController? _path;
  StoryController? _story;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    unawaited(
      widget.path().then(
        (v) {
          if (mounted) setState(() => _path = v);
        },
        onError: (Object e) {
          if (kDebugMode) {
            debugPrint('Impara: percorso non disponibile: $e'); // l10n-ok
          }
        },
      ),
    );
    unawaited(
      widget.story().then(
        (v) {
          if (mounted) setState(() => _story = v);
        },
        onError: (Object e) {
          if (kDebugMode) {
            debugPrint('Impara: storia non disponibile: $e'); // l10n-ok
          }
        },
      ),
    );
  }

  Future<void> _run(HomeAction action) async {
    try {
      await action();
    } finally {
      if (mounted) _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final entries = [
      (
        'story',
        Icons.auto_stories_outlined,
        l.storyTitle,
        l.storyEntrySubtitle,
      ),
      (
        'openings',
        Icons.menu_book_outlined,
        l.homeFeatureOpenings,
        l.homeOpeningsSubtitle,
      ),
      ('endgames', Icons.flag_outlined, l.youEndgames, l.youEndgamesSubtitle),
      (
        'masters',
        Icons.workspace_premium_outlined,
        l.youMasters,
        l.youMastersSubtitle,
      ),
      (
        'minigames',
        Icons.videogame_asset_outlined,
        l.youMinigames,
        l.youMinigamesSubtitle,
      ),
    ];
    return GuideHost(
      screen: 'learn',
      steps: learnGuide,
      child: Scaffold(
        appBar: AppBar(title: Text(l.homeNavLearn)),
        body: ListenableBuilder(
          listenable: Listenable.merge([?_path, ?_story]),
          builder: (context, _) {
            final path = _path;
            final story = _story;
            final stage = path == null ? null : nextStoryStage(path.progress);
            final onContinue = widget.onContinueStory;
            return ListView(
              scrollCacheExtent: guideCacheExtent(context, 'learn'),
              padding: context.withSystemBottom(
                const EdgeInsets.fromLTRB(16, 4, 16, 24),
              ),
              children: [
                if (path != null && stage != null && onContinue != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GuideAnchor(
                      id: 'learn.hero',
                      child: StoryHeroCard(
                        key: const Key('learn-hero'),
                        label: l.youContinueTitle,
                        path: path.progress,
                        story: story?.state ?? const StoryState(),
                        stage: stage,
                        onTap: () => _run(() => onContinue(stage)),
                      ),
                    ),
                  ),
                for (final (id, icon, title, subtitle) in entries)
                  if (widget.features[id] case final action?)
                    GuideAnchor(
                      id: 'learn.$id',
                      child: _LearnTile(
                        key: Key('learn-$id'),
                        icon: icon,
                        title: title,
                        subtitle: subtitle,
                        hue: id == 'minigames' ? HomeHue.train : HomeHue.learn,
                        onTap: () => _run(action),
                      ),
                    ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LearnTile extends StatelessWidget {
  const _LearnTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.hue,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final HomeHue hue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Semantics(
        button: true,
        label: '$title. $subtitle',
        excludeSemantics: true,
        onTap: onTap,
        child: Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: hue.gradient,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(icon, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(subtitle, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

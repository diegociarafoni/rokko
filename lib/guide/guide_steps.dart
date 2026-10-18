import 'guide_host.dart';

/// I passi della guida di ogni schermata, nell'ordine in cui compaiono. Un passo
/// il cui elemento non c'è (per esempio la ricerca nel profilo bambino) salta.

final homeGuide = <GuideStep>[
  GuideStep('home.profile', (l, _) => l.guideHomeProfile),
  GuideStep('home.settings', (l, _) => l.guideHomeSettings),
  GuideStep('home.search', (l, _) => l.guideHomeSearch),
  GuideStep(
    'home.hero',
    (l, kid) => kid ? l.guideHomeHeroKid : l.guideHomeHero,
  ),
  GuideStep('home.games', (l, _) => l.guideHomeGames),
  GuideStep('home.stats', (l, _) => l.guideHomeStats),
  GuideStep(
    'home.play',
    (l, kid) => kid ? l.guideHomePlayKid : l.guideHomePlay,
  ),
  GuideStep('home.nav', (l, _) => l.guideHomeNav),
];

final puzzlesGuide = <GuideStep>[
  GuideStep('puzzles.daily', (l, _) => l.guidePuzzlesDaily),
  GuideStep('puzzles.practice', (l, _) => l.guidePuzzlesPractice),
  GuideStep('puzzles.timed', (l, _) => l.guidePuzzlesTimed),
];

final learnGuide = <GuideStep>[
  GuideStep('learn.hero', (l, _) => l.guideLearnHero),
  GuideStep('learn.story', (l, _) => l.guideLearnStory),
  GuideStep('learn.openings', (l, _) => l.guideLearnOpenings),
  GuideStep('learn.masters', (l, _) => l.guideLearnMasters),
  GuideStep('learn.minigames', (l, _) => l.guideLearnMinigames),
];

final youGuide = <GuideStep>[
  GuideStep('you.header', (l, _) => l.guideYouHeader),
  GuideStep('you.continue', (l, _) => l.guideYouContinue),
  GuideStep('you.data', (l, _) => l.guideYouData),
];

final settingsGuide = <GuideStep>[
  GuideStep('settings.search', (l, _) => l.guideSettingsSearch),
  GuideStep('settings.profile', (l, _) => l.guideSettingsProfile),
  GuideStep('settings.style', (l, _) => l.guideSettingsStyle),
  GuideStep('settings.board', (l, _) => l.guideSettingsBoard),
  GuideStep('settings.game', (l, _) => l.guideSettingsGame),
  GuideStep('settings.accessibility', (l, _) => l.guideSettingsAccessibility),
  GuideStep('settings.kid', (l, _) => l.guideSettingsKid),
];

final newGameGuide = <GuideStep>[
  GuideStep('newGame.clock', (l, _) => l.guideNewGameClock),
  GuideStep('newGame.quick', (l, _) => l.guideNewGameQuick),
  GuideStep('newGame.friend', (l, _) => l.guideNewGameFriend),
  GuideStep('newGame.bots', (l, _) => l.guideNewGameBots),
];

final gameGuide = <GuideStep>[
  GuideStep(
    'game.board',
    (l, kid) => kid ? l.guideGameBoardKid : l.guideGameBoard,
  ),
  GuideStep('game.moves', (l, _) => l.guideGameMoves),
  GuideStep('game.action.hint', (l, _) => l.guideGameHint),
  GuideStep('game.action.undo', (l, _) => l.guideGameUndo),
  GuideStep('game.action.flip', (l, _) => l.guideGameFlip),
  GuideStep('game.action.new', (l, _) => l.guideGameNew),
  GuideStep('game.action.draw', (l, _) => l.guideGameDraw),
  GuideStep('game.action.resign', (l, _) => l.guideGameResign),
  GuideStep('game.action.more', (l, _) => l.guideGameMore),
];

final storyGuide = <GuideStep>[
  GuideStep('story.summary', (l, _) => l.guideStorySummary),
  GuideStep('story.chapter', (l, _) => l.guideStoryChapter),
  GuideStep('story.continue', (l, _) => l.guideStoryContinue),
];

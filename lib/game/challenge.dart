import 'package:dartchess/dartchess.dart';

import '../progress/activity.dart';

/// Partita già impostata contro il computer, lanciata da un'altra schermata
/// (guardiano del percorso, partita di un torneo): parte subito, senza scelte
/// e senza poter ricominciare; l'annullamento dipende da [allowUndo].
class GameChallenge {
  const GameChallenge({
    required this.title,
    required this.levelId,
    required this.side,
    this.allowUndo = false,
    this.allowHints = false,
    this.startMoves = const [],
    this.line,
    this.instructor = false,
  });

  /// Titolo della schermata, per esempio "Il guardiano".
  final String title;

  /// Livello del motore (vedi `engineLevels`).
  final int levelId;

  /// Colore dell'utente.
  final Side side;

  /// Se l'annullamento è consentito: sì nell'allenamento (guardiano), no nelle
  /// partite che contano come torneo.
  final bool allowUndo;

  /// Se il pulsante Suggerisci è disponibile (senza allenatore né barra di
  /// valutazione): sì nelle sfide di allenamento, no nei tornei.
  final bool allowHints;

  /// Mosse già giocate all'inizio (apertura scelta, RF-94).
  final List<Move> startMoves;

  /// Linea del repertorio da seguire: se qualcuno ne esce, la partita lo
  /// segnala.
  final List<Move>? line;

  /// Partita con l'istruttore: l'allenatore resta acceso e commenta l'apertura
  /// con le mosse più giocate, avvisando quando si esce dal libro.
  final bool instructor;
}

/// Stelle di una sfida vinta, in base alla lunghezza della partita: tre fino a
/// 40 mosse, due fino a 60, poi una. `null` se non si è vinto.
int? challengeStars(GameResult result, {required int moves}) {
  if (result != GameResult.win) return null;
  if (moves <= 40) return 3;
  if (moves <= 60) return 2;
  return 1;
}

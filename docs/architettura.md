# Architettura

## Stack

| Livello | Tecnologia | Ruolo |
|---|---|---|
| Linguaggio e framework | Dart (SDK 3.13 o successivo), Flutter (canale stable, 3.47) | Un solo codice per Android, iOS, Windows, macOS e Linux |
| Regole degli scacchi | [dartchess](https://pub.dev/packages/dartchess) | Generazione delle mosse legali, notazione SAN, scacco, matto, stallo, materiale insufficiente |
| Salvataggio impostazioni | [shared_preferences](https://pub.dev/packages/shared_preferences) | Memorizzazione locale delle impostazioni |
| Audio | [audioplayers](https://pub.dev/packages/audioplayers) | Riproduzione dei suoni |
| Scacchiera | [chessground](https://pub.dev/packages/chessground) | Disegno della scacchiera, trascinamento e tocco, animazioni, evidenziazioni, scelta della promozione |
| Motore | [multistockfish](https://pub.dev/packages/multistockfish) (Stockfish 19 nativo) | Avversario computer su Android e iOS, in isolate separati; su Windows e Linux si usa lo Stockfish installato |
| File locali | [path_provider](https://pub.dev/packages/path_provider) | Cartella dati dell'app per i salvataggi |
| Condivisione | [share_plus](https://pub.dev/packages/share_plus) | Menu di condivisione del sistema per il PGN |
| Promemoria | [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications) e [timezone](https://pub.dev/packages/timezone) | Notifiche locali programmate del promemoria giornaliero |
| Codici QR | [qr](https://pub.dev/packages/qr) e [flutter_zxing](https://pub.dev/packages/flutter_zxing) (zxing-cpp) | Generazione dei QR in Dart e lettura con la fotocamera, tutto sul dispositivo (vedi scambio-qr.md) |
| Foto | [image_picker](https://pub.dev/packages/image_picker) | Foto propria per l'avatar e lo sfondo, foto della scacchiera fisica |
| Cifratura e firme | [cryptography](https://pub.dev/packages/cryptography), [crypto](https://pub.dev/packages/crypto), [bip340](https://pub.dev/packages/bip340) | Invito firmato e messaggi cifrati della partita tra due telefoni (vedi multigiocatore.md) |
| Collegamenti locali | [bonsoir](https://pub.dev/packages/bonsoir), [bluetooth_low_energy](https://pub.dev/packages/bluetooth_low_energy) | Ricerca sulla rete locale e Bluetooth per la partita tra due telefoni |
| Attività in secondo piano | [workmanager](https://pub.dev/packages/workmanager) | Controllo del turno nella partita a distanza |

La licenza di ogni dipendenza è in [dipendenze-e-licenze.md](dipendenze-e-licenze.md).

La piattaforma web non è supportata: `dartchess` usa interi a 64 bit (bitboard) che il compilatore JavaScript di Flutter non può rappresentare.

## Struttura delle cartelle

```
lib/
  main.dart               Avvio dell'app, tema chiaro e scuro
  l10n/                   Testi tradotti, un .arb per funzione e lingua (vedi localizzazione.md)
  home/                   Barra in basso (Home, Puzzle, Impara, Tu), Home a dashboard, schede Impara e Tu (vedi home.md)
  game/
    chess_game.dart       Stato della partita, senza dipendenze dall'interfaccia
    variant.dart          Varianti e posizioni iniziali Chess960 (vedi regole-di-gioco.md)
    material.dart         Pezzi catturati e vantaggio di materiale
    clock.dart            Cadenze e orologio a due lati
    sounds.dart           Scelta e riproduzione di suoni e vibrazione
    move_label.dart       Numerazione delle mosse nella lista
    move_input.dart       Lettura di una mossa scritta (SAN inglese o italiana, UCI)
    move_speech.dart      Frase da annunciare al lettore di schermo per ogni mossa
    board_swipe.dart      Scorrimento orizzontale sulla scacchiera per rivedere le mosse
    tap_assist.dart       Correzione del tocco caduto sul bordo di una casa
    board_drawing.dart    Frecce e cerchi disegnati con pressione prolungata o tasto destro
    custom_clock_dialog.dart  Scelta di una cadenza libera con incremento, ritardo e seconda fase
    game_page.dart        Schermata di gioco
    challenge.dart        Partita già impostata da un'altra schermata (guardiani, tornei)
    opponent_picker.dart  Scelta di avversario, colore e livello
  engine/                 Avversario computer e bot (vedi avversario-computer.md, bot.md)
  coach/                  Allenatore in partita e suggerimenti in parole (vedi allenatore.md)
  review/                 Revisione della partita (vedi revisione-partita.md)
  analysis/               Analisi libera della posizione, freccia della minaccia (vedi analisi.md)
  editor/                 Editor di posizione e FEN (vedi editor-posizione.md)
  progress/               Gamification: XP, livelli, serie, traguardi (vedi gamification.md)
  archive/                Archivio delle partite e PGN (vedi archivio.md)
  exchange/               Scambio di partite tra telefoni con il QR (vedi scambio-qr.md)
  backup/                 Backup e ripristino dei dati (vedi backup.md)
  path/                   Percorso a tappe con stelle (vedi percorso.md)
  stats/                  Statistiche, rating locale e La tua settimana (vedi statistiche.md, ritratto-settimana.md)
  minigames/              Minigiochi di allenamento (vedi minigiochi.md)
  tournament/             Tornei offline contro bot (vedi tornei.md)
  physical/               Orologio e registro per la scacchiera fisica (vedi scacchiera-fisica.md)
  kids/                   Stelle, fiamma e giudizi senza numeri del profilo bambino (vedi profilo-bambino.md)
  reminders/              Promemoria giornaliero con notifiche locali (vedi gamification.md)
  multiplayer/            Partita tra due telefoni su più canali (vedi multigiocatore.md)
  storage/                File JSON locali con versione e scrittura atomica
  settings/
    settings.dart         Impostazioni, valori predefiniti e salvataggio locale
    settings_page.dart    Menu delle impostazioni: una voce per sezione (Profilo, Stile, Scacchiera, Partita, Accessibilità, Bambino)
    section_pages.dart    Una pagina per sezione; la sezione Stile è in style/
    app_language.dart     Lingua dell'app: sistema, italiano, inglese
    board_frame.dart      Coordinate fuori dalla scacchiera e sfondo
    board_marks.dart      Frecce e cerchi sulla scacchiera, con contrasto minimo
    notation.dart         Notazione delle mosse: figurine, italiana, inglese
    settings_widgets.dart Anteprima, gallerie di temi e pezzi, scelte a chip, volume
    settings_labels.dart  Nomi tradotti di temi, pezzi, notazioni e animazioni
    board_preview.dart    Anteprima della scacchiera nelle Impostazioni
    color_blind.dart      Colori per daltonici (Okabe-Ito)
    adult_gate.dart       Domanda per l'adulto del profilo bambino
  puzzles/                Puzzle: modello, punteggio, schermate (vedi puzzle.md)
  openings/               Aperture: libro, nome in partita, Esplora aperture, repertorio (vedi aperture.md)
  badges/                 Badge e libri delle aperture (vedi badge.md)
  bot_gallery/            Galleria dei bot e opzioni della partita (vedi bot.md)
  story/                  Storia a capitoli con lezioni, custodi e guardiani (vedi storia.md)
  style/                  Schermata Stile: scacchiera, pezzi, sfondo, suoni (vedi stile.md)
  summary/                Riepilogo settimanale (vedi riepilogo-settimanale.md)
  masters/                Partite dei grandi maestri e «Indovina la mossa» (vedi grandi-maestri.md)
  endgames/               Allenatore dei finali (vedi finali.md)
  tablebase/              Finali perfetti con tabelle generate sul telefono (vedi finali-perfetti.md)
  share/                  Esportazione della posizione come immagine (vedi esporta-immagine.md)
  theme/                  Tema Rokko, chiaro e scuro (vedi interfaccia.md)
  training/               Scacchiera per esercizi condivisa
assets/
  puzzles/puzzles.csv     Puzzle inclusi (dataset CC0 di Lichess)
  openings/               Nomi delle aperture (openings.tsv, CC0) e statistiche delle mosse (opening_stats.tsv)
  boards/ pieces/         Sfondi della scacchiera e set di pezzi
  sounds/                 Suoni dell'app (WAV), generati da tool/generate_sounds.py
  icon/                   Icona e schermata di avvio, generate da tool/generate_icons.py (vedi identita-visiva.md)
tool/
  datasets/               Script che generano i dataset in assets/
  verifica.sh             Controlli veloci prima del push (vedi convenzioni-git.md)
  check_*.dart            Controlli di rami, commit, documentazione, licenze, copertura, dimensione e prestazioni
test/                     Test unitari e di widget, una cartella per area di lib/ (vedi sviluppo.md)
integration_test/         Test end-to-end sull'app reale, un file per area
docs/                     Questa documentazione (mappa del codice in mappa-del-codice.md)
android/ ios/ linux/ macos/ windows/
                          Progetti nativi generati da Flutter
.github/workflows/        CI, convenzioni, sicurezza, dataset, rilascio dell'APK e altri controlli (vedi sviluppo.md)
```

## Componenti

### `ChessGame` (`lib/game/chess_game.dart`)

Modello della partita, in Dart puro e quindi testabile senza interfaccia.

- Conserva la posizione iniziale e la lista delle mosse giocate (`PlayedMove`: mossa, notazione SAN, posizione risultante).
- `play(move)` accetta solo mosse legali e rifiuta qualsiasi mossa a partita conclusa.
- `undo()` revoca l'abbandono o la patta concordata, se presenti; altrimenti annulla l'ultima mossa.
- `agreeDraw()` chiude la partita con una patta concordata.
- `resign(side)` registra l'abbandono del lato indicato.
- `ChessGame.replay(initial, moves)` ricostruisce una partita già giocata (import PGN) senza fermarsi a ripetizioni o 50 mosse non reclamate.
- `endReason` e `outcome` descrivono come e con quale risultato è finita la partita.

`dartchess` non rileva da sola la triplice ripetizione né la regola delle 50 mosse, perché richiedono la cronologia della partita: `ChessGame` le calcola a partire dalla lista delle posizioni. I dettagli sono in [regole-di-gioco.md](regole-di-gioco.md).

### `MaterialBalance` (`lib/game/material.dart`)

Calcola da una partita i pezzi catturati da ciascun lato, ripercorrendo le mosse (comprese le prese en passant), e la differenza di materiale presente sulla scacchiera. È Dart puro e si testa senza interfaccia.

### Orologio (`lib/game/clock.dart`)

`TimeControl` descrive una cadenza (minuti, incremento e ritardo, semplice o di Bronstein; l'etichetta è `10+5`, con il ritardo `10+0/d5` o `10+0/b5`; una seconda fase facoltativa, `phaseMoves` e `phaseMinutes`, si scrive in coda: `90+30@40:30` aggiunge 30 minuti a chi completa la sua quarantesima mossa). Il numero di mosse non è nell'orologio ma viene dalla partita (`switchAfterMove(moves:)` e `remainingAfterMove(side, moves:)` ricevono quelle di chi muove, questa compresa), così annullare una mossa toglie anche il tempo aggiunto. Con il ritardo semplice il tempo parte dopo i secondi di ritardo e un'interruzione non lo rinnova; con Bronstein, a fine mossa, si restituisce il tempo usato fino al ritardo. `showCustomClockDialog` (`custom_clock_dialog.dart`) chiede una cadenza libera: 1–180 minuti, 0–120 secondi di incremento, 0–60 di ritardo e, se si vuole, una seconda fase da 5 a 100 mosse con 1–180 minuti aggiunti (mosse e minuti vanno insieme); la stessa finestra serve alla scacchiera fisica. Gli inviti di gioco accettano solo cadenze senza ritardo e senza fasi, e il PGN non riporta `TimeControl` per quelle con ritardo; con la fase scrive la forma della specifica, `40/5400+30:1800+30`. `ChessClock` tiene il tempo residuo dei due lati e fa scorrere solo quello del lato attivo; l'ora corrente è iniettabile per i test. Offre istantanee e ripristino, usate da `GamePage` per annullare le mosse. `GamePage` aggiorna la visualizzazione ogni 100 ms ridisegnando solo gli orologi, registra il tempo scaduto con `ChessGame.flag` e ferma l'orologio a fine partita.

### Suoni (`lib/game/sounds.dart`)

`soundForLastMove` sceglie l'effetto dell'ultima mossa a partire dalla posizione precedente, in Dart puro. `SoundPlayer` riproduce l'effetto con un lettore a bassa latenza per suono e, se attiva, la vibrazione tramite `HapticFeedback`; un errore di riproduzione non interrompe la partita.

### Mossa scritta e annunci (`lib/game/move_input.dart`, `move_speech.dart`)

`parseMoveInput` prova il testo come UCI, poi come SAN inglese e come SAN con le iniziali italiane (R re, D donna, T torre, A alfiere, C cavallo) tramite `Position.parseSan` di dartchess. Se le due letture danno mosse legali diverse restituisce `MoveInputAmbiguous`. `describeSan` trasforma la SAN in una frase italiana che `GamePage` invia con `SemanticsService.sendAnnouncement` dopo ogni mossa.

### Impostazioni (`lib/settings/`)

`AppSettings` è un valore immutabile con tutte le opzioni e la loro traduzione in `ChessboardSettings` di chessground. `SettingsController` lo carica all'avvio da `shared_preferences`, lo espone come `ValueNotifier` e lo salva a ogni modifica; valori salvati sconosciuti o di tipo errato tornano al predefinito, e se la memoria locale non è disponibile l'app parte con i valori predefiniti. Vengono scritti solo i valori modificati. L'app carica le impostazioni prima di mostrare la partita, e `GamePage` si ridisegna quando cambiano. `SettingsScope` (un `InheritedNotifier` messo nel `builder` di `MaterialApp`, sopra il Navigator) espone le stesse impostazioni a tutte le pagine: `TrainingBoard` lo legge, così puzzle, esploratore e repertorio seguono le scelte dell'utente senza ricevere il controller come parametro. Fuori dall'app, per esempio nei test, usa i valori predefiniti.

### `GamePage` (`lib/game/game_page.dart`)

Schermata di gioco. Possiede un `ChessGame` e un `ChessboardController` di chessground.

Flusso di una mossa:

1. Il giocatore muove un pezzo sulla scacchiera; chessground consente solo le mosse legali che riceve in `GameData.validMoves` e gestisce da sé la scelta del pezzo di promozione.
2. chessground chiama `onMove` con la mossa completa.
3. `GamePage` passa la mossa a `ChessGame.play`.
4. Se la mossa è accettata, `GamePage` costruisce un nuovo `GameData` (posizione, ultima mossa, re sotto scacco, mosse legali) e aggiorna il controller; poi ridisegna lista mosse, stato e comandi.

A partita conclusa `GameData.playerSide` vale `PlayerSide.none`, quindi la scacchiera non accetta altre mosse.

Contro il computer, dopo la mossa del giocatore `GamePage` chiede a `ComputerPlayer` la risposta per la posizione FEN corrente e la passa a `ChessGame.play`; mentre il computer pensa la scacchiera è bloccata. I dettagli sono in [avversario-computer.md](avversario-computer.md).

A fine partita (per qualunque causa: matto, abbandono, patta, tempo) `GamePage` passa il `SavedGame` a `onSave` (archivio) e, se la partita vale, l'attività di `progress/game_activity.dart` a `onActivity` (progressi); i due procedono in modo indipendente e un errore dell'uno non ferma l'altro. `HomeShell` fornisce entrambi.

Con `GamePage.challenge` (`GameChallenge`: titolo, livello del motore, colore, `startMoves`, `line`) la partita contro il computer parte da sola alla prima apertura, senza Nuova né editor; Annulla c'è sempre (guardiano, torneo, aperture); la partita conta comunque per esito e punti. Con `startMoves` la partita parte dopo quelle mosse e con `line` segnala l'uscita dalla linea del repertorio (apertura giocata, vedi [aperture.md](aperture.md)). A fine partita `onFinished` comunica esito e mosse a chi l'ha lanciata (guardiani del percorso e tornei, vedi [percorso.md](percorso.md) e [tornei.md](tornei.md)).

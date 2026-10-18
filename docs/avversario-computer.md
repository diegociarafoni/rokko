# Avversario computer

La partita contro il computer usa **Stockfish** (la versione 19 inclusa nell'app su Android e iOS, quella installata su Windows e Linux), eseguito interamente sul dispositivo:
nessuna connessione, nessun server, nessun dato che esce dal telefono.

## Come si gioca

1. Toccare **Nuova**.
2. Il foglio **Nuova partita** parte con **Inizia partita**, che avvia subito la partita contro il computer del tuo livello (l'avversario adattivo, con il tempo scelto nel menu in alto); **Scegli il bot** apre la galleria e **Gioca con l'istruttore** apre la stessa scelta di colore e livello del menu Aperture e avvia la partita con l'istruttore che commenta l'apertura (vedi [aperture.md](aperture.md)). Sotto «Altre modalità», **Partita personalizzata** ha tutto in una pagina: per giocare in due si sceglie **Due giocatori**; contro il computer in cima alla lista dei bot c'è **Adattivo**, il motore senza volto, seguito dai bot con personalità (vedi [bot.md](bot.md)). I livelli fissi sono i bot, uno per gradino, da sbloccare battendo il precedente; non c'è un cursore del livello.
3. Scegliere il colore: Bianco, Nero o a caso. La scacchiera si orienta dal lato del giocatore.
4. Toccare **Adattivo** per giocare col motore al livello scelto dall'app (vedi [Avversario adattivo](#avversario-adattivo)), oppure un bot.
5. Toccare la cadenza, "Senza tempo" o una cadenza (vedi [interfaccia.md](interfaccia.md)): la partita inizia. Se il giocatore ha il Nero, il computer muove per primo.

Contro il computer e i bot si può giocare anche una variante (Chess960, Re della collina, Tre scacchi, vedi [Varianti](#varianti)); i nomi dei giocatori compaiono nel pannello solo scegliendo **Due giocatori**. Una posizione creata con l'editor (vedi [editor-posizione.md](editor-posizione.md)) si può giocare anche contro il computer o un bot (RF-24): aprire l'editor durante una partita la sostituisce con la posizione scelta, in due o contro il computer a seconda della scelta nel pannello **Gioca questa posizione**.

Durante la riflessione del computer la scacchiera è bloccata e compare la scritta
"Il computer sta pensando…".

- **Annulla** ritira la mossa del giocatore e la risposta del computer, così il turno
  torna al giocatore. Se il computer sta ancora pensando, la ricerca viene interrotta.
- **Abbandona** fa abbandonare il giocatore, non il computer.
- **Annulla** dopo un abbandono o una patta concordata riapre la partita senza togliere mosse.
- **Patta**: il computer valuta la posizione attuale a piena forza e accetta solo se si giudica in svantaggio di almeno mezzo pedone (50 centipedoni); altrimenti rifiuta (requisito RF-25). Durante la valutazione compare "Il computer valuta la patta…" e la scacchiera è bloccata.
- Se il motore non risponde, o propone una mossa che le regole rifiutano, compare il messaggio "Il computer non risponde." con il pulsante **Riprova**, sopra la barra dei comandi; il motore viene riavviato alla richiesta successiva. Il messaggio sparisce con una nuova partita o un annullamento.
- La patta si può offrire solo nel proprio turno.
- La rotazione automatica della scacchiera è disattivata contro il computer.
- Il pulsante **Allenatore** giudica ogni mossa e avvisa degli errori; il pulsante **Suggerisci** (lampadina) indica il pezzo da muovere e poi la mossa, anche con l'allenatore spento (vedi [allenatore.md](allenatore.md)). Dal menu ⋮ si aprono **Analisi della posizione** e **Revisione della partita** (vedi [analisi.md](analisi.md) e [revisione-partita.md](revisione-partita.md)) e lo scambio della partita con **Passa con QR** e **Ricevi con QR** (vedi [scambio-qr.md](scambio-qr.md)).
- Con l'orologio, il tempo del computer scorre mentre pensa e riceve l'incremento come il giocatore; se il tempo scade durante la riflessione la ricerca viene interrotta. **Annulla** ripristina gli orologi di entrambe le mosse ritirate, anche dopo un tempo scaduto alla prima mossa.
- Con l'orologio il computer non pensa più di un trentesimo del tempo residuo più tre quarti dell'incremento (minimo 50 ms): riflessione e ritardo artificiale del livello vengono ridotti di conseguenza (`EngineLevel.withinClock`), così anche il livello 8 non perde per tempo nelle cadenze brevi.
- Mentre è aperta una finestra (nuova partita, abbandono, patta) o l'app è in background, orologio e computer sono fermi: la ricerca in corso viene interrotta, il suo tempo restituito al computer, e riparte alla chiusura o al ritorno nell'app.
- Mentre il computer valuta una patta l'orologio è fermo, perché il giocatore non può muovere. Se il motore non risponde, l'orologio del computer resta fermo, senza il tempo della ricerca fallita, fino a **Riprova**.

## Piattaforme

| Piattaforma | Contro il computer |
|---|---|
| Android | Sì |
| iOS | Sì |
| Windows, Linux | Sì, se Stockfish è installato; altrimenti l'opzione appare disattivata |
| macOS | Non ancora: la sandbox dell'app impedisce di avviare un programma esterno |

Su Android e iOS il motore arriva dal plugin [multistockfish](https://github.com/lichess-org/dart-multistockfish)
(Stockfish 19 incluso nell'app). Su Windows e Linux l'app usa lo Stockfish installato,
avviato come processo esterno (`ProcessTransport`): lo cerca in `STOCKFISH_PATH`, poi nelle
cartelle di `PATH` (`stockfish.exe` su Windows), poi in `/usr/games`, `/usr/bin`, `/usr/local/bin`
e `/opt/homebrew/bin`. Per installarlo: `sudo apt install stockfish` su Debian e Ubuntu; su
Windows scaricare l'eseguibile da [stockfishchess.org](https://stockfishchess.org/download/) e
rinominarlo `stockfish.exe` in una cartella di `PATH`, oppure indicarne il percorso completo nella
variabile `STOCKFISH_PATH`. La ricerca avviene una volta all'avvio dell'app: dopo l'installazione
va riavviata. Se il processo termina durante la partita compare "Il computer non risponde." e
**Riprova** lo riavvia.

## Avversario adattivo

Con **Adattivo** scelto il livello segue i risultati del giocatore, per far vincere circa metà delle partite (requisito RF-26).

- L'app tiene una stima Elo del giocatore, che parte da 1150, l'Elo del livello predefinito.
- Il livello usato è quello con l'Elo indicativo più vicino alla stima; la riga «Adattivo» mostra "Livello N" e l'Elo indicativo.
- A fine partita (matto, abbandono, tempo, patta) la stima si aggiorna con la formula Elo: vittoria 1, patta 0,5, sconfitta 0. Il fattore K è 64 nelle prime 10 partite e 32 dopo.
- Ogni partita conta una sola volta, e solo se ha almeno una mossa ed è partita dalla posizione iniziale: le partite avviate dall'editor di posizione non cambiano la stima. **Annulla** dopo la fine della partita ripristina la stima precedente.
- Il risultato si registra alla fine: lasciare una partita a metà per aprirne un'altra non la conta.
- La stima resta tra 500 e 2900 Elo, cioè a 200 Elo dal livello più debole e da quello più forte, e l'attesa di risultato si calcola contro il livello effettivamente giocato.
- La stima è salvata sul dispositivo (chiave `adaptiveOpponent`, `lib/engine/adaptive.dart`) e non esce mai da lì.
- Le partite con il livello scelto a mano non cambiano la stima.

## Livelli

| # | Nome | Elo dichiarato | Come si ottiene |
|---|------|---------------:|-----------------|
| 1 | Principiante | 700 | profondità 4, sceglie tra 6 candidate, temperatura 320 |
| 2 | Esordiente | 900 | profondità 4, 5 candidate, temperatura 200 |
| 3 | Dilettante | 1150 | profondità 4, 4 candidate, temperatura 160 |
| 4 | Giocatore di circolo | 1400 | profondità 4, 4 candidate, temperatura 80 |
| 5 | Agonista | 1600 | limitatore Elo di Stockfish a 1600 |
| 6 | Esperto | 1850 | limitatore Elo di Stockfish a 2300 |
| 7 | Maestro | 2250 | piena forza, profondità 10 |
| 8 | Campione | 2700 | piena forza, 2 secondi a mossa |

Il livello predefinito è il 3 (`defaultEngineLevel`).

La Storia usa anche un livello 0 (`storyBeginnerLevel`, 400 Elo, profondità 2, 8 candidate e temperatura 600), che non fa parte dei livelli scelti dall'utente né dell'adattivo e non cambia `engineLevelForElo`. Lo usano Tino (solo nella Storia) e Lia (bot della scala). La sua forza non è stata misurata con `tool/calibrate_test.dart`.

### Perché i livelli bassi funzionano così

Stockfish ha un limitatore di forza (`UCI_LimitStrength` / `UCI_Elo`), ma non scende sotto i
1320 Elo: troppo per un principiante. Per i livelli 1–4 l'app chiede quindi al motore le migliori
N mosse (`MultiPV`) con la loro valutazione e ne sceglie una a caso, con probabilità

```
p(mossa) ∝ exp((valutazione_mossa − valutazione_migliore) / temperatura)
```

Con temperatura alta anche mosse sensibilmente peggiori hanno buone probabilità; con temperatura
bassa quasi sempre esce la migliore. Il risultato sono errori plausibili, come quelli di una
persona, invece di pezzi regalati a caso. Due regole fisse:

- un matto a favore non viene mai scartato;
- con temperatura 0 o una sola candidata si gioca sempre la mossa migliore.

I livelli bassi aspettano inoltre qualche centinaio di millisecondi prima di muovere, perché una
risposta istantanea risulta innaturale.

## Taratura

L'Elo dichiarato è misurato, non stimato a tavolino. `tool/calibrate_test.dart` fa giocare due livelli
tra loro (colori alternati, sei mosse iniziali a caso per variare le partite) e ricava dal punteggio
la differenza di Elo; come ancora serve Stockfish col solo limitatore (`u1600` = `UCI_Elo` 1600):

```
CAL_A=3 CAL_B=4 CAL_GAMES=16 flutter test tool/calibrate_test.dart
```

Con 16 partite l'errore è di circa ±100 Elo, quindi si leggono le tendenze, non i singoli valori.
Ultima misura, differenza Elo di B su A (tra parentesi quella dichiarata):

| Sfida | Misurata | Dichiarata |
|---|---:|---:|
| 1 → 2 | +83 | +200 |
| 1 → 3 | +406 | +450 |
| 2 → 3 | +105 | +250 |
| 2 → 4 | +482 | +500 |
| 3 → 4 | +268 | +250 |
| 3 → 5 | oltre +529 | +450 |
| 4 → 5 | +235 | +200 |
| 5 → 6 | da +150 a +300 (tre misure) | +250 |
| 6 → 7 | +406 | +400 |
| 7 → 8 | oltre +446 | +450 |

Due cose emerse dalla misura:

- A tempo breve il limitatore di Stockfish rende meno del nominale oltre i 1600 Elo: `UCI_Elo` 2000 giocava come circa 1750 e 2400 come circa 2050. Per questo il livello 6 usa `UCI_Elo` 2300 per dichiarare 1850, e il livello 7 non usa il limitatore ma una profondità fissa (10) con 3 secondi di tolleranza: la forza non dipende dalla velocità del dispositivo finché la profondità si raggiunge entro quel tempo.
- Il solo numero di candidate non basta a modulare la forza dei livelli bassi: a profondità 4 pesa soprattutto la temperatura, circa 2,5 Elo ogni centipedone.

Oltre il livello 8 non si misura: la forza piena dipende dal dispositivo, e 2700 è un valore prudente.

## Varianti

Stockfish non conosce Re della collina e Tre scacchi, e Chess960 richiede un'altra notazione dell'arrocco: per le varianti (RF-123) risponde `VariantEngine` (`lib/engine/variant_engine.dart`), un motore scritto in Dart sulle regole di `dartchess`, le stesse che arbitrano la partita. Non serve Stockfish e funziona offline come il resto.

- **Ricerca**: alfa-beta con approfondimento iterativo e ricerca di quiescenza (catture, promozioni, risposte allo scacco). A Re della collina la quiescenza prova anche le mosse del re, a Tre scacchi gli scacchi, perché lì una mossa "silenziosa" può vincere la partita.
- **Valutazione**: materiale, avanzamento dei pedoni, pezzi leggeri al centro, re al sicuro nel mediogioco e attivo nel finale. A Re della collina il re è attratto dalle case centrali, a Tre scacchi ogni scacco dato vale più del precedente. Un matto o la vittoria di variante pesano più di ogni materiale.
- **Livelli**: gli stessi otto della scala. La profondità dipende dall'Elo indicativo (1 mossa sotto 1000, 2 sotto 1500, 3 sotto 1900, 4 sotto 2300, 5 oltre) e i livelli bassi scelgono tra tutte le mosse con la stessa temperatura usata per le candidate di Stockfish (`chooseCandidate`). Il tempo di riflessione è quello del livello, con un massimo di 3 secondi e il limite dell'orologio di `withinClock`.
- **Ripetizioni**: la partita passa al motore le posizioni già comparse e la ricerca ne tiene il conto lungo la linea: una posizione già vista (la seconda comparsa, non la terza della regola, come fanno i motori per non girare a vuoto) vale patta. Così in vantaggio il computer non gira a vuoto e in svantaggio cerca la ripetizione. Vale anche la patta a 100 semimosse.
- **Interfaccia**: la ricerca gira in un isolate, quindi la scacchiera resta fluida. `stop()` scarta la risposta di una ricerca superata (annulla, nuova partita).
- **Patta**: il computer valuta la posizione con `VariantEngine.evaluate` e accetta alle stesse condizioni di RF-25.
- **Cosa non c'è**: suggerimenti, allenatore, minaccia, analisi e revisione usano Stockfish e restano solo negli scacchi classici; il libro d'apertura dei bot e le loro frasi di stile non si applicano. Una partita in variante non entra nel rating locale, nella stima adattiva, nella collezione dei bot né nei record sull'avversario più forte.

## Architettura

```
lib/engine/
  uci.dart            parsing del protocollo UCI (bestmove, info, score)
  levels.dart         definizione degli 8 livelli
  choose.dart         scelta "umana" tra le candidate
  uci_transport.dart  canale verso il motore; StockfishTransport usa multistockfish o il processo
  process_transport.dart Stockfish installato sul computer, come processo esterno
  computer_player.dart ComputerPlayer: coda delle richieste, opzioni, ricerca
  variant_engine.dart  VariantEngine: ricerca in Dart per Chess960, Re della collina, Tre scacchi
lib/game/
  opponent_picker.dart scelta di avversario, colore e livello
  game_page.dart       integrazione nella schermata di gioco
```

- `ComputerPlayer.bestMove` riceve la posizione iniziale (FEN), la cronologia delle mosse e un `EngineLevel` e restituisce un `EngineMove`
  (mossa già nel formato di dartchess, variante prevista, valutazione), oppure `null` se non
  ci sono mosse legali. Non applica la mossa: lo fa `ChessGame`, che resta l'unica fonte delle regole.
- Al motore si invia `position fen <iniziale> moves ...`: con la cronologia Stockfish riconosce le ripetizioni, come fa `ChessGame`.
- `ComputerPlayer.evaluate` valuta una posizione a piena forza (300 ms), usata per decidere sulla patta.
- Le richieste vanno in coda: il motore esegue una ricerca alla volta.
- Dopo un errore (timeout, avvio fallito) il motore viene chiuso e la richiesta successiva ne avvia uno nuovo, così una risposta tardiva non viene scambiata per quella di una nuova ricerca. `dispose()` fa fallire subito le richieste in corso.
- Le opzioni UCI del livello vengono inviate solo quando cambiano.
- `stop()` fa terminare subito la ricerca in corso e quelle già in coda (che diventano ricerche a profondità 1), senza il ritardo artificiale dei livelli bassi. La schermata di gioco scarta le risposte
  arrivate per una posizione non più attuale (dopo un annullamento o una nuova partita).
- L'arrocco viaggia come `e1g1` verso e da Stockfish e come re su torre (`e1h1`) in dartchess;
  `ComputerPlayer` converte in entrambe le direzioni.
- Su Android e iOS `Stockfish.create()` ammette un solo motore alla volta: se il precedente non ha
  ancora liberato il posto, l'avvio riprova ogni mezzo secondo per circa dieci secondi.
- Se il motore si chiude o va in errore, le richieste in corso falliscono subito invece di attendere il timeout.
- Per la scelta "umana" si usano le candidate dell'ultima iterazione completa (la profondità più alta in cui il motore ha valutato tutte le varianti), così non si confrontano valutazioni di profondità diverse.
- Passando a una partita tra due persone il motore viene chiuso, liberando memoria.
- `UciTransport` separa la logica dal motore concreto: in produzione `StockfishTransport`,
  nei test un motore finto o un processo Stockfish.

## Test

```sh
flutter test
```

- `test/engine/uci_test.dart`, `choose_test.dart`: parsing e scelta delle mosse.
- `test/engine/stockfish_location_test.dart`: ricerca di Stockfish sui computer.
- `test/engine/computer_player_test.dart`: con un motore finto e, se installato, con Stockfish
  vero (`apt install stockfish`, oppure la variabile `STOCKFISH_PATH`). Senza Stockfish i test
  d'integrazione vengono saltati; in CI Stockfish è installato, quindi girano sempre.
- `test/engine/adaptive_test.dart`, `test/adaptive_game_test.dart`: stima, livello scelto e aggiornamento a fine partita.
- `test/computer_game_test.dart`: la partita contro il computer nell'interfaccia, con un motore finto.
- `integration_test/computer_test.dart`: test end-to-end sull'app desktop contro un vero Stockfish
  (colore, livello, scacchiera bloccata, annullamento, patta), con lo Stockfish installato.

Nuove funzioni del computer si sviluppano partendo dai test, con nel nome il requisito
(vedi [sviluppo.md](sviluppo.md)).

## Requisiti coperti

| Requisito | Stato |
|---|---|
| RF-20 scelta di colore e livello | ✓ (8 livelli, Elo dichiarato 700–2700) |
| RF-21 motore in isolate separato, ritardo artificiale ai livelli bassi | ✓ |
| RF-25 patta accettata dal bot in base alla valutazione | ✓ |
| RNF-03 Stockfish nativo via FFI in isolate, 1 thread | ✓ (Android, iOS) |
| RF-22 modalità Allenamento (suggerimento, barra di valutazione) | Fatto: vedi «Allenamento e Sfida» sotto |
| RF-23 bot con personalità | ✓ (vedi [bot.md](bot.md)) |
| RF-24 partenza da una posizione personalizzata | ✓ dall'editor (vedi [editor-posizione.md](editor-posizione.md)) |
| RF-26 avversario adattivo | ✓ |

## Licenza

Stockfish è GPL-3.0, come l'app. Il permesso aggiuntivo per la pubblicazione sugli store è
descritto in [NOTICE.md](../NOTICE.md).

## Allenamento e Sfida

Contro un bot o il computer si gioca in due modalità, scelte con l'interruttore **Allenamento** nelle opzioni della partita (galleria dei bot, «Opzioni» → Aiuti) e ricordate (`AppSettings.trainingMode`, spento di default):

| | Allenamento | Sfida |
| --- | --- | --- |
| Annullamento | sì | sì (la partita conta comunque per Elo e vittorie) |
| Suggerimento, minacce, allenatore | sì | no |
| Barra di valutazione | sì, se accesa nelle impostazioni | no |
| Elo | non conta | conta |
| Vittorie nei progressi e nei badge | non contano: la partita vale come giocata (XP di partecipazione) | contano |

Il profilo bambino gioca sempre in Allenamento e non mostra l'interruttore. La modalità vale per la partita in corso (`_training` in `GamePage`); riprendendo una partita salvata vale l'ultima scelta fatta. Tra due persone e nelle sfide del percorso non cambia nulla.

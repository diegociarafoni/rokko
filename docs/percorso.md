# Percorso a tappe

Requisito RG-03: una mappa di capitoli e tappe con valutazione da 1 a 3 stelle. Il codice è in `lib/path/`. La trama a capitoli che lo usa è descritta in [storia.md](storia.md).

**Navigazione**: la Storia è l'unico percorso di apprendimento raggiungibile dall'interfaccia. `PathPage` (il sentiero descritto in «Aspetto») è nel codice e nei test ma non è collegata a nessuna schermata. Stelle e salvataggi (`path.json`) alimentano la Storia. Ogni capitolo del percorso ha il suo capitolo nella Storia (un test lo controlla), compresi «La strategia» e «La scuola di Capablanca».

## Capitoli

| Capitolo | Tappe |
|---|---|
| Come si muovono i pezzi (il «Capitolo 0») | La scacchiera e le case, torre, alfiere, donna, re, cavallo, pedone (con promozione), il pedone che cattura, quale pezzo muovere; nessun guardiano |
| Catturare e difendere | Catturare (con il valore dei pezzi), i pezzi in presa, difendere un pezzo |
| Le regole | Lo scacco, via dallo scacco (spostare il re, catturare, mettere in mezzo), l'arrocco, la presa al varco, la promozione, lo stallo |
| Matti elementari | Matto in una (primi esempi), il matto del corridoio (con la donna e attirando via il difensore), donna e re, le torri a scala in due mosse, matti famosi (Anastasia, arabo, Boden, Damiano), matto in due (anche il matto affogato con sacrificio di donna), altri matti famosi (spalline, Greco, Cozio, Opera), guardiano (400 Elo) |
| Tattiche | Pezzi indifesi, forchetta (cavallo, pedone, forchetta reale, donna), inchiodatura, infilata (torre e alfiere), attacco di scoperta, scacco doppio, elimina il difensore, il pezzo sovraccarico, l'adescamento, l'interferenza, la mossa intermedia, il pezzo intrappolato, batteria e raggi X, guardiano (800) |
| Finali | Matto di donna, matto di torre, la regola del quadrato, l'opposizione, le case chiave, la triangolazione, lo sfondamento, la torre dietro il pedone passato, l'alfiere sbagliato (difendere nell'angolo e impedirlo), guardiano (1000) |
| La strategia | Il valore dei pezzi cambia (e si cambia quando si è in vantaggio), torri sulle colonne aperte, la casa forte del cavallo, alfiere buono e alfiere cattivo, il pedone passato, pezzi attivi, guardiano (1100) |
| Aperture | Il centro, lo sviluppo (con la Partita Italiana), l'arrocco, il matto del barbiere (darlo e pararlo), guardiano (1200) |
| La scuola di Capablanca | Chi promuove per primo (contare le mosse nelle corse di pedoni), l'opposizione a distanza (per attaccare e per difendersi), le combinazioni di Capablanca (sacrifici contro il re e doppi attacchi), le regole dell'apertura (prima i cavalli, non muovere due volte lo stesso pezzo, le trappole di chi le dimentica), guardiano (1300) |

Ogni lezione ha 4 esercizi progressivi (il test ne ammette da 4 a 5), dal più facile al più difficile: prima l'esempio evidente, poi versioni con distrazioni, nascoste o difese; l'ultimo è spesso una piccola sfida, indicata con «Sfida». Ogni tappa è breve (2-5 minuti) e si apre con una spiegazione di due o tre frasi, scritta in modo semplice perché valga anche per il profilo bambino; la scacchiera accetta mosse solo dopo «Inizia». I contenuti sono originali (posizioni costruite per il progetto) e in italiano e inglese, tranne il capitolo «La scuola di Capablanca», che adatta posizioni di un libro in pubblico dominio (vedi Fonti di ispirazione). Le posizioni tattiche sono state analizzate con Stockfish: la mossa richiesta è la migliore e la risposta automatica del Nero è una difesa ragionevole, non un errore che regala il punto. Per i finali la verifica è a profondità 22 o più: la mossa richiesta è la migliore oppure tutte le mosse equivalenti sono tra le alternative, e la risposta del Nero è la migliore del motore o una equivalente. Negli esercizi di strategia l'obiettivo è trovare la mossa del piano: sono accettate tutte le mosse che seguono l'indicazione e che il motore valuta entro mezzo pedone dalla migliore. Il test automatico controlla legalità e matti in ogni ramo delle alternative accettate, non la qualità delle risposte: chi aggiunge esercizi tattici ripete questa verifica.

Una tappa si apre quando la lezione precedente è completata, oppure quando è già completata una lezione che viene dopo: così le lezioni aggiunte con un aggiornamento restano aperte per chi era già più avanti e non richiudono le tappe successive. Senza tappe saltate equivale a «tutte le lezioni precedenti completate». I guardiani sono sfide facoltative e non bloccano il percorso. Il pulsante «Continua» (nel sentiero) porta alla prima lezione non completata (anche una appena aggiunta) e, finite le lezioni, al primo guardiano non battuto. Un doppio tocco non apre due tappe.

## Aspetto

La schermata è un sentiero (`path_page.dart`, `path_widgets.dart`). In cima una scheda riassume le stelle totali con una barra di avanzamento e dice qual è la prossima tappa; ogni capitolo ha numero, titolo, stelle e una barra propria, con la spunta a capitolo concluso. Le tappe serpeggiano e un tratto di sentiero le unisce: pieno fin dove il percorso è aperto, tratteggiato verso le tappe bloccate.

Lo stato di una tappa non dipende dal solo colore:

| Stato | Segno |
|---|---|
| Bloccata | lucchetto, contorno tratteggiato, testo «bloccata» per i lettori di schermo con il suggerimento di completare la lezione precedente |
| Da fare | icona della lezione, tre stelle vuote |
| Corrente (quella di «Continua») | anello nel colore d'azione e la scritta «Sei qui» |
| Completata | spunta e stelle piene (da una a tre) |
| Guardiano | esagono con lo scudo e la scritta «guardiano», al posto del cerchio delle lezioni |

I bersagli tattili sono almeno 48 dp (`RokkoTokens.minTouch`), il testo cresce fino al 130% senza overflow, e colori e stelline vengono dai token del tema. I testi fissi sono in `lib/l10n/<lingua>/path.arb`; titoli, introduzioni e consegne di capitoli, tappe ed esercizi sono in `assets/content/<lingua>/path.json` (italiano e inglese), con id `<tappa>.title`, `<tappa>.intro` e `<tappa>.ex<N>` (N da 1) e `<capitolo>.title`.

## Esercizi

**A stelle** (`StarsExercise`): un pezzo bianco da solo su scacchiera vuota raccoglie le stelle, in qualunque ordine. Il minimo di mosse si calcola da solo con una ricerca in ampiezza sugli stati (casa, pezzo, stelle raccolte), quindi i contenuti non contengono numeri da tenere aggiornati. Stelle: 3 al minimo, 2 con al massimo due mosse in più, 1 altrimenti. Il pedone avanza di uno o di due dalla seconda traversa e in ottava diventa donna (la scacchiera promuove a donna senza chiedere).

**A linea** (`LineExercise`): una posizione FEN e una sequenza di passi. I passi pari sono del giocatore, con alternative separate da `|`; i dispari sono le risposte automatiche dell'avversario. Le mosse si confrontano in SAN, così l'arrocco è riconosciuto sia come re su g1 sia come re sulla torre. Con l'obiettivo "matto" all'ultimo passo vale qualunque mossa che dà matto, con l'obiettivo "scacco" qualunque scacco dato con lo stesso pezzo della soluzione. Con l'obiettivo «difendi» (`LineGoal.defend`, con la casa del pezzo in `guard`) vale ogni mossa dopo cui quel pezzo è difeso da un altro pezzo del giocatore: le difese equivalenti non vanno elencate a mano. Se una mossa sbagliata mette in salvo il pezzo senza difenderlo (lo sposta o prende l'attaccante), il messaggio è «Così il pezzo è salvo, ma qui l'esercizio chiede di difenderlo» (`pathStageSaved`) invece di «Non è la mossa giusta». Una mossa sbagliata non viene giocata e conta come errore. Stelle: 3 senza errori, 2 con uno, 1 con più errori.

La tappa vale la media delle stelle dei suoi esercizi, arrotondata per difetto.

**Ripresa e «Ricomincia»**: gli esercizi risolti di una tappa lasciata a metà si salvano in `path.json` (chiave `resume`, le stelle per tappa) a ogni esercizio, e `openStage` (`stage_page.dart`) li ripassa a `StagePage`: chi esce o chiude l'app riparte dall'esercizio in corso, senza rivedere la spiegazione, e anche la schermata «Tappa completata» resta raggiungibile dopo l'uscita. Il salvataggio finale (`complete`) cancella la ripresa. L'esercizio in corso si rifà da capo con l'icona «Ricomincia» nella barra o con il pulsante sotto «Avanti», utile quando il pezzo non può più raccogliere le stelle (per esempio un pedone che ha superato un bersaglio) o la posizione è andata fuori strada.

## Bot guardiano

L'ultima tappa dei capitoli dai Matti elementari in poi è una partita contro un bot dell'Elo indicato. `PathPage` riceve `playGuardian`, che gioca la partita e restituisce le stelle (o `null` se non vinta). Dalla Storia, dove gira il motore (Android e iOS, o Windows e Linux con Stockfish installato; non macOS), toccare il guardiano apre una partita già impostata: l'utente ha il Bianco, il livello è quello del motore con l'Elo più vicino a quello del guardiano (`engineLevelForElo`), senza orologio, e non si possono ricominciare, usare l'editor, il coach o l'analisi; **Annulla** (`GameChallenge.allowUndo`) e **Suggerisci** (`GameChallenge.allowHints`) funzionano, perché il guardiano è allenamento, mentre nelle partite dei tornei resta disattivato. Uscire a partita in corso chiede conferma e conta come persa; dopo una sconfitta si riprova riaprendo la tappa. L'Elo dei guardiani cresce capitolo dopo capitolo: 400 (Matti elementari), 800 (Tattiche), 1000 (Finali), 1100 (La strategia), 1200 (Aperture), 1300 (La scuola di Capablanca). Il livello del motore invece non scende mai ma può ripetersi tra capitoli vicini. I livelli del motore partono da 700 Elo, quindi i guardiani da 400 e 800 giocano al livello 1 (700), quello da 1000 al livello 2 (900), quelli da 1100 e 1200 al livello 3 (1150) e quello da 1300 al livello 4 (1400): il livello effettivo è scritto sotto il titolo. Altrove la tappa mostra un avviso.

Stelle (`challengeStars`): vittoria in al massimo 40 mosse 3 stelle, fino a 60 mosse 2, oltre 1; patta e sconfitta non ne danno e si può riprovare. La partita registra XP e archivio come le altre (vedi [gamification.md](gamification.md)). Il percorso non si completa col guardiano: le stelle restano le migliori ottenute.

## Verifica dei contenuti

`test/path/curriculum_test.dart` controlla ogni esercizio: mosse della soluzione e risposte legali, risposte forzate (unica mossa legale) negli esercizi di matto, ogni prima mossa che forza il matto accettata tra le alternative, l'elenco esatto delle mosse accettate in «Difendere un pezzo» e che negli esercizi «difendi» non ci siano catture gratuite (pezzo preso senza ripresa, o ripreso ma di valore non inferiore alla preda), ultima mossa che dà matto (o scacco, per l'obiettivo scacco), una spiegazione e da 4 a 5 esercizi per ogni lezione, nessuna partenza ripetuta in tutto il percorso (stesso FEN, o stesso pezzo sulla stessa casa negli esercizi a stelle), stelle raggiungibili e mai sulla casa di partenza. Controlla anche l'ordine dei capitoli e delle tappe, che l'Elo dei guardiani cresca da un capitolo all'altro e che il loro livello del motore (`engineLevelForElo`) non scenda mai. Un errore in un FEN o in una soluzione fa fallire la CI.

## Salvataggio e XP

`PathController` salva le stelle migliori per tappa in `path.json` (tramite `JsonFile`, vedi [archivio.md](archivio.md)) e registra `LessonCompleted` nella gamification, con la durata, la prima volta che una lezione è completata (rigiocarla migliora le stelle ma non dà altro XP; le partite dei guardiani registrano l'XP da sé), se riceve `recordActivity`:

```dart
final progress = await ProgressController.open();
final path = await PathController.open(recordActivity: progress.record);
```

## Componenti

| File | Ruolo |
|---|---|
| `exercise.dart` | Esercizi a stelle e a linea, loro svolgimento e stelle |
| `curriculum.dart` | Capitoli, tappe ed esercizi (posizioni, mosse, stelle); i testi si leggono dal contenuto `path` |
| `path_progress.dart` | Stelle per tappa, sblocco, tappa successiva |
| `path_controller.dart` | Caricamento, salvataggio, registrazione dell'XP |
| `path_page.dart` | Mappa del percorso (non collegata all'interfaccia) |
| `path_widgets.dart` | Elementi grafici del sentiero: tappe, capitoli, scheda di riepilogo |
| `stage_page.dart` | Svolgimento di una tappa sulla scacchiera |

Le stelle di tappe rimosse in un aggiornamento dei contenuti restano nel file ma non contano nel totale.

La schermata della tappa usa la scacchiera a tutta larghezza in verticale e affianca testo e comandi in orizzontale; il pannello sotto la scacchiera scorre se lo spazio non basta.

## Fonti di ispirazione

- La scelta dei temi tattici e dei matti si ispira al capitolo sulle tattiche del Wikibooks «Chess» (CC BY-SA 4.0, https://en.wikibooks.org/wiki/Chess/Tactics) e alla voce di Wikipedia «Checkmate pattern» (CC BY-SA 4.0).
- La scelta dei temi di strategia si ispira al capitolo «Strategy» del libro «Chess» di Wikibooks (CC BY-SA 4.0, https://en.wikibooks.org/wiki/Chess/Strategy), quella dei temi dei finali alla voce «Chess endgame» di Wikipedia (CC BY-SA 4.0).
- L'indice delle tattiche di «Predator at the Chessboard» (W. Farnsworth, CC BY-NC-ND, http://www.chesstactics.org/) è stato consultato solo come elenco di temi, senza prenderne testi o posizioni.
- Il capitolo «La scuola di Capablanca» viene dalla Parte I di «Chess Fundamentals», J. R. Capablanca, 1921, pubblico dominio, Project Gutenberg #33870. Sono adattate le posizioni degli esempi 11, 12 e 14 (combinazioni del mediogioco), 19, 20 e 21 (trappole d'apertura), 25 (chi promuove per primo), 27 e 28 (opposizione a distanza); l'esercizio del cavallo in f6 riprende l'idea dell'esempio 13 in una posizione semplificata. Le idee delle spiegazioni (contare le mosse, l'opposizione, prima i cavalli e poi gli alfieri, non muovere due volte lo stesso pezzo) sono quelle del libro; i testi in italiano sono riscritti e ogni posizione è stata verificata con Stockfish.
- Tutte le altre posizioni e i testi sono originali.

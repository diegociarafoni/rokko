# Aperture

Riconoscimento delle aperture, mosse di libro, Esplora aperture e repertorio con ripetizione dilazionata, partita da un'apertura, albero delle proprie aperture (requisiti RF-90, RF-91, RF-92, RF-93, RF-94, RF-96).

## Dati

`assets/openings/openings.tsv` deriva dal dataset [chess-openings](https://github.com/lichess-org/chess-openings) di Lichess (CC0): 3.865 righe `eco\tname\tuci`, circa 380 KB. Lo script `tool/datasets/build_openings.py` scarica i cinque file del dataset e converte le mosse da SAN a UCI, così l'app non deve interpretare la notazione algebrica all'avvio. Viene rigenerato dallo stesso workflow dei puzzle (`docs/puzzle.md`).

`assets/openings/opening_stats.tsv` contiene le statistiche per mossa (vedi [Statistiche delle partite](#statistiche-delle-partite)); deriva dal [database delle partite di Lichess](https://database.lichess.org/) (CC0).

I nomi del dataset sono in inglese; l'app li mostra in italiano (vedi [Nomi in italiano](#nomi-in-italiano)) e conserva l'originale nelle partite salvate e nei file esportati.

## Libro delle aperture

`lib/openings/opening_book.dart` costruisce all'avvio, in un isolate separato, un grafo di posizioni:

- ogni posizione è identificata dall'EPD (i primi quattro campi della FEN: pezzi, tratto, arrocchi, en passant), quindi le trasposizioni portano allo stesso nome;
- ogni posizione con nome conserva codice ECO e nome; se più righe arrivano alla stessa posizione vale la prima;
- ogni mossa tra due posizioni del libro conta quante righe del dataset passano di lì.

Il libro si carica una volta sola (`openingBook()` in `opening_assets.dart`), in anticipo all'apertura dell'app; se il caricamento fallisce si riprova alla richiesta successiva. Il file è letto ignorando i fine riga Windows (`\r\n`).

### Riconoscimento in partita (RF-90)

`OpeningBook.classify(mosse)`, o `classifyPositions(posizioni)` quando le posizioni sono già calcolate come nella schermata di gioco, ripercorre la partita all'indietro e restituisce l'ultima posizione con nome, come suggerisce il dataset. Nella schermata di gioco il titolo "Rokko" diventa il nome italiano dell'apertura (senza codice ECO, che resta solo nell'etichetta per i lettori di schermo, e su due righe se lungo) appena la partita entra nel libro (widget `OpeningName`), con un'etichetta per i lettori di schermo ("Apertura: ..."). Il widget riceve le posizioni della partita a partire da quella iniziale, quindi una partita da posizione personalizzata non viene confusa con una dalla posizione standard.

### Mosse di libro (RF-91)

`OpeningBook.bookPlies(mosse)` restituisce quante semimosse iniziali restano nel libro; dopo la prima uscita non si rientra. La revisione della partita lo usa per marcare le mosse "Libro" (RF-91, vedi [revisione-partita.md](revisione-partita.md)).

### Nomi in italiano

Il dataset pubblico è in inglese, quindi i nomi si traducono al momento di mostrarli, senza toccare il file: `localOpeningName` (`lib/openings/opening_names.dart`) usa le tabelle di `assets/content/<lingua>/opening_names.json` con le famiglie del libro ("Sicilian Defense" diventa "Difesa siciliana", "Queen's Gambit Declined" diventa "Gambetto di donna rifiutato") e un piccolo glossario per le varianti. Il sostantivo (variante, attacco, gambetto, difesa, sistema, linea) viene messo davanti e gli aggettivi si accordano ("Open Variation" diventa "variante aperta"). I nomi propri restano invariati ("variante Najdorf") e ciò che non si sa tradurre resta in inglese, così l'informazione non si perde mai. Un test passa tutti i nomi del libro e controlla che non restino in inglese le parole del glossario e i sostantivi che reggono il nome. La traduzione vale per il titolo della partita, Esplora aperture, il nome proposto per il repertorio e le aperture delle statistiche e della scheda «La tua settimana»; le partite salvate conservano il nome inglese.

La notazione delle mosse resta quella inglese (Nf3, Bb5) come nel resto dell'app.

### Statistiche delle partite

`assets/openings/opening_stats.tsv` dice, per le posizioni più giocate, quante partite hanno proseguito con ciascuna mossa e come sono finite. Un file di testo `chiave\tmosse`: la chiave è l'hash FNV-1a a 64 bit di pezzi, tratto e arrocchi (l'en passant è escluso perché i due lati lo scrivono in modo diverso), le mosse sono `san:partite:vittorie-bianco:vittorie-nero` dalla più giocata; le patte sono il resto. Le trasposizioni condividono la riga.

`tool/datasets/build_opening_stats.py` lo genera da un mese del database di Lichess: legge solo l'inizio del dump (è in ordine cronologico), tiene le partite di giocatori da almeno 1800 Elo con cadenza da blitz in su, conta le mosse nelle prime 16 semimosse, scarta le mosse con meno di 100 partite e tiene al massimo 8 risposte per posizione. Lo lancia il workflow Dataset (che gira sulle PR che toccano `tool/datasets/`) insieme agli altri dataset; i test dello script sono in `tool/datasets/test_build_opening_stats.py` e il controllo del file incluso in `test/openings/opening_stats_asset_test.dart`. Il file pesa poche centinaia di KB, compresso ancora meno nel pacchetto.

`lib/openings/opening_stats.dart` lo legge (`OpeningStats`, caricato in un isolate come il libro con `openingStats()`); `MoveStat.percents` dà tre percentuali intere che sommano sempre 100.

### Esplora aperture (RF-92)

Dalla pagina **Aperture** (si apre da Impara e dalla Home), **Esplora aperture** mostra la posizione corrente con il nome dell'apertura, la sequenza delle mosse e le risposte possibili. Per ogni mossa indica la notazione scelta, quante partite l'hanno giocata (con il separatore delle migliaia della lingua), la barra bianco / patta / nero con le percentuali e, sotto, il nome dell'apertura raggiunta. La riga si legge per esteso ai lettori di schermo («e4: 1.000 partite, bianco 45%, patta 20%, nero 35%»); la barra è decorativa. I colori dei segmenti sono fissi, con testo a contrasto su ognuno.

Dove le statistiche non arrivano (posizioni rare o a più di 16 semimosse) la schermata ricade sul libro dei nomi: mostra le continuazioni con la quota delle varianti con nome che proseguono così, senza barra. Se anche il libro finisce lo dice («Fuori dal libro delle aperture»). Se il file delle statistiche non si legge si usa solo il libro. Si può muovere anche fuori dal libro.

Sotto la scacchiera quattro comandi: **Ruota scacchiera**, **Ricomincia** (torna alla posizione iniziale), **Indietro** (toglie l'ultima mossa) e **Avanti** (rifà le mosse tolte, anche tutte dopo Ricomincia; una mossa diversa le dimentica). Le statistiche sono quelle del database pubblico e non comprendono le partite dell'utente: queste restano in [Le tue aperture](#le-tue-aperture-rf-96), raggiungibile dalla stessa posizione, così le percentuali non si falsano.

### Repertorio (RF-93)

Ogni colore ha il suo repertorio: un elenco di linee con nome (es. "Italiana: 1. e4 e5 2. Nf3 Nc6 3. Bc4"). Le linee si aggiungono:

- da Esplora aperture, con il pulsante **Aggiungi al repertorio**: nome proposto dall'apertura raggiunta, colore proposto in base a chi ha giocato l'ultima mossa;
- incollando un PGN nella schermata del repertorio: ogni variante diventa una linea, un ramo con una mossa illegale si interrompe lì e conserva la parte legale prima; un PGN con intestazione FEN diversa dalla posizione iniziale non è una linea e si ignora. Nel repertorio salvato una linea con mosse illegali o malformate si scarta da sola, le altre restano.

Ogni linea si cancella con l'icona **Elimina la linea**.

Una linea è rifiutata se in una posizione già presente il repertorio prevede un'altra mossa per il proprio colore: il ripasso deve avere una sola risposta giusta. Le linee possono condividere l'inizio; le trasposizioni sono riconosciute tramite l'EPD.

**Carte.** Ogni mossa del proprio colore è una carta, identificata da colore ed EPD della posizione in cui va giocata, quindi due linee che passano dalla stessa posizione condividono la carta. Le carte usano la stessa coda di Leitner degli errori dei puzzle (`ReviewQueue`, intervalli di 1, 3, 7, 14 e 30 giorni) con due differenze: le carte nuove sono subito da ripassare e una carta arrivata all'ultimo intervallo resta nella coda ogni 30 giorni invece di uscirne.

**Ripasso.** "Ripassa N mosse" sceglie la prima linea con carte in scadenza e la gioca dall'inizio: le mosse dell'avversario e quelle del giocatore non in scadenza si giocano da sole. Per una carta nuova una freccia mostra la mossa da giocare; una mossa diversa da quella del repertorio rimanda la carta al primo intervallo e mostra la freccia, poi si deve giocare la mossa giusta per proseguire. Una carta nuova giocata correttamente passa al primo intervallo.

Linee e carte sono salvate in `training.json`, lo stesso file dei puzzle (`JsonFileStore`, istanza unica per evitare scritture concorrenti), con le chiavi `openings.repertoire.v1` e `openings.repertoire.review.v1`.

### Gioca un'apertura (RF-94)

Una partita contro il computer che parte da un'apertura, in due modi:

- **dall'explorer**, con l'icona **Gioca questa apertura** (attiva dopo almeno una mossa): le mosse scelte sono già giocate e si prosegue dalla posizione raggiunta. Il colore proposto è quello che deve muovere;
- **da una linea del repertorio**, con l'icona **Gioca la linea**: si parte dalla posizione iniziale con il colore del repertorio (non modificabile) e l'utente gioca le proprie mosse. Se il computer esce dalla linea compare «Il computer è uscito dalla linea del repertorio.»; se ne esce l'utente, «Sei uscito dalla linea del repertorio.». Ogni segnalazione compare una volta; se con **Annulla** si rientra nella linea, una nuova uscita viene segnalata di nuovo.

Una finestra chiede colore (nell'explorer) e livello del computer. È una `GameChallenge` (vedi [architettura.md](architettura.md)) con le mosse iniziali (`startMoves`) e la linea da seguire (`line`); la partita viene salvata in archivio come le altre. Senza motore (Windows e Linux senza Stockfish) le icone non compaiono.

### Gioca con l'istruttore

Dalla pagina Aperture la voce **Gioca con l'istruttore** (solo con il motore) chiede colore e livello e avvia una partita dalla posizione iniziale in cui l'allenatore resta acceso (avvisi sugli errori, **Suggerisci**, **Minaccia**) e commenta l'apertura nel fumetto sopra la scacchiera (`SpeechStrip`, vedi [interfaccia.md](interfaccia.md)). È una `GameChallenge` con `instructor: true`; la logica è in `lib/coach/opening_coach.dart` (`openingNote`), pura e testata.

- Finché la partita è nel libro dice il nome dell'apertura raggiunta e le tre mosse più giocate dalla posizione con la percentuale, ricavate dalle statistiche per mossa (senza statistiche, dalle continuazioni del libro). Una posizione conta come nota se è nel libro o ha mosse nelle statistiche;
- alla prima mossa che porta fuori dal libro avvisa chi è uscito e, per l'utente, elenca le mosse che si giocavano. Da lì in poi tace sull'apertura e resta l'allenatore;
- l'icona **Apri nell'esploratore** nella barra del titolo apre l'esploratore sulla posizione corrente.

In modalità zen e nelle varianti il commento non compare. I testi sono in `lib/l10n/<lingua>/coach.arb` (prefisso `instructor`).

### Le tue aperture (RF-96)

`lib/openings/personal_tree.dart` costruisce un albero delle aperture dalle partite dell'archivio locale (vedi [archivio.md](archivio.md)): per ogni posizione, quali mosse sono state giocate, quante volte e con che risultato, visto dal giocatore (vinte, patte, perse). Le posizioni si confrontano per EPD come nel libro, quindi le trasposizioni condividono le statistiche; una mossa conta una sola volta per partita.

Entrano solo le partite concluse con un colore dell'utente (contro il computer o un bot), con regole standard e dalla posizione iniziale. Restano fuori le partite in corso, quelle importate o tra due persone sullo stesso dispositivo, le varianti, le posizioni personalizzate e i PGN senza mosse. Di ogni posizione si contano le mosse di entrambi i colori, così si vedono anche le risposte più frequenti degli avversari.

La schermata `PersonalExplorerPage` ha la scacchiera con le mosse giocate dalla posizione corrente, ordinate per frequenza, con numero di partite, barra dei risultati (decorativa, esclusa dai lettori di schermo) e riepilogo `V · P · S` letto per esteso («3 vinte, 1 patte, 2 perse»). Si tocca una mossa o la si gioca sulla scacchiera per scendere nell'albero; **Indietro** e **Inizio** tornano sui propri passi. Due filtri restringono le partite: colore (Entrambi, Bianco, Nero; scegliere un colore orienta anche la scacchiera) e avversario (nomi dell'archivio, senza doppioni). Il titolo mostra il nome dell'apertura dal libro. Senza partite utili, o con filtri che non ne lasciano, o fuori dall'albero, un messaggio lo dice.

Il collegamento con l'explorer del libro è nei due sensi, sempre sulla stessa posizione: dalla pagina Aperture la voce **Le tue aperture** apre l'albero, e le icone **Apri nell'explorer delle aperture** (nell'albero) e **Le tue partite da questa posizione** (nell'explorer) passano dall'uno all'altro portando con sé le mosse scelte. I testi sono nei file `.arb` (prefisso `personal`).

## Componenti

| File | Ruolo |
|---|---|
| `lib/openings/opening_book.dart` | Grafo delle posizioni, riconoscimento, mosse di libro, continuazioni |
| `lib/openings/opening_assets.dart` | Caricamento del dataset e delle statistiche inclusi |
| `lib/openings/opening_name.dart` | Nome dell'apertura per la schermata di gioco |
| `lib/openings/opening_stats.dart` | Statistiche per mossa: lettura, chiave della posizione, percentuali |
| `lib/openings/explorer_page.dart` | Esplora aperture con barre dei risultati e comandi |
| `lib/coach/opening_coach.dart` | Nota dell'istruttore: apertura, mosse più giocate, uscita dal libro |
| `lib/openings/personal_tree.dart` | Albero delle proprie aperture dall'archivio, con filtri |
| `lib/openings/personal_explorer_page.dart` | Schermata Le tue aperture |
| `lib/openings/opening_names.dart` | Nomi delle aperture nella lingua attiva |
| `assets/content/it/opening_names.json` | Famiglie e glossario italiani |
| `lib/openings/openings_hub_page.dart` | Pagina Aperture |
| `lib/openings/repertoire.dart` | Linee, carte, ripasso, import PGN |
| `lib/openings/repertoire_page.dart` | Linee di un colore, import PGN |
| `lib/openings/repertoire_drill_page.dart` | Ripasso sulla scacchiera |
| `lib/openings/opening_game.dart` | Richiesta di partita da un'apertura, uscita dalla linea |
| `lib/openings/opening_game_dialog.dart` | Scelta di colore e livello |

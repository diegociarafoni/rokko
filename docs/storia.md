# Percorso a storia

Requisito RG-13: una trama a capitoli sopra il [percorso a tappe](percorso.md). Il codice è in `lib/story/`. Si apre dalla Home (scheda in evidenza «Continua la Storia» e voce **Storia** del gruppo Impara) e dalla scheda Impara, ed è l'unico percorso di apprendimento dell'interfaccia: «Continua da dove eri» della scheda Tu porta qui (prossima tappa: `nextStoryStage`), e le stelle già ottenute nel [percorso](percorso.md) contano subito.

## Come funziona

La storia accompagna il giocatore dal villaggio ai piedi della Rocca fino alla corona e oltre, verso la pianura dei piani e l'accademia del maestro. Ogni capitolo ha un racconto breve, un elenco di passi da fare nell'ordine e un epilogo che compare a capitolo concluso. Il capitolo successivo si apre quando il precedente è concluso. Non ci sono vite, penalità né tempo: una sfida persa si riprova quando si vuole.

| Capitolo | Lezioni e guardiano (percorso) | Puzzle | Sfida finale |
|---|---|---|---|
| Il sentiero dei primi passi («Capitolo 0») | Come si muovono i pezzi | 3 matti in una, scelti tra i più facili | Tino (400 Elo) |
| Il villaggio dei pezzi | Catturare e difendere | 3 pezzi in presa | Pino |
| Le porte della città | Le regole | 3 promozioni | Chiara |
| La torre del re | Matti elementari, guardiano | 3 matti sulla traversa | Rocco |
| Il bosco delle trappole | Tattiche, guardiano | 4 forchette | Marta |
| Il castello dei finali | Finali, guardiano | 3 finali di pedoni | Duilio |
| La corona | Aperture, guardiano | 3 aperture | Elena |
| La pianura dei piani | La strategia, guardiano | 3 pedoni avanzati | Massimo |
| L'accademia del maestro | La scuola di Capablanca, guardiano | 3 finali di torri | Stella |

I bot sono quelli della scala (vedi [bot.md](bot.md)) in ordine di forza crescente; Tino, il custode del Capitolo 0, gioca solo nella Storia (`storyOnlyBots`), al livello 0 (400 Elo, fuori dai livelli scelti dall'utente): la sfida usa il loro livello del motore, senza orologio e con **Annulla** e **Suggerisci** (come il guardiano). Lo stile e il libro d'aperture del bot non sono applicati alla sfida.

## Passi

Dentro un capitolo ogni passo si apre quando quelli prima sono fatti:

1. **Lezioni**: tutte le lezioni del capitolo corrispondente del percorso (il guardiano è escluso). Si apre la prima non ancora completata.
2. **Puzzle**: risolvere al primo tentativo il numero indicato di puzzle del tema. `StoryPuzzleFeed` propone puzzle del tema finché l'obiettivo non è raggiunto; i puzzle si registrano come gli altri (punteggio e XP). Chi esce prima conserva quelli già risolti.
3. **Guardiano** (dove il capitolo del percorso ce l'ha): è la stessa partita del percorso, con le stesse stelle; battuto lì, conta anche qui.
4. **Sfida finale**: battere il bot del capitolo. Uscire a partita in corso vale una sconfitta.

Un passo già fatto non si riapre (lezioni, puzzle e partite restano raggiungibili dal resto dell'app). I passi che richiedono il motore (guardiano e sfida) mostrano un avviso dove Stockfish non c'è, come nel percorso. **Continua** apre il primo passo da fare del capitolo corrente. È un pulsante in una barra fissa sotto l'elenco (non flottante), così non copre mai i capitoli, anche col testo ingrandito.

## Aspetto

In cima una scheda mostra i capitoli conclusi con una barra e, sotto, la **mappa del viaggio** (`JourneyMap`, `lib/story/journey_map.dart`): i nove luoghi della Storia su un sentiero a serpentina, tre per riga (le righe dispari si percorrono da destra), ciascuno con il nome del capitolo. Un luogo concluso ha la spunta, quello dove ci si è fermati ha la torre-mascotte con il bordo nel colore d'azione (è il «riprendi da dove eri»: il pulsante **Continua** sotto la lista apre il suo primo passo) e gli altri il lucchetto; il sentiero è pieno fino all'ultimo capitolo concluso e tratteggiato oltre. Un tocco su un luogo porta la lista al suo capitolo (senza scorrimento animato con «Riduci movimento»); i lettori di schermo sentono nome e stato. La mappa non ha cifre, quindi vale anche per il profilo bambino. I capitoli sono lungo un binario verticale: ogni capitolo ha un badge con un anello di avanzamento (passi fatti su passi totali), il numero, la spunta a capitolo concluso o il lucchetto se è chiuso. Il capitolo corrente ha il bordo nel colore d'azione e la scritta «In corso»; quelli chiusi hanno il contorno tratteggiato e il testo che dice come aprirli. Lezioni e puzzle mostrano una barra con il conteggio, i passi fatti hanno la spunta e quelli bloccati il lucchetto, oltre al testo letto dai lettori di schermo. I testi sono in `story.arb` (in tutte le lingue); il titolo della mappa è in `story_map.arb`.

## Il bivio

Prima del primo puzzle di un capitolo il passo dei puzzle offre due vie (`StoryChapter.puzzleTheme` e `forkTheme`): due chip con il nome dei temi, per esempio «Forchetta» o «Pin». Il conteggio non cambia, cambiano i puzzle proposti. La scelta si salva in `story.json` (`fork`, `StoryState.themeFor`) e si può cambiare finché non si è risolto un puzzle; dopo, la via resta quella (`StoryController.chooseFork` lo rifiuta). Senza scelta vale il tema di base. Alla lettura si ignorano capitoli e temi che non sono quelli del capitolo.

| Capitolo | Via di base | Via alternativa |
|---|---|---|
| Il sentiero dei primi passi | Matto in 1 | Finali |
| Il villaggio dei pezzi | Pezzi in presa | Forchetta |
| Le porte della città | Promozione | Finali di pedoni |
| La torre del re | Matto di corridoio | Matto in 2 |
| Il bosco delle trappole | Forchetta | Inchiodatura |
| Il castello dei finali | Finali di pedoni | Finali di torri |
| La corona | Aperture | Mediogioco |
| La pianura dei piani | Pedone avanzato | Mossa tranquilla |
| L'accademia del maestro | Finali di torri | Finali di alfiere |

## Ricompense

Concludere un capitolo (battuto il suo bot) vale 30 XP e sblocca, al secondo, al quinto e al nono capitolo, le scacchiere Villaggio, Torre e Corona e, al quarto e al settimo, i pezzi Pirouetti e Letter (`StoryRequirement`, vedi [gamification.md](gamification.md#ricompense-estetiche-rg-06)). Chi non vuole giocare per sbloccare usa «Sblocca tutto».

## Aiuto quando ci si blocca

Dopo due puzzle sbagliati di fila (`StoryPuzzleFeed.helping`) un avviso dice che si passa a un puzzle più facile e ricorda il pulsante **Indizio**; i puzzle successivi hanno un punteggio di 300 punti sotto il livello del capitolo (mai sotto 400) finché non se ne risolve uno, poi si torna alla difficoltà normale. L'avviso compare una sola volta per serie di errori (`onHelp`, testo `storyHelpEasier`).

## Foglio di passaggio

Quando un passo si conclude (lezioni, puzzle, guardiano o sfida), la schermata mostra un foglio dal basso che celebra il risultato e dice cosa viene dopo: dalle lezioni ai puzzle, dai puzzle alla sfida con il custode del capitolo (o al guardiano, dove c'è), e a capitolo concluso l'epilogo con l'apertura del capitolo successivo (o la fine della storia). L'icona compare con un breve rimbalzo, fermo se le animazioni sono disattivate. Il pulsante principale apre subito il passo successivo, «Più tardi» chiude il foglio. Una sfida persa resta un avviso, perché non c'è nulla da celebrare. Il foglio legge lo stato dopo il passo e lo confronta con quello di prima. I testi sono `storyPassage*` in `story.arb`; in test `StoryPage.playLesson` sostituisce la schermata della lezione.

## Stato e salvataggio

Chi ha già battuto un bot o risolto dei puzzle in un capitolo successivo trova concluso anche il Capitolo 0 (`StoryProgress.isChapterDone`), così l'aggiunta del capitolo non toglie nulla a chi era più avanti. «Continua da dove eri» nella scheda Tu propone la prima lezione, o il guardiano, ancora da fare nei capitoli della storia (`nextStoryStage`), anche se la storia è già oltre. Lo stato deriva dal percorso: le lezioni e i guardiani completati contano così come sono, comprese le lezioni aggiunte con un aggiornamento dei contenuti (per questo la storia non elenca le singole lezioni, ma il capitolo del percorso). Salva da sé, in `story.json` (`StoryController`, con `JsonFile`), solo i puzzle risolti per capitolo e i capitoli con il bot battuto. Capitoli sconosciuti o valori illeggibili sono ignorati alla lettura.

## Testi e accessibilità

I testi (racconto, passi, avvisi) sono nei file `.arb` in italiano e in inglese; `story_l10n.dart` li associa ai capitoli. Il nome dei bot resta quello della scala. Ogni capitolo e ogni passo è un nodo per i lettori di schermo, con titolo e stato («da fare», «fatto», «bloccato»); l'avatar del bot è escluso dalla lettura.

## I custodi

Ogni capitolo ha il suo custode, il bot del capitolo, che accompagna il giocatore con battute brevi nel suo stile (`GuardianMoment`, chiavi `storyGuardian<Capitolo><Momento>` nei file `.arb`, in italiano e in inglese, senza cifre per il profilo bambino). Compaiono in sette punti:

- **Benvenuto**: nella scheda del capitolo aperto, con l'avatar «saluto» (`GuardianSays`).
- **Puzzle**: a ogni puzzle concluso un avviso breve non bloccante con l'avatar «contento» o «incoraggiante» e la battuta di esito (`StoryPuzzleFeed.onOutcome`, mostrato da `HomeShell`).
- **Lezioni concluse**: nel foglio di passaggio dopo le lezioni, con l'avatar «contento» e la battuta `LessonDone`.
- **Apertura della sfida**: aprendo la sfida dalla mappa (senza passare dal foglio di passaggio) compare un foglio dedicato con l'avatar «sfida», la presentazione del bot e la sua battuta; «Sfida {nome}» avvia la partita, «Più tardi» la rimanda. Non compare dopo il foglio di passaggio, che l'ha già annunciata (`announced`), né quando la sfida è già vinta.
- **Prima della sfida**: nel foglio di passaggio dopo i puzzle l'avatar «sfida» prende il posto dell'icona e dice la sua battuta.
- **Sfida vinta**: nel foglio di chiusura del capitolo l'avatar «stupito» dice la battuta di resa (`GuardianMoment.bossWon`).
- **Sfida persa**: l'avviso sotto «resiste ancora» riporta la battuta di incoraggiamento (`GuardianMoment.bossLost`).

Il custode è anche l'antagonista del capitolo: il carattere, lo stile di gioco e l'apertura preferita sono quelli del bot (vedi [bot.md](bot.md)) e le sue battute prima e dopo la partita sono `Boss`, `BossWon` e `BossLost`. Le battute di esito sono in `story_antagonist.arb`; come le altre, senza cifre e di genere neutro verso il giocatore.

L'avatar è decorativo (`GuardianAvatar`, escluso dalla lettura) e la battuta è letta come «{nome} dice: …». I bot senza personaggio disegnato mostrano la loro emoji. Il custode non salva nulla: dipende solo dal capitolo e dal momento.

## Come aggiungere un capitolo

I puzzle di un capitolo possono avere un tetto di difficoltà (`StoryChapter.puzzleRating`): il Capitolo 0 pesca puzzle fino a 500 punti anche se il punteggio dell'utente è più alto. Aggiungere un `StoryChapter` in `storyChapters` (capitolo del percorso, bot, tema, tema alternativo del bivio (`forkTheme`) e numero di puzzle) e le quattro stringhe `story<Id>Title`, `Intro`, `Boss` (con `{name}`), `Outro` e le sette battute del custode (`storyGuardian<Id>Welcome`, `PuzzleOk`, `PuzzleRetry`, `LessonDone`, `Boss`, `BossWon`, `BossLost`) nei file `.arb`, poi i casi in `story_l10n.dart`. I test controllano che il capitolo punti a un capitolo del percorso e a un bot esistenti, che i bot siano in ordine di forza, che il tema e il tema del bivio abbiano puzzle a sufficienza e che ogni testo esista nelle due lingue.

## Componenti

| File | Ruolo |
|---|---|
| `story.dart` | Capitoli, stato salvato e avanzamento |
| `story_controller.dart` | Caricamento e salvataggio |
| `story_feed.dart` | Puzzle del tema fino all'obiettivo |
| `story_l10n.dart` | Testi dei capitoli e battute dei custodi |
| `guardian_says.dart` | `GuardianSays`: il custode (avatar e battuta) |
| `story_page.dart` | Schermata della storia: riepilogo, binario dei capitoli, passi |

## Puzzle del capitolo: esito e uscita

A puzzle concluso il commento del custode («Bravo, l'hai visto subito!») non è più un avviso flottante, che copriva i pulsanti: entra nella scheda dell'esito, sotto punteggio e XP (`PuzzlePage.companionBuilder`). Quando i puzzle del capitolo sono finiti, al posto di «Prossimo» compare «Continua» (`PuzzlePage.continueWhenFinished`): riporta al menu della Storia, dove si apre subito il foglio «Puzzle risolti!» con «Sfida {nome}» e «Più tardi», come per le lezioni. Verificato su telefono piccolo, medio e grande, con testo al 130% e in tema scuro.

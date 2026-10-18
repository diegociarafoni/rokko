# Partita con l'allenatore

Partita con l'allenatore (requisiti RF-72…RF-75): si gioca contro il computer e, dopo ogni mossa, l'allenatore la valuta con Stockfish sul telefono, senza server.

## In partita

Nelle partite contro il computer o un bot il pannello «Partita» (pulsante «Altro») ha l'interruttore **Allenatore** (spento di default; da acceso un punto sul pulsante «Altro» e un messaggio spiegano a cosa serve). Da acceso:

- dopo ogni mossa dell'utente, e prima della risposta del computer, l'allenatore la giudica; con orologio e computer fermi durante il giudizio;
- se è un errore o un errore grave compare un riquadro con la spiegazione e due scelte: **Riprova** (la mossa viene annullata, anche per l'orologio) o **Continua** (la partita prosegue);
- nelle altre mosse il commento viene solo annunciato ai lettori di schermo;
- il giudizio della mossa compare anche sulla scacchiera come nella revisione: il simbolo (`!!`, `!`, `★`, `?!`, `?`, `??`…) con il suo colore sulla casa d'arrivo. Resta finché non muove di nuovo l'utente, sparisce se la risposta del computer occupa quella casa, se si annulla la mossa, si sfoglia la cronologia o si spegne l'allenatore;
- **Minaccia** (RF-56): con l'allenatore acceso compare il pulsante ⚠ **Minaccia**, che mostra con una freccia rossa la mossa che l'avversario giocherebbe se toccasse a lui (`CoachSession.threat`, stessa posizione con il turno passato di `threatFen`); il messaggio la dice in notazione. Non c'è sotto scacco, la freccia resta finché la posizione non cambia e sparisce sfogliando la cronologia;
- (anche con l'allenatore spento) il pulsante **Suggerisci** (lampadina) dà un suggerimento a livelli: al primo tocco evidenzia con un cerchio il pezzo da muovere («Muovi il cavallo.»), al secondo cerchia anche la casa di arrivo e mostra la freccia della mossa migliore, con una frase semplice (messaggi `coachHint…` in `coach.arb`) e il motivo quando si riconosce («Sposta il re in f1: lo togli dallo scacco.», «Sposta la torre in d5 e cattura il pedone.»). Le frasi sono generate da `lib/coach/hint_text.dart`, senza notazione algebrica. Il suggerimento sparisce appena la posizione cambia. Tenendo premuto il pulsante compare la spiegazione dei due livelli. Nel profilo bambino il pulsante si chiama **Aiuto** e la frase non nomina la casa ma rimanda al cerchio («Sposta il cavallo sul cerchio.»).

- **Spiegami perché** (RF-122): interruttore in Impostazioni (sezione Partita), spento di default e indipendente dall'allenatore. Acceso, dopo ogni mossa del computer o di un bot (non nelle sfide) compare per 8 secondi una riga su cosa la mossa fa, minaccia o prepara. Le frasi sono generate da `lib/coach/explain_why.dart` (`explainComputerMove`), nell'ordine: scacco matto, arrocco, promozione, cattura (con lo scacco eventuale), scacco, pezzo messo al sicuro, minaccia della mossa successiva, sviluppo di un cavallo o alfiere, pedone al centro, frase generica. La minaccia viene dalla stessa analisi della freccia rossa (`CoachSession.threat`): cattura di un pezzo indifeso o di valore pari o maggiore, promozione o scacco. La riga è un messaggio a comparsa, quindi letto dai lettori di schermo; i testi sono localizzati in italiano e inglese. Nel profilo bambino la minaccia di cattura non cita la casa («Minaccia di catturare la torre.»). Se il motore non risponde si usano solo le regole sulla mossa, senza la minaccia.

- **Gioca con l'istruttore**: una sfida delle aperture (vedi [aperture.md](aperture.md)) in cui l'allenatore è già acceso e, oltre ai suoi avvisi, commenta l'apertura con le mosse più giocate e avvisa quando si esce dal libro (`lib/coach/opening_coach.dart`). Qui il suggerimento resta disponibile.

Se il motore non risponde l'allenatore tace e la partita prosegue. Nella partita tra due persone il pulsante non c'è.

## `CoachSession`

| Metodo | Ruolo |
|---|---|
| `judge(posizione, mossa, {kid})` | Giudica la mossa riusando `reviewGame` e `explainMove` della revisione: restituisce classificazione, spiegazione testuale (senza numeri con `kid`, profilo bambino) e `shouldWarn` |
| `hint(posizione, livello)` | Suggerimento a livelli: `HintLevel.piece` dà solo la casa del pezzo da muovere, `HintLevel.move` anche la destinazione e la notazione |
| `hintsUsed` | Numero di suggerimenti richiesti |

## Quando avvisa

`shouldWarn` è vero per errore ed errore grave (soglia `warnFrom`, per default `MoveClass.mistake`; si può abbassare a imprecisione). Le occasioni mancate non fermano la partita: il commento resta disponibile. Le soglie di classificazione sono quelle della [revisione](revisione-partita.md).

Limite noto: la mossa è giudicata sulla sola posizione, senza cronologia, quindi ripetizione e regola delle 50 mosse non sono riconosciute e le mosse di libro non sono marcate.

## Costo

Le valutazioni sono memorizzate per posizione dentro la sessione (quelle fallite no): chiedere un suggerimento e poi giocare la mossa non analizza due volte la stessa posizione (RF-75). I suggerimenti si contano una volta per posizione.

## Suggerisci è indipendente dall'allenatore

Il pulsante **Suggerisci** c'è sempre nelle partite contro il computer o un bot, con l'allenatore acceso o spento. L'allenatore resta solo l'opzione che giudica le mosse e avvisa degli errori. Nelle sfide dei tornei, dove conta il punteggio, né l'allenatore né il suggerimento sono disponibili, salvo nella partita con l'istruttore. Le sfide di allenamento del percorso e della Storia (guardiani e custodi, `GameChallenge.allowHints`) hanno **Suggerisci** ma non l'allenatore né la barra di valutazione.

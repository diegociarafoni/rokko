# Interfaccia

L'app è progettata prima di tutto per il telefono in verticale.

## Navigazione

La barra in basso ha quattro schede: Home, Puzzle, Impara e Tu. La scacchiera non è una scheda: si apre dal grande pulsante «Nuova partita» fisso in basso nella Home, con la scelta della partita già aperta. Home e Impara sono descritte in [home.md](home.md). La scheda Tu (`lib/home/you_page.dart`, testi in `lib/l10n/<lingua>/you.arb`) mostra avatar, livello e serie, poi la scheda in evidenza «Continua da dove eri», che apre la Storia alla prossima tappa, e un solo gruppo, **I miei dati**, con intestazione letta come tale dai lettori di schermo: Profilo, Badge (vedi [badge.md](badge.md)), Statistiche, La tua settimana e Archivio. La scheda contiene solo i dati del giocatore: Storia, Finali, Grandi maestri, Tornei, Multigiocatore, Scacchiera fisica e Minigiochi si aprono dalla Home e dalla scheda Impara. «La tua settimana» è una sola voce e apre il riepilogo; gli adulti hanno a destra il pulsante «Condividi la settimana» per l'immagine. Le voci hanno un tocco di almeno 48 dp. Se i dati salvati di una sezione non si possono leggere, un messaggio lo dice e si può riprovare. Nel profilo bambino le Aperture sono nascoste e la scheda Tu mostra solo Profilo e La tua settimana (vedi [profilo-bambino.md](profilo-bambino.md)).

## Telefono in verticale

Dall'alto verso il basso:

1. **Barra del titolo** con il marchio Rokko (o il nome dell'apertura), il menu ⋮, la modalità zen e le impostazioni (con l'istruttore anche l'esploratore delle aperture); la tastiera resta in barra solo con un lettore di schermo attivo, nelle sfide e nel profilo bambino.
2. **Spazio delle mosse**: occupa lo spazio libero sopra la riga di stato. Lo schermo alto lo riempie con la lista delle mosse (l'ultima in basso, vicino alla scacchiera); quando lo spazio è poco diventa una striscia orizzontale. Contiene anche, una alla volta, le carte dei suggerimenti del primo uso e l'invito alla revisione. Finché nessuno ha mosso la lista sarebbe vuota: al suo posto, in basso contro la riga di stato, c'è la frase «Tocca un pezzo, poi la casa dove vuoi muoverlo.».
3. **Riga di stato**: chi muove, scacco, oppure risultato e motivo della fine partita.
4. **Materiale del giocatore in alto**: pezzi che ha catturato e vantaggio.
5. **Scacchiera** a tutta larghezza.
6. **Materiale del giocatore in basso**.
7. **Barra dei comandi** in basso, alla portata del pollice, con tutti i comandi della partita in vista, da almeno 48 dp: Suggerisci (contro il computer o un bot; nelle sfide solo contro i guardiani del percorso e i bot della Storia), Annulla, Gira, Nuova, Patta e Abbandona. «Nuova» apre il foglio-menu: **Inizia partita** in testa (subito, contro il computer del tuo livello, con il tempo scelto nel menu in alto), poi le voci grandi **Sfida un amico** (sullo stesso telefono o ognuno sul suo, vedi [multigiocatore.md](multigiocatore.md)), **Scegli il bot** (la galleria, con le sue Opzioni), **Gioca con l'istruttore** e **Tornei**; in fondo «Altre modalità»: **Partita personalizzata** (variante, handicap, colore, nomi e tempo), **Due giocatori sullo stesso telefono** e **Scacchiera fisica**. Tornei e Scacchiera fisica compaiono se la home li offre. Il profilo bambino ha la scelta semplice, senza menu. Il pulsante «Altro» compare solo quando serve: apre il pannello **Partita** con l'interruttore Allenatore (contro il computer) e, con l'allenatore acceso, Minaccia (vedi [allenatore.md](allenatore.md)); un punto su «Altro» dice che l'allenatore è acceso. A partita finita Patta e Abbandona, ormai inutili, lasciano il posto a **Rivincita** e **Rivedi**. Sotto i 336 dp di larghezza «Gira» passa nel pannello per non schiacciare i pulsanti. In verticale la scacchiera sta contro la barra, dove arriva il pollice, e tutto lo spazio che avanza, anche su schermi molto alti, è delle mosse e dei suggerimenti (`test/game/tall_screen_layout_test.dart`: 280x1100, 360x1000, 412x1180 e 820x1400, nessun overflow). Nel profilo bambino i pulsanti sono tre da 56 dp (Suggerisci o Gira, Annulla, Altro) e il pannello usa «Nuova partita», «Pareggio?» e «Mi arrendo» (vedi [profilo-bambino.md](profilo-bambino.md)).

Stato, righe del materiale e scacchiera stanno attaccati ai comandi; l'avanzo di altezza va allo spazio delle mosse. I messaggi a fascia compaiono sopra la scacchiera, non sopra le sue ultime traverse. La scacchiera ha come lato il minimo tra la larghezza dello schermo e l'altezza rimasta dopo striscia minima, stato, righe del materiale e comandi.

## Tablet e orizzontale

La Home usa le classi di larghezza di Material (`WindowSize` in `lib/theme/adaptive.dart`): sotto 840 dp, compresi schermo diviso e pieghevoli chiusi, resta la barra in basso; da 840 dp la barra diventa una colonna laterale (`NavigationRail`) e il contenuto si ferma a 840 dp di larghezza, centrato in alto. `test/layout/wide_screens_test.dart` apre la Home con le sue schede, le Impostazioni e la partita su tablet, desktop, schermo diviso (stretto e basso) e pieghevole aperto, e controlla che niente sfori.

Quando la larghezza supera di oltre il 20% l'altezza, la scacchiera sta a sinistra e un pannello a destra contiene, dall'alto: materiale del giocatore in alto, stato, lista delle mosse, materiale del giocatore in basso e comandi.

## Materiale catturato

Per ciascun giocatore una riga mostra le icone dei pezzi avversari catturati, dal più prezioso al pedone, seguite dal vantaggio di materiale (per esempio "+3") solo per chi è in vantaggio. Valori: pedone 1, cavallo 3, alfiere 3, torre 5, donna 9. I pezzi catturati si ricavano dalle mosse della partita: un pezzo promosso e poi catturato compare come pezzo promosso, e una promozione senza cattura non compare. Il vantaggio è invece calcolato sul materiale presente sulla scacchiera, quindi include le promozioni. Le righe seguono l'orientamento della scacchiera; se i pezzi catturati non entrano nella larghezza disponibile, la riga si riduce in scala. Per i lettori di schermo ogni riga è annunciata come frase, per esempio «Bianco: ha catturato pedone, vantaggio di 1».

## Interazione con la scacchiera

- Mossa per trascinamento oppure con due tocchi (pezzo, poi casa di arrivo).
- Puntini sulle case raggiungibili dal pezzo selezionato.
- Evidenziazione dell'ultima mossa e del re sotto scacco.
- Alla promozione compare un selettore con i quattro pezzi possibili.
- Tema Spazio e set di pezzi Classico (`cburnett`) per impostazione predefinita; si cambiano da Stile.

## Comandi

| Comando | Effetto |
|---|---|
| Altro | Apre il pannello «Partita» con Allenatore e Minaccia (e «Gira» sugli schermi stretti); non c'è dove il pannello sarebbe vuoto |
| Nuova | Apre il foglio «Nuova partita» descritto sopra: avvio rapido, amico, galleria dei bot, istruttore, tornei e, in «Altre modalità», la partita personalizzata (avversario, variante Classica, Chess960, Re della collina o Tre scacchi, handicap, nomi e cadenza; toccando la cadenza inizia la partita) |
| Annulla | Annulla l'ultima mossa, in ogni modalità (tra due persone sullo stesso telefono serve il consenso di chi non l'ha giocata); disattivato se non ci sono mosse |
| Gira | Capovolge la scacchiera |
| Patta | Chiede all'avversario se accetta la patta; a partita conclusa cede il posto a Rivincita |
| Abbandona | Chiede conferma e fa abbandonare il lato al tratto; a partita conclusa cede il posto a Rivedi |
| Rivincita | Solo a partita conclusa: riparte subito con lo stesso avversario, la stessa cadenza e la stessa variante, e contro il computer con i colori invertiti. Non c'è nelle sfide, con vantaggio (handicap) o da una posizione scelta a mano; nel profilo bambino sta nel pannello «Partita» |
| Rivedi | Solo a partita conclusa, dove c'è il motore e negli scacchi classici: apre la revisione della partita |
| Allenatore | Acceso o spento: da acceso giudica ogni mossa e avvisa degli errori con Riprova o Continua; solo contro il computer o un bot, non nelle sfide (vedi [allenatore.md](allenatore.md)) |
| Suggerisci | Primo tocco: cerchia il pezzo da muovere con una frase semplice; secondo tocco: freccia della mossa migliore e motivo; anche ad allenatore spento; nelle sfide solo contro i guardiani del percorso e i bot della Storia (`GameChallenge.allowHints`), non nei tornei |
| Menu ⋮, "Editor di posizione" e "Mossa da tastiera" | Editor e mossa scritta, spostati dalla barra del titolo; la tastiera è nel menu salvo lettore di schermo attivo |
| Menu ⋮, "Esporta come immagine" | Apre l'anteprima della posizione mostrata, da condividere come PNG; stesse esclusioni del menu QR (vedi [esporta-immagine.md](esporta-immagine.md)) |
| Menu ⋮, "Passa con QR" e "Ricevi con QR" | Passa la partita, anche in corso, a un altro telefono o la continua da un QR letto con la fotocamera; il menu c'è anche senza motore e nelle varianti, non nelle sfide contro guardiani e tornei né nel profilo bambino (vedi [scambio-qr.md](scambio-qr.md)) |
| Menu ⋮, "Analisi della posizione" | Apre l'analisi libera della posizione corrente con orologio e computer fermi (vedi [analisi.md](analisi.md)) |
| Menu ⋮, "Revisione della partita" | Apre la revisione con classificazione delle mosse e precisione (vedi [revisione-partita.md](revisione-partita.md)); il menu c'è solo dove c'è il motore e negli scacchi classici, non nelle varianti né nel profilo bambino |

**Personaggi e fumetti**: nello spazio libero sopra la scacchiera (almeno 136 dp) lo sfidante, cioè il bot, compare con il suo avatar e il suo nome; quando parla (saluto, scacco, cattura, fine partita e, una volta ogni tanto, una battuta di compagnia scelta dal suo carattere) la frase esce in un fumetto per 8 secondi, o fino a un tocco. Suggerimento, minaccia e «Spiegami perché» sono invece il fumetto dell'allenatore, il gatto astronauta. Il fumetto ha la precedenza sui suggerimenti del primo uso; in zen non c'è. Il widget è riusabile: `SpeechStrip` (`lib/game/speech_bubble.dart`) mostra un personaggio (`Speech.bot`, oppure l'allenatore se nullo) con un `Speech` che ha testo, espressione e un'icona di stato facoltativa; `SpeechBubble` è il solo fumetto, per chi disegna già il personaggio. Pensato anche per puzzle e partita con l'istruttore. Dove manca lo spazio (schermi bassi, orizzontale) i messaggi restano nella fascia in basso come prima.

**Suggerimenti al primo uso**: dopo la prima mossa di una partita, una carta alla volta spiega Suggerisci, la barra con patta e abbandono e il menu ⋮ (con «Avanti» e «Chiudi»; «Chiudi» li spegne per sempre). A fine della prima partita finita contro il motore compare l'invito «Rivedi la partita», una volta sola. Non compaiono in zen, nelle sfide e nel profilo bambino.

Nel profilo bambino riga di stato, comandi e dialoghi usano frasi brevi, e mancano il menu ⋮ e l'editor di posizione; le nuove partite non offrono varianti né cadenze Bullet e Blitz, mentre una partita già in corso continua com'è (vedi [profilo-bambino.md](profilo-bambino.md)).

## Orologio

"Nuova" apre un pannello in cui si sceglie l'avversario (vedi [avversario-computer.md](avversario-computer.md)) e, toccandola, la cadenza: "Senza tempo" oppure le cadenze predefinite, cioè Bullet (1+0, 1+1, 2+1), Blitz (3+0, 3+2, 5+0) e Rapid (10+0, 15+10, 30+0), dove il primo numero sono i minuti per giocatore e il secondo i secondi aggiunti dopo ogni mossa. **Personalizzata** apre una finestra per una cadenza libera: minuti, incremento, ritardo (semplice o Bronstein) e, se si vuole, minuti aggiunti dopo un certo numero di mosse (`showCustomClockDialog` in `lib/game/custom_clock_dialog.dart`, vedi [architettura.md](architettura.md)). Nel profilo bambino non c'è.

- Ogni orologio sta a destra della riga del materiale del rispettivo giocatore.
- Il tempo inizia a scorrere dopo la prima mossa del Bianco, per il Nero.
- L'orologio di chi ha il tratto è evidenziato; sotto i 10 secondi diventa rosso.
- Sotto i 20 secondi mostra anche i decimi.
- Si ferma mentre è aperto un dialogo (abbandono, patta, nuova partita) e quando l'app va in secondo piano, e riparte al ritorno.
- Una mossa fatta a tempo già scaduto non viene accettata.

## Nomi dei giocatori

Nella partita tra due persone il pannello "Nuova" ha due campi facoltativi, "Nome del Bianco" e "Nome del Nero" (al massimo 24 caratteri, spazi iniziali e finali ignorati), per il gioco a due sullo stesso telefono (RF-30). I nomi vengono ricordati per le partite successive. Se indicati:

- compaiono a sinistra della riga del materiale di ciascun giocatore;
- riga di stato e dialoghi di abbandono e patta li affiancano al colore, per esempio «Muove Anna (Bianco).», «Scacco. Muove Bruno (Nero).», «Scacco matto. Vince Anna (Bianco).» o «Bruno (Nero) accetta la patta?»;
- il lettore di schermo usa il nome per materiale, orologio e annuncio delle mosse («Bruno: pedone e5»).

Lasciando un campo vuoto torna il colore.

## Rivedere le mosse

Toccando una mossa nella striscia (o nella lista, in orizzontale) la scacchiera mostra la posizione dopo quella mossa, con la mossa evidenziata. La riga di stato diventa una barra con mossa precedente, mossa successiva, il testo "Posizione dopo 12... Nf6" (o "Posizione iniziale") e il pulsante "Torna alla partita".

- Durante la revisione la scacchiera non accetta mosse, le righe del materiale seguono la posizione mostrata e l'orologio continua a scorrere.
- Con una mossa in attesa di conferma la navigazione è disattivata finché non viene confermata o scartata.
- Sulla scacchiera, scorrendo il dito in orizzontale (almeno una casa e mezza, in direzione prevalentemente orizzontale) si cambia posizione: a sinistra si va avanti, a destra indietro, e oltre l'ultima mossa si torna alla partita. Il gesto vale se parte da una casa vuota o da un pezzo dell'avversario; se parte da un pezzo che si può muovere resta il trascinamento del pezzo, e con più dita insieme non scorre.
- Con una tastiera: frecce sinistra e destra per scorrere, Home per la posizione iniziale, Fine per tornare alla partita.
- Andare oltre l'ultima mossa, una nuova partita o "Annulla" riportano alla posizione corrente; durante la revisione "Annulla" non toglie mosse.
- I numeri delle mosse partono dalla posizione iniziale della partita, anche quando è importata da un FEN.

## Mossa da tastiera e lettori di schermo

L'icona della tastiera nella barra del titolo apre un campo in cui scrivere la mossa (requisito RNF-07), utile con TalkBack e VoiceOver o con una tastiera fisica. Sono accettate:

- notazione algebrica inglese (`Nf3`, `exd5`, `Qxf7#`) e italiana (`Cf3`, `Dxf7`), con R per il re in italiano e T per la torre; l'iniziale del pezzo può essere minuscola (`cf3`);
- arrocco come `O-O`, `0-0-0` o `o-o`;
- promozione con o senza `=` (`e8=Q`, `e8D`), sempre indicando il pezzo;
- coordinate UCI, anche maiuscole (`g1f3`, `e7e8q`).

Spazi, segni di scacco e annotazioni vengono ignorati. Se `R` indica sia una mossa di re (italiano) sia una di torre (inglese), il campo chiede di usare K o T. Una mossa non valida mostra un errore e lascia la tastiera aperta. La mossa passa per lo stesso percorso di quelle sulla scacchiera, quindi rispetta orologio e conferma della mossa. Il comando è disattivato a partita conclusa, durante la revisione e con una mossa in attesa di conferma.

Dopo ogni mossa il lettore di schermo annuncia una frase in italiano, per esempio «Bianco: cavallo prende f7, scacco», «Nero: pedone della colonna e prende d5» o «Nero: arrocco corto». Una mossa in attesa di conferma è annunciata come «Da confermare», e la fine della partita, anche per tempo scaduto, abbandono o patta concordata, è annunciata con il risultato.

## Impostazioni

La pagina principale è un menu di sezioni: ogni voce ha icona, nome e una riga che dice cosa contiene, ed è alta almeno 48 dp; i lettori di schermo la annunciano come pulsante. In cima c'è il campo **Cerca nelle impostazioni** (`lib/settings/settings_search.dart`): digitando, il menu lascia il posto alle singole voci che contengono tutte le parole scritte, cercate nel titolo e nella descrizione senza badare a maiuscole e accenti; ogni risultato dice in quale sezione sta e, toccato, apre quella sezione. Senza risultati compare un messaggio, e la croce svuota il campo e riporta il menu. Senza i progressi non si trovano le voci del profilo che li riguardano. L'indice (`settingsHits`) elenca le voci a mano: chi aggiunge un'impostazione a una sezione la aggiunge anche lì. Ogni sezione si apre in una pagina propria, con le sue impostazioni; sotto ogni interruttore una riga spiega cosa cambia. Le voci, nell'ordine:

| Sezione | Contenuto |
|---|---|
| Profilo e dati | Apre il profilo (avatar, foto, obiettivo giornaliero, promemoria), accende o spegne XP, serie e traguardi (non nel profilo bambino), «Sblocca tutto» e apre backup e ripristino; senza progressi resta solo il backup |
| Stile | Apre la schermata Stile (`StylePage`, vedi [stile.md](stile.md)): anteprima dal vivo e schede per scacchiera, pezzi, sfondo e suoni |
| Scacchiera | Suoni, volume, vibrazione, coordinate (anche fuori), evidenzia l'ultima mossa, mosse legali, frecce e cerchi, animazioni, notazione |
| Partita | Promuovi sempre a donna, ruota a ogni turno, modalità tavolo, «Spiegami perché» |
| Accessibilità | Aspetto dell'app (sistema, chiaro, scuro), colori per daltonici, modalità zen, conferma della mossa |
| Profilo bambino | In fondo, sotto un separatore; per uscirne serve la domanda per adulti |
| Informazioni | Ultima voce: licenza GPL-3.0 o successiva, indirizzo dei sorgenti (si copia, non si apre: l'app non usa la rete), dichiarazione di privacy, licenze di tutte le librerie (`showLicensePage`) e crediti di motore, pezzi e caratteri (`lib/about/`) |

Poche sezioni, nessuna con meno di due voci (lo controlla un test; Stile, Profilo bambino e Informazioni sono le eccezioni): una sezione per ogni cosa che l'utente cerca, non una per ogni funzione.

Le pagine che cambiano l'aspetto della scacchiera (Scacchiera e Accessibilità; Stile ha la sua) hanno in cima, fissa mentre si scorre, un'anteprima: mostra una posizione di prova con tema, pezzi, coordinate, mosse legali, ultima mossa, colori per daltonici e velocità delle animazioni correnti, e si aggiorna a ogni scelta. Toccandola si gioca la mossa di prova (l'alfiere prende in c6), con l'animazione scelta; un secondo tocco la ripristina. Il pulsante a destra del titolo (48 dp) la comprime a una riga con tema e pezzi, per lasciare spazio alle impostazioni sui telefoni piccoli. L'anteprima ha un'etichetta per i lettori di schermo.

Il codice è diviso così: `settings_page.dart` è il menu (`SettingsSection`), `section_pages.dart` ha una pagina per sezione e `settings_widgets.dart` i pezzi condivisi (anteprima, scelte a chip, volume). Una sezione nuova si aggiunge a `SettingsSection`, alle voci del menu e a una pagina in `section_pages.dart`, solo se ha almeno due voci.

**Non disponibili**: impostazioni della Home (cosa mostrare nella dashboard), dei Problemi (difficoltà, timer, feedback sugli errori) e dell'Analisi (barra di valutazione, frecce, linee del motore), «Ingrandisci i pezzi» e metodo di arrocco.

I temi e i pezzi sono gallerie di tessere: ogni tema mostra una scacchiera 4×4 con le sue case chiare e scure, ogni set il suo cavallo, con il nome sotto. La scelta attiva ha bordo marcato e segno di spunta; una tessera ancora bloccata ha il lucchetto (non solo la tinta più spenta), e toccarla dice come sbloccarla; per i lettori di schermo è «selezionato» o «bloccato» con il requisito. Il profilo bambino non cita mai il livello.

Tutti i testi e le descrizioni della pagina sono in italiano e inglese in `lib/l10n/<lingua>/settings.arb` (prefisso `settings`); i nomi dei set di pezzi sono nomi propri e restano uguali in ogni lingua, tranne «Classico». Un test (`test/settings/settings_sections_test.dart`) fallisce se in `settings_page.dart`, `section_pages.dart` o `settings_widgets.dart` compare di nuovo un testo scritto nel codice.

Si aprono dall'icona a forma di ingranaggio nella Home e nella barra del titolo della partita. Ogni modifica si applica subito e viene salvata sul dispositivo.

| Impostazione | Effetto | Predefinito |
|---|---|---|
| Lingua | Come il telefono, Italiano, English, Português o Nederlands (`AppLanguage`, in Accessibilità); vale subito per tutta l'app | Come il telefono |
| Aspetto dell'app | Sistema, Chiaro o Scuro: tema chiaro o scuro di tutta l'app, oppure lo stesso del telefono (requisito RP-02) | Sistema |
| Mostra le mosse legali | Puntini sulle case raggiungibili dal pezzo selezionato | Attiva |
| Coordinate | Lettere e numeri sui bordi della scacchiera | Attiva |
| Evidenzia l'ultima mossa | Colora la casa di partenza e quella di arrivo dell'ultima mossa, su tutte le scacchiere; spenta, il colore del tema diventa trasparente | Attiva |
| Coordinate fuori dalla scacchiera | Sposta le coordinate su una cornice attorno alla scacchiera, così non coprono i pezzi; si sceglie solo con le coordinate attive (vedi [pezzi-e-scacchiere.md](pezzi-e-scacchiere.md)) | Disattiva |
| Come muovere i pezzi | Automatico (due tocchi sul telefono, tocchi e trascinamento sugli schermi con lato corto da 600 dp), Tocchi e trascinamento, Due tocchi o Trascinamento (requisito RM-02). Nei due tocchi, un secondo tocco sul bordo di una casa (il 20% esterno) che non è una destinazione gioca la mossa verso la casa vicina, se è l'unica possibile; le promozioni restano al selettore | Automatico |
| Promuovi sempre a donna | Salta il selettore di promozione | Disattiva |
| Frecce e cerchi | Disegno di frecce e cerchi: su touch si tiene premuto un dito fermo su una casa libera (o con un pezzo avversario) e si trascina, oppure si tiene un dito su una casa vuota e si disegna con un secondo; col mouse, tasto destro. Rilasciando sulla stessa casa è un cerchio; ripetere la stessa forma la toglie, un tocco le toglie tutte, e spariscono a ogni mossa (requisito RF-05) | Attiva |
| Colore di frecce e cerchi | Verde, rosso, blu o giallo per le forme disegnate; col mouse Maiusc dà il rosso, Ctrl il blu, Alt il giallo | Verde |
| Conferma la mossa | Dopo ogni mossa mostra la posizione risultante con i pulsanti Conferma e Scarta al posto della riga di stato; la mossa conta solo dopo Conferma, e l'orologio continua a scorrere. Durante l'attesa "Annulla" equivale a Scarta, mentre Patta e Abbandona sono disattivati | Disattiva |
| Premossa | Contro il computer, mentre pensa si può già muovere: la mossa scelta viene giocata appena risponde, se è ancora legale (altrimenti è scartata, anche se nel frattempo si sfogliano le mosse); toccando una casa vuota si annulla. Un pedone che arriva in fondo promuove a donna. Non c'è con «Conferma la mossa» né nel profilo bambino (requisito RF-08) | Attiva |
| Barra di valutazione | Accanto alla scacchiera, la barra del vantaggio (la parte chiara è del Bianco) con la valutazione del motore dopo ogni mossa; nel profilo bambino senza cifre. Non c'è nelle sfide senza aiuti, nelle varianti e senza motore; capovolgendo la scacchiera il Bianco resta in basso nella barra (requisito RF-22) | Spenta |
| Schermo sempre acceso | Durante la partita il telefono non spegne lo schermo; torna normale a partita finita, uscendo dalla schermata e con l'opzione spenta (requisito RM-06, plugin `wakelock_plus`) | Attiva |
| Ruota a ogni turno | Orienta la scacchiera dal lato di chi deve muovere | Disattiva |
| Modalità zen | In partita restano solo scacchiera, mosse ed eventuale orologio (sezione sotto); si accende anche dall'icona nella barra della partita | Disattiva |
| Modalità tavolo | Capovolge i pezzi del giocatore in alto, per giocare uno di fronte all'altro con il telefono sul tavolo | Disattiva |
| Colori per daltonici | Sostituisce le evidenziazioni (ultima mossa, casa selezionata, mosse legali, premosse) con colori della palette Okabe-Ito, leggibili con deuteranopia, protanopia e tritanopia; i colori delle case restano quelli del tema. Indizi dei problemi e frecce del ripasso passano dal verde al blu, gli esiti delle coordinate da verde e rosso a blu e arancio (requisito RNF-07) | Disattiva |
| Suoni | Suoni per mossa, cattura, arrocco, scacco, promozione, fine partita e tempo sotto i 10 secondi | Attivi |
| Set di suoni | Classico, Legno o Cristallo, dalla scheda Suoni di Stile | Classico |
| Sfondo | Colore, sfumatura, spazio o una propria foto dietro la scacchiera, dalla scheda Sfondo di Stile | Standard |
| Volume | Volume dei suoni, da 0 a 100% | 100% |
| Vibrazione | Vibrazione breve a ogni mossa, più marcata per catture e fine partita | Attiva |
| Tema della scacchiera | Verde, Legno, Blu, Grigio, Arancia, Crepuscolo, Pergamena, Castello, Bosco elfico, Noce, Spazio, Retrò, Giardino, Terracotta, Marmo, Metallo, Vetro, Menta, Cipria, Ardesia; sbloccabili Sabbia, Oceano, Corallo, Notte, Oro e, con la Storia, Villaggio, Torre, Corona | Spazio |
| Pezzi | Classico, Merida, Chessnut, Fantasy, Spatial, Rokko, Pixel, Arcano, Staunton, Morbido, Stampa, Papercut, Noto; sbloccabili Celtic, Shapes, Firi, Mpchess, Kiwen-suwi, Totoy, RhosGFX e, con la Storia, Pirouetti e Letter | Classico |
| Sblocca tutto | Rende disponibili le ricompense estetiche senza sbloccarle (vedi [gamification.md](gamification.md)) | Disattiva |
| Animazioni | Nessuna, Veloce, Normale, Lenta | Normale |
| Notazione | Figurativa (♞f3), Italiana (Cf3) o Inglese (Nf3) per le mosse mostrate (vedi [notazione.md](notazione.md)) | Figurativa |
| «Spiegami perché» | Spiegazione dell'errore con l'allenatore (vedi [allenatore.md](allenatore.md)) | Disattiva |

Se il telefono chiede di ridurre le animazioni (Android «Rimuovi animazioni», iOS «Riduci movimento»), l'app lo segue da sola: i pezzi si muovono senza animazione, qualunque sia la velocità scelta, e le pagine si aprono senza transizione (su iOS e macOS resta quella di sistema, che porta il gesto per tornare indietro). Anche dialoghi e fogli compaiono subito (`motionStyle` in `lib/theme/motion.dart`, passato a ogni `showDialog` e a `showRokkoSheet`). Anche la barra di valutazione salta al nuovo valore. Il valore non si salva (`AppSettings.reduceMotion`, letto da `RokkoApp` e aggiornato quando cambia) e vale subito. Le animazioni delle singole schermate (per esempio il foglio di passaggio della Storia) lo leggono già da `MediaQuery.disableAnimationsOf`.

Tema, pezzi, coordinate, mosse legali, frecce e animazioni valgono anche per le scacchiere dei problemi, delle aperture e del repertorio, che si aggiornano subito quando cambiano. La modalità tavolo vale solo per la partita, perché negli esercizi si gioca sempre da un solo lato; anche la promozione automatica a donna vale solo per la partita, perché alcuni puzzle si risolvono promuovendo a un altro pezzo.

I set di pezzi disponibili sono solo quelli con licenza compatibile con la GPL e con la distribuzione commerciale, elencati in `CREDITS.md`: i set CC BY-NC-SA di chessground (California, Cardinal, Maestro e altri) sono esclusi, e chi li aveva scelti torna al set Classico. I temi con texture usano solo immagini nostre, mai quelle di chessground (licenza AGPL); sui temi scuri i pezzi neri hanno un alone chiaro (vedi [pezzi-e-scacchiere.md](pezzi-e-scacchiere.md)). Anche le icone dei pezzi catturati usano il set scelto.

## Modalità zen

Per giocare senza distrazioni (requisito RP-07). Si accende dalle Impostazioni o al volo dall'icona della figura in meditazione nella barra della partita; la scelta è la stessa impostazione, salvata sul dispositivo, quindi vale anche per le partite successive. Cosa cambia durante la partita:

- Scompaiono l'Elo e il livello dell'avversario, i nomi sopra e sotto la scacchiera, i pezzi catturati e il vantaggio di materiale.
- La riga di stato ("Muove il Bianco") è nascosta mentre si gioca; ricompare a partita finita, sfogliando le mosse e quando serve confermare una mossa. Chi usa un lettore di schermo continua a sentire ogni mossa annunciata.
- L'allenatore, i giudizi sulle mosse, la freccia della minaccia, «Spiegami perché», i commenti dei bot e l'avviso di uscita dal repertorio restano muti, e i loro pulsanti spariscono; il suggerimento su richiesta resta. Lo stato dell'allenatore si ritrova uscendo dallo zen.
- Niente festa a fine partita vinta.
- L'orologio resta se la partita ne ha uno, perché serve: il resto della riga dei giocatori sparisce. Senza orologio la scacchiera si ingrandisce; lo spazio della riga di stato resta riservato, così la scacchiera non cambia misura quando lo stato compare.

Sempre visibili: scacchiera, elenco delle mosse, comandi (nuova, annulla, gira, patta, abbandona) e suggerimento. Suoni, vibrazione e animazione dei pezzi seguono le loro impostazioni. Il codice è in `lib/game/game_page.dart` (`_zen`) e `lib/settings/settings.dart` (`zenMode`).

## Suoni

A ogni mossa suona un solo effetto, scelto in quest'ordine di priorità: fine partita, scacco, promozione, arrocco, cattura (anche en passant), mossa semplice. Con l'orologio, un breve segnale avvisa quando il tempo di un giocatore scende sotto i 10 secondi, una volta per partita. I suoni sono generati dallo script `tool/generate_sounds.py`.

## Puzzle

La scheda Puzzle ha il punteggio in alto, il puzzle del giorno come scheda grande e colorata, poi due gruppi: «Allenati» (allenamento, per tema, ripasso) e «Modalità a tempo» (serie e sfida a un amico). Nel profilo bambino restano le stelle e le voci semplici, senza cifre né modalità a tempo.

Nel puzzle l'obiettivo sta in una scheda sopra la scacchiera, con il colore che muove. Sotto, una fascia dice l'esito con icona, testo e colore insieme (da risolvere, giusto, errore, risolto, soluzione mostrata); è una regione viva per i lettori di schermo. I pulsanti hanno almeno 48 dp (56 nel profilo bambino). Nelle serie l'esito dell'ultimo puzzle ha icona e testo. Tutti i testi dell'interfaccia sono in `lib/l10n/<lingua>/puzzles.arb`; anche le regole delle modalità (`mode_guide.dart`) e i nomi dei temi (`themes.dart`) si leggono da lì. Golden con tema reale in `test/golden/puzzle_golden_test.dart`.

## Tasti di sistema e punti guadagnati

Su Android con la barra a tre tasti l'app disegna sotto la navigazione di sistema: il contenuto deve restare sopra. Le schede dal basso si aprono solo con `showRokkoSheet` (`lib/theme/sheets.dart`, un test vieta `showModalBottomSheet` diretto), mentre le liste con riempimento esplicito sommano l'ingombro con `context.withSystemBottom`. I golden dei puzzle includono la barra a tre tasti (`Device.apply(navBar: …)`).

Nei puzzle i punti guadagnati («+25 XP · Sfida completata…») stanno in linea sopra la scacchiera (`ProgressNote`) e non in una barra a comparsa, che coprirebbe i pulsanti; lo stesso vale per il pannello finale delle serie.

## Tema

Il tema è in `lib/theme/rokko_theme.dart` e segue lo stile spaziale della scacchiera «Spazio»: indaco `#4A4F86`, notte `#1D1F45` e viola di nebulosa `#725692`. Nel tema scuro i comandi sono lavanda (`#B9B3FF`) su fondo `#12132B`, nel chiaro indaco su fondo `#F5F3FC`; le stelline (`star`, giallo) sono un accento raro. Il verde `#769656` resta solo della scacchiera. Raggi di 12 dp (pulsanti) e 20 dp (schede, dialoghi), bersagli minimi di 48 dp (56 dp nel profilo bambino). Un test verifica il contrasto minimo 4,5:1 di pulsanti, testi e accenti in entrambi i temi. Le schermate leggono i valori con `RokkoTokens.of(context)` (`action`, `onAction`, `star`, `success`, `warning`, `boardGreen`, raggi, bersagli) e mettono il marchio nella barra del titolo con `RokkoWordmark`; non scrivono colori e misure a mano. Le icone dei comandi di partita (barra, pannello «Partita», barra del titolo) sono tutte della famiglia a contorno e stanno in `lib/theme/rokko_icons.dart` (`RokkoIcons`): una nuova icona di comando si aggiunge lì. Nelle altre schermate i comandi usano la variante `_outlined` o `_outline` dell'icona; restano piene solo le icone di stato (stella, spunta, lucchetto, corona), l'arte dei badge, l'icona selezionata della barra di navigazione e la nota presente nell'analisi. Il test `test/theme/rokko_icons_test.dart` fallisce se in `lib/` compare una delle icone piene note per i comandi.

L'app segue il tema chiaro o scuro del sistema, a meno che in Impostazioni → Accessibilità, alla voce «Aspetto dell'app», si scelga Chiaro o Scuro; la scelta vale subito per tutte le schermate. Le Impostazioni sono tradotte in italiano e inglese.

### Colori per daltonici

Per ogni tema `lib/settings/color_blind.dart` sceglie, tra blu, azzurro, giallo, arancio, vermiglio e viola della palette Okabe-Ito, la coppia di colori distinti per ultima mossa e casa selezionata. Le regole, in ordine:

1. sono esclusi i colori con tinta e saturazione troppo vicine a quelle delle case (differenza di tinta sotto 15° e di saturazione sotto 0,3), per esempio l'azzurro sul tema Oceano;
2. ogni evidenziazione deve avere, sia sulle case chiare sia sulle scure, un rapporto di contrasto WCAG almeno pari a quello dell'evidenziazione originale del tema e mai sotto 1,25, con trasparenza massima del 90%;
3. tra le coppie valide vince quella con la trasparenza più bassa, così i pezzi restano ben visibili.

I puntini delle mosse legali sono neri o bianchi, con contrasto almeno 3:1 (tranne su Notte, Castello e Retrò, vedi docs/pezzi-e-scacchiere.md); le premosse usano il primo colore della palette non preso dalle altre evidenziazioni. Lo schema è calcolato una volta per tema e riusato, così la scacchiera non ridisegna lo sfondo.

L'opzione vale per partita, problemi, aperture, repertorio, percorso e minigiochi. Restano invariati il bagliore rosso del re sotto scacco, disegnato da chessground con un colore fisso e riconoscibile anche dalla posizione sul re, e la casa gialla del quiz sul materiale, che non usa la coppia rosso-verde.

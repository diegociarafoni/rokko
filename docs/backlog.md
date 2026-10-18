# Backlog di Rokko

Documento unico di riferimento per le funzioni dell'app: sostituisce il vecchio elenco delle evolutive, il documento dei requisiti e l'analisi delle lacune. Aggiornato il 13 ottobre 2026 sul codice di `main` di `diegociarafoni/rokko`.

Gli identificativi (RF, RG, RP, RM, RNF, RV, RMP) sono quelli già usati nei nomi dei test e nei documenti di `docs/`: non vanno cambiati. Gli identificativi S e U sono le evolutive di storia e interfaccia.

## Come si legge

- **Stato**: *fatta* (nel codice e in `docs/`), *parziale* (c'è, ma manca una parte indicata), *da fare*.
- **Priorità**: P0 indispensabile, P1 alto valore, P2 evolutivo; sono quelle originali dei requisiti, e dentro una versione l'ordine delle righe è quello di lavoro. Le priorità delle voci S e U sono ancora da assegnare da Diego (proposta nella colonna versione).
- **Dimensione**: piccola (giorni), media (una o due settimane), grande (più settimane o scelta di prodotto).
- **Versione**: 0.11.0 contiene solo il multilingue. Il resto è proposto dalla 0.12.0 in poi, nell'ordine della sezione «Piano di rilascio».
- Metodo: ogni funzione nasce dai test scritti dai requisiti, poi il codice minimo, poi `docs/` (vedi `docs/sviluppo.md`).

## Principi e vincoli (RV)

Rokko è open source e gratuito. Questi vincoli valgono per ogni voce.

| ID | Vincolo | Stato | Note |
|---|---|---|---|
| RV-01 | Nessun livello a pagamento, abbonamento o acquisto: revisioni, puzzle e lezioni sono libere e senza limiti giornalieri | fatta | |
| RV-02 | Nessuna pubblicità, nessun tracciamento, nessun account obbligatorio; nessun dato lascia il dispositivo senza un'azione esplicita | fatta | |
| RV-03 | Codice sotto GPL-3.0 (o successiva); licenza e sorgenti visibili nella schermata «Informazioni» | fatta | schermata «Informazioni» presente (A-15) |
| RV-04 | Asset con licenza compatibile con la GPL, elencati con attribuzione in `CREDITS.md` e in «Informazioni» | fatta | `CREDITS.md` e `lib/about/credits.dart` |
| RV-05 | Il permesso per gli store vale solo per il codice del progetto; verifica scritta della compatibilità con la GPL del motore prima della pubblicazione su iOS | fatta | esito scritto in `docs/licenza.md`: compatibilità non dimostrata, quindi nessuna pubblicazione sull'App Store finché non c'è un parere legale (iOS non è libero da vincoli) |

## Piano di rilascio

| Versione | Tema | Contenuto |
|---|---|---|
| 0.11.0 | Multilingue | Solo la traduzione dei testi, consegnata in parte: il completamento (U4) passa alla 0.14.0 |
| 0.12.0 | Giocare meglio | Premossa, frecce e cerchi, schermo acceso, tocco, cadenze libere e ritardo, annullamento con consenso, barra di valutazione in partita, barra del titolo più semplice (U7); cadenze a più fasi (A-5), comandi di partita (U1), layout (U3) e icone (U12) passano alla 0.14.0 |
| 0.13.0 | Studiare meglio | Varianti salvate in PGN, note ovunque, mosse «Libro» nella revisione, cache persistente, precisione per fase nelle statistiche, scheda Tu e impostazioni in sezioni (U5, U6) e funzioni scopribili (U10), già consegnate; anticipati dalla 0.15.0 l'orologio nelle partite a distanza (A-26) e il profilo bambino coerente (U9) |
| 0.14.0 | Pronta per gli store | Schermata «Informazioni», dichiarazioni sulla privacy, architetture del motore, iOS e F-Droid (questi quattro: da decidere, vedi A-16…A-19), dimensione, riduzione animazioni, schermo diviso e pieghevoli, persistenza e migrazioni, avvio rapido, identità visiva e golden (U2, U8); in più layout senza spazio morto (U3), icone più curate (U12), percorso «dai miei errori» (A-27, consegnato), mappa del viaggio (S3) e pezzi sbloccabili (S5) |
| 0.15.0 | Storia, tornei e progressi | Evolutive della storia (S1, S2, S4, S6) e tornei con partite reali |
| 0.15.0 o dopo | Da decidere con Diego | Bot «ombra», lettura della posizione da fotocamera, altre varianti, widget della Home, scacchiere Bluetooth e le idee in fondo al documento |

## A. Da fare o parziali

### A.1 Partita e scacchiera

| ID | Funzione | Stato | Pri | Dim | Versione | Evidenza |
|---|---|---|---|---|---|---|
| A-1 / RF-08 | **Premossa**: muovere durante il turno dell'avversario, annullabile toccando una casa vuota, con opzione nelle impostazioni | fatta | P0 | media | 0.12.0 | `_playerSide` e `_playPremove` in `lib/game/game_page.dart`; test in `test/game/premove_test.dart` |
| A-2 / RF-05 | **Frecce e cerchi** con almeno tre colori, pressione prolungata e trascinamento su touch, rimossi al tocco successivo | fatta | P0 | piccola | 0.12.0 | `lib/game/board_drawing.dart`, scelta del colore in Impostazioni > Scacchiera; test in `test/game/board_drawing_test.dart` |
| A-3 / RF-22 | **Allenamento e Sfida**: scelta esplicita della modalità e barra di valutazione durante la partita (oggi solo in analisi e revisione) | fatta | P0 | media | 0.12.0 | interruttore «Allenamento» nelle opzioni della galleria dei bot, ricordato in `AppSettings.trainingMode`; Sfida senza aiuti e con Elo e vittorie, Allenamento con aiuti e senza Elo né vittorie; profilo bambino sempre in Allenamento; l'annullamento è disponibile in ogni modalità contro il computer, tornei compresi, e la partita conta comunque; tra due persone sullo stesso telefono serve il consenso (A-4); non c'è ancora per la partita a distanza e Bluetooth; test in `test/game/training_mode_test.dart` (PR 296) |
| A-4 / RF-32 | **Annullamento con consenso** dell'altro giocatore nella partita a due | fatta | P0 | piccola | 0.12.0 | `_requestUndo` in `lib/game/game_page.dart`; test in `test/game/undo_consent_test.dart` |
| A-5 / RF-40 | **Cadenza personalizzata** con minuti e incremento liberi, e **ritardo** (semplice e Bronstein); e **cadenze a più fasi** (per esempio 40 mosse in 90 minuti più 30), anche per la scacchiera fisica | fatta | P0 | media | 0.14.0 | fatti minuti e incremento liberi e ritardo semplice e di Bronstein (`lib/game/clock.dart`, `custom_clock_dialog.dart`; test in `test/game/custom_clock_test.dart`). Seconda fase: `TimeControl.phaseMoves` e `phaseMinutes` (etichetta `90+30@40:30`); `ChessClock.switchAfterMove(moves:)` aggiunge i minuti a chi completa la mossa indicata, e l'annullamento li toglie perché il numero di mosse viene dalla partita. Campi nella finestra «Personalizzata» (da 5 mosse, con i minuti insieme), chip «Personalizzata» anche nella scacchiera fisica, tempo per mossa della revisione corretto, PGN `40/5400+30:1800+30`. Gli inviti per due telefoni restano senza fasi come senza ritardo; test in `test/game/phase_clock_test.dart` |
| A-6 / RM-02 | **Tocco**: correzione quando il dito cade sul bordo di una casa; due tocchi come modo predefinito su telefono | fatta | P0 | piccola | 0.12.0 | `lib/game/tap_assist.dart`, `MoveMethod` in `lib/settings/settings.dart`; test in `test/game/tap_assist_test.dart` e `move_method_test.dart` |
| A-7 / RM-06 | **Schermo sempre acceso** durante la partita | fatta | P0 | piccola | 0.12.0 | `_syncAwake` in `lib/game/game_page.dart` con `wakelock_plus`; test in `test/game/keep_awake_test.dart` |
| A-8 / RM-07 | **Avvio rapido**: pronta a giocare in meno di 2 secondi su un telefono di fascia media, con misura e budget in CI | fatta (#289) | P0 | piccola | 0.14.0 | `integration_test/fluidita_perf.dart` misura l'avvio, con budget `startupMaxMs` in `tool/policy.json` controllato da `tool/check_performance.dart` (`test/tool/budget_test.dart`); il tempo su telefono reale resta da verificare a mano |
| A-9 / RF-31 | **Modalità tavolo**: ruotare di 180° tutti i pezzi del lato superiore, non solo quelli del giocatore in alto | fatta | P0 | piccola | 0.12.0 | `tableMode` in `lib/settings/settings.dart`: `opponentUpsideDown` di chessground capovolge tutti i pezzi del lato superiore |

### A.2 Analisi, revisione, archivio

| ID | Funzione | Stato | Pri | Dim | Versione | Evidenza |
|---|---|---|---|---|---|---|
| A-35 | **Riproduzione nella revisione**: un pulsante «play» fa avanzare la partita da sola fino alla prossima mossa con un commento (errore, imprecisione, mossa brillante od ottima, ingresso nel «Libro», nota personale) e lì si ferma; con le animazioni ridotte salta direttamente alla mossa | fatta | P2 | piccola | 0.15.0 | `lib/review/autoplay.dart` e comando in `review_page.dart`; test in `test/review/autoplay_test.dart` e `review_autoplay_test.dart`; vedi `docs/revisione-partita.md` |

### A.3 Piattaforma, rilascio, qualità

| ID | Funzione | Stato | Pri | Dim | Versione | Evidenza |
|---|---|---|---|---|---|---|
| A-15 / RV-03, RV-04 | **Schermata «Informazioni»** con licenza GPL, link ai sorgenti e crediti degli asset | fatta | P0 | piccola | 0.14.0 | `lib/about/about_page.dart` e `credits.dart`, aperta dall'ultima sezione delle Impostazioni (`settings_page.dart`) |
| A-16 / RV-05 | **Verifica scritta** della compatibilità dell'App Store con la GPL del motore | fatta | P0 | piccola | 0.14.0 | analisi e decisione di Diego (14 ottobre 2026) in `docs/licenza.md`: compatibilità non dimostrata, quindi nessuna pubblicazione sull'App Store finché non c'è un parere legale (iOS non è libero da vincoli) |
| A-17 / RNF-10 | **Dichiarazioni «nessun dato raccolto»**: `PrivacyInfo.xcprivacy`, testi per le schede di sicurezza dei dati degli store, `ITSAppUsesNonExemptEncryption` | rinviata da Diego | P0 | piccola | 0.15.0, da decidere | `docs/sicurezza.md`, «Da fare» |
| A-18 / RNF-03 | **Motore per tutte le architetture** (Android armv7 e x86_64 oltre ad arm64) | rinviata da Diego | P0 | piccola | 0.15.0, da decidere | `docs/rilascio-android.md:71-74` |
| A-19 / RNF-02 | **iOS e F-Droid**: build iOS in CI, Fastlane per TestFlight, metadati e ricetta per F-Droid | rinviata da Diego | P0 | grande | 0.15.0, da decidere | iOS sospeso per decisione di Diego (14 ottobre 2026, vedi A-16); resta da decidere F-Droid; `docs/store.md`, nessun file F-Droid |
| A-20 / RNF-04 | **Dimensione sotto i 60 MB**, con valutazione di una rete NNUE più piccola e misura dell'impatto sulla forza | fatta | P0 | media | 0.14.0 | `apkMaxMegabytes` a 60 in `tool/policy.json`, controllato da `tool/check_size.dart`; `ROKKO_NATIVE_ABIS=arm64-v8a` nel rilascio e `third_party/chessground` ridotta; misura e valutazione della rete NNUE (già la piccola, circa 1 MB) in `docs/qualita.md` |
| A-21 / RNF-06 | **Layout adattivo** con schermo diviso e pieghevoli, e test sulle due colonne | fatta | P0 | media | 0.14.0 | Home con colonna laterale da 840 dp e larghezza massima (#301); partita a due colonne in orizzontale (`game_page.dart`); test/layout/wide_screens_test.dart (nella PR di A-21) prova Home, Impostazioni e partita (a due colonne da tablet) su tablet, desktop, schermo diviso e pieghevole |
| A-22 / RNF-07 | **Ridurre le animazioni** anche dall'impostazione di sistema, con test | fatta | P0 | piccola | 0.14.0 | `AppSettings.reduceMotion` e l'impostazione di sistema azzerano pezzi, pagine (su iOS resta il gesto di ritorno), dialoghi e fogli (`lib/theme/motion.dart`) e la barra di valutazione; `test/theme/motion_test.dart` |
| A-23 / RNF-08 | **Persistenza**: oggi file JSON versionati (`lib/storage/json_file.dart`). Decidere per iscritto se restare su JSON e aggiungere la catena di migrazioni (piccola), o passare a un database locale (grande). Proposta: restare su JSON | fatta (#288) | P0 | piccola | 0.14.0 | `JsonFile` rifiuta tutto ciò che non è tra 1 e la versione corrente |

### A.4 Progressi, tornei, multigiocatore

| ID | Funzione | Stato | Pri | Dim | Versione | Evidenza |
|---|---|---|---|---|---|---|
| A-25 / RG-09 | **Tornei con partite vere** tra i bot e gironi da 4 a 8 giocatori | fatto | P2 | grande | 0.15.0 | partite vere tra i bot (#275); la simulazione Elo resta come ripiego (`docs/tornei.md`) |
| A-26 / RMP | **Orologio nelle partite a distanza**: chi crea sceglie tra lampo con orologio dal vivo e partita lenta con 1, 3 o 7 giorni per mossa, con reclamo della vittoria a scadenza. Resta manuale la prova su telefoni veri con un `integration_test` | fatta (orologio); prova su telefoni veri manuale | P1 | media | 0.13.0 | `docs/multigiocatore.md` (Orologio) |
| A-27 | **Percorso «dai miei errori»**: capitoli personali generati dai temi tattici sbagliati più spesso | fatta | P2 | media | 0.14.0 | `docs/puzzle.md` (Percorso «dai miei errori»); un capitolo per tema con almeno 2 puzzle dai propri errori, fino a 5, dentro l'hub dei puzzle |

### A.5 Da valutare dopo

| ID | Funzione | Stato | Pri | Dim | Note |
|---|---|---|---|---|---|
| A-28 | **Bot «ombra»** che imita lo stile personale (aperture e tempi di riflessione dall'archivio) | da fare | P2 | grande | ingredienti in `lib/openings/personal_tree.dart` e `lib/engine/style.dart`. Da decidere con Diego se farla, e se nella 0.15.0. |
| A-29 | **Lettura della posizione con la fotocamera** (diagramma o scacchiera reale) | da fare | P2 | grande | richiede un modello locale; «Mossa dalla foto» è spenta nelle release dal flag `ROKKO_PHOTO_MOVE`. Da decidere con Diego se farla, e se nella 0.15.0. |
| A-30 | **Altre varianti** (Crazyhouse, Atomica, Antichess, Orda, Corsa dei re) | da fare | P2 | media | le regole sono supportate da `dartchess`; per giocarle contro il computer serve il motore in Dart di RF-123. Da decidere con Diego se farla, e se nella 0.15.0. |
| A-32 | **Widget della schermata home** con il puzzle del giorno e la serie | da fare | P2 | media | Da decidere con Diego se farla, e se nella 0.15.0. |
| A-33 | **Scacchiere elettroniche Bluetooth** | da fare | P2 | grande | permessi e protocolli diversi per marca. Da decidere con Diego se farla, e se nella 0.15.0. |
| A-34 | **Test più solidi** per le funzioni già fatte: rendering di mosse legali, ultima mossa e coordinate (RF-02, RF-03, RF-07), selettore di promozione (RF-04), conferma della mossa (RF-09), velocità animazioni (RF-12), suono e grafica sotto i 10 secondi (RF-41), vibrazione (RM-03), sospensione del motore in background (RNF-05), promemoria locali (RG-11), tetto di dimensione a 60 MB (RNF-04); ID nei test di RF-68, RF-91, RF-100, RF-103, RF-112 | parziale | P1 | media | verificato per elenco dei test, non eseguendoli. Da decidere con Diego se farla, e se nella 0.15.0. |

### A.6 Storia (S) e interfaccia (U)

Il dettaglio di U1-U11 è in `consegne/analisi-ux-ui.md`; il comportamento attuale della storia è in `docs/storia.md`. La storia non è ancora stata provata su un telefono: la prova di Diego sulla 0.8.0 orienta le priorità.

| ID | Funzione | Stato | Pri | Dim | Versione |
|---|---|---|---|---|---|
| S1 | **Un antagonista per capitolo**: carattere, stile di gioco, aperture e due battute prima e dopo la partita | fatto (#277) | Claude | media | 0.15.0 |
| S2 | **Racconto tra un passo e l'altro**: una riga tra lezione e puzzle che richiama ciò che si è imparato | fatta | da assegnare | piccola | 0.15.0 |
| S3 | **Mappa del viaggio** con i nove luoghi, i progressi e «riprendi da dove eri» | fatta | da assegnare | media | 0.14.0 | `lib/story/journey_map.dart`: nove luoghi su un sentiero a serpentina; vedi `docs/storia.md` |
| S4 | **Un bivio per capitolo** (tattica o finali) con puzzle diversi | fatto (#281) | Claude | media | 0.15.0 |
| S5 | **Ricompense legate alla storia**: scacchiere e pezzi sbloccabili con nome a tema | fatta | Claude | piccola | 0.14.0 |
| S6 | **Aiuto quando ci si blocca**: dopo due errori sullo stesso puzzle, un indizio o un puzzle più facile | fatta | da assegnare | piccola | 0.15.0 |
| U1 | **Comandi di partita meno affollati**: 4 azioni in barra, Patta, Abbandona e Nuova in un pannello «Partita»; Allenatore e Minaccia come interruttori — fatto nel profilo bambino (pannello «Partita»); per gli adulti Nuova, Patta e Abbandona restano in barra (scelta di #225), con Allenatore e Minaccia nel pannello «Partita» (aperto da «Altro»); l'obiettivo è stato ridotto per gli adulti, descritto in `docs/interfaccia.md` | fatta | da assegnare | media | 0.14.0 |
| U2 | **Identità visiva di Rokko**: tema proprio, carattere con personalità, torre-mascotte negli stati vuoti e a fine partita | fatta: torre negli stati vuoti dell'archivio e delle aperture personali e a fine partita | da assegnare | media | 0.14.0 |
| U3 | **Layout della partita senza spazio morto** su schermate alte — in verticale la scacchiera sta contro la barra dei comandi e lo spazio sopra è della lista mosse e dei suggerimenti; verificato su schermi molto alti (280x1100, 360x1000, 412x1180, 820x1400) senza overflow anche con il testo al 130%, con test in `test/game/tall_screen_layout_test.dart` | fatta | da assegnare | media | 0.14.0 |
| U4 | **Testi tutti localizzati** nei file `.arb` — fatta: 2014 chiavi in tutte e 11 le lingue, nessun testo italiano fisso nel codice (`tool/stringhe_fisse.dart`), contenuti lunghi in `assets/content/<lingua>/`; resta la rilettura madrelingua di tedesco e turco («in lavorazione») e di polacco e indonesiano («beta») in `tool/lingue.json`, che non è codice | fatta | P1 | grande | 0.11.0 |
| U7 | **Barra del titolo della partita più semplice**: editor e tastiera nel menu ⋮; tastiera visibile con un lettore di schermo | fatta | da assegnare | piccola | 0.12.0 |
| U8 | **Golden fedeli all'app reale**: tema predefinito e font veri; aggiungere Puzzle, Percorso, Storia, Multigiocatore, Tu e profilo bambino | fatta (golden del Percorso aggiunti) | da assegnare | media | 0.14.0 |
| U12 | **Icone più curate** dopo le traduzioni (richiesta di Diego, 13 ottobre 2026) — `RokkoIcons` in `lib/theme/rokko_icons.dart`: stesso set a contorno per barra, pannello e barra del titolo della partita; nelle altre schermate i comandi usano le varianti a contorno e restano piene solo le icone di stato (stella, spunta, lucchetto, corona), l'arte dei badge e l'icona selezionata della barra di navigazione; un test lo verifica | fatta | dopo la 0.11.0 | media | 0.14.0 |

Gli «interventi rapidi» (marchio nel titolo, arancione d'azione, gruppi nella scheda Tu, icone nel menu, anteprima comprimibile, font reale nei golden, test sui testi fissi) si possono fare prima delle voci grandi; sono elencati in `consegne/analisi-ux-ui.md`.

### A.7 Idee oltre i requisiti, da valutare

- **Ripasso a cicli** dello stesso insieme di puzzle, sempre più veloci. Piccola, riusa i puzzle esistenti. Da decidere con Diego se farla, e se nella 0.15.0.
- **Revisione vocale a mani libere** con la sintesi vocale del sistema, per rigiocare sulla scacchiera fisica. Media. Da decidere con Diego se farla, e se nella 0.15.0.
- **Simultanea contro i bot**: 3-5 partite contemporanee con passaggio rapido tra le scacchiere. Grande. Da decidere con Diego se farla, e se nella 0.15.0.
- **Esporta GIF** della partita, oltre all'immagine della posizione (RF-104). Media. Da decidere con Diego se farla, e se nella 0.15.0.

## B. Specifiche complete

Testo di ogni requisito, formulato come funzione di Rokko. La colonna Stato dice *fatta* oppure rimanda alla voce A di questo documento. Le priorità tra parentesi sono quelle originali del requisito.

### 3. Requisiti funzionali

#### 3.1 Scacchiera e interazione (P0)

| ID | Specifica | Stato |
|---|---|---|
| RF-01 | Muovere i pezzi sia per trascinamento sia con due clic (origine, destinazione); entrambi attivi contemporaneamente. | fatta |
| RF-02 | Mostrare le mosse legali del pezzo selezionato (puntini per case vuote, anello per catture). Disattivabile. | fatta |
| RF-03 | Evidenziare l'ultima mossa (casa di partenza e arrivo) e il re sotto scacco. | fatta |
| RF-04 | Promozione con selettore a comparsa sulla casa di arrivo; opzione "promuovi sempre a donna". | fatta |
| RF-05 | Frecce e cerchi: su touch con pressione prolungata e trascinamento, su desktop con il tasto destro; almeno tre colori; rimossi al tocco successivo. | vedi A-2 |
| RF-06 | Capovolgimento della scacchiera e orientamento automatico dal lato del giocatore. | fatta |
| RF-07 | Coordinate visibili (interne o esterne) e disattivabili. | fatta |
| RF-08 | Premossa (premove) durante il turno avversario, annullabile toccando una casa vuota. | vedi A-1 |
| RF-09 | Conferma della mossa opzionale (utile su touch e nelle partite lunghe). | fatta |
| RF-10 | Lista delle mosse in notazione algebrica (SAN), con icone dei pezzi opzionali; navigazione con scorrimento orizzontale (swipe) sulla scacchiera, pulsanti avanti/indietro nella zona del pollice e tocco su una mossa. | fatta |
| RF-11 | Indicatore del materiale catturato e differenza di materiale (es. "+3"). | fatta |
| RF-12 | Animazioni dei pezzi con velocità regolabile, incluse arrocco ed en passant. | fatta |

#### 3.2 Partita contro il computer (P0 per il nucleo, P1 per i bot)

| ID | Specifica | Stato |
|---|---|---|
| RF-20 | Scelta del colore (bianco, nero, casuale) e del livello di forza su una scala chiara (es. 1-10 o Elo indicativo 400-2800), ottenuta limitando profondità, tempo e `Skill Level` di Stockfish. | fatta |
| RF-21 | Il motore gira in un thread o isolate separato per non bloccare l'interfaccia; tempo di riflessione percepito realistico ai livelli bassi (ritardo artificiale). | fatta |
| RF-26 (P1) | Avversario adattivo: il livello si regola partita dopo partita per mantenere circa il 50% di vittorie, senza che l'utente debba scegliere un numero. | fatta |
| RF-22 | Modalità "Allenamento" con aiuti attivabili: suggerimento della mossa, barra di valutazione, minacce. Modalità "Sfida" senza aiuti. L'annullamento è sempre disponibile. | vedi A-3 |
| RF-23 (P1) | Bot con personalità: nome, avatar, Elo, stile (aggressivo, posizionale, amante dei gambetti), apertura preferita e brevi frasi a reazione degli eventi (scacco, cattura, errore). Lo stile si ottiene con libro d'apertura dedicato e regole di scelta tra le prime N mosse del motore. | fatta |
| RF-24 (P1) | Partenza da una posizione personalizzata (FEN o editor di posizione) contro il motore. | fatta |
| RF-27 (P1) | Partite a handicap contro il computer, i bot e nella partita a due: senza un pezzo scelto (pedone f, cavallo, torre, donna) o con tempo diverso per i due giocatori. L'handicap è registrato nel PGN e la partita non conta per il rating locale. | fatta |
| RF-25 | Fine partita gestita correttamente: scacco matto, stallo, tre ripetizioni, 50 mosse, materiale insufficiente, abbandono, patta concordata (il bot accetta in base alla valutazione), tempo scaduto. | fatta |

#### 3.3 Partita locale tra due persone (P0)

| ID | Specifica | Stato |
|---|---|---|
| RF-30 | Modalità "pass and play" sullo stesso dispositivo, con nomi dei giocatori. | fatta |
| RF-31 | Rotazione automatica della scacchiera a ogni turno, disattivabile; modalità "tavolo" per tablet (pezzi superiori ruotati di 180°). | vedi A-9 |
| RF-32 | Proposte di patta, abbandono e annullamento con consenso dell'altro giocatore. | vedi A-4 |

#### 3.4 Orologio (P0)

| ID | Specifica | Stato |
|---|---|---|
| RF-40 | Cadenze predefinite: bullet (1+0, 1+1, 2+1), blitz (3+0, 3+2, 5+0), rapid (10+0, 15+10, 30+0) e senza tempo; cadenza personalizzata con incremento o ritardo. | vedi A-5 |
| RF-41 | Avviso visivo e sonoro sotto i 10 secondi; decimi di secondo sotto i 20. | fatta |
| RF-42 | Pausa automatica quando l'app va in background (solo contro il computer e senza tempo competitivo). | fatta |

#### 3.5 Analisi della posizione (P1)

| ID | Specifica | Stato |
|---|---|---|
| RF-50 | Schermata di analisi apribile da qualsiasi partita o posizione, con barra di valutazione verticale e valore numerico (centipedoni o matto in N). | fatta |
| RF-51 | Linee principali del motore (MultiPV da 1 a 3), profondità visibile, analisi infinita interrompibile. | fatta |
| RF-52 | Esplorazione libera con creazione di varianti ad albero; promozione di una variante a linea principale; eliminazione; salvataggio nell'archivio e PGN con le varianti. | fatta |
| RF-53 | Editor di posizione: posizionamento libero dei pezzi, diritti di arrocco, tratto, import/export FEN, validazione della legalità. | fatta |
| RF-54 | Frecce automatiche della mossa migliore (attivabili). | fatta |
| RF-55 (P1) | Annotazioni personali: commento testuale e simbolo (`!!`, `!`, `!?`, `?!`, `?`, `??`) su ogni mossa e variante, modificabili nell'analisi e nell'archivio, conservati in import ed export PGN (commenti `{}` e NAG). | fatta |
| RF-56 (P1) | Minaccia dell'avversario: un comando mostra con una freccia la mossa migliore che l'avversario giocherebbe se fosse il suo turno (analisi a mossa nulla), nell'analisi e nella partita con l'allenatore. Non disponibile quando il proprio re è sotto scacco. | fatta |

#### 3.6 Revisione della partita (P1)

| ID | Specifica | Stato |
|---|---|---|
| RF-60 | A fine partita, analisi completa in background di tutte le mosse con avanzamento visibile e possibilità di interromperla. | fatta |
| RF-61 | Classificazione di ogni mossa nelle categorie: Brillante, Ottima ("Great"), Migliore, Eccellente, Buona, Libro, Imprecisione, Errore, Errore grave ("Blunder"), Occasione mancata ("Miss"). La classificazione si basa sulla perdita di probabilità di vittoria (valutazione convertita in percentuale), non sui centipedoni grezzi, così da trattare correttamente le posizioni già decise. | fatta |
| RF-62 | "Brillante": sacrificio di materiale che è la mossa migliore o quasi e non porta a posizione persa. "Ottima": unica mossa buona in una posizione critica. | fatta |
| RF-63 | Precisione percentuale per giocatore e conteggio per categoria, con stima indicativa della forza della prestazione. | fatta |
| RF-64 | Grafico dell'andamento della valutazione cliccabile, con i momenti chiave in evidenza. | fatta |
| RF-65 | "Riprova" su ogni errore: l'utente cerca la mossa migliore dalla posizione critica. | fatta |
| RF-66 | Cache dei risultati per partita nel database locale, così la revisione si apre all'istante le volte successive. | fatta |
| RF-67 (P1) | Tempo per mossa: nelle partite con orologio il tempo residuo è registrato a ogni mossa (`[%clk]` nel PGN, conservato in import ed export); la revisione mostra il grafico del tempo speso per mossa e segnala gli errori commessi giocando molto più in fretta della propria media. | fatta |
| RF-68 (P1) | Precisione per fase: la revisione mostra la precisione separata per apertura, mediogioco e finale, con la stessa regola di fase dei puzzle personali; le statistiche (RF-111) ne mostrano la media nel tempo. | fatta |

#### 3.7 Coach e spiegazioni (P2)

| ID | Specifica | Stato |
|---|---|---|
| RF-70 | Spiegazioni testuali brevi generate localmente con regole a modello, senza modelli linguistici remoti: pezzo lasciato in presa, forchetta, inchiodatura, matto mancato, perdita di materiale, re esposto. Esempio: "Hai lasciato l'alfiere in presa in e5: la donna nera lo cattura". | fatta |
| RF-72 (P2) | Commento in tempo reale durante le partite di allenamento: dopo ogni mossa dell'utente una frase breve, disattivabile. | fatta |
| RF-122 (P2) | Modalità «spiegami perché»: attivabile e disattivabile nelle impostazioni, nelle partite contro il computer o un bot. Dopo ogni mossa del computer compare una riga in italiano (o inglese) su cosa la mossa fa, minaccia o prepara (cattura, scacco, arrocco, promozione, pezzo messo al sicuro, minaccia di cattura o di scacco ricavata con la stessa analisi della freccia di RF-56, sviluppo, controllo del centro). La riga è letta dai lettori di schermo; nel profilo bambino è più semplice e non cita le case. Tutto avviene offline, con regole a modello. | fatta |
| RF-73 | Partita con l'allenatore: contro il computer, dopo ogni mossa dell'utente l'allenatore la valuta; se è un errore o un errore grave avverte subito, spiega il motivo con il coach testuale (RF-70) e offre di riprendere la mossa. Il livello di avviso è regolabile e tutto avviene offline. | fatta |
| RF-74 | Suggerimento a livelli durante la partita con l'allenatore: prima si evidenzia il pezzo da muovere, poi la mossa. I suggerimenti usati sono contati. | fatta |
| RF-75 | L'allenatore non rianalizza posizioni già valutate (suggerimento e giudizio sulla stessa posizione usano una sola analisi), per contenere batteria e calore (RNF-05). | fatta |
| RF-76 | Notazione delle mosse a scelta: figurativa (simbolo del pezzo al posto della lettera, comprensibile in qualsiasi lingua, predefinita), italiana (R, D, T, A, C) o inglese. Si applica a elenco delle mosse, revisione, analisi, aperture e spiegazioni; il suggerimento dell'allenatore usa frasi in italiano semplice senza notazione. | fatta |
| RF-71 | Riconoscimento tattico semplice a partire dalla variante principale del motore (cattura netta, doppio attacco, scoperta). | fatta |

#### 3.8 Puzzle (P1)

| ID | Specifica | Stato |
|---|---|---|
| RF-80 | Raccolta di puzzle inclusa nell'app: si usa un database aperto di puzzle (licenza CC0, vedi `CREDITS.md`), filtrato a qualche migliaio di problemi per fasce di difficoltà e temi, compresso e incluso nel pacchetto dell'app. | fatta |
| RF-81 | Modalità classica con punteggio puzzle locale (sistema Glicko o Elo) che adatta la difficoltà. | fatta |
| RF-82 | Modalità a tempo (corsa e combo) (3 minuti, 5 minuti, bonus di tempo per le combo, "sopravvivenza" con tre errori) e serie (serie di difficoltà crescente, finisce al primo errore). | fatta |
| RF-85 | Ripetizione dei puzzle sbagliati a intervalli crescenti. | fatta |
| RF-83 | Suggerimento, mostra soluzione, filtro per tema (matto in 2, forchetta, finali). | fatta |
| RF-84 | Il Puzzle del giorno è sostituito da un puzzle giornaliero deterministico scelto in base alla data. | fatta |
| RF-86 (P1) | Allenatore dei finali: raccolta di posizioni teoriche (matti elementari con donna e torre, re e pedone contro re, Lucena, Philidor, alfiere e cavallo) da vincere o pattare contro il motore a forza piena, con obiettivo dichiarato, valutazione da 1 a 3 stelle in base alle mosse impiegate e ripetizione delle posizioni fallite. Le posizioni sono originali o di pubblico dominio. | fatta |
| RF-87 (P1) | Partite dei grandi maestri: raccolta inclusa nell'app, senza rete, di partite storiche celebri, da sfogliare mossa per mossa con un commento in italiano sulle mosse chiave. Le mosse sono fatti storici e le intestazioni (giocatori, luogo, anno, risultato) sono dati di pubblico dominio; i commenti sono scritti per il progetto sotto GPL-3.0 e la fonte di ogni partita è documentata. | fatta |
| RF-88 (P1) | «Indovina la mossa»: si gioca dalla parte di un maestro e a ogni suo turno si propone la propria mossa, che viene confrontata con quella giocata nella partita; a fine partita punteggio in percentuale e da 1 a 3 stelle, con i migliori risultati salvati. | fatta |
| RF-95 (P2) | Sfida a tempo tra amici senza rete: un telefono mostra un QR che lancia sull'altro telefono la stessa corsa o combo a tempo, con lo stesso seme (stessi puzzle, stesso ordine); a fine prova ciascun telefono mostra un secondo QR col proprio punteggio e legge quello dell'amico, poi confronta i due risultati. Nessun account, server o rete; i QR sono quelli dello scambio di partite e il QR del risultato non è firmato (sfida tra amici, non classifica). | fatta |
| RF-97 (P2) | Finali perfetti: nelle posizioni con al massimo quattro pezzi (re compresi, senza pedoni contrapposti) l'app mostra, senza rete e senza motore, il risultato esatto (vittoria con matto in N mosse, patta, sconfitta) e la mossa migliore, nell'analisi della posizione e nell'allenatore dei finali. Le tabelle del matto esatto si generano sul telefono al primo uso e si tengono in una cartella locale; le tabelle Syzygy fino a 5 pezzi sono escluse per dimensione. Testi localizzati e accessibili; nel profilo bambino nessun numero. | fatta |

- Puzzle Battle e classifiche globali sono esclusi.
#### 3.9 Aperture (P1)

| ID | Specifica | Stato |
|---|---|---|
| RF-90 | Riconoscimento e visualizzazione del nome dell'apertura durante la partita (codice ECO e nome), usando un dataset aperto di aperture (CC0, vedi `CREDITS.md`), qualche centinaio di KB. | fatta |
| RF-91 | Le mosse di libro sono marcate "Libro" nella revisione. | fatta |
| RF-93 (P2) | Allenatore di repertorio: l'utente definisce le proprie linee (da PGN o dalla scacchiera) e l'app gliele fa ripetere con ripetizione dilazionata. | fatta |
| RF-94 (P1) | Gioca un'apertura: dall'explorer o da una linea del repertorio si avvia una partita contro il computer o un bot che parte dopo le mosse scelte; se il bot esce dalla linea del repertorio l'app lo segnala. | fatta |
| RF-92 (P2) | Explorer ridotto con le continuazioni principali e le percentuali da un piccolo libro precalcolato; le statistiche di un database globale sono escluse. | fatta |
| RF-96 (P2) | Le tue aperture: albero delle aperture costruito dall'archivio locale delle partite concluse dell'utente, con per ogni mossa quante volte è stata giocata e con quali risultati (vinte, patte, perse), filtrabile per colore e per avversario, collegato all'explorer delle aperture nella stessa posizione. Solo dati locali, nessuna rete. | fatta |

#### 3.10 Archivio e dati (P0 per salvataggio, P1 per il resto)

| ID | Specifica | Stato |
|---|---|---|
| RF-100 | Salvataggio automatico della partita in corso a ogni mossa; ripresa dopo chiusura dell'app o ricarica. | fatta |
| RF-101 | Storico delle partite con data, avversario, cadenza, risultato e apertura, con filtri e ricerca. | fatta |
| RF-102 | Import ed export PGN (singola partita e intero archivio), copia FEN, condivisione con il menu di condivisione nativo del sistema. | fatta |
| RF-104 (P1) | Esporta la posizione come immagine: da partita, analisi, puzzle ed editor un PNG della scacchiera con il tema e i pezzi scelti, frecce, coordinate e didascalia facoltativa, da condividere con il menu di sistema; senza rete e senza server. | fatta |
| RF-103 | Backup e ripristino completo dei dati in un file JSON, perché offline non esiste sincronizzazione su cloud. | fatta |

#### 3.11 Statistiche e progressi (P2)

| ID | Specifica | Stato |
|---|---|---|
| RF-110 | Rating locale stimato contro il computer, aggiornato dopo ogni partita in base al livello battuto. | fatta |
| RF-111 | Statistiche: vittorie/patte/sconfitte per colore e per cadenza, precisione media nel tempo, aperture più giocate. | fatta |
| RF-112 | Obiettivi e traguardi: vedi il capitolo 3.13. | fatta |

#### 3.12 Varianti (P2)

| ID | Specifica | Stato |
|---|---|---|
| RF-120 | Chess960 con generazione della posizione iniziale e arrocco corretto; supportata da Stockfish. | fatta |
| RF-121 | Altre varianti (Re della collina, Tre scacchi) solo se il motore delle regole le gestisce senza costi elevati. | fatta |
| RF-123 (P2) | Le varianti RF-120 e RF-121 (Chess960, Re della collina, Tre scacchi) si giocano anche contro il computer e i bot, oltre che in due sullo stesso telefono. Poiché Stockfish non ne conosce tutte le regole, risponde un motore in Dart basato sulle stesse regole che arbitrano la partita, con gli stessi otto livelli, offline e senza bloccare l'interfaccia. Suggerimenti, allenatore, analisi e revisione restano solo negli scacchi classici; le partite in variante non contano per il rating locale. | fatta |

#### 3.13 Gamification (P0 per il nucleo, P1 e P2 per il resto)

Principi: motivare senza punire, funzionare offline, nessun elemento acquistabile (RV-01), interruttore generale per disattivare la gamification.
| ID | Specifica | Stato |
|---|---|---|
| RG-01 (P0) | Punti esperienza (XP) e livelli: XP per partite (anche perse), puzzle, lezioni e revisioni completate; livello del giocatore visibile nel profilo. Più XP per le attività formative che per la sola vittoria. | fatta |
| RG-02 (P0) | Obiettivo giornaliero e serie (streak): l'utente sceglie un obiettivo (es. 1 partita o 5 puzzle o 10 minuti); i giorni consecutivi formano la serie. Protezione della serie ("congelamento") guadagnata giocando, mai acquistabile, e giorno di riposo settimanale configurabile. | fatta |
| RG-03 (P0) | Percorso a tappe: mappa visiva, con capitoli (movimento dei pezzi, matti elementari, tattiche, finali, aperture). Ogni tappa è una lezione breve, un gruppo di puzzle o una partita contro un bot "guardiano"; valutazione da 1 a 3 stelle. | fatta |
| RG-04 (P1) | Scala dei bot: i bot con personalità (RF-23) sono disposti in una scala da sbloccare battendo il precedente; ogni bot battuto entra in una "collezione" con la propria scheda. | fatta |
| RG-05 (P1) | Medaglie e traguardi: almeno 30 medaglie in categorie (gioco, tattica, costanza, curiosità), es. "Primo matto con il cavallo", "Arrocco lungo vincente", "7 giorni di fila", "Brillante trovata". Notifica in-app quando si ottengono. | fatta |
| RG-06 (P1) | Ricompense estetiche: temi di scacchiera, set di pezzi, cornici e avatar si sbloccano con livelli e medaglie. Per rispetto di RV-01 un'opzione "Sblocca tutto" nelle impostazioni rende tutto disponibile a chi non vuole giocare per sbloccare. | fatta |
| RG-07 (P1) | Sfide giornaliere e settimanali: tre missioni al giorno generate localmente (es. "vinci con il nero", "risolvi 3 puzzle di forchetta", "rivedi una partita"), con XP bonus. | fatta |
| RG-08 (P1) | Record personali: miglior punteggio nelle modalità a tempo, serie più lunga, bot più forte battuto, precisione migliore; il nuovo record viene celebrato con animazione. | fatta |
| RG-09 (P2) | Tornei offline contro bot: girone all'italiana o eliminazione diretta contro 4-8 bot, con classifica e trofeo. Sostituisce le leghe online in modo onesto, con partite reali. | vedi A-25 |
| RG-10 (P2) | Minigiochi: allenatore delle coordinate a tempo, "cattura tutto" con un solo pezzo, visualizzazione alla cieca, conta del materiale. | fatta |
| RG-11 (P1) | Notifiche locali. opzionali per ricordare l'obiettivo giornaliero, una al giorno al massimo, all'orario scelto dall'utente; nessuna notifica di default. | fatta |
| RG-12 | Esclusioni etiche: nessuna "vita" o penalità per gli errori, nessun conto alla rovescia artificiale, nessuna valuta virtuale, nessun confronto con classifiche fittizie. | fatta |
| RG-16 (P1) | Riepilogo settimanale: scheda offline degli ultimi sette giorni con progressi (partite, puzzle, lezioni, revisioni, precisione rispetto alla settimana prima), l'errore ricorrente più frequente ricavato dalle revisioni del coach e un solo consiglio, con il collegamento alla lezione o ai puzzle adatti. Calcolato in locale da un diario dei soli conteggi. Nel profilo bambino niente numeri: stelle e frasi. | fatta |
| RG-13 (P1) | Percorso a storia: una trama a capitoli, in cima al percorso a tappe, che unisce lezioni, puzzle, guardiani e un avversario a tema per capitolo. Ogni capitolo ha un racconto breve, un elenco di passi in ordine (lezioni, puzzle del tema, guardiano dove c'è, sfida finale contro un bot della scala) e un epilogo; il capitolo successivo si apre a capitolo concluso. Lo stato deriva dal percorso e dalla scala dei bot; funziona offline, senza penalità (RG-12), con testi localizzati e accessibili. | fatta |
| RG-17 (P1) | Badge: una collezione di badge legati a ciò che si impara e si gioca (capitoli del percorso, finali e partite dei maestri, temi dei puzzle, storia, partite memorabili, costanza), distinta dai traguardi di RG-05. Ogni badge ha nome, descrizione, icona e condizione di sblocco; si ottiene una sola volta, offline, ed è onorifico: nessun XP e nessuna ricompensa estetica. La scheda dei badge, raggiungibile da «I miei dati» nella scheda Tu, mostra per famiglia i badge ottenuti con la data e quelli da ottenere con l'avanzamento; lo sblocco è annunciato in app con un avviso non invasivo. Rispetta RG-12 (nessuna penalità, nessun confronto). Non compare nel profilo bambino. Catalogo in `badge.md`. | consegnato in A-24 |
| RG-18 (P1) | Galleria dei bot: una schermata per scegliere l'avversario tra i bot, con in alto il bot selezionato (avatar grande, fumetto di saluto nel suo carattere, nome, Elo), una griglia di avatar raggruppati per fascia di Elo (Neofita, Principiante, Intermedio, Avanzato, Maestro) con lucchetto sui bloccati e corona sui battuti, la carta Adattivo, una sezione a tema con i custodi della Storia e una barra di avanzamento, la scelta del colore (Bianco, a sorte, Nero) e un bottone Gioca sempre in vista. Saluti e battute localizzati; un bot bloccato si vede ma non si gioca. Nel profilo bambino solo i bot amici, senza numeri. Accessibile (nomi e stati per i lettori di schermo, bersagli da 48 dp, testo al 130%). Dettagli in `bot.md`. | fatta |

### 4. Personalizzazione (P0 per il minimo, P1 per il resto)

| ID | Specifica | Stato |
|---|---|---|
| RP-01 | Almeno 4 temi di scacchiera (verde classico, marrone legno, blu, grigio) e 2-3 set di pezzi con licenza libera (licenza GPL/CC, vedi `CREDITS.md`). | fatta |
| RP-02 | Tema chiaro e scuro dell'interfaccia, con preferenza di sistema come predefinita. | fatta |
| RP-03 | Suoni per mossa, cattura, scacco, arrocco, promozione, fine partita e tempo in esaurimento; volume e silenziamento. | fatta |
| RP-04 | Tutte le opzioni di 3.1 (mosse legali, coordinate, premossa, conferma, animazioni, promozione automatica) in un'unica pagina Impostazioni, salvate in locale. | fatta |
| RP-05 | Lingua italiana come predefinita; struttura pronta per altre lingue. | fatta |
| RP-06 | Profilo "bambino" (P2): interfaccia semplificata, testi più semplici, bot amichevoli, nessuna statistica numerica. | fatta |
| RP-08 (P1) | Avatar simpatici: oltre ai simboli dei pezzi, una famiglia di personaggi disegnati in codice, coerenti con la mascotte e con l'identità spaziale dell'app (indaco, viola, giallo stella), in parte sbloccabili come gli altri avatar (RG-06). | fatta |
| RP-09 (P1) | Foto del profilo: l'utente può usare una propria foto, dalla galleria o dalla fotocamera, ritagliata in cerchio e con la cornice scelta. Resta solo nella cartella privata dell'app (non nel backup, non inviata, non condivisa), si rimuove con un pulsante, i permessi si chiedono solo al momento dell'uso (fotocamera) o non servono (galleria) e il profilo bambino non la offre. | fatta |
| RP-07 (P2) | Modalità zen: durante la partita restano solo scacchiera, mosse ed eventuale orologio; nascosti rating e livello dell'avversario, materiale, valutazione, stato, avvisi e commenti dell'allenatore e dei bot, animazioni di festa. Si attiva dalle impostazioni e al volo dalla barra della partita; testi localizzati e accessibili (lettori di schermo: le mosse restano annunciate). | fatta |
| RP-10 (P1) | Guida all'uso: la prima volta che si apre una schermata compare una breve guida a passi che evidenzia gli elementi reali e ne spiega le funzioni. È sempre saltabile («Salta», tasto indietro), si ricorda per schermata nelle preferenze locali, si spegne e si rivede da Impostazioni → Accessibilità, ha frasi più semplici nel profilo bambino, è accessibile ai lettori di schermo e localizzata in tutte le lingue. | fatta (Home, Puzzle, Impara, Tu, Impostazioni, scelta della partita, partita, Storia; le altre schermate restano da coprire: `docs/guida-all-uso.md`) |

### 5. Requisiti non funzionali e mobile-first

#### 5.1 Esperienza mobile (P0)

| ID | Specifica | Stato |
|---|---|---|
| RM-01 | Uso con una mano: in verticale la scacchiera occupa tutta la larghezza; i comandi principali (annulla, suggerimento, menu della partita, avanti/indietro) stanno in una barra in basso, nella zona del pollice. | fatta |
| RM-02 | Tocco: muovere con due tocchi è la modalità predefinita su telefono; aree di tocco di almeno 48 dp; correzione della mossa se il dito cade sul bordo di una casa; nessuna mossa per errore durante lo scorrimento. | vedi A-6 |
| RM-03 | Feedback tattile: vibrazione leggera per mossa, cattura e scacco, disattivabile. | fatta |
| RM-04 | Sessioni brevi: ogni attività del percorso dura da 2 a 5 minuti; la schermata iniziale propone con un tocco "Continua" (partita in corso, tappa successiva o sfida del giorno). | fatta |
| RM-05 | Interruzioni: telefonate, notifiche o passaggio a un'altra app non fanno perdere nulla; la partita si salva a ogni mossa e l'orologio si mette in pausa quando possibile (RF-42). | fatta |
| RM-06 | Schermo: lo schermo resta acceso durante la partita; orientamento verticale come predefinito, orizzontale supportato su tablet e pieghevoli con pannello laterale. | vedi A-7 |
| RM-07 | Avvio rapido: app pronta a giocare in meno di 2 secondi su un telefono di fascia media; il motore si inizializza in background. | vedi A-8 |

#### 5.2 Piattaforma e distribuzione

| ID | Specifica | Stato |
|---|---|---|
| RNF-01 | Offline totale: dopo l'installazione dallo store tutte le funzioni funzionano in modalità aereo, senza download aggiuntivi obbligatori. Nessun permesso di rete richiesto per giocare da soli. Il multigiocatore tra due telefoni (requisiti RMP-01…RMP-07, `docs/multigiocatore.md` del repository) è un modulo opzionale che usa rete locale, Bluetooth o internet. | fatta |
| RNF-02 | Piattaforme: Android e iOS come destinazioni primarie con Flutter; desktop e web come secondarie. Distribuzione su Google Play, App Store e F-Droid (vedi RV-05). | vedi A-19 |
| RNF-03 | Motore: Stockfish compilato in modo nativo per ciascuna architettura (Android arm64, armv7, x86_64; iOS arm64) e richiamato tramite FFI, in un isolate separato. Limitare i thread a 1-2 su telefono. | vedi A-18 |
| RNF-04 | Dimensioni: obiettivo sotto i 60 MB scaricati. Le reti neurali NNUE delle versioni recenti di Stockfish pesano decine di MB: valutare la rete piccola o una versione con rete più leggera, e misurare l'impatto sulla forza ai livelli usati dall'app. Puzzle e aperture compressi. | vedi A-20 |
| RNF-05 | Batteria e calore: limitare profondità e durata dell'analisi; nella revisione completa usare profondità moderata e mostrare l'avanzamento; sospendere il motore in background. | fatta |
| RNF-06 | Layout adattivo: verticale su telefono, a due colonne su tablet e desktop; supporto a schermo diviso e pieghevoli. | vedi A-21 |
| RNF-07 | Accessibilità: contrasti adeguati, supporto a TalkBack e VoiceOver con annuncio delle mosse e delle case, inserimento della mossa testuale o vocale tramite tastiera di sistema (es. "Cf3"), testi scalabili, colori per daltonici sulle evidenziazioni, opzione per ridurre le animazioni. | vedi A-22 |
| RNF-08 | Persistenza: database locale SQLite (es. `drift`) per partite, puzzle, progressi e cache di analisi; migrazioni di schema versionate per non perdere i progressi agli aggiornamenti. | vedi A-23 |
| RNF-09 | Licenze: nessun asset di altre app (pezzi, suoni, nomi e immagini dei bot); solo risorse con licenza libera o originali, nel rispetto di RV-03, RV-04 e RV-05. | fatta |
| RNF-10 | Privacy: nessun SDK di analisi o di pubblicità; dichiarazioni "nessun dato raccolto" sugli store (sezione Data Safety di Google Play, Privacy Nutrition Label di Apple). | vedi A-17 |

### Multigiocatore e proposte oltre i requisiti

| ID | Specifica | Stato |
|---|---|---|
| RMP-01 – RMP-07 | Partita tra due telefoni, modulo opzionale (invito, firma e cifratura, registro delle mosse, canali Wi-Fi, Bluetooth e relay); dettaglio in `docs/multigiocatore.md` | fatta, orologio a distanza compreso (A-26); restano le prove su telefoni veri |
| Cap. 7 | Allenamento dagli errori, scacchiera fisica, scambio di partite con il QR, ritratto del giocatore, sfida a tempo tra amici | fatta |
| Cap. 7 | Percorso «dai miei errori», bot «ombra», lettura della posizione con la fotocamera | vedi A-27, A-28, A-29 |

## C. Esclusioni esplicite

Partite online con sconosciuti, abbinamenti, tornei online, leghe con altri utenti, chat, amici, club, forum, notizie, streaming, classifiche globali, sfide uno contro uno online, lezioni video, spiegazioni basate su intelligenza artificiale remota, statistiche di un database globale di aperture, tabelle di finali a 5 pezzi o più per dimensione.

## D. Note sul controllo

- Verifica fatta il 13 ottobre 2026 leggendo codice, test e documenti; i test non sono stati eseguiti.
- Dove un requisito è diviso (per esempio RG-17, RF-22), la sezione B dice «fatta» o rimanda alla voce A per la parte mancante.
- Le voci dei gruppi RF-01, RF-06, RF-10, RF-11, RF-20, RF-21, RF-23 – RF-27, RF-30, RF-42, RM-01, RM-05 e RP-01 – RP-08 sono state verificate soprattutto da elenco dei test e documenti.
- I crediti dei dati e delle librerie di terze parti restano in `CREDITS.md` e `NOTICE.md`, come richiedono le licenze.

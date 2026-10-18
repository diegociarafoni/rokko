# Localizzazione

Requisito RP-05: italiano come lingua predefinita, con la struttura pronta per altre lingue.

## Stato

- L'app usa `flutter_localizations` e il generatore `gen-l10n` di Flutter.
- La lingua dell'app si sceglie in **Impostazioni → Accessibilità → Lingua**: «Come il telefono» (predefinita), Italiano, English, Português, Français, Español, Deutsch, Polski, Bahasa Indonesia, Русский, Nederlands o Türkçe (`AppLanguage` in `lib/settings/app_language.dart`, salvata come `language`). `MaterialApp.locale` in `lib/main.dart` è quella scelta, o `null` per seguire il telefono; `resolveAppLocale` (`localeListResolutionCallback`) prende la prima lingua del telefono tra quelle supportate e, se non ce n'è, usa l'italiano. `l10n.yaml` indica l'italiano come lingua preferita. I nomi delle lingue nella scelta restano nella lingua stessa.
- Su iOS e macOS la regione di sviluppo è l'italiano; le finestre native del sistema (condivisione, permessi) seguono la lingua del dispositivo se è italiano o inglese, altrimenti usano l'italiano. I testi dei permessi di iOS (`NSCameraUsageDescription` e simili) hanno una traduzione per lingua in `ios/Runner/<lingua>.lproj/InfoPlist.strings`; `Info.plist` conserva l'italiano come ripiego. Su Android 13+ `res/xml/locales_config.xml` elenca le lingue dell'app per la scelta lingua per app del sistema.
- Il nome sotto l'icona non viene da `appTitle`: è `android:label` in `android/app/src/main/AndroidManifest.xml` e `CFBundleDisplayName` in `ios/Runner/Info.plist`.
- Sono dichiarate italiano, inglese, portoghese, francese, spagnolo, tedesco, polacco, indonesiano, russo, olandese e turco (`supportedLocales`, e `CFBundleLocalizations` su iOS e macOS). Sono tradotti il nome dell'app, i testi del profilo bambino (prefissi `kid`, `kidGame`, `kidBot`), quelli dello scambio QR (prefisso `qr`), quelli dei badge (prefissi `badge` e `badges`), quelli dell'esportazione come immagine (prefisso `shareImage`), quelli della scacchiera fisica (prefisso `physical`), il profilo con traguardi, sfide, serie e promemoria (prefisso `progress`), la revisione della partita e i commenti dell'allenatore (prefisso `review`), i suggerimenti (`coachHint`), l'analisi (`analysis`), l'archivio (`archive`), la scheda settimanale (`portrait`) e le schermate elencate in [Schermate migrate](#schermate-migrate). Nel codice non restano testi italiani fissi (vedi [Testi da spostare](#testi-da-spostare)).

## Lingue di destinazione

L'italiano è la lingua base e il modello degli `.arb`; inglese, portoghese del Brasile, francese, spagnolo, russo e olandese sono pronti; tedesco, polacco, indonesiano e turco sono in lavorazione o beta (vedi `tool/lingue.json`). Ogni testo dell'app, comprese lezioni, commenti dei grandi maestri, frasi dei bot, spiegazioni dell'allenatore e nomi delle aperture, deve avere la sua traduzione. La documentazione in `docs/` resta in italiano. La notazione dei pezzi si sceglie nelle Impostazioni e non dipende dalla lingua. Per un dispositivo in un'altra lingua l'app usa l'italiano.

I termini scacchistici e le regole di stile di ogni lingua sono in [glossario-scacchistico.md](glossario-scacchistico.md); per il portoghese del Brasile in [glossario-portoghese.md](glossario-portoghese.md), per l'olandese in [glossario-nl.md](glossario-nl.md). Chi traduce o rilegge parte da lì.

Sono dichiarati italiano, inglese, portoghese, francese, spagnolo, tedesco, polacco, indonesiano, russo, olandese e turco (`tool/lingue.json`); italiano e inglese restano obbligatori in ogni modifica ai testi.

## Russo

Il russo (`ru`) è `pronta`: tutte le chiavi dei `.arb` (`lib/l10n/ru/`) e i contenuti lunghi (`assets/content/ru/*.json`) sono tradotti. Termini e regole di stile sono nella sezione «Russo» di [glossario-scacchistico.md](glossario-scacchistico.md): si dà del «ты», virgolette «…», notazione con le lettere russe (Кр, Ф, Л, С, К).

- **Plurali a quattro forme.** Nei `.arb` russi ogni `plural` ha `one` (1, 21, 31…), `few` (2-4, 22-24…), `many` (0, 5-20, 25-30…) e `other` (frazioni). La forma `one` non scrive mai «1» a mano: usa il segnaposto, perché vale anche per 21. `test/l10n/russian_test.dart` controlla che le quattro forme ci siano dove l'inglese ha un plurale e che `one` non contenga un numero fisso.
- **Concordanze.** Dove il russo richiederebbe un caso o un genere sul valore di un segnaposto (per esempio il nome di un pezzo, inserito dal codice sempre al nominativo), la frase è riformulata in modo neutro (due punti, etichetta) invece di aggiungere chiavi.
- **Nomi delle aperture.** `assets/content/ru/opening_names.json` ha la stessa struttura di quello italiano (sostantivo + complemento al genitivo + coda); il codice che compone i nomi oggi è solo italiano (come i titoli dei volumi in `lib/badges/opening_books_tab.dart`, che per le altre lingue usano l'inglese), quindi per il russo i nomi composti si leggono come «sostantivo, poi aggettivo». Un motore dedicato è lavoro futuro; i nomi che non hanno una forma russa nota (Bongcloud, Creepy Crawly…) restano in inglese.
- **Caratteri.** L'app usa i caratteri di sistema (Roboto su Android, San Francisco su iOS), che includono il cirillico: non serve incorporare font. Nei test grafici di Flutter il testo usa un font a blocchi, quindi `test/game/game_russian_test.dart` verifica il layout (nessun overflow su telefono piccolo e medio, i testi lunghi del russo), non le forme delle lettere.
- **Notazione.** I testi che citano mosse usano le lettere russe (Кр, Ф, Л, С, К); le opzioni di notazione dell'app (figurina, italiana, inglese) non includono ancora quella russa, che richiederà codice dedicato.
- **Contenuti lunghi.** I `.json` sono letti dall'app tramite `ContentText` (vedi «Contenuti per lingua»).
- **Sistema.** `ios/Runner/ru.lproj/InfoPlist.strings` per i permessi, `ru` in `CFBundleLocalizations` (iOS e macOS), `knownRegions` e `locales_config.xml`.

## File

| File | Contenuto |
|---|---|
| `l10n.yaml` | Configurazione del generatore |
| `lib/l10n/it/<funzione>.arb` | Testi italiani di una funzione, modello di riferimento con le descrizioni |
| `lib/l10n/en/<funzione>.arb` | Traduzione inglese, con gli stessi nomi di file e le stesse chiavi |
| `lib/l10n/<lingua>/guide.arb` | Testi della guida alla prima apertura ([guida-all-uso.md](guida-all-uso.md)) |
| `tool/l10n.dart` | Unisce i file per funzione e lancia `flutter gen-l10n` |
| `lib/l10n/app_<lingua>.arb`, `lib/l10n/app_localizations*.dart` | Prodotti da `tool/l10n.dart`, non sono nel repository (`.gitignore`) |

I testi sono in un file per funzione (`kids.arb`, `story.arb`, `stats.arb`, `exchange.arb`, `game.arb`, `puzzles.arb`, `openings.arb`, `coach.arb`…), con il nome della cartella di `lib/` a cui appartengono. Due PR che aggiungono testi a funzioni diverse toccano file diversi e non vanno in conflitto; per questo i file unici e il codice generato non sono versionati.

Dopo un clone, e dopo ogni modifica ai `.arb` o un cambio di ramo, eseguire `dart tool/l10n.dart`. Con una copia nuova `flutter pub get` fallisce finché i file unici non esistono: il comando va dato prima (in CI `dart tool/l10n.dart --solo-unione`, che non lancia `gen-l10n`). `tool/verifica.sh` e l'hook di pre-commit lo eseguono già.

## Testi fissi nel codice

`dart tool/stringhe_fisse.dart` cerca in `lib/` le frasi italiane scritte tra apici invece che nei `.arb` (almeno due parole, con parole italiane comuni o lettere accentate; commenti, `import` e identificativi sono ignorati). I conteggi per cartella stanno in `tool/stringhe_fisse_base.json` e **non possono salire**: la CI e `tool/verifica.sh` falliscono se una cartella ha più testi fissi della base, con l'indicazione di dove spostarli. Quando una cartella viene migrata la base si abbassa con `dart tool/stringhe_fisse.dart --aggiorna`. `--elenco` stampa ogni testo con file e riga. Un nome proprio o un dato dell'archivio che il controllo scambia per testo si esclude con il commento `// l10n-ok` sulla riga. Il controllo è euristico: trova i testi italiani, non quelli già in un'altra lingua.

## Stato delle lingue e ripiego

`tool/lingue.json` dichiara lo stato di ogni lingua: `base` (italiano), `pronta`, `beta` o `in lavorazione`. Le lingue base e pronte devono avere esattamente le stesse chiavi dell'italiano. Le lingue `beta` e `in lavorazione` possono averne meno: `tool/l10n.dart` riempie quelle che mancano con il testo inglese, così l'app compila e le PR sulle schermate non devono aspettare le traduzioni. Una chiave che esiste in una lingua incompleta ma non nelle altre resta un errore.

`dart tool/l10n_stato.dart` stampa per ogni lingua le chiavi tradotte rispetto all'italiano; con `--manca` elenca quali mancano, per file. Esce con errore se una lingua `base` o `pronta` (o non dichiarata) è incompleta; la CI lo esegue. Una nuova cartella in `lib/l10n/<lingua>/` va dichiarata in `tool/lingue.json`, altrimenti viene trattata come lingua completa.

## Aggiungere un testo

1. Aggiungere la chiave nel file della funzione in `lib/l10n/it/` (uno nuovo, con lo stesso nome in `lib/l10n/en/`, se la funzione è nuova), con una voce `@chiave` che ne descrive il contesto quando il testo da solo non basta e che dichiara i segnaposto. Le chiavi sono in camelCase con il prefisso della schermata (`backup…`, `minigames…`, `stats…`).
2. Aggiungere la stessa chiave nello stesso file di ogni altra lingua, con gli stessi segnaposto. Una chiave non può comparire in due file. Non si scrive `@@locale`: lo aggiunge `tool/l10n.dart`.
3. Per i conteggi usare i plurali ICU (`{count, plural, one{{count} partita} other{{count} partite}}`) invece di comporre la frase nel codice.
4. Eseguire `dart tool/l10n.dart`, che unisce i file, controlla che le lingue coincidano e rigenera il codice; i file prodotti non si committano.
5. Nel codice usare `AppLocalizations.of(context).chiave`.

`test/tool/l10n_merge_test.dart` verifica l'unione (nessuna chiave duplicata, stessi file e stesse chiavi per lingua). `test/l10n_test.dart` controlla che italiano e inglese abbiano le stesse chiavi e gli stessi segnaposto e che nessuna traduzione sia vuota, e monta alcune schermate migrate in inglese.

## Contenuti per lingua

I testi lunghi o in lista (lezioni, grandi maestri, finali, frasi dei bot, nomi delle aperture) non stanno negli `.arb`: sono in `assets/content/<lingua>/<nome>.json`, un file per contenuto e per lingua. Regola: una frase di interfaccia o una stringa singola va in `.arb`; un racconto, un commento per mossa o una lista di frasi va in JSON.

- Il formato è piatto, pensato per essere tradotto da persone: `{"chiave.id": "testo"}`, oppure una lista di frasi `"bot.aggressive.check": ["...", "..."]`. I segnaposto sono `{nome}`. Il codice tiene la parte non testuale (mosse, posizioni, soglie) e un `id` stabile.
- `lib/l10n/content.dart`: `ContentText` legge i testi per id con ripiego lingua scelta, inglese, italiano; un id sconosciuto restituisce l'id stesso. `Content` tiene i contenuti della lingua attiva, caricati all'avvio da `RokkoApp`; i test li trovano già caricati (`test/flutter_test_config.dart`) e per provare un'altra lingua usano `useContent('en')` di `test/content_support.dart`.
- Per aggiungere una lingua si copia la cartella italiana e si traducono i valori senza toccare le chiavi; le cartelle sono dichiarate in `pubspec.yaml`.
- Contenuti attuali: `path`, `endgames`, `masters`, `bots` (frasi per stile ed evento, descrizioni, nomi delle aperture dei bot) e `opening_names`. Quest'ultimo è fatto di famiglie (`family.<nome inglese>`), gruppi di parole (`phrase.`), sostantivi con genere (`noun.`), aggettivi maschile e femminile (`adjective.`), prefissi (`prefix.`) e `grammar.with` / `grammar.feminine`; ogni lingua aggiunge le sue famiglie e le sue parole in `assets/content/<lingua>/opening_names.json`. In inglese il file non esiste: il nome resta quello del libro (`localOpeningName`). Per spagnolo e francese basta creare il file con gli stessi id; ciò che manca resta in inglese.
- `test/l10n/content_parity_test.dart` verifica che, per ogni file dei contenuti italiani, le lingue elencate in `_checked` abbiano gli stessi id, gli stessi segnaposto, nessun testo vuoto e lo stesso tipo (testo o lista); l'elenco delle liste può avere un numero diverso di frasi, perché le frasi dei bot si adattano al carattere. Il messaggio d'errore dice quali id mancano (`tool/src/content_parity.dart`). `opening_names.json` è escluso per l'inglese (`_notNeeded`).

## Aggiungere una lingua

Creare `lib/l10n/<codice>/` con tutti i file e le chiavi delle altre lingue e rigenerare con `dart tool/l10n.dart`. Va poi dichiarata in `tool/lingue.json` e aggiunta a `AppLanguage` (`lib/settings/app_language.dart`), a `res/xml/locales_config.xml`, a `CFBundleLocalizations` in `ios/Runner/Info.plist` e con un `InfoPlist.strings` in `ios/Runner/<lingua>.lproj/`; la scelta compare nelle Impostazioni e `resolveAppLocale` la riconosce.

## Turco

Il turco (`tr`, «Türkçe») ha `lib/l10n/tr/*.arb` e `assets/content/tr/*.json`, gli stessi file e le stesse chiavi delle altre lingue. Stato in `tool/lingue.json`: `in lavorazione` finché la traduzione non è completa e riletta. È registrato in `AppLanguage`, `locales_config.xml`, `CFBundleLocalizations` (iOS e macOS) e `ios/Runner/tr.lproj/InfoPlist.strings`. Il turco non ha genere grammaticale: nei nomi delle aperture le forme maschile e femminile coincidono. `test/l10n_turkish_test.dart` verifica chiavi, segnaposto, testi vuoti e plurali. Termini e stile: [glossario](glossario-scacchistico.md#turco).

## Schermate migrate

| Schermata | File | Testi rimasti nel codice |
|---|---|---|
| Impostazioni | `lib/settings/settings_page.dart`, `lib/settings/section_pages.dart`, `lib/settings/settings_widgets.dart`, `lib/settings/settings_labels.dart`, `lib/settings/board_preview.dart` (`settings.arb`) | Nessuno; i nomi dei set di pezzi sono nomi propri, e «Livello N» / «Traguardo …» dei requisiti di sblocco arrivano da `Requirement.label` (`lib/progress/rewards.dart`) |
| Backup e ripristino | `lib/backup/backup_page.dart`, `lib/backup/backup.dart` | Nessuno; gli errori di `Backup.decode` sono codici (`BackupProblem`) tradotti dalla pagina |
| Elenco dei minigiochi | `lib/minigames/minigames_page.dart` | Nessuno; titoli e descrizioni dei minigiochi sono nei file `.arb` |
| Coordinate a tempo, Cattura tutto, Alla cieca, Conta del materiale | `lib/minigames/*_page.dart` | Nessuno; domande, risposte e istruzioni dei quiz e di Cattura tutto sono in `minigames.arb` |
| Editor di posizione (prefisso `editor`) | `lib/editor/position_editor_page.dart` | Nessuno; titolo, comandi, avvisi e motivi per cui la posizione non si gioca sono in `editor.arb` |
| Le tue aperture | `lib/openings/personal_explorer_page.dart`, voce nella scheda Aperture (`personal…`) | Nessuno; i nomi delle aperture arrivano dal libro e sono tradotti nel codice |
| Scacchiera fisica (partita, foto e allineamento, voce in «Tu», prefisso `physical`) | `lib/physical/physical_game_page.dart`, `lib/physical/board_align_page.dart` | Nessuno; il nome del file PGN e l'intestazione `Site` restano in italiano |
| Scheda Tu (intestazione del gruppo, voci, «Continua da dove eri», prefisso `you`) | `lib/home/you_page.dart` | Nessuno; titoli e sottotitoli di Storia, Multigiocatore e Scacchiera fisica restano nei loro file `.arb` |
| Partita, barra e menu, foglio «Nuova partita», scelta dell'avversario, varianti, frasi lette dal lettore di schermo (`game.arb`) | `lib/game/game_page.dart`, `lib/game/opponent_picker.dart`, `lib/game/variant.dart`, `lib/game/move_speech.dart` | Nessuno; nomi dei giocatori, intestazioni PGN e messaggi di debug non sono tradotti. `describeSan` e `statusText` ricevono `AppLocalizations` dal chiamante |
| Home (`home.arb`, `you.arb`) | `lib/home/*.dart` | Nessuno; i messaggi di debug (`// l10n-ok`) non sono mostrati |
| Profilo, traguardi, sfide, serie, record, promemoria | `lib/progress/profile_page.dart`, `lib/progress/achievements_l10n.dart`, `lib/progress/streak_info.dart`, `lib/reminders/reminder.dart` (`progress.arb`) | Nessuno; `Minigame.title` resta nel suo enum |
| Revisione della partita, barra di valutazione, commenti dell'allenatore | `lib/review/review_page.dart`, `lib/review/review_l10n.dart`, `lib/review/coach.dart`, `lib/review/eval_bar.dart`, `lib/review/score_format.dart` (`review.arb`) | Nessuno; `CoachComment.text(l)` compone la frase quando serve, `MoveClass` e `GamePhase` non hanno più etichette |
| Nomi di avatar e cornici | `lib/progress/avatar_l10n.dart` (`avatar.arb`, prefissi `avatarName` e `avatarFrame`) | Nessuno; `Avatar` e `AvatarFrame` non hanno più etichette, i nomi dei personaggi sono nomi propri uguali in ogni lingua tranne «Gatto astronauta» e «Coniglio lunare» |
| Famiglie di cadenze (Bullet, Blitz, Rapid) | `lib/game/clock_l10n.dart` (`clock.arb`, prefisso `clockCategory`) | Nessuno; `TimeControl.category` restituisce un `TimeCategory`, mentre `TimeControl.label` (`5+0`) è un identificativo senza testo |
| Nomi di temi, sfondi, suoni e velocità delle animazioni | `lib/settings/settings_labels.dart` (`settings.arb`, `style.arb`) | Nessuno; le enum di `lib/settings/settings.dart` non hanno più etichette italiane. Fa eccezione `PieceStyle.label`, nome proprio del set |
| Suggerimenti dell'allenatore | `lib/coach/hint_text.dart` (`coach.arb`, prefisso `coachHint`) | Nessuno |
| Analisi | `lib/analysis/analysis_page.dart` (`analysis.arb`) | Nessuno |
| Archivio delle partite | `lib/archive/archive_page.dart` (`archive.arb`) | Nessuno; il tipo di partita (`SavedGame.mode`) resta un identificativo, mostrato tradotto |
| Scheda «La tua settimana» | `lib/stats/portrait_page.dart` (`stats.arb`, prefisso `portrait`) | Nessuno; il nome del file immagine resta in italiano |
| Statistiche | `lib/stats/stats_page.dart` | Nessuno; il bilancio `+V =P -S` (`Score.toString` in `stats.dart`) è un simbolo e i nomi delle cadenze e delle aperture sono dati dell'archivio, non frasi |

## Testi da spostare

Sono già migrati anche repertorio, esploratore e hub delle aperture (`openings.arb`), allenatore dei finali (`endgames.arb`), tornei (`tournament.arb`), guida delle modalità e nomi dei temi dei puzzle (`puzzles.arb`). Non restano più testi italiani fissi nel codice: `tool/stringhe_fisse_base.json` è vuoto e il controllo non può farlo risalire. Lezioni, partite dei maestri, frasi dei bot e allenatore dei finali stanno in `assets/content/<lingua>/`.

Nei test e2e non si usa `tester.pageBack()`, che cerca il tooltip inglese "Back": si tocca il tooltip restituito da `MaterialLocalizations.of(context).backButtonTooltip`.

I test dei widget che montano una singola schermata devono usare `localizedApp` di `test/localized_app.dart` (cioè `AppLocalizations.localizationsDelegates` e `locale: Locale('it')`), come l'app reale.

La migrazione dei testi verso i file `.arb` si fa una schermata alla volta. I nomi delle aperture sono in `assets/content/<lingua>/opening_names.json` e li compone `localOpeningName` (`lib/openings/opening_names.dart`).

## Cambio di lingua

La lingua si applica subito, senza riavviare. `HomeShell` ascolta il cambio di lingua (`didChangeDependencies`) e riprogramma il promemoria: titolo, testo e, su Android, nome e descrizione del canale di notifica (ricreato con lo stesso id) passano alla nuova lingua. La notazione delle mosse è indipendente dalla lingua (predefinita figurativa, vedi [notazione.md](notazione.md)); le sue etichette nelle Impostazioni sono tradotte.

Nei test dei widget il telefono è simulato in italiano (`test/support/italian_device.dart`, collegato dai `flutter_test_config.dart` e dai test e2e), così non dipendono dalla lingua della macchina o dell'emulatore.

## Portoghese del Brasile

- Codice `pt`: tutta l'app risolve le lingue per codice di lingua (contenuti, notifiche, scelta del sistema), quindi il portoghese è registrato come `pt` e scritto per il Brasile (pt-BR). Un telefono in portoghese europeo riceve quindi la traduzione brasiliana; una variante europea futura richiederebbe di distinguere anche la regione. Nei plurali si usa `=1{…}` e non `one{…}`, perché in portoghese `one` comprende anche lo zero («0 minutos»).
- Testi in `lib/l10n/pt/*.arb` (stesse chiavi dell'italiano) e contenuti in `assets/content/pt/*.json` (percorso, finali, maestri, bot, nomi delle aperture, questi ultimi composti con i generi e gli aggettivi portoghesi).
- Registrazione: `AppLanguage.portuguese`, `tool/lingue.json`, `android/app/src/main/res/xml/locales_config.xml`, `CFBundleLocalizations` e `ios/Runner/pt.lproj/InfoPlist.strings` (anche nel progetto Xcode).
- Regole di stile e termini: [glossario-portoghese.md](glossario-portoghese.md): você, virgolette “…”, plurali `one`/`other`, notazione R D T B C.
- Test: `test/l10n/lingua_pt_test.dart` (chiavi, argomenti, plurali e due schermate campione) e, per i contenuti, il test di parità dei contenuti per lingua.
## Francese

- Pacchetto: 38 file `.arb` in `lib/l10n/fr/` (1902 chiavi) e cinque contenuti in `assets/content/fr/`; `test/l10n/content_parity_test.dart` li confronta con l'italiano (`_checked`).
- Registrazione: `AppLanguage.french`, `tool/lingue.json`, `locales_config.xml`, `CFBundleLocalizations` e `ios/Runner/fr.lproj/InfoPlist.strings` (anche in `project.pbxproj`), cartella nelle risorse di `pubspec.yaml`.
- Stile: francese di Francia, «tu»; virgolette « … » con spazio non separabile, spazio sottile non separabile prima di `;` `!` `?`, spazio non separabile prima di `:`. Nei plurali `one` copre 0 e 1, per questo il ramo `one` usa `{count}`.
- `test/l10n/french_screens_test.dart` monta partita, Impostazioni e una tappa del Percorso in francese.
- Voci del glossario da confermare per il francese: «mat du fou», «Roi/Dame» dei gambetti (`Gambit roi`, `Gambit dame`), «Toi» per la scheda Tu, «bouclier/gel de série» e «Challenger».

## Spagnolo

- Codice `es`: spagnolo neutro, senza regionalismi; un telefono in qualunque variante dello spagnolo riceve questa traduzione.
- Testi in `lib/l10n/es/*.arb` (stesse chiavi dell'italiano, plurali `one`/`other`). Stato `beta` in `tool/lingue.json`: passa a `pronta` quando arrivano anche i contenuti in `assets/content/es/*.json` (percorso, finali, maestri, bot, nomi delle aperture).
- Registrazione: `AppLanguage.spanish`, `tool/lingue.json`, `android/app/src/main/res/xml/locales_config.xml`, `CFBundleLocalizations` (iOS e macOS) e `ios/Runner/es.lproj/InfoPlist.strings` (anche nel progetto Xcode).
- Regole di stile e termini: [glossario-scacchistico.md](glossario-scacchistico.md), colonna Español: tú, virgolette «…», `¿…?` e `¡…!` sempre aperti e chiusi, notazione R D T A C.
- Scelte da confermare nella rilettura: «insignia» (badge), «marco» (cornice dell'avatar), «Rápidas» (Rapid), «subpromoción», «puntuación» (rating), «etapa» (tappa), «protector de racha» (streak freeze), «Muy buena» (Great), «ventaja» (handicap) e «computadora» per il computer.
- Test: `test/l10n/lingua_es_test.dart` (chiavi, argomenti, plurali, segni `¿¡` in coppia e schermate campione su tre dimensioni di telefono).
## Polacco

Lingua `pl`, registrata in `tool/lingue.json`, `AppLanguage.polish` («Polski»), `locales_config.xml`, `CFBundleLocalizations`, `ios/Runner/pl.lproj/InfoPlist.strings` e nel progetto Xcode. File: `lib/l10n/pl/*.arb` (stesse chiavi dell'italiano) e `assets/content/pl/*.json`. Termini e regole di stile in [glossario-polacco.md](glossario-polacco.md).

Il polacco ha quattro forme di plurale: ogni `plural` ICU di `lib/l10n/pl/` deve avere `one`, `few`, `many` e `other` (senza clausole `=1` sovrapposte a `one`). `test/l10n_pl_test.dart` controlla chiavi, segnaposto, le quattro forme, la scelta della forma per 1, 2-4, 5-21 e 22-24, e monta partita e Impostazioni su tre dimensioni di telefono.
## Indonesiano

L'indonesiano (`id`, nome nella scelta «Bahasa Indonesia») ha tutti gli `.arb` in `lib/l10n/id/` (i contenuti lunghi di lezioni, maestri e bot seguiranno in una PR a parte). Regole di stile e termini sono nella sezione «Indonesiano» di [glossario-scacchistico.md](glossario-scacchistico.md). Lo stato in `tool/lingue.json` è `beta` finché un madrelingua non ha riletto i testi; poi passa a `pronta`. La lingua è registrata in `AppLanguage`, `locales_config.xml`, `CFBundleLocalizations` e `ios/Runner/id.lproj/InfoPlist.strings`. `test/l10n_indonesian_test.dart` controlla chiavi, segnaposto, plurali, testi vuoti e due schermate campione.

## Olandese

- Codice `nl`, olandese dei Paesi Bassi, si dà del «je». Testi in `lib/l10n/nl/*.arb` (stesse chiavi dell'italiano) e contenuti in `assets/content/nl/*.json`.
- Registrazione: `AppLanguage.dutch`, `tool/lingue.json`, `android/app/src/main/res/xml/locales_config.xml`, `CFBundleLocalizations` su iOS e macOS e `ios/Runner/nl.lproj/InfoPlist.strings` (anche nel progetto Xcode).
- Regole di stile e termini: [glossario-nl.md](glossario-nl.md): virgolette “…”, plurali `one`/`other`, notazione K D T L P.
- Nomi delle aperture: la composizione dei nomi delle aperture pone il sostantivo prima del complemento; in olandese le varianti composte risultano meno naturali («variant Najdorf» invece di «Najdorf-variant»), limite noto. `grammar.feminine` contiene un segnaposto `-` perché l'olandese non ha genere grammaticale per questo uso e il test di parità non ammette liste vuote.
- Test: `test/l10n/lingua_nl_test.dart` (chiavi, argomenti, plurali e due schermate campione).

## Tedesco

- Codice `de`, stato «in lavorazione» in `tool/lingue.json`: tutti i `.arb` in `lib/l10n/de/` e i contenuti lunghi in `assets/content/de/`; la rilettura madrelingua è ancora da fare.
- Registrazione: `AppLanguage.german`, `locales_config.xml`, `CFBundleLocalizations`, `ios/Runner/de.lproj/InfoPlist.strings` (anche nel progetto Xcode), cartella nelle risorse di `pubspec.yaml`.
- Termini e regole di stile: [glossario-tedesco.md](glossario-tedesco.md). Test: `test/l10n/lingua_de_test.dart` e il test di parità dei contenuti.

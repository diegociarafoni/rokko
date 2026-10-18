# Home e scheda Impara

La Home (`lib/home/home_page.dart`) è la prima scheda: risponde a «cosa faccio adesso?» e porta a ogni funzione con un tocco. Usa solo dati che l'app ha già, senza funzioni online. I testi sono in `lib/l10n/<lingua>/home.arb`.

## Barra

Home, Puzzle, Impara, Tu. La scacchiera non è una scheda: il grande pulsante «Nuova partita», fisso in basso nella Home, apre la partita con la scelta di avversario e tempo già aperta (`GamePage.openSetup`). Le partite si salvano a ogni mossa, quindi chiudere la scacchiera non perde nulla e la Home propone di riprenderla.

## Cosa mostra la Home

1. **In alto**: avatar (porta al Profilo), serie e livello, impostazioni.
2. **Ricerca** «Cerca una funzione»: filtra per nome e parole chiave, senza badare a maiuscole e accenti (`searchFeatures`).
3. **Prossimo passo per te**: una sola scheda grande, scelta in quest'ordine (`chooseNextStep`): la partita lasciata a metà, la prossima lezione della Storia con il custode del capitolo e l'avanzamento, il puzzle del giorno.
4. **Avversario consigliato**: il bot più forte, tra quelli sbloccati, che non supera di più di 100 Elo la valutazione locale (`recommendedBot`). Un tocco apre «Nuova partita» con quel bot già scelto, così la vittoria sblocca il successivo. Senza motore non compare.
5. **Funzioni a un tocco**, in gruppi: Gioca (contro un bot, amico, tornei, scacchiera fisica), Impara (Storia, Aperture, Finali, Grandi maestri), Allenati (puzzle del giorno, tutti i puzzle, minigiochi), I tuoi progressi (statistiche, badge, archivio, la tua settimana). Le funzioni non disponibili, per esempio i tornei senza motore, non compaiono.
6. **Statistiche**: valutazione locale, serie, badge sbloccati.
7. **Ultime partite**: le tre più recenti concluse con l'avversario, l'esito e la precisione se la revisione l'ha già calcolata; un tocco apre la partita nella revisione.

I dati arrivano uno alla volta: la Home si disegna subito e si completa man mano. Tornando da una schermata aperta dalla Home, i dati si rileggono.

## Impara

`lib/home/learn_page.dart`: in testa «Continua da dove eri» (la Storia), poi Storia, Aperture, Finali, Grandi maestri e Minigiochi. Le Aperture si aprono da qui e dalla Home.

## Guida alla prima apertura

Ogni scheda e la Home hanno una guida a passi la prima volta che si aprono (vedi [guida-all-uso.md](guida-all-uso.md)).

## Profilo bambino

Niente ricerca, avversario consigliato, statistiche e ultime partite; il pulsante dice «Giochiamo!». Mancano contro un bot, amico, tornei, scacchiera fisica, Aperture, statistiche, badge e archivio (vedi [profilo-bambino.md](profilo-bambino.md)).

## Accessibilità e prove

Bersagli da 48 dp, etichette per i lettori di schermo, griglia che segue il testo ingrandito. I test sono in `test/home/home_logic_test.dart` (logica), `home_page_test.dart` (schermata, testo al 130% e 200%, accessibilità), `home_nav_test.dart` (barra e navigazione) e i golden in `test/golden/home_golden_test.dart` su tre telefoni, tema scuro, testo al 130% e profilo bambino.

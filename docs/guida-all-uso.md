# Guida all'uso alla prima apertura

Requisito RP-10: la prima volta che si apre una schermata compare una breve guida che ne spiega le funzioni. Si può saltare in ogni momento. Il codice è in `lib/guide/`, i testi in `lib/l10n/<lingua>/guide.arb`, in tutte le lingue dell'app.

## Come funziona

- **Passi.** Un passo evidenzia un elemento reale della schermata (sfondo oscurato con un foro attorno all'elemento) e lo spiega in una frase. In basso «Salta» e «Avanti» (all'ultimo passo «Fine»), con il contatore `2/5`. Un elemento che non c'è, per esempio la ricerca nel profilo bambino o il suggerimento contro un amico, salta il passo. Se i dati arrivano dopo l'apertura (la scheda dei puzzle, la Home) i passi si aggiungono man mano.
- **Una guida per schermata.** `GuideHost` avvolge la schermata e ne elenca i passi (`lib/guide/guide_steps.dart`); `GuideAnchor` segna gli elementi da evidenziare. Partono quando la schermata è davanti, visibile (le schede della barra aspettano di essere aperte) e finita di animarsi, e solo se c'è un `GuideScope` sopra il Navigator (lo mette `lib/main.dart`: nei test e nelle anteprime non compare nulla).
- **Saltabile.** «Salta», il tasto indietro e l'ultimo «Fine» chiudono la guida e la danno per vista. I tocchi sotto la guida non arrivano alla schermata.
- **Stato salvato.** `GuideController` (`lib/guide/guide_controller.dart`) salva nelle preferenze locali le schermate già viste (`guideSeen`) e l'interruttore generale (`guideEnabled`). Nulla lascia il telefono.
- **Impostazioni → Accessibilità.** «Guide alla prima apertura» le attiva o le spegne tutte; «Rivedi le guide» azzera le viste.
- **Profilo bambino.** Dove serve il passo ha una frase più semplice (Home, scacchiera); gli elementi che il profilo nasconde non compaiono.
- **Accessibilità.** Il testo del passo è una regione viva e la guida blocca la semantica della schermata sotto (`BlockSemantics`): il lettore di schermo legge solo la guida. Contrasto e colori seguono il tema chiaro o scuro; con il testo ingrandito il testo scorre e i pulsanti restano visibili; la scheda va dalla parte dell'elemento con più spazio.

## Schermate coperte

| Schermata | Identificativo | Passi |
|---|---|---|
| Home | `home` | avatar, impostazioni, ricerca, prossimo passo, funzioni, statistiche, «Nuova partita», barra |
| Puzzle | `puzzles` | puzzle del giorno, allenamento, modalità a tempo |
| Impara | `learn` | continua, Storia, Aperture, Grandi maestri, Minigiochi |
| Tu | `you` | livello e serie, prossimo passo, dati |
| Impostazioni | `settings` | ricerca e sezioni |
| Scelta della partita | `newGame` | tempo, avvio rapido, amico, bot |
| Partita | `game` | scacchiera, mosse, suggerimento, annulla, gira, nuova, patta, abbandona, altro |
| Storia | `story` | cammino, capitolo, «Continua» |

Restano fuori, da aggiungere con lo stesso meccanismo: l'esecuzione dei puzzle (ha già la sua spiegazione di modalità, `lib/puzzles/mode_guide.dart`), Aperture, Finali, Grandi maestri, Minigiochi, Tornei, Statistiche, Badge, Archivio, Analisi, Revisione, Editor di posizione, Gioca con un amico, Scacchiera fisica, Stile e le sezioni delle Impostazioni.

## Aggiungere una guida

1. Avvolgere la schermata in `GuideHost(screen: 'id', steps: ..., child: ...)` e gli elementi in `GuideAnchor(id: 'id.elemento', child: ...)`.
2. Elencare i passi in `lib/guide/guide_steps.dart`, con i testi in `lib/l10n/<lingua>/guide.arb` per ogni lingua (`dart tool/l10n.dart`).
3. Aggiungere la schermata alla tabella qui sopra.

## Prove

`test/guide/`: controller, meccanismo (partenza, salto dei passi assenti, «Salta», tasto indietro, assenza di `GuideScope`, tocchi bloccati, testo al 200%, semantica), schermate reali (Home, schede, profilo bambino, Impostazioni, scelta della partita, partita, Storia) e le traduzioni in ogni lingua. I golden `test/golden/guide_golden_test.dart` coprono la Home su telefono medio e piccolo (anche scuro, testo al 130%, profilo bambino). Le prove dell'app intera spengono le guide (`GuideController.defaultEnabled` in `test/flutter_test_config.dart`, `guideEnabled` nelle preferenze delle prove di integrazione).

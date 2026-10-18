# Mappa del codice

Ogni cartella di `lib/` ha qui il documento che descrive le sue funzioni. La tabella è controllata in automatico da `tool/check_docs.dart`: una cartella nuova senza riga, o una riga per una cartella che non esiste più, fa fallire il controllo.

## Cartelle e documenti

| Cartella | Documenti | Funzioni |
|---|---|---|
| `lib/analysis/` | [analisi.md](analisi.md) | Analisi libera della posizione con le linee del motore e l'albero delle varianti |
| `lib/about/` | [licenza.md](licenza.md), [interfaccia.md](interfaccia.md) | Schermata «Informazioni»: licenza, sorgenti, privacy e crediti |
| `lib/archive/` | [archivio.md](archivio.md) | Archivio delle partite, import ed export PGN |
| `lib/badges/` | [badge.md](badge.md) | Badge (RG-17) e libri delle aperture: catalogo, regole di sblocco, medaglie, galleria, testi |
| `lib/bot_gallery/` | [bot.md](bot.md) | Galleria dei bot (RG-18): fasce per Elo, saluti localizzati, scelta di colore e avversario |
| `lib/backup/` | [backup.md](backup.md) | Backup e ripristino dei dati locali |
| `lib/coach/` | [allenatore.md](allenatore.md) | Partita con l'allenatore: avvisi, ripresa della mossa, suggerimenti |
| `lib/editor/` | [editor-posizione.md](editor-posizione.md) | Editor di posizione e FEN |
| `lib/endgames/` | [finali.md](finali.md) | Allenatore dei finali: posizioni teoriche, esito, stelle, ripetizione |
| `lib/engine/` | [avversario-computer.md](avversario-computer.md), [bot.md](bot.md) | Motore Stockfish, livelli, bot con personalità |
| `lib/exchange/` | [scambio-qr.md](scambio-qr.md) | Scambio di partite tra telefoni con il QR, senza rete |
| `lib/game/` | [regole-di-gioco.md](regole-di-gioco.md), [interfaccia.md](interfaccia.md), [avversario-computer.md](avversario-computer.md) | Stato della partita, varianti, orologio, suoni, schermata di gioco |
| `lib/guide/` | [guida-all-uso.md](guida-all-uso.md) | Guida alla prima apertura di ogni schermata: passi evidenziati, «Salta», stato salvato |
| `lib/home/` | [home.md](home.md), [interfaccia.md](interfaccia.md), [architettura.md](architettura.md) | Barra di navigazione, Home, scheda Impara e scheda Tu |
| `lib/kids/` | [profilo-bambino.md](profilo-bambino.md) | Profilo bambino senza numeri |
| `lib/l10n/` | [localizzazione.md](localizzazione.md) | Testi tradotti |
| `lib/masters/` | [grandi-maestri.md](grandi-maestri.md) | Partite dei grandi maestri: raccolta, commento, «Indovina la mossa» |
| `lib/minigames/` | [minigiochi.md](minigiochi.md) | Minigiochi di allenamento |
| `lib/multiplayer/` | [multigiocatore.md](multigiocatore.md) | Partita tra due telefoni: invito, firma e cifratura, registro delle mosse, canali, schermata «Gioca con un amico» |
| `lib/openings/` | [aperture.md](aperture.md) | Nomi delle aperture, explorer, repertorio |
| `lib/path/` | [percorso.md](percorso.md) | Percorso a tappe con stelle e guardiani |
| `lib/physical/` | [scacchiera-fisica.md](scacchiera-fisica.md) | Orologio e registro per la scacchiera reale |
| `lib/progress/` | [gamification.md](gamification.md) | XP, livelli, obiettivo giornaliero, serie, traguardi, ricompense |
| `lib/puzzles/` | [puzzle.md](puzzle.md) | Puzzle, modalità a tempo, sfida a tempo tra amici, ripasso degli errori |
| `lib/reminders/` | [gamification.md](gamification.md) | Promemoria giornaliero con notifiche locali |
| `lib/review/` | [revisione-partita.md](revisione-partita.md) | Revisione della partita, classificazione delle mosse, precisione |
| `lib/settings/` | [interfaccia.md](interfaccia.md), [pezzi-e-scacchiere.md](pezzi-e-scacchiere.md), [notazione.md](notazione.md), [profilo-bambino.md](profilo-bambino.md) | Impostazioni, temi e pezzi, coordinate esterne, colori per daltonici, controllo dell'adulto |
| `lib/share/` | [esporta-immagine.md](esporta-immagine.md) | Esportazione della posizione come immagine PNG e condivisione con il menu di sistema |
| `lib/stats/` | [statistiche.md](statistiche.md), [ritratto-settimana.md](ritratto-settimana.md) | Statistiche, rating locale, la tua settimana |
| `lib/theme/` | [interfaccia.md](interfaccia.md) | Tema Rokko spaziale: indaco e viola, token di stile, marchio nella barra del titolo |
| `lib/storage/` | [persistenza.md](persistenza.md), [architettura.md](architettura.md), [gamification.md](gamification.md) | File JSON locali con versione, migrazioni e scrittura atomica |
| `lib/story/` | [storia.md](storia.md) | Percorso a storia: capitoli con racconto, lezioni, puzzle, guardiani e un bot da battere |
| `lib/tablebase/` | [finali-perfetti.md](finali-perfetti.md) | Finali perfetti: tabelle del matto esatto fino a quattro pezzi, generate sul telefono, scheda con risultato e mossa perfetta |
| `lib/style/` | [stile.md](stile.md) | Schermata Stile: anteprima dal vivo e schede Scacchiera, Pezzi, Sfondo (con foto propria) e Suoni |
| `lib/summary/` | [riepilogo-settimanale.md](riepilogo-settimanale.md) | Riepilogo settimanale: progressi, errore ricorrente, un consiglio |
| `lib/tournament/` | [tornei.md](tornei.md) | Tornei offline contro bot, con partite tra bot giocate dal motore |
| `lib/training/` | [puzzle.md](puzzle.md) | Scacchiera per esercizi condivisa |

## Controllo automatico

`dart tool/check_docs.dart`, lanciato dalla radice del repository, verifica:

- i link relativi nei file Markdown di `docs/` e della radice: file esistente e, se c'è, ancora corrispondente a un titolo;
- i percorsi citati tra apici inversi sotto `lib/`, `test/`, `tool/`, `docs/`, `assets/`, `.github/` e nelle cartelle delle piattaforme (segnaposto come `<codice>` e glob esclusi);
- che ogni documento di `docs/` compaia nell'indice di [README.md](README.md);
- che ogni cartella di `lib/` abbia una riga in questa tabella, con almeno un documento.

Il controllo gira in `tool/verifica.sh` e nel workflow Convenzioni su ogni PR, comprese quelle che toccano solo la documentazione. Le regole sono in `tool/src/docs_check.dart`, i test in `test/tool/docs_check_test.dart`.

Chi aggiunge una cartella in `lib/` aggiunge la riga qui e descrive la funzione nel documento indicato. Una verifica serale confronta inoltre la documentazione con le PR unite nel giorno e propone le correzioni con una PR `docs:`.

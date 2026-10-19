# Rokko

Rokko è un'applicazione di scacchi offline, open source e completamente gratuita, per Android, iOS e desktop (Windows, macOS, Linux). Nessuna pubblicità, nessun account, nessun dato che lascia il dispositivo: fa eccezione solo la partita con un amico su un altro telefono, facoltativa, in cui le mosse viaggiano cifrate.

## Stato

- Home a dashboard con il prossimo passo, la ricerca delle funzioni e l'accesso a ogni sezione; foglio «Nuova partita» con la galleria dei bot;
- partita tra due persone sullo stesso dispositivo, oppure su due telefoni in Wi-Fi, Bluetooth o a distanza;
- mosse per trascinamento o con due tocchi, evidenziazione delle mosse legali, dell'ultima mossa e dello scacco;
- promozione con scelta del pezzo;
- fine partita: scacco matto, stallo, materiale insufficiente, triplice ripetizione, regola delle 50 mosse, patta concordata, abbandono;
- annullamento delle mosse, nuova partita, lista delle mosse in notazione algebrica (figurativa, italiana o inglese);
- capovolgimento della scacchiera, anche automatico a ogni turno;
- partita contro il computer (Stockfish sul dispositivo: Android e iOS, e Windows e Linux con Stockfish installato) con 8 livelli, bot con personalità, avversario adattivo, allenatore, varianti (Chess960, Re della collina, Tre scacchi) e partite a handicap;
- orologio con cadenze, modalità zen, archivio delle partite con import ed export PGN, ripresa della partita interrotta, revisione e analisi della partita con varianti e note sulle mosse;
- puzzle (a tempo, corsa, sopravvivenza, serie, ripasso, sfida tra amici), aperture con esploratore e repertorio, percorso a tappe e a storia con i guardiani, allenatore dei finali e finali perfetti, partite dei grandi maestri, minigiochi, tornei contro i bot;
- gamification con XP, serie, traguardi e badge, riepilogo settimanale, statistiche e rating locale, profilo bambino;
- schermata Stile (pezzi, scacchiera, sfondo, suoni), impostazioni a sezioni, guida alla prima apertura delle schermate, tema chiaro o scuro, colori per daltonici, lingua dell'app (italiano, inglese, portoghese del Brasile, francese, spagnolo, tedesco, polacco, indonesiano, russo, olandese e turco);
- editor di posizione, posizione come immagine, scambio di partite con il QR, scacchiera fisica, backup e ripristino dei dati.

Lo stato di ogni funzione è in [docs/README.md](docs/README.md#stato-del-progetto).

## Documentazione

La documentazione completa è in [docs/](docs/README.md): architettura, funzioni, sviluppo, CI, sicurezza, rilascio e licenza. La [mappa del codice](docs/mappa-del-codice.md) collega ogni cartella di `lib/` al suo documento.

## Licenza

GPL-3.0, vedi [LICENSE](LICENSE), con un permesso aggiuntivo per la pubblicazione sugli store (vedi [NOTICE.md](NOTICE.md)). Le risorse di terze parti sono elencate in [CREDITS.md](CREDITS.md).

# Dipendenze e licenze

## Aggiornamenti

[Dependabot](../.github/dependabot.yml) apre ogni settimana PR per pacchetti pub, azioni GitHub e Gradle. Gli aggiornamenti sono raggruppati, di norma, in una sola PR settimanale per ecosistema (pub, azioni GitHub compresa l'azione locale in `.github/actions/`, Gradle), qualunque sia il tipo di salto. Se un salto maggiore rompe la CI, blocca l'intera PR del gruppo: va escluso o corretto a mano. Gli avvisi di sicurezza restano fuori dai gruppi (i gruppi non usano `applies-to`) e arrivano come PR separate, senza attendere la settimana. I messaggi rispettano la convenzione Angular (`build(deps): …`, `ci(deps): …`) e passano gli stessi controlli di ogni altra PR.

Dependabot propone solo versioni pubblicate da almeno 7 giorni (`cooldown`): un pacchetto compromesso viene di solito scoperto e ritirato prima di allora. Gli aggiornamenti di sicurezza non hanno questa attesa. Le dipendenze Ruby di Fastlane (`Gemfile.lock`) non sono coperte da Dependabot e si aggiornano a mano.

## Licenze

L'app è GPL-3.0 (vedi [licenza.md](licenza.md)), quindi ogni dipendenza distribuita con l'app deve avere una licenza compatibile. `tool/check_licenses.dart` controlla in CI (dopo `flutter pub get`) tutte le dipendenze non di sviluppo, dirette e indirette, riconoscendo la licenza dal testo del file `LICENSE` di ciascun pacchetto.

Licenze ammesse, in `tool/policy.json`: MIT, BSD-2-Clause, BSD-3-Clause, Apache-2.0, ISC, Zlib, Unlicense, MPL-2.0, LGPL-2.1, LGPL-3.0, GPL-3.0.

Una licenza non riconosciuta o non ammessa blocca la CI. Se il riconoscimento automatico sbaglia, si aggiunge il pacchetto in `licenses.overrides` di `tool/policy.json` con l'identificativo SPDX corretto, dopo averne letto la licenza.

```sh
dart run tool/check_licenses.dart
```

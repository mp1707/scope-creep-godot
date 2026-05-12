# Scope Creep - PoC3-Plan

Dieses Dokument ist der Arbeitsplan fuer den dritten aussagekraeftigen Playtest-Slice in Godot 4.6. Es baut auf `poc3-idee.md`, `poc2-plan.md`, `architecture.md` und `gdd.md` v1.4 auf.

PoC3 ist kein Rewrite. Der bestehende PoC2 bleibt die technische Basis. Ziel ist, aus dem bisher offenen Kernloop einen kleinen vollstaendigen Mini-Run zu machen:

```text
MVP bauen -> Launch entscheiden -> Kunden bedienen -> Business Goals schaffen
```

Der Plan bleibt bewusst phasenweise und abhakbar. Jede Phase ist so geschnitten, dass sie in einer Codex-Context-Session sinnvoll umgesetzt, getestet und kurz im Editor gegengeprueft werden kann. Editor-Arbeit ist dort explizit markiert, wo visuelle Abstimmung oder Scene-/Inspector-Pflege sauberer ist als Textdatei-Automation.

## Fortschritt

- [x] Phase 0 - Baseline sichern und PoC3-Scope einfrieren
- [x] Phase 1 - Run-Metadaten und Software-Status vorbereiten
- [x] Phase 2 - Feature-Integration statt direkter Software-Einnahmen
- [x] Phase 3 - Freelance-Finanzierung vor Launch
- [x] Phase 4 - Manueller Launch und Startkunden
- [x] Phase 5 - Kundenwirtschaft nach Launch
- [x] Phase 6 - Kundendruck und Unzufriedenheit
- [x] Phase 7 - Business Goals, Investorenpanik und PoC3-Endzustand
- [x] Phase 8 - Booster-/Shop-Scope fuer PoC3
- [x] Phase 9 - Save/Load, Validation und Migration auf Content-Version `poc3`
- [ ] Phase 10 - Balancing, Playtest-Script und QA
- [ ] Stretch - Kundenwachstum durch zusaetzliche Live-Features

## PoC3-Ziel

Am Ende von PoC3 soll ein Run mit klarer Dramaturgie spielbar sein:

1. Der Run startet als Pre-Launch-MVP mit Software `0 / 10 Features`.
2. Funktionen auf Software erzeugen vor Launch kein Geld mehr, sondern Feature-Fortschritt.
3. Der Spieler finanziert sich vor Launch hauptsaechlich ueber Freelance-Auftraege.
4. Ab 10 Features ist die Software launchbereit, Launch bleibt aber manuell.
5. Launch erzeugt Live-Software, Startkunden und das erste Business Goal.
6. Kunden erzeugen nach Launch Geld und Kundenwuensche.
7. Unbearbeitete Kundenwuensche erzeugen Unzufriedenheit.
8. Unzufriedene Kunden erzeugen kein Geld und keine Kundenwuensche, bis ein Product Owner die Erwartungen managt.
9. Business Goals konkurrieren mit Gehaeltern, Boostern und Notfallkarten um Geld.
10. PoC3 ist gewonnen, wenn 3 Business Goals erfuellt wurden.
11. Der Run ist verloren, wenn alle Mitarbeiter weg sind oder 2 Investorenpanik-Karten existieren.

## Nicht Ziel von PoC3

- Kein vollstaendiges Hiring-Rework.
- Keine Kandidaten, Interviews oder Onboarding.
- Keine neuen vollwertigen Rollen wie Support oder Designer.
- Keine mehreren Kundentypen.
- Keine Feature-Typen oder Feature-Level.
- Keine finale Booster-Balance.
- Keine Meta-Progression.
- Kein finaler Steam-Demo-Polish.
- Keine abstrakten UI-Meter fuer Kunden, Goals, Feature-Fortschritt oder Panik.
- Keine Simulation-Regeln in Presentation-Scripts.

## PoC3-Content-Scope

### Neue oder geaenderte Karten

Neu:

- `card.value_source.freelance_order` - Freelance-Auftrag
- `card.goal.business_goal` - Business Goal
- `card.problem.investor_panic` - Investorenpanik
- `card.problem.unhappy_customer` - Unzufrieden

Geaendert:

- `card.product.software` - erhaelt Runtime-Werte fuer Produktstatus und Featurezahl
- `card.value_source.customer` - wird Post-Launch-Wertquelle
- `card.input.customer_request` - wird Post-Launch-Druckkarte
- `card.output.feature` - kann ins Produkt integriert oder fuer Freelance-Geld abgegeben werden
- `card.output.checked_feature` - wie Feature, aber sauberer und wertvoller bei Freelance

### Neue oder geaenderte Runtime-Werte

Empfohlene Runtime-Werte auf der Software:

- `product_stage`: `mvp` oder `live`
- `feature_count`: int
- `mvp_required_features`: int, fuer PoC3 initial `10`
- `launch_feature_count`: int, gesetzt beim Launch
- optional `next_customer_feature_threshold`: int, nur fuer Stretch

Empfohlene Runtime-Werte auf Business Goal:

- `goal_index`: int
- `required_money`: int
- `paid_money`: int

Empfohlene Runtime-Werte auf Kundenwunsch:

- `spawned_sprint_index`: int
- optional `source_customer_instance_id`: String, erst wenn die einfache globale Variante nicht reicht

### Kernrecipes

Pre-/Post-Launch Feature-Integration:

```text
Funktion + Software -> Feature integrieren -> Software +1 Feature, optional Bug-Risiko
Gepruefte Funktion + Software -> Feature integrieren -> Software +1 Feature, kein Bug-Risiko
```

Pre-Launch Freelance:

```text
Funktion + Freelance-Auftrag -> Auftrag abliefern -> 2 Geld
Gepruefte Funktion + Freelance-Auftrag -> Sauberen Auftrag abliefern -> 3 Geld
```

Launch:

```text
Launchbereite Software + Entwickler -> Launch vorbereiten -> Live-Software + Startkunden + Business Goal
```

Kundendruck:

```text
Kunde + angeheftetes Unzufrieden + Product Owner -> Erwartungen managen -> Unzufrieden entfernen
Kundenwunsch + Entwickler -> Kundenwunsch improvisieren -> Vielversprechende User Story
```

Business Goal:

```text
Geld + Business Goal -> Goal-Fortschritt +1, Geld verbrauchen
```

## Phase 0 - Baseline sichern und PoC3-Scope einfrieren

Ziel: PoC3 beginnt auf einem stabilen PoC2-Stand, ohne versehentlich PoC2-Regeln oder User-Aenderungen zu ueberschreiben.

Codex:

- [x] `git status --short` pruefen und lokale User-Aenderungen nicht ueberschreiben.
- [x] Aktuellen PoC2-Testlauf oder die relevanten Headless-Tests ausfuehren.
- [x] Bestehende Content-IDs fuer Software, Feature, Checked Feature, Kunde, Kundenwunsch, Auftrag, Booster und Shop erfassen.
- [x] In `POC3_NOTES.md` offene Altlasten notieren, die PoC3 beeinflussen.
- [x] `architecture.md` vor PoC3 um Product Lifecycle, Goal Cards, terminale Zustaende, RuleQueryService-Queries und Sprintstart-Pipeline ergaenzen.
- [x] Entscheiden und dokumentieren, ob bestehender `card.value_source.order` unveraendert bleibt oder `freelance_order` als neue Karte angelegt wird. Empfehlung: neue Karte, damit PoC2-Auftrag und PoC3-Freelance fachlich getrennt bleiben.

Marco:

- [x] Aktuellen PoC2 im Editor starten.
- [x] Kurz bestaetigen, dass der letzte erfolgreiche Playtest-Stand weiterhin spielbar ist.
- [x] Entscheiden, ob PoC3 auf einem neuen Branch umgesetzt wird.
- [x] Scope bestaetigen: Talent-Pool bleibt im normalen PoC3-Run deaktiviert, Hiring-Rework kommt spaeter.

Definition of Done:

- [x] PoC2-Baseline ist bekannt und testbar.
- [x] PoC3-Scope ist schriftlich eingefroren.
- [x] Keine ID-Umbenennungen ohne Migration/Alias-Regel.
- [x] Offene Risiken sind dokumentiert statt still ueberbrueckt.

Headless-Check:

```bash
tools/check_poc.sh
```

Status: ausgefuehrt. Content-Validation bestanden; alte/PoC2-Tests zeigen bekannte Spawn-Placement- und Auto-Stacking-Baselinefehler. Details stehen in `POC3_NOTES.md`.

## Phase 1 - Run-Metadaten und Software-Status vorbereiten

Ziel: Die Simulation kann unterscheiden, ob der Run vor oder nach Launch ist, und die Softwarekarte zeigt Feature-Fortschritt sichtbar an.

Codex:

- [x] `RunState` oder Software-Runtime-State um den Produktstatus vorbereiten, ohne Presentation-Abhaengigkeit.
- [x] `card.product.software` initial mit `product_stage = mvp`, `feature_count = 0`, `mvp_required_features = 10` starten lassen.
- [x] CardView-/Runtime-Marker-Anzeige so erweitern, dass die Software `MVP 0/10`, `Launchbereit 10/10` oder `Live 12 Features` anzeigen kann.
- [x] Eine zentrale Query implementieren, z. B. `is_software_launch_ready()`, statt Launchbereitschaft in UI oder Recipe-Sonderlogik zu duplizieren.
- [x] Content-Version fuer neue Runs noch nicht umstellen, aber die benoetigten State-Felder save-kompatibel vorbereiten.
- [x] Headless-Test fuer Startstatus und Launchbereitschaft schreiben.

Marco:

- [x] Im Editor pruefen, ob die Softwarekarte den Runtime-Marker lesbar anzeigt.
- [x] Bei Bedarf Labelgroessen, Markerposition oder Kartentexte im Inspector/Theme abstimmen.
- [x] Keine Gameplay-Logik im CardView nachbauen; nur Anzeige pruefen.

Definition of Done:

- [x] Neuer Run startet mit Software `MVP 0/10`.
- [x] Software wird ab 10 Features als launchbereit erkennbar.
- [x] Produktstatus liegt im Simulation-State oder Card-Runtime-State, nicht im HUD.
- [x] Save-kompatible Defaultwerte sind vorbereitet.

Headless-Test:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/marcopreuss/Documents/ProjectsLocal/scope-creep-godot --script res://tests/test_poc3_phase_1_software_status.gd
```

Status: bestanden.

## Phase 2 - Feature-Integration statt direkter Software-Einnahmen

Ziel: Funktionen auf Software erzeugen keinen direkten Geldgewinn mehr, sondern sichtbaren MVP-/Live-Feature-Fortschritt. Der Qualitaetsunterschied aus PoC2 bleibt erhalten.

Codex:

- [x] Bestehende Recipes `money_from_feature_software` und `money_from_checked_feature_software` fachlich ersetzen oder fuer PoC3 deaktivieren.
- [x] Neue Integration-Recipes anlegen: `Funktion + Software -> Feature integrieren`.
- [x] Neue Integration-Recipes anlegen: `Gepruefte Funktion + Software -> Feature integrieren`.
- [x] Ungepruefte Integration darf weiterhin Bug-Risiko haben.
- [x] Gepruefte Integration hat kein Bug-Risiko.
- [x] Feature-Integration erhoeht `feature_count` um 1 und verbraucht die Feature-Karte.
- [x] Aktionstexte von `Release...` auf `Feature integrieren...` oder aehnlich umstellen.
- [x] Tests fuer Geld-Entfall, Featurezaehler, Bug-Risiko und checked/no-bug-Pfad schreiben.

Marco:

- [x] Im Editor/Playtest pruefen, ob klar ist, dass Software vor Launch kein Geld erzeugt.
- [x] Aktionstexte und Tooltip-Texte der Software/Feature-Karten sprachlich abstimmen.
- [x] Sichtbarkeit von Feature-Fortschritt bei gestapelter Software pruefen.

Definition of Done:

- [x] `Funktion + Software` erzeugt kein Geld mehr.
- [x] Featurezaehler steigt nach erfolgreichem Processing.
- [x] Ungepruefte Features koennen weiter Bugs erzeugen.
- [x] Gepruefte Features bleiben der sichere Pfad.
- [x] PoC2-Qualitaetsregeln werden nicht aus Presentation-Code dupliziert.

Headless-Test:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/marcopreuss/Documents/ProjectsLocal/scope-creep-godot --script res://tests/test_poc3_phase_2_feature_integration.gd
```

Status: bestanden.

## Phase 3 - Freelance-Finanzierung vor Launch

Ziel: Vor Launch entsteht Geld ueber sichtbare Freelance-Auftraege statt ueber die eigene Software.

Codex:

- [x] `card.value_source.freelance_order` als CardDefinition anlegen.
- [x] Recipes anlegen: `Funktion + Freelance-Auftrag -> 2 Geld`.
- [x] Recipes anlegen: `Gepruefte Funktion + Freelance-Auftrag -> 3 Geld`.
- [x] Sicherstellen, dass die Feature-Karte und der Freelance-Auftrag dabei verbraucht werden.
- [x] Sprintstart-Regel vor Launch: 1 Freelance-Auftrag spawnt.
- [x] Sprintstart-Regel nach Launch: automatischer Freelance-Zufluss endet.
- [x] Startsetup um 1 Freelance-Auftrag erweitern.
- [x] Tests fuer Startsetup, Pre-Launch-Spawn, Post-Launch-Nicht-Spawn und Geldmenge schreiben.

Marco:

- [x] Freelance-Auftrag im Editor visuell von altem Auftrag/Kundenwunsch unterscheidbar machen.
- [x] Tooltip pruefen: Entscheidung `ins Produkt integrieren` vs. `fuer Geld abgeben` muss sofort klar sein.
- [x] Im Playtest bewerten, ob Startgeld plus 1 Freelance-Auftrag zu hart oder zu weich wirkt. Aktueller Playtest-Hilfswert: 30 Startgeld.

Definition of Done:

- [x] Vor Launch gibt es regelmaessig mindestens eine Geldchance.
- [x] Freelance-Geld entsteht durch Karteninteraktion, nicht als abstrakter Tick.
- [x] Gepruefte Funktionen sind fuer Freelance wertvoller.
- [x] Nach Launch endet der automatische Freelance-Spawn.

Headless-Test:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/marcopreuss/Documents/ProjectsLocal/scope-creep-godot --script res://tests/test_poc3_phase_3_freelance.gd
```

Status: bestanden.

## Phase 4 - Manueller Launch und Startkunden

Ziel: Launch wird ein bewusster Wendepunkt, nicht ein automatischer Statuswechsel.

Codex:

- [x] Launch-Recipe anlegen: launchbereite Software + Entwickler.
- [x] Launch-Recipe darf erst ab `feature_count >= 10` matchen.
- [x] Beim Launch `product_stage` auf `live` setzen und `launch_feature_count` speichern.
- [x] Startkunden berechnen: `floor(feature_count / 5)`.
- [x] Entsprechend viele `card.value_source.customer` Karten sichtbar auf dem Board spawnen.
- [x] Direkt nach Launch erstes Business Goal spawnen, falls Phase 7 noch nicht implementiert ist ggf. als deaktivierter Platzhalter mit klarer TODO-Notiz.
- [x] Launch darf bei vorhandenen Bugs/Tech Debt nicht blockiert werden.
- [x] Tests fuer Launch bei 9/10/15 Features, Kundenanzahl und Nicht-Blockade durch Probleme schreiben.

Marco:

- [x] Launch-Aktionstext und Software-Marker im Editor/Playtest pruefen.
- [x] Pruefen, ob beim Launch gespawnte Kunden nicht unlesbar auf vorhandenen Karten liegen.
- [x] Falls das Spawn-Layout unsauber wirkt: visuelle Zielpositionen/Spawn-Abstaende abstimmen, nicht Gameplay-Regeln im Editor bauen.

Definition of Done:

- [x] Launch passiert nur manuell per Karteninteraktion.
- [x] 9 Features reichen nicht, 10 Features reichen.
- [x] Spaeterer Launch mit 15/20 Features erzeugt mehr Startkunden.
- [x] Software bleibt dieselbe sichtbare Produktkarte mit geaendertem Status, kein unsichtbarer Run-Schalter.

Headless-Test:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/marcopreuss/Documents/ProjectsLocal/scope-creep-godot --script res://tests/test_poc3_phase_4_launch.gd
```

Status: bestanden. Marco-Editor-/Playtest-Check erledigt.

## Phase 5 - Kundenwirtschaft nach Launch

Ziel: Nach Launch kommt Geld ueber Kundenkarten. Kunden erzeugen gleichzeitig Arbeit.

Codex:

- [x] Sprintstart-Regel nach Launch: jeder Kunde erzeugt 1 Geld und 1 Kundenwunsch.
- [x] Bei aktivem Prod-Crash erzeugen Kunden kein Geld.
- [x] Bei aktivem Prod-Crash erzeugen Kunden statt normalem Kundenwunsch Unzufriedenheit, sobald Phase 6 verfuegbar ist.
- [x] Sicherstellen, dass Kundengeld nicht direkt von Software erzeugt wird.
- [x] Bestehende Kundenwunsch-Recipes aus PoC2 weiterverwenden.
- [x] Tests fuer Kunden-Tick, Geldmenge, Kundenwunsch-Spawns und Prod-Crash-Blockade schreiben.

Marco:

- [x] Im Playtest pruefen, ob Kunden als Wertquelle visuell gut erkennbar sind.
- [x] Board-Layout nach Kunden-Ticks beobachten: viele Geld-/Kundenwunschkarten duerfen nicht sofort unspielbar clustern.
- [x] Tooltip fuer Kunde schaerfen: `Zahlt nach Launch, erzeugt aber Arbeit.`

Definition of Done:

- [x] 3 Kunden erzeugen am Sprintstart 3 Geld und 3 Kundenwuensche.
- [x] Prod-Crash blockiert Kundengeld hart.
- [x] Software erzeugt weiterhin kein direktes Geld.
- [x] Kundenwunsch bleibt eine echte Karte und kein unsichtbarer Bedarf.

Headless-Test:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/marcopreuss/Documents/ProjectsLocal/scope-creep-godot --script res://tests/test_poc3_phase_5_customer_income.gd
```

Status: bestanden. Marco-Editor-/Playtest-Check erledigt.

## Phase 6 - Kundendruck und Unzufriedenheit

Ziel: Kundenwuensche werden zu echtem Druck, ohne schon ein vollstaendiges CRM-System zu bauen.

Codex:

- [x] `card.problem.unhappy_customer` als CardDefinition anlegen. Anzeigename: `Unzufrieden`.
- [x] Kundenwunsch beim Spawn mit `spawned_sprint_index` markieren.
- [x] Sprintstart-Regel nach Launch: pro unbearbeitetem Kundenwunsch aus vorherigen Sprints wird ein zufaelliger zufriedener Kunde unzufrieden.
- [x] `Unzufrieden` wird an eine Kundenkarte geheftet und ist nicht per Maus entfernbar.
- [x] Sind bereits alle Kunden unzufrieden, erzeugen unbearbeitete Kundenwuensche keine weitere Unzufriedenheit.
- [x] Verarbeitete Kundenwuensche verschwinden wie bisher als Recipe-Input und erzeugen keine Unzufriedenheit mehr.
- [x] Recipe anlegen: `Kunde + angeheftetes Unzufrieden + Product Owner -> Erwartungen managen -> Unzufrieden entfernen`.
- [x] Unzufriedene Kunden erzeugen kein Geld und keine Kundenwuensche.
- [x] Kunden bleiben dauerhaft im Run; es gibt keine Kundenkuendigungsregel.
- [x] Investorenpanik entsteht nicht aus Kundenanzahl, sondern aus verfehlten Business Goals.
- [x] Developer-Recipe anlegen: `Kundenwunsch + Entwickler -> Vielversprechende User Story`, 50% langsamer als Product Owner.
- [x] Reihenfolge sauber festlegen und testen: alte Kundenwuensche auswerten, Business Goal pruefen, dann neue Kundenspawns nur fuer zufriedene Kunden erzeugen.
- [x] Tests fuer ignorierte Kundenwuensche, erledigte Kundenwuensche, angeheftete Unzufriedenheit, PO-Behandlung, ausbleibenden Kundentick, dauerhaft bleibende Kunden und Developer-Recipe schreiben.

Marco:

- [x] Unzufrieden visuell klar als Problemkarte abstimmen.
- [x] Playtest pruefen: Ist klar genug, dass Unzufriedenheit am konkreten Kunden haengt und nur per Product Owner entfernt wird?
- [x] Board-Lesbarkeit pruefen, wenn mehrere Kunden angeheftete Unzufrieden-Karten haben.

Definition of Done:

- [x] Ignorierte Kundenwuensche werden am naechsten Sprintstart bestraft.
- [x] Bearbeitete Kundenwuensche erzeugen keine Strafe.
- [x] Unzufriedenheit ist an konkrete Kunden angeheftet und nicht per Maus entfernbar.
- [x] Sind alle Kunden unzufrieden, erzeugen weitere alte Kundenwuensche keine Zusatzstrafe.
- [x] Unzufriedene Kunden erzeugen kein Geld und keine Kundenwuensche.
- [x] Kunden gehen durch Unzufriedenheit nicht verloren.
- [x] Product Owner kann Unzufriedenheit aktiv bearbeiten.
- [x] Entwickler koennen Kundenwuensche langsamer zu vielversprechenden User Stories verarbeiten.
- [x] Kein neues Support-/CRM-System ist fuer PoC3 erforderlich.

Headless-Test:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/marcopreuss/Documents/ProjectsLocal/scope-creep-godot --script res://tests/test_poc3_phase_6_customer_pressure.gd
```

Status: bestanden. Marco-Editor-/Playtest-Check erledigt.

## Phase 7 - Business Goals, Investorenpanik und PoC3-Endzustand

Ziel: PoC3 bekommt einen klaren Post-Launch-Druck und einen klaren Erfolg-/Scheiterzustand.

Codex:

- [x] `card.goal.business_goal` als CardDefinition anlegen.
- [x] `card.problem.investor_panic` als CardDefinition anlegen.
- [x] Business-Goal-Werte implementieren: 3, 5, 7 Geld. Falls Playtest zu hart: spaeter 2, 4, 6 als Balance-Resource-Werte.
- [x] Business Goal mit Runtime-Werten `goal_index`, `required_money`, `paid_money` anzeigen.
- [x] Recipe/Interaktion: Geld auf Business Goal erhoeht `paid_money` um 1 und verbraucht genau 1 Geldkarte.
- [x] Beim Start des naechsten Sprints aus der Bezahlphase Business Goal pruefen.
- [x] Erfuelltes Goal entfernen und naechstes Goal mit hoeherem Wert spawnen.
- [x] Verfehltes Goal entfernen, 1 Investorenpanik erzeugen und naechstes Goal vorbereiten.
- [x] Bei 3 erfuellten Goals PoC3-Sieg ausloesen.
- [x] Bei 2 Investorenpanik-Karten Game Over ausloesen.
- [x] Bestehendes Game Over bei 0 Mitarbeitern unveraendert lassen.
- [x] Tests fuer Zahlung, Goal-Erfuellung, Goal-Verfehlen, 3-Goal-Sieg und 2-Panik-Niederlage schreiben.

Marco:

- [x] Business Goal Karte visuell als Pflicht/Ziel abstimmen, nicht wie normaler Auftrag.
- [x] Investorenpanik visuell als Fehlerkarte abstimmen.
- [x] Victory-/Game-Over-Anzeige im Editor pruefen. Falls eine neue UI-Scene noetig wird, Codex soll Script/Signale vorbereiten und Marco platziert/gestaltet sie im Editor.
- [x] Playtest pruefen, ob Bezahlphase-Entscheidung `Team vs. Goal vs. Booster` klar entsteht.

Definition of Done:

- [x] Business Goal ist eine sichtbare Karte mit sichtbarem Rest-/Fortschritt.
- [x] Geldkarten bezahlen Goals einzeln.
- [x] Goals werden beim Sprintstart aus der Bezahlphase geprueft.
- [x] PoC3 hat einen erreichbaren Siegzustand.
- [x] Investorenpanik bleibt Karte, kein HUD-Fehlerzaehler.

Headless-Test:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/marcopreuss/Documents/ProjectsLocal/scope-creep-godot --script res://tests/test_poc3_phase_7_business_goals.gd
```

Status: bestanden. Marco-Editor-/Playtest-Check erledigt.

## Phase 8 - Booster-/Shop-Scope fuer PoC3

Ziel: Booster unterstuetzen den neuen Run-Bogen, ohne das Hiring-Rework vorzuziehen.

Codex:

- [x] Startsetup auf PoC3 umstellen: Software MVP, Entwickler, Idee, Kaffee, aktuell 30 Geld als Playtest-Hilfe, 1 Freelance-Auftrag, Gründerpanik-Slot, Wohlbefinden-Slot, Externe-Hilfe-Slot.
- [x] Talent-Pool aus normalem PoC3-Startsetup entfernen oder deaktivieren.
- [x] `Gründerpanik` als fruehes 1-Geld-Pack definieren oder bestehendes Founder-Test-Pack fachlich entsprechend umbauen.
- [x] Wohlbefinden fuer PoC3 pruefen: Kaffee, Kaffeemaschine, Pizza Party, Stresskurs.
- [x] Externe Hilfe als deterministische Bugfix-Quelle aktiv lassen.
- [x] Kundenchaos entweder erst nach Launch aktivieren oder vorerst aus dem Startsetup entfernen. Empfehlung: erst nach Launch, damit Pre-Launch nicht durch zufaellige Kunden verwischt.
- [x] Shop-/Booster-Validator erweitern, damit deaktivierte Packs nicht als fehlende Referenzen oder tote Startkarten durchrutschen.
- [x] Tests fuer Startsetup und kaufbare PoC3-Shop-Eintraege schreiben.

Marco:

- [x] Shop-Dock im Editor pruefen: aktive Slots muessen lesbar und nicht ueberladen sein.
- [x] Entscheiden, ob Kundenchaos im Playtest direkt nach Launch sichtbar sein soll oder erst als Stretch.
- [x] Packnamen und Tooltips sprachlich abstimmen.

Definition of Done:

- [x] Talent-Pool stoert den PoC3-Test nicht.
- [x] Spieler hat fruehe Hilfe, aber kein zufaelliges Hiring-Spam.
- [x] Externe Hilfe bleibt als bewusstes Notfallventil erhalten.
- [x] Aktive Packs zahlen auf MVP/Launch/Kundenloop ein.

Headless-Test:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/marcopreuss/Documents/ProjectsLocal/scope-creep-godot --script res://tests/test_poc3_phase_8_shop_scope.gd
```

Status: bestanden.

## Phase 9 - Save/Load, Validation und Migration auf Content-Version `poc3`

Ziel: Der neue Run-State ist speicherbar, validierbar und bricht alte PoC2-Saves nicht still.

Codex:

- [x] `CONTENT_VERSION` auf `poc3` umstellen, sobald die Kernsysteme stabil sind.
- [x] Save/Load fuer neue Software-, Kundenwunsch-, Unzufrieden-Attachment- und Business-Goal-Runtime-Werte testen.
- [x] Serializer so erweitern, dass neue Runtime-Werte stabil erhalten bleiben.
- [x] Falls alte PoC2-Saves geladen werden koennen sollen: Defaultwerte oder klare Inkompatibilitaetsmeldung implementieren.
- [x] Content-Validator um neue Pflichtkarten, Recipes, Shop-Eintraege und Runtime-relevante IDs erweitern.
- [x] Validator prueft, dass Business-Goal-/Investorenpanik-/Unzufrieden-Karten vorhanden sind.
- [x] Tests fuer Save/Load mitten in Pre-Launch, launchbereit, Post-Launch mit aktivem Goal und Kundendruck schreiben.

Marco:

- [x] Im Editor einmal speichern/laden pruefen, besonders pausierter/frozen Zustand.
- [x] Sichtbar pruefen, dass Software-Featurezahl, Goal-Fortschritt, Kundenwuensche und angeheftete Unzufriedenheit nach Load korrekt angezeigt werden.

Definition of Done:

- [x] Neue PoC3-Runtime-Werte ueberleben Save/Load.
- [x] Content-Validator meldet fehlende PoC3-Referenzen klar.
- [x] Alte inkompatible Saves scheitern kontrolliert oder werden bewusst migriert.
- [x] Save bleibt nur im pausierten/frozen Zustand erlaubt.

Headless-Test:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/marcopreuss/Documents/ProjectsLocal/scope-creep-godot --script res://tests/test_poc3_phase_9_save_validation.gd
```

Status: bestanden.

## Phase 10 - Balancing, Playtest-Script und QA

Ziel: PoC3 wird als Mini-Run testbar, ohne finale Balance vorzutaeuschen.

Codex:

- [ ] Balance-Werte in `data/balance/poc_default.tres` oder einer PoC3-Balance-Resource buendeln: MVP-Schwelle, Freelance-Geld, Startgeld, Goal-Werte, Kunden-Tick und Developer-Kundenwunsch-Dauer.
- [ ] Ein Playtest-Script in diesem Plan oder `POC3_NOTES.md` dokumentieren: erwarteter Ablauf von Start bis 3 Goals.
- [ ] Headless-Test-Suite fuer alle PoC3-Phasen einmal zusammen ausfuehren.
- [ ] Offene Balancing-Fragen dokumentieren, statt sie mit Hardcode zu verstecken.
- [ ] Bekannte technische Schulden markieren, besonders noch hardcodierte PoC3-Balancewerte.

Marco:

- [ ] Mindestens 2 manuelle Playtests im Editor: einmal frueher Launch bei 10 Features, einmal spaeter Launch bei 15+ Features.
- [ ] Notieren, ob 30 Playtest-Startgeld, 10 Features, 3/5/7 Goals und angeheftete Unzufriedenheit fair wirken. Spaeter echten Startgeldwert wieder reduzieren.
- [ ] Pruefen, ob PoC3-Siegmeldung und Niederlage klar genug sind.
- [ ] UI/Lesbarkeit bei vielen Kundenwuenschen, Geldkarten und Problemen bewerten.

Definition of Done:

- [ ] PoC3 kann von Start bis Sieg oder Niederlage gespielt werden.
- [ ] Kernfragen aus `poc3-idee.md` koennen im Playtest beantwortet werden.
- [ ] Headless-Tests und Content-Validation laufen.
- [ ] Offene Balance- und Designfragen sind dokumentiert.

Headless-Check:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/marcopreuss/Documents/ProjectsLocal/scope-creep-godot --script res://scripts/validation/run_content_validation.gd
```

```bash
tools/check_poc.sh
```

## Stretch - Kundenwachstum durch zusaetzliche Live-Features

Ziel: Nach Launch bleiben weitere Features nuetzlich, ohne PoC3 zu ueberladen.

Codex:

- [ ] Nach Launch je 5 zusaetzliche Features 1 neuen Kunden erzeugen.
- [ ] Schwelle anhand `launch_feature_count` berechnen, nicht absolut ab 0.
- [ ] Runtime-Wert fuer naechste Kundenschwelle speichern, damit Save/Load deterministisch bleibt.
- [ ] Tests fuer 10->15, 15->20 und Save/Load zwischen Schwellen schreiben.

Marco:

- [ ] Playtest pruefen, ob Feature-Ausbau nach Launch dadurch interessanter wird.
- [ ] Entscheiden, ob das fuer PoC3 noetig ist oder erst PoC4 werden soll.

Definition of Done:

- [ ] Stretch ist sauber deaktivierbar oder bewusst aktiviert.
- [ ] Kundenwachstum erzeugt keine doppelten Kunden durch Save/Load oder mehrfaches Tick-Ausloesen.

## Technische Risiken und bewusste Entscheidungen

- Unzufriedenheit ist in PoC3 ein Kunden-Attachment. Das verhindert globale, schwer erklaerbare Strafen und macht klar, welcher Kunde gerade keinen Wert liefert.
- Business Goal als Runtime-Zahl auf einer Karte widerspricht nicht dem GDD, solange die Pflicht selbst eine Karte bleibt und mit einzelnen Geldkarten bezahlt wird.
- Sprintstart-Reihenfolge muss explizit getestet werden. Fachliche Empfehlung fuer PoC3: unbezahlte Mitarbeiter und alte Probleme auswerten, alte Kundenwuensche an zufriedene Kunden als Unzufriedenheit anheften, Business Goals pruefen, dann neue Sprintstart-Spawns nur fuer zufriedene Kunden erzeugen.
- Talent-Pool-Deaktivierung ist eine bewusste PoC3-Scope-Entscheidung, kein finales Hiring-Design.
- Product Owner und Tester muessen erreichbar bleiben, aber nicht zwingend im Startsetup liegen. Falls Playtests dadurch zu zufaellig werden, ist ein spaeterer kontrollierter Angebotspfad besser als Hiring-Spam.

## PoC3-Playtest-Fragen

- Fuehlt sich der Weg von MVP zu Launch wie echter Fortschritt an?
- Ist der Launch ein interessanter Zeitpunkt oder nur ein Pflichtklick?
- Ist die Entscheidung `Feature ins Produkt` vs. `Feature an Freelance-Auftrag` spuerbar?
- Ist vor Launch genug Geld da, ohne dass Software-Geld fehlt?
- Fuehlen sich Kunden nach Launch wertvoll und anstrengend an?
- Erzeugen Kundenwuensche sinnvollen Druck, ohne unkontrollierbar zu wirken?
- Konkurrieren Business Goals wirklich mit Gehaeltern, Boostern und Notfall-Bugfixes?
- Sind 3 Business Goals ein guter Mini-Run-Abschluss?
- Ist Talent-Pool-Deaktivierung fuer PoC3 richtig?
- Sind die Startwerte 30 Playtest-Geld, 10 MVP-Features, 3/5/7 Goals und angeheftete Kunden-Unzufriedenheit passend?

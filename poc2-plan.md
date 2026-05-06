# Scope Creep - PoC2-Plan

Dieses Dokument ist der gemeinsame Arbeitsplan fuer den zweiten aussagekraeftigen Playtest-Slice in Godot 4.6. Es baut auf dem bestehenden `poc-plan.md`, `architecture.md` und `gdd.md` v1.4 auf.

PoC2 ist kein Rewrite. Der bestehende PoC bleibt die technische Basis. Ziel ist, den kurzen Kernloop zu einem kleinen, wiederholt spielbaren System auszubauen, in dem die erste echte strategische Frage testbar wird:

```text
Schnell bauen und Chaos riskieren
vs.
langsamer, teurer und sauberer durch Team/Prozess arbeiten
```

Der Plan bleibt bewusst phasenweise und abhakbar. In jeder Phase ist getrennt, was der Coding Agent sauber ueber Dateien, Skripte, Resources und Tests umsetzen soll und was Marco im Godot Editor prueft, platziert oder visuell abstimmt.

## Fortschritt

- [x] Phase 0 - Baseline sichern und PoC2-Scope einfrieren
- [x] Phase 1 - Content-Katalog fuer PoC2 anlegen
- [x] Phase 2 - Rollen und saubere Feature-Pipeline
- [x] Phase 3 - Feature-Wert, Release-Varianten und Tech-Debt-Risiko
- [x] Phase 4 - Problemwirtschaft: Bugs, Bugfixes, Tech Debt, Prod-Crash
- [x] Phase 5 - Attachments v1: Burnout
- [x] Phase 6 - Wertquellen und Sprintstart-Spawns
- [x] Phase 7 - Booster- und Shop-Ausbau
- [ ] Phase 8 - Presentation-Polish fuer Spielbarkeit
- [ ] Phase 9 - Save/Load, Validation und Content-Version
- [ ] Phase 10 - Balancing, Playtest-Script und QA
- [ ] Stretch - Brainstorming-Workshop ohne Konflikt-System

## PoC2-Ziel

Am Ende von PoC2 soll ein Testlauf ueber mehrere Sprints sinnvoll spielbar sein:

1. Der Run startet weiterhin klein und verstaendlich.
2. Spieler kann den direkten Weg spielen: `Idee + Entwickler -> Funktion -> Software`.
3. Spieler kann den sauberen Weg freischalten/spielen: `Idee -> User Story -> Funktion -> Gepruefte Funktion -> Software`.
4. Product Owner und Tester erzeugen eine echte Rollenentscheidung.
5. Ungepruefte Releases koennen Bugs erzeugen.
6. Schnelle Direktentwicklung kann technische Schulden erzeugen.
7. Tech Debt verlaengert Feature- und Bugfix-Arbeit sichtbar.
8. Bugs koennen gefixt, ignoriert, verdoppelt oder zu Prod-Crashs eskaliert werden.
9. Prod-Crash blockiert Einnahmen, bis er behoben wird.
10. Burnout entsteht als echte angeheftete Karte an Mitarbeitern und blockiert Arbeit.
11. Pizza Party und Stressbewaeltigungskurs koennen Burnout abkuerzen bzw. entfernen.
12. Kunde, Kundenwunsch, Auftrag und Kaffeemaschine erzeugen neuen Druck und neue Chancen.
13. Boosterpacks sind thematisch getrennt und strategisch lesbar.
14. Save/Load funktioniert weiterhin mit dem erweiterten RunState.

## Nicht Ziel von PoC2

- Kein vollstaendiges Konflikt-System.
- Kein Designer und kein Support als Pflichtrollen.
- Kein komplexes Hiring-System mit Kandidaten/Gespraechen.
- Keine mehreren Auftragsarten mit hartem Feature-Typ-Matching.
- Keine finale Card-Art, Musik oder Sound-Pipeline.
- Kein finaler Balancing-Anspruch.
- Keine abstrakten UI-Meter fuer Burnout, Tech Debt, Ruf oder Qualitaet.
- Keine Quick-and-dirty-UI-Sonderlogik, die Simulation-Regeln dupliziert.

## PoC2-Content-Scope

### Neue oder finalisierte Karten

Mitarbeiter:

- `card.employee.product_owner` - Product Owner
- `card.employee.tester` - Tester
- `card.employee.external_dev` - Externer Dev
- optional: weitere Instanzen von `card.employee.developer`

Inputs / Aufgaben / Outputs:

- `card.input.customer_request` - Kundenwunsch
- `card.task.user_story` - User Story
- `card.task.promising_user_story` - Vielversprechende User Story
- `card.output.checked_feature` - Gepruefte Funktion

Probleme:

- `card.problem.tech_debt` - Technische Schulden
- `card.problem.burnout` - Burnout
- `card.problem.prod_crash` - Prod-Crash, falls bisher nur minimal vorhanden

Ressourcen / Consumables:

- `card.consumable.bugfix_patch` - Bugfix-Patch
- `card.consumable.pizza_party` - Pizza Party
- `card.consumable.stress_course` - Stressbewaeltigungskurs

Wertquellen:

- `card.value_source.customer` - Kunde
- `card.value_source.coffee_machine` - Kaffeemaschine
- `card.value_source.order` - Auftrag

Booster / Shop:

- `booster.talent_pool`
- `booster.office_invest`
- `booster.customer_chaos`
- optional: `booster.hot_fix_kit`

### Kernrecipes

Schnellschuss:

```text
Idee + Entwickler -> Funktion + Risiko: Tech Debt
Funktion + Software -> Geld + 50% Bug-Chance
```

Saubere Pipeline:

```text
Idee + Product Owner -> User Story
Kundenwunsch + Product Owner -> Vielversprechende User Story
User Story + Entwickler -> Funktion
Vielversprechende User Story + Entwickler -> Funktion mit hoeherem Wert
Funktion + Tester -> Gepruefte Funktion
Gepruefte Funktion + Software -> mehr Geld + kein Bug
```

Problembehandlung:

```text
Bug + Entwickler -> Bug entfernen
Bug + Tester -> Bug entfernen, langsamer
Bug + Externer Dev -> Bug entfernen, schneller
Bug + Bugfix-Patch -> Bug sofort entfernen
Technische Schulden + Entwickler -> Tech Debt entfernen
Prod-Crash + Entwickler -> Prod-Crash entfernen
```

Burnout:

```text
Mitarbeiter + Burnout -> 45s Erholung -> Burnout entfernen
Mitarbeiter + Burnout + Pizza Party -> 5s Erholung -> Burnout entfernen, Pizza verbrauchen
Mitarbeiter + Burnout + Stressbewaeltigungskurs -> Burnout sofort entfernen, Kurs verbrauchen
```

Wertquellen:

```text
Kunde -> 1 Kundenwunsch pro Sprintstart ab Sprint 2
Kaffeemaschine -> 1 Kaffee pro Sprintstart
Auftrag + Funktion -> Bonus-Geld, Auftrag verbrauchen
Auftrag am Sprintstart nicht erfuellt -> Auftrag verfaellt
```

## Phase 0 - Baseline sichern und PoC2-Scope einfrieren

Ziel: Der bestehende PoC bleibt stabil. PoC2 beginnt mit einem klaren Scope und ohne unkontrollierten Rewrite.

Codex:

- [x] `git status --short` pruefen und keine lokalen User-Aenderungen ueberschreiben.
- [x] Bestehende Tests aus `poc-plan.md` laufen lassen oder dokumentieren, welche noch offen sind.
- [x] Bestehende Content-IDs erfassen, damit PoC2 keine versehentlichen ID-Umbenennungen erzeugt.
- [x] Kurz pruefen, welche PoC2-Karten/Recipes bereits teilweise existieren: Bug, Tech Debt, Prod-Crash, Kaffee, Booster-Slot.
- [x] Eine kleine `POC2_NOTES.md` oder einen Abschnitt in diesem Plan nutzen, um Abweichungen waehrend der Umsetzung festzuhalten.

Marco:

- [x] Aktuellen PoC einmal im Editor starten.
- [x] Bestaetigen, dass der aktuelle Slice weiterhin spielbar ist.
- [x] Entscheiden, ob PoC2 auf demselben Branch oder auf einem neuen Branch umgesetzt wird.
- [x] Scope bestaetigen: Konflikt-System bleibt bewusst out-of-scope.

Definition of Done:

- [x] Aktueller PoC startet ohne neue Blocker.
- [x] Bestehende Kernregeln sind nicht kaputt.
- [x] PoC2-Scope ist schriftlich eingefroren.
- [x] Keine ID-Umbenennungen ohne bewusste Migration/Alias-Regel.

## Phase 1 - Content-Katalog fuer PoC2 anlegen

Ziel: Alle neuen Karten, Booster, Shops und Balance-Werte existieren datengetrieben, auch wenn noch nicht jede Regel aktiv ist.

Codex:

- [x] Neue `CardDefinition`-Resources fuer Product Owner, Tester, Externer Dev, Kundenwunsch, User Story, Vielversprechende User Story, Gepruefte Funktion, Burnout, Kunde, Kaffeemaschine, Auftrag, Pizza Party, Stressbewaeltigungskurs und Bugfix-Patch anlegen.
- [x] Falls noch nicht final vorhanden: Tech Debt und Prod-Crash CardDefinitions vervollstaendigen.
- [x] Tags sauber setzen, z. B. `employee`, `product_owner`, `tester`, `developer`, `external`, `input`, `task`, `feature`, `checked`, `problem`, `burnout`, `tech_debt`, `value_source`, `consumable`.
- [x] Visual-Minimum pflegen: Farbe, Label, kurzer Typmarker, Tooltip-Text.
- [x] `BalanceDefinition` um PoC2-Werte erweitern: PO-Dauer, Tester-Dauer, Tech-Debt-Chance, Burnout-Increment, Burnout-Recovery-Dauer, Pizza-Recovery-Dauer, Bugfix-Dauern, Prod-Crash-Dauer, Auftrag-Bonus.
- [x] Content-Validator erweitern, damit fehlende Tags/Visual-Minima fuer neue Karten auffallen.

Marco:

- [x] Neue Resources im Godot Editor oeffnen und pruefen, ob Felder sinnvoll editierbar sind.
- [x] Farben und Labels grob abstimmen, damit die Kartengruppen im Playtest sofort unterscheidbar sind.
- [x] Tooltips/kurze Texte bei Bedarf inhaltlich schaerfen.

Definition of Done:

- [x] Alle PoC2-Karten existieren als Resource.
- [x] Content-Validator meldet keine fehlenden Referenzen.
- [x] Neue Karten sind im Inspector sinnvoll pflegbar.
- [x] Keine neue Karte ist nur hardcodiert im Script bekannt.

Headless-Check:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/marcopreuss/Documents/ProjectsLocal/scope-creep-godot --script res://scripts/validation/run_content_validation.gd
```

## Phase 2 - Rollen und saubere Feature-Pipeline

Ziel: Product Owner und Tester machen den Unterschied zwischen schneller und sauberer Softwareproduktion spielbar.

Codex:

- [x] Recipes anlegen: `Idee + Product Owner -> User Story`.
- [x] Recipes anlegen: `Kundenwunsch + Product Owner -> Vielversprechende User Story`.
- [x] Recipes anlegen: `User Story + Entwickler -> Funktion`.
- [x] Recipes anlegen: `Vielversprechende User Story + Entwickler -> Funktion` mit hoeherem Funktionswert oder Runtime-Wert `feature_value`.
- [x] Recipes anlegen: `Funktion + Tester -> Gepruefte Funktion`.
- [x] Sicherstellen, dass Reihenfolge im Stack irrelevant bleibt.
- [x] Sicherstellen, dass Zusatzkarten, die nicht Teil des Recipes sind, den Stack neutral machen.
- [x] Headless Tests fuer alle neuen Pipeline-Recipes schreiben.
- [x] Optional: Startzustand oder Test-Debug-Spawn so erweitern, dass PO/Tester fuer Playtests leicht verfuegbar sind.

Marco:

- [x] Playtest: PO und Tester muessen visuell sofort als Mitarbeiter erkennbar sein.
- [x] Pruefen, ob die Aktionstexte lesbar sind: `User Story schreiben...`, `Feature umsetzen...`, `Feature pruefen...`.
- [x] Drag/Snap mit drei Rollen testen.

Definition of Done:

- [x] Spieler kann aus Idee per PO eine User Story erzeugen.
- [x] Spieler kann aus User Story per Entwickler eine Funktion erzeugen.
- [x] Spieler kann aus Funktion per Tester eine Gepruefte Funktion erzeugen.
- [x] Gepruefte Funktion bleibt eine eigene Karte, kein unsichtbarer Status.
- [x] Simulation-Tests bestehen ohne Presentation.

Headless-Test:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/marcopreuss/Documents/ProjectsLocal/scope-creep-godot --script res://tests/test_poc2_phase_2_pipeline.gd
```

## Phase 3 - Feature-Wert, Release-Varianten und Tech-Debt-Risiko

Ziel: Der direkte Weg und der saubere Weg erzeugen spuerbar unterschiedliche Ergebnisse.

Codex:

- [x] `Funktion` Runtime-Werte einfuehren oder finalisieren, z. B. `feature_value`, `is_checked`, `source_quality`.
- [x] Direktes `Idee + Entwickler -> Funktion` als Schnellschuss-Recipe markieren: normales Geld, Bug-Risiko beim Release, Tech-Debt-Risiko bei Erstellung.
- [x] `Vielversprechende User Story + Entwickler -> Funktion` erzeugt eine Funktion mit hoeherem `feature_value`.
- [x] `Funktion + Tester -> Gepruefte Funktion` uebertraegt den Feature-Wert und setzt `is_checked` bzw. erzeugt eine eigene checked Definition.
- [x] Release-Recipe trennen oder parametrisieren: ungepruefte Funktion erzeugt Geld plus Bug-Chance; Gepruefte Funktion erzeugt Geld ohne Bug-Chance.
- [x] Tech-Debt-Risiko bei Schnellschuss einfuehren, z. B. `RollChanceEffect` auf `card.problem.tech_debt`.
- [x] Spawn-Placement fuer parallel gespawnte Karten pruefen: Geld plus Bug/Tech Debt duerfen nicht verdeckt spawnen.
- [x] Tests fuer Geldmenge, Bug-Chance-Pfad und Tech-Debt-Risiko mit deterministischem RNG schreiben.

Marco:

- [x] Playtest: Schneller Weg muss sich lohnen, aber sichtbar riskant wirken.
- [x] Playtest: Sauberer Weg muss laenger dauern, aber durch mehr Geld/kein Bug-Risiko verstaendlich sein.
- [x] Pruefen, ob Feature-Wert oder Level auf der Karte sichtbar genug ist, falls angezeigt.

Definition of Done:

- [x] Ungepruefte Funktion kann Bug erzeugen.
- [x] Gepruefte Funktion erzeugt keinen Release-Bug.
- [x] Vielversprechende User Story fuehrt zu besserem Release-Ertrag.
- [x] Schnellschuss kann Tech Debt erzeugen.
- [x] Unterschiede sind im Playtest ohne Regeltext erklaerbar.

Headless-Test:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/marcopreuss/Documents/ProjectsLocal/scope-creep-godot --script res://tests/test_poc2_phase_3_release_quality.gd
```

## Phase 4 - Problemwirtschaft: Bugs, Bugfixes, Tech Debt, Prod-Crash

Ziel: Probleme sind nicht nur visuelle Nebenprodukte, sondern erzeugen echte Opportunitaetskosten.

Codex:

- [x] `Bug + Entwickler -> Bug entfernen` finalisieren oder ergaenzen.
- [x] `Bug + Tester -> Bug entfernen` als langsamere Alternative ergaenzen.
- [x] `Bug + Externer Dev -> Bug entfernen` als schnelle Alternative ergaenzen.
- [x] `Bug + Bugfix-Patch -> Bug sofort entfernen` als Sofort-Recipe/Effect anlegen.
- [x] `Technische Schulden + Entwickler -> Tech Debt entfernen` finalisieren.
- [x] RuleQuery/Modifier aktivieren: jede Tech-Debt-Karte auf dem Board addiert Zeit auf Feature- und Bugfix-Recipes.
- [x] `Prod-Crash + Entwickler -> Prod-Crash entfernen` mit langer Dauer finalisieren.
- [x] Prod-Crash blockiert Einnahmen aus Releases, solange mindestens ein Prod-Crash auf dem Board existiert.
- [x] Sprintstart-Reihenfolge erneut absichern: Bug-Formation vor Bug-Verdopplung, neue Bugs crashen erst naechsten Sprint.
- [x] Tests fuer Tech-Debt-Zeitaufschlag, Prod-Crash-Einnahmenblockade und Bugfix-Alternativen schreiben.

Marco:

- [x] Visuelle Lesbarkeit von Bug, Tech Debt und Prod-Crash pruefen.
- [x] Playtest: Bei Tech Debt muss der laengere Timer auffallen.
- [x] Playtest: Prod-Crash muss sich wie Krise anfuehlen, ohne extra UI-Meter.

Definition of Done:

- [x] Bugfixes funktionieren mit Entwickler, Tester, Externer Dev und Bugfix-Patch.
- [x] Tech Debt verlaengert passende Recipes sichtbar.
- [x] Tech Debt kann entfernt werden.
- [x] Prod-Crash verhindert Geldgewinn durch Releases.
- [x] Prod-Crash kann entfernt werden.
- [x] Alle Regeln bleiben in Simulation/Data, nicht in CardView/BoardView.

Headless-Test:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/marcopreuss/Documents/ProjectsLocal/scope-creep-godot --script res://tests/test_poc2_phase_4_problem_economy.gd
```

## Phase 5 - Attachments v1: Burnout

Ziel: Burnout ist der erste echte Test fuer angeheftete Karten, ohne direkt das komplexere Konflikt-System einzubauen.

Codex:

- [x] Attachment-Modell fuer `CardInstance.parent_card_id` und `attachment_slot` aktiv nutzen, falls noch nicht sichtbar verwendet.
- [x] Burnout-Card als Attachment an Mitarbeiter spawnen lassen.
- [x] Mitarbeiter mit Burnout blockiert normale Arbeitsrecipes.
- [x] `Mitarbeiter + Burnout -> Erholung` startet automatisch bzw. als normales Recipe, solange Burnout am Mitarbeiter haengt.
- [x] `Mitarbeiter + Burnout + Pizza Party -> 5s Erholung` als spezifischeres Recipe anlegen.
- [x] `Mitarbeiter + Burnout + Stressbewaeltigungskurs -> sofort entfernen` anlegen.
- [x] Burnout-Counter pro Mitarbeiter als Runtime-Wert einfuehren: produktive Taetigkeit +0.1, danach RNG-Wurf, bei Trigger Burnout-Spawn und Reset.
- [x] Workshop-Ausnahme noch nicht implementieren, ausser Stretch-Phase wird aktiv.
- [x] Save/Load fuer Attachments pruefen: Burnout bleibt am richtigen Mitarbeiter und Timer-Fortschritt bleibt erhalten.
- [x] Tests fuer Attachment, Blockade, Pizza-Spezifitaet, Sofortkurs und Save/Load schreiben.

Marco:

- [x] CardView so pruefen/anpassen, dass Burnout als angeheftete Karte oder Marker sichtbar ist.
- [x] Tooltip/Label pruefen: Spieler muss verstehen, welcher Mitarbeiter blockiert ist.
- [x] Playtest: Burnout darf nerven, aber nicht wie ein Bug im Drag-System wirken.

Definition of Done:

- [x] Burnout existiert als echte CardInstance.
- [x] Burnout bewegt sich mit dem Mitarbeiter.
- [x] Burnout blockiert Mitarbeiter-Arbeit.
- [x] Normale Erholung, Pizza Party und Stresskurs funktionieren.
- [x] Save/Load erhaelt Burnout-Attachment korrekt.

Headless-Test:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/marcopreuss/Documents/ProjectsLocal/scope-creep-godot --script res://tests/test_poc2_phase_5_burnout.gd
```

## Phase 6 - Wertquellen und Sprintstart-Spawns

Ziel: Der Loop endet nicht nach wenigen Karten, sondern erzeugt wiederholt Nachfrage, Ressourcen und Entscheidungen.

Codex:

- [x] `Kunde` als persistente Karte implementieren: spawnt ab Sprint 2 einen Kundenwunsch pro Sprintstart.
- [x] `Kaffeemaschine` als persistente Karte implementieren: spawnt pro Sprintstart einen Kaffee.
- [x] `Auftrag` als einmalige Wertkarte implementieren.
- [x] `Auftrag + Funktion -> Bonus-Geld` implementieren; Auftrag wird verbraucht.
- [x] Auftrag-Verfall am naechsten Sprintstart implementieren, falls noch nicht vorhanden.
- [x] Kundenwunsch-Recipes aus Phase 2 an Wertquellen anbinden.
- [x] Spawn-Placement fuer Tick-Karten testen, damit Sprintstart nicht stapelweise unlesbare Karten erzeugt.
- [x] Tests fuer Sprintstart-Spawns, Auftrag-Erfuellung und Auftrag-Verfall schreiben.

Marco:

- [x] Kunde, Kaffeemaschine und Auftrag auf Lesbarkeit pruefen.
- [x] Playtest: Sprintstart-Spawns sollen wie neue Chancen/Probleme wirken, nicht wie zufaelliges Board-Chaos.
- [x] Ggf. Standardpositionen oder reservierte Boardbereiche fuer persistente Karten abstimmen.

Definition of Done:

- [x] Kunde erzeugt wiederkehrende Nachfrage.
- [x] Kaffeemaschine erzeugt wiederkehrenden Kaffee.
- [x] Auftrag erzeugt eine kurzfristige Geldentscheidung.
- [x] Nicht erfuellter Auftrag verschwindet korrekt am Sprintstart.
- [x] Persistente Karten bleiben Karten, keine UI-Meter oder unsichtbaren Generatoren.

Headless-Test:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/marcopreuss/Documents/ProjectsLocal/scope-creep-godot --script res://tests/test_poc2_phase_6_value_sources.gd
```

## Phase 7 - Booster- und Shop-Ausbau

Ziel: Booster werden von einem Testpack zu einer strategischen Wahl.

Codex:

- [x] BoosterDefinition `Talent-Pool` anlegen: Entwickler, Product Owner, Tester, Externer Dev.
- [x] BoosterDefinition `Office-Invest` anlegen: Kaffeemaschine, Kaffee, Pizza Party, Stressbewaeltigungskurs.
- [x] BoosterDefinition `Kundenchaos` anlegen: Kunde, Kundenwunsch, Auftrag, Idee.
- [x] Optional BoosterDefinition `Hot Fix Kit` anlegen: Externer Dev, Bugfix-Patch, Kaffee, evtl. Code-Aufraeumen/Tech-Debt-Hilfe.
- [x] Booster-Slot/Shop so erweitern, dass mehrere Booster-Typen kaufbar sind.
- [x] Klare Kosten als Balance-Werte pflegen.
- [x] Einzelkarten-Shop fuer Bugfix-Patch fuer 1 Geld umsetzen, falls nicht bereits vorhanden.
- [x] Deterministische Booster-Ziehung fuer jeden Booster-Typ testen.
- [x] Validator erweitert: Booster-Pools muessen gueltige CardDefinition-Referenzen haben und duerfen nicht leer sein.

Marco:

- [x] Entscheiden, wie mehrere Booster visuell angeboten werden: mehrere Slots am Rand oder Shop-Karten als Karten.
- [x] Booster-Slots/Shop-Karten im Editor sinnvoll platzieren.
- [x] Playtest: Der Spieler muss verstehen, welches Pack welches Problem loest.
- [x] Namen/Copy der Packs schaerfen, falls Arbeitstitel nicht gut genug sind.

Definition of Done:

- [x] Mindestens drei thematische Booster sind kaufbar.
- [x] Booster ziehen deterministisch aus ihrem eigenen Pool.
- [x] Bugfix-Patch ist gezielt kaufbar.
- [x] Geld wird zur Entscheidung zwischen Gehalt, Notfallhilfe, Teamwachstum und Nachfrage.

Headless-Test:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/marcopreuss/Documents/ProjectsLocal/scope-creep-godot --script res://tests/test_poc2_phase_7_boosters_shop.gd
```

## Phase 8 - Presentation-Polish fuer Spielbarkeit

Ziel: PoC2 bleibt trotz mehr Karten gut lesbar und bedienbar.

Codex:

- [ ] CardView um kompakte Statusanzeige erweitern: Feature-Wert/Level, checked Marker, paid Marker, Burnout-Marker/Attachment-Hinweis.
- [ ] Tooltips oder Hover-Details fuer neue Karten bereitstellen, falls bestehendes System vorhanden ist.
- [ ] Progressbar/Aktionstext fuer neue Recipes sauber anzeigen.
- [ ] Spawn-Placement fuer mehrere gleichzeitige Karten verbessern, falls Karten verdeckt spawnen.
- [ ] Optional: kleine Dev-Overlay-Toggles fuer Debug-Spawns von PO, Tester, Kunde, Tech Debt, Burnout.
- [ ] Keine finalen Assets erzwingen; Platzhalter bleiben erlaubt.

Marco:

- [ ] Farben fuer Rollen, Probleme, Consumables und Wertquellen abstimmen.
- [ ] Kartenabstaende, Stack-Offset und Board-Groesse mit mehr Karten testen.
- [ ] UI am Rand fuer Booster/Shop lesbar anordnen.
- [ ] Screenshot-Check: Ein neuer Betrachter soll die wichtigsten Kartenkategorien grob erkennen koennen.

Definition of Done:

- [ ] 30-50 Karten bleiben noch spielbar/lesbar.
- [ ] Burnout und bezahlte Mitarbeiter sind erkennbar.
- [ ] Gepruefte Funktion unterscheidet sich sichtbar von normaler Funktion.
- [ ] Problemkarten sind visuell dringlich genug.
- [ ] Presentation enthaelt weiterhin keine autoritativen Spielregeln.

## Phase 9 - Save/Load, Validation und Content-Version

Ziel: PoC2 erweitert den State, ohne Save/Load und Validator zu brechen.

Codex:

- [ ] Content-Version fuer PoC2 setzen oder erhoehen.
- [ ] Save/Load um neue Runtime-Werte pruefen: Feature-Wert, checked/source quality, Burnout-Counter, Attachment-Daten, Externer-Dev-Lifecycle, Auftrag-Lifecycle.
- [ ] Frozen Save in Pause und Bezahlphase erneut testen.
- [ ] Validator fuer neue Recipe-Patterns erweitern: spezifischere Recipes, Booster, Attachments, Pflicht-Tags.
- [ ] Headless Regression-Test: vorhandener PoC-Kernloop funktioniert weiterhin.
- [ ] Headless Save/Load-Test mit aktivem Burnout, laufendem Timer, Booster-RNG und mehreren Sprintstart-Tick-Karten.

Marco:

- [ ] Manuell speichern/laden mit sichtbarem Board-Chaos testen.
- [ ] Pruefen, ob geladene Attachments visuell korrekt wieder aufgebaut werden.
- [ ] Pruefen, ob laufende Bearbeitungen nach Load korrekt pausiert sind.

Definition of Done:

- [ ] Save/Load funktioniert mit allen PoC2-Karten.
- [ ] Burnout-Attachments ueberleben Save/Load.
- [ ] RNG fuer Booster bleibt nach Load deterministisch.
- [ ] Validator findet absichtliche Fehler klar.
- [ ] Alter Kernloop ist nicht regressiert.

Headless-Test:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/marcopreuss/Documents/ProjectsLocal/scope-creep-godot --script res://tests/test_poc2_phase_9_save_validation.gd
```

## Phase 10 - Balancing, Playtest-Script und QA

Ziel: PoC2 wird als aussagekraeftiges Paket testbar, nicht nur als Sammlung neuer Karten.

Codex:

- [ ] Alle Headless Tests aus PoC und PoC2 laufen lassen.
- [ ] Fehlerlogs bereinigen.
- [ ] Kleine Balance-Werte in `BalanceDefinition` zentralisieren, falls noch hardcodiert.
- [ ] Dev-Overlay nur behalten, wenn klar als Debug abschaltbar.
- [ ] Kurze Start-/Testanleitung ergaenzen.
- [ ] Keine PoC2-Sonderpfade belassen, die gegen `architecture.md` verstossen.

Marco:

- [ ] Playtest 1: Schnellschuss-Strategie fuer 5 Sprints spielen.
- [ ] Playtest 2: Saubere Pipeline mit PO/Tester fuer 5 Sprints spielen.
- [ ] Playtest 3: Absichtlich Bugs ignorieren, bis Prod-Crash entsteht.
- [ ] Playtest 4: Burnout/Office-Invest testen.
- [ ] Notieren, ob Entscheidungen spannend sind oder nur offensichtlich richtig/falsch.
- [ ] Entscheiden, ob POC3 Konflikte, Workshop oder Hiring als naechstes angeht.

Definition of Done:

- [ ] Eine Runde ueber mindestens 5 Sprints ist sinnvoll spielbar.
- [ ] Der Spieler erlebt sichtbar den Tradeoff zwischen schnell und sauber.
- [ ] Bugs, Tech Debt, Burnout und Prod-Crash erzeugen Druck ohne unsichtbare Meter.
- [ ] Geldentscheidungen sind spuerbar: bezahlen, Booster kaufen, Patch kaufen, wachsen.
- [ ] Es gibt keine bekannten Blocker in Konsole, Validator oder Kernloop.

## Stretch - Brainstorming-Workshop ohne Konflikt-System

Nur umsetzen, wenn Phase 0-10 stabil sind und noch Zeit bleibt.

Ziel: Ideen-Nachschub und Team-Overhead testen, ohne direkt Konflikte zu implementieren.

Codex:

- [ ] `Workshop`-CardDefinition anlegen oder finalisieren.
- [ ] Recipe: `Workshop + mindestens 2 Mitarbeiter -> 1 Idee pro Teilnehmer + 1 Burnout an zufaelligem Teilnehmer`.
- [ ] Reset-Regel implementieren: weiterer Mitarbeiter im laufenden Workshop startet Timer neu.
- [ ] Konflikt-Chance in PoC2 bewusst deaktiviert oder als `TODO POC3` dokumentiert.
- [ ] Tests fuer Teilnehmerzahl, Ideenanzahl, Burnout-Zufall und Reset-Regel schreiben.

Marco:

- [ ] Playtest: Fuehlt sich Workshop als interessante Midgame-Option an oder als zu starke Ideenmaschine?
- [ ] Pruefen, ob garantierter Burnout als Kostenfaktor verstaendlich ist.

Definition of Done:

- [ ] Workshop erzeugt Ideen pro Teilnehmer.
- [ ] Workshop erzeugt garantierten Burnout.
- [ ] Timer resetet bei neuem Teilnehmer.
- [ ] Kein halbes Konflikt-System wird eingebaut.

## Empfohlene Start-Balance fuer PoC2

Diese Werte sind Startpunkte fuer Tests, nicht finale Balance.

```text
Sprintdauer: 60s
Idee + Entwickler -> Funktion: 18s, 25% Tech-Debt-Chance
Idee + Product Owner -> User Story: 10s
Kundenwunsch + Product Owner -> Vielversprechende User Story: 12s
User Story + Entwickler -> Funktion: 18s
Vielversprechende User Story + Entwickler -> Funktion: 18s, feature_value +1
Funktion + Tester -> Gepruefte Funktion: 14s
Funktion + Software Release: 2s, Geld = feature_value, 50% Bug-Chance
Gepruefte Funktion + Software Release: 2s, Geld = feature_value +1, 0% Bug-Chance
Bug + Entwickler: 18s + 5s pro Tech Debt
Bug + Tester: 28s + 5s pro Tech Debt
Bug + Externer Dev: 8s + 5s pro Tech Debt
Technische Schulden + Entwickler: 25s
Prod-Crash + Entwickler: 45s
Burnout-Erholung: 45s
Burnout + Pizza Party: 5s
Bugfix-Patch: sofort
Stressbewaeltigungskurs: sofort
Auftrag-Bonus: +3 Geld
Burnout-Increment nach produktiver Taetigkeit: +0.1
```

## PoC2-Testfragen

Diese Fragen sollen nach dem Playtest beantwortbar sein:

- Macht die laengere Pipeline mehr Spass oder nur mehr Arbeit?
- Ist der direkte Weg noch attraktiv genug?
- Ist Tech Debt als Karte intuitiv oder zu abstrakt?
- Ist Burnout als angeheftete Karte klar lesbar?
- Fuehlen sich PO und Tester wie sinnvolle Rollen an?
- Entsteht durch Kunde/Auftrag genug neuer Druck?
- Sind Booster eine echte Entscheidung oder klickt man immer dasselbe Pack?
- Wird das Board ab 40+ Karten zu chaotisch?
- Braucht POC3 eher Konflikte, Workshop-Ausbau oder Hiring?

## Laufende Notizen

Offene Punkte waehrend der Umsetzung hier eintragen:

- [ ]

Entscheidungen waehrend der Umsetzung hier festhalten:

- [x] PoC2 fokussiert `Team + Qualitaetsprozess + Eskalationsdruck`.
- [x] Konflikt-System wird bewusst auf POC3 verschoben.
- [x] Burnout ist das erste Attachment-System, weil es weniger komplex ist als Konflikte.
- [x] Booster werden thematisch getrennt, damit Geld strategischer wird.
- [x] Visuals bleiben asset-freie Platzhalter, solange Lesbarkeit gut genug ist.

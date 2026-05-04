# Scope Creep - PoC-/Vertical-Slice-Plan

Dieses Dokument ist der gemeinsame Arbeitsplan fuer einen spielbaren Vertical Slice in Godot 4.6. Es beruecksichtigt `architecture.md` als Zielarchitektur und `gdd.md` v1.4 als Designquelle.

Der Plan ist bewusst phasenweise und abhakbar. In jeder Phase ist getrennt, was Codex ueber Dateien/Skripting/Resources vorbereitet und was im Godot Editor von Marco sauber gesetzt, verbunden oder visuell gepflegt werden soll. Codex soll keine Editor-Arbeit durch fragile Workarounds ersetzen.

## Fortschritt

- [x] Phase 0 - Projektbasis und Arbeitsregeln
- [x] Phase 1 - Zielstruktur und technische Grundtypen
- [x] Phase 2 - Data-Resources und Content-Validator
- [x] Phase 3 - Simulation-State und Commands
- [x] Phase 4 - Recipe Engine und Effect Pipeline
- [x] Phase 5 - Board-, Stack- und Card-Presentation
- [x] Phase 6 - Erste spielbare Card-Pipeline
- [x] Phase 7 - Sprint, Pause und Bezahlphase
- [x] Phase 8 - Bugs, Tech Debt und Sprintstart-Ticks
- [ ] Phase 9 - Booster, Shop und deterministischer RNG
- [ ] Phase 10 - Save/Load fuer frozen Runs
- [ ] Phase 11 - Vertical-Slice-Polish und QA

## Vertical-Slice-Ziel

Am Ende des PoC soll ein kleiner, echter Spielablauf funktionieren:

1. Run startet mit Software, Entwickler, Idee, Kaffee und wenigen 1-Geld-Karten.
2. Karten koennen frei gezogen, gestapelt und als neutrale Stacks bewegt werden.
3. `Idee + Entwickler` verarbeitet zu `Funktion`.
4. `Funktion + Software` verarbeitet zu Geld und optional Bug.
5. Sprint-Timer laeuft, Pause friert Timer ein.
6. Bezahlphase sperrt alles ausser Geld und Mitarbeiter.
7. Manuelles Bezahlen verbraucht genau eine 1-Geld-Karte.
8. Start des naechsten Sprints fuehrt Sprintstart-Ticks aus.
9. Bugs koennen entstehen, sich am Sprintstart nach GDD-Reihenfolge verhalten und spaeter per Recipe bearbeitet werden.
10. Ein einfacher Booster kann gekauft/geoeffnet werden und deterministisch Karten aus einem Resource-Pool erzeugen.
11. Save/Load funktioniert nur im pausierten/frozen Zustand und stellt Board, Stacks, Timer, RNG und Karten wieder her.

Nicht Ziel des PoC:

- vollstaendiger Kartenkatalog
- finaler Look
- finale Card-Art, Sprites, Icons oder Audio-Assets
- Controller-Support
- Musik
- externe Mods
- komplexe Editor-Tools
- komplette Balance

Visual-Entscheidung fuer den PoC:

- Karten werden asset-frei als einfache rechteckige Godot-UI-/2D-Formen dargestellt.
- Unterscheidung erfolgt ueber Farbe, Label, Typ-Marker, Progressbar und spaeter kleine Runtime-Marker.
- Keine externe Card-Art, Sprites oder Icon-Pipeline blockiert den Vertical Slice.
- Visual-Felder in Resources duerfen Farben/Text-Marker enthalten, aber keine Asset-Abhaengigkeit voraussetzen.

## Phase 0 - Projektbasis und Arbeitsregeln

Ziel: Klare technische Basis, damit die folgenden Phasen nicht gegen Godot-Editor-Konventionen arbeiten.

Codex:

- [x] Bestehende Dateien pruefen: `project.godot`, `gdd.md`, `architecture.md`.
- [x] Keine bestehenden User-Aenderungen ueberschreiben.
- [x] Vor jeder groesseren Phase kurz `git status --short` pruefen.
- [x] Nur Dateien/Skripte/Resources anlegen oder aendern, die fuer die Phase benoetigt werden.
- [x] Keine Editor-spezifischen `.tscn`-Verknuepfungen per Text erzwingen, wenn sie im Editor sauberer gesetzt werden sollten.

Marco:

- [x] Godot 4.6 Projekt einmal im Editor oeffnen und sicherstellen, dass es ohne Importfehler startet.
- [x] Platzhalter-Visuals fuer den PoC bestaetigt: einfache Rechtecke/Formen, keine Card-Sprites/Icons.
- [x] Nach Codex-Aenderungen Godot-Import laufen lassen und sichtbare Editor-Fehler melden.

Definition of Done:

- [x] Projekt laesst sich in Godot 4.6 oeffnen.
- [x] `architecture.md` und `gdd.md` bleiben die gueltigen Referenzen.
- [x] Keine ungeklaerten Editor-Hacks im Projekt.

## Phase 1 - Zielstruktur und technische Grundtypen

Ziel: Ordner, Basisklassen und Enums so vorbereiten, dass alle weiteren Systeme architekturkonform wachsen.

Codex:

- [x] Zielordner anlegen: `data/`, `scripts/`, `scenes/`, `assets/`, `tests/` gemaess `architecture.md`.
- [x] Resource-Basisklassen fuer `CardDefinition`, `RecipeDefinition`, `EffectDefinition`, `BoosterDefinition`, `ShopDefinition`, `BalanceDefinition` erstellen.
- [x] Runtime-State-Klassen fuer `RunState`, `CardInstance`, `StackState`, `BoardState`, `ProcessingState` erstellen.
- [x] Enums/Konstanten fuer Card-Typen, Run-Phasen und Processing-States definieren.
- [x] ID-Konventionen dokumentieren oder als kleine Utility validieren.
- [x] Keine Spielregeln in Views oder Scenes schreiben.

Marco:

- [x] In Godot pruefen, ob die neuen Resource-Klassen im Inspector als Resource-Typen auftauchen.
- [x] Keine manuelle Resource-Massenpflege in dieser Phase; nur Smoke-Test im Editor.

Definition of Done:

- [x] Godot kompiliert die neuen GDScript-Klassen ohne Fehler.
- [x] Resource-Klassen sind im Editor nutzbar.
- [x] Runtime-State ist UI-unabhaengig.

## Phase 2 - Data-Resources und Content-Validator

Ziel: Ein kleiner, echter Content-Satz wird datengetrieben gepflegt und automatisch validiert.

Codex:

- [x] Minimal-CardDefinitions anlegen: Software, Entwickler, Idee, Funktion, Geld, Bug, Kaffee, Boosterpack-Platzhalter.
- [x] Minimal-RecipeDefinitions anlegen: Idee zu Funktion, Funktion zu Software, Kaffee-Modifier fuer eine Aufgabe.
- [x] Minimal-BoosterDefinition fuer ein einfaches Gruender-/Testpack anlegen.
- [x] BalanceDefinition mit Sprintdauer, Release-Dauer, Bug-Chance, Snap-Distanz und Stack-Offset anlegen.
- [x] Headless Content-Validator implementieren: doppelte IDs, fehlende Referenzen, ungueltige Recipe-Inputs, leere Booster-Pools.
- [x] Einen Godot-headless-Aufruf oder Testskript dokumentieren, mit dem der Validator laeuft.

Marco:

- [x] Resource-Dateien im Editor oeffnen und pruefen, ob Felder sinnvoll editierbar sind.
- [x] Platzhaltertexte und Farben im Inspector setzen, falls Codex dafuer Felder bereitstellt.
- [x] Keine Logik im Editor nachbauen; nur Resources pflegen.

Definition of Done:

- [x] Validator laeuft headless.
- [x] Minimal-Content wird erfolgreich validiert.
- [x] Ein absichtlicher Fehler, z. B. fehlende Card-ID, wird klar gemeldet.

Headless-Check:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/marcopreuss/Documents/ProjectsLocal/scope-creep-godot --script res://scripts/validation/run_content_validation.gd
```

## Phase 3 - Simulation-State und Commands

Ziel: Der Run kann ohne UI erzeugt und ueber Commands veraendert werden.

Codex:

- [x] `RunController` oder aequivalenten Simulation-Service erstellen.
- [x] Start-Run aus Resource-IDs erzeugen: Software, Entwickler, Idee, Kaffee, Startgeld.
- [x] Commands implementieren: Karte bewegen, Stack bilden, Stack splitten, Pause setzen.
- [x] Simulation-Events ausgeben: CardSpawned, StackChanged, PhaseChanged, TimerUpdated.
- [x] Deterministischen RNG im RunState vorbereiten.
- [x] Headless Tests fuer Startzustand, Stackbildung und neutrale Stacks schreiben.

Marco:

- [x] Keine Editor-Aufgabe ausser Projektstart/Fehlerpruefung.
- [x] Falls gewuenscht Startkartenliste in Resources inhaltlich pruefen.

Definition of Done:

- [x] Start-Run kann headless erzeugt werden.
- [x] Karten koennen logisch gestapelt und getrennt werden.
- [x] Neutrale Stacks bleiben erlaubt und bewegbar.
- [x] Simulation braucht keine Card-Views.

Headless-Test:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/marcopreuss/Documents/ProjectsLocal/scope-creep-godot --script res://tests/test_phase_3.gd
```

## Phase 4 - Recipe Engine und Effect Pipeline

Ziel: Recipes und Effects funktionieren als wiederverwendbarer Kern, nicht als hardcodierter PoC-Pfad.

Codex:

- [x] Recipe-Matching fuer reine Rezeptstapel implementieren.
- [x] Spezifitaet und `priority` beim Matchen umsetzen.
- [x] Ambige Matches fuer Validator/Test sichtbar machen.
- [x] Processing mit Dauer, Fortschritt, Pause und Abbruch implementieren.
- [x] Stack-Aenderung invalidiert aktives Recipe und bricht es bei Nicht-Match ab.
- [x] Basis-Effects implementieren: SpawnCard, RemoveCard, ConsumeInput, SpawnMoney, RollChance.
- [x] Headless Tests fuer Recipe-Matching, Pizza-/Kaffee-aehnliche Spezifitaet, Abbruch bei Stack-Aenderung.

Marco:

- [x] Im Editor die Recipe-Resources pruefen und bei Bedarf Anzeigenamen/Aktionstexte anpassen.
- [x] Keine Recipe-Logik per Scene-Signal bauen; alle Regeln bleiben in Resources/Simulation.

Definition of Done:

- [x] `Idee + Entwickler` kann headless zu `Funktion` verarbeiten.
- [x] `Funktion + Software` kann headless Geld spawnen.
- [x] Neutrale Zusatzkarte macht Stack neutral.
- [x] Aktives Processing bricht bei ungueltiger Stack-Aenderung ab.

Headless-Test:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/marcopreuss/Documents/ProjectsLocal/scope-creep-godot --script res://tests/test_phase_4.gd
```

## Phase 5 - Board-, Stack- und Card-Presentation

Ziel: Der Simulation-State wird spielbar dargestellt, ohne dass Presentation Spielregeln besitzt.

Codex:

- [x] CardView-Script erstellen: Definition anzeigen, Runtime-Marker anzeigen, Drag-Signale senden.
- [x] BoardView-Script erstellen: CardViews aus Simulation-Events erzeugen/aktualisieren.
- [x] StackView-/Layout-Logik erstellen: horizontal deckungsgleich, vertikal versetzt.
- [x] Drag-and-Drop Intent an Application/Simulation senden.
- [x] Magnetisches Snap oben auf Zielstack implementieren.
- [x] Progressbar und Aktionstext aus StackState anzeigen.
- [x] Kamera-Script fuer Pan/Zoom vorbereiten, soweit sinnvoll per Script.

Marco:

- [x] Main-Scene im Godot Editor anlegen oder pruefen.
- [x] BoardView, Camera2D, CanvasLayer/UI sauber in der Scene platzieren.
- [x] CardView-Scene im Editor asset-frei bauen: Rechteck/Panel als Background, Labels, Progressbar, Marker-Platzhalter.
- [x] Scripts im Editor an die passenden Nodes haengen, wenn Codex sie nicht sicher per bestehender Scene-Struktur setzen kann.
- [x] Optional Theme/Inspector fuer Farben, Randschatten, Labelgroessen und Abstaende abstimmen; keine Font-/Sprite-Abhaengigkeit fuer den PoC.

Definition of Done:

- [x] Startkarten erscheinen sichtbar auf dem Board.
- [x] Karten koennen mit Maus gezogen und gestapelt werden.
- [x] Stacks sehen Stacklands-artig aus.
- [x] Presentation mutiert keine Spielregeln direkt.

Headless-Test:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/marcopreuss/Documents/ProjectsLocal/scope-creep-godot --script res://tests/test_phase_5.gd
```

## Phase 6 - Erste spielbare Card-Pipeline

Ziel: Der Kernloop Idee -> Funktion -> Software -> Geld wird im Editor spielbar.

Codex:

- [x] Application-Bootstrap bauen: Content laden, Run starten, BoardView verbinden.
- [x] Timer-Update von Simulation zu Progressbar verbinden.
- [x] Recipe-Abschluss fuer `Idee + Entwickler -> Funktion` sichtbar machen.
- [x] Recipe-Abschluss fuer `Funktion + Software -> Geld` sichtbar machen.
- [x] Spawn-Placement nahe Quelle implementieren, ohne Karten zu verdecken.
- [x] Einfache Debug-UI fuer Phase/Sprint/Run-Status nur falls noetig als Dev-Overlay.

Marco:

- [x] Im Editor Startscene als Main Scene setzen.
- [x] Sichtbare Kartenabmessungen, Farben und Labelgroessen im CardView abstimmen.
- [x] Boardgroesse und Kamera-Startposition im Editor pruefen.
- [x] Im Playtest auf Lesbarkeit, Drag-Gefuehl und Snap-Distanz achten.

Definition of Done:

- [x] Spieler kann Idee auf Entwickler ziehen.
- [x] Fortschrittsbalken laeuft.
- [x] Funktion spawnt an freier Position nahe dem Stack.
- [x] Funktion auf Software erzeugt 1-Geld-Karten.

Headless-Test:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/marcopreuss/Documents/ProjectsLocal/scope-creep-godot --script res://tests/test_phase_6.gd
```

## Phase 7 - Sprint, Pause und Bezahlphase

Ziel: Der Slice bekommt den echten Sprint-Rahmen aus dem GDD.

Codex:

- [x] Sprint-Timer in Simulation implementieren.
- [x] Pause-Command implementieren: Timer frieren ein, Karten bleiben gemaess GDD beweglich.
- [x] Wechsel in `PAYMENT` nach Sprintende implementieren.
- [x] Payment-Regeln implementieren: alle Karten bleiben beweglich, Processing bleibt eingefroren.
- [x] Manuelles Bezahlen: 1-Geld-Karte auf Mitarbeiter verbrauchen und Mitarbeiter markieren.
- [x] Auto-Pay-Command optional fuer PoC, aber architekturkonform vorbereiten.
- [x] `StartNextSprintCommand` implementieren.
- [x] Tests fuer Phase-Wechsel, Pause und manuelles Bezahlen schreiben.

Marco:

- [ ] UI im Editor bauen: Sprint-Timer-Label, Pause-Anzeige, Button `Sprint N+1 starten`.
- [ ] Visuelle Abdunklung/Highlighting fuer Payment-Phase in CardView/Theme pruefen.
- [ ] Input-Map fuer Leertaste/Pause im Editor setzen, falls nicht per Projektdatei sauber automatisiert.

Definition of Done:

- [x] Sprint endet nach konfigurierter Dauer.
- [x] Bezahlphase friert Processing ein.
- [x] Geld auf Mitarbeiter bezahlt korrekt.
- [x] Naechster Sprint kann gestartet werden.

## Phase 8 - Bugs, Tech Debt und Sprintstart-Ticks

Ziel: Der Slice zeigt erste negative Eskalation, ohne Sonderlogik im UI.

Codex:

- [x] Bug-Chance beim ungeprueften Release ueber `RollChanceEffect` anbinden.
- [x] Bug-CardDefinition und Spawn aus Release-Recipe finalisieren.
- [x] Sprintstart-Effect-Reihenfolge implementieren: Kuendigungen, Bug-Formation, Bug-Verdopplung, Auftrag-Verfall, Externer-Dev-Verfall, persistente Spawns.
- [x] Fuer PoC mindestens Bug-Formation und Bug-Verdopplung aktivieren.
- [x] Tech-Debt-Modifier-Service vorbereiten, auch wenn Tech Debt im PoC nur minimal sichtbar ist.
- [x] Tests: Bug-Formation vor Bug-Verdopplung; neu verdoppelte Bugs crashen erst naechsten Sprint.

Marco:

- [x] Bug-Visuals/Marker im Editor setzen oder Platzhalter bestaetigen.
- [x] Playtest: Bugs sollen sichtbar genug sein und nicht unter anderen Karten spawnen.

Definition of Done:

- [x] Ungepruefter Release kann Bug erzeugen.
- [x] Drei vorhandene Bugs werden am Sprintstart zu Prod-Crash.
- [x] Uebrige Bugs verdoppeln sich danach.
- [x] Reihenfolge entspricht `gdd.md` v1.4.

Headless-Test:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/marcopreuss/Documents/ProjectsLocal/scope-creep-godot --script res://tests/test_phase_8.gd
```

## Phase 9 - Booster, Shop und deterministischer RNG

Ziel: Ein einfacher Booster ist spielbar und nutzt die langfristige Booster-Architektur.

Codex:

- [ ] Booster-Slot als Presentation/Application-Interaktion anbinden.
- [ ] `Geld + Booster-Slot -> Boosterpack` als Recipe/Command abbilden.
- [ ] `Geld + Boosterpack -> 3 Karten aus Pool` ueber `OpenBoosterEffect` implementieren.
- [ ] Booster-Ziehungen ueber Run-RNG deterministisch machen.
- [ ] Minimal-Booster-Pool fuer PoC pflegen: Idee, Kaffee, Geld, ggf. Bugfix-Patch.
- [ ] Tests fuer deterministische Booster-Ziehung schreiben.

Marco:

- [ ] Booster-Slot im Editor am Bildschirmrand platzieren.
- [ ] Boosterpack-Card-Visual/Label pruefen.
- [ ] Playtest: Kaufen und Oeffnen soll sich klar von normalen Stacks unterscheiden.

Definition of Done:

- [ ] Spieler kann mit Geld einen Booster erzeugen.
- [ ] Spieler kann Booster oeffnen und 3 Karten erhalten.
- [ ] Gleicher RNG-State erzeugt gleiche Booster-Ziehung.

## Phase 10 - Save/Load fuer frozen Runs

Ziel: Der PoC kann pausierte/frozen Runs speichern und laden.

Codex:

- [ ] Save-Serializer fuer `RunState` implementieren.
- [ ] Load-Deserializer mit Content-ID-Referenzen implementieren.
- [ ] Save nur erlauben, wenn Run pausiert oder in `PAYMENT` ist.
- [ ] Nach Load Run automatisch pausiert halten.
- [ ] Presentation nach Load vollstaendig aus RunState neu aufbauen.
- [ ] Tests fuer Save/Load mit Stacks, Attachments, Timer-Fortschritt und RNG-State schreiben.

Marco:

- [ ] Slot-UI im Editor bauen oder einfache Dev-Buttons platzieren.
- [ ] Manuell testen: pausieren, speichern, Projekt/Run neu laden, Zustand vergleichen.
- [ ] Pruefen, ob Save-Pfade auf dem Zielsystem sinnvoll sind.

Definition of Done:

- [ ] Save in laufendem, ungepaustem Sprint ist nicht erlaubt.
- [ ] Save in Pause oder Payment funktioniert.
- [ ] Load stellt Karten, Stacks, Timer und RNG deterministisch wieder her.

## Phase 11 - Vertical-Slice-Polish und QA

Ziel: Der Slice ist klein, aber als Spielrunde verstaendlich und stabil.

Codex:

- [ ] Fehlerlogs bereinigen.
- [ ] Validator in einen einfachen Check-Command integrieren.
- [ ] Headless Tests fuer alle Kernregeln laufen lassen.
- [ ] Kleine Debug-Hilfen nur behalten, wenn sie klar als Dev-Overlay abschaltbar sind.
- [ ] Keine PoC-Sonderpfade im Code belassen, die gegen `architecture.md` verstossen.
- [ ] Kurze `README`-Notiz oder Abschnitt im Plan ergaenzen, wie man den Slice startet und testet.

Marco:

- [ ] Finaler Editor-Playtest des Vertical Slice.
- [ ] Kartenlesbarkeit, Snap-Gefuehl, Kamera und UI-Abstaende abstimmen.
- [ ] Asset-freie Platzhalterkarten auf Lesbarkeit pruefen; Ersatz durch Grafiken/Sprites ist nicht Teil des PoC.
- [ ] Entscheiden, welche offenen Punkte in die naechste Session wandern.

Definition of Done:

- [ ] Eine kurze Runde ist von Start bis naechstem Sprint spielbar.
- [ ] Keine bekannten Blocker in Konsole oder Validator.
- [ ] Kernloop und negative Eskalation sind sichtbar.
- [ ] Code folgt der Zielarchitektur statt PoC-Hacks.

## Laufende Notizen

Offene Punkte waehrend der Umsetzung hier eintragen:

- [ ]

Entscheidungen waehrend der Umsetzung hier festhalten:

- [x] PoC wird ohne externe Assets umgesetzt. Karten sind einfache Rechtecke/Formen mit Farben, Labels, Typ-Markern und Progressbars.
- [x] Die Start-Mitarbeiterkarte ist `Entwickler` (`card.employee.developer`), nicht `Solo-Entwickler`. Solo ist nur der Startzustand ohne Kollegen.
- [x] Die Main Scene ist ab Phase 6 `res://scenes/application/Main.tscn`.
- [x] Drag/Drop folgt ab Phase 6 einem physischen Kartenmodell: zuletzt gezogene/gedroppte Karten liegen oben; neutrale Stacks bleiben organisierbar.
- [x] Phase 7 setzt unbezahlte Mitarbeiter bereits beim Start des naechsten Sprints um, weil ein `StartNextSprintCommand` ohne Kuendigung die GDD-Regel verletzen wuerde. Phase 8 ergaenzt darauf die restliche Sprintstart-Reihenfolge.
- [x] Phase 7 nutzt vorerst das bestehende Dev-Overlay fuer Timer, Pause, Auto-Pay und `Sprint N+1 starten`; finaler UI-Aufbau/Styling bleibt Editor-Arbeit.
- [x] Bezahlphase erlaubt ab Phase 7 weiterhin normale Kartenbewegung, damit gemischte Stacks vor manueller Bezahlung getrennt werden koennen. Processing bleibt trotzdem eingefroren.
- [x] Phase 8 macht Bug, Prod-Crash und Tech Debt bereits per Entwickler bearbeitbar. Labels sind datengetrieben: `Debugging...`, `Hotfixing...`, `Aufräumen...`.

Bekannte technische Schulden hier festhalten:

- [ ] PoC-Dauern fuer `Bug + Entwickler` und `Tech Debt + Entwickler` sind noch Balancing-Platzhalter; `Prod-Crash + Entwickler` nutzt bereits die GDD-Dauer 45s.

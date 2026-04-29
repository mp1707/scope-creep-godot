# Scope Creep - PoC-/Vertical-Slice-Plan

Dieses Dokument ist der gemeinsame Arbeitsplan fuer einen spielbaren Vertical Slice in Godot 4.6. Es beruecksichtigt `architecture.md` als Zielarchitektur und `gdd.md` v1.4 als Designquelle.

Der Plan ist bewusst phasenweise und abhakbar. In jeder Phase ist getrennt, was Codex ueber Dateien/Skripting/Resources vorbereitet und was im Godot Editor von Marco sauber gesetzt, verbunden oder visuell gepflegt werden soll. Codex soll keine Editor-Arbeit durch fragile Workarounds ersetzen.

## Fortschritt

- [ ] Phase 0 - Projektbasis und Arbeitsregeln
- [ ] Phase 1 - Zielstruktur und technische Grundtypen
- [ ] Phase 2 - Data-Resources und Content-Validator
- [ ] Phase 3 - Simulation-State und Commands
- [ ] Phase 4 - Recipe Engine und Effect Pipeline
- [ ] Phase 5 - Board-, Stack- und Card-Presentation
- [ ] Phase 6 - Erste spielbare Card-Pipeline
- [ ] Phase 7 - Sprint, Pause und Bezahlphase
- [ ] Phase 8 - Bugs, Tech Debt und Sprintstart-Ticks
- [ ] Phase 9 - Booster, Shop und deterministischer RNG
- [ ] Phase 10 - Save/Load fuer frozen Runs
- [ ] Phase 11 - Vertical-Slice-Polish und QA

## Vertical-Slice-Ziel

Am Ende des PoC soll ein kleiner, echter Spielablauf funktionieren:

1. Run startet mit Software, Solo-Entwickler, Idee, Kaffee und wenigen 1-Geld-Karten.
2. Karten koennen frei gezogen, gestapelt und als neutrale Stacks bewegt werden.
3. `Idee + Solo-Entwickler` verarbeitet zu `Funktion`.
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
- Controller-Support
- Musik
- externe Mods
- komplexe Editor-Tools
- komplette Balance

## Phase 0 - Projektbasis und Arbeitsregeln

Ziel: Klare technische Basis, damit die folgenden Phasen nicht gegen Godot-Editor-Konventionen arbeiten.

Codex:

- [ ] Bestehende Dateien pruefen: `project.godot`, `gdd.md`, `architecture.md`.
- [ ] Keine bestehenden User-Aenderungen ueberschreiben.
- [ ] Vor jeder groesseren Phase kurz `git status --short` pruefen.
- [ ] Nur Dateien/Skripte/Resources anlegen oder aendern, die fuer die Phase benoetigt werden.
- [ ] Keine Editor-spezifischen `.tscn`-Verknuepfungen per Text erzwingen, wenn sie im Editor sauberer gesetzt werden sollten.

Marco:

- [ ] Godot 4.6 Projekt einmal im Editor oeffnen und sicherstellen, dass es ohne Importfehler startet.
- [ ] Entscheiden, ob Platzhalter-Visuals vorerst reichen oder ob frueh einfache Card-Sprites/Icons eingefuegt werden.
- [ ] Nach Codex-Aenderungen Godot-Import laufen lassen und sichtbare Editor-Fehler melden.

Definition of Done:

- [ ] Projekt laesst sich in Godot 4.6 oeffnen.
- [ ] `architecture.md` und `gdd.md` bleiben die gueltigen Referenzen.
- [ ] Keine ungeklaerten Editor-Hacks im Projekt.

## Phase 1 - Zielstruktur und technische Grundtypen

Ziel: Ordner, Basisklassen und Enums so vorbereiten, dass alle weiteren Systeme architekturkonform wachsen.

Codex:

- [x] Zielordner anlegen: `data/`, `scripts/`, `scenes/`, `assets/`, `tests/` gemaess `architecture.md`.
- [ ] Resource-Basisklassen fuer `CardDefinition`, `RecipeDefinition`, `EffectDefinition`, `BoosterDefinition`, `ShopDefinition`, `BalanceDefinition` erstellen.
- [ ] Runtime-State-Klassen fuer `RunState`, `CardInstance`, `StackState`, `BoardState`, `ProcessingState` erstellen.
- [ ] Enums/Konstanten fuer Card-Typen, Run-Phasen und Processing-States definieren.
- [ ] ID-Konventionen dokumentieren oder als kleine Utility validieren.
- [ ] Keine Spielregeln in Views oder Scenes schreiben.

Marco:

- [ ] In Godot pruefen, ob die neuen Resource-Klassen im Inspector als Resource-Typen auftauchen.
- [ ] Keine manuelle Resource-Massenpflege in dieser Phase; nur Smoke-Test im Editor.

Definition of Done:

- [ ] Godot kompiliert die neuen GDScript-Klassen ohne Fehler.
- [ ] Resource-Klassen sind im Editor nutzbar.
- [ ] Runtime-State ist UI-unabhaengig.

## Phase 2 - Data-Resources und Content-Validator

Ziel: Ein kleiner, echter Content-Satz wird datengetrieben gepflegt und automatisch validiert.

Codex:

- [ ] Minimal-CardDefinitions anlegen: Software, Solo-Entwickler, Idee, Funktion, Geld, Bug, Kaffee, Boosterpack-Platzhalter.
- [ ] Minimal-RecipeDefinitions anlegen: Idee zu Funktion, Funktion zu Software, Kaffee-Modifier fuer eine Aufgabe.
- [ ] Minimal-BoosterDefinition fuer ein einfaches Gruender-/Testpack anlegen.
- [ ] BalanceDefinition mit Sprintdauer, Release-Dauer, Bug-Chance, Snap-Distanz und Stack-Offset anlegen.
- [ ] Headless Content-Validator implementieren: doppelte IDs, fehlende Referenzen, ungueltige Recipe-Inputs, leere Booster-Pools.
- [ ] Einen Godot-headless-Aufruf oder Testskript dokumentieren, mit dem der Validator laeuft.

Marco:

- [ ] Resource-Dateien im Editor oeffnen und pruefen, ob Felder sinnvoll editierbar sind.
- [ ] Platzhaltertexte, Farben oder einfache Icons im Inspector setzen, falls Codex dafuer Felder bereitstellt.
- [ ] Keine Logik im Editor nachbauen; nur Resources pflegen.

Definition of Done:

- [ ] Validator laeuft headless.
- [ ] Minimal-Content wird erfolgreich validiert.
- [ ] Ein absichtlicher Fehler, z. B. fehlende Card-ID, wird klar gemeldet.

## Phase 3 - Simulation-State und Commands

Ziel: Der Run kann ohne UI erzeugt und ueber Commands veraendert werden.

Codex:

- [ ] `RunController` oder aequivalenten Simulation-Service erstellen.
- [ ] Start-Run aus Resource-IDs erzeugen: Software, Solo-Entwickler, Idee, Kaffee, Startgeld.
- [ ] Commands implementieren: Karte bewegen, Stack bilden, Stack splitten, Pause setzen.
- [ ] Simulation-Events ausgeben: CardSpawned, StackChanged, PhaseChanged, TimerUpdated.
- [ ] Deterministischen RNG im RunState vorbereiten.
- [ ] Headless Tests fuer Startzustand, Stackbildung und neutrale Stacks schreiben.

Marco:

- [ ] Keine Editor-Aufgabe ausser Projektstart/Fehlerpruefung.
- [ ] Falls gewuenscht Startkartenliste in Resources inhaltlich pruefen.

Definition of Done:

- [ ] Start-Run kann headless erzeugt werden.
- [ ] Karten koennen logisch gestapelt und getrennt werden.
- [ ] Neutrale Stacks bleiben erlaubt und bewegbar.
- [ ] Simulation braucht keine Card-Views.

## Phase 4 - Recipe Engine und Effect Pipeline

Ziel: Recipes und Effects funktionieren als wiederverwendbarer Kern, nicht als hardcodierter PoC-Pfad.

Codex:

- [ ] Recipe-Matching fuer reine Rezeptstapel implementieren.
- [ ] Spezifitaet und `priority` beim Matchen umsetzen.
- [ ] Ambige Matches fuer Validator/Test sichtbar machen.
- [ ] Processing mit Dauer, Fortschritt, Pause und Abbruch implementieren.
- [ ] Stack-Aenderung invalidiert aktives Recipe und bricht es bei Nicht-Match ab.
- [ ] Basis-Effects implementieren: SpawnCard, RemoveCard, ConsumeInput, SpawnMoney, RollChance.
- [ ] Headless Tests fuer Recipe-Matching, Pizza-/Kaffee-aehnliche Spezifitaet, Abbruch bei Stack-Aenderung.

Marco:

- [ ] Im Editor die Recipe-Resources pruefen und bei Bedarf Anzeigenamen/Aktionstexte anpassen.
- [ ] Keine Recipe-Logik per Scene-Signal bauen; alle Regeln bleiben in Resources/Simulation.

Definition of Done:

- [ ] `Idee + Solo-Entwickler` kann headless zu `Funktion` verarbeiten.
- [ ] `Funktion + Software` kann headless Geld spawnen.
- [ ] Neutrale Zusatzkarte macht Stack neutral.
- [ ] Aktives Processing bricht bei ungueltiger Stack-Aenderung ab.

## Phase 5 - Board-, Stack- und Card-Presentation

Ziel: Der Simulation-State wird spielbar dargestellt, ohne dass Presentation Spielregeln besitzt.

Codex:

- [ ] CardView-Script erstellen: Definition anzeigen, Runtime-Marker anzeigen, Drag-Signale senden.
- [ ] BoardView-Script erstellen: CardViews aus Simulation-Events erzeugen/aktualisieren.
- [ ] StackView-/Layout-Logik erstellen: horizontal deckungsgleich, vertikal versetzt.
- [ ] Drag-and-Drop Intent an Application/Simulation senden.
- [ ] Magnetisches Snap oben auf Zielstack implementieren.
- [ ] Progressbar und Aktionstext aus StackState anzeigen.
- [ ] Kamera-Script fuer Pan/Zoom vorbereiten, soweit sinnvoll per Script.

Marco:

- [ ] Main-Scene im Godot Editor anlegen oder pruefen.
- [ ] BoardView, Camera2D, CanvasLayer/UI sauber in der Scene platzieren.
- [ ] CardView-Scene im Editor bauen: Labels, Background, Progressbar, Marker-Platzhalter.
- [ ] Scripts im Editor an die passenden Nodes haengen, wenn Codex sie nicht sicher per bestehender Scene-Struktur setzen kann.
- [ ] Font `PatrickHand-Regular.ttf` oder andere Platzhalter-Styles im Theme/Inspector setzen.

Definition of Done:

- [ ] Startkarten erscheinen sichtbar auf dem Board.
- [ ] Karten koennen mit Maus gezogen und gestapelt werden.
- [ ] Stacks sehen Stacklands-artig aus.
- [ ] Presentation mutiert keine Spielregeln direkt.

## Phase 6 - Erste spielbare Card-Pipeline

Ziel: Der Kernloop Idee -> Funktion -> Software -> Geld wird im Editor spielbar.

Codex:

- [ ] Application-Bootstrap bauen: Content laden, Run starten, BoardView verbinden.
- [ ] Timer-Update von Simulation zu Progressbar verbinden.
- [ ] Recipe-Abschluss fuer `Idee + Solo-Entwickler -> Funktion` sichtbar machen.
- [ ] Recipe-Abschluss fuer `Funktion + Software -> Geld` sichtbar machen.
- [ ] Spawn-Placement nahe Quelle implementieren, ohne Karten zu verdecken.
- [ ] Einfache Debug-UI fuer Phase/Sprint/Run-Status nur falls noetig als Dev-Overlay.

Marco:

- [ ] Im Editor Startscene als Main Scene setzen.
- [ ] Sichtbare Kartenabmessungen, Farben und Labelgroessen im CardView abstimmen.
- [ ] Boardgroesse und Kamera-Startposition im Editor pruefen.
- [ ] Im Playtest auf Lesbarkeit, Drag-Gefuehl und Snap-Distanz achten.

Definition of Done:

- [ ] Spieler kann Idee auf Solo-Entwickler ziehen.
- [ ] Fortschrittsbalken laeuft.
- [ ] Funktion spawnt an freier Position nahe dem Stack.
- [ ] Funktion auf Software erzeugt 1-Geld-Karten.

## Phase 7 - Sprint, Pause und Bezahlphase

Ziel: Der Slice bekommt den echten Sprint-Rahmen aus dem GDD.

Codex:

- [ ] Sprint-Timer in Simulation implementieren.
- [ ] Pause-Command implementieren: Timer frieren ein, Karten bleiben gemaess GDD beweglich.
- [ ] Wechsel in `PAYMENT` nach Sprintende implementieren.
- [ ] Payment-Regeln implementieren: nur Geld und Mitarbeiter beweglich/interaktiv.
- [ ] Manuelles Bezahlen: 1-Geld-Karte auf Mitarbeiter verbrauchen und Mitarbeiter markieren.
- [ ] Auto-Pay-Command optional fuer PoC, aber architekturkonform vorbereiten.
- [ ] `StartNextSprintCommand` implementieren.
- [ ] Tests fuer Phase-Wechsel, Pause und manuelles Bezahlen schreiben.

Marco:

- [ ] UI im Editor bauen: Sprint-Timer-Label, Pause-Anzeige, Button `Sprint N+1 starten`.
- [ ] Visuelle Abdunklung/Highlighting fuer Payment-Phase in CardView/Theme pruefen.
- [ ] Input-Map fuer Leertaste/Pause im Editor setzen, falls nicht per Projektdatei sauber automatisiert.

Definition of Done:

- [ ] Sprint endet nach konfigurierter Dauer.
- [ ] Bezahlphase friert Processing ein.
- [ ] Geld auf Mitarbeiter bezahlt korrekt.
- [ ] Naechster Sprint kann gestartet werden.

## Phase 8 - Bugs, Tech Debt und Sprintstart-Ticks

Ziel: Der Slice zeigt erste negative Eskalation, ohne Sonderlogik im UI.

Codex:

- [ ] Bug-Chance beim ungeprueften Release ueber `RollChanceEffect` anbinden.
- [ ] Bug-CardDefinition und Spawn aus Release-Recipe finalisieren.
- [ ] Sprintstart-Effect-Reihenfolge implementieren: Kuendigungen, Bug-Formation, Bug-Verdopplung, Auftrag-Verfall, Externer-Dev-Verfall, persistente Spawns.
- [ ] Fuer PoC mindestens Bug-Formation und Bug-Verdopplung aktivieren.
- [ ] Tech-Debt-Modifier-Service vorbereiten, auch wenn Tech Debt im PoC nur minimal sichtbar ist.
- [ ] Tests: Bug-Formation vor Bug-Verdopplung; neu verdoppelte Bugs crashen erst naechsten Sprint.

Marco:

- [ ] Bug-Visuals/Marker im Editor setzen oder Platzhalter bestaetigen.
- [ ] Playtest: Bugs sollen sichtbar genug sein und nicht unter anderen Karten spawnen.

Definition of Done:

- [ ] Ungepruefter Release kann Bug erzeugen.
- [ ] Drei vorhandene Bugs werden am Sprintstart zu Prod-Crash.
- [ ] Uebrige Bugs verdoppeln sich danach.
- [ ] Reihenfolge entspricht `gdd.md` v1.4.

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
- [ ] Platzhaltergrafiken/Sprites ersetzen, soweit fuer den Slice sinnvoll.
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

- [ ] 

Bekannte technische Schulden hier festhalten:

- [ ] 

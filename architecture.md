# Scope Creep - Architekturzielbild

Dieses Dokument beschreibt die langfristige Zielarchitektur fuer Scope Creep auf Basis von `gdd.md` v1.4. Es ist kein Vertical-Slice-Plan und keine Roadmap, sondern die technische Referenz fuer eine robuste, datengetriebene Godot-4.6/GDScript-Implementierung.

Die Architektur soll kleine erste Slices ermoeglichen, ohne spaeter in eine Quick-and-dirty-Struktur umzuschlagen. Neue Karten, Recipes, Booster, Effekte, Balancing-Werte und spaetere Systeme muessen ueber Daten und klar getrennte Laufzeitmodelle erweiterbar sein.

## 1. Grundsaetze

- **GDScript als Primaersprache:** Die Zielarchitektur nutzt GDScript und Godot-4.6-Bordmittel. C# ist nicht Teil des Zielbilds.
- **Godot Resources als Content-Basis:** Karten, Recipes, Booster, Shops, Effekte und Balancing werden als versionierte `Resource`-Assets modelliert.
- **Simulation vor Presentation:** Spielregeln laufen in einer UI-unabhaengigen Simulation. Views zeigen Zustand an und senden Spielerabsichten als Commands.
- **Definitionen sind immutable:** `CardDefinition`, `RecipeDefinition`, `BoosterDefinition` und Balance-Resources werden zur Laufzeit nicht veraendert. Laufzeitdaten liegen in State-Objekten.
- **Alles Wichtige ist eine Karte:** Burnout, Konflikt, Geld, Bugs, Prod-Crashs und spaetere Probleme sind echte `CardInstance`s, keine versteckten UI-Meter.
- **Datengetrieben, aber nicht skriptlos um jeden Preis:** Standardverhalten wird ueber Resources beschrieben. Komplexe Effekte duerfen kleine, klar begrenzte GDScript-Effect-Klassen nutzen.
- **Intern erweiterbar:** Die Architektur ist auf wachsenden eigenen Content ausgelegt. Externes Modding, Mod-Namespaces und ein Mod-Loader sind kein Initialziel.
- **Headless testbar:** Der Simulation-Core muss ohne aktive Board-UI, ohne Card-Views und ohne Godot-Editor-Interaktion testbar sein.

## 2. Layering

Die Codebasis wird in vier Schichten getrennt. Abhaengigkeiten duerfen nur nach unten gehen.

```text
Application
  -> Presentation
  -> Simulation
  -> Data
```

### Data

Die Data-Schicht enthaelt Godot `Resource`-Definitionen und keine Laufzeitlogik mit Board-Zustand.

Zustaendig fuer:

- Karten-Definitionen
- Recipe-Definitionen
- Effect-Definitionen und Effect-Parameter
- Booster- und Shop-Definitionen
- Balancing-Resources
- Content-Validierung

### Simulation

Die Simulation ist die autoritative Quelle fuer Spielzustand und Regeln. Sie darf keine Card-Views, Szenenpositionen aus der Presentation oder UI-Nodes kennen.

Zustaendig fuer:

- `RunState`, `CardInstance`, `StackState`, Board-State
- Recipe-Matching
- Effect-Ausfuehrung
- Sprint- und Phasenlogik
- RNG
- Save-kompatible Serialisierung
- Regelqueries wie Tech-Debt-Zeitaufschlag oder Konfliktblockaden

### Presentation

Presentation ist eine austauschbare Darstellung des Simulation-State. Sie darf keine Spielregel dauerhaft selbst entscheiden.

Zustaendig fuer:

- Card-Views und Stack-Views
- Drag-and-Drop
- magnetisches Snap-Verhalten
- Board-Kamera, Edge-Pan und Zoom
- Tooltips, Marker, Fortschrittsbalken
- visuelle Sperrung in der Bezahlphase
- Animationen und Sounds

Presentation sendet Spielerabsichten als Commands an Application/Simulation, z. B. `move_card_to_stack`, `split_stack`, `start_next_sprint`, `pay_employee`.

### Application

Application verbindet Menues, Scenes, Save/Load und Simulation.

Zustaendig fuer:

- Bootstrapping und Laden aller Content-Resources
- Slot-Auswahl und Savegame-Verwaltung
- Scene-Orchestrierung
- Weiterleitung von UI-Commands an die Simulation
- Anwendung von Simulation-Events auf Presentation
- globale Pause und Run-Lifecycle

## 3. Zielstruktur

Die Zielstruktur ist eine Empfehlung fuer die langfristige Organisation. Sie muss nicht vollstaendig existieren, bevor der erste Slice gebaut wird.

```text
res://data/cards/
res://data/recipes/
res://data/effects/
res://data/boosters/
res://data/shops/
res://data/balance/

res://src/application/
res://src/simulation/
res://src/presentation/
res://src/save/
res://src/validation/

res://tests/
```

IDs sind stabile `snake_case`-Strings mit Domain-Praefix:

```text
card.employee.developer
card.problem.bug
recipe.feature_from_story.dev
recipe.burnout_recovery.pizza
booster.office_invest
effect.spawn_card
```

IDs duerfen nach Release nicht umbenannt werden, ohne eine Savegame-Migration oder Alias-Regel zu definieren.

## 4. Content-Resources

### CardDefinition

`CardDefinition` beschreibt statische Kartendaten.

Mindestfelder:

- `id: String`
- `display_name: String`
- `type: CardType`
- `tags: PackedStringArray`
- `short_text: String`
- `tooltip_text: String`
- `visual: CardVisualDefinition`
- `base_values: Dictionary`
- `default_state: Dictionary`

Beispiele fuer `type`:

- `EMPLOYEE`
- `INPUT`
- `TASK`
- `OUTPUT`
- `PROBLEM`
- `RESOURCE`
- `PROCESS`
- `VALUE_SOURCE`
- `PRODUCT`
- `CONSUMABLE`

Tags ermoeglichen generisches Matching, z. B. `employee`, `developer`, `problem`, `bug`, `money`, `conflict`, `burnout`, `feature`.

### RecipeDefinition

`RecipeDefinition` beschreibt eine wirksame Stack-Kombination.

Mindestfelder:

- `id: String`
- `display_text: String`
- `inputs: Array[RecipeInputMatcher]`
- `constraints: Array[RecipeConstraintDefinition]`
- `duration: DurationDefinition`
- `priority: int`
- `specificity_score: int`
- `effects_on_start: Array[EffectDefinition]`
- `effects_on_complete: Array[EffectDefinition]`
- `effects_on_cancel: Array[EffectDefinition]`
- `allowed_extra_inputs: Array[RecipeInputMatcher]`

Recipes matchen auf reine Rezeptstapel. Karten, die weder Input noch explizit erlaubter Zusatzinput sind, machen den Stapel neutral. Reihenfolge ist fuer das Matching egal; die visuelle Stack-Reihenfolge bleibt aber erhalten.

Wenn mehrere Recipes matchen, gilt:

1. Hoeherer `specificity_score` gewinnt.
2. Bei gleicher Spezifitaet gewinnt das vorteilhaftere Recipe ueber `priority`.
3. Bleibt ein Gleichstand, ist der Content fehlerhaft und muss vom Validator gemeldet werden.

Beispiel: `Mitarbeiter + Burnout + Pizza Party` gewinnt gegen `Mitarbeiter + Burnout`, weil das Pizza-Recipe spezifischer ist und 5 Sekunden statt 45 Sekunden dauert.

### EffectDefinition

Effects sind kleine, kombinierbare Aktionen. Recipe-Abschluss, Soforteffekte, Booster-Oeffnung und Sprintstart-Ticks nutzen dieselbe Effect-Pipeline.

Standard-Effects:

- `SpawnCardEffect`
- `RemoveCardEffect`
- `AttachCardEffect`
- `DetachCardEffect`
- `MoveCardEffect`
- `SetInstanceValueEffect`
- `ModifyInstanceValueEffect`
- `StartProcessingEffect`
- `ConsumeInputEffect`
- `RollChanceEffect`
- `SpawnMoneyEffect`
- `CreateConflictEffect`
- `RemoveConflictEffect`
- `AbortProcessingEffect`
- `MarkEmployeePaidEffect`
- `QuitUnpaidEmployeesEffect`
- `FormProdCrashEffect`
- `DuplicateBugsEffect`
- `ExpireCardsEffect`
- `OpenBoosterEffect`

Ein Effect bekommt einen `EffectContext` mit Zugriff auf Run-State, Stack, ausloesendes Recipe, RNG, Source-Card und Result-Collector. Effects mutieren nur den Simulation-State, nie Presentation-Nodes.

### BoosterDefinition

`BoosterDefinition` beschreibt Pack-Inhalte und Ziehregeln.

Mindestfelder:

- `id: String`
- `display_name: String`
- `cost_money_cards: int`
- `draw_count: int`
- `pool_entries: Array[BoosterPoolEntry]`
- `open_effects: Array[EffectDefinition]`

Pool-Eintraege referenzieren `CardDefinition`-IDs und Gewichte. Booster-Ziehungen laufen ueber den Run-RNG, damit Tests und Save/Load deterministisch bleiben.

### ShopDefinition

Shops sind ebenfalls datengetrieben. Einzelkarten-Shop und Booster-Slot sind Varianten desselben Kaufmodells.

Mindestfelder:

- `id: String`
- `entries: Array[ShopEntryDefinition]`

Ein `ShopEntryDefinition` enthaelt Kosten in 1-Geld-Karten, Zielkarte oder Booster, Verfuegbarkeitsbedingungen und optionale Kauf-Effects.

### BalanceDefinition

Balancing-Werte liegen nicht hardcodiert in Recipes oder Systems.

Beispiele:

- Sprintdauer
- Burnout-Anstieg pro produktiver Taetigkeit
- Burnout-Erholungsdauer
- Pizza-Party-Erholungsdauer
- Tech-Debt-Zeitaufschlag
- Bug-Chance beim ungeprueften Release
- Workshop-Konfliktchance
- Prod-Crash-Reparaturdauer
- Board-Snap-Distanz
- Stack-Offset
- Spawn-Placement-Radius

## 5. Runtime-State

### RunState

`RunState` ist der vollstaendige serialisierbare Zustand eines Runs.

Mindestfelder:

- `run_id: String`
- `sprint_index: int`
- `phase: RunPhase`
- `is_paused: bool`
- `rng_state`
- `cards: Dictionary[String, CardInstance]`
- `stacks: Dictionary[String, StackState]`
- `board: BoardState`
- `active_timers: Dictionary`
- `paid_employee_ids: PackedStringArray`
- `content_version: String`

`RunState` ist die einzige Quelle fuer Simulation-Wahrheit. Presentation darf daraus Views erzeugen, aber keine eigenen Spielregelzustaende fuehren.

### CardInstance

`CardInstance` beschreibt eine konkrete Karte im Run.

Mindestfelder:

- `instance_id: String`
- `definition_id: String`
- `stack_id: String`
- `parent_card_id: String`
- `attachment_slot: String`
- `position: Vector2`
- `state: CardRuntimeState`
- `values: Dictionary`
- `created_at_sprint: int`

`parent_card_id` und `attachment_slot` modellieren angeheftete Karten wie Burnout oder Konflikt. Eine Konfliktkarte bleibt eine normale CardInstance, klebt aber an Bob und referenziert Alice ueber `values.target_employee_id`.

Geld ist immer eine CardInstance mit Definition `card.resource.money` und Wert 1. Groessere Betraege sind mehrere Geldkarten, nicht ein Instance-Wert.

### StackState

`StackState` beschreibt eine logische Kartengruppe.

Mindestfelder:

- `stack_id: String`
- `card_ids: PackedStringArray`
- `base_position: Vector2`
- `active_recipe_id: String`
- `processing_state: ProcessingState`
- `elapsed: float`
- `duration: float`
- `is_processing_paused: bool`

Die Stack-Reihenfolge wird fuer Darstellung und Drag-Verhalten gespeichert. Recipe-Matching behandelt die enthaltenen Karten als ungeordnete Menge plus Constraints.

### BoardState

`BoardState` beschreibt Board-Groesse und logische Platzierung.

Mindestfelder:

- `size: Vector2`
- `camera_state`
- `reserved_areas`
- `spawn_history`

Die Simulation kennt logische Positionen und Stacks. Presentation berechnet daraus Card-Offsets, Hover-Reihenfolge und Animationen.

## 6. Commands und Events

Spieleraktionen werden als Commands an die Simulation gereicht. Dadurch bleiben UI und Regeln getrennt.

Beispiele:

- `MoveCardCommand(card_id, target_stack_id)`
- `MoveStackCommand(stack_id, position)`
- `SplitStackCommand(card_id)`
- `PayEmployeeCommand(money_card_id, employee_id)`
- `AutoPayCommand()`
- `OpenBoosterCommand(money_card_id, booster_card_id)`
- `StartNextSprintCommand()`
- `PauseCommand()`
- `SaveRunCommand(slot_id)`

Die Simulation antwortet mit Events, die Presentation und Application anwenden koennen.

Beispiele:

- `CardSpawned`
- `CardRemoved`
- `StackChanged`
- `RecipeStarted`
- `RecipeCancelled`
- `RecipeCompleted`
- `PhaseChanged`
- `TimerUpdated`
- `EmployeePaid`
- `RunEnded`
- `ValidationWarning`

Events sind nicht die Savegame-Quelle. Sie dienen der Darstellung, Animation, Audio und Debugbarkeit.

## 7. Recipe Engine

Die Recipe Engine ist ein eigenstaendiger Simulation-Service.

Aufgaben:

- Kandidaten-Recipes fuer einen Stack finden
- Input-Matcher gegen CardInstances und Tags pruefen
- Constraints pruefen
- spezifischstes Recipe waehlen
- bei Gleichstand Priority anwenden
- Ambiguitaeten an Validator/Debug melden
- Dauer ueber DurationDefinition und Modifier berechnen
- Processing starten, fortschreiben, pausieren, abbrechen und abschliessen

### Stack-Aenderungen

Jede Stack-Aenderung triggert eine Neupruefung:

1. Wenn kein aktives Recipe existiert, wird ein passendes Recipe gesucht.
2. Wenn ein aktives Recipe existiert und weiterhin exakt passt, laeuft es weiter.
3. Wenn ein aktives Recipe nicht mehr passt, wird es sofort abgebrochen.
4. Nach dem Abbruch darf der neue Stack direkt ein anderes Recipe starten, wenn er passt.

Beim Abbruch verschwindet nur der Arbeitsbalken. Es entsteht kein `cancelled`-State und kein separates Cancel-Objekt. Karten bleiben im neuen Stack-Zustand, ausser ein Recipe definiert explizite Cancel-Effects.

### Constraints

Constraints halten Sonderregeln aus Recipe-Code heraus.

Beispiele:

- Mitarbeiter darf nicht bereits durch Burnout processing-blockiert sein.
- Zwei Konfliktparteien duerfen keinen gemeinsamen Stack bilden, ausser das Recipe verlangt genau diesen Konflikt.
- Konfliktworkshop verlangt Konfliktkarte plus beide referenzierten Parteien.
- Bezahlphase erlaubt nur Geld-auf-Mitarbeiter-Interaktionen.
- Kaffee wirkt nur, wenn Kaffee Teil des Arbeits-Recipes ist.

## 8. Effect Pipeline

Effects laufen in einer deterministischen Pipeline. Jeder Effect erhaelt denselben `EffectContext` und erzeugt optional weitere Effects oder Events.

Quellen fuer Effects:

- Recipe-Start
- Recipe-Abschluss
- Sofort-Recipes wie Bugfix-Patch oder Stressbewaeltigungskurs
- Sprintstart-Ticks
- Booster-Oeffnung
- Shop-Kauf
- Save/Load-Migrationen, falls spaeter noetig

### Query- und Modifier-System

Globale Regeln werden nicht in jedes Recipe kopiert.

Beispiele:

- Tech-Debt fragt alle Tech-Debt-Karten auf dem Board ab und addiert pro Karte Zeit auf Feature- und Bugfix-Recipes.
- Prod-Crash fragt, ob mindestens ein Prod-Crash auf dem Board existiert, und blockiert Geld-Spawn aus Releases.
- Burnout-Counter wird nach produktiven Taetigkeiten ueber einen Employee-Modifier/Effect erhoeht.
- Kaffee reduziert die Dauer eines Recipes, wenn Kaffee Teil des Stack-Inputs ist.

Dieses System soll als `RuleQueryService` oder aehnlicher Simulation-Service modelliert werden. Recipes fragen keine globalen Nodes ab.

## 9. Sprint- und Phasenlogik

Es gibt zwei Run-Phasen:

- `SPRINT`
- `PAYMENT`

### SPRINT

In der Sprint-Phase laufen Timer, wenn das Spiel nicht pausiert ist. Karten duerfen bewegt und gestapelt werden. Booster und Shop-Kaeufe passieren live.

Pause friert alle Processing-Timer ein. Karten bleiben beweglich, solange die GDD-Regel es erlaubt. Save ist nur erlaubt, wenn der Run pausiert oder in der Bezahlphase eingefroren ist.

### PAYMENT

Beim Ablauf des Sprint-Timers wechselt der Run in `PAYMENT`.

Regeln:

- Alle Processing-Timer bleiben pausiert.
- Board und Stacks bleiben visuell erhalten.
- Beweglich sind nur Geldkarten und Mitarbeiter.
- Manuelles Bezahlen verbraucht genau eine 1-Geld-Karte.
- Auto-Pay ist nur verfuegbar, wenn genug Geld fuer alle regulären Mitarbeiter existiert.
- Bezahlte Mitarbeiter werden im RunState markiert.

### Sprintstart-Effekte

Nach Klick auf `Sprint N+1 starten` werden Effects in exakt dieser Reihenfolge ausgefuehrt:

1. Unbezahlte Mitarbeiter kuendigen; laufende Bearbeitungen mit ihnen brechen ab; Konflikte mit ihnen verschwinden.
2. Je 3 bereits vorhandene Bugs formen 1 Prod-Crash.
3. Uebrig gebliebene Bugs verdoppeln sich.
4. Nicht erfuellte Auftraege verfallen.
5. Externer Dev verfällt, wenn seine Lifecycle-Regel greift.
6. Persistente Tick-Karten wie Kunde und Kaffeemaschine spawnen ihre Karten.

Danach startet die neue Sprint-Phase und der Sprint-Timer laeuft wieder.

## 10. Board, Stacks und Attachments

Das Board verwaltet logische Positionen, Stacks und Spawn-Placement.

### Drag und Snap

- Karten besitzen freie `Vector2`-Positionen.
- Beim Drop sucht das Board den naechsten gueltigen Zielstack innerhalb der Snap-Distanz.
- Eine Karte snappt immer oben auf den Zielstack.
- Neutrale Stacks bleiben erlaubt und koennen als Gruppe bewegt werden.
- Es gibt keine harte Stackgroesse; UI-Lesbarkeit ist die praktische Grenze.

### Darstellung

Presentation rendert Stacks Stacklands-artig:

- horizontal exakt uebereinander
- vertikal leicht versetzt
- obere Karte ist visuell im Vordergrund
- Progressbar und Aktionstext gehoeren zum aktiven Stack, nicht zu einer einzelnen View

### Spawn-Placement

Neue Karten spawnen an einer freien Position nahe der Quelle. Der Placement-Service sucht Positionen, die keine bestehende Karte verdecken und nicht unter einer Karte liegen.

Der Placement-Service ist Teil der Board-Simulation oder ein deterministic helper. Presentation darf die Spawn-Position animieren, aber nicht eigenmaechtig andere Zielpositionen waehlen.

### Attachments

Attachments sind normale CardInstances mit Parent/Anchor.

Beispiele:

- Burnout klebt an einem Mitarbeiter.
- Konflikt klebt an einem Mitarbeiter und referenziert eine Zielperson.
- Spaetere Upgrades koennen an Mitarbeiter oder Software angeheftet werden.

Attachments bewegen sich mit dem Parent. Ob sie fuer ein Recipe zaehlen, entscheidet das Recipe-Matching. Konflikt wird fuer normale Solo-Recipes ignoriert, zaehlt aber fuer Konflikt-Recipes.

## 11. Save/Load

Savegames serialisieren den gefrorenen `RunState`, nicht die Presentation.

Save ist nur erlaubt:

- waehrend manueller Pause in der Sprint-Phase
- waehrend der Bezahlphase

Gespeichert werden mindestens:

- Content-Version
- Sprintnummer und Phase
- Pause-Status
- RNG-State
- alle CardInstances inklusive Definition-ID, Runtime-Werten, Attachments und Position
- alle StackStates inklusive Reihenfolge und Processing-Fortschritt
- BoardState
- bezahlte Mitarbeiter
- laufende Timer und aktive Recipe-IDs

Beim Laden wird das Spiel automatisch pausiert. Presentation baut Card-Views und Stack-Views aus dem geladenen RunState neu auf.

Savegames speichern Definition-IDs, nicht kopierte Definition-Daten. Wenn Content-IDs geaendert werden, braucht es Migrationen oder Aliase.

## 12. Validation

Ein Content-Validator ist Teil des Zielbilds und wird vor Custom Editor Tools priorisiert.

Der Validator prueft mindestens:

- doppelte IDs
- fehlende oder ungueltige Referenzen auf Karten, Tags, Recipes, Effects, Booster und Shops
- Recipes, die nie matchen koennen
- ambige Recipe-Matches ohne eindeutige Priority
- Booster ohne gueltigen Pool
- Shop-Eintraege mit ungueltigen Kosten oder Targets
- Effects mit fehlenden Pflichtparametern
- CardDefinitions ohne Typ, Text oder Visual-Minimum
- Save-relevante ID-Umbenennungen ohne Migration/Alias

Der Validator soll headless laufen koennen und klare Fehlertexte mit Resource-Pfad und ID ausgeben.

## 13. Testing

Die Simulation muss headless testbar sein. Tests duerfen keine Card-Views, Kamera oder Drag-Animationen brauchen.

Pflichtszenarien:

- Recipe-Matching mit neutralen Stacks.
- Spezifischeres Recipe gewinnt, z. B. Burnout + Pizza Party.
- Priority-Gleichstand wird erkannt oder eindeutig aufgeloest.
- Stack-Aenderung bricht laufendes Processing ab.
- Sprintstart-Effects laufen in GDD-Reihenfolge.
- Bug-Formation passiert vor Bug-Verdopplung.
- Neu verdoppelte Bugs formen erst beim naechsten Sprintstart einen Prod-Crash.
- Konfliktkarte blockiert gemeinsame Stacks mit Zielperson.
- Konfliktkarte wird fuer normale Solo-Recipes ignoriert.
- Kaffee wirkt nur als Teil des naechsten Arbeits-Recipes.
- Geld bleibt immer 1-Geld-Karte.
- Save/Load eines frozen RunState erhaelt Timer-Fortschritt, Stacks, Attachments und RNG-State.
- Booster-Ziehung ist mit gleichem RNG-State deterministisch.

Tests sollen bevorzugt gegen Simulation-Services und State-Objekte laufen. Presentation-Tests pruefen nur UI-spezifisches Verhalten wie Stack-Offset, Drag-Snap und Sichtbarkeit der Bezahlphasen-Sperren.

## 14. Performance-Ziel

Das GDD erwartet 50 bis 100 sichtbare Karten im normalen Spielverlauf und Spitzen bis etwa 200 Karten. Die Architektur muss dafuer ausgelegt sein.

Ziele:

- Recipe-Matching nur fuer veraenderte Stacks ausfuehren, nicht fuer das ganze Board pro Frame.
- Timer-Updates in Simulation zentralisieren.
- Card-Views poolbar halten, falls Spaetphasen-Spawns haeufig werden.
- Effekte batchweise ausfuehren und Events gesammelt an Presentation geben.
- Board-Placement mit einfachen Spatial-Queries oder Grid-Bucketing vorbereiten, sobald naive Suche messbar teuer wird.
- Resources beim Start laden und validieren, nicht waehrend Drag-Operationen.

Performance-Optimierungen duerfen die Trennung von Simulation und Presentation nicht aufweichen.

## 15. Grenzen des Zielbilds

Nicht Teil dieser Architektur:

- externer Mod-Loader
- Netzwerk/Multiplayer
- Touch-Steuerung
- Custom Editor Panels als Initialziel
- C#-Core
- eine Vertical-Slice-Roadmap

Diese Punkte koennen spaeter bewusst ergaenzt werden, sollen aber die Initialarchitektur nicht komplizierter machen.


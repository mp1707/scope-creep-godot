# AGENTS.md - Scope Creep

Diese Datei beschreibt, wie Codex in diesem Projekt arbeiten soll. Sie gilt fuer alle Arbeiten im Repository.

## Rolle

Codex ist mein technischer Mentor und Implementierungspartner.

- Wenn ich um Anleitung bitte, fuehrst du mich Schritt fuer Schritt durch.
- Wenn ich um Umsetzung bitte, implementierst du selbststaendig im Repo.
- Nach jeder Implementierung erklaerst du kurz:
  - was geaendert wurde,
  - warum es so geloest wurde,
  - wie es funktioniert,
  - wie ich es im Godot Editor pruefen oder weiter verbinden soll.
- Du benennst technische Risiken direkt und frueh.
- Du vermeidest Quick-and-dirty-Loesungen, auch im PoC, wenn sie der Zielarchitektur widersprechen.

## Sprache und Stil

- Antworte auf Deutsch.
- Sei knapp, konkret und handlungsorientiert.
- Keine langen Meta-Erklaerungen, wenn eine klare Anweisung reicht.
- Bei Fehlern oder schlechten Annahmen: direkt benennen, hoeflich und ohne Umweg.
- Bei Entscheidungspunkten:
  - 2-3 sinnvolle Optionen nennen,
  - Trade-offs kurz erklaeren,
  - klare Empfehlung aussprechen.
- Im Guide-Modus: ein sinnvoller Schritt pro Antwort, nicht fuenf parallele Aufgaben.
- Code-Snippets nie nackt posten: immer Datei, Node/Scene-Kontext und Ausloeser/Event nennen.

## Projektquellen

Vor Architektur- oder Gameplay-Entscheidungen pruefen:

1. `gdd.md` - Game Design Document und Regelwahrheit.
2. `architecture.md` - langfristiges technisches Zielbild.
3. `current_scope.md` - aktueller Umsetzungsstand und Scope-Kontext.

Wenn eine geplante Loesung einem dieser Dokumente widerspricht:

- nicht still ueberbruecken,
- Widerspruch kurz benennen,
- bei Widerspruch zu `gdd.md` oder `architecture.md` Marco vor der Umsetzung explizit fragen,
- nach bestaetigter Abweichung die betroffenen Dokumente im selben Arbeitsschritt aktualisieren, damit sie aktuell bleiben.

Wenn Dokumente unklar oder widerspruechlich sind, klaeren wir die Regel, statt implizit eine neue zu erfinden.

Dokumente sollen laufend aktuell gehalten werden. Wenn eine Implementierung Regeln, Architektur oder bereits umgesetzten Scope veraendert, werden `gdd.md`, `architecture.md` und/oder `current_scope.md` entsprechend aktualisiert.

## Godot-Version und Technologie

- Zielversion: Godot 4.6.
- Primaersprache: GDScript.
- Content und Balancing: Godot `Resource`-Assets.
- Kein C#-Core.
- Kein externer Mod-Loader im Initialziel.
- Simulation muss headless testbar bleiben.

## Godot Best Practices

Bei jeder Empfehlung und jedem Snippet konsequent auf saubere, skalierbare Godot-Entscheidungen achten. Kurzfristige Vereinfachungen werden zu spaeteren Schulden; solche Risiken aktiv markieren.

### GDScript

- Statisches Typing konsequent verwenden:
  - Variablen typisieren.
  - Funktionsparameter typisieren.
  - Rueckgabewerte typisieren.
  - Signal-Parameter typisieren.
- Wiederverwendbare Typen mit `class_name` versehen.
- Keine untypisierten Dictionary-Strukturen als Ersatz fuer echte Resources oder State-Klassen verwenden.
- Keine globalen String-IDs frei im Code verstreuen; stabile IDs gehoeren in Resources/Konstanten/Validierung.

### Scenes und Nodes

- Eine Scene, eine Aufgabe.
- Keine God Objects.
- Wenn ein Script mehrere Verantwortlichkeiten hat oder grob ueber 150 Zeilen waechst: Aufteilung pruefen.
- Node-Verantwortlichkeiten klar halten:
  - Presentation zeigt Zustand und sammelt Input.
  - Simulation entscheidet Regeln.
  - Application verbindet Scenes, Save/Load und Run-Lifecycle.
- Keine Gameplay-State-Mutation direkt aus UI-Code.
- Keine fragilen Node-Pfade wie `get_node("../../Foo")`, wenn ein Signal, Export oder Controller sauberer ist.

### Daten und Resources

- Alles Konfigurierbare als `Resource` modellieren:
  - Karten
  - Recipes
  - Effects
  - Booster
  - Shops
  - Balancing-Werte
- Card-/Recipe-/Booster-Definitionen zur Laufzeit nicht veraendern.
- Runtime-Zustand liegt in `CardInstance`, `StackState`, `RunState` usw.
- Neue Karten oder Balancing-Aenderungen sollen moeglichst ohne Code-Aenderung funktionieren.
- Content-Validierung ist Pflicht, sobald Resources referenziert werden.

### Kopplung

- Signals und lose Kopplung bevorzugen.
- Lokale Signals fuer Parent/Child-Kommunikation.
- Application/Controller fuer Simulation-Commands.
- EventBus nur fuer echte cross-cutting Events verwenden, nicht als Ersatz fuer klare Ownership.
- `@export` fuer editorseitige Konfiguration nutzen, wenn der Wert im Editor gepflegt werden soll.

### Komposition

- Komposition vor Vererbung.
- Kleine wiederverwendbare Komponenten bevorzugen.
- Keine tiefen Klassenhierarchien fuer Kartenlogik.
- Spezialverhalten zuerst als Daten, Constraints, Effects oder Modifier modellieren, nicht als Subclass pro Karte.

### Performance

Das GDD plant 50-100 sichtbare Karten, Spitzen bis ca. 200 Karten.

- Kein per-frame globales Suchen wie `get_tree().get_nodes_in_group()` fuer Gameplay-Regeln.
- Recipe-Matching nur fuer veraenderte Stacks ausfuehren.
- Timer zentral in der Simulation verwalten.
- CardViews bei Bedarf poolbar halten.
- Spawn-/Snap-Suche so bauen, dass spaeter Grid/Bucketing moeglich ist.
- Resources beim Start laden/validieren, nicht waehrend Drag-Operationen.

## Scope-Creep-spezifische Architekturregeln

- `gdd.md` v1.4 ist die Regelquelle.
- `architecture.md` ist die technische Zielquelle.
- `current_scope.md` beschreibt, was bereits umgesetzt ist und welcher Scope aktuell gilt.
- Keine PoC-Sonderwege, die spaeter sicher ersetzt werden muessen, ohne sie klar als technische Schuld zu markieren.
- Simulation und Presentation bleiben getrennt.
- UI sendet Commands/Intents; Simulation mutiert `RunState`.
- Recipe Engine, Effect Pipeline, Sprint State Machine und Save/Load muessen headless testbar bleiben.

Wichtige GDD-Regeln, die nicht verletzt werden duerfen:

- Geld ist immer eine 1-Geld-Karte.
- Konflikt ist eine einseitige, angeheftete Karte mit Zielperson.
- Kaffee ist eine aktive Processing-Interaktion auf laufende Mitarbeiterarbeit, kein Recipe-Input.
- Sprintstart-Ticks passieren erst beim Start des naechsten Sprints.
- Bug-Formation passiert vor Bug-Verdopplung.
- Save ist nur im pausierten/frozen Zustand erlaubt.
- Reine Rezeptstapel: nicht erlaubte Zusatzkarten machen den Stack neutral.
- Spezifischere/vorteilhaftere Recipes gewinnen; Gleichstand braucht explizite Priority.
- Jede Stack-Aenderung, die ein aktives Recipe invalidiert, bricht Processing sofort ab.

## Zusammenarbeit bei Godot-Editor-Aufgaben

Codex soll nicht hacky Dinge im Textformat erzwingen, die im Godot Editor sauberer erledigt werden.

Codex macht:

- GDScript schreiben.
- Resources vorbereiten, wenn das per Datei sinnvoll und stabil ist.
- Tests und Validatoren schreiben.
- klare Editor-Anweisungen geben.
- erklaeren, welche Nodes/Scenes/Exports verbunden werden muessen.

Marco macht im Editor:

- Scenes visuell zusammenbauen, wenn Layout/Node-Struktur editorseitig sauberer ist.
- Scripts an Nodes haengen, wenn Codex die Scene-Struktur nicht stabil kennen kann.
- Sprites, Fonts, Themes, Icons und visuelle Platzhalter setzen.
- Input Map pruefen oder setzen, wenn das bewusst im Editor passieren soll.
- Inspector-Werte abstimmen, die visuelles Gefuehl betreffen.

Wenn Codex eine Editor-Aufgabe automatisieren will, muss die Loesung robust und nachvollziehbar sein. Sonst klare Anleitung geben statt Hack.

## Tests und Validierung

- Headless Tests fuer Simulation priorisieren.
- Presentation nur dort testen, wo UI-Verhalten wirklich relevant ist.
- Content-Validator ausbauen, sobald neue Resource-Typen entstehen.
- Nach relevanten Aenderungen passende Tests oder zumindest Validator/Headless-Check ausfuehren.
- Wenn Tests nicht laufen koennen, Grund klar nennen.

Mindestens zu testen, sobald Systeme existieren:

- Recipe-Matching mit neutralen Stacks.
- Spezifischeres Recipe gewinnt.
- Stack-Aenderung bricht Processing ab.
- Sprintstart-Effect-Reihenfolge.
- Konflikt-Attachments und gemeinsame Stack-Blockade.
- Kaffee als Recipe-Teil.
- Geld als 1-Geld-Karte.
- Save/Load frozen RunState.
- Booster-Ziehung mit deterministischem RNG.

## Dateikonventionen

- Scenes: `PascalCase.tscn`
- Scripts: `snake_case.gd`
- Resources: `snake_case.tres`
- Directories: `snake_case`
- Signals: Vergangenheit oder klares Ereignis, z. B. `card_moved`, `recipe_completed`, `phase_changed`.
- IDs: stabile Strings mit Domain-Praefix, z. B. `card.employee.developer`, `recipe.feature_from_story.dev`.

Abweichungen nur mit Begruendung.

## Arbeitsweise bei Implementierungen

Vor Aenderungen:

- Relevante Dateien lesen.
- `git status --short` pruefen.
- Bestehende User-Aenderungen nicht ueberschreiben.

Waehrend der Arbeit:

- Kleine, zusammenhaengende Schritte.
- Keine unrelated Refactors.
- Keine generierten Massenumbauten ohne Not.
- Keine Formatierer laufen lassen, die fremde Dateien veraendern, ausser explizit gewuenscht.

Nach der Arbeit:

- Kurz zusammenfassen, was geaendert wurde.
- Tests/Checks nennen.
- Offene Editor-Aufgaben fuer Marco nennen.
- Wenn etwas bewusst noch nicht final ist, als technische Schuld oder naechsten Schritt markieren.

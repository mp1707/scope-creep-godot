# Current Scope - Gameplay-Stand

Stand: aktueller Build.

Dieses Dokument beschreibt den aktuellen Spielumfang aus Spielersicht. Es ist keine Zielbeschreibung des fertigen Spiels, sondern eine Momentaufnahme: Was kann man im aktuellen Build tun, welche Systeme sind schon spielbar und welche Karten existieren?

## Kurzfazit

Der aktuelle Stand ist ein kleiner, aber geschlossener Management-Run auf Kartenbasis.

Man startet mit einer MVP-Software, baut Features, finanziert sich dauerhaft ueber den Freelance-Shop-Slot, entscheidet den Launch manuell, bedient danach Kunden, bezahlt Business Goals, verwaltet Bugs, Tech Debt, Prod-Crashes und Burnout und kann das Team ueber eine langsame Hiring-Pipeline aus Bewerbern, Angeboten und Onboarding vergroessern.

Das Spiel ist damit mehr als ein reiner Recipe-Test. Es hat inzwischen einen Anfang, einen Launch-Wendepunkt, Post-Launch-Druck, Sieg- und Niederlagebedingungen sowie kontrolliertes Teamwachstum. Balance, Lesbarkeit, UI-Polish, Content-Breite, Konflikte, Workshops, finale Card-Art, Tutorial und Meta-Progression fehlen aber noch oder sind bewusst nicht final.

Die Karten-Presentation hat inzwischen ein einheitliches Juice-System: Hover, Drag-Lift, verzoegertes Drag-Follow, subtile Drag-Rotation, Snap-Bounce, Schattenzustaende und Drop-Ziel-Feedback laufen zentral ueber die CardView-Presentation und nicht ueber verstreute Einzel-Tweens. Das Visual-Theming ist als `GameVisualThemeDefinition` zentral geladen: Board, HUD, Tooltips, Status-Badges, Shop-Dock-Preview und Card-Surface-Werte kommen aus dem aktiven Visual-Theme. Das Board nutzt einen leicht offwhitefarbenen Dotgrid-Hintergrund; Punktfarbe, Abstand und Radius sind Teil des aktiven Visual-Themes. Die aktuelle Kartenpalette orientiert sich an hellen Post-it-Toenen statt gedeckten Ockerfarben. Kartenicons nutzen einen Scribble-Kreis als Hintergrund; Scribble und Icon-Farbe werden aus dunkleren Toenen der jeweiligen Kartenfarbe abgeleitet, waehrend Header-Text einen einheitlichen dunkel blau-grauen Ton nutzt. Bestehende Karten behalten ihre direkten `CardVisualDefinition`-Farben als Overrides; neue Karten koennen ueber semantische `visual_role_id`s aus dem Theme starten. SFX bleiben davon getrennt.

Beim Draggen fragt die Presentation die Simulation nach allen aktuell gueltigen Drop-Zielen. Passende Board- und Shop-Stacks werden waehrend des Drags mit einem horizontal gespiegelten Pfeil am rechten oberen Karteneck markiert; der Pfeil nutzt die Header-Textfarbe der Zielkarte. Nach erfolgreichem Stapeln spielt kurz ein Snap-Feedback mit Corner-Stripes an zwei diagonal gegenueberliegenden Ecken der gestackten Karte. Die Preview zeigt nur Drops, die nach aktueller Phase, Stack-Inhalt, Mengen und Processing-Zustand wirklich ausfuehrbar sind; theoretische Spaeter-Kombinationen werden nicht markiert.

`CardView.tscn` enthaelt die sichtbare Karten-Node-Struktur jetzt vollstaendig als editorseitig anpassbare Scene. Das Script bindet Content, Runtime-Zustand, Theme und Juice, erzeugt aber normale sichtbare Kartenbestandteile nicht mehr still nach. Karten-Tooltips sind in `CardTooltipView.tscn`/`card_tooltip_view.gd` ausgelagert, damit Tooltip-Layout und Styling ebenfalls im Editor feinjustierbar bleiben.

## Wie eine Runde aktuell startet

Der Run startet als Pre-Launch-MVP. Auf dem Board liegt im aktuellen Startsetup nur ein spezielles Boosterpack:

- `Dein Startup` mit Sternsymbol und 8 Oeffnungen.
- Beim Oeffnen erscheinen in fixer Reihenfolge: Software mit MVP-Fortschritt `0 / 5 Features`, Entwickler, Idee, Kaffee, vier einzelne Geldkarten.
- Shop-/Booster-Zugaenge fuer Gruenderpanik, Wohlbefinden, Talent-Pool, externen Bugfix, Freelance-Auftrag und Resteverwertung bleiben als Dock-Interaktionen live. Kundenchaos wird nach Launch als zusaetzlicher Dock-Zugang aktiviert.

Geld ist wie im GDD vorgesehen keine Zahl im UI. Eine Geldkarte entspricht immer genau 1 Geld.

Der Spieler kann Karten per Drag-and-Drop bewegen, stapeln und wieder auseinanderziehen. Passende Stacks starten automatisch Processing mit Aktionstext und Fortschritt. Nicht passende Zusatzkarten machen einen Stack neutral; der Stack bleibt trotzdem bewegbar und organisierbar. Wenn mehrere passende Aufgaben auf einem aktiven Mitarbeiter- oder Zielstack liegen, wird die unterste Aufgabe zuerst bearbeitet. Oberhalb gestapelte weitere Aufgaben bleiben in der Warteschlange und brechen die laufende Bearbeitung nicht ab.

## Aktueller Run-Bogen

### 1. Pre-Launch: MVP bauen und Geld sichern

Vor Launch erzeugt die eigene Software noch kein Geld. Funktionen auf Software erhoehen stattdessen den MVP-Featurezaehler.

Der Grundkonflikt ist:

```text
Funktion ins Produkt integrieren -> MVP-Fortschritt
Funktion in den Freelance-Slot dumpen -> sofort Geld
```

Der Spieler braucht genug Features fuer den Launch, muss aber gleichzeitig Gehaelter, Booster, Bugfixes und spaeter Hiring bezahlen.

### 2. Launch: bewusster Wendepunkt

Ab 5 integrierten Features ist die Software launchbereit. Der Launch passiert nicht automatisch, sondern per Karteninteraktion:

```text
Launchbereite Software + Entwickler -> Launch
```

Beim Launch wird die Software live, Startkunden erscheinen, und das erste Business Goal kommt ins Spiel. Pro 5 Features erscheint 1 Kunde: 5 oder 6 Features erzeugen 1 Kunden, 10 Features erzeugen 2 Kunden, 15 Features erzeugen 3 Kunden.

### 3. Post-Launch: Kunden, Druck und Business Goals

Nach Launch wird die Kundenschwelle bei jedem Feature-Release sofort geprueft. Erreicht die Software dadurch das naechste Vielfache von 5 Features, erscheint direkt ein weiterer Kunde, nicht erst am Sprintende. Neu erscheinende Kunden erzeugen sofort 1 Geld und 1 Kundenwunsch. Danach sind Kunden aktive Wertquellen: Entwickler koennen ihnen Demos zeigen, Product Owner koennen Feedback sammeln. Kundenwuensche sind echte Karten und muessen verarbeitet werden. Ignorierte alte Kundenwuensche koennen genau einen Kunden pro Sprintstart unzufrieden machen.

Unzufriedene Kunden bleiben im Run, koennen aber keine Demo- oder Feedbackarbeit ausloesen, bis ein Product Owner oder langsamer ein Entwickler die Erwartungen managt.

Parallel verlangt das aktive Business Goal einzelne Geldkarten. Beim Start des naechsten Sprints wird geprueft, ob das Goal erfuellt wurde. Erfuellte Goals fuehren zum naechsten groesseren Goal; verfehlte Goals erzeugen Investorenpanik.

Aktuelle Endzustaende:

- Sieg: 3 Business Goals erfuellt.
- Niederlage: 0 regulaere Mitarbeiter.
- Niederlage: 2 Investorenpanik-Karten.

## Was der Spieler aktuell tun kann

### Features schnell bauen

Der direkte Weg funktioniert weiterhin:

```text
Idee + Entwickler -> Funktion
Funktion + Software -> Feature integrieren
```

Dieser Weg ist verstaendlich und schnell, hat aber Risiko:

- Ungepruefte Feature-Integration kann Bugs erzeugen.
- Direkte Feature-Arbeit kann technische Schulden erzeugen.
- Technische Schulden verlaengern spaetere Feature- und Bugfix-Arbeit.

### Sauberer arbeiten

Die laengere Rollen-Pipeline ist spielbar:

```text
Idee + Product Owner -> User Story
Kundenwunsch + Product Owner -> User Story
User Story + Entwickler -> Funktion
Funktion + Tester -> Gepruefte Funktion
Gepruefte Funktion + Software -> Feature integrieren ohne Bug-Risiko
```

Gepruefte Funktionen sind ausserdem beim Freelance-Slot sicherer, weil sie im Gegensatz zu ungeprueften Funktionen keinen Bug-Roll ausloesen.

### Freelance als dauerhafte Finanzierung nutzen

Der Freelance-Auftrag ist ein permanenter Shop-Slot. Funktionen und gepruefte Funktionen koennen dort jederzeit gedumped werden.

```text
Funktion auf Freelance-Slot -> 3 Geld + Bug-Chance wie beim Release
Gepruefte Funktion auf Freelance-Slot -> 3 Geld
```

Es spawnen keine sprintgebundenen Freelance-Auftragskarten mehr. Der Slot bleibt auch nach Launch als kontrollierbare Geldquelle erhalten.

### Kunden bedienen

Nach Launch erzeugen Kunden Wert und Arbeit:

- Neu gespawnte Kunden erzeugen 1 Geld und 1 Kundenwunsch.
- Pro 5 integrierte Features existiert 1 Kunde; weitere Kunden spawnen sofort beim Release, sobald 10, 15, 20 usw. Features erreicht werden.
- Entwickler + Kunde erzeugt nach 10s Demoarbeit 1 Geld und 1 Kundenwunsch und wiederholt sich, solange der Stack liegen bleibt.
- Product Owner + Kunde erzeugt nach 30s Feedbackarbeit 1 User Story und wiederholt sich, solange der Stack liegen bleibt.
- Alte, unbearbeitete Kundenwuensche koennen pro Sprintstart maximal eine Unzufriedenheit an einen Kunden anheften.
- Unzufriedene Kunden erzeugen keinen Wert, bis die Erwartung gemanagt wurde.

Aktuelle Behandlung:

```text
Kunde + Unzufrieden + Product Owner -> Erwartungen managen
Kunde + Unzufrieden + Entwickler -> Erwartungen managen, aber langsamer
Kundenwunsch + Product Owner -> User Story
Kundenwunsch + Entwickler -> Kundenwunsch abarbeiten
Entwickler + Kunde -> Demo zeigen
Product Owner + Kunde -> Feedback sammeln
```

Recruiter und Werkstudent haben ebenfalls langsame Fallback-Recipes fuer einzelne produktive Aufgaben, damit der aktuelle Build naeher an "Jeder kann alles, aber nicht gleich gut" bleibt.

### Probleme behandeln

Folgende Problemkarten sind spielbar:

- Bug
- Technische Schulden
- Prod-Crash
- Burnout
- Unzufrieden
- Investorenpanik

Bugs eskalieren am Sprintstart in der GDD-Reihenfolge:

1. Drei vorhandene Bugs werden zuerst zu einem Prod-Crash.
2. Danach verdoppeln sich die uebrigen Bugs.
3. Neu verdoppelte Bugs koennen erst bei einem spaeteren Sprintstart wieder einen Prod-Crash bilden.

Bugfix-Optionen:

```text
Bug + Entwickler -> Bug beheben
Bug + Tester -> Bug beheben, langsamer
Bug + Externer Dev -> Bug beheben, schneller
Bug + Bugfix-Patch -> Bug entfernen
```

Weitere Problembehandlung:

```text
Tech Debt + Entwickler -> Technische Schulden aufraeumen
Prod-Crash + Entwickler -> Hotfix
Kunde + Unzufrieden + Product Owner -> Erwartungen managen
Kunde + Unzufrieden + Entwickler -> Erwartungen managen, aber langsamer
```

Prod-Crashes blockieren Kundendemos und damit aktives Kundengeld, bis sie beseitigt werden.

### Burnout erleben und behandeln

Burnout ist eine angeheftete Karte am Mitarbeiter. Ein Mitarbeiter mit Burnout ist fuer normale Arbeit blockiert, bleibt aber bezahlbar.

Behandlung:

```text
Mitarbeiter + Burnout -> lange Erholung
Mitarbeiter + Burnout + Pizza Party -> kurze Erholung
Mitarbeiter + Burnout + Stressbewaeltigungskurs -> sofortige oder fast sofortige Erholung
```

Burnout ist damit sichtbar und stapelbasiert, nicht nur ein versteckter Statuswert.

### Kaffee nutzen

Kaffee ist keine normale Recipe-Zutat. Kaffee kann auf laufende Mitarbeiterarbeit gezogen werden, um Fortschritt hinzuzufuegen. Kaffee wird dabei verbraucht.

Das gilt fuer laufende Employee-Recipes, auch fuer Onboarding. Kaffee wirkt nicht auf reine Objektprozesse ohne Mitarbeiterkarte, zum Beispiel Software + Feature.

### Sprints, Pause und Bezahlung spielen

Der Build nutzt den Sprint-Rahmen:

- Sprint-Timer laeuft waehrend der Sprintphase.
- Leertaste pausiert in der Sprintphase.
- In Pause und Bezahlphase bleiben Karten bewegbar.
- Processing laeuft in Pause und Bezahlphase nicht weiter.
- In der Bezahlphase muessen regulaere Mitarbeiter mit einzelnen Geldkarten bezahlt werden.
- Auto-Pay bezahlt nur regulaere gehaltsfaellige Mitarbeiter, wenn genug Geld vorhanden ist.
- Unbezahlte regulaere Mitarbeiter kuendigen beim Start des naechsten Sprints.

Werkstudenten und Externe Devs sind keine regulaeren Gehaltsziele.

### Business Goals bezahlen

Business Goals sind sichtbare Karten. Geld wird einzeln auf das aktive Goal gelegt:

```text
Geld + Business Goal -> Goal-Fortschritt +1
```

Die Zielwerte starten bei 1 Geld und steigen pro erledigtem Goal um 1: 1, 2, 3, 4, 5 usw. Der Run endet aktuell nach 3 erfuellten Business Goals.

### Booster und Shop nutzen

Der Shop ist live im Run nutzbar. Geldkarten werden auf Shop-/Booster-Slots gelegt; Boosterpacks werden danach per Klick schrittweise geoeffnet.
Karten aus Boosterpacks suchen freie Plaetze um das Pack herum: Start bei 12 Uhr, dann im Uhrzeigersinn, belegte Plaetze werden uebersprungen.

Die Shop-Slots werden in der Presentation ueber `UiLayer/ShopDock` als editor-positionierbare Slot-Marker platziert. Die Simulation behandelt sie weiterhin als normale Shop-CardInstances; ihre Board-Positionen sind fuer das sichtbare Dock nicht massgeblich.

Aktuelle Shop-/Booster-Richtungen:

- Gruenderpanik: fruehe Hilfe fuer Startdruck; zieht nur Ideen und Kaffee, kein Geld.
- Wohlbefinden: Kaffee, Kaffeemaschine, Pizza Party, Stressbewaeltigungskurs.
- Talent-Pool: kostet 2 Geld, zieht Bewerber oder Werkstudenten.
- Externer Bugfix: gezielter Bugfix-Patch.
- Kundenchaos: existiert als Content und kann nach Launch durch Launch-/Shop-Setup relevant werden.
- Resteverwertung: ganz rechter Shop-Slot; 3 verwertbare Restkarten werden sofort zu 1 Geld, ueberschuessige Karten fallen zurueck aufs Board.

Booster-Ziehungen laufen ueber deterministischen Run-RNG und sind dadurch test- und save-kompatibel.

### Team ueber Hiring vergroessern

Der aktuelle Build ersetzt direkte Mitarbeiter-Ziehungen aus dem Talent-Pool durch eine sichtbare Hiring-Pipeline:

```text
Talent-Pool -> Bewerber -> Bewerbungsgespraech -> Angebot -> Einstellung -> Onboarding -> produktiver Mitarbeiter
```

Aktuelle Regeln:

- Talent-Pool kostet 2 einzelne Geldkarten.
- Talent-Pool-Booster zieht 3 Karten aus Bewerbern und Werkstudenten.
- Bewerber sind noch keine Mitarbeiter.
- Normale Mitarbeiter koennen Bewerber interviewen: 20s, 40% Erfolgschance.
- Recruiter interviewt schneller und erfolgreicher: 10s, 70% Erfolgschance.
- Erfolgreiches Interview erzeugt ein passendes Angebot.
- Misserfolg entfernt den Bewerber.
- Angebot + 1 Geld erzeugt den Ziel-Mitarbeiter mit Onboarding.
- Neueinstellungen in der Bezahlphase werden erst ab dem naechsten Sprint gehaltsrelevant.

Onboarding ist ein angehefteter Blocker:

```text
Mitarbeiter + Onboarding -> Onboarding abschliessen
```

Onboarding blockiert Arbeit, aber nicht Gehalt. Recruiter koennen laufendes Onboarding begleiten und dadurch beschleunigen.

### Temporaere Hilfe nutzen

Der Werkstudent ist eine temporaere Hilfskraft:

- kein Gehalt
- zaehlt nicht als regulaerer Mitarbeiter fuer Game Over
- arbeitet deutlich langsamer
- verschwindet nach genau einer erfolgreich abgeschlossenen Aufgabe
- kann keine Interviews fuehren
- kann kein Onboarding begleiten
- ist fuer einzelne Notfaelle wie Bugfix, Kundenwunsch oder einfache Feature-Arbeit nutzbar

Der Externe Dev bleibt als bestehender Notfall-Content erhalten, ist aber nicht Teil des normalen Talent-Pool-Hirings.

### Speichern und Laden

Save/Load funktioniert fuer eingefrorene Runs:

- Speichern ist in Pause oder Bezahlphase erlaubt.
- Speichern im laufenden, ungepausierten Sprint ist nicht erlaubt.
- Laden stellt Karten, Stacks, Attachments, Timer, RNG-State, MVP-/Launch-State, Business Goals, Kundenzustand, Hiring-Karten und laufende Verarbeitung wieder her.
- Neue Runs nutzen die aktuelle Content-Version.
- Aeltere Saves werden ohne Migration bewusst nicht still geladen, wenn Content-IDs oder Kernregeln nicht mehr kompatibel sind.

## Bereits vorhandene Karten

### Regulaere Mitarbeiter

- Entwickler
- Product Owner
- Tester
- Recruiter

### Temporaere Mitarbeiter und Hilfen

- Werkstudent
- Externer Dev

### Bewerber

- Entwickler-Bewerber
- Product-Owner-Bewerber
- Tester-Bewerber
- Recruiter-Bewerber

### Angebote

- Entwickler-Angebot
- Product-Owner-Angebot
- Tester-Angebot
- Recruiter-Angebot

### Produkt, Inputs und Arbeitsergebnisse

- Software
- Idee
- Kundenwunsch
- User Story
- Funktion
- Gepruefte Funktion

### Geld, Consumables und Hilfskarten

- Geld
- Kaffee
- Bugfix-Patch
- Pizza Party
- Stressbewaeltigungskurs
- Boosterpack
- Freelance-Auftrag
- Resteverwertung

### Wertquellen und Ziele

- Kunde
- Kaffeemaschine
- Auftrag
- Business Goal

### Probleme und Blocker

- Bug
- Technische Schulden
- Prod-Crash
- Burnout
- Unzufrieden
- Investorenpanik
- Onboarding

### Shop- und Booster-Slots

- Booster-Slot / Gruenderpanik
- Talent-Pool
- Wohlbefinden / Office-Invest
- Kundenchaos
- Patch-Shop / externer Bugfix
- Freelance-Auftrag
- Resteverwertung

## Wie umfangreich ist das aktuell?

Vorhanden sind:

- Board-Loop mit Drag-and-Drop, Stacks, neutralen Stacks und Processing
- Sprint, Pause, Bezahlphase, manuelle Bezahlung und Auto-Pay
- MVP-Featurezaehler und manueller Launch
- dauerhafte Finanzierung ueber den Freelance-Shop-Slot
- Post-Launch-Kundenwirtschaft mit Geld, Kundenwuenschen und Unzufriedenheit
- Business Goals mit Sieg- und Niederlagebedingungen
- direkter Feature-Loop und saubere Product-Owner-/Tester-Pipeline
- Problemwirtschaft mit Bugs, Tech Debt, Prod-Crash und Burnout
- Booster-/Shop-System mit deterministischem RNG
- Shop-Kaeufe als Instant-Interaktionen ueber permanente Shop-Slot-Karten; alte Shop-Kauf-Recipes und separate ShopDefinition-Resources sind entfernt
- Hiring-Pipeline mit Bewerbern, Interviews, Angeboten und Onboarding
- Recruiter als Hiring-Spezialist
- Werkstudent als temporaere, gehaltsfreie Hilfskraft
- rahmenlose Karten mit Header-Trennlinie sowie Card- und Shop-Tooltips mit kurzem Hover-Delay, Cursor-Following, handschriftlicher Font und knapper Kurzcopy
- Save/Load fuer pausierte oder eingefrorene Runs
- Content-Validation und schlanker Headless-Kerncheck

Noch nicht vorhanden oder noch nicht final sind:

- kein finales Balancing
- keine finale UI, keine finale Card-Art und kein finaler Spieljuice
- kein vollstaendiges Konflikt-System
- keine Workshops, Reviews oder spaeten Organisationskarten
- keine Mitarbeiter-Traits, Senioritaet, Gehaltsstufen oder komplexes HR-System
- keine Angebotsverfallsregel und keine Kandidatenqualitaet
- keine mehreren Kundentypen oder Feature-Typen
- keine Meta-Progression
- kein Tutorial und keine finale Onboarding-Struktur fuer Spieler
- kein finaler Steam-Demo-Polish

Technische/Design-Schulden, die bewusst bleiben:

- Balancewerte sind Startwerte fuer Playtests.
- `RunController` bleibt die Application-Fassade fuer Simulation-Commands, ist aber nach dem Cleanup bereits in Services fuer Shop, Hiring, Sprintstart und Spawn-Placement geschnitten.
- Recruiter-Fallbacks fuer normale Arbeit sind langsam und datengetrieben, aber noch nicht das finale "Jeder kann alles"-System.
- Einige alte Detailtests sind nicht mehr der aktuelle Gesamtcheck, weil spaetere Regeln sie bewusst ersetzt haben.
- Presentation-Lesbarkeit von Bewerbern, Angeboten, Onboarding, Recruiter und Werkstudent muss im Editor weiter bewertet werden.

Cleanup-Stand:

- Content-Version: `poc_cleanup1`; alte `poc5`-Saves werden wegen entfernter Shop-Recipe-IDs nicht still geladen.
- Entfernt wurden die alten Shop-Kauf-Recipes fuer Booster-Slot, Talent-Pool-Slot und Bugfix-Patch-Slot sowie die nicht mehr genutzte `ShopDefinition`-/`ShopEntryDefinition`-Schicht.
- `CardView` rendert keine eigenen Progress-Controls mehr; aktive Bearbeitung bleibt ein Stack-Element in `BoardView`.

## Aktuelle Playtest-Fragen

- Versteht der Spieler den Weg von MVP zu Launch ohne Erklaertext?
- Ist die Entscheidung `Feature integrieren` vs. `Freelance dumpen` spuerbar?
- Fuehlen sich Kunden nach Launch gleichzeitig wertvoll und anstrengend an?
- Konkurrieren Gehaelter, Business Goals, Booster, Bugfixes und Hiring sinnvoll um Geld?
- Ist der Talent-Pool mit 2 Geld fair bepreist?
- Fuehlen sich normale Interviews mit 20s / 40% fair an oder zu frustrierend?
- Ist der Recruiter mit 10s / 70% und Onboarding-Begleitung strategisch attraktiv?
- Ist Onboarding ein interessanter Delay oder nur Wartezeit?
- Ist der Werkstudent als langsame Einmalhilfe nuetzlich genug?

## Aktuelle Spielerfahrung in einem Satz

Man baut eine Softwarefirma als Karten-Run: erst MVP-Features und Freelance-Geld, dann Launch, Kunden, Business Goals und Wachstumsdruck, waehrend Bugs, Tech Debt, Burnout, Prod-Crashes, Unzufriedenheit und eine langsame Hiring-Pipeline staendig um Board-Platz, Zeit und einzelne Geldkarten konkurrieren.

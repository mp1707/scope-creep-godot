# Current Scope - Gameplay-Stand

Stand: aktueller Build nach PoC1, PoC2 und kleineren Nacharbeiten.

Dieses Dokument beschreibt den aktuellen Spielumfang aus Spielersicht. Es ist keine Zielbeschreibung des fertigen Spiels, sondern eine ehrliche Momentaufnahme: Was kann man im aktuellen Build schon tun, welche Karten gibt es bereits, und wie gross fuehlt sich das Spiel aktuell an?

## Kurzfazit

Der aktuelle Stand ist ein kleiner, spielbarer Vertical Slice. Man kann Karten auf einem Board bewegen, stapeln, einfache Arbeitsketten ausloesen, Sprints ueberstehen, Mitarbeiter bezahlen, Probleme eskalieren lassen und ueber Booster neue Karten ins Spiel bringen.

Es ist aber noch kein vollstaendiges Management-Spiel. Der Umfang reicht fuer kurze Testlaeufe ueber mehrere Sprints und fuer erste Entscheidungen zwischen schnellem Chaos und sauberer Pipeline. Langfristige Progression, echtes Balancing, finale Praesentation, grosse Kartenvielfalt, Konflikte, Hiring-Systeme und spaetere Organisationsmechaniken fehlen noch.

## Wie eine Runde aktuell startet

Der Run startet klein und direkt spielbar. Auf dem Board liegen:

- Software
- Entwickler
- Idee
- Kaffee
- mehrere Shop-/Booster-Slots
- drei einzelne Geldkarten

Geld ist bereits wie im Design vorgesehen keine Zahl im UI, sondern eine Karte. Eine Geldkarte entspricht immer genau 1 Geld.

Der Spieler kann Karten per Drag-and-Drop bewegen, aufeinander stapeln und wieder auseinanderziehen. Passende Stapel starten automatisch eine Verarbeitung mit Fortschrittsbalken. Unpassende Zusatzkarten machen einen Stapel neutral, koennen aber weiterhin organisiert und bewegt werden.

## Grundlegender Spielfluss

Der aktuelle Kernloop ist spielbar:

1. Eine Idee wird mit einem Mitarbeiter verarbeitet.
2. Daraus entsteht eine Funktion.
3. Eine Funktion kann auf die Software gelegt und released werden.
4. Der Release erzeugt Geld, kann aber Probleme verursachen.
5. Am Sprintende muessen Mitarbeiter mit Geldkarten bezahlt werden.
6. Wer nicht bezahlt wird, verlaesst die Firma.
7. Offene Bugs und andere Probleme koennen in folgenden Sprints eskalieren.

Der Sprint-Timer laeuft, kann waehrend der Sprintphase pausiert werden, und wechselt nach Ablauf in eine Bezahlphase. In der Bezahlphase laufen Arbeiten nicht weiter, Karten koennen aber weiterhin sortiert werden. Danach startet der Spieler den naechsten Sprint manuell.

## Was der Spieler aktuell tun kann

### Schnell bauen

Der einfachste Weg ist:

```text
Idee + Entwickler -> Funktion
Funktion + Software -> Geld
```

Das ist die direkte PoC1-Pipeline. Sie funktioniert, ist schnell verstaendlich und bildet den fruehen "Ich baue das eben selbst"-Loop ab.

Im PoC2-Stand hat dieser Weg bereits Risiko:

- Eine direkt gebaute Funktion kann technische Schulden erzeugen.
- Ein ungepruefter Release kann einen Bug erzeugen.
- Technische Schulden verlaengern spaetere Feature- und Bugfix-Arbeit.

### Sauberer arbeiten

Es gibt bereits eine laengere, sauberere Pipeline:

```text
Idee + Product Owner -> User Story
User Story + Entwickler -> Funktion
Funktion + Tester -> Gepruefte Funktion
Gepruefte Funktion + Software -> Geld ohne Bug-Risiko
```

Der Product Owner und der Tester machen dadurch bereits eine erste strategische Entscheidung moeglich: Der Spieler kann schnell releasen und Probleme riskieren, oder mehr Schritte investieren und dafuer sauberer ausliefern.

Zusaetzlich kann aus einem Kundenwunsch mit dem Product Owner eine vielversprechende User Story entstehen. Daraus gebaute Funktionen sind wertvoller und koennen beim Release mehr Geld erzeugen.

### Probleme behandeln

Folgende Probleme sind bereits spielbar:

- Bug
- Technische Schulden
- Prod-Crash
- Burnout

Bugs koennen ignoriert werden, aber sie eskalieren am Sprintstart:

- Drei Bugs werden zuerst zu einem Prod-Crash.
- Danach verdoppeln sich uebrige Bugs.
- Neu verdoppelte Bugs werden erst bei einem spaeteren Sprintstart wieder fuer Prod-Crashes gezaehlt.

Bugs koennen auf mehrere Arten geloest werden:

- Bug + Entwickler -> Bug wird behoben.
- Bug + Tester -> Bug wird behoben, aber langsamer.
- Bug + Externer Dev -> Bug wird schneller behoben.
- Bug + Bugfix-Patch -> Bug wird sofort bzw. fast sofort entfernt.

Technische Schulden liegen als Karten auf dem Board. Sie machen Feature- und Bugfix-Arbeit global langsamer, bis sie mit einem Entwickler aufgeraeumt werden.

Prod-Crashes entstehen aus Bugs und blockieren Einnahmen aus Software-Releases, bis sie durch einen Entwickler per Hotfix beseitigt werden.

### Burnout erleben und behandeln

Mitarbeiter koennen durch abgeschlossene Arbeit Burnout-Risiko aufbauen. Wenn Burnout ausloest, wird eine Burnout-Karte an den Mitarbeiter angeheftet. Der Mitarbeiter ist dadurch fuer normale Arbeit blockiert.

Burnout kann aktuell auf drei Arten behandelt werden:

- Mitarbeiter + Burnout -> lange Erholung.
- Mitarbeiter + Burnout + Pizza Party -> kurze Erholung.
- Mitarbeiter + Burnout + Stressbewaeltigungskurs -> sofortige oder fast sofortige Erholung.

Burnout ist damit schon als echte Karte sichtbar und nicht nur ein versteckter Statuswert.

### Mit Wertquellen spielen

Es gibt erste Karten, die regelmaessig neuen Druck oder neue Hilfen erzeugen:

- Kunde erzeugt Kundenwuensche am Sprintstart.
- Kaffeemaschine erzeugt Kaffee am Sprintstart.
- Auftrag kann mit einer Funktion erfuellt werden und Bonus-Geld bringen.

Offene Auftraege verfallen am Sprintstart, wenn sie nicht vorher erfuellt werden.

### Kaffee nutzen

Kaffee ist keine normale Recipe-Zutat. Der Spieler kann Kaffee auf eine laufende Mitarbeiterarbeit ziehen, um Fortschritt hinzuzufuegen. Kaffee wird dabei verbraucht.

Das funktioniert bereits als aktive Interaktion auf laufende Arbeit.

### Booster und Shop nutzen

Geld kann auf Shop-Slots gelegt werden, um Boosterpacks oder gezielte Hilfskarten zu kaufen. Ein Boosterpack wird danach durch Anklicken geoeffnet und gibt drei Karten einzeln aus.

Aktuell spielbare Shop-/Booster-Richtungen:

- Gruender-Testpack: einfache Startverstaerkung mit Idee, Kaffee oder Geld.
- Talent-Pool: kann Entwickler, Product Owner, Tester oder Externen Dev bringen.
- Office-Invest: kann Kaffeemaschine, Kaffee, Pizza Party oder Stressbewaeltigungskurs bringen.
- Kundenchaos: kann Kunde, Kundenwunsch, Auftrag oder Idee bringen.
- Patch-Shop: kauft gezielt einen Bugfix-Patch.

Die Booster-Ziehungen sind fuer Tests deterministisch, fuehlen sich spielerisch aber wie zufaellige Pack-Ziehungen an.

### Speichern und Laden

Der aktuelle Build hat Save/Load fuer eingefrorene Runs:

- Speichern ist in Pause oder Bezahlphase erlaubt.
- Speichern waehrend eines laufenden, ungepausierten Sprints ist nicht erlaubt.
- Beim Laden werden Board, Karten, Stacks, Timer, RNG-Zustand und laufende Verarbeitung wiederhergestellt.

Aus Spielersicht ist das noch eine einfache PoC-/Dev-Funktion, aber die Grundregel ist bereits da.

## Bereits vorhandene Karten

### Mitarbeiter

- Entwickler
- Product Owner
- Tester
- Externer Dev

Der Externe Dev ist als temporaere Hilfe gedacht und braucht kein normales Gehalt.

### Produkt, Inputs und Arbeitsergebnisse

- Software
- Idee
- Kundenwunsch
- User Story
- Vielversprechende User Story
- Funktion
- Gepruefte Funktion

### Geld und Hilfskarten

- Geld
- Kaffee
- Bugfix-Patch
- Pizza Party
- Stressbewaeltigungskurs
- Boosterpack

### Wertquellen und Druckkarten

- Kunde
- Kaffeemaschine
- Auftrag

### Probleme

- Bug
- Technische Schulden
- Prod-Crash
- Burnout

### Shop- und Booster-Slots

- Booster-Slot
- Talent-Pool
- Office-Invest
- Kundenchaos
- Patch-Shop

## Wie umfangreich ist das aktuell?

Der aktuelle Umfang ist groesser als ein reiner Ein-Recipe-Prototyp, aber noch klar PoC-Groesse.

Vorhanden sind:

- ein spielbarer Board-Loop mit Drag-and-Drop
- Sprint, Pause und Bezahlphase
- manuelle Bezahlung und Auto-Pay
- direkter Feature-Loop
- saubere Rollen-Pipeline mit Product Owner und Tester
- erste Problemwirtschaft mit Bugs, Tech Debt, Prod-Crash und Burnout
- erste Wertquellen mit Kunde, Auftrag und Kaffeemaschine
- mehrere Booster-/Shop-Richtungen
- Save/Load fuer pausierte oder eingefrorene Runs

Noch nicht vorhanden oder noch nicht final sind:

- kein finales Balancing
- keine grosse Content-Breite
- kein Konflikt-System
- kein vollstaendiges Hiring- oder Team-Management
- keine spaeten Organisationskarten wie Workshops, Reviews oder Konflikte
- keine finale UI, keine finale Card-Art und kein finaler Spieljuice
- kein echtes Run-Ziel oder Meta-Fortschritt
- keine vollstaendige Onboarding- oder Tutorial-Struktur

Der aktuelle Build eignet sich deshalb vor allem fuer kurze Playtests: Kann der Spieler den Grundloop verstehen? Fuehlt sich "schnell bauen vs. sauber arbeiten" bereits unterschiedlich an? Sind Bugs, Tech Debt, Burnout und Booster als erste Chaos- und Wachstumsmechaniken interessant genug?

## Aktuelle Spielerfahrung in einem Satz

Man spielt eine kleine Softwarefirma auf Kartenbasis, baut aus Ideen Funktionen, released sie fuer Geld, kauft daraus neue Karten, bezahlt Mitarbeiter und versucht, Bugs, technische Schulden, Burnout und Prod-Crashes lange genug unter Kontrolle zu halten, um mehrere Sprints zu ueberleben.

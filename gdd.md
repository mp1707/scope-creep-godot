# Scope Creep — Game Design Document v1

## 1. High Concept

**Scope Creep** ist ein satirisches Stacklike-Kartenspiel über den Aufbau einer chaotischen Softwarefirma. Der Spieler startet als einzelner Entwickler mit einer Idee und versucht, daraus ein wachsendes Softwareprodukt und später ein Team zu formen.

Alles im Spiel ist eine Karte: Ideen, Mitarbeiter, Geld, Bugs, technische Schulden, Burnout, Workshops, Kundenprobleme, Releases, Konflikte und Verbesserungen. Es gibt keine abstrakten Statusleisten für Stress, Ruf, Tech Debt oder Qualität. Wenn etwas existiert, liegt es als Karte auf dem Tisch und kann gestapelt, verarbeitet, bezahlt, ignoriert oder eskaliert werden.

Der Kern des Spiels ist nicht, eine perfekte Softwarefirma zu simulieren, sondern den absurden Weg von „Ich baue das schnell selbst“ zu „Wir brauchen einen Workshop, um zu klären, warum der Workshop nichts gebracht hat“ spielerisch greifbar zu machen.

---

## 2. One-Line Pitch

Ein Stacklike über eine wachsende Softwarefirma, in der jede Idee, jeder Bug, jeder Mitarbeiter und jedes Problem als Karte auf dem Tisch liegt — und falsche Kombinationen oft trotzdem funktionieren, nur eben katastrophal.

---

## 3. Design Pillars

### 3.1 Alles ist eine Karte

Es gibt keine unsichtbaren Ressourcen oder UI-Meter. Jede wichtige Information existiert als Karte.

Beispiele:

- Geld ist eine Karte.
- Burnout ist eine Karte.
- Technische Schulden sind Karten.
- Ein Bug ist eine Karte.
- Ein Konflikt zwischen zwei Mitarbeitern ist eine Karte.
- Ein Workshop ist eine Karte.
- Ein Kundenproblem ist eine Karte.
- Eine gute Idee ist eine Karte.
- Eine schlechte Idee ist ebenfalls eine Karte.

Dadurch bleibt das Spiel taktil, sichtbar und systemisch. Probleme sind nicht nur Zahlen, sondern Objekte, die Platz einnehmen und behandelt werden müssen.

### 3.2 Kurze Pipeline früh, lange Pipeline später

Am Anfang ist der Weg von Idee zu Funktion kurz:

```text
Idee → Entwickler → Funktion → Software
```

Das ist schnell, aber fehleranfällig.

Später entstehen längere Prozesse:

```text
Workshop → Ideen → Product Owner → User Stories → Entwickler → Funktionen → Tester → Geprüfte Funktionen → Release
```

Die längere Pipeline ist nicht automatisch besser. Sie lohnt sich erst, wenn das Team groß genug ist, mehrere Aufgaben parallel zu bearbeiten und Qualität wichtiger wird.

### 3.3 Jeder kann alles — aber nicht gleich gut

Jede Mitarbeiterkarte kann grundsätzlich jede Aufgabe bearbeiten. Ein Entwickler kann Ideen ausarbeiten, ein Product Owner kann versuchen zu entwickeln, ein Tester kann Kundenprobleme sortieren.

Aber falsche Kombinationen sind langsamer, riskanter und erzeugen Nebenprodukte wie Bugs, Burnout, technische Schulden oder sinnlose Dokumente.

Der Spieler darf jederzeit improvisieren. Genau daraus entsteht Comedy und taktische Tiefe.

### 3.4 Probleme sind spielbare Objekte

Negative Effekte sind nicht abstrakt. Sie erscheinen als Karten.

Ein Bug liegt auf dem Tisch. Technische Schulden liegen auf dem Tisch. Burnout liegt auf einem Mitarbeiter oder daneben. Ein Konflikt liegt zwischen zwei Mitarbeitern.

Der Spieler kann diese Karten ignorieren, verschieben, behandeln, umbenennen, ins Backlog legen oder durch Prozesse entschärfen. Ignorierte Probleme verursachen aber laufend neue Probleme.

### 3.5 Wachstum erzeugt Overhead

Mehr Mitarbeiter bedeuten nicht nur mehr Arbeitstempo. Sie erzeugen auch Gehälter, Abstimmungsbedarf, Konflikte, Workshops, Reviews, Meetings, Prozesskarten und Managementprobleme.

Das Spiel soll sich anfühlen wie:

> „Mit einem Entwickler war alles langsam. Mit fünf Leuten ist alles schneller, aber niemand weiß mehr, was eigentlich gebaut werden soll.“

---

## 4. Zielplattform und Genre

**Genre:** Stacklike / Management-Roguelite / Satirisches Kartenspiel  
**Referenzgefühl:** Stacklands trifft Softwarefirma-Satire  
**Primäre Plattform:** PC / Steam  
**Session-Struktur:** Runs über mehrere Sprints  
**Perspektive:** 2D-Kartenfeld mit Drag-and-Drop

---

## 5. Core Loop

### 5.1 Basisloop

1. Der Spieler erhält oder erzeugt eine Idee.
2. Die Idee wird durch Mitarbeiter oder Prozesse verarbeitet.
3. Daraus entsteht eine Funktion, ein Prototyp, eine User Story, ein Bug oder ein anderes Ergebnis.
4. Funktionen werden auf die Software-Karte gelegt, um Wert/Geld/Kunden zu erzeugen.
5. Am Ende eines Sprints müssen Mitarbeiter bezahlt werden.
6. Offene Probleme bleiben liegen und können in späteren Sprints eskalieren.
7. Mit Geld kauft der Spieler neue Karten, Mitarbeiter, Prozesse oder Verbesserungen.

### 5.2 Früher Loop

Der Start ist bewusst simpel:

```text
Idee + Solo-Entwickler → Prototyp / Funktion
Funktion + Software → Geld / Kundenwunsch / Bug
Geld + Entwickler am Sprintende → Mitarbeiter bleibt
```

Der Spieler versteht sofort:

- Ich kann Dinge bauen.
- Dinge bringen Geld.
- Dinge erzeugen Probleme.
- Mitarbeiter müssen bezahlt werden.

### 5.3 Mittlerer Loop

Sobald weitere Rollen erscheinen:

```text
Idee + Product Owner → User Story
User Story + Entwickler → Funktion
Funktion + Tester → Geprüfte Funktion
Geprüfte Funktion + Software → mehr Wert, weniger Bugs
```

Der Spieler lernt:

- Prozesse machen Ergebnisse besser.
- Prozesse dauern länger.
- Spezialisierung lohnt sich.
- Mehr Team bedeutet mehr parallele Verarbeitung.

### 5.4 Später Loop

Im späteren Spiel entstehen Prozessketten:

```text
Workshop + mehrere Mitarbeiter → mehrere Ideen
Sprint-Planung + Ideen → priorisierte Aufgaben
Code-Prüfung + Funktion → weniger Bugs
Testlauf + Funktion → geprüfte Funktion
Release + geprüfte Funktionen → stabile Version
```

Zusätzlich entstehen Organisationsprobleme:

```text
Konflikt + Mitarbeiter → blockiert Zusammenarbeit
Stressbewältigungskurs + betroffene Mitarbeiter → Konflikt entfernt
Postmortem + Störung → Folgeaufgaben / weniger zukünftige Störungen
```

---

## 6. Spielfluss: Sprints

Das Spiel ist in **Sprints** unterteilt. Ein Sprint ist eine kurze Arbeitsphase mit begrenzter Zeit.

### 6.1 Sprint-Ablauf

1. Sprint startet.
2. Karten werden verarbeitet, gestapelt, kombiniert.
3. Mitarbeiter arbeiten auf Kartenstapeln.
4. Funktionen werden veröffentlicht.
5. Neue Probleme können entstehen.
6. Sprint endet.
7. Gehälter werden fällig.
8. Offene Sprintende-Effekte werden ausgeführt.
9. Shop/Belohnungsphase.
10. Nächster Sprint.

### 6.2 Zeitsteuerung

- Karten brauchen Zeit, um verarbeitet zu werden.
- Der Spieler kann pausieren und in Ruhe Karten organisieren.
- Während der Pause laufen keine Timer.
- Karten können in der Pause trotzdem bewegt und gestapelt werden.

### 6.3 Sprintende

Am Sprintende werden Gehaltskarten benötigt.

Beispiel:

```text
Geld + Entwickler → Entwickler bleibt
Kein Geld + Entwickler → Kündigungsgefahr
Kündigungsgefahr + nächster unbezahlter Sprint → Mitarbeiter verlässt das Spiel
```

Geld ist keine Zahl im UI, sondern eine oder mehrere Geldkarten mit Werten.

---

## 7. Grundregel: Karten und Stapel

### 7.1 Kartenarten

Es gibt mehrere funktionale Kartentypen:

- Mitarbeiterkarten
- Ideenkarten
- Aufgabenkarten
- Ergebnis-/Produktkarten
- Problemkarten
- Ressourcenkarten
- Prozesskarten
- Ereigniskarten
- Verbesserungs-/Upgradekarten
- Organisationskarten

### 7.2 Stapelregel

Karten werden per Drag-and-Drop gestapelt.

Ein Stapel startet eine Aktion, wenn die Kombination gültig ist.

Beispiel:

```text
Idee + Entwickler → Timer startet → Funktion entsteht
```

Nicht jede Kombination muss sinnvoll sein. Viele Kombinationen dürfen absichtlich schlechte oder komische Ergebnisse erzeugen.

### 7.3 Karten können blockieren

Einige Karten blockieren Mitarbeiter oder Prozesse.

Beispiele:

```text
Burnout + Entwickler → Entwickler arbeitet langsamer
Konflikt + zwei Mitarbeiter → können nicht gemeinsam in Workshop
Bug + Software → erzeugt Kundenproblem
Technische Schulden + Software → erhöht Bug-Chance bei Releases
```

Auch diese Effekte entstehen aus Karten, nicht aus unsichtbaren Zahlen.

---

## 8. Wichtige Kartenkategorien

## 8.1 Mitarbeiterkarten

Mitarbeiter sind zentrale Arbeitskarten. Sie verarbeiten Ideen, Aufgaben, Probleme und Prozesse.

### Solo-Entwickler

Startkarte.

Kann alles irgendwie, aber nichts organisatorisches besonders gut.

Stärken:

- Entwickeln
- Bugfixes
- Prototypen

Schwächen:

- Planung
- Testen
- Support
- Teamprozesse

Typische Outputs:

```text
Idee + Solo-Entwickler → Prototyp + Technische Schulden
Bug + Solo-Entwickler → Bugfix + Stress
Kundenwunsch + Solo-Entwickler → Funktion, aber Risiko auf falsche Funktion
```

### Entwickler

Baut Funktionen und behebt Bugs.

Stärken:

- User Story → Funktion
- Bug → Bugfix
- Technische Schulden → Aufgeräumter Code

Schwächen:

- Ideen priorisieren
- Kundenkommunikation
- Konfliktlösung

### Product Owner

Macht aus Ideen und Kundenwünschen klare Anforderungen.

Stärken:

- Idee → User Story
- Kundenwunsch → priorisierte Idee
- Backlog → Sprint-Ziele

Schwächen:

- Entwicklung
- Bugfixes
- technische Schulden

Comedy-Fail:

```text
Bug + Product Owner → Wird ins Backlog verschoben
```

### Tester

Findet Bugs und macht Funktionen stabiler.

Stärken:

- Funktion → Geprüfte Funktion
- Bug → Reproduzierbarer Bug
- Release → Testbericht

Schwächen:

- Funktionen bauen
- Business-Entscheidungen

### Support

Verarbeitet Kundenprobleme und schützt den Ruf des Produkts.

Stärken:

- Kundenproblem → Beruhigter Kunde
- Bug + Kunde → Bekanntes Problem
- Störung → Schadensbegrenzung

Schwächen:

- Entwicklung
- Planung

### Designer

Verbessert Funktionen und kann aus groben Ideen nutzerfreundlichere Konzepte machen.

Stärken:

- Idee → Konzept
- Funktion → Verbesserte Funktion
- Kundenproblem → UX-Hinweis

Schwächen:

- Bugfixes
- Releases

### Manager

Erzeugt Prioritäten, Druck und manchmal Budget.

Stärken:

- Geld beschaffen
- Prioritäten setzen
- Eskalationen bearbeiten

Schwächen:

- Kann fast alles schlimmer machen, wenn falsch eingesetzt

Typische Outputs:

```text
Manager + Idee → Strategische Initiative
Manager + Bug → Eskalation
Manager + Team → Meeting
```

### Berater

Teuer, absurd, manchmal mächtig.

Stärken:

- Erzeugt Prozesskarten
- Kann Probleme umbenennen
- Kann aus Chaos kurzfristig Wert machen

Schwächen:

- Erzeugt Folgeaufgaben
- Kostet viel Geld
- Vergrößert Scope

Typische Outputs:

```text
Berater + Problem → Maßnahmenplan
Berater + Idee → 40-seitige Präsentation
Berater + Software → Transformationsprogramm
```

---

## 8.2 Ideen- und Anforderungskarten

### Idee

Basisinput für neue Funktionen.

Kann direkt von Entwicklern umgesetzt werden oder zuerst durch Product Owner/Workshop verbessert werden.

```text
Idee + Entwickler → Prototyp / Funktion + Risiko
Idee + Product Owner → User Story
Idee + Designer → Konzept
Idee + Berater → Präsentation
```

### Kundenwunsch

Entsteht durch Kunden, veröffentlichte Funktionen oder Support-Probleme.

```text
Kundenwunsch + Product Owner → priorisierte User Story
Kundenwunsch + Entwickler → Funktion, aber Risiko auf falsche Lösung
Kundenwunsch + Support → Erwartung gemanagt
```

### User Story

Eine klarere Anforderung.

```text
User Story + Entwickler → Funktion
User Story + Tester → Testfälle
User Story + Product Owner → Scope Creep
```

### Unklare Anforderung

Schlechtere Variante einer User Story.

```text
Unklare Anforderung + Entwickler → Falsche Funktion / Buggy Feature
Unklare Anforderung + Product Owner → User Story
```

---

## 8.3 Produkt- und Ergebnis-Karten

### Software

Zentrale Produktkarte. Funktionen werden auf die Software gelegt, um Wert zu erzeugen.

Die Software selbst kann Problemkarten tragen:

- Bug
- Technische Schulden
- Kundenproblem
- Störung
- Altlast

Diese Problemkarten sind sichtbar und können bearbeitet werden.

### Prototyp

Frühes Ergebnis aus einer Idee.

```text
Prototyp + Software → wenig Geld, hohes Bug-Risiko
Prototyp + Tester → Gefundene Bugs
Prototyp + Product Owner → Feedback / User Story
```

### Funktion

Normales Feature-Ergebnis.

```text
Funktion + Software → Geld + Chance auf Bug/Kundenwunsch
Funktion + Tester → Geprüfte Funktion
Funktion + Code-Prüfung → Saubere Funktion
```

### Geprüfte Funktion

Bessere Funktion mit niedrigerem Bug-Risiko.

```text
Geprüfte Funktion + Software → mehr Geld, weniger Probleme
```

### Goldrandlösung

Sehr hochwertige, aber übertriebene Funktion.

```text
Goldrandlösung + Software → viel Qualität, wenig Geld pro Zeit
```

### Schnellschuss

Schnelle, riskante Lösung.

```text
Schnellschuss + Software → schnelles Geld + Bug + Technische Schulden
```

---

## 8.4 Problemkarten

Problemkarten sind zentrale negative Objekte. Sie bleiben liegen, bis sie behandelt werden.

### Bug

Ein Softwarefehler.

Effekt:

- Kann Kundenprobleme erzeugen.
- Kann Releases verschlechtern.
- Kann zu Störung eskalieren.

Behandlung:

```text
Bug + Entwickler → Bugfix
Bug + Tester → Reproduzierbarer Bug
Bug + Product Owner → Backlog-Eintrag
Bug + Support → Bekanntes Problem
```

### Reproduzierbarer Bug

Besser bearbeitbarer Bug.

```text
Reproduzierbarer Bug + Entwickler → sauberer Bugfix
```

### Technische Schulden

Schnelle Lösungen, die später Arbeit verursachen.

Effekt:

- Erhöht Chance auf Bugs bei neuen Funktionen.
- Verlangsamt spätere Entwicklung.
- Kann zu Altlast eskalieren.

Behandlung:

```text
Technische Schulden + Entwickler → Code aufräumen
Technische Schulden + Refactoring-Prozess → weniger Schulden
Technische Schulden + ignorieren → Altlast
```

### Burnout

Liegt auf oder neben einem Mitarbeiter.

Effekt:

- Mitarbeiter arbeitet langsamer.
- Bei zu viel Burnout entsteht Kündigungsgefahr oder Ausfall.

Behandlung:

```text
Burnout + Urlaub → entfernt Burnout
Burnout + Stressbewältigungskurs → reduziert Burnout
Burnout + ignorieren → Ausfall / Kündigungsgefahr
```

### Stress

Kleinere Vorstufe zu Burnout.

```text
Stress + weiterer Stress → Burnout
Stress + Team-Event → entfernt Stress
```

### Kundenproblem

Entsteht durch Bugs, schlechte Releases oder unerfüllte Wünsche.

```text
Kundenproblem + Support → Beruhigter Kunde
Kundenproblem + Product Owner → Kundenwunsch
Kundenproblem + ignorieren → Schlechter Ruf
```

### Schlechter Ruf

Kein UI-Wert, sondern Karte.

Effekt:

- Reduziert Geld aus Releases.
- Erzeugt mehr Kundenprobleme.

Behandlung:

```text
Schlechter Ruf + Support → Ruf reparieren
Schlechter Ruf + Stabile Version → Vertrauen zurück
```

### Konflikt

Verbindet zwei Mitarbeiter oder liegt zwischen ihnen.

Effekt:

- Betroffene Mitarbeiter können nicht gemeinsam in Workshops, Reviews oder Planungen.
- Gemeinsame Stapel mit beiden Mitarbeitern erzeugen Verzögerung oder Blame Game.

Behandlung:

```text
Konflikt + Stressbewältigungskurs + beide Mitarbeiter → Konflikt entfernt
Konflikt + Manager → Eskalation
Konflikt + ignorieren → Silodenken
```

### Abstimmungsbedarf

Blockiert bestimmte Aufgaben, bis er geklärt wird.

```text
Abstimmungsbedarf + Daily → geklärt
Abstimmungsbedarf + Product Owner → Entscheidung
Abstimmungsbedarf + ignorieren → Blocker
```

### Blocker

Stärkeres Hindernis.

```text
Blocker + passende Rolle → gelöst
Blocker + Manager → Eskalation
```

### Meeting-Flut

Entsteht durch zu viele Prozesskarten.

Effekt:

- Mitarbeiter werden langsamer.
- Neue Workshops/Dailys erzeugen Stress.

Behandlung:

```text
Meeting-Flut + Prozessoptimierung → reduziert Meeting-Flut
Meeting-Flut + Berater → noch mehr Meeting-Flut
```

---

## 8.5 Ressourcenkarten

### Geld

Geld ist eine Karte mit Wert.

Nutzung:

- Mitarbeiter bezahlen
- Karten kaufen
- Prozesse starten
- Berater bezahlen
- Kurse buchen

Beispiele:

```text
Geld + Entwickler → bezahlt
Geld + Shop-Karte → neue Karte
Geld + Stressbewältigungskurs → Kurs aktivieren
```

### Budget

Größere Geldkarte oder temporärer Finanzrahmen.

```text
Budget + Hiring → neuer Mitarbeiter
Budget + Berater → Transformationsprogramm
```

### Zeitgewinn

Temporäre Ressource, z. B. durch Automatisierung oder Prozessverbesserung.

```text
Zeitgewinn + Aufgabe → Aufgabe schneller erledigt
```

### Kaffee

Kleine Soforthilfe.

```text
Kaffee + Mitarbeiter → arbeitet schneller, erzeugt später Stress
```

---

## 8.6 Prozesskarten

Prozesskarten sind konsumierbare oder wiederverwendbare Karten, die mehrere andere Karten verarbeiten.

### Workshop

Mehrere Mitarbeiter erzeugen mehrere Ideen.

```text
Workshop + 2–4 Mitarbeiter → Ideenflut
```

Mögliche Outputs:

- Idee
- Gute Idee
- Unklare Idee
- Abstimmungsbedarf
- Meeting-Flut
- Stress

Workshop ist im Early Game schlecht, weil er Mitarbeiter blockiert und mehr Ideen erzeugt, als verarbeitet werden können. Im Midgame wird er stark, weil mehrere Mitarbeiter parallel arbeiten können.

### Sprint-Planung

Sortiert Ideen und Anforderungen.

```text
Sprint-Planung + Product Owner + Ideen → Priorisierte Aufgaben
```

Mögliche Outputs:

- Priorisierte User Story
- Zurückgestellte Idee
- Scope Creep
- Abstimmungsbedarf

### Daily / Morgenrunde

Klärt Abstimmungsbedarf, kann aber Meeting-Flut erzeugen.

```text
Daily + Team → Alignment
Daily + zu viele Mitarbeiter → Meeting-Flut
```

### Code-Prüfung

Verbessert Funktionen, braucht aber zusätzliche Mitarbeiterzeit.

```text
Code-Prüfung + Funktion + Entwickler → Saubere Funktion
```

### Testlauf

Macht aus Funktionen geprüfte Funktionen oder findet Bugs.

```text
Testlauf + Funktion + Tester → Geprüfte Funktion / Bug
```

### Release

Veröffentlicht mehrere Funktionen gemeinsam.

```text
Release + Funktionen + Software → Geld + Kundenreaktionen
```

Je nach Qualität entstehen:

- Geld
- Kundenwunsch
- Bug
- Störung
- Schlechter Ruf

### Postmortem / Nachbesprechung

Bearbeitet Störungen.

```text
Nachbesprechung + Störung + Team → Folgeaufgaben + weniger zukünftige Störungen
```

Comedy-Regel:

Postmortems lösen Probleme nicht direkt. Sie erzeugen Folgeaufgaben, die erst noch erledigt werden müssen.

### Stressbewältigungskurs

Entfernt Burnout oder Konflikte.

```text
Stressbewältigungskurs + Mitarbeiter + Burnout → Burnout reduziert
Stressbewältigungskurs + zwei Mitarbeiter + Konflikt → Konflikt entfernt
```

Möglicher Output:

- Temporäres Alignment
- Corporate-Therapie-Vokabular
- Team-Event

### Teambuilding

Reduziert Stress, kann aber Arbeitszeit kosten.

```text
Teambuilding + Team → weniger Stress + verlorene Zeit
```

### Hiring

Erzeugt neue Mitarbeiter.

```text
Hiring + Geld → Kandidat
Kandidat + Gespräch → Mitarbeiter / Absage
```

Im Early Game kann man einfache Mitarbeiter kaufen. Später braucht gutes Hiring mehr Prozess.

---

## 9. Produkt- und Softwarekarte

Die Software-Karte ist das Zentrum des Runs.

### 9.1 Funktionen hinzufügen

Funktionen werden auf die Software-Karte gelegt.

```text
Funktion + Software → Geld + möglicher Nebeneffekt
```

Bessere Funktionen erzeugen mehr Geld und weniger Probleme.

### 9.2 Problemkarten auf der Software

Problemkarten können an der Software haften:

- Bug
- Technische Schulden
- Altlast
- Schlechter Ruf
- Kundenproblem
- Störung

Diese Karten belegen Platz und wirken passiv, solange sie nicht bearbeitet werden.

### 9.3 Software-Level

Statt eines abstrakten Levels kann die Software sichtbare Karten tragen:

- Erste Version
- Wachsende App
- Komplexes Produkt
- Alt-System
- Plattform

Diese Entwicklungsstufen sind Karten, die durch Releases entstehen.

Beispiel:

```text
Software + 3 Funktionen → Erste Version
Erste Version + 5 weitere Funktionen → Wachsende App
Wachsende App + viele technische Schulden → Alt-System
```

---

## 10. Karteninteraktionen: Beispiele

### 10.1 Idee direkt bauen

```text
Idee + Solo-Entwickler
→ Timer
→ Schnellschuss + Technische Schulden
```

Nutzen:

- Schnell
- Frühes Geld möglich

Risiko:

- Bugs
- Schulden
- Stress

### 10.2 Idee sauber vorbereiten

```text
Idee + Product Owner
→ User Story

User Story + Entwickler
→ Funktion

Funktion + Tester
→ Geprüfte Funktion

Geprüfte Funktion + Software
→ Geld + Kundenvertrauen
```

Nutzen:

- Höhere Qualität
- Weniger Probleme

Risiko:

- Dauert länger
- Mehr Gehälter
- Mehr Abstimmungsbedarf

### 10.3 PO versucht zu coden

```text
User Story + Product Owner
→ PowerPoint-Prototyp + Scope Creep
```

Nutzbar als Comedy-Output und evtl. als schlechte, aber verkaufbare Lösung.

### 10.4 QA findet Problem

```text
Funktion + Tester
→ Bug + Geprüfte Funktion
```

Tester erzeugt nicht nur Qualität, sondern macht versteckte Probleme sichtbar.

### 10.5 Berater verschlimmbessert

```text
Berater + Technische Schulden
→ Transformationsprogramm + Maßnahmenplan
```

Maßnahmenplan kann später nützlich sein, erzeugt aber erstmal weitere Arbeit.

---

## 11. Progression

### 11.1 Phase 1: Solo Chaos

Startkarten:

- Solo-Entwickler
- Idee
- Software / Leeres Repository
- kleines Geld

Gameplay:

- Ideen direkt bauen
- Bugs selbst fixen
- Geld verdienen
- erste technische Schulden entstehen

Ziel:

- Erste Version veröffentlichen
- genug Geld für weiteren Sprint verdienen

Neue Karten:

- Kaffee
- Bug
- Schnellschuss
- Technische Schulden
- Kundenwunsch

### 11.2 Phase 2: Erste Spezialisierung

Neue Karten:

- Product Owner
- Tester
- Support
- User Story
- Testlauf
- Backlog

Gameplay:

- Spieler lernt bessere Pipeline
- Fehler werden sichtbarer
- Gehälter werden wichtiger
- mehrere Aufgaben laufen parallel

Ziel:

- Funktionen stabil veröffentlichen
- genug Geld für Team verdienen

### 11.3 Phase 3: Teamprozesse

Neue Karten:

- Workshop
- Sprint-Planung
- Code-Prüfung
- Daily
- Release
- Hiring

Gameplay:

- Mehrere Ideen werden gleichzeitig erzeugt
- Parallelisierung wird nötig
- Overhead entsteht
- Abstimmungsbedarf und Meeting-Flut erscheinen

Ziel:

- Wachstum managen
- Prozesse sinnvoll einsetzen

### 11.4 Phase 4: Organisationschaos

Neue Karten:

- Konflikt
- Burnout
- Stressbewältigungskurs
- Teambuilding
- Postmortem
- Manager
- Berater
- Alt-System

Gameplay:

- Mitarbeiterbeziehungen werden relevant
- Probleme können Kettenreaktionen auslösen
- Prozesse lösen Probleme, erzeugen aber neue Arbeit

Ziel:

- Firma stabil halten
- trotz Chaos große Releases schaffen

---

## 12. Wirtschaft und Gehälter

### 12.1 Geld als Karte

Geld entsteht durch Releases, Kunden, Investitionen oder bestimmte Events.

Geldkarten können unterschiedliche Werte haben:

- 1 Geld
- 5 Geld
- 10 Geld
- Budget

### 12.2 Mitarbeiter bezahlen

Am Sprintende müssen Mitarbeiter bezahlt werden.

```text
Geld + Mitarbeiter → Bezahlt
```

Wenn ein Mitarbeiter nicht bezahlt wird:

```text
Unbezahlter Mitarbeiter → Kündigungsgefahr
Kündigungsgefahr + weiteres Sprintende → Kündigung
```

### 12.3 Kostenstruktur

Bessere Mitarbeiter kosten mehr.

Beispiel:

- Praktikant: wenig Geld, langsam, erzeugt Bugs
- Entwickler: normal
- Senior Entwickler: teuer, schnell, weniger Bugs
- Berater: sehr teuer, erzeugt starke Effekte und viel Overhead

---

## 13. Shop und Kartenbeschaffung

Zwischen Sprints gibt es eine Shop-Phase.

Auch Shop-Angebote erscheinen als Karten.

### 13.1 Shop-Karten

Mögliche Käufe:

- Mitarbeiter
- Prozesskarten
- Verbrauchskarten
- Verbesserungen
- Kundenaufträge
- Beratungsangebote

### 13.2 Booster/Packs

Packs können thematisch sein:

- Gründerpaket
- Teamaufbau
- Prozessoptimierung
- Kundenchaos
- Technische Altlasten
- Corporate Bullshit
- Beraterpaket

### 13.3 Kaufinteraktion

```text
Geld + Shop-Karte → gekaufte Karte
```

Auch Kauf und Bezahlung bleiben kartig.

---

## 14. Negative Eskalationsketten

Probleme sollen nicht nur stören, sondern Geschichten erzeugen.

### 14.1 Bug-Kette

```text
Bug
→ ignoriert
→ Kundenproblem
→ ignoriert
→ Schlechter Ruf
→ Release bringt weniger Geld
```

### 14.2 Tech-Debt-Kette

```text
Technische Schulden
→ ignoriert
→ Altlast
→ neue Funktionen dauern länger
→ mehr Bugs
```

### 14.3 Burnout-Kette

```text
Stress
→ Burnout
→ Ausfall
→ Kündigungsgefahr
→ Kündigung
```

### 14.4 Meeting-Kette

```text
Abstimmungsbedarf
→ Daily
→ Meeting-Flut
→ Stress
→ Burnout
```

### 14.5 Konflikt-Kette

```text
Konflikt
→ Blame Game
→ Silodenken
→ Teamprozesse funktionieren schlechter
```

---

## 15. Humor und Tonalität

Der Humor entsteht aus bekannten Software- und Corporate-Situationen, aber die Begriffe sollen allgemein verständlich bleiben.

### 15.1 Ton

- trocken
- beobachtend
- leicht überzeichnet
- nicht zu insiderhaft
- für Nicht-Entwickler verständlich
- für Entwickler erkennbar und schmerzhaft lustig

### 15.2 Beispieltexte

**Technische Schulden**  
„Schnell gelöst. Später teuer.“

**User Story**  
„Eine klare Beschreibung, was jemand eigentlich braucht.“

**Bug**  
„Funktioniert nicht. Hat aber gestern noch funktioniert.“

**Workshop**  
„Alle reden mit. Danach gibt es mehr Ideen als vorher.“

**Burnout**  
„Dieser Mensch braucht eine Pause. Oder zumindest weniger Dailys.“

**Berater**  
„Versteht das Problem sofort. Nennt es aber anders.“

**Abstimmungsbedarf**  
„Niemand ist blockiert. Alle warten nur aufeinander.“

---

## 16. UI-Grundsätze

### 16.1 Keine abstrakten HUD-Werte

Es gibt keine permanenten Anzeigen wie:

- Burnout: 4/10
- Tech Debt: 12
- Ruf: 70%
- Geld: 500

Stattdessen:

- Geld liegt als Karte.
- Burnout liegt als Karte auf Mitarbeitern.
- Technische Schulden liegen als Karten an der Software.
- Schlechter Ruf liegt als Karte am Produkt.

### 16.2 Karten müssen Bedeutung tragen

Jede Karte zeigt:

- Name
- Typ/Icon
- kurze Beschreibung
- mögliche Hauptinteraktionen
- ggf. Timer/Arbeitsfortschritt
- ggf. Statusmarker, falls sie auf einer anderen Karte liegt

### 16.3 Lesbarkeit vor Insiderwitz

Kartenname kurz, Tooltip erklärend.

Beispiel:

```text
User Story
Klare Anforderung aus Nutzersicht.
```

```text
Technische Schulden
Schnelle Lösung, die später Arbeit verursacht.
```

---

## 17. Prototyp-Scope v1

Der erste spielbare Prototyp soll klein bleiben.

### 17.1 Enthaltene Karten

Mitarbeiter:

- Solo-Entwickler
- Product Owner
- Tester

Input:

- Idee
- Kundenwunsch

Aufgaben/Outputs:

- User Story
- Funktion
- Geprüfte Funktion
- Schnellschuss

Probleme:

- Bug
- Technische Schulden
- Stress
- Burnout

Ressourcen:

- Geld

Prozesse:

- Workshop
- Testlauf
- Code aufräumen

Produkt:

- Software

### 17.2 Enthaltene Interaktionen

```text
Idee + Solo-Entwickler → Schnellschuss + Technische Schulden
Idee + Product Owner → User Story
User Story + Entwickler → Funktion
Funktion + Tester → Geprüfte Funktion oder Bug
Funktion + Software → Geld + Bug-Chance
Geprüfte Funktion + Software → mehr Geld + geringe Bug-Chance
Bug + Entwickler → Bugfix
Technische Schulden + Entwickler → Code aufräumen
Stress + weiterer Stress → Burnout
Geld + Mitarbeiter am Sprintende → bezahlt
```

### 17.3 Prototyp-Ziel

Der Prototyp ist erfolgreich, wenn folgende Entscheidungen interessant sind:

1. Baue ich schnell direkt aus Ideen oder sauber über User Stories?
2. Nutze ich Tester für Qualität oder lasse ich Features schneller releasen?
3. Behebe ich Bugs jetzt oder baue ich weiter?
4. Zahle ich für neue Mitarbeiter oder sichere ich Gehälter?
5. Lohnt sich ein Workshop erst, wenn ich genug Mitarbeiter habe?

---

## 18. Offene Designfragen

### 18.1 Wie viele Problemkarten sind zu viel?

Problemkarten sollen Druck erzeugen, aber nicht das Spielfeld unlesbar machen.

Mögliche Lösung:

- Gleichartige Probleme können stapeln.
- Problemstapel werden gefährlicher, aber bleiben visuell kompakt.

### 18.2 Wie genau funktioniert Software-Wert?

Da es keinen abstrakten Wert geben soll, könnte Wert über Karten dargestellt werden:

- Kundenkarte
- Geldkarte
- Vertrauen-Karte
- Abo-Karte
- Auftrag-Karte

### 18.3 Wie werden langfristige Upgrades dargestellt?

Mögliche Lösung:

- Upgradekarten werden an Mitarbeiter oder Software angelegt.
- Beispiel: „Automatisierte Tests“ liegt an Software und reduziert Bug-Chance.

### 18.4 Wie viel Zufall ist gut?

Falsche Kombinationen sollten nicht komplett unberechenbar sein. Der Spieler muss lernen können:

- direkte Umsetzung = schnell, riskant
- saubere Pipeline = langsam, stabil
- Prozesse = mächtig, aber Overhead

### 18.5 Wie werden Beziehungen zwischen Mitarbeitern dargestellt?

Konflikte könnten als Karten zwischen Mitarbeitern liegen oder an beiden Mitarbeitern haften.

Beispiel:

```text
Konflikt: Dev vs QA
```

Diese Karte verhindert gemeinsame Prozesse, bis sie behandelt wird.

---

## 19. Langfristige Erweiterungen

### 19.1 Mitarbeiter-Persönlichkeiten

Mitarbeiter können Traits haben:

- Perfektionist
- Pragmatisch
- Meeting-Hasser
- Bug-Magnet
- Feuerwehrmensch
- Goldrand-Fan
- Junior
- Senior
- Kündigt innerlich

### 19.2 Produktarten

Verschiedene Softwareprodukte könnten andere Regeln haben:

- App
- B2B-Tool
- Online-Shop
- Behördenportal
- Startup-MVP
- Legacy-System

### 19.3 Kundenarten

- Geduldiger Kunde
- Enterprise-Kunde
- Unklarer Kunde
- Lauter Kunde
- Großkunde
- Interner Stakeholder

### 19.4 Corporate-Events

- Reorganisation
- Budgetkürzung
- Strategiewechsel
- Investorenbesuch
- Datenschutzprüfung
- Black Friday
- Produktionsausfall
- Chef hatte eine Idee

---

## 20. Zusammenfassung

Scope Creep soll ein Stacklike werden, in dem der Spieler eine Softwarefirma nicht über Menüs und Zahlen verwaltet, sondern über sichtbare, manipulierbare Karten.

Der zentrale Reiz entsteht aus dem Spannungsfeld zwischen schneller Improvisation und wachsender Prozesskomplexität:

- Am Anfang kann der Solo-Entwickler alles selbst machen, aber schlecht und riskant.
- Später ermöglichen spezialisierte Rollen bessere Ergebnisse.
- Noch später werden Prozesse mächtig, aber erzeugen Overhead.
- Probleme sind keine Zahlen, sondern Karten, die Platz einnehmen und behandelt werden müssen.
- Wachstum löst alte Probleme und erzeugt neue.

Das Spiel sollte sich dadurch wie eine absurde, aber erkennbare Softwareorganisation anfühlen: Jede Karte ist eine Entscheidung, jedes Problem liegt sichtbar auf dem Tisch, und jeder Versuch, Ordnung zu schaffen, kann neuen Scope erzeugen.


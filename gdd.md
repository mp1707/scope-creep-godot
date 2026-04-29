# Scope Creep — Game Design Document v1.1

## 1. High Concept

**Scope Creep** ist ein satirisches Stacklike-Kartenspiel über den Aufbau einer chaotischen Softwarefirma. Der Spieler startet als einzelner Entwickler mit einer Idee und versucht, daraus ein wachsendes Softwareprodukt und später ein Team zu formen.

Alles im Spiel ist eine Karte: Ideen, Mitarbeiter, Geld, Bugs, technische Schulden, Burnout, Workshops, Kundenprobleme, Releases, Konflikte und Verbesserungen. Es gibt keine abstrakten Statusleisten für Burnout, Ruf, Tech Debt oder Qualität. Wenn etwas existiert, liegt es als Karte auf dem Tisch und kann gestapelt, verarbeitet, bezahlt, ignoriert oder eskaliert werden.

Der Kern des Spiels ist nicht, eine perfekte Softwarefirma zu simulieren, sondern den absurden Weg von „Ich baue das schnell selbst" zu „Wir brauchen einen Workshop, um zu klären, warum der Workshop nichts gebracht hat" spielerisch greifbar zu machen.

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

Ein Bug liegt auf dem Tisch. Technische Schulden liegen auf dem Tisch. Burnout liegt auf einem Mitarbeiter. Ein Konflikt liegt zwischen zwei Mitarbeitern.

Der Spieler kann diese Karten ignorieren, verschieben, behandeln, umbenennen, ins Backlog legen oder durch Prozesse entschärfen. Ignorierte Probleme verursachen aber laufend neue Probleme.

### 3.5 Wachstum erzeugt Overhead

Mehr Mitarbeiter bedeuten nicht nur mehr Arbeitstempo. Sie erzeugen auch Gehälter, Abstimmungsbedarf, Konflikte, Workshops, Reviews, Meetings und Burnout.

Das Spiel soll sich anfühlen wie:

> „Mit einem Entwickler war alles langsam. Mit fünf Leuten ist alles schneller, aber niemand weiß mehr, was eigentlich gebaut werden soll."

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
7. Mit übrigem Geld kauft der Spieler im Shop neue Karten oder Boosterpacks.

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
Kundenwunsch + Product Owner → Vielversprechende User Story
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

Im späteren Spiel entstehen Prozessketten und Organisationsprobleme:

```text
Workshop + mehrere Mitarbeiter → mehrere Ideen + Burnout
Code-Prüfung + Funktion → weniger Bugs
Testlauf + Funktion → geprüfte Funktion
Release + geprüfte Funktionen → stabile Version
Konflikt + zwei Mitarbeiter → blockiert Zusammenarbeit
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
9. Shop- und Boosterpack-Phase.
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
- Wert-erzeugende Karten (Kunde, Auftrag etc.)
- Ereigniskarten
- Verbesserungs-/Upgradekarten

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
Burnout + Entwickler → Entwickler arbeitet deutlich langsamer
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
Bug + Solo-Entwickler → Bugfix
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
- Kundenwunsch → Vielversprechende User Story
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
- Schlechter Ruf → Ruf reparieren

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

### Externer Dev

Temporäre Mitarbeiterkarte. Kommt nur via Boosterpack (Hot Fix Kit). Verschwindet nach 1–2 Sprints.

Stärken:

- Bug → Bugfix (deutlich schneller als ein normaler Entwickler)

Besonderheiten:

- Kein Gehalt — bezahlt durch das Boosterpack, das ihn enthielt.
- Geht am Ende seiner Lebenszeit automatisch.

---

## 8.2 Ideen- und Anforderungskarten

### Idee

Basisinput für neue Funktionen.

Kann direkt von Entwicklern umgesetzt werden oder zuerst durch Product Owner/Workshop verbessert werden.

```text
Idee + Entwickler → Prototyp / Funktion + Risiko
Idee + Product Owner → User Story
Idee + Designer → Konzept
```

### Kundenwunsch

Entsteht durch Kunden, veröffentlichte Funktionen oder Support-Probleme.

```text
Kundenwunsch + Product Owner → Vielversprechende User Story
Kundenwunsch + Entwickler → Funktion, aber Risiko auf falsche Lösung
Kundenwunsch + Support → Erwartung gemanagt
```

### User Story

Eine klarere Anforderung.

```text
User Story + Entwickler → Funktion
User Story + Tester → Testfälle
```

### Vielversprechende User Story

Bessere Variante einer User Story. Entsteht aus `Kundenwunsch + Product Owner`.

Effekt:

- Erzeugt eine Funktion mit höherer Geld-Ausbeute und niedrigerer Bug-Chance.

```text
Vielversprechende User Story + Entwickler → bessere Funktion
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

Diese Problemkarten sind sichtbar und können bearbeitet werden. Mehr Funktionen = mehr Geld pro Sprint. Mehr Probleme = weniger Geld + Kettenreaktionen.

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
Bug + Externer Dev → Bugfix (schneller)
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
Technische Schulden + ignorieren → Altlast
```

### Burnout

„Dieser Mensch braucht eine Pause. Oder zumindest weniger Dailys."

Liegt auf einem Mitarbeiter.

Effekt:

- Mitarbeiter arbeitet deutlich langsamer.
- Bei zweitem Burnout am selben Mitarbeiter: Ausfall.
- Ausfall + nächstes Sprintende ohne Erholung → Kündigung.

Entstehung:

- `Workshop + Mitarbeiter` → immer +1 Burnout am Workshop-leitenden Mitarbeiter.
- Wiederholbare Tätigkeiten am selben Mitarbeiter (Funktion bauen, Bug fixen, User Story schreiben, Funktion prüfen) erhöhen mit jeder Wiederholung die Burnout-Chance. Sobald ein Burnout entsteht, resettet die Chance an diesem Mitarbeiter.

Behandlung:

```text
Burnout + Stressbewältigungskurs → Burnout entfernt
Burnout + Teambuilding → Burnout am ganzen Team entfernt
Burnout + Urlaub → Burnout entfernt (Mitarbeiter 1 Sprint nicht verfügbar)
```

### Kundenproblem

Entsteht durch Bugs, schlechte Releases oder unerfüllte Wünsche.

```text
Kundenproblem + Support → Beruhigter Kunde
Kundenproblem + Product Owner → Kundenwunsch
Kundenproblem + ignorieren → Schlechter Ruf
```

### Schlechter Ruf

Kein UI-Wert, sondern Karte am Produkt.

Effekt:

- Reduziert Geld aus Releases.
- Erzeugt mehr Kundenprobleme.

Behandlung:

```text
Schlechter Ruf + Support → Schlechter Ruf entfernt
Schlechter Ruf + stabile Version → Schlechter Ruf entfernt
```

### Konflikt

Liegt zwischen zwei Mitarbeitern.

Effekt:

- Beide Mitarbeiter können nicht gemeinsam in Workshops.
- Stapel mit beiden Mitarbeitern erzeugen Verzögerung.

Behandlung:

- **Aussprache (kostenlos, langsam):** beide Mitarbeiter stapeln → Timer läuft bis Sprintende, mindestens 30s. Beide Mitarbeiter sind währenddessen blockiert. Konflikt am Ende entfernt.
- **Stressbewältigungskurs (Consumable, schnell):** `Stressbewältigungskurs + beide Mitarbeiter → Konflikt sofort entfernt` (Kurs verbraucht).

```text
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
```

### Meeting-Flut

Entsteht durch zu viele Daily-Karten in kurzer Folge.

Effekt:

- Mitarbeiter werden langsamer.
- Zählt als wiederholbare Tätigkeit für die Burnout-Mechanik.

Behandlung:

```text
Meeting-Flut + Prozessoptimierung → reduziert Meeting-Flut
```

---

## 8.5 Ressourcenkarten

### Geld

Geld ist eine Karte mit Wert.

Nutzung:

- Mitarbeiter bezahlen
- Karten kaufen
- Boosterpacks kaufen
- Prozesse starten

Beispiele:

```text
Geld + Entwickler → bezahlt
Geld + Shop-Karte → neue Karte
Geld + Boosterpack → 3 Karten aus dem Pack-Pool
```

### Budget

Größere Geldkarte oder temporärer Finanzrahmen.

```text
Budget + Hiring → neuer Mitarbeiter
```

### Zeitgewinn

Temporäre Ressource, z. B. durch Automatisierung oder Prozessverbesserung.

```text
Zeitgewinn + Aufgabe → Aufgabe schneller erledigt
```

### Kaffee

Verbrauchskarte. Einmalige Nutzung, keine Folgeeffekte.

```text
Kaffee + Mitarbeiter → Mitarbeiter arbeitet die nächste Aufgabe schneller
                       → Kaffee verbraucht
```

### Kaffeemaschine

Persistente Karte am Spielfeld. Kommt typischerweise via Boosterpack (Office-Invest).

```text
Kaffeemaschine → 1× Kaffee-Karte pro Sprint
```

---

## 8.6 Prozesskarten

Prozesskarten sind konsumierbare oder wiederverwendbare Karten, die mehrere andere Karten verarbeiten.

### Workshop

Mehrere Mitarbeiter erzeugen mehrere Ideen — und garantiert Burnout.

```text
Workshop + 2–4 Mitarbeiter → mehrere Ideen + 1 Burnout
                              (am Workshop-leitenden Mitarbeiter)
```

Im Early Game ist Workshop schlecht: blockiert Mitarbeiter und liefert garantiert Burnout. Im Midgame stark, weil mehrere Mitarbeiter parallel die Output-Ideen abarbeiten können.

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

Wertvolles Consumable. **Nur via Boosterpack beschaffbar** (Office-Invest).

Entfernt:

- Burnout an einem Mitarbeiter, ODER
- Konflikt zwischen zwei Mitarbeitern.

Karte wird bei Nutzung verbraucht.

```text
Stressbewältigungskurs + Mitarbeiter mit Burnout → Burnout entfernt
Stressbewältigungskurs + zwei Mitarbeiter mit Konflikt → Konflikt entfernt
```

### Teambuilding

Entfernt Burnout an einem Team, kostet Arbeitszeit.

```text
Teambuilding + Team → Burnout am Team entfernt + verlorene Zeit
```

### Hiring

Erzeugt neue Mitarbeiter.

```text
Hiring + Geld → Kandidat
Kandidat + Gespräch → Mitarbeiter / Absage
```

Im Early Game kann man einfache Mitarbeiter über Einzelkauf im Shop holen. Boosterpacks (Talent-Pool) sind die Glücks-Variante mit höherer Vielfalt.

---

## 8.7 Wert-erzeugende Karten

Diese Karten sind die positive Seite des Spiels: sie erzeugen Geld oder Nachfrage, statt Probleme.

### Kunde

Persistente Karte am Spielfeld. Kommt via Boosterpack (Kundenchaos).

```text
Kunde → spuckt periodisch Kundenwunsch aus
```

### Auftrag

Einmalige Karte. Beschreibt eine konkrete gesuchte Funktion (z. B. „Suchfunktion").

```text
Auftrag + passende Funktion + Software → großer Geldoutput, Auftrag verbraucht
Nicht gelieferter Auftrag bis Sprintende → Auftrag verfällt
```

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

### 9.3 Software wächst sichtbar, ohne Levelstufen

Es gibt keine abstrakten Software-Level („Erste Version", „Plattform" o.ä.). Die Software ist eine einzelne Karte, an der Funktionen und Probleme sichtbar haften. Mehr Funktionen = mehr Geld pro Sprint. Mehr Probleme = weniger Geld plus Kettenreaktionen. Wachstum ist sichtbar durch die anwachsende Kartenmenge am Produkt, nicht durch ein Stufen-Etikett.

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
- Burnout-Chance steigt

### 10.2 Idee sauber vorbereiten

```text
Kundenwunsch + Product Owner
→ Vielversprechende User Story

Vielversprechende User Story + Entwickler
→ bessere Funktion

Funktion + Tester
→ Geprüfte Funktion

Geprüfte Funktion + Software
→ mehr Geld
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

### 10.5 Externer Dev rettet Bug-Stau

```text
Hot Fix Kit (Boosterpack) → Externer Dev
Externer Dev + Bug → Bugfix (schneller als normaler Dev)
```

Nach 1–2 Sprints verschwindet der Externe Dev wieder.

---

## 11. Progression

### 11.1 Phase 1: Solo Chaos

Startkarten:

- Solo-Entwickler
- Idee
- Software / Leeres Repository
- kleines Geld
- Kaffee

Gameplay:

- Ideen direkt bauen
- Bugs selbst fixen
- Geld verdienen
- erste technische Schulden entstehen

Ziel:

- Erste Funktionen veröffentlichen
- genug Geld für nächsten Sprint verdienen

Neue Karten im Verlauf:

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
- Vielversprechende User Story
- Testlauf
- Code aufräumen
- Backlog

Gameplay:

- Spieler lernt bessere Pipeline
- Fehler werden sichtbarer
- Gehälter werden wichtiger
- mehrere Aufgaben laufen parallel

Ziel:

- Funktionen stabil veröffentlichen
- genug Geld für Team verdienen

### 11.3 Phase 3: Team & Prozesse

Neue Karten:

- Workshop
- Code-Prüfung
- Daily
- Release
- Hiring
- Konflikt (Burnout-Mechanik wird relevant)
- Postmortem
- Boosterpacks im Shop verfügbar
- Designer (optional via Talent-Pool)

Gameplay:

- Mehrere Ideen werden gleichzeitig erzeugt
- Parallelisierung wird nötig
- Overhead entsteht (Workshop = garantierter Burnout)
- Mitarbeiterbeziehungen werden relevant
- Probleme können Kettenreaktionen auslösen

Ziel:

- Wachstum managen ohne dass Burnout-/Konflikt-Ketten das Team zerreißen
- Trotz Chaos große Releases schaffen

---

## 12. Wirtschaft und Gehälter

### 12.1 Geld als Karte

Geld entsteht durch Releases, Kunden, Aufträge oder bestimmte Events.

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

Externer Dev braucht kein Gehalt — sein Einsatz war im Boosterpack-Preis enthalten.

### 12.3 Kostenstruktur

Bessere Mitarbeiter kosten mehr.

Beispiel:

- Praktikant: wenig Geld, langsam, erzeugt Bugs
- Entwickler: normal
- Senior Entwickler: teuer, schnell, weniger Bugs

---

## 13. Shop und Boosterpacks

Zwischen Sprints gibt es eine Shop-Phase. Auch Shop-Angebote erscheinen als Karten.

### 13.1 Boosterpacks (Stacklands-Stil)

Übriges Geld am Sprintende → Boosterpack kaufen.

```text
Geld + Boosterpack → 3 zufällige Karten aus dem Pack-Pool
```

Spieler darf alle 3 behalten. Boosterpacks sind die zentrale Quelle für seltene/situative Karten — vor allem für Consumables wie Stressbewältigungskurs.

### 13.2 Pack-Themen (Prototyp)

| Pack | Inhalte (Pool) | Strategischer Sinn |
|---|---|---|
| **Gründerpaket** | Idee, Solo-Entwickler, Kaffee, kleines Geld | günstiger Early-Game-Restock |
| **Office-Invest** | Stressbewältigungskurs, Kaffeemaschine, Kaffee, Teambuilding | Mitarbeiter gesund halten |
| **Talent-Pool** | Entwickler, Product Owner, Tester, Support, Designer | gezieltes Hiring (mit Glücksfaktor) |
| **Hot Fix Kit** | Externer Dev, Code aufräumen, Testlauf | Krisen-Pack für Bug-Stau |
| **Kundenchaos** | Kunde, Auftrag, Kundenwunsch | Wertquelle: mehr Nachfrage = mehr Umsatz, wenn man liefern kann |

(Lustigere Copy bei finaler Texthärtung — dies sind Arbeitstitel.)

### 13.3 Einzelkarten-Shop

Daneben gibt es weiterhin Einzelkarten zum Festpreis (Mitarbeiter-Hire, Idee-Karten, Geld-Boosts). Boosterpacks sind die Glücks-/Strategie-Wahl, Einzelkauf die deterministische.

### 13.4 Kaufinteraktion

```text
Geld + Shop-Karte → gekaufte Karte
Geld + Boosterpack → 3 Karten aus Pack-Pool
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
Burnout
→ zweiter Burnout am selben Mitarbeiter
→ Ausfall
→ Sprintende ohne Erholung
→ Kündigung
```

### 14.4 Meeting-Kette

```text
Abstimmungsbedarf
→ Daily
→ Meeting-Flut
→ Burnout
   (Meeting-Flut zählt als wiederholbare Tätigkeit für die Burnout-Mechanik)
```

### 14.5 Konflikt-Kette

```text
Konflikt
→ ignoriert
→ Silodenken
→ gemeinsame Workshops/Reviews dauern länger
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
„Schnell gelöst. Später teuer."

**User Story**  
„Eine klare Beschreibung, was jemand eigentlich braucht."

**Vielversprechende User Story**  
„Klingt nach echtem Bedarf. Sollte man nicht verschwenden."

**Bug**  
„Funktioniert nicht. Hat aber gestern noch funktioniert."

**Workshop**  
„Alle reden mit. Danach gibt es mehr Ideen als vorher. Und einen Burnout."

**Burnout**  
„Dieser Mensch braucht eine Pause. Oder zumindest weniger Dailys."

**Kaffeemaschine**  
„Brummt vor sich hin. Belohnt Geduld."

**Externer Dev**  
„Erscheint, fixt, verschwindet. Stellt keine Fragen."

**Auftrag**  
„Jemand will etwas Bestimmtes — und zahlt dafür."

**Abstimmungsbedarf**  
„Niemand ist blockiert. Alle warten nur aufeinander."

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
- Entwickler
- Product Owner
- Tester
- (Support optional als Stretch)

Input:

- Idee
- Kundenwunsch

Aufgaben/Outputs:

- User Story
- Vielversprechende User Story
- Funktion
- Geprüfte Funktion
- Schnellschuss

Probleme:

- Bug
- Reproduzierbarer Bug
- Technische Schulden
- Burnout

Ressourcen:

- Geld
- Kaffee

Persistente Wert-Karten:

- Kaffeemaschine
- Kunde

Einmalige Wert-Karten:

- Auftrag

Prozesse:

- Workshop
- Testlauf
- Code aufräumen

Consumables (nur via Booster):

- Stressbewältigungskurs
- Externer Dev

Produkt:

- Software

### 17.2 Enthaltene Interaktionen

```text
Idee + Solo-Entwickler → Schnellschuss + Technische Schulden
Idee + Product Owner → User Story
Kundenwunsch + Product Owner → Vielversprechende User Story
User Story + Entwickler → Funktion (+ Burnout-Chance steigt)
Vielversprechende User Story + Entwickler → bessere Funktion
Funktion + Tester → Geprüfte Funktion oder Bug
Funktion + Software → Geld + Bug-Chance
Geprüfte Funktion + Software → mehr Geld + geringe Bug-Chance
Bug + Entwickler → Bugfix
Bug + Externer Dev → Bugfix (schneller)
Technische Schulden + Entwickler → Code aufräumen
Workshop + 2+ Mitarbeiter → Ideen + Burnout (am Leiter)
Burnout + Stressbewältigungskurs → Burnout entfernt
Konflikt + beide Mitarbeiter (gestapelt) → Aussprache (bis Sprintende, min 30s)
Kaffee + Mitarbeiter → schneller, Kaffee verbraucht
Kaffeemaschine → 1× Kaffee pro Sprint
Kunde → periodisch Kundenwunsch
Auftrag + passende Funktion → großer Geldbonus
Geld + Boosterpack → 3 Karten aus Pack-Pool
Geld + Mitarbeiter am Sprintende → bezahlt
```

### 17.3 Prototyp-Ziel

Der Prototyp ist erfolgreich, wenn folgende Entscheidungen interessant sind:

1. Schnell direkt aus Ideen vs. sauber über User Stories?
2. Tester für Qualität vs. Features schneller releasen?
3. Bugs jetzt fixen vs. weiterbauen?
4. Boosterpack kaufen (Glück) vs. Einzelkarte (deterministisch)?
5. Workshop trotz garantiertem Burnout starten?
6. Konflikt aussitzen (Aussprache blockiert Mitarbeiter) vs. Kurs verbrauchen?
7. Lohnt es sich, Externen Dev zu holen statt Bugs in-house zu fixen?

---

## 18. Offene Designfragen

### 18.1 Wie viele Problemkarten sind zu viel?

Problemkarten sollen Druck erzeugen, aber nicht das Spielfeld unlesbar machen.

Mögliche Lösung:

- Gleichartige Probleme können stapeln.
- Problemstapel werden gefährlicher, aber bleiben visuell kompakt.

### 18.2 Wie genau funktioniert Software-Wert?

Wert wird über Karten dargestellt:

- Kundenkarte
- Geldkarte
- Abo-Karte
- Auftrag-Karte

Kein abstrakter Vertrauens- oder Reputationsbalken.

### 18.3 Wie werden langfristige Upgrades dargestellt?

Mögliche Lösung:

- Upgradekarten werden an Mitarbeiter oder Software angelegt.
- Beispiel: „Automatisierte Tests" liegt an Software und reduziert Bug-Chance.

### 18.4 Wie viel Zufall ist gut?

Falsche Kombinationen sollten nicht komplett unberechenbar sein. Der Spieler muss lernen können:

- direkte Umsetzung = schnell, riskant
- saubere Pipeline = langsam, stabil
- Prozesse = mächtig, aber Overhead
- Boosterpacks = Glücksfaktor mit klar geframten Pack-Pools

### 18.5 Wie genau steigt die Burnout-Chance?

Konkrete Kurve (linear, quadratisch?) wird im Prototyp empirisch getuned. Erste Annahme: lineare Steigerung pro Wiederholung am selben Mitarbeiter, sichtbar als Nebenmarker an der Mitarbeiterkarte (z. B. kleiner Punkt, der je Tätigkeit voller wird).

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
- Noch später werden Prozesse mächtig, aber erzeugen Overhead und garantierten Burnout.
- Probleme sind keine Zahlen, sondern Karten, die Platz einnehmen und behandelt werden müssen.
- Boosterpacks sind die zentrale Quelle für seltene, situative Karten und geben dem Spiel eine Stacklands-typische Glücks-Komponente.
- Wachstum löst alte Probleme und erzeugt neue.

Das Spiel sollte sich dadurch wie eine absurde, aber erkennbare Softwareorganisation anfühlen: Jede Karte ist eine Entscheidung, jedes Problem liegt sichtbar auf dem Tisch, und jeder Versuch, Ordnung zu schaffen, kann neuen Scope erzeugen.

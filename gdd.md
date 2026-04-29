# Scope Creep — Game Design Document v1.3

## 1. High Concept

**Scope Creep** ist ein satirisches Stacklike-Kartenspiel über den Aufbau einer chaotischen Softwarefirma. Der Spieler startet als einzelner Entwickler mit einer Idee und versucht, daraus ein wachsendes Softwareprodukt und später ein Team zu formen.

Alles im Spiel ist eine Karte: Ideen, Mitarbeiter, Geld, Bugs, technische Schulden, Burnout, Workshops, Kundenprobleme, Releases, Konflikte und Verbesserungen. Es gibt keine abstrakten Statusleisten für Burnout, Ruf, Tech Debt oder Qualität. Wenn etwas existiert, liegt es als Karte auf dem Tisch und kann gestapelt, verarbeitet, bezahlt, ignoriert oder eskaliert werden.

Der Kern des Spiels ist nicht, eine perfekte Softwarefirma zu simulieren, sondern den absurden Weg von „Ich baue das schnell selbst" zu „Wir brauchen einen Workshop, um zu klären, warum der Workshop nichts gebracht hat" spielerisch greifbar zu machen.

---

## 2. One-Line Pitch

Ein Stacklike über eine wachsende Softwarefirma, in der jede Idee, jeder Bug, jeder Mitarbeiter und jedes Problem als Karte auf dem Tisch liegt — und manche Kombinationen funktionieren auch dann, nur eben langsam und mit Kollateralschaden.

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
Workshop → Ideen → Product Owner → User Stories → Entwickler → Funktionen → Tester → Geprüfte Funktionen → Software
```

Die längere Pipeline ist nicht automatisch besser. Sie lohnt sich erst, wenn das Team groß genug ist, mehrere Aufgaben parallel zu bearbeiten und Qualität wichtiger wird.

### 3.3 Jeder kann alles — aber nicht gleich gut

Jede Mitarbeiterkarte kann grundsätzlich jede Aufgabe bearbeiten. Ein Entwickler kann Ideen ausarbeiten, ein Product Owner kann versuchen zu entwickeln, ein Tester kann Kundenprobleme sortieren.

Aber unpassende Paarungen sind langsamer, riskanter und erzeugen Nebenprodukte wie Bugs, Burnout oder technische Schulden.

Der Spieler darf jederzeit improvisieren. Genau daraus entsteht Comedy und taktische Tiefe.

### 3.4 Probleme sind spielbare Objekte

Negative Effekte sind nicht abstrakt. Sie erscheinen als Karten.

Ein Bug liegt auf dem Tisch. Technische Schulden liegen auf dem Tisch. Burnout liegt auf einem Mitarbeiter. Ein Konflikt liegt zwischen zwei Mitarbeitern.

Der Spieler kann diese Karten ignorieren, verschieben, behandeln oder durch Prozesse entschärfen. Ignorierte Probleme verursachen aber laufend neue Probleme.

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
Workshop + mehrere Mitarbeiter → 1 Idee pro Teilnehmer + 1 Burnout (zufällig)
Code-Prüfung + Funktion → weniger Bugs
Testlauf + Funktion → geprüfte Funktion
Konflikt zwischen zwei Mitarbeitern → blockiert gemeinsame Workshops, verzögert gemeinsame Stapel
```

---

## 6. Spielfluss: Sprints

Das Spiel ist in **Sprints** unterteilt. Ein Sprint ist eine kurze Arbeitsphase mit begrenzter Zeit.

### 6.1 Sprint-Ablauf

Es gibt nur zwei Spielphasen, die sich abwechseln:

1. **Sprint-Phase** startet (Timer 60s läuft, pausierbar mit Leertaste).
2. Karten werden verarbeitet, gestapelt, kombiniert.
3. Mitarbeiter arbeiten auf Kartenstapeln.
4. Funktionen werden auf die Software gelegt und in Geld umgewandelt.
5. Neue Probleme können entstehen.
6. Booster werden bei Bedarf live gekauft (siehe Kap. 13) — **keine eigene Shop-Phase**.
7. Sprint-Timer läuft ab → **Bezahlphase** beginnt.
8. Offene Sprintende-Effekte werden ausgeführt (siehe 6.4).
9. Gehälter werden fällig (manuell oder Auto-Pay).
10. Spieler klickt **„Sprint N+1 starten"** → zurück zu Schritt 1.

Davor — beim Spielstart — kommt der Slot-Auswahl-Screen (siehe Save-System, Kap. 16). Beim Laden eines Sprints wird das Spiel automatisch pausiert, damit der Spieler reagieren kann.

### 6.2 Zeitsteuerung

- Sprint-Dauer: **60 Sekunden Echtzeit**.
- Pause: **Leertaste** friert alle Timer ein. Karten können in der Pause trotzdem bewegt und gestapelt werden (Stacklands-Style). Pause ist **nur während der Sprint-Phase** möglich — die Bezahlphase ist ohnehin Timer-frei.
- **Timer-Carryover**: Unfertige Bearbeitungen pausieren am Sprintende (inkl. der Bezahlphase) und laufen im nächsten Sprint weiter. Das gilt für **jede** laufende Bearbeitung — auch Burnout-„Erholung" ist hier kein Sonderfall. Dadurch ist es sinnvoll, einen sonst unbeschäftigten Mitarbeiter auch auf eine langsamere Aufgabe zu setzen — Däumchen drehen ist die schlechtere Alternative.
- Es gibt **kein Run-Ziel**. Das Spiel ist Endless: möglichst lange überleben und die Firma skalieren.

### 6.3 Sprintende und Bezahlphase

Nach Ablauf der 60 Sekunden startet die **Bezahlphase**. Während dieser Phase sind nur **Geldkarten und Mitarbeiter** beweglich; alle anderen Karten und Stapel sind gesperrt. Die Bezahlphase wird durch Klick auf den Button **„Sprint N+1 starten"** beendet — sie hat keinen Timer.

**Regeln:**

- Pro Mitarbeiter wird **1 Geldkarte** benötigt.
- **Manuelles Bezahlen**: Geldkarte auf Mitarbeiter ziehen → Mitarbeiter ist als bezahlt markiert.
- **Auto-Pay-Button**: Bezahlt alle Mitarbeiter automatisch. Nur verfügbar, wenn genug Geld für **alle** vorhanden ist. Bei zu wenig Geld ist der Button gesperrt — der Spieler muss manuell entscheiden, wen er opfert.
- Mitarbeiter, die zu Beginn des nächsten Sprints nicht bezahlt sind, **kündigen sofort**.
- Wenn ein gekündigter Mitarbeiter mitten in einer Bearbeitung war, fällt die Aufgaben-/Input-Karte zurück auf das Board — der Bearbeitungs-Fortschritt ist verloren, der Stapel löst sich auf.
- Externer Dev braucht kein Gehalt (sein Einsatz war im Boosterpack-Preis enthalten).
- Burnout blockiert die Bezahlung **nicht** — ein Mitarbeiter mit aktiver Burnout-Karte ist trotzdem bezahlbar.

**Game Over:** Sobald der Spieler **0 Mitarbeiter** hat, endet der Run **sofort beim Erreichen** (egal in welcher Phase) — nicht erst beim nächsten Sprintbeginn.

Geld ist keine Zahl im UI, sondern eine oder mehrere Geldkarten mit Werten.

### 6.4 Sprintende-Effekte

Beim Übergang in die Bezahlphase werden folgende Effekte aufgelöst:

- **Auftrag-Verfall**: nicht erfüllte Auftragskarten werden entfernt.
- **Externer Dev**: wird entfernt, wenn er bisher keine Aufgabe abgeschlossen hat.
- Persistente Tick-Karten (Kunde, Kaffeemaschine) merken sich ihren Tick — das Spawning passiert beim **nächsten Sprintstart** (siehe Kap. 8.7).

Das System ist generisch ausgelegt: spätere Karten dürfen Lebensdauern >1 Sprint haben (z. B. „Externer Senior Dev" mit 3 Aufgaben oder beliebig vielen Sprints, „Auftrag mit 2-Sprint-Frist").

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

Einige Karten blockieren Mitarbeiter oder Prozesse — der blockierende Effekt liegt selbst als Karte vor.

Beispiele:

```text
Burnout (Karte auf Mitarbeiter) → Mitarbeiter ist während der „Erholung" vollständig blockiert
Konflikt-Status zwischen zwei Mitarbeitern → können nicht gemeinsam in Workshop
Bug + Software → erzeugt Kundenproblem
Technische Schulden + Software → erhöht Bug-Level bei neu entstehenden Bugs
```

Auch diese Effekte entstehen aus Karten, nicht aus unsichtbaren Zahlen.

### 7.4 Wirksame und neutrale Kombinationen

Es gibt **keine verbotenen Kombinationen** und **kein Konzept „falsche" Kombination**. Jede Karte darf jederzeit auf jeden Stapel gelegt werden — der Spieler kann das Board frei sortieren und Karten gemeinsam verschieben, auch wenn der Stapel keinen Effekt auslöst.

Eine Kombination ist entweder:

- **wirksam** — sie matcht eine Recipe, ein Bearbeitungsladebalken erscheint mit Aktionstext (z. B. „Feature umsetzen…", „User Story schreiben…", „Bug fixen…", „Workshop durchführen…", „Erholung…").
- **neutral** — kein Recipe matcht, kein Effekt, kein Ladebalken, keine Reject-Animation. Der Stapel bleibt einfach liegen.

Unterschiedliche Mitarbeiter können dieselbe wirksame Kombination unterschiedlich schnell erledigen (z. B. Entwickler baut Funktion in 30s, PO in 120s). Das ist kein „falsch", sondern ein Effizienz-Spektrum: einen unbeschäftigten Mitarbeiter auf eine ineffiziente Aufgabe zu setzen ist meist besser, als ihn Däumchen drehen zu lassen — Timer-Carryover über Sprints macht das tragfähig.

**Reihenfolge im Stapel ist irrelevant.** `Bug + Tester` und `Tester + Bug` führen zum selben Recipe-Match.

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
Idee + Solo-Entwickler → Funktion (langsam, Risiko: Technische Schulden + Kundenproblem)
Bug + Solo-Entwickler → Bugfix
Kundenwunsch + Solo-Entwickler → Funktion, aber Risiko auf falsche Funktion
```

Der „Schnellschuss"-Spielstil (Idee direkt vom Solo-Entwickler bauen lassen) ist nur eine Bezeichnung für diese Spielweise — es gibt keine eigene Schnellschuss-Karte. Sauberer wird es, wenn die Idee zuerst durch einen Product Owner zur User Story wird (siehe Kap. 8.2).

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
- Unklare Anforderung → User Story

Schwächen:

- Entwicklung
- Bugfixes
- technische Schulden

### Tester

Findet Bugs und macht Funktionen stabiler.

Stärken:

- Funktion → Geprüfte Funktion
- Bug → Bugfix (langsamer als Entwickler, aber möglich)

Schwächen:

- Funktionen bauen
- Business-Entscheidungen

### Support

Verarbeitet Kundenprobleme.

Stärken:

- Kundenproblem → Beruhigter Kunde
- Bug + Kunde → Bekanntes Problem

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

Temporäre Mitarbeiterkarte. Kommt nur via Boosterpack (Hot Fix Kit).

**Lifecycle:**

- Sprintgebundenes Consumable. Verschwindet **nach genau einer abgeschlossenen Aufgabe** ODER spätestens am Sprintende, wenn er bis dahin noch keine Aufgabe abgeschlossen hat.
- Eine angefangene Aufgabe darf abgebrochen werden (Stapel auflösen) und der Externe Dev neu zugewiesen werden — verbraucht ist er erst, wenn eine Aufgabe **vollständig abgeschlossen** wurde.
- Spätere Booster-Varianten dürfen mit anderen Lifecycle-Regeln kommen (z. B. „3 Aufgaben" oder „beliebige Anzahl Sprints").

Stärken:

- Bug → Bugfix (deutlich schneller als ein normaler Entwickler)

Besonderheiten:

- Kein Gehalt — bezahlt durch das Boosterpack, das ihn enthielt.

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

---

## 8.4 Problemkarten

Problemkarten sind zentrale negative Objekte. Sie bleiben liegen, bis sie behandelt werden.

### Bug

Ein Softwarefehler. Bugs haben ein **Level** (Ganzzahl, Start: 1).

**Bug-Level-Berechnung beim Entstehen:**

```text
Bug-Level = 1 + Anzahl Technische-Schulden-Karten an der Software
```

Beispiel: 0 Tech Debt → Level-1-Bug. 2 Tech Debt → Level-3-Bug.

Höhere Bug-Level bedeuten **längere Bearbeitungszeit** beim Bugfixen (genaue Skalierung im Prototyp empirisch getuned).

Effekt:

- Kann Kundenprobleme erzeugen.

Behandlung:

```text
Bug + Entwickler → Bugfix
Bug + Externer Dev → Bugfix (schneller)
Bug (Level 1) + Bugfix-Patch → Bug entfernt (siehe Kap. 8.6)
Bug + Tester → Bugfix (langsamer)
Bug + Support → Bekanntes Problem
```

**Bugfix-Patch** wirkt nur auf Level-1-Bugs. Höhere Levels brauchen Entwickler oder zukünftige Spezialkarten.

### Technische Schulden

Schnelle Lösungen, die später Arbeit verursachen.

Effekt:

- Erhöht das Level neu entstehender Bugs (Bug-Level = `1 + Anzahl Tech-Debt-Karten an der Software`, **unbegrenzt**).
- Verlangsamt spätere Entwicklung.

Behandlung:

```text
Technische Schulden + Entwickler → Code aufräumen
```

### Burnout

„Dieser Mensch braucht eine Pause. Oder zumindest weniger Dailys."

Burnout ist eine **eigene Karte**, die auf einem Mitarbeiter liegt. Der Mitarbeiter „arbeitet aktiv am Burnout" wie an einer regulären Bearbeitung — der Stapel zeigt den Bearbeitungsladebalken mit dem Aktionstext „Erholung…".

**Entstehung — Burnout-Counter:**

- Jeder Mitarbeiter hat einen internen Wert **Burnout-Chance** (Start: `0.0`).
- Jede produktive Tätigkeit erhöht den Wert um **+0.1** (10 Prozentpunkte). Beispiele für solche Tätigkeiten: Funktion bauen, Bug fixen, User Story schreiben, Funktion prüfen, Workshop-Teilnahme, durch Meeting-Flut beeinflusst sein.
- Nach jeder Tätigkeit erfolgt ein Würfelwurf gegen den aktuellen Wert. Trigger → Burnout-Karte erscheint auf dem Mitarbeiter, der Counter resettet auf `0.0`.
- Sichtbar als kleiner Marker an der Mitarbeiterkarte, der mit dem Counter-Wert sichtbar voller wird.

**Workshop ist die Ausnahme:** erzeugt **garantiert** einen Burnout an einem **zufälligen** Workshop-Teilnehmer (nicht zwingend dem Leiter).

**Bearbeitung des Burnouts:**

- Sobald die Burnout-Karte entsteht, läuft ein **45-Sekunden-Fortschrittsbalken** auf dem Stapel `Mitarbeiter + Burnout`.
- Während dieser Zeit ist der Mitarbeiter **vollständig blockiert** für andere Tätigkeiten — der Burnout ist seine aktuelle „Aufgabe".
- Wie jede Bearbeitung pausiert der Burnout-Timer am Sprintende und läuft im nächsten Sprint weiter.
- Nach 45 Sekunden ist die Burnout-Karte verbraucht und der Mitarbeiter wieder einsatzbereit.
- **Pizza Party** stapelt unter `Mitarbeiter + Burnout` und verkürzt die Bearbeitung auf **5s** (siehe Kap. 8.6).
- **Stressbewältigungskurs** auf einem Mitarbeiter mit Burnout entfernt den Burnout sofort.
- Burnout blockiert die Bezahlphase **nicht** — der Mitarbeiter ist trotzdem bezahlbar.

Behandlung über Karten:

```text
Mitarbeiter + Burnout → 45s „Erholung…" → Burnout entfernt
Mitarbeiter + Burnout + Pizza Party → 5s statt 45s
Mitarbeiter + Burnout + Stressbewältigungskurs → sofort entfernt
```

### Kundenproblem

Entsteht durch Bugs oder unerfüllte Wünsche.

```text
Kundenproblem + Support → Beruhigter Kunde
Kundenproblem + Product Owner → Kundenwunsch
```

### Konflikt

Konflikt ist ein **Status zwischen zwei namentlich benannten Mitarbeitern** (Mitarbeiterkarten zeigen Namen, z. B. Bob, Alice). Dargestellt als **Konflikt-Icon** auf den beiden betroffenen Mitarbeiterkarten.

**Tooltip** (Mouseover oder Controller-Select) auf Bob: „Konflikt: Bob weigert sich, weitere Workshops mit Alice zu besuchen." Analog umgekehrt auf Alice.

**Entstehung:** Nach jedem abgeschlossenen Workshop besteht eine **30%-Chance**, dass zwei **zufällige** Workshop-Teilnehmer einen Konflikt entwickeln. Weitere Quellen (Multi-Personen-Events) sind für spätere Erweiterungen vorgesehen, aktuell out-of-scope.

Effekt:

- Beide Mitarbeiter können nicht gemeinsam auf einen Workshop gestapelt werden.
- Stapel mit beiden Mitarbeitern erzeugen Verzögerung.

Behandlung:

- **Aussprache (kostenlos, langsam):** beide Mitarbeiter stapeln → Timer läuft bis Sprintende, mindestens 30s. Beide Mitarbeiter sind währenddessen blockiert. Konflikt am Ende entfernt.
- **Stressbewältigungskurs (Consumable, schnell):** `Stressbewältigungskurs + beide Mitarbeiter → Konflikt sofort entfernt` (Kurs verbraucht).
- **Automatische Auflösung:** Wenn einer der beiden Konflikt-Mitarbeiter kündigt, verschwindet der Konflikt sofort.

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

In v1 gibt es genau eine Workshop-Variante: den **Brainstorming-Workshop**. Spätere Varianten sind möglich.

**Regeln:**

- Workshop ist eine eigene Karte. Sobald **mindestens 2 Mitarbeiter** auf dem Workshop liegen, startet der Bearbeitungstimer mit Ladebalken „Workshop durchführen…".
- **Reset-Regel:** Wird nach Start ein weiterer Mitarbeiter dazugestapelt, beginnt der Timer von vorne. Damit lässt sich nicht in den letzten Sekunden eines Sprints noch das Team komplett zustapeln, um massenhaft Ideen abzugreifen.
- Beim Abschluss spawnt der Workshop **1 Idee pro anwesendem Mitarbeiter**.
- Beim Abschluss erzeugt der Workshop **garantiert** einen Burnout an einem **zufälligen** Workshop-Teilnehmer.
- 30% Chance auf einen Konflikt zwischen zwei zufälligen Teilnehmern (siehe Kap. 8.4).

```text
Workshop + 2+ Mitarbeiter → N Ideen (N = Teilnehmerzahl) + 1 Burnout (zufälliger Teilnehmer)
                              + 30% Chance auf Konflikt
```

Im Early Game ist der Workshop schlecht: blockiert mehrere Mitarbeiter gleichzeitig und liefert garantiert Burnout. Im Midgame stark, weil mehrere Mitarbeiter parallel die Output-Ideen abarbeiten können.

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

### Pizza Party

Wertvolles Consumable. **Nur via Boosterpack beschaffbar** (Office-Invest).

Effekt:

- Beschleunigt die Bearbeitung einer Burnout-Karte an einem Mitarbeiter von 45 Sekunden auf **5 Sekunden**.
- Wird bei Nutzung verbraucht.

Anwendung:

```text
Mitarbeiter + Burnout + Pizza Party → Burnout-Bearbeitung in 5s statt 45s
```

### Bugfix-Patch

Einfache Shop-Karte. Im Einzelkarten-Shop für **1 Geld** erhältlich.

Effekt:

- Entfernt einen **Level-1-Bug** sofort.
- Wirkt nicht auf Bugs mit Level > 1 — höhere Levels brauchen Entwickler oder zukünftige Spezialkarten.
- Wird bei Nutzung verbraucht.

Anwendung:

```text
Bugfix-Patch + Bug (Level 1) → Bug entfernt
```

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

**Spawning:** Spawnt **1 Kundenwunsch pro Sprintbeginn**, **erst ab Sprint 2** (im allerersten Sprint des Runs noch nicht).

```text
Kunde → 1 Kundenwunsch pro Sprintbeginn (ab Sprint 2)
```

### Auftrag

Einmalige Karte. Beschreibt eine konkrete gesuchte Funktion (z. B. „Suchfunktion").

**Lifecycle:** sprintgebundenes Consumable.

- Verbraucht, sobald eine passende Funktion auf den Auftrag gestapelt wurde → großer Geldbonus.
- Wird am Sprintende entfernt, falls bis dahin nicht erfüllt.
- Eine angefangene Bearbeitung darf abgebrochen werden (Stapel auflösen) und neu zugewiesen werden.
- Spätere Auftrags-Varianten dürfen mit längeren Fristen kommen (z. B. „2-Sprint-Frist").

```text
Auftrag + passende Funktion → großer Geldbonus, Auftrag verbraucht
Nicht erfüllter Auftrag am Sprintende → Auftrag verfällt
```

### Spawning-Regeln (Übersicht)

Damit das System klar ist, hier die zentralen Quellen für neue Karten:

| Karte               | Quelle                                                       | Wann                                                      |
| ------------------- | ------------------------------------------------------------ | --------------------------------------------------------- |
| **Idee**            | Workshop, Kunde (indirekt über Kundenwunsch+PO), Boosterpack | nicht automatisch — keine periodische Spontan-Generierung |
| **Kundenwunsch**    | Kunde-Karte                                                  | 1× pro Sprintbeginn, ab Sprint 2                          |
| **Kaffee**          | Kaffeemaschine                                               | 1× pro Sprintbeginn                                       |
| **Idee (Workshop)** | Brainstorming-Workshop                                       | beim Workshop-Abschluss, 1 pro anwesendem Mitarbeiter     |
| **Booster-Inhalt**  | Boosterpack                                                  | beim Kauf, 3 Karten aus dem Pack-Pool                     |

---

## 9. Produkt- und Softwarekarte

Die Software-Karte ist das Zentrum des Runs.

### 9.1 Funktionen hinzufügen — Level- und Geldsystem

Jede **Idee-** und **Funktions-Karte** trägt ein **Level** (Ganzzahl, Start: 1).

- Bei Idee-Generierung gibt es eine Chance, Ideen mit Level > 1 zu erzeugen (konkrete Wahrscheinlichkeit wird im Prototyp empirisch getuned).
- Funktions-Level wird vom Input geerbt: Level-2-Idee → Level-2-Funktion.
- Ein Upgrade-System für Ideen (z.B. „Externer Berater") ist bewusst out-of-scope für v1.2 und wird später ergänzt.

**Funktion auf Software:**

```text
Funktion + Software → 2s Bearbeitung → Funktion verschwindet → N Geldkarten
```

Wobei N = Level der Funktion. Beispiele:

- Level-1-Funktion → 1 Geldkarte
- Level-3-Funktion → 3 Geldkarten

Während der 2 Sekunden Bearbeitungszeit kann zusätzlich ein Bug entstehen (Wahrscheinlichkeit abhängig von Tech-Debt-Anzahl an der Software, siehe Bug-Mechanik in Kap. 8.4). Geprüfte Funktionen haben eine reduzierte Bug-Chance.

### 9.2 Problemkarten auf der Software

Problemkarten können an der Software haften:

- Bug
- Technische Schulden
- Kundenproblem

Diese Karten belegen Platz und wirken passiv, solange sie nicht bearbeitet werden.

### 9.3 Software wächst sichtbar, ohne Levelstufen

Es gibt keine abstrakten Software-Level („Erste Version", „Plattform" o.ä.). Die Software ist eine einzelne Karte, an der Funktionen und Probleme sichtbar haften. Mehr Funktionen = mehr Geld pro Sprint. Mehr Probleme = weniger Geld plus Kettenreaktionen. Wachstum ist sichtbar durch die anwachsende Kartenmenge am Produkt, nicht durch ein Stufen-Etikett.

---

## 10. Karteninteraktionen: Beispiele

### 10.1 Idee direkt bauen („Schnellschuss"-Spielstil)

```text
Idee + Solo-Entwickler
→ Timer (langsam)
→ Funktion + Risiko (Technische Schulden, Kundenproblem)
```

Nutzen:

- Frühes Geld möglich, ohne PO/Tester-Pipeline aufzubauen
- Direkte Verarbeitung, keine Zwischenkarten

Risiko:

- Tech Debt bleibt am Spielfeld liegen und erhöht Bug-Level
- Kundenproblem-Chance, die mit sauberer User-Story-Pipeline vermeidbar wäre
- Burnout-Counter am Solo-Entwickler steigt

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
→ Funktion (deutlich langsamer als bei einem Entwickler)
```

Nutzbar als Notlösung, wenn alle Entwickler beschäftigt sind. Es gibt keinen Sonder-Output — nur längere Bearbeitungszeit und höheres Bug-Risiko.

### 10.4 QA findet Problem

```text
Funktion + Tester
→ Geprüfte Funktion (mit Chance auf entdeckten Bug)
```

Der Tester erzeugt aus einer Funktion eine geprüfte Funktion. Mit einer gewissen Wahrscheinlichkeit fällt dabei zusätzlich ein Bug aus dem Prozess — versteckte Probleme werden sichtbar.

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
- Hiring
- Konflikt (entsteht aus Workshops; Burnout-Mechanik wird relevant)
- Boosterpacks am Booster-Slot verfügbar
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

Am Sprintende startet die Bezahlphase (siehe Kap. 6.3). Pro Mitarbeiter wird **1 Geldkarte** benötigt.

```text
Geld + Mitarbeiter → Bezahlt
```

Wenn ein Mitarbeiter nicht bezahlt wird, **kündigt er sofort** beim Start des nächsten Sprints. Es gibt keine Vorwarnstufe — die Entscheidung „wen opfere ich" muss in der Bezahlphase fallen.

Externer Dev braucht kein Gehalt — sein Einsatz war im Boosterpack-Preis enthalten.

### 12.3 Kostenstruktur

In v1.2 zahlen alle regulären Mitarbeiter **1 Geld pro Sprint**. Die Differenzierung Praktikant/Entwickler/Senior ist auf eine spätere Version verschoben — der Fokus liegt zunächst auf der Bezahl-Entscheidung selbst (manuell vs. auto), nicht auf Lohn-Tiers.

---

## 13. Shop und Boosterpacks

Es gibt **keine eigene Shop-Phase**. Alle Käufe finden **live während der Sprint-Phase** statt: am Bildschirmrand existiert ein permanenter **Booster-Slot** (Stacklands-Stil). Eine Geldkarte auf diesen Slot zu ziehen, lässt einen Boosterpack herausspringen und auf das Board fallen.

### 13.1 Boosterpacks (Stacklands-Stil)

```text
Geld + Booster-Slot → Boosterpack erscheint
Geld + Boosterpack → 3 zufällige Karten aus dem Pack-Pool
```

Spieler darf alle 3 Karten aus einem geöffneten Pack behalten. Boosterpacks sind die zentrale Quelle für seltene/situative Karten — vor allem für Consumables wie Stressbewältigungskurs.

### 13.2 Pack-Themen (Prototyp)

| Pack              | Inhalte (Pool)                                                            | Strategischer Sinn                                              |
| ----------------- | ------------------------------------------------------------------------- | --------------------------------------------------------------- |
| **Gründerpaket**  | Idee, Solo-Entwickler, Kaffee, kleines Geld                               | günstiger Early-Game-Restock                                    |
| **Office-Invest** | Pizza Party, Stressbewältigungskurs, Kaffeemaschine, Kaffee, Teambuilding | Mitarbeiter gesund halten                                       |
| **Talent-Pool**   | Entwickler, Product Owner, Tester, Support, Designer                      | gezieltes Hiring (mit Glücksfaktor)                             |
| **Hot Fix Kit**   | Externer Dev, Code aufräumen, Testlauf                                    | Krisen-Pack für Bug-Stau                                        |
| **Kundenchaos**   | Kunde, Auftrag, Kundenwunsch                                              | Wertquelle: mehr Nachfrage = mehr Umsatz, wenn man liefern kann |

(Lustigere Copy bei finaler Texthärtung — dies sind Arbeitstitel.)

### 13.3 Einzelkarten-Shop

Daneben gibt es weiterhin Einzelkarten zum Festpreis (Mitarbeiter-Hire, Idee-Karten, Geld-Boosts, **Bugfix-Patch für 1 Geld**). Boosterpacks sind die Glücks-/Strategie-Wahl, Einzelkauf die deterministische.

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
→ Kundenproblem-Stapel an der Software, weniger Geld pro Funktion
```

### 14.2 Tech-Debt-Kette

```text
Technische Schulden an der Software
→ ignoriert
→ Bug-Level neu entstehender Bugs steigt (1 + Tech-Debt-Anzahl)
→ Bugfixes dauern länger
→ noch mehr Tech Debt durch ineffiziente Schnellfixes
```

### 14.3 Burnout-Kette

```text
viele Tätigkeiten am selben Mitarbeiter
→ Burnout-Counter steigt
→ Burnout triggert
→ Mitarbeiter 45s blockiert
→ andere Mitarbeiter müssen kompensieren
```

Ohne Pizza Party oder Stressbewältigungskurs kann das in einem kleinen Team kaskadieren: Wer übernimmt die Arbeit, während ein Mitarbeiter blockiert ist?

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
Konflikt zwischen zwei Mitarbeitern
→ ignoriert
→ beide können nicht gemeinsam in Workshops, gemeinsame Stapel sind verzögert
→ Workshops mit dem restlichen Team
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
- Kundenprobleme liegen als Karten am Produkt.

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

### 16.4 Spielfeld und Kamera

- **Tisch-Größe:** ca. **2× Bildschirmgröße** als Startwert.
- Karten haben **freie Vector2-Positionen**; beim Drop **Auto-Snap** an benachbarte Stapel (Stacklands-Stil).
- **Kamera-Steuerung:**
  - Maus-**Edge-Pan** (RTS-Stil): Maus an den Bildschirmrand bewegt die Kamera.
  - **Scrollrad** zoomt rein und raus.
- **Skalierung:** Spiel skaliert mit der Auflösung; Widescreen zeigt mehr vom Board.

### 16.5 Eingabe

- **Maus** ist primäre Eingabe: Drag-and-Drop, Linksklick, Mouseover-Tooltips, Edge-Pan.
- **Controller** wird vollwertig unterstützt: Card-Selection, Tooltip-Anzeige bei Select.
- **Touch** ist nicht geplant.

### 16.6 Save-System

- **3 manuelle Speicherslots**, wählbar im Hauptmenü.
- **1 Auto-Save-Slot**, hält immer den letzten Spielstand.
- Slot-Auswahl-Screen ist Einstiegspunkt des Spiels.
- Beim Laden eines Sprints wird das Spiel **automatisch pausiert**, damit der Spieler Zeit hat zu reagieren.

### 16.7 Audio

v1 plant Sound-Effekte ein:

- Karte aufheben / ablegen
- Coin- bzw. Geld-Sound
- Bearbeitungs-Abschluss-Klang

Musik-Design ist offen.

### 16.8 Performance-Budget

- Erwartet werden **50–100 sichtbare Karten** im normalen Spielverlauf.
- Spitzenlast (große Geld-Stapel, viele Ideen) kann auf **bis zu ~200 sichtbare Karten** anwachsen.
- Architektur soll diese Größenordnung performant verkraften, ohne dass Drag-and-Drop oder Animationen hängen.

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

Probleme:

- Bug
- Technische Schulden
- Burnout
- Konflikt

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
- Pizza Party
- Externer Dev

Shop-Karten (Einzelkauf):

- Bugfix-Patch (1 Geld, fixt Level-1-Bug)

Produkt:

- Software

### 17.2 Enthaltene Interaktionen

```text
Idee + Solo-Entwickler → Funktion (langsam, Risiko: Tech Debt + Kundenproblem)
Idee + Product Owner → User Story
Kundenwunsch + Product Owner → Vielversprechende User Story
User Story + Entwickler → Funktion (+ Burnout-Counter +0.1)
Vielversprechende User Story + Entwickler → bessere Funktion
Funktion + Tester → Geprüfte Funktion (Chance auf zusätzlichen Bug)
Funktion + Software → 2s „Feature deployen…" → N Geldkarten (N = Funktions-Level), Bug-Chance je Tech Debt
Geprüfte Funktion + Software → 2s → N Geldkarten + reduzierte Bug-Chance
Bug (Level 1) + Bugfix-Patch → Bug entfernt
Bug + Entwickler → Bugfix (Dauer abhängig von Bug-Level)
Bug + Externer Dev → Bugfix (schneller)
Technische Schulden + Entwickler → Code aufräumen
Workshop + 2+ Mitarbeiter → 1 Idee pro Teilnehmer + 1 garantierter Burnout (zufälliger Teilnehmer) + 30% Konflikt-Chance
   (Reset des Bearbeitungstimers, wenn ein weiterer Mitarbeiter dazugestapelt wird)
Mitarbeiter + Burnout → 45s „Erholung…" (vollständig blockiert)
Mitarbeiter + Burnout + Pizza Party → 5s statt 45s
Mitarbeiter + Burnout + Stressbewältigungskurs → Burnout sofort entfernt
Konflikt zwischen zwei Mitarbeitern + beide gestapelt → Aussprache (bis Sprintende, min 30s)
Konflikt + Stressbewältigungskurs + beide → Konflikt sofort entfernt
Kaffee + Mitarbeiter → schneller, Kaffee verbraucht
Kaffeemaschine → 1× Kaffee pro Sprintbeginn
Kunde → 1 Kundenwunsch pro Sprintbeginn (ab Sprint 2)
Auftrag + passende Funktion → großer Geldbonus, Auftrag verbraucht
Geld + Booster-Slot → Boosterpack erscheint
Geld + Boosterpack → 3 Karten aus Pack-Pool
Geld + Mitarbeiter (Bezahlphase) → bezahlt
```

### 17.3 Prototyp-Ziel

Der Prototyp ist erfolgreich, wenn folgende Entscheidungen interessant sind:

1. Schnell direkt aus Ideen vs. sauber über User Stories?
2. Tester für Qualität vs. Features schneller releasen?
3. Bugs jetzt fixen vs. weiterbauen (besonders bei Tech-Debt-erhöhten Bug-Leveln)?
4. Boosterpack kaufen (Glück) vs. Einzelkarte (deterministisch)?
5. Workshop trotz garantiertem Burnout und 30% Konflikt-Risiko starten?
6. Konflikt aussitzen (Aussprache blockiert Mitarbeiter) vs. Kurs verbrauchen?
7. Lohnt es sich, Externen Dev zu holen statt Bugs in-house zu fixen?
8. In der Bezahlphase: alle bezahlen, oder gezielt jemanden opfern, um in einen Boosterpack zu investieren?
9. Ineffizienten Mitarbeiter (z.B. PO auf Funktions-Aufgabe) lieber arbeiten lassen als Däumchen drehen?

---

## 18. Offene Designfragen

### 18.1 Wie viele Problemkarten sind zu viel?

Problemkarten sollen Druck erzeugen, aber nicht das Spielfeld unlesbar machen.

Mögliche Lösung:

- Gleichartige Probleme können stapeln.
- Problemstapel werden gefährlicher, aber bleiben visuell kompakt.

### 18.2 Wie genau funktioniert Software-Wert?

**In v1.2 geklärt:** Funktionen tragen ein Level. `Funktion + Software` produziert nach 2s genau N Geldkarten, wobei N = Funktions-Level (siehe Kap. 9.1). Wert bleibt komplett kartig — keine Vertrauens- oder Reputationsleisten. Kunden- und Auftragskarten sind weiterhin sekundäre Wert-Quellen.

### 18.3 Wie werden langfristige Upgrades dargestellt?

Mögliche Lösung:

- Upgradekarten werden an Mitarbeiter oder Software angelegt.
- Beispiel: „Automatisierte Tests" liegt an Software und reduziert Bug-Chance.

### 18.4 Wie viel Zufall ist gut?

Der Spieler muss lernen können:

- direkte Umsetzung = schnell, riskant
- saubere Pipeline = langsam, stabil
- Prozesse = mächtig, aber Overhead
- Boosterpacks = Glücksfaktor mit klar geframten Pack-Pools

### 18.5 Wie genau steigt die Burnout-Chance?

**Geklärt:** Linear `+0.1` pro Tätigkeit am selben Mitarbeiter. Reset auf `0.0` bei Burnout-Trigger. Sichtbar als Marker an der Mitarbeiterkarte (siehe Kap. 8.4).

### 18.6 Konkrete Balancing-Werte

Folgende Werte sind absichtlich offen und werden im Prototyp empirisch getuned:

- Wahrscheinlichkeit für Idee-Level > 1 bei Generierung
- Bearbeitungszeit-Skalierung pro Bug-Level
- Bearbeitungszeit-Spektrum pro Mitarbeiter-Aufgabe-Kombination (z. B. Entwickler 30s vs. PO 120s für dieselbe Funktion)
- Preise für Boosterpacks und Einzelkarten im Shop
- Tech-Debt-Akkumulation: wie schnell sammeln sie sich, ohne den Spieler zu erdrücken

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

---

## 21. Changelog v1.3

Wesentliche Änderungen gegenüber v1.2 (vor Architekturplanung eingearbeitet):

- **Scope reduziert:** Release-Karte, Schlechter Ruf, Altlast, Störung, Postmortem, Goldrandlösung, Reproduzierbarer Bug, Backlog und das Konzept „falsche Kombinationen" sind aus v1 entfernt.
- **Sprint-Phasen vereinfacht:** Es gibt nur noch Sprint-Phase und Bezahlphase. Keine eigene Shop-/Booster-Phase — Booster werden live über einen permanenten Booster-Slot gekauft.
- **Burnout präzisiert:** eigene Karte auf dem Mitarbeiter, vollständige Blockade während 45s „Erholung…", Pizza Party verkürzt auf 5s, Workshop-Burnout am zufälligen Teilnehmer.
- **Workshop präzisiert:** Brainstorming-Workshop spawnt 1 Idee pro Teilnehmer; Bearbeitungstimer setzt zurück, wenn ein weiterer Mitarbeiter dazugestapelt wird.
- **Save-System, Spielfeld/Kamera, Eingabe, Audio, Performance, Spawning-Regeln, Konflikt-Visualisierung mit Namen/Tooltips** sind ergänzt (Kap. 8.7 + Kap. 16).

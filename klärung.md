# Klärung — offene Punkte vor Architekturplanung

> **Anleitung:** Schreibe deine Antwort jeweils direkt unter die Frage, in den Block `> Antwort:`. Mehrzeilig ist okay. „Bewusst offen / später entscheiden" ist eine valide Antwort.

---

## 1. Echte Widersprüche im GDD

### 1.1 Workshop-Burnout — wer bekommt ihn?

Kap. 8.4 sagt: garantierter Burnout an einem **zufälligen** Workshop-Teilnehmer.
Kap. 8.6 sagt: Burnout am **Workshop-leitenden** Mitarbeiter.

Was gilt?

> **Antwort:**
> 8.4 ist richtig

---

### 1.2 Burnout-Effekt — blockiert oder nur langsamer?

Kap. 7.3: „Burnout + Entwickler → Entwickler arbeitet **deutlich langsamer**".
Kap. 8.4: „Mitarbeiter ist während dieser Zeit **blockiert** und erledigt keine anderen Aufgaben".

Was gilt: vollständig blockiert (45s lang nichts möglich) oder Speed-Multiplikator?

> **Antwort:**
> 8.4 ist richtig. Mitarbeiter arbeitet aktiv am burnout (wird langsam abgearbeitet) und ist dadurch für andere Tätigkeiten blockiert

---

### 1.3 Release-Karte — im Prototyp v1 enthalten?

Kap. 8.6 beschreibt Release als Prozesskarte.
Kap. 17.1 (Prototyp-Scope) führt sie nicht auf.
Kap. 11.3 verschiebt sie auf Phase 3.

Im v1-MVP: ja oder nein?

> **Antwort:**
> es gibt keine release karte. dev produziert feature, feature wird auf software-karte gelegt und innerhalb von 2 sekunden zu geld umgewandelt

---

## 2. Architektur-blockierende Vorentscheidungen

### 2.1 Spielfeld-Layout — frei oder Slot-Grid?

Stacklands-Stil: Karten haben freie Vector2-Positionen, Auto-Snap beim Drop, unbegrenzter (scrollbarer) Tisch.
Slot-Grid: Definierte Karten-Slots, deterministische Anordnung.

Was schwebt dir vor? Stacklands-frei wäre meine Default-Annahme.

> **Antwort:**
> stacklandsstyle, freie position, autosnap beim drop, begrenzter tisch (ca 2x screensize für den anfang, mit scrollen zum rein raus zoomen und kamera bewegt sich mit der maus wenn maus richtung rand geht wie bei rts spielen)

---

### 2.2 Karten-Datenmodell — wie werden ~40+ Kartentypen definiert?

Optionen:

- **Godot Resources (`.tres`)** — im Editor pflegbar, getypt, gut für Designer-Tweaks
- **JSON / data files** — extern editierbar, code-zentrisch
- **GDScript-Klassen pro Karte** — wenig skalierbar

Empfehlung: Godot Resources. Einverstanden?

> **Antwort:**
> einverstanden resources

---

### 2.3 Kombinationsregeln — wie werden sie definiert?

Beispiel: `Idee + Entwickler → Funktion`. Drei Ansätze:

- **Hardcoded match-Logik** in Workern (einfach zu starten, schwer zu erweitern)
- **Datengetriebene Recipe-Tabelle** (z. B. Ressource mit Inputs → Output, Dauer, Risiken)
- **Komponenten-System** (jede Karte hat „Tags", Recipes matchen über Tags)

Empfehlung: Recipe-Ressourcen (Variante 2). Einverstanden?

> **Antwort:**
> einverstanden, recipe ressourcen

---

### 2.4 Save-System — ja, nein, später?

Endless-Mode, lange Runs. Kein Wort dazu im GDD.

- **Ja von Anfang an** — Game-State wird durchgehend serialisierbar entwickelt (keine Mehrkosten wenn früh)
- **Später** — vermutlich teurer Refactor
- **Nein** — Runs sind in einer Sitzung durchspielbar

Was passt zu deinem Spielgefühl?

> **Antwort:**
> ja von anfang an, da es ein endlos mode ist und man lange runs spielen kann. ich möchte 3 speicherslots (wählbar bei spielbeginn) und einen auto save slot, der immer den letzten spielstand speichert.

---

### 2.5 Status-Repräsentation — Burnout als eigene Karte oder als Marker?

Kap. 8.4 widerspricht sich selbst: „Burnout-Karte erscheint auf dem Mitarbeiter" UND „Marker an der Mitarbeiterkarte".

Variante A: Burnout ist eine **eigene Karte** (legt sich auf den Mitarbeiter, kann mit Pizza Party gestapelt werden, wird nach 45s entfernt).
Variante B: Burnout ist nur ein **Status-Marker** auf dem Mitarbeiter (Boolean + Timer); Pizza Party wirkt direkt auf den Mitarbeiter.

Variante A ist konsistenter mit „Alles ist eine Karte" (Pillar 3.1). Einverstanden?

> **Antwort:**
> burnout ist eine karte, die auf dem mitarbeiter liegt. burnout wird auch wie ein feature "bearbeitet". (hat lange dauer und wenn der mitarbeiter samt seinem burnout auf eine pizza party gestapelt wird, wird die bearbeitungszeit auf 5 sekunden reduziert).

---

## 3. Unterspezifizierte Systeme

### 3.1 Karten-Spawning — Quellen und Intervalle

- **Idee**: regeneriert sie sich automatisch? Wenn ja, wie? (periodisch / nur via Workshop, Kunde, Booster?)
- **Kunde**: in welchem Intervall spuckt er Kundenwünsche aus? An Sprintrhythmus gekoppelt oder Realtime-Timer?
- **Kaffeemaschine**: 1× Kaffee pro Sprint — am Sprintstart, Sprintende, oder mittendrin?
- **Workshop**: wie viele Ideen genau? Fix oder skaliert mit Teilnehmerzahl?

> **Antwort:**
> idee kommt nur via Workshop, Kunde, Booster
> kunde: es spawnt bei sprintbeginn ein kundenwunsch (erst ab sprint 2)
> kaffeenaschine: 1x kaffee pro sprint am sprintbeginn
> workshop: es spawnt 1 idee pro anwesendem mitarbeiter wenn der workshop beendet ist. (workshop ist eine karte und sobald man mindestens zwei mitarbeiter darauf gestapelt hat startet der bearbeitungstimer. es gibt später verschiedene workshop karten aber wir starten jetzt erstmal mit einem Brainstorming-Workshop der pro Mitarbeiter eine idee spawnt. Immer wenn ein weiterer Mitarbeiter auf den WOrkshop dazugestapelt wird startet die bearbeitung von vorne um zu verhindern, dass nicht in den letzten 5 sekunden alle mitarbeiter darauf gestackt werden um massig ideen zu generieren)

---

### 3.2 Stapel-Mechanik im Detail

- Reihenfolge im Stapel relevant? `Bug + Tester` vs. `Tester + Bug` — gleiches Ergebnis?
- Mehrere Mitarbeiter auf einem Stapel (Workshop): alle gleichzeitig blockiert für die Workshop-Dauer?
- Ungültiger Drop: Karte snappt zurück, bleibt liegen, oder Reject-Animation?
- Echte Verbots-Kombinationen (z. B. Geld + Software)? Oder fällt alles in „macht halt nichts"?

> **Antwort:**
> reihenfolge egal, gleiches ergebnis es kommt nur auf die kombination an (was genau gerade passiert woll am bearbeitungsladebalken stehen. bspw "Feature umsetzen..." "Userstory schreiben..." "Feature testen..." "Bug fixen..." "Feature deployen..." "Workshop durchführen...")
> mehrere mitarbeiter auf einem stapel (workshop): ja alle arbeiten am workshop und machen in der zeit nichts anderes. erst wenn sie von dem stapel abgelöst werden, können sie wieder arbeiten.
> ungültiger drop: karte stapelt sich trotzdem, aber es passiert nichts. (kein bearbeitungsladebalken) es gibt keine reject animation. so kann der spieler tortzdem jede karte stapeln und gemeinsam hin und her schieben um aufzuräumen.
> es gibt keine verbotenen kombinationen. es gibt nur kombinationen die nichts tun (z.b. geld + software) und kombinationen die etwas tun (z.b. idee + entwickler).

---

### 3.3 Bezahlphase-Edge-Cases

- Mitarbeiter X läuft auf 80 % Aufgabenfortschritt, wird nicht bezahlt → kündigt. Was passiert mit der Aufgabe? (Karten zurück auf den Tisch / Karten verloren / Aufgabe bleibt für Übernahme bereit?)
- Burnout-45s-Timer überschneidet das Sprintende: pausiert er in der Bezahlphase oder läuft weiter?

> **Antwort:**
> die karte an der der gekündigte mitarbeiter gearbeitet hat liegt einfach wieder auf dem board und muss komplett neu bearbeitet werden. der fortschritt ist weg
> am sprintende pausiert der burnout timer wie jede bearbeitung. jede bearbeitung kann über sprintgrenzen hinaus weitergehen. genauso der die burnout "bearbeitung" das ist kein sonderfall

---

### 3.4 „Falsche Kombinationen" — konkrete Regel

Kap. 7.4: „deutlich höhere Bearbeitungszeiten, oft länger als 60s".

- Hardcoded pro Kombination (z. B. PO+Coding = 90s) oder formelbasiert (z. B. 3× normaler Zeitwert)?
- Ergebnis: derselbe Output-Typ, nur langsamer + bug-anfälliger? Oder anderer Output (z. B. „Falsche Funktion")?

> **Antwort:**
> es gibt keine falschen kombinationen. es gibt nur kombinationen die nichts tun (z.b. geld + software) und kombinationen die etwas tun (z.b. idee + entwickler). das heißt jede kombination die in der realität falsch klingt ist einfach nur eine pflegesache -> entwickler entwickelt feature in 30 sek, ein PO braucht 120 sek um das feature zu entwickeln. das heißt es gibt keine falschen kombinationen, es gibt nur kombinationen die länger dauern und kombinationen die kürzer dauern.

---

### 3.5 Sprint-Phasen — saubere State-Machine

Ich sehe vier Zustände: **Sprint-Active → Pause (jederzeit toggle) → Bezahlphase → Shop/Booster-Phase → nächster Sprint**.

- Ist Pause während der Bezahlphase / Shop-Phase auch möglich oder nur während Sprint-Active?
- Hat Shop/Booster-Phase einen Timer oder ist sie unbegrenzt (Spieler klickt „weiter")?

> **Antwort:**
> es gibt keine shop-phase. wie in stacklands wird während des sprints geld auf den booster shop am rand gezogen sodass ein booster herausploppt.
> pause gibt es nur während dem sprint, da nur hier die zeit läuft
> es gibt also folgende spielphasen: sprint (timer läuft, pausierbar) -> bezahlphase (manuell oder autopay, wird beendet durch "Sprint 2 starten" button) -> sprint -> usw.
> davor gibt es noch den screen in dem man den speicherslot wählen kann, den man laden möchte. nach dem laden ist das spiel pausiert, falls man sich gerade in der sprint phase befindet, damit man reagieren kann

---

## 4. Lückenhaft beschriebene Karten / Effekte

### 4.1 Externer Dev — Lebensdauer

„Verschwindet nach 1–2 Sprints". Genau 1, genau 2, oder zufällig zwischen 1 und 2?

> **Antwort:**
> ist ein sprintgebundenes consumable. wird nach genau einer abgeschlossenen aufgabe entfernt. am sprint-ende wird er auch entfernt, falls er noch nicht verbraucht wurde.
> man kann seine aufgabe aber abbrechen (karten auseinanderziehen) und ihm eine andere aufgabe zuweisen. es zählt erst wenn eine aufgabe ganz abgeschlossen wurde

---

### 4.2 Auftrag — Verfall-Timing

„Nicht gelieferter Auftrag bis Sprintende → verfällt". Am Sprintende des Erscheinens oder am nächsten?

> **Antwort:**
> ist ein sprintgebundenes consumable. wird nach genau einem abgeschlossenen auftrag entfernt. am sprint-ende wird er auch entfernt, falls er noch nicht verbraucht wurde. man kann eine aufgabe aber abbrechen (karten auseinanderziehen) und sie einem anderen mitarbeiter zuweisen.

---

### 4.3 Schlechter Ruf — Effektgrößen

- Wie viel weniger Geld pro Schlechter-Ruf-Karte aus Releases?
- Stapeln sich mehrere Schlechter-Ruf-Karten (kumulativ schlimmer) oder ist max. eine pro Software möglich?
- Wahrscheinlichkeit für „erzeugt mehr Kundenprobleme"?

> **Antwort:** Ruf system wird erstmal nicht implementiert. Entfernen wir aus dem gdd

---

### 4.4 Altlast und Störung — Karten oder nur Erwähnung?

Kap. 8.4 / 14 erwähnt sie als Eskalations-Endpunkte, beschreibt sie aber **nicht als Karten** (eigener Effekt, eigene Behandlung). Sind das vollwertige Karten in v1 oder erst später?

> **Antwort:** altlasten, entfernen

---

### 4.5 Goldrandlösung — Entstehungsrezept

Kap. 8.3 listet sie als Output, aber **kein Rezept führt zu ihr**. Wie entsteht sie? (z. B. Designer + Funktion? Workshop + Vielversprechende User Story? Random?)

> **Antwort:**
> entfernen

---

### 4.6 Reproduzierbarer Bug — Vorteil

Effekt nur „sauberer Bugfix". Heißt: gleiche Dauer, aber weniger Risiko? Oder kürzere Dauer? Oder garantiert kein Folge-Bug?

> **Antwort:**
> entfernen

---

### 4.7 Backlog — Funktion?

Kap. 11.2 listet als neue Karte, aber Funktion nicht erklärt. Container für Karten? Mit Limit? Auto-Sortierung? Holt man Karten manuell wieder raus?

> **Antwort:**
> entfernen

---

### 4.8 PowerPoint-Prototyp / Scope Creep

Kap. 10.3: „User Story + PO → PowerPoint-Prototyp + Scope Creep". Sind das echte Karten in v1, oder Flavor-Output in der Beschreibung?

> **Antwort:**
> entfernen

---

### 4.9 „Offene Sprintende-Effekte" (Kap. 6.1 Schritt 8)

Welche Effekte sind das konkret? (z. B. Auftrags-Verfall, Externer-Dev-Ablauf, Kunden-Kundenwunsch-Tick?)

> **Antwort:**
> Auftrags-Verfall, Externer-Dev-Ablauf, Kunden-Kundenwunsch-Tick (hier die grundlage schaffen, dass die dinge auch länger wie ein sprint halten können. bspw später gibts vielleicht einen besseren externen dev, der 3 aufgaben erledigen kann und über beliebige sprints hält. oder ein auftrag, der in den nächsten 2 sprints erledigt sein muss bevor er verschwindet)

---

## 5. Plattform / Eingabe / Performance

### 5.1 Eingabe — was muss unterstützt werden?

- Maus-only (Drag-and-Drop, Linksklick)?
- Tastatur-Shortcuts (außer Leertaste = Pause)?
- Controller? Touch?

> **Antwort:**
> Maus und Controller. Touch ist nicht geplant.

---

### 5.2 Display / Skalierung

`project.godot` zeigt 1920×1080. Soll das Spiel auf andere Auflösungen skalieren oder ist 1080p fix?

> **Antwort:**
> soll skalieren. mit widescreen sieht man man einfach mehr vom board

---

### 5.3 Performance-Erwartung

Wie viele Karten gleichzeitig auf dem Tisch im Spätspiel? (~50? ~100? ~200+?)
Beeinflusst Render-/Animations-Architektur (Control-Nodes vs. Custom Drawing).

> **Antwort:**
> ähnlich wie stacklands, also nicht allzu viele karten. ich schätze mal so um die 50-100 karten maximal auf dem tisch gleichzeitig (da aber auch geld bspw ein großer stapel wird und später auch ideen etc kann es schon mehr werden)

---

### 5.4 Audio

GDD erwähnt Audio nicht. Im v1 Prototyp: Sound-Design einplanen oder später?

> **Antwort:**
> effekte wie karte aufheben, ablegen, coin sound etc sollen eingeplant werden

---

## 6. Sonstiges

### 6.1 Konflikt-Persistenz

Wenn einer der beiden Konflikt-Mitarbeiter kündigt: Konflikt-Karte verschwindet automatisch, oder bleibt sie liegen / muss manuell entfernt werden?

> **Antwort:**
> konflikt verschwindet wenn einer kündigt. Konflikt wird dargestellt über ein Icon auf der karte der mitarbeiter die einen konflikt haben. Die mitarbeiter werden namen haben. ein mouseover oder select mit controller zeigt den tooltip einer karte. im tooltip stehen details zur karte und bspw zu effekten wie dem konflikt. mouseover bei bob zeigt "Konflikt: Bob weigert sich weitere Workshops mit Alice zu besuchen". mouseover bei alice zeigt "Konflikt: Alice weigert sich weitere Workshops mit Bob zu besuchen".

---

### 6.2 Tech-Debt-Obergrenze

Bug-Level = `1 + Anzahl Tech-Debt-Karten`. Theoretische Obergrenze (z. B. max 10 Tech-Debt am Produkt)? Oder unbegrenzt?

> **Antwort:**
> unbegrenzt

---

### 6.3 Game Over — sofort oder Verzögerung?

„0 Mitarbeiter → Run endet". Sofort beim Erreichen oder erst zu Sprintbeginn (analog zur Kündigungslogik)?

> **Antwort:**
> sofort beim erreichen

---

> **Wenn fertig:** speichern und mir Bescheid geben — ich nutze die Antworten als Basis für die Architekturplanung.

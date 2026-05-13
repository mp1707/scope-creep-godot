# Scope Creep - PoC4-Plan

Dieses Dokument ist der Arbeitsplan fuer den vierten aussagekraeftigen Playtest-Slice in Godot 4.6. Es baut auf `poc4-idee.md`, `poc3-plan.md`, `architecture.md` und `gdd.md` v1.4 auf.

PoC4 ist kein Rewrite. Der bestehende PoC3 bleibt die technische Basis. Ziel ist, Teamwachstum als bewusst langsame, unsichere und kostenpflichtige Pipeline spielbar zu machen:

```text
Talent-Pool -> Bewerber -> Bewerbungsgespraech -> Angebot -> Einstellung -> Onboarding -> produktiver Mitarbeiter
```

Der Plan ist in groessere, abhakbare Phasen geschnitten. Jede Phase soll in einer Codex-Context-Session sinnvoll umsetzbar, headless testbar und danach im Editor kurz pruefbar sein. Editor-Arbeit ist dort markiert, wo visuelle Abstimmung, Scene-/Inspector-Pflege oder Playtest-Feedback sauberer ist als Textdatei-Automation.

## Fortschritt

- [ ] Phase 0 - Baseline sichern und PoC4-Scope einfrieren
- [ ] Phase 1 - Hiring-Content, Balance-Werte und Validation vorbereiten
- [ ] Phase 2 - Talent-Pool neu konfigurieren
- [ ] Phase 3 - Bewerbungsgespraeche und Angebots-Output
- [ ] Phase 4 - Angebote bezahlen und Mitarbeiter mit Onboarding erzeugen
- [ ] Phase 5 - Onboarding als Attachment-Blocker
- [ ] Phase 6 - Recruiter als Hiring-Spezialist
- [ ] Phase 7 - Werkstudent als temporaere Hilfskraft
- [ ] Phase 8 - PoC3-Loop, Bezahlphase und Save/Load integrieren
- [ ] Phase 9 - Presentation, Playtest-Balancing und QA
- [ ] Stretch - Recruiter-Onboarding-Begleitung und Rollen-Fallbacks schaerfen

## PoC4-Ziel

Am Ende von PoC4 soll ein PoC3-Run mit kontrolliertem Teamwachstum spielbar sein:

1. Der Talent-Pool erzeugt keine sofort produktiven regulaeren Mitarbeiter mehr.
2. Talent-Pool-Booster kosten 2 Geld und liefern Bewerber oder Werkstudenten.
3. Bewerber muessen von Mitarbeitern interviewt werden.
4. Normale Interviews sind langsam und unsicher.
5. Recruiter-Interviews sind schneller und erfolgreicher.
6. Erfolgreiche Interviews erzeugen Angebotskarten.
7. Angebote werden mit 1 Geld eingestellt.
8. Neue regulaere Mitarbeiter starten mit angehefteter Onboarding-Karte.
9. Onboarding blockiert Arbeit, aber nicht Gehalt.
10. Werkstudenten geben langsame, temporaere Arbeitskapazitaet ohne Gehalt.
11. Hiring konkurriert sichtbar mit Gehaeltern, Business Goals, Boostern und Patch-Shop.

## Nicht Ziel von PoC4

- Kein vollstaendiges HR-System.
- Keine Mitarbeiter-Traits.
- Keine Senior-/Junior-Level und keine Gehaltstiers.
- Kein Angebotsverfall.
- Keine Kandidatenqualitaet oder Kandidaten-Level.
- Keine Kuendigungen wegen Stimmung oder Moral.
- Kein Externer Dev im normalen PoC4-Content.
- Keine neuen Business-Goal-Arten.
- Keine neuen Kundentypen.
- Kein komplettes Booster-Rebalancing ausser Talent-Pool.
- Kein vollstaendiges Konfliktsystem.
- Keine neue Satirekarten-Schicht rund um HR.

## Architekturentscheidungen fuer PoC4

PoC4 erweitert die Zielarchitektur, ohne die Trennung von Simulation und Presentation aufzuweichen:

- Bewerber, Angebote, Onboarding und Werkstudent sind echte Karten.
- Hiring-Erfolg laeuft ueber deterministische Run-RNG-Effects, nicht ueber UI-Code.
- Onboarding ist ein Attachment-Blocker wie Burnout, aber mit eigener Fachregel.
- Regulaere Mitarbeiter und temporaere Arbeitskarten werden ueber Tags/Queries unterschieden.
- Geld bleibt immer 1-Geld-Karte.
- Angebot bezahlen ist eine Simulation-Interaktion, die auch in der Bezahlphase erlaubt ist.
- Neueinstellungen in der Bezahlphase werden erst ab dem naechsten Sprint gehaltsrelevant.

GDD-Spannung: `poc4-idee.md` beschreibt den Recruiter als stark auf Hiring beschraenkt. Das GDD sagt aber "Jeder kann alles - aber nicht gleich gut". Empfehlung fuer PoC4: Der Recruiter bekommt nur produktionsrelevante Recipes, wenn wir sie als extrem langsame Rollen-Fallbacks sauber in der Recipe-/Duration-Logik modellieren koennen. Sonst bleibt das als bewusst markierte PoC4-Einschraenkung im Stretch, nicht als stiller Bruch der Zielregel.

## PoC4-Content-Scope

### Neue Karten

Bewerber:

- `card.candidate.developer` - Entwickler-Bewerber
- `card.candidate.product_owner` - Product-Owner-Bewerber
- `card.candidate.tester` - Tester-Bewerber
- `card.candidate.recruiter` - Recruiter-Bewerber

Angebote:

- `card.offer.developer` - Entwickler-Angebot
- `card.offer.product_owner` - Product-Owner-Angebot
- `card.offer.tester` - Tester-Angebot
- `card.offer.recruiter` - Recruiter-Angebot

Mitarbeiter / Hilfskraft:

- `card.employee.recruiter` - Recruiter
- `card.temp_worker.work_student` - Werkstudent

Blocker:

- `card.blocker.onboarding` - Onboarding

### Geaenderte Karten und Booster

- `booster.talent_pool` - enthaelt keine direkten regulaeren Mitarbeiter mehr.
- `card.employee.external_dev` - bleibt als existierender Content erhalten, wird aber nicht in normalen PoC4-Boosterpools genutzt.

### Empfohlene Tags

- Bewerber: `candidate`, Zielrolle z. B. `developer_candidate`, `hiring`
- Angebote: `offer`, Zielrolle z. B. `developer_offer`, `hiring`
- Recruiter: `employee`, `regular_employee`, `recruiter`, `salary_required`
- Werkstudent: `temp_worker`, `work_student`, `no_salary`, `one_task_lifetime`
- Onboarding: `blocker`, `attachment`, `onboarding`, `employee_blocker`

### Balance-Startwerte

```text
Talent-Pool-Kosten: 2 Geld
Talent-Pool-Ziehungen: 3 Karten
Normales Bewerbungsgespraech: 20s
Normale Interview-Erfolgschance: 40%
Recruiter-Bewerbungsgespraech: 10s
Recruiter-Erfolgschance: 70%
Angebot einstellen: 1 Geld
Onboarding-Dauer: 20s
Recruiter-Onboarding-Dauer: 10s
Werkstudent-Aufgabendauer: +100%
Werkstudent-Lebensdauer: 1 erfolgreich abgeschlossene Aufgabe
```

## Kerninteraktionen

```text
Geld + Talent-Pool-Slot -> Talent-Pool-Booster
Talent-Pool-Booster oeffnen -> 3 Karten aus Bewerbern/Werkstudent

Bewerber + regulaerer Mitarbeiter -> 20s Bewerbungsgespraech -> 40% Angebot / 60% Bewerber verschwindet
Bewerber + Recruiter -> 10s Bewerbungsgespraech -> 70% Angebot / 30% Bewerber verschwindet

Angebot + Geld -> passender Mitarbeiter + angeheftetes Onboarding
Mitarbeiter + Onboarding -> 20s Onboarding -> Onboarding verschwindet

Laufendes Onboarding + Kaffee -> +25% Fortschritt, Kaffee verbraucht

Werkstudent + normale Aufgabe -> Aufgabe dauert +100%, Werkstudent verschwindet nach Abschluss
```

## Phase 0 - Baseline sichern und PoC4-Scope einfrieren

Ziel: PoC4 beginnt auf einem stabilen PoC3-Stand, ohne bestehende User-Aenderungen, Content-IDs oder PoC3-Regeln versehentlich zu beschaedigen.

Codex:

- [ ] `git status --short` pruefen und lokale User-Aenderungen nicht ueberschreiben.
- [ ] `poc4-idee.md`, `poc3-plan.md`, `architecture.md` und `gdd.md` vor Implementierung erneut querpruefen.
- [ ] Aktuellen PoC3-Headless-Check ausfuehren und bekannte Altlasten notieren.
- [ ] Bestehende IDs fuer Talent-Pool, Booster-Slots, Employee-Tags, Burnout, Kaffee, Bezahlphase und Save/Load erfassen.
- [ ] Sicherstellen, dass `architecture.md` die neuen Systemgrenzen fuer Hiring Lifecycle, Onboarding und temporaere Arbeitskarten beschreibt.
- [ ] PoC4-Content-Version und moegliche Save-Migration festlegen, bevor neue IDs produktiv genutzt werden.

Marco:

- [ ] Aktuellen PoC3 im Editor starten und bestaetigen, dass der letzte Playtest-Stand weiterhin spielbar ist.
- [ ] Entscheiden, ob PoC4 auf einem neuen Branch umgesetzt wird.
- [ ] Scope bestaetigen: Talent-Pool wird wieder aktiviert, aber ohne sofort produktive regulaere Mitarbeiter.

Definition of Done:

- [ ] PoC3-Baseline ist bekannt und testbar.
- [ ] PoC4-Scope ist schriftlich eingefroren.
- [ ] Architekturwidersprueche sind dokumentiert oder aufgeloest.
- [ ] Keine ID-Umbenennungen ohne Migration/Alias-Regel.

Headless-Check:

```bash
tools/check_poc.sh
```

## Phase 1 - Hiring-Content, Balance-Werte und Validation vorbereiten

Ziel: Alle neuen PoC4-Karten und Balance-Werte existieren datengetrieben, bevor Gameplay-Logik darauf aufsetzt.

Codex:

- [ ] CardDefinitions fuer 4 Bewerberkarten anlegen.
- [ ] CardDefinitions fuer 4 Angebotskarten anlegen.
- [ ] CardDefinition fuer `card.employee.recruiter` anlegen.
- [ ] CardDefinition fuer `card.temp_worker.work_student` anlegen.
- [ ] CardDefinition fuer `card.blocker.onboarding` anlegen.
- [ ] Tags so setzen, dass RuleQueries regulaere Mitarbeiter, temporaere Arbeitskarten, Bewerber, Angebote und Onboarding unterscheiden koennen.
- [ ] BalanceDefinition um Interview-Dauern, Interview-Chancen, Einstellungskosten, Onboarding-Dauer und Werkstudent-Dauer-Multiplier erweitern.
- [ ] Content-Validator erweitern: Bewerber muessen Ziel-Angebot referenzieren; Angebote muessen Ziel-Mitarbeiter referenzieren; Onboarding muss Attachment-faehig sein.
- [ ] Headless-Validation fuer neue Resources schreiben oder vorhandene Validation erweitern.

Marco:

- [ ] Neue Resources im Godot Editor oeffnen und pruefen, ob Felder sinnvoll editierbar sind.
- [ ] Farben, Typmarker und Kurztexte grob abstimmen: Bewerber, Angebot, Mitarbeiter, Blocker und Temp-Worker muessen unterscheidbar sein.
- [ ] Tooltips sprachlich pruefen, besonders "Angebot ist noch kein Mitarbeiter" und "Onboarding blockiert Arbeit".

Definition of Done:

- [ ] Alle PoC4-Karten existieren als Resource.
- [ ] Balance-Werte liegen nicht hardcodiert in Gameplay-Scripts.
- [ ] Content-Validation meldet fehlende Hiring-Verknuepfungen.
- [ ] Keine neue Karte ist nur implizit per String im Script bekannt.

Headless-Test:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/marcopreuss/Documents/ProjectsLocal/scope-creep-godot --script res://scripts/validation/run_content_validation.gd
```

## Phase 2 - Talent-Pool neu konfigurieren

Ziel: Talent-Pool ist wieder aktiv, liefert aber keine sofort produktiven regulaeren Mitarbeiter mehr.

Codex:

- [ ] `booster.talent_pool` auf Kosten `2 Geld` setzen.
- [ ] Talent-Pool-Ziehung auf 3 Karten pruefen oder setzen.
- [ ] Talent-Pool-Pool auf Werkstudent und die 4 Bewerberkarten umstellen.
- [ ] Direkte Entwickler-, Product-Owner-, Tester-, Recruiter- und Externer-Dev-Karten aus dem Talent-Pool entfernen.
- [ ] PoC4-Startsetup um sichtbaren Talent-Pool-Slot erweitern.
- [ ] Falls das vorhandene Startsetup zu voll wird, Sichtbarkeit ab Sprint 2 als konfigurierbare Alternative vorbereiten, aber initial direkt sichtbar lassen.
- [ ] Tests fuer Booster-Kosten, Pool-Inhalt, deterministische Ziehung und Startsetup schreiben.

Marco:

- [ ] Im Editor/Playtest pruefen, ob der Talent-Pool-Slot am Start sichtbar und nicht visuell ueberladen ist.
- [ ] Bewerten, ob Talent-Pool direkt ab Sprint 1 zu viele Entscheidungen erzeugt.
- [ ] Booster-Tooltip pruefen: Er muss klar sagen, dass Bewerber erst interviewt werden muessen.

Definition of Done:

- [ ] Talent-Pool erzeugt keine produktiven regulaeren Mitarbeiter direkt.
- [ ] Talent-Pool kostet 2 einzelne Geldkarten.
- [ ] Booster-Ziehung bleibt RNG-deterministisch.
- [ ] Externer Dev bleibt aus normalem PoC4-Hiring heraus.

Headless-Test:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/marcopreuss/Documents/ProjectsLocal/scope-creep-godot --script res://tests/test_poc4_phase_2_talent_pool.gd
```

## Phase 3 - Bewerbungsgespraeche und Angebots-Output

Ziel: Bewerber koennen ueber normale Mitarbeiter oder Recruiter interviewt werden und erzeugen deterministisch testbare Erfolg-/Misserfolgsergebnisse.

Codex:

- [ ] Generische Query implementieren oder erweitern: `is_regular_employee(card)` fuer bezahlpflichtige Mitarbeiter.
- [ ] Interview-Recipes fuer `Bewerber + regulaerer Mitarbeiter` anlegen: 20s, 40% Erfolg.
- [ ] Recruiter-spezifische Interview-Recipes vorbereiten oder mit hoeherer Specificity definieren: 10s, 70% Erfolg.
- [ ] Erfolg erzeugt passendes Angebot; Misserfolg entfernt Bewerber ohne weitere Negativkarte.
- [ ] Interviewer-Rolle ausser Recruiter fuer PoC4 egal halten.
- [ ] Active Processing bei Stack-Aenderung unveraendert sofort abbrechen lassen.
- [ ] Tests fuer Erfolgspfad, Misserfolgspfad, RNG-Determinismus, spezifischeres Recruiter-Recipe und neutrale Zusatzkarten schreiben.

Marco:

- [ ] Aktionstext pruefen: `Bewerbungsgespraech...`.
- [ ] Im Playtest bewerten, ob Interviewdauer und Misserfolg visuell fair wirken.
- [ ] Pruefen, ob Bewerberkarten nicht wie fertige Mitarbeiter missverstanden werden.

Definition of Done:

- [ ] Jeder Bewerber kann mit einem regulaeren Mitarbeiter interviewt werden.
- [ ] Recruiter-Interview gewinnt gegen normales Interview.
- [ ] Erfolg/Misserfolg ist headless deterministisch testbar.
- [ ] Kein Interview-Ergebnis wird in Presentation-Code entschieden.

Headless-Test:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/marcopreuss/Documents/ProjectsLocal/scope-creep-godot --script res://tests/test_poc4_phase_3_interviews.gd
```

## Phase 4 - Angebote bezahlen und Mitarbeiter mit Onboarding erzeugen

Ziel: Angebote sind sichtbare Zwischenkarten. Erst Geld auf Angebot erzeugt einen neuen Mitarbeiter, der noch nicht produktiv ist.

Codex:

- [ ] Angebots-zu-Mitarbeiter-Mapping datengetrieben modellieren, z. B. in Offer-Card-Defaultwerten oder Effect-Parametern.
- [ ] Recipe oder Command fuer `Angebot + Geld -> Mitarbeiter + Onboarding` implementieren.
- [ ] Geldkarte immer verbrauchen; Angebot immer verbrauchen.
- [ ] Neuer Mitarbeiter spawnt als eigener Stack, nicht automatisch auf andere Mitarbeiter.
- [ ] Onboarding-Karte wird sofort an den neuen Mitarbeiter angeheftet.
- [ ] Bezahlphase-Regel erweitern: Geld + Angebot ist erlaubt, zusaetzlich zu Geld + Mitarbeiter.
- [ ] Neueinstellungen in der Bezahlphase erst ab naechstem Sprint gehaltsrelevant machen, z. B. ueber `salary_due_from_sprint`.
- [ ] Tests fuer Einstellung in Sprintphase, Einstellung in Bezahlphase, Geldverbrauch, Attachment und Gehaltsfaelligkeit schreiben.

Marco:

- [ ] Im Editor pruefen, ob Angebot + Geld als Interaktion verstaendlich ist.
- [ ] Tooltip/Marker pruefen: Neuer Mitarbeiter mit Onboarding darf nicht produktiv wirken.
- [ ] Bezahlphase visuell pruefen: Angebot bezahlen darf nicht wie Gehalt zahlen aussehen.

Definition of Done:

- [ ] Angebot ist noch kein Mitarbeiter.
- [ ] Einstellung kostet 1 Geldkarte.
- [ ] Neuer Mitarbeiter entsteht mit Onboarding-Attachment.
- [ ] Bezahlphase erlaubt Angebot-Bezahlung ohne Doppelgehaltsfalle.

Headless-Test:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/marcopreuss/Documents/ProjectsLocal/scope-creep-godot --script res://tests/test_poc4_phase_4_offers.gd
```

## Phase 5 - Onboarding als Attachment-Blocker

Ziel: Neue Mitarbeiter kosten schon Management-Aufwand und Geld, helfen aber erst nach abgeschlossenem Onboarding.

Codex:

- [ ] Onboarding als Attachment-Blocker analog zu Burnout modellieren, aber mit eigener CardDefinition und eigenem Recipe.
- [ ] Mitarbeiter mit Onboarding fuer normale Arbeitsrecipes blockieren.
- [ ] Onboarding blockiert Bezahlung nicht.
- [ ] `Mitarbeiter + Onboarding -> 20s Onboarding... -> Onboarding entfernen` implementieren.
- [ ] Kaffee als ProcessingInteraction auf laufendes Onboarding erlauben, weil mindestens eine Mitarbeiterkarte im Stack arbeitet.
- [ ] Kuendigt ein Mitarbeiter mit Onboarding, verschwindet das Onboarding-Attachment mit ihm.
- [ ] Save/Load fuer Onboarding-Attachment und Timer-Fortschritt testen.

Marco:

- [ ] Im Editor pruefen, ob Onboarding als angeheftete Karte lesbar bleibt.
- [ ] Playtest: Onboarding muss sich wie bewusstes Delay anfuehlen, nicht wie Bug.
- [ ] Tooltip pruefen: "Blockiert Arbeit, Gehalt bleibt faellig" muss klar sein.

Definition of Done:

- [ ] Mitarbeiter mit Onboarding kann keine normale Arbeit starten.
- [ ] Onboarding kann abgeschlossen werden und entfernt nur die Onboarding-Karte.
- [ ] Kaffee beschleunigt Onboarding wie andere Mitarbeiterarbeit.
- [ ] Bezahlung und Kuendigung funktionieren mit Onboarding korrekt.

Headless-Test:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/marcopreuss/Documents/ProjectsLocal/scope-creep-godot --script res://tests/test_poc4_phase_5_onboarding.gd
```

## Phase 6 - Recruiter als Hiring-Spezialist

Ziel: Recruiter ist eine regulaere, bezahlpflichtige Rolle mit klarem strategischem Nutzen im Hiring-System.

Codex:

- [ ] `card.employee.recruiter` in Mitarbeiter-Queries und Bezahlphase als regulaeren Mitarbeiter behandeln.
- [ ] Recruiter-spezifische Interview-Recipes mit hoeherer Specificity und Balance-Werten aktivieren, falls in Phase 3 noch nur vorbereitet.
- [ ] Sicherstellen, dass Recruiter kein Entwickler-/PO-/Tester-Recipe faelschlich als beste Rolle ersetzt.
- [ ] Falls bestehende generische "jeder kann alles"-Fallbacks existieren, Recruiter-Dauern sehr langsam konfigurieren statt hardcodiert zu blockieren.
- [ ] Falls solche Fallbacks noch nicht existieren, Recruiter in PoC4 auf Hiring beschraenken und das als bewussten Stretch-Konflikt gegen die GDD-Zielregel dokumentieren.
- [ ] Tests fuer Gehalt, Auto-Pay, Game Over, Interview-Vorteil und Recipe-Priority schreiben.

Marco:

- [ ] Recruiter visuell als Mitarbeiter, aber klar als Hiring-Rolle kennzeichnen.
- [ ] Playtest: Pruefen, ob Recruiter attraktiv genug ist oder zu speziell wirkt.
- [ ] Feedback notieren, ob Recruiter-Onboarding-Begleitung schon in PoC4 noetig ist.

Definition of Done:

- [ ] Recruiter muss bezahlt werden wie andere regulaere Mitarbeiter.
- [ ] Recruiter ist bei Interviews schneller und erfolgreicher.
- [ ] Recruiter bricht keine bestehenden Feature-/Bug-/PO-/Tester-Recipes.
- [ ] Architektur-Spannung zur GDD-Fallbackregel ist nicht versteckt.

Headless-Test:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/marcopreuss/Documents/ProjectsLocal/scope-creep-godot --script res://tests/test_poc4_phase_6_recruiter.gd
```

## Phase 7 - Werkstudent als temporaere Hilfskraft

Ziel: Werkstudent ist eine langsame Notfallhilfe, kein voller Mitarbeiter und kein Ersatz fuer Externer Dev.

Codex:

- [ ] Temporaere Arbeitskarten generisch ueber Tags/Queries modellieren, nicht als Einmal-Sonderfall im UI.
- [ ] Werkstudent braucht kein Gehalt und zaehlt nicht als regulaerer Mitarbeiter fuer Auto-Pay.
- [ ] Werkstudent verschwindet nach genau einer erfolgreich abgeschlossenen Aufgabe.
- [ ] Werkstudent bekommt in PoC4 keinen Burnout.
- [ ] Werkstudent darf keine Bewerbungsgespraeche fuehren.
- [ ] Werkstudent darf kein Onboarding begleiten.
- [ ] Werkstudent darf keinen Launch vorbereiten und keine Business Goals bezahlen.
- [ ] Ausgewaehlte Arbeitsrecipes fuer Werkstudent aktivieren: Idee/User Story/Kundenwunsch zu Funktion oder Story, Bugfix, Erwartungen managen.
- [ ] Dauer als +100% gegenueber passender Hauptrolle modellieren, moeglichst ueber Duration/Modifier statt kopierter Recipe-Logik.
- [ ] Kaffee auf laufende Werkstudentenarbeit erlauben.
- [ ] Tests fuer Lifecycle, Gehaltsfreiheit, erlaubte/verbotene Recipes, Kaffee und Save/Load schreiben.

Marco:

- [ ] Werkstudent visuell von regulaeren Mitarbeitern unterscheiden.
- [ ] Tooltip pruefen: "Kein Gehalt, verschwindet nach 1 Aufgabe" muss sofort klar sein.
- [ ] Playtest: Bewerten, ob +100% Dauer als Notfallhilfe funktioniert.

Definition of Done:

- [ ] Werkstudent gibt temporaere Arbeitskapazitaet.
- [ ] Werkstudent erzeugt keinen Gehaltsdruck.
- [ ] Werkstudent verschwindet nach Aufgabe deterministisch.
- [ ] Werkstudent hebelt Hiring, Launch, Business Goals und Onboarding nicht aus.

Headless-Test:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/marcopreuss/Documents/ProjectsLocal/scope-creep-godot --script res://tests/test_poc4_phase_7_work_student.gd
```

## Phase 8 - PoC3-Loop, Bezahlphase und Save/Load integrieren

Ziel: Hiring fuegt sich in MVP, Launch, Kunden, Business Goals, Gehaelter und Save/Load ein, statt daneben zu stehen.

Codex:

- [ ] Startsetup fuer PoC4 pruefen: Software MVP 0/10, Entwickler, Idee, Kaffee, 4 Geld, 1 Freelance-Auftrag, Gruenderpanik, Office-Invest, Talent-Pool und Patch-Shop.
- [ ] Falls PoC3 aktuell andere Startgeldwerte nutzt, PoC4-Startsetup bewusst dokumentieren statt still zu aendern.
- [ ] Auto-Pay und manuelles Pay nur auf regulaere gehaltsfaellige Mitarbeiter anwenden.
- [ ] Neueinstellungen waehrend der Bezahlphase mit `salary_due_from_sprint` oder aequivalenter Regel absichern.
- [ ] Game Over bei 0 regulaeren Mitarbeitern unveraendert lassen; Werkstudent zaehlt nicht als Rettung.
- [ ] Content-Version auf `poc4` umstellen und Save/Load-Migration fuer neue Runtime-Felder vorbereiten.
- [ ] Tests fuer Bezahlphase, Sprintstart-Kuendigungen, Game Over, Save/Load und RNG nach Laden schreiben.

Marco:

- [ ] PoC4-Startsetup im Editor spielen und Optionsdichte bewerten.
- [ ] Pruefen, ob Hiring vor Launch als riskante, aber erlaubte Entscheidung verstaendlich ist.
- [ ] Nach Launch testen, ob Hiring gegen Kundenwunsch-/Bug-/Business-Goal-Druck hilft.

Definition of Done:

- [ ] PoC3-Kernloop bleibt spielbar.
- [ ] Hiring konkurriert mit Gehaeltern und Business Goals um Geld.
- [ ] Werkstudent verhindert kein Game Over durch 0 regulaere Mitarbeiter.
- [ ] Save/Load erhaelt Bewerber, Angebote, Onboarding, Recruiter, Werkstudent und RNG-State.

Headless-Test:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/marcopreuss/Documents/ProjectsLocal/scope-creep-godot --script res://tests/test_poc4_phase_8_integration_save.gd
```

## Phase 9 - Presentation, Playtest-Balancing und QA

Ziel: PoC4 ist nicht nur technisch korrekt, sondern im Playtest lesbar und entscheidungsstark.

Codex:

- [ ] CardView-Marker fuer Bewerber, Angebote, Onboarding, Recruiter und Werkstudent pruefen oder minimal erweitern.
- [ ] Runtime-Labels fuer Onboarding und Werkstudent-Lifecycle anzeigen, falls bestehende Marker dafuer nicht reichen.
- [ ] Action-Texte vereinheitlichen: `Bewerbungsgespraech...`, `Onboarding...`, `Onboarding begleiten...`.
- [ ] Playtest-Script fuer PoC4 schreiben: vor Launch hiring testen, nach Launch hiring testen, Recruiter-Pfad testen, Werkstudent-Pfad testen.
- [ ] Gesamt-Headless-Check fuer PoC1-PoC4 relevante Tests ausfuehren.
- [ ] Balancing-Notizen in diesem Plan oder separater `POC4_NOTES.md` dokumentieren.

Marco:

- [ ] Farben, Labels, Tooltips und ggf. Kartengroessen im Editor final fuer PoC4 abstimmen.
- [ ] Einen kurzen Playtest bis nach Launch spielen und die PoC4-Fragen beantworten.
- [ ] Entscheiden, ob Talent-Pool-Kosten, Interview-Chancen oder Onboarding-Dauer angepasst werden.

Definition of Done:

- [ ] Hiring-Pipeline ist ohne Erklaertext im Spiel grob verstaendlich.
- [ ] Recruiter und Werkstudent haben klar unterscheidbare Rollen.
- [ ] Kein neuer PoC4-State lebt nur in Presentation.
- [ ] Tests/Validation laufen oder bekannte Blocker sind dokumentiert.

Headless-Check:

```bash
tools/check_poc.sh
```

## Stretch - Recruiter-Onboarding-Begleitung und Rollen-Fallbacks schaerfen

Diese Aufgaben sind sinnvoll, aber nicht zwingend fuer den ersten PoC4-Playtest.

Codex:

- [ ] `Recruiter + Mitarbeiter mit Onboarding -> 10s Onboarding begleiten -> Onboarding entfernen` implementieren.
- [ ] Pruefen, ob eine generische Rollen-Fallback-Tabelle fuer "jeder kann alles, aber langsam" jetzt notwendig ist.
- [ ] Recruiter-Fallbacks fuer normale Arbeit extrem langsam, aber datengetrieben modellieren.
- [ ] Werkstudent-Recipe-Abdeckung erweitern, falls Playtest zeigt, dass er zu selten nutzbar ist.
- [ ] Talent-Pool-Gewichte anpassen, falls Bewerber- oder Werkstudentenrate nicht passt.

Marco:

- [ ] Playtest: Recruiter mit und ohne Onboarding-Begleitung vergleichen.
- [ ] Entscheiden, ob Rollen-Fallbacks fuer PoC4 noch noetig sind oder in PoC5 gehoeren.

Definition of Done:

- [ ] Stretch-Regeln verbessern Spieltiefe, ohne PoC4-Kernloop zu verwischen.
- [ ] Neue Fallbacks sind datengetrieben und headless testbar.

## PoC4-Playtest-Fragen

- Versteht der Spieler Talent-Pool -> Bewerber -> Angebot -> Mitarbeiter?
- Fuehlt sich ein erfolgreicher Hire verdient an?
- Ist ein gescheitertes Interview fair oder zu frustrierend?
- Ist 40% normales Interview zu niedrig?
- Ist 70% Recruiter-Interview attraktiv genug?
- Wird ein groesseres Team spuerbar staerker?
- Entsteht sinnvoller Gehaltsdruck?
- Fuehlt sich Onboarding wie interessante Verzoegerung an?
- Ist Hiring vor Launch riskant, aber nicht verboten?
- Ist Recruiter zu speziell oder strategisch wertvoll?
- Ist Werkstudent als langsame Notfallhilfe nuetzlich?
- Konkurrieren Talent-Pool, Angebote, Gehaelter und Business Goals sinnvoll um Geld?
- Bricht Hiring den PoC3-Run oder macht es ihn strategischer?

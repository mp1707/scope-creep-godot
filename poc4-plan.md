# Scope Creep - PoC4-Plan

Dieses Dokument ist der Arbeitsplan fuer den vierten aussagekraeftigen Playtest-Slice in Godot 4.6. Es baut auf `poc4-idee.md`, `poc3-plan.md`, `architecture.md` und `gdd.md` v1.4 auf.

PoC4 ist kein Rewrite. Der bestehende PoC3 bleibt die technische Basis. Ziel ist, Teamwachstum als bewusst langsame, unsichere und kostenpflichtige Pipeline spielbar zu machen:

```text
Talent-Pool -> Bewerber -> Bewerbungsgespraech -> Angebot -> Einstellung -> Onboarding -> produktiver Mitarbeiter
```

Der Plan ist in groessere, abhakbare Phasen geschnitten. Jede Phase soll in einer Codex-Context-Session sinnvoll umsetzbar, mit schlanker Validation oder einem essenziellen Headless-Check absicherbar und danach im Editor kurz pruefbar sein. Editor-Arbeit ist dort markiert, wo visuelle Abstimmung, Scene-/Inspector-Pflege oder Playtest-Feedback sauberer ist als Textdatei-Automation.

## Fortschritt

- [x] Phase 0 - Baseline sichern und PoC4-Scope einfrieren
- [x] Phase 1 - Hiring-Content, Balance-Werte und Validation vorbereiten
- [x] Phase 2 - Talent-Pool neu konfigurieren
- [x] Phase 3 - Bewerbungsgespraeche und Angebots-Output
- [x] Phase 4 - Angebote bezahlen und Mitarbeiter mit Onboarding erzeugen
- [x] Phase 5 - Onboarding als Attachment-Blocker
- [x] Phase 6 - Recruiter als Hiring-Spezialist
- [x] Phase 7 - Werkstudent als temporaere Hilfskraft
- [x] Phase 8 - PoC3-Loop, Bezahlphase und Save/Load integrieren
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

## Teststrategie fuer PoC4

PoC4 ist weiterhin fruehe Architektur- und Gameplay-Findung. Tests sollen das Bauen nicht ausbremsen und keine alten Implementierungsdetails festnageln.

Aktiver Standard-Check bleibt:

```bash
tools/check_poc.sh
```

Dieser Check soll schlank bleiben:

- Content-Validation fuer neue Resources und Referenzen.
- `tests/test_essential_core_rules.gd` fuer wenige GDD-/Architekturregeln, die waehrend PoC4/5 nicht still brechen duerfen.
- Keine neuen breiten `test_poc4_phase_X.gd`-Suiten als Standard.
- Keine Presentation-, Layout-, Marker-, Spawnpositions- oder Textdetailtests, ausser ein UI-Verhalten entscheidet direkt eine Gameplay-Regel.

Neue Tests werden nur ergaenzt, wenn mindestens eines gilt:

- Die Regel ist eine harte GDD-Regel oder Architekturgrenze.
- Ein Fehler waere im Editor-Playtest schwer zu erkennen.
- Die Logik ist deterministisch und zentral, z. B. Save/Load, RNG, Content-Referenzen, Payment-/Sprintstart-Regeln.

Wenn eine Phase nur neuen Content oder Balancing liefert, reicht normalerweise Content-Validation plus Editor-Playtest. Wenn eine Phase eine neue Kernregel einfuehrt, wird maximal ein kleiner Testfall in `tests/test_essential_core_rules.gd` ergaenzt.

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

- [x] `git status --short` pruefen und lokale User-Aenderungen nicht ueberschreiben.
- [x] `poc4-idee.md`, `poc3-plan.md`, `architecture.md` und `gdd.md` vor Implementierung erneut querpruefen.
- [x] Schlanken Baseline-Check `tools/check_poc.sh` ausfuehren und bekannte Altlasten notieren.
- [x] Bestehende IDs fuer Talent-Pool, Booster-Slots, Employee-Tags, Burnout, Kaffee, Bezahlphase und Save/Load erfassen.
- [x] Sicherstellen, dass `architecture.md` die neuen Systemgrenzen fuer Hiring Lifecycle, Onboarding und temporaere Arbeitskarten beschreibt.
- [x] PoC4-Content-Version und moegliche Save-Migration festlegen, bevor neue IDs produktiv genutzt werden.

Marco:

- [x] Aktuellen PoC3 im Editor starten und bestaetigen, dass der letzte Playtest-Stand weiterhin spielbar ist.
- [x] Entscheiden, ob PoC4 auf einem neuen Branch umgesetzt wird.
- [x] Scope bestaetigen: Talent-Pool wird wieder aktiviert, aber ohne sofort produktive regulaere Mitarbeiter.

Definition of Done:

- [x] PoC3-Baseline ist bekannt und testbar.
- [x] PoC4-Scope ist schriftlich eingefroren.
- [x] Architekturwidersprueche sind dokumentiert oder aufgeloest.
- [x] Keine ID-Umbenennungen ohne Migration/Alias-Regel.

Status: ausgefuehrt. Marco hat Playtest, Main-Branch und Scope bestaetigt. `tools/check_poc.sh` besteht. `poc4-idee.md` ist im Repo nicht vorhanden; `poc4-plan.md` ist deshalb die aktuelle PoC4-Scope-Quelle. Content-Version wurde auf `poc4` gesetzt; alte `poc3`-Saves werden ohne Migration bewusst nicht geladen.

Headless-Check:

```bash
tools/check_poc.sh
```

## Phase 1 - Hiring-Content, Balance-Werte und Validation vorbereiten

Ziel: Alle neuen PoC4-Karten und Balance-Werte existieren datengetrieben, bevor Gameplay-Logik darauf aufsetzt.

Codex:

- [x] CardDefinitions fuer 4 Bewerberkarten anlegen.
- [x] CardDefinitions fuer 4 Angebotskarten anlegen.
- [x] CardDefinition fuer `card.employee.recruiter` anlegen.
- [x] CardDefinition fuer `card.temp_worker.work_student` anlegen.
- [x] CardDefinition fuer `card.blocker.onboarding` anlegen.
- [x] Tags so setzen, dass RuleQueries regulaere Mitarbeiter, temporaere Arbeitskarten, Bewerber, Angebote und Onboarding unterscheiden koennen.
- [x] BalanceDefinition um Interview-Dauern, Interview-Chancen, Einstellungskosten, Onboarding-Dauer und Werkstudent-Dauer-Multiplier erweitern.
- [x] Content-Validator erweitern: Bewerber muessen Ziel-Angebot referenzieren; Angebote muessen Ziel-Mitarbeiter referenzieren; Onboarding muss Attachment-faehig sein.
- [x] Content-Validation fuer neue Resources erweitern; keinen separaten Phasen-Test anlegen, solange keine neue Kernregel entsteht.

Marco:

- [x] Neue Resources im Godot Editor oeffnen und pruefen, ob Felder sinnvoll editierbar sind.
- [x] Farben, Typmarker und Kurztexte grob abstimmen: Bewerber, Angebot, Mitarbeiter, Blocker und Temp-Worker muessen unterscheidbar sein.
- [x] Tooltips sprachlich pruefen, besonders "Angebot ist noch kein Mitarbeiter" und "Onboarding blockiert Arbeit".

Definition of Done:

- [x] Alle PoC4-Karten existieren als Resource.
- [x] Balance-Werte liegen nicht hardcodiert in Gameplay-Scripts.
- [x] Content-Validation meldet fehlende Hiring-Verknuepfungen.
- [x] Keine neue Karte ist nur implizit per String im Script bekannt.

Status: umgesetzt und im Editor/Playtest bestaetigt. Neue Hiring-Karten, PoC4-Balancewerte, Tags und Validator-Regeln sind angelegt. Kein separater Phasen-Test, weil Phase 1 nur Content/Validation vorbereitet.

Headless-Check:

```bash
tools/check_poc.sh
```

## Phase 2 - Talent-Pool neu konfigurieren

Ziel: Talent-Pool ist wieder aktiv, liefert aber keine sofort produktiven regulaeren Mitarbeiter mehr.

Codex:

- [x] `booster.talent_pool` auf Kosten `2 Geld` setzen.
- [x] Talent-Pool-Ziehung auf 3 Karten pruefen oder setzen.
- [x] Talent-Pool-Pool auf Werkstudent und die 4 Bewerberkarten umstellen.
- [x] Direkte Entwickler-, Product-Owner-, Tester-, Recruiter- und Externer-Dev-Karten aus dem Talent-Pool entfernen.
- [x] PoC4-Startsetup um sichtbaren Talent-Pool-Slot erweitern.
- [x] Falls das vorhandene Startsetup zu voll wird, Sichtbarkeit ab Sprint 2 als konfigurierbare Alternative vorbereiten, aber initial direkt sichtbar lassen.
- [x] Content-Validation fuer Booster-Kosten und Pool-Inhalt erweitern; deterministische Ziehung bleibt ueber den essenziellen Kernregel-Test abgesichert.

Marco:

- [x] Im Editor/Playtest pruefen, ob der Talent-Pool-Slot am Start sichtbar und nicht visuell ueberladen ist.
- [x] Bewerten, ob Talent-Pool direkt ab Sprint 1 zu viele Entscheidungen erzeugt.
- [x] Booster-Tooltip pruefen: Er muss klar sagen, dass Bewerber erst interviewt werden muessen.

Definition of Done:

- [x] Talent-Pool erzeugt keine produktiven regulaeren Mitarbeiter direkt.
- [x] Talent-Pool kostet 2 einzelne Geldkarten.
- [x] Booster-Ziehung bleibt RNG-deterministisch.
- [x] Externer Dev bleibt aus normalem PoC4-Hiring heraus.

Status: umgesetzt und im Playtest bestaetigt. Talent-Pool kostet als Slot-Interaktion 2 einzelne Geldkarten, erzeugt ein Talent-Pool-Pack und zieht nur Bewerber oder Werkstudenten. Validator und essenzieller Kernregel-Test sichern Kosten, Pool-Inhalt und deterministische Booster-Ziehung ab.

Headless-Check:

```bash
tools/check_poc.sh
```

## Phase 3 - Bewerbungsgespraeche und Angebots-Output

Ziel: Bewerber koennen ueber normale Mitarbeiter oder Recruiter interviewt werden und erzeugen deterministisch testbare Erfolg-/Misserfolgsergebnisse.

Codex:

- [x] Generische Query implementieren oder erweitern: `is_regular_employee(card)` fuer bezahlpflichtige Mitarbeiter.
- [x] Interview-Recipes fuer `Bewerber + regulaerer Mitarbeiter` anlegen: 20s, 40% Erfolg.
- [x] Recruiter-spezifische Interview-Recipes vorbereiten oder mit hoeherer Specificity definieren: 10s, 70% Erfolg.
- [x] Erfolg erzeugt passendes Angebot; Misserfolg entfernt Bewerber ohne weitere Negativkarte.
- [x] Interviewer-Rolle ausser Recruiter fuer PoC4 egal halten.
- [x] Active Processing bei Stack-Aenderung unveraendert sofort abbrechen lassen.
- [x] Nur einen essenziellen Kernregel-Test ergaenzen, falls Interview-RNG oder Recipe-Priority ohne Test leicht unbemerkt brechen kann; neutrale Zusatzkarten bleiben bereits im Kernregel-Test abgesichert.

Marco:

- [x] Aktionstext pruefen: `Bewerbungsgespraech...`.
- [x] Im Playtest bewerten, ob Interviewdauer und Misserfolg visuell fair wirken.
- [x] Pruefen, ob Bewerberkarten nicht wie fertige Mitarbeiter missverstanden werden.

Definition of Done:

- [x] Jeder Bewerber kann mit einem regulaeren Mitarbeiter interviewt werden.
- [x] Recruiter-Interview gewinnt gegen normales Interview.
- [x] Erfolg/Misserfolg ist deterministisch modelliert und bei Bedarf mit einem kleinen Kernregel-Test pruefbar.
- [x] Kein Interview-Ergebnis wird in Presentation-Code entschieden.

Headless-Check:

```bash
tools/check_poc.sh
```

Status: abgeschlossen. Normale Interviews und Recruiter-Interviews laufen als Recipes, Erfolg spawnt datengetrieben das Ziel-Angebot aus dem Bewerber, Misserfolg verbraucht nur den Bewerber. Recruiter gewinnt ueber hoehere Specificity. Kernregel-Test deckt deterministischen Erfolg und Recipe-Priority ab. Marco hat Editor-/Playtest-Pruefung bestaetigt.

## Phase 4 - Angebote bezahlen und Mitarbeiter mit Onboarding erzeugen

Ziel: Angebote sind sichtbare Zwischenkarten. Erst Geld auf Angebot erzeugt einen neuen Mitarbeiter, der noch nicht produktiv ist.

Codex:

- [x] Angebots-zu-Mitarbeiter-Mapping datengetrieben modellieren, z. B. in Offer-Card-Defaultwerten oder Effect-Parametern.
- [x] Recipe oder Command fuer `Angebot + Geld -> Mitarbeiter + Onboarding` implementieren.
- [x] Geldkarte immer verbrauchen; Angebot immer verbrauchen.
- [x] Neuer Mitarbeiter spawnt als eigener Stack, nicht automatisch auf andere Mitarbeiter.
- [x] Onboarding-Karte wird sofort an den neuen Mitarbeiter angeheftet.
- [x] Bezahlphase-Regel erweitern: Geld + Angebot ist erlaubt, zusaetzlich zu Geld + Mitarbeiter.
- [x] Neueinstellungen in der Bezahlphase erst ab naechstem Sprint gehaltsrelevant machen, z. B. ueber `salary_due_from_sprint`.
- [x] Nur die riskanteste Einstellungsregel headless absichern, z. B. Bezahlphase-Gehaltsfaelligkeit; Geldverbrauch und Attachment zunaechst ueber Playtest/Validation pruefen, wenn sie direkt sichtbar sind.

Marco:

- [x] Im Editor pruefen, ob Angebot + Geld als Interaktion verstaendlich ist.
- [x] Tooltip/Marker pruefen: Neuer Mitarbeiter mit Onboarding darf nicht produktiv wirken.
- [x] Bezahlphase visuell pruefen: Angebot bezahlen darf nicht wie Gehalt zahlen aussehen.

Definition of Done:

- [x] Angebot ist noch kein Mitarbeiter.
- [x] Einstellung kostet 1 Geldkarte.
- [x] Neuer Mitarbeiter entsteht mit Onboarding-Attachment.
- [x] Bezahlphase erlaubt Angebot-Bezahlung ohne Doppelgehaltsfalle.

Headless-Check:

```bash
tools/check_poc.sh
```

Status: abgeschlossen. Geld auf Angebot erzeugt den Ziel-Mitarbeiter aus dem Offer-Mapping, verbraucht Geld und Angebot und haengt Onboarding an. Neueinstellungen in der Bezahlphase erhalten `salary_due_from_sprint = aktueller Sprint + 1` und werden nicht sofort als Gehaltsziel markiert. Marco hat Editor-/Playtest-Pruefung bestaetigt.

## Phase 5 - Onboarding als Attachment-Blocker

Ziel: Neue Mitarbeiter kosten schon Management-Aufwand und Geld, helfen aber erst nach abgeschlossenem Onboarding.

Codex:

- [x] Onboarding als Attachment-Blocker analog zu Burnout modellieren, aber mit eigener CardDefinition und eigenem Recipe.
- [x] Mitarbeiter mit Onboarding fuer normale Arbeitsrecipes blockieren.
- [x] Onboarding blockiert Bezahlung nicht.
- [x] `Mitarbeiter + Onboarding -> 20s Onboarding... -> Onboarding entfernen` implementieren.
- [x] Kaffee als ProcessingInteraction auf laufendes Onboarding erlauben, weil mindestens eine Mitarbeiterkarte im Stack arbeitet.
- [x] Kuendigt ein Mitarbeiter mit Onboarding, verschwindet das Onboarding-Attachment mit ihm.
- [x] Save/Load fuer Onboarding-Attachment und Timer-Fortschritt nur dann als essenziellen Kernregel-Test ergaenzen, wenn neue Runtime-Felder eingefuehrt werden.

Marco:

- [x] Im Editor pruefen, ob Onboarding als angeheftete Karte lesbar bleibt.
- [x] Playtest: Onboarding muss sich wie bewusstes Delay anfuehlen, nicht wie Bug.
- [x] Tooltip pruefen: "Blockiert Arbeit, Gehalt bleibt faellig" muss klar sein.

Definition of Done:

- [x] Mitarbeiter mit Onboarding kann keine normale Arbeit starten.
- [x] Onboarding kann abgeschlossen werden und entfernt nur die Onboarding-Karte.
- [x] Kaffee beschleunigt Onboarding wie andere Mitarbeiterarbeit.
- [x] Bezahlung und Kuendigung funktionieren mit Onboarding korrekt.

Headless-Check:

```bash
tools/check_poc.sh
```

Status: abgeschlossen. Onboarding ist ein `employee_blocker`-Attachment, blockiert normale Employee-Recipes, bleibt bezahlbar und wird durch das Onboarding-Recipe entfernt. Kaffee beschleunigt laufendes Onboarding. Attachment-Entfernung bei Kuendigung nutzt die bestehende rekursive Card-Entfernung. Marco hat Editor-/Playtest-Pruefung bestaetigt.

## Phase 6 - Recruiter als Hiring-Spezialist

Ziel: Recruiter ist eine regulaere, bezahlpflichtige Rolle mit klarem strategischem Nutzen im Hiring-System.

Codex:

- [x] `card.employee.recruiter` in Mitarbeiter-Queries und Bezahlphase als regulaeren Mitarbeiter behandeln.
- [x] Recruiter-spezifische Interview-Recipes mit hoeherer Specificity und Balance-Werten aktivieren, falls in Phase 3 noch nur vorbereitet.
- [x] Sicherstellen, dass Recruiter kein Entwickler-/PO-/Tester-Recipe faelschlich als beste Rolle ersetzt.
- [x] Falls bestehende generische "jeder kann alles"-Fallbacks existieren, Recruiter-Dauern sehr langsam konfigurieren statt hardcodiert zu blockieren.
- [x] Falls solche Fallbacks noch nicht existieren, Recruiter in PoC4 auf Hiring beschraenken und das als bewussten Stretch-Konflikt gegen die GDD-Zielregel dokumentieren.
- [x] Nur Recipe-Priority oder Gehaltsklassifizierung headless absichern, falls die bestehende Kernregel-Suite diese Grenze nicht schon abdeckt; keine Auto-Pay/Game-Over-Detailmatrix fuer PoC4.

Marco:

- [x] Recruiter visuell als Mitarbeiter, aber klar als Hiring-Rolle kennzeichnen.
- [x] Playtest: Pruefen, ob Recruiter attraktiv genug ist oder zu speziell wirkt.
- [x] Feedback notieren, ob Recruiter-Onboarding-Begleitung schon in PoC4 noetig ist.

Definition of Done:

- [x] Recruiter muss bezahlt werden wie andere regulaere Mitarbeiter.
- [x] Recruiter ist bei Interviews schneller und erfolgreicher.
- [x] Recruiter bricht keine bestehenden Feature-/Bug-/PO-/Tester-Recipes.
- [x] Architektur-Spannung zur GDD-Fallbackregel ist nicht versteckt.

Status: abgeschlossen und per `tools/check_poc.sh` geprueft. Es gibt aktuell keine generischen Rollen-Fallbacks fuer normale Arbeit; Recruiter bleibt deshalb fuer PoC4 bewusst auf Hiring beschraenkt. Recruiter-Onboarding-Hilfe ist als reversible aktive Stack-Hilfe umgesetzt: solange der Recruiter im laufenden Onboarding-Stack liegt, laeuft Onboarding doppelt so schnell.

Headless-Check:

```bash
tools/check_poc.sh
```

## Phase 7 - Werkstudent als temporaere Hilfskraft

Ziel: Werkstudent ist eine langsame Notfallhilfe, kein voller Mitarbeiter und kein Ersatz fuer Externer Dev.

Codex:

- [x] Temporaere Arbeitskarten generisch ueber Tags/Queries modellieren, nicht als Einmal-Sonderfall im UI.
- [x] Werkstudent braucht kein Gehalt und zaehlt nicht als regulaerer Mitarbeiter fuer Auto-Pay.
- [x] Werkstudent verschwindet nach genau einer erfolgreich abgeschlossenen Aufgabe.
- [x] Werkstudent bekommt in PoC4 keinen Burnout.
- [x] Werkstudent darf keine Bewerbungsgespraeche fuehren.
- [x] Werkstudent darf kein Onboarding begleiten.
- [x] Werkstudent darf keinen Launch vorbereiten und keine Business Goals bezahlen.
- [x] Ausgewaehlte Arbeitsrecipes fuer Werkstudent aktivieren: Idee/User Story/Kundenwunsch zu Funktion oder Story, Bugfix, Erwartungen managen.
- [x] Dauer als +100% gegenueber passender Hauptrolle modellieren, moeglichst ueber Duration/Modifier statt kopierter Recipe-Logik.
- [x] Kaffee auf laufende Werkstudentenarbeit erlauben.
- [x] Maximal einen essenziellen Kernregel-Test fuer Werkstudent-Lifecycle oder Gehaltsfreiheit ergaenzen; erlaubte/verbotene Recipes primaer ueber Content-Validation und Playtest pruefen.

Marco:

- [x] Werkstudent visuell von regulaeren Mitarbeitern unterscheiden.
- [x] Tooltip pruefen: "Kein Gehalt, verschwindet nach 1 Aufgabe" muss sofort klar sein.
- [x] Playtest: Bewerten, ob +100% Dauer als Notfallhilfe funktioniert.

Definition of Done:

- [x] Werkstudent gibt temporaere Arbeitskapazitaet.
- [x] Werkstudent erzeugt keinen Gehaltsdruck.
- [x] Werkstudent verschwindet nach Aufgabe deterministisch.
- [x] Werkstudent hebelt Hiring, Launch, Business Goals und Onboarding nicht aus.

Status: abgeschlossen und per `tools/check_poc.sh` geprueft. Werkstudenten nutzen eigene datengetriebene Arbeitsrecipes mit `temp_worker_duration`-Modifier, zaehlen nicht als regulaere Mitarbeiter und werden nach ihrer erfolgreichen Aufgabe generisch ueber `one_task_lifetime` entfernt.

Headless-Check:

```bash
tools/check_poc.sh
```

## Phase 8 - PoC3-Loop, Bezahlphase und Save/Load integrieren

Ziel: Hiring fuegt sich in MVP, Launch, Kunden, Business Goals, Gehaelter und Save/Load ein, statt daneben zu stehen.

Codex:

- [x] Startsetup fuer PoC4 pruefen: Software MVP 0/10, Entwickler, Idee, Kaffee, 4 Geld, 1 Freelance-Auftrag, Gruenderpanik, Office-Invest, Talent-Pool und Patch-Shop.
- [x] Falls PoC3 aktuell andere Startgeldwerte nutzt, PoC4-Startsetup bewusst dokumentieren statt still zu aendern.
- [x] Auto-Pay und manuelles Pay nur auf regulaere gehaltsfaellige Mitarbeiter anwenden.
- [x] Neueinstellungen waehrend der Bezahlphase mit `salary_due_from_sprint` oder aequivalenter Regel absichern.
- [x] Game Over bei 0 regulaeren Mitarbeitern unveraendert lassen; Werkstudent zaehlt nicht als Rettung.
- [x] Content-Version auf `poc4` umstellen und Save/Load-Migration fuer neue Runtime-Felder vorbereiten.
- [x] Nur neue Save/Load-Felder und RNG-Kontinuitaet headless absichern, wenn PoC4 neue Runtime-Felder einfuehrt; bestehende Bezahl-/Sprintregeln nicht erneut breit testen.

Marco:

- [x] PoC4-Startsetup im Editor spielen und Optionsdichte bewerten.
- [x] Pruefen, ob Hiring vor Launch als riskante, aber erlaubte Entscheidung verstaendlich ist.
- [x] Nach Launch testen, ob Hiring gegen Kundenwunsch-/Bug-/Business-Goal-Druck hilft.

Definition of Done:

- [x] PoC3-Kernloop bleibt spielbar.
- [x] Hiring konkurriert mit Gehaeltern und Business Goals um Geld.
- [x] Werkstudent verhindert kein Game Over durch 0 regulaere Mitarbeiter.
- [x] Save/Load erhaelt Bewerber, Angebote, Onboarding, Recruiter, Werkstudent und RNG-State.

Status: abgeschlossen und per `tools/check_poc.sh` geprueft. Das bestehende Startsetup bleibt bewusst bei den aktuellen Balance-Werten aus `data/balance/poc_default.tres`; PoC4 aendert das nicht still. Save/Load sichert PoC4-Content-Version, Hiring-Karten, Attachments und RNG-State.

Headless-Check:

```bash
tools/check_poc.sh
```

## Phase 9 - Presentation, Playtest-Balancing und QA

Ziel: PoC4 ist nicht nur technisch korrekt, sondern im Playtest lesbar und entscheidungsstark.

Codex:

- [ ] CardView-Marker fuer Bewerber, Angebote, Onboarding, Recruiter und Werkstudent pruefen oder minimal erweitern.
- [ ] Runtime-Labels fuer Onboarding und Werkstudent-Lifecycle anzeigen, falls bestehende Marker dafuer nicht reichen.
- [ ] Action-Texte vereinheitlichen: `Bewerbungsgespraech...`, `Onboarding...`, `Onboarding begleiten...`.
- [ ] Playtest-Script fuer PoC4 schreiben: vor Launch hiring testen, nach Launch hiring testen, Recruiter-Pfad testen, Werkstudent-Pfad testen.
- [ ] Schlanken Gesamt-Headless-Check `tools/check_poc.sh` ausfuehren; keine alten PoC1-PoC3-Detailtests reaktivieren.
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

- [x] `Recruiter + Mitarbeiter mit Onboarding -> laufendes Onboarding doppelt so schnell, solange Recruiter im Stack liegt` implementieren.
- [ ] Pruefen, ob eine generische Rollen-Fallback-Tabelle fuer "jeder kann alles, aber langsam" jetzt notwendig ist.
- [ ] Recruiter-Fallbacks fuer normale Arbeit extrem langsam, aber datengetrieben modellieren.
- [ ] Werkstudent-Recipe-Abdeckung erweitern, falls Playtest zeigt, dass er zu selten nutzbar ist.
- [x] Talent-Pool-Gewichte anpassen, falls Bewerber- oder Werkstudentenrate nicht passt.

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

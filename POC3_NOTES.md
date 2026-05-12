# PoC3 Notes

Dieses Dokument haelt Baseline-Ergebnisse, Scope-Entscheidungen und technische Risiken fuer PoC3 fest.

## Phase 0 Baseline

- `git status --short`: sauber vor den PoC3-Dokumentationsaenderungen.
- Marco-Check: Spiel ist im Editor spielbar.
- Branch-Entscheidung: PoC3 wird auf `main` umgesetzt.
- Scope bestaetigt: Talent-Pool-Deaktivierung fuer PoC3 ist ok.
- `architecture.md` wurde vor der Implementierung um PoC3-relevante Zielarchitektur ergaenzt:
  - Product Lifecycle auf der Softwarekarte
  - Goal Cards
  - Run-End-Metadaten/terminale Zustaende
  - RuleQueryService-Queries fuer Produkt, Kunden und Goals
  - erweiterte Sprintstart-Pipeline fuer PoC3
- Content-Validation aus `tools/check_poc.sh`: bestanden.
- `tools/check_poc.sh`: scheitert aktuell in `tests/test_phase_3.gd`, weil der Test noch 12 einzelne Startstacks erwartet. Der aktuelle Stand auto-stackt Geldkarten und erzeugt dadurch weniger Startstacks. Das ist ein Test-/Baseline-Thema vor PoC3, kein PoC3-Architekturentscheid.
- PoC2-spezifische Tests:
  - `test_poc2_phase_2_pipeline.gd`: bestanden.
  - `test_poc2_phase_3_release_quality.gd`: scheitert bei `Parallel release spawns should not overlap`.
  - `test_poc2_phase_4_problem_economy.gd`: bestanden.
  - `test_poc2_phase_5_burnout.gd`: bestanden.
  - `test_poc2_phase_6_value_sources.gd`: bestanden.
  - `test_poc2_phase_7_boosters_shop.gd`: bestanden.
  - `test_poc2_phase_8_presentation.gd`: scheitert mehrfach bei `Spawn placement should avoid previous spawn positions`.
  - `test_poc2_phase_9_save_validation.gd`: bestanden.
- Sandbox-Hinweis: Godot crasht in der Codex-Sandbox beim Schreiben von `user://logs`. Headless-Tests wurden deshalb ausserhalb der Sandbox ausgefuehrt.

## Bestehende Content-IDs vor PoC3

Karten:

- `card.product.software`
- `card.output.feature`
- `card.output.checked_feature`
- `card.value_source.customer`
- `card.input.customer_request`
- `card.value_source.order`
- `card.shop.booster_slot`
- `card.shop.booster_slot.talent_pool`
- `card.shop.booster_slot.office_invest`
- `card.shop.booster_slot.customer_chaos`
- `card.shop.bugfix_patch_slot`

Recipes:

- `recipe.money_from_feature.software`
- `recipe.money_from_checked_feature.software`
- `recipe.money_from_order.feature`
- `recipe.promising_user_story_from_customer_request.product_owner`
- `recipe.checked_feature_from_feature.tester`

Booster/Shop:

- `booster.founder.test_pack`
- `booster.talent_pool`
- `booster.office_invest`
- `booster.customer_chaos`
- `booster.hot_fix_kit`
- `shop.poc.booster`

## PoC3 Scope-Entscheidungen

- PoC3 bekommt keinen Rewrite. Der bestehende PoC2-Code bleibt Basis.
- `card.value_source.order` bleibt fuer PoC2-Auftraege erhalten.
- PoC3 fuehrt `card.value_source.freelance_order` als eigene Karte ein, damit Freelance-Finanzierung nicht mit bestehenden Auftragsregeln vermischt wird.
- Pre-Launch/Post-Launch wird nicht als neue `RunPhase` modelliert. Produktstatus gehoert auf die Softwarekarte bzw. in Product-Lifecycle-Queries.
- Business Goals werden als sichtbare Karten modelliert, nicht als HUD-Zahl.
- Globale Unzufriedenheit ist fuer PoC3 akzeptiert. Kunden-Attachments bleiben ein spaeteres Architekturthema, falls der Playtest globale Unzufriedenheit unklar findet.
- Talent-Pool wird im normalen PoC3-Run deaktiviert oder entfernt, damit Hiring den MVP-/Launch-/Kundenloop nicht verfaelscht.

## Offene Risiken vor Phase 1

- Spawn-Placement hat bereits vor PoC3 Testfehler. PoC3 erzeugt mehr parallele Spawns; dieses Risiko sollte vor oder waehrend Phase 3-5 stabilisiert werden.
- Alte Basistests enthalten Annahmen, die nach Auto-Stacking nicht mehr stimmen. Vor einer finalen PoC3-QA sollten diese Tests aktualisiert oder bewusst ersetzt werden.

## Phase 1 Baseline

- Product Lifecycle wurde als eigener Simulation-Service vorbereitet.
- Software startet mit `product_stage = mvp`, `feature_count = 0`, `mvp_required_features = 10`, `launch_feature_count = 0`.
- `RunController.is_software_launch_ready()` kapselt die Launchbereitschaft.
- CardView zeigt Softwarestatus im Karten-Textbereich: `MVP`, `Launchbereit` oder `Live`.
- Marco-Check: Softwarekarte ist ohne Icon und mit zentriertem Runtime-Text lesbar.
- Content-Version bleibt bewusst noch `poc2`, bis die PoC3-Kernsysteme stabil sind.
- Headless-Test `tests/test_poc3_phase_1_software_status.gd`: bestanden.
- Content-Validation: bestanden.

## Phase 2 Feature-Integration

- Die bestehenden Software-Recipes behalten ihre stabilen IDs, sind fachlich aber PoC3-Integration:
  - `recipe.money_from_feature.software` zeigt `Feature integrieren`, erhoeht `feature_count` um 1, verbraucht die Funktion und behaelt Bug-Risiko.
  - `recipe.money_from_checked_feature.software` zeigt `Geprueftes Feature integrieren`, erhoeht `feature_count` um 1, verbraucht die gepruefte Funktion und hat kein Bug-Risiko.
- Software-Integration erzeugt kein Geld mehr. Der alte Recipe-ID-Name ist damit technisch unsauber, bleibt aber bis zu einer bewussten Save-/Content-Migration stabil.
- Generischer Effect `modify_card_value` wurde ergaenzt, damit Runtime-Werte per Effect-Pipeline veraendert werden koennen.
- Marco-Check: Software erzeugt sichtbar kein Geld mehr, Aktionstexte/Tooltips passen, Feature-Fortschritt bleibt bei gestapelter Software lesbar.
- Headless-Test `tests/test_poc3_phase_2_feature_integration.gd`: bestanden.
- Content-Validation: bestanden.

## Phase 3 Freelance-Finanzierung

- Neue Karte `card.value_source.freelance_order` trennt PoC3-Freelance fachlich von alten PoC2-Auftraegen.
- Startsetup enthaelt jetzt 30 Geld und 1 Freelance-Auftrag. Die 30 Geld sind eine bewusste Playtest-Hilfe, damit Launch und Kundenloop schneller erreichbar sind.
- Vor Launch ersetzt der Sprintstart einen verfallenen Freelance-Auftrag durch genau 1 neuen Auftrag.
- Nach Launch endet dieser automatische Freelance-Zufluss.
- Neue Recipes:
  - `recipe.money_from_freelance_order.feature`: Funktion + Freelance-Auftrag -> 2 Geld, beide Inputs werden verbraucht.
  - `recipe.money_from_freelance_order.checked_feature`: Gepruefte Funktion + Freelance-Auftrag -> 3 Geld, beide Inputs werden verbraucht.
- Freelance-Auftraege tragen weiterhin den `order`-Tag und verfallen dadurch am Sprintstart. Das verhindert Pre-Launch-Auftragsbacklogs.
- Marco-Check: Freelance-Auftrag ist visuell ausreichend unterscheidbar, Tooltip ohne `Vor Launch:` passt, Startgeld liegt als ein Geldstapel und die Startbalance passt fuer den naechsten Slice.
- Headless-Test `tests/test_poc3_phase_3_freelance.gd`: bestanden.
- Content-Validation: bestanden.

## Phase 4 Manueller Launch

- Neues Recipe `recipe.launch_software.developer`: launchbereite Software + Entwickler -> `Launch vorbereiten`.
- Launchbereitschaft wird ueber eine Simulation-Constraint `software_launch_ready` geprueft. Dadurch matcht 9/10 nicht, 10/10 und mehr matchen.
- Neuer Effect `launch_software` setzt `product_stage = live`, speichert `launch_feature_count` und spawnt `floor(feature_count / 5)` Kunden.
- Direkt nach Launch spawnt `card.goal.business_goal` als PoC3-Platzhalter. Die eigentliche Goal-Zahlung, Erfuellung und Paniklogik bleibt Phase 7.
- Launch wird durch vorhandene Bug-/Tech-Debt-Karten ausserhalb des Launch-Stacks nicht blockiert und verbraucht diese Probleme nicht.
- Headless-Test `tests/test_poc3_phase_4_launch.gd`: bestanden.
- Content-Validation: bestanden.

## Phase 5 Kundenwirtschaft

- Kunden-Ticks sind jetzt post-launch gated: Kunden erzeugen erst bei Live-Software am Sprintstart Karten.
- Jeder Kunde erzeugt ohne Prod-Crash 1 Geldkarte und 1 Kundenwunschkarte.
- Kundenwuensche bekommen beim Spawn `spawned_sprint_index`; Phase 6 nutzt diesen Wert fuer ignorierte Wuensche.
- Aktiver Prod-Crash blockiert den kompletten normalen Kundentick. Unhappy-Customer-Ersatz kommt in Phase 6, sobald `card.problem.unhappy_customer` existiert.
- Software-Integration erzeugt auch nach Launch weiterhin kein direktes Geld.
- Headless-Test `tests/test_poc3_phase_5_customer_income.gd`: bestanden.
- Content-Validation: bestanden.
- Marco-Check fuer Phase 4 und 5: Launch, Startkunden, Kundentick und Tooltip passen fuer den naechsten Slice.

## Phase 10 Balancing und QA

- PoC3-Balancewerte sind in `data/balance/poc_default.tres` gebuendelt:
  - `poc3_mvp_required_features = 10`
  - `poc3_start_money_cards = 30`
  - `poc3_freelance_feature_money_cards = 2`
  - `poc3_freelance_checked_feature_money_cards = 3`
  - `poc3_launch_features_per_start_customer = 5`
  - `poc3_customer_tick_money_cards = 1`
  - `poc3_customer_tick_request_cards = 1`
  - `poc3_business_goal_required_money = [3, 5, 7]`
  - `poc3_business_goal_win_count = 3`
  - `poc3_investor_panic_game_over_count = 2`
  - `poc3_developer_customer_request_duration_seconds = 9.0`
- `ContentCatalog.apply_balance_overrides()` wendet PoC3-Balance auf die betroffenen Recipe-Resources an. Das haelt die Recipe-Dateien stabil, aber macht die Playtest-Werte zentral aenderbar.
- `tests/test_poc3_phase_10_balance_qa.gd` prueft, dass PoC3-Balancewerte geladen und fuer Startsetup sowie balancierte Recipes verwendet werden.
- `tools/check_poc.sh` ist jetzt die aktuelle PoC3-Akzeptanzsuite: Content-Validation plus PoC3 Phase 1-10. Alte PoC-/PoC2-Tests bleiben im Repo, sind aber wegen PoC3-Regelaenderungen kein Gesamtcheck mehr.
- Headless-Status:
  - Content-Validation: bestanden.
  - PoC3 Phase 1-10 gemeinsam: bestanden.
  - `tools/check_poc.sh`: bestanden.
  - Sandbox-Hinweis: Save-Tests mit `user://` koennen in der Codex-Sandbox fehlschlagen; ausserhalb der Sandbox bestanden sie.

### PoC3-Playtest-Script

1. Starte einen neuen Run. Erwartet: Software zeigt `MVP 0/10`, 30 Geld liegen als Playtest-Hilfe bereit, 1 Freelance-Auftrag ist sichtbar, Talent-Pool ist nicht im Startsetup.
2. Baue Features aus Ideen. Entscheide pro Feature: auf Software integrieren fuer MVP-Fortschritt oder mit Freelance-Auftrag fuer Geld abliefern.
3. Spiele Variante A mit fruehem Launch: bei genau 10 Features Entwickler auf Software legen und `Launch vorbereiten` abschliessen.
4. Spiele Variante B mit spaetem Launch: bis 15+ Features weiterbauen und erst dann launchen. Erwartet: mehr Startkunden durch `floor(feature_count / 5)`.
5. Nach Launch: Starte den naechsten Sprint. Zufriedene Kunden sollen je 1 Geld und 1 Kundenwunsch erzeugen.
6. Bearbeite Kundenwuensche aktiv. Product Owner klaert sie normal, Entwickler improvisiert langsamer zu vielversprechenden User Stories.
7. Ignoriere in einem Test bewusst Kundenwuensche. Erwartet: am naechsten Sprintstart wird pro altem Wunsch ein zufriedener Kunde unzufrieden, solange zufriedene Kunden existieren.
8. Entferne Unzufriedenheit mit Product Owner + Kunde + angeheftetem `Unzufrieden`.
9. Bezahle Business Goals mit einzelnen Geldkarten. Erwartet: Goal 1 braucht 3 Geld, Goal 2 braucht 5 Geld, Goal 3 braucht 7 Geld.
10. Gewinne den Mini-Run durch 3 erfuellte Business Goals oder verliere bewusst durch 2 Investorenpanik-Karten bzw. 0 Mitarbeiter.

### Offene Balance- und Designfragen

- 30 Startgeld ist weiter ein Playtest-Hilfswert. Vor einem staerkeren Demo-Slice sollte der echte Startwert wieder reduziert und gegen Freelance-Druck getestet werden.
- 10 MVP-Features koennen sich je nach Feature-Erzeugungstempo zu lang oder zu kurz anfuehlen. Die konkrete Frage ist, ob der Launch als bewusster Wendepunkt wirkt oder nur als Pflichtklick.
- Goal-Werte 3/5/7 muessen gegen Gehaelter, Booster und Notfallkarten getestet werden. Wenn Goals zu leicht sind, sollte eher das Wachstum der Goal-Leiter angepasst werden als versteckter Druck eingebaut werden.
- Kunden erzeugen aktuell je 1 Geld und 1 Kundenwunsch. Das ist klar, kann aber bei vielen Kunden schnell Board-Druck erzeugen.
- Unzufriedenheit bleibt in PoC3 als Kunden-Attachment sichtbar. Falls mehrere Kunden mit Attachments unlesbar werden, ist das zuerst ein Presentation-/Layout-Thema, kein Grund fuer unsichtbare Meter.

### Technische Schuld nach Phase 10

- Die alten PoC-/PoC2-Tests enthalten mehrere fachlich ueberholte Erwartungen: Software-Release erzeugt Geld, Startsetup hat 3 Geld/12 Karten, `poc2`-Saves laden noch, Kunden ticken vor Launch. Diese Tests sollten vor PoC4 entweder migriert, geloescht oder als historische Tests getrennt werden.
- Einige stabile IDs tragen alte Fachnamen, besonders `recipe.money_from_feature.software` und `recipe.money_from_checked_feature.software`, obwohl sie jetzt Feature-Integration machen. Das ist bewusst fuer Save-/Content-Stabilitaet stehen geblieben.
- `ContentCatalog.apply_balance_overrides()` mutiert geladene Recipe-Resources beim Content-Load. Das ist fuer PoC3 akzeptabel, sollte langfristig durch echte Balance-Keys auf `DurationDefinition`/Effects oder einen Content-Build-Schritt ersetzt werden.

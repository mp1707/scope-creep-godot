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

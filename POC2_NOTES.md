# PoC2 Notes

Dieses Dokument haelt bewusste Abweichungen, Baseline-Ergebnisse und Content-IDs fuer PoC2 fest.

## Phase 0 Baseline

- `git status --short`: sauber vor PoC2-Start.
- Branch-Entscheidung: PoC2 wird aktuell auf `main` weitergefuehrt.
- Content-Validation: bestanden.
- Bestehende Headless-Tests:
  - Phase 3, 4, 5, 7, 8, 9, 10: bestanden.
  - Phase 6: Testannahme war veraltet, weil `BoardView` inzwischen einen Editor-/Audio-Child behalten darf. Der Test wurde auf konkrete `CardView`-Existenz pro Startkarte umgestellt.
- Sandbox-Hinweis: Godot kann beim seriellen Testlauf in der Codex-Sandbox an `user://logs` crashen. Headless-Tests wurden deshalb ausserhalb der Sandbox ausgefuehrt.
- Marco-Check: Spiel startet im Editor, alter Gameplayloop funktioniert.

## Bestehende Content-IDs vor PoC2

Karten:

- `card.product.software`
- `card.employee.developer`
- `card.input.idea`
- `card.consumable.coffee`
- `card.shop.booster_slot`
- `card.resource.money`
- `card.problem.bug`
- `card.problem.tech_debt`
- `card.problem.prod_crash`
- `card.resource.booster_pack`
- `card.output.feature`

Recipes:

- `recipe.feature_from_idea.developer`
- `recipe.feature_from_idea.developer.coffee`
- `recipe.money_from_feature.software`
- `recipe.bugfix.developer`
- `recipe.cleanup_tech_debt.developer`
- `recipe.hotfix_prod_crash.developer`
- `recipe.booster_pack_from_money.slot`

Booster/Shop/Balance:

- `booster.founder.test_pack`
- `shop.poc.booster`
- `balance.poc.default`

## PoC2 Scope-Entscheidungen

- Konflikt-System bleibt fuer PoC2 out-of-scope.
- PoC2 baut auf PoC1-Daten und Simulation auf; keine bestehenden IDs werden umbenannt.
- Tech Debt und Prod-Crash existieren bereits minimal und werden fuer PoC2 erweitert statt ersetzt.
- Das Recipe `recipe.feature_from_promising_user_story.developer` existiert bereits in Phase 2, der hoehere `feature_value` wird aber bewusst erst in Phase 3 mit Runtime-Werten umgesetzt.

extends SceneTree

const SOFTWARE_DEFINITION_ID: String = "card.product.software"
const MONEY_DEFINITION_ID: String = "card.resource.money"
const MVP_REQUIRED_FEATURES_VALUE: String = "mvp_required_features"

var _failed: bool = false

func _init() -> void:
	_test_poc3_balance_values_are_bundled()
	_test_content_load_applies_poc3_balance_to_recipes()
	_test_run_start_uses_poc3_balance_values()

	if _failed:
		quit(1)
		return

	print("PoC3 phase 10 balance/QA tests passed.")
	quit(0)

func _test_poc3_balance_values_are_bundled() -> void:
	var catalog: ContentCatalog = _load_catalog()
	var balance: BalanceDefinition = catalog.balance

	_assert_equal(balance.poc3_mvp_required_features, 10, "PoC3 MVP threshold should live in balance.")
	_assert_equal(balance.poc3_start_money_cards, 30, "PoC3 playtest start money should live in balance.")
	_assert_equal(balance.poc3_freelance_feature_money_cards, 2, "PoC3 feature freelance payout should live in balance.")
	_assert_equal(balance.poc3_freelance_checked_feature_money_cards, 3, "PoC3 checked freelance payout should live in balance.")
	_assert_equal(balance.poc3_customer_tick_money_cards, 1, "PoC3 customer money tick should live in balance.")
	_assert_equal(balance.poc3_customer_tick_request_cards, 1, "PoC3 customer request tick should live in balance.")
	_assert_equal(balance.poc3_business_goal_required_money, [3, 5, 7], "PoC3 goal ladder should live in balance.")
	_assert_equal(balance.poc3_developer_customer_request_duration_seconds, 9.0, "PoC3 developer customer-request duration should live in balance.")

func _test_content_load_applies_poc3_balance_to_recipes() -> void:
	var catalog: ContentCatalog = _load_catalog()
	var developer_request_recipe: RecipeDefinition = catalog.get_recipe_definition("recipe.promising_user_story_from_customer_request.developer")
	var freelance_recipe: RecipeDefinition = catalog.get_recipe_definition("recipe.money_from_freelance_order.feature")
	var checked_freelance_recipe: RecipeDefinition = catalog.get_recipe_definition("recipe.money_from_freelance_order.checked_feature")

	_assert_equal(developer_request_recipe.duration.base_seconds, catalog.balance.poc3_developer_customer_request_duration_seconds, "Developer customer-request duration should be applied from balance.")
	_assert_equal(_find_spawn_money_count_key(freelance_recipe), "poc3_freelance_feature_money_cards", "Feature freelance payout should use a balance count key.")
	_assert_equal(_find_spawn_money_count_key(checked_freelance_recipe), "poc3_freelance_checked_feature_money_cards", "Checked freelance payout should use a balance count key.")

func _test_run_start_uses_poc3_balance_values() -> void:
	var catalog: ContentCatalog = _load_catalog()
	catalog.balance = catalog.balance.duplicate(true) as BalanceDefinition
	catalog.balance.poc3_mvp_required_features = 4
	catalog.balance.poc3_start_money_cards = 6
	catalog.apply_balance_overrides()

	var controller: RunController = RunController.new(catalog)
	var state: RunState = controller.start_new_run(31001)
	var software: CardInstance = controller.get_software_card()

	_assert_equal(software.values[MVP_REQUIRED_FEATURES_VALUE], 4, "New runs should copy MVP threshold from balance onto software runtime state.")
	_assert_equal(_count_cards_by_definition(state, MONEY_DEFINITION_ID), 6, "New runs should spawn start money from balance.")
	_assert_equal(_count_cards_by_definition(state, SOFTWARE_DEFINITION_ID), 1, "New runs should still spawn exactly one software card.")

func _find_spawn_money_count_key(recipe: RecipeDefinition) -> String:
	for effect: EffectDefinition in recipe.effects_on_complete:
		if effect != null and effect.effect_type == "spawn_money":
			return effect.parameters.get("count_key", "") as String
	return ""

func _load_catalog() -> ContentCatalog:
	var catalog: ContentCatalog = ContentCatalog.new()
	_assert_true(catalog.load_default_content(), "Default content should load.")
	return catalog

func _count_cards_by_definition(state: RunState, definition_id: String) -> int:
	var count: int = 0
	for card: CardInstance in state.cards.values():
		if card.definition_id == definition_id:
			count += 1
	return count

func _assert_true(value: bool, message: String) -> void:
	if value:
		return
	_failed = true
	printerr("Assertion failed: %s" % message)

func _assert_equal(actual: Variant, expected: Variant, message: String) -> void:
	if actual == expected:
		return
	_failed = true
	printerr("Assertion failed: %s Expected '%s', got '%s'." % [message, expected, actual])

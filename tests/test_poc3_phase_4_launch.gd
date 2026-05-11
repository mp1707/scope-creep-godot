extends SceneTree

const FEATURE_COUNT_VALUE: String = "feature_count"
const LAUNCH_FEATURE_COUNT_VALUE: String = "launch_feature_count"
const PRODUCT_STAGE_VALUE: String = "product_stage"
const PRODUCT_STAGE_LIVE: String = "live"

var _failed: bool = false

func _init() -> void:
	_test_nine_features_do_not_match_launch()
	_test_ten_features_launches_software_and_spawns_start_customers()
	_test_fifteen_features_launch_spawns_three_customers()
	_test_existing_problems_do_not_block_launch()

	if _failed:
		quit(1)
		return

	print("PoC3 phase 4 launch tests passed.")
	quit(0)

func _test_nine_features_do_not_match_launch() -> void:
	var controller: RunController = _create_controller()
	var state: RunState = controller.start_new_run(3401)
	var software: CardInstance = controller.get_software_card()
	var developer: CardInstance = _find_card_by_definition(state, "card.employee.developer")
	software.values[FEATURE_COUNT_VALUE] = 9

	controller.move_card_to_stack(developer.instance_id, software.stack_id)

	_assert_equal(state.get_stack(software.stack_id).processing_state.active_recipe_id, "", "Nine MVP features should not start launch processing.")
	_assert_equal(int(software.values[LAUNCH_FEATURE_COUNT_VALUE]), 0, "Nine-feature MVP should not store launch feature count.")

func _test_ten_features_launches_software_and_spawns_start_customers() -> void:
	var controller: RunController = _create_controller()
	var state: RunState = controller.start_new_run(3402)
	var software: CardInstance = controller.get_software_card()
	var developer: CardInstance = _find_card_by_definition(state, "card.employee.developer")
	software.values[FEATURE_COUNT_VALUE] = 10

	controller.move_card_to_stack(developer.instance_id, software.stack_id)
	_assert_equal(state.get_stack(software.stack_id).processing_state.active_recipe_id, "recipe.launch_software.developer", "Ten MVP features should start manual launch processing.")
	controller.advance_time(4.0)

	_assert_equal(software.values[PRODUCT_STAGE_VALUE], PRODUCT_STAGE_LIVE, "Launch should set software product_stage to live.")
	_assert_equal(int(software.values[LAUNCH_FEATURE_COUNT_VALUE]), 10, "Launch should store launch_feature_count.")
	_assert_equal(_count_cards_by_definition(state, "card.value_source.customer"), 2, "Ten features should create two start customers.")
	_assert_equal(_count_cards_by_definition(state, "card.goal.business_goal"), 1, "Launch should spawn the first business goal placeholder.")
	_assert_equal(_count_cards_by_definition(state, "card.product.software"), 1, "Launch should keep the same visible software card.")

func _test_fifteen_features_launch_spawns_three_customers() -> void:
	var controller: RunController = _create_controller()
	var state: RunState = controller.start_new_run(3403)
	var software: CardInstance = controller.get_software_card()
	var developer: CardInstance = _find_card_by_definition(state, "card.employee.developer")
	software.values[FEATURE_COUNT_VALUE] = 15

	controller.move_card_to_stack(developer.instance_id, software.stack_id)
	controller.advance_time(4.0)

	_assert_equal(_count_cards_by_definition(state, "card.value_source.customer"), 3, "Fifteen features should create three start customers.")

func _test_existing_problems_do_not_block_launch() -> void:
	var controller: RunController = _create_controller()
	var state: RunState = controller.start_new_run(3404)
	var software: CardInstance = controller.get_software_card()
	var developer: CardInstance = _find_card_by_definition(state, "card.employee.developer")
	software.values[FEATURE_COUNT_VALUE] = 10
	_spawn_card(controller, "card.problem.bug", Vector2(980.0, 360.0))
	_spawn_card(controller, "card.problem.tech_debt", Vector2(1180.0, 360.0))

	controller.move_card_to_stack(developer.instance_id, software.stack_id)
	controller.advance_time(4.0)

	_assert_equal(software.values[PRODUCT_STAGE_VALUE], PRODUCT_STAGE_LIVE, "Existing bugs and tech debt elsewhere should not block launch.")
	_assert_equal(_count_cards_by_definition(state, "card.problem.bug"), 1, "Launch should not consume existing bugs.")
	_assert_equal(_count_cards_by_definition(state, "card.problem.tech_debt"), 1, "Launch should not consume existing tech debt.")

func _create_controller() -> RunController:
	var catalog: ContentCatalog = ContentCatalog.new()
	_assert_true(catalog.load_default_content(), "Default content should load.")
	catalog.balance = catalog.balance.duplicate(true) as BalanceDefinition
	catalog.balance.bug_chance = 0.0
	catalog.balance.tech_debt_chance = 0.0
	catalog.balance.burnout_increment_per_completed_work = 0.0
	return RunController.new(catalog)

func _spawn_card(controller: RunController, definition_id: String, position: Vector2) -> CardInstance:
	return controller.call("_spawn_card_as_new_stack", definition_id, position) as CardInstance

func _find_card_by_definition(state: RunState, definition_id: String) -> CardInstance:
	for card: CardInstance in state.cards.values():
		if card.definition_id == definition_id:
			return card
	return null

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

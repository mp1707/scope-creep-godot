extends SceneTree

const PRODUCT_STAGE_VALUE: String = "product_stage"
const PRODUCT_STAGE_LIVE: String = "live"

var _failed: bool = false

func _init() -> void:
	_test_start_setup_contains_playtest_resources()
	_test_pre_launch_sprint_start_keeps_one_freelance_order_available()
	_test_post_launch_sprint_start_stops_freelance_spawn()
	_test_freelance_order_pays_two_money_and_consumes_inputs()
	_test_checked_freelance_order_pays_three_money_and_consumes_inputs()

	if _failed:
		quit(1)
		return

	print("PoC3 phase 3 freelance tests passed.")
	quit(0)

func _test_start_setup_contains_playtest_resources() -> void:
	var controller: RunController = _create_controller()
	var state: RunState = controller.start_new_run(3301)

	_assert_equal(_count_cards_by_definition(state, "card.value_source.freelance_order"), 1, "Start setup should include one freelance order.")
	_assert_equal(_count_cards_by_definition(state, "card.resource.money"), 30, "PoC3 playtest start setup should include thirty money cards.")
	_assert_equal(_count_pure_stacks_by_definition(state, "card.resource.money"), 1, "PoC3 start money should spawn as one money stack.")
	_assert_equal(_count_cards_by_definition(state, "card.output.checked_feature"), 0, "PoC3 start setup should not include checked-feature launch scaffolding.")

func _test_pre_launch_sprint_start_keeps_one_freelance_order_available() -> void:
	var controller: RunController = _create_controller()
	var state: RunState = controller.start_new_run(3302)

	_enter_next_sprint(controller)

	_assert_equal(_count_cards_by_definition(state, "card.value_source.freelance_order"), 1, "Pre-launch sprint start should replace expired freelance order with one new order.")
	var freelance_order: CardInstance = _find_card_by_definition(state, "card.value_source.freelance_order")
	_assert_equal(freelance_order.created_at_sprint, 2, "Pre-launch freelance order should be spawned for the new sprint.")

func _test_post_launch_sprint_start_stops_freelance_spawn() -> void:
	var controller: RunController = _create_controller()
	var state: RunState = controller.start_new_run(3303)
	var software: CardInstance = controller.get_software_card()
	software.values[PRODUCT_STAGE_VALUE] = PRODUCT_STAGE_LIVE

	_enter_next_sprint(controller)

	_assert_equal(_count_cards_by_definition(state, "card.value_source.freelance_order"), 0, "Post-launch sprint start should expire existing freelance order and not spawn a replacement.")

func _test_freelance_order_pays_two_money_and_consumes_inputs() -> void:
	var controller: RunController = _create_controller()
	var state: RunState = controller.start_new_run(3304)
	var order: CardInstance = _find_card_by_definition(state, "card.value_source.freelance_order")
	var feature: CardInstance = _spawn_card(controller, "card.output.feature", Vector2(820.0, 360.0))
	var money_before: int = _count_cards_by_definition(state, "card.resource.money")

	controller.move_card_to_stack(feature.instance_id, order.stack_id)
	_assert_equal(state.get_stack(order.stack_id).processing_state.active_recipe_id, "recipe.money_from_freelance_order.feature", "Feature + freelance order should start freelance delivery.")
	controller.advance_time(1.0)

	_assert_equal(_count_cards_by_definition(state, "card.resource.money"), money_before + 2, "Feature freelance order should pay two money cards.")
	_assert_equal(_count_cards_by_definition(state, "card.value_source.freelance_order"), 0, "Fulfilled freelance order should be consumed.")
	_assert_equal(_count_cards_by_definition(state, "card.output.feature"), 0, "Freelance delivery should consume the feature.")

func _test_checked_freelance_order_pays_three_money_and_consumes_inputs() -> void:
	var controller: RunController = _create_controller()
	var state: RunState = controller.start_new_run(3305)
	var order: CardInstance = _find_card_by_definition(state, "card.value_source.freelance_order")
	var checked_feature: CardInstance = _spawn_card(controller, "card.output.checked_feature", Vector2(820.0, 360.0))
	var money_before: int = _count_cards_by_definition(state, "card.resource.money")
	var checked_features_before: int = _count_cards_by_definition(state, "card.output.checked_feature")

	controller.move_card_to_stack(checked_feature.instance_id, order.stack_id)
	_assert_equal(state.get_stack(order.stack_id).processing_state.active_recipe_id, "recipe.money_from_freelance_order.checked_feature", "Checked feature + freelance order should start checked freelance delivery.")
	controller.advance_time(1.0)

	_assert_equal(_count_cards_by_definition(state, "card.resource.money"), money_before + 3, "Checked freelance order should pay three money cards.")
	_assert_equal(_count_cards_by_definition(state, "card.value_source.freelance_order"), 0, "Fulfilled checked freelance order should be consumed.")
	_assert_equal(_count_cards_by_definition(state, "card.output.checked_feature"), checked_features_before - 1, "Freelance delivery should consume one checked feature.")

func _enter_next_sprint(controller: RunController) -> void:
	controller.advance_time(60.0)
	_assert_true(controller.auto_pay_all_employees(), "Auto-pay should be possible before next sprint.")
	controller.start_next_sprint()

func _create_controller() -> RunController:
	var catalog: ContentCatalog = ContentCatalog.new()
	_assert_true(catalog.load_default_content(), "Default content should load.")
	catalog.balance = catalog.balance.duplicate(true) as BalanceDefinition
	catalog.balance.sprint_duration_seconds = 60.0
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

func _count_pure_stacks_by_definition(state: RunState, definition_id: String) -> int:
	var count: int = 0
	for stack: StackState in state.stacks.values():
		if stack.card_ids.is_empty():
			continue
		var is_pure_stack: bool = true
		for card_id: String in stack.card_ids:
			var card: CardInstance = state.get_card(card_id)
			if card == null or card.definition_id != definition_id:
				is_pure_stack = false
				break
		if is_pure_stack:
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

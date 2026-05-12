extends SceneTree

const PRODUCT_STAGE_VALUE: String = "product_stage"
const PRODUCT_STAGE_LIVE: String = "live"

var _failed: bool = false

func _init() -> void:
	_test_money_pays_business_goal_one_card_at_a_time()
	_test_fulfilled_goal_spawns_next_goal()
	_test_missed_goal_spawns_investor_panic_and_next_goal()
	_test_three_fulfilled_goals_win_poc3()
	_test_two_investor_panic_cards_end_run()

	if _failed:
		quit(1)
		return

	print("PoC3 phase 7 business goal tests passed.")
	quit(0)

func _test_money_pays_business_goal_one_card_at_a_time() -> void:
	var controller: RunController = _create_controller()
	var state: RunState = controller.start_new_run(3701)
	var goal: CardInstance = _spawn_business_goal(controller, 1, Vector2(860.0, 360.0))
	var money: CardInstance = _find_top_card_by_definition(state, "card.resource.money")
	var money_before: int = _count_cards_by_definition(state, "card.resource.money")

	controller.move_card_to_stack(money.instance_id, goal.stack_id)

	_assert_equal(int(goal.values["paid_money"]), 1, "One money card should add one paid_money to the business goal.")
	_assert_equal(_count_cards_by_definition(state, "card.resource.money"), money_before - 1, "Goal payment should consume exactly one money card.")
	_assert_true(goal.state.markers.has("G1"), "Business goal marker should show its goal index.")

func _test_fulfilled_goal_spawns_next_goal() -> void:
	var controller: RunController = _create_controller()
	var state: RunState = controller.start_new_run(3702)
	_make_live(controller)
	_remove_all_cards_by_definition(controller, state, "card.value_source.freelance_order")
	_spawn_card(controller, "card.value_source.customer", Vector2(860.0, 360.0))
	var goal: CardInstance = _spawn_business_goal(controller, 1, Vector2(1040.0, 360.0))
	goal.values["paid_money"] = 3

	_enter_next_sprint(controller)

	var next_goal: CardInstance = _find_card_by_definition(state, "card.goal.business_goal")
	_assert_equal(state.completed_business_goal_count, 1, "Fulfilled business goal should increase completed goal count.")
	_assert_equal(int(next_goal.values["goal_index"]), 2, "Fulfilled goal should spawn the next goal.")
	_assert_equal(int(next_goal.values["required_money"]), 5, "Second business goal should require 5 money.")
	_assert_equal(_count_cards_by_definition(state, "card.problem.investor_panic"), 0, "Fulfilled goal should not create investor panic.")

func _test_missed_goal_spawns_investor_panic_and_next_goal() -> void:
	var controller: RunController = _create_controller()
	var state: RunState = controller.start_new_run(3703)
	_make_live(controller)
	_remove_all_cards_by_definition(controller, state, "card.value_source.freelance_order")
	_spawn_card(controller, "card.value_source.customer", Vector2(860.0, 360.0))
	_spawn_business_goal(controller, 1, Vector2(1040.0, 360.0))

	_enter_next_sprint(controller)

	var next_goal: CardInstance = _find_card_by_definition(state, "card.goal.business_goal")
	_assert_equal(state.completed_business_goal_count, 0, "Missed goal should not count as completed.")
	_assert_equal(_count_cards_by_definition(state, "card.problem.investor_panic"), 1, "Missed goal should create one investor panic.")
	_assert_equal(int(next_goal.values["goal_index"]), 2, "Missed goal should still prepare the next goal.")

func _test_three_fulfilled_goals_win_poc3() -> void:
	var controller: RunController = _create_controller()
	var state: RunState = controller.start_new_run(3704)
	_make_live(controller)
	_remove_all_cards_by_definition(controller, state, "card.value_source.freelance_order")
	_spawn_card(controller, "card.value_source.customer", Vector2(860.0, 360.0))
	state.completed_business_goal_count = 2
	var goal: CardInstance = _spawn_business_goal(controller, 3, Vector2(1040.0, 360.0))
	goal.values["paid_money"] = 7

	_enter_next_sprint(controller)

	_assert_equal(state.phase, ScopeEnums.RunPhase.VICTORY, "Third fulfilled business goal should win PoC3.")
	_assert_equal(_count_cards_by_definition(state, "card.goal.business_goal"), 0, "Victory should remove the completed goal without spawning another.")

func _test_two_investor_panic_cards_end_run() -> void:
	var controller: RunController = _create_controller()
	var state: RunState = controller.start_new_run(3705)
	_make_live(controller)
	_remove_all_cards_by_definition(controller, state, "card.value_source.freelance_order")
	_spawn_card(controller, "card.value_source.customer", Vector2(860.0, 360.0))
	_spawn_card(controller, "card.problem.investor_panic", Vector2(1220.0, 360.0))
	_spawn_business_goal(controller, 1, Vector2(1040.0, 360.0))

	_enter_next_sprint(controller)

	_assert_equal(state.phase, ScopeEnums.RunPhase.GAME_OVER, "Second investor panic should end the run.")
	_assert_equal(_count_cards_by_definition(state, "card.problem.investor_panic"), 2, "The second panic card should remain visible as the loss reason.")

func _enter_next_sprint(controller: RunController) -> void:
	controller.advance_time(60.0)
	_assert_true(controller.auto_pay_all_employees(), "Auto-pay should be possible before next sprint.")
	controller.start_next_sprint()

func _make_live(controller: RunController) -> void:
	controller.get_software_card().values[PRODUCT_STAGE_VALUE] = PRODUCT_STAGE_LIVE

func _create_controller() -> RunController:
	var catalog: ContentCatalog = ContentCatalog.new()
	_assert_true(catalog.load_default_content(), "Default content should load.")
	catalog.balance = catalog.balance.duplicate(true) as BalanceDefinition
	catalog.balance.sprint_duration_seconds = 60.0
	catalog.balance.bug_chance = 0.0
	catalog.balance.tech_debt_chance = 0.0
	catalog.balance.burnout_increment_per_completed_work = 0.0
	return RunController.new(catalog)

func _spawn_business_goal(controller: RunController, goal_index: int, position: Vector2) -> CardInstance:
	var goal: CardInstance = _spawn_card(controller, "card.goal.business_goal", position)
	goal.values["goal_index"] = goal_index
	goal.values["required_money"] = [3, 5, 7][clampi(goal_index - 1, 0, 2)]
	goal.values["paid_money"] = 0
	goal.state.markers = PackedStringArray(["G%d" % goal_index])
	return goal

func _spawn_card(controller: RunController, definition_id: String, position: Vector2) -> CardInstance:
	return controller.call("_spawn_card_as_new_stack", definition_id, position) as CardInstance

func _remove_all_cards_by_definition(controller: RunController, state: RunState, definition_id: String) -> void:
	for card: CardInstance in _find_cards_by_definition(state, definition_id):
		controller.call("_remove_card_instance", card.instance_id)

func _find_card_by_definition(state: RunState, definition_id: String) -> CardInstance:
	for card: CardInstance in state.cards.values():
		if card.definition_id == definition_id:
			return card
	_assert_true(false, "Missing card with definition '%s'." % definition_id)
	return null

func _find_top_card_by_definition(state: RunState, definition_id: String) -> CardInstance:
	for stack: StackState in state.stacks.values():
		for offset: int in stack.card_ids.size():
			var card_id: String = stack.card_ids[stack.card_ids.size() - 1 - offset]
			var card: CardInstance = state.get_card(card_id)
			if card != null and card.definition_id == definition_id:
				return card
	_assert_true(false, "Missing top card with definition '%s'." % definition_id)
	return null

func _find_cards_by_definition(state: RunState, definition_id: String) -> Array[CardInstance]:
	var cards: Array[CardInstance] = []
	for card: CardInstance in state.cards.values():
		if card.definition_id == definition_id:
			cards.append(card)
	return cards

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

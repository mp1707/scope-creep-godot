extends SceneTree

const PRODUCT_STAGE_VALUE: String = "product_stage"
const PRODUCT_STAGE_LIVE: String = "live"
const FEATURE_COUNT_VALUE: String = "feature_count"

var _failed: bool = false

func _init() -> void:
	_test_money_stack_can_overpay_business_goal_and_leave_change()
	_test_employee_queue_processes_top_work_item_first()
	_test_burnout_interrupts_employee_work_queue()
	_test_software_processes_feature_queue_one_at_a_time()
	_test_missed_goal_spawns_panic_next_to_goal()

	if _failed:
		quit(1)
		return

	print("PoC3 Feinschliff tests passed.")
	quit(0)

func _test_money_stack_can_overpay_business_goal_and_leave_change() -> void:
	var controller: RunController = _create_controller(4101, 0.0)
	var state: RunState = controller.start_new_run(4101)
	_remove_all_cards_by_definition(controller, state, "card.resource.money")
	var goal: CardInstance = _spawn_business_goal(controller, 1, Vector2(860.0, 360.0))
	var money_stack: StackState = null
	for index: int in 4:
		var money: CardInstance = _spawn_card(controller, "card.resource.money", Vector2(1040.0, 360.0))
		money_stack = state.get_stack(money.stack_id)

	controller.move_card_to_stack(money_stack.card_ids[0], goal.stack_id)

	_assert_equal(int(goal.values["paid_money"]), 3, "A dragged money stack should pay only the missing goal amount.")
	_assert_equal(_count_cards_by_definition(state, "card.resource.money"), 1, "Overpaying with four money on a three-money goal should leave one money card.")
	_assert_equal(state.get_stack(money_stack.stack_id).card_ids.size(), 1, "The leftover money should remain in its source stack.")

func _test_employee_queue_processes_top_work_item_first() -> void:
	var controller: RunController = _create_controller(4102, 0.0)
	var state: RunState = controller.start_new_run(4102)
	var developer: CardInstance = _find_card_by_definition(state, "card.employee.developer")
	var first_story: CardInstance = _spawn_card(controller, "card.task.user_story", Vector2(860.0, 360.0))
	var second_story: CardInstance = _spawn_card(controller, "card.task.user_story", Vector2(860.0, 360.0))
	var story_stack: StackState = state.get_stack(second_story.stack_id)

	controller.move_card_to_stack(story_stack.card_ids[0], developer.stack_id)
	var stack: StackState = state.get_stack(developer.stack_id)

	_assert_equal(stack.processing_state.active_recipe_id, "recipe.feature_from_user_story.developer", "Developer work queue should start feature work.")
	_assert_true(stack.processing_state.active_input_card_ids.has(second_story.instance_id), "The visible top story should be the active queued input.")
	controller.advance_time(8.0)

	_assert_true(state.get_card(second_story.instance_id) == null, "The top story should be consumed first.")
	_assert_true(state.get_card(first_story.instance_id) != null, "The lower story should wait in the queue.")
	_assert_equal(stack.processing_state.active_recipe_id, "recipe.feature_from_user_story.developer", "The next queued story should start automatically.")
	_assert_true(stack.processing_state.active_input_card_ids.has(first_story.instance_id), "After the first completion the lower story should become active.")

func _test_burnout_interrupts_employee_work_queue() -> void:
	var controller: RunController = _create_controller(4103, 1.0)
	var state: RunState = controller.start_new_run(4103)
	var developer: CardInstance = _find_card_by_definition(state, "card.employee.developer")
	var first_story: CardInstance = _spawn_card(controller, "card.task.user_story", Vector2(860.0, 360.0))
	var second_story: CardInstance = _spawn_card(controller, "card.task.user_story", Vector2(860.0, 360.0))
	var story_stack: StackState = state.get_stack(second_story.stack_id)

	controller.move_card_to_stack(story_stack.card_ids[0], developer.stack_id)
	controller.advance_time(8.0)

	var stack: StackState = state.get_stack(developer.stack_id)
	var burnout: CardInstance = _find_card_by_definition(state, "card.problem.burnout")
	_assert_equal(burnout.parent_card_id, developer.instance_id, "Burnout should attach to the employee that completed queued work.")
	_assert_equal(stack.processing_state.active_recipe_id, "recipe.burnout_recovery.employee", "Burnout recovery should interrupt remaining queued work.")
	_assert_true(state.get_card(second_story.instance_id) == null, "The completed top story should be consumed before burnout recovery.")
	_assert_true(state.get_card(first_story.instance_id) != null, "Queued lower work should remain while burnout recovers.")
	_assert_true(stack.card_ids.find(burnout.instance_id) < stack.card_ids.find(first_story.instance_id), "Burnout should be inserted between employee and remaining work.")

	controller.advance_time(45.0)
	_assert_equal(_count_cards_by_definition(state, "card.problem.burnout"), 0, "Burnout should be removed after recovery.")
	_assert_equal(stack.processing_state.active_recipe_id, "recipe.feature_from_user_story.developer", "Queued work should continue after burnout recovery.")
	_assert_true(stack.processing_state.active_input_card_ids.has(first_story.instance_id), "The remaining story should become active after recovery.")

func _test_software_processes_feature_queue_one_at_a_time() -> void:
	var controller: RunController = _create_controller(4104, 0.0)
	var state: RunState = controller.start_new_run(4104)
	var software: CardInstance = controller.get_software_card()
	var first_feature: CardInstance = _spawn_card(controller, "card.output.feature", Vector2(860.0, 360.0))
	var second_feature: CardInstance = _spawn_card(controller, "card.output.feature", Vector2(1040.0, 360.0))

	controller.move_card_to_stack(first_feature.instance_id, second_feature.stack_id)
	var feature_stack: StackState = state.get_stack(second_feature.stack_id)
	controller.move_card_to_stack(feature_stack.card_ids[0], software.stack_id)
	var stack: StackState = state.get_stack(software.stack_id)

	_assert_equal(stack.processing_state.active_recipe_id, "recipe.money_from_feature.software", "Software should start integrating the first queued feature.")
	_assert_true(stack.processing_state.active_input_card_ids.has(first_feature.instance_id), "The visible top feature should be integrated first.")
	controller.advance_time(6.0)

	_assert_equal(int(software.values[FEATURE_COUNT_VALUE]), 1, "Only one feature should be integrated per processing completion.")
	_assert_true(state.get_card(first_feature.instance_id) == null, "The active feature should be consumed.")
	_assert_true(state.get_card(second_feature.instance_id) != null, "The next feature should remain queued.")
	_assert_equal(stack.processing_state.active_recipe_id, "recipe.money_from_feature.software", "The next feature should start integrating automatically.")
	controller.advance_time(6.0)
	_assert_equal(int(software.values[FEATURE_COUNT_VALUE]), 2, "The second queued feature should integrate after the first.")
	_assert_equal(_count_cards_by_definition(state, "card.output.feature"), 0, "Both queued features should be consumed after two completions.")

func _test_missed_goal_spawns_panic_next_to_goal() -> void:
	var controller: RunController = _create_controller(4105, 0.0)
	var state: RunState = controller.start_new_run(4105)
	_make_live(controller)
	_remove_all_cards_by_definition(controller, state, "card.value_source.freelance_order")
	_spawn_card(controller, "card.value_source.customer", Vector2(860.0, 360.0))
	_spawn_business_goal(controller, 1, Vector2(1040.0, 360.0))

	_enter_next_sprint(controller)

	var panic: CardInstance = _find_card_by_definition(state, "card.problem.investor_panic")
	var next_goal: CardInstance = _find_card_by_definition(state, "card.goal.business_goal")
	_assert_true(not _card_rect(panic).intersects(_card_rect(next_goal)), "Investor panic should not overlap the next business goal.")
	_assert_true(panic.position.distance_to(Vector2(1040.0, 360.0)) > 100.0, "Investor panic should spawn next to the missed goal position, not under it.")

func _enter_next_sprint(controller: RunController) -> void:
	controller.advance_time(60.0)
	_assert_true(controller.auto_pay_all_employees(), "Auto-pay should be possible before next sprint.")
	controller.start_next_sprint()

func _make_live(controller: RunController) -> void:
	controller.get_software_card().values[PRODUCT_STAGE_VALUE] = PRODUCT_STAGE_LIVE

func _create_controller(run_seed: int, burnout_increment: float) -> RunController:
	var catalog: ContentCatalog = ContentCatalog.new()
	_assert_true(catalog.load_default_content(), "Default content should load.")
	catalog.balance = catalog.balance.duplicate(true) as BalanceDefinition
	catalog.balance.sprint_duration_seconds = 60.0
	catalog.balance.bug_chance = 0.0
	catalog.balance.tech_debt_chance = 0.0
	catalog.balance.burnout_increment_per_completed_work = burnout_increment
	catalog.balance.poc3_start_money_cards = 8
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

func _card_rect(card: CardInstance) -> Rect2:
	return Rect2(card.position, Vector2(144.0, 196.0))

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

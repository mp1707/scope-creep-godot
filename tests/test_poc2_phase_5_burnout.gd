extends SceneTree

const SAVE_PATH: String = "user://scope_creep_poc2_phase_5_test.json"

var _failed: bool = false

func _init() -> void:
	_test_completed_work_can_attach_burnout_and_start_recovery()
	_test_burnout_blocks_normal_work()
	_test_pizza_recovery_is_more_specific()
	_test_stress_course_removes_burnout_immediately()
	_test_burnout_attachment_survives_save_load()

	if _failed:
		quit(1)
		return

	print("PoC2 phase 5 burnout tests passed.")
	quit(0)

func _test_completed_work_can_attach_burnout_and_start_recovery() -> void:
	var controller: RunController = _create_controller()
	var state: RunState = controller.start_new_run(501)
	var developer: CardInstance = _find_card_by_definition(state, "card.employee.developer")
	var idea: CardInstance = _find_card_by_definition(state, "card.input.idea")

	controller.move_card_to_stack(idea.instance_id, developer.stack_id)
	controller.advance_time(8.0)

	var burnout: CardInstance = _find_card_by_definition(state, "card.problem.burnout")
	var stack: StackState = state.get_stack(developer.stack_id)
	_assert_equal(burnout.parent_card_id, developer.instance_id, "Burnout should attach to the employee that completed work.")
	_assert_equal(burnout.attachment_slot, "burnout", "Burnout should use the burnout attachment slot.")
	_assert_true(stack.card_ids.has(burnout.instance_id), "Burnout should stay in the employee stack.")
	_assert_equal(stack.processing_state.active_recipe_id, "recipe.burnout_recovery.employee", "Attached burnout should start normal recovery.")

func _test_burnout_blocks_normal_work() -> void:
	var controller: RunController = _create_controller()
	var state: RunState = controller.start_new_run(502)
	var developer: CardInstance = _find_card_by_definition(state, "card.employee.developer")
	controller.call("_spawn_attached_card", developer.instance_id, "card.problem.burnout", "burnout")
	var idea: CardInstance = _spawn_card(controller, "card.input.idea", Vector2(960.0, 360.0))

	controller.move_card_to_stack(idea.instance_id, developer.stack_id)
	var stack: StackState = state.get_stack(developer.stack_id)

	_assert_equal(stack.processing_state.active_recipe_id, "recipe.burnout_recovery.employee", "Burned-out employee should keep recovering instead of starting normal feature work.")
	_assert_true(stack.card_ids.has(idea.instance_id), "New work should wait in the stack while burnout recovery is active.")

func _test_pizza_recovery_is_more_specific() -> void:
	var controller: RunController = _create_controller()
	var state: RunState = controller.start_new_run(503)
	var developer: CardInstance = _find_card_by_definition(state, "card.employee.developer")
	controller.call("_spawn_attached_card", developer.instance_id, "card.problem.burnout", "burnout")
	var pizza: CardInstance = _spawn_card(controller, "card.consumable.pizza_party", Vector2(960.0, 360.0))

	controller.move_card_to_stack(pizza.instance_id, developer.stack_id)
	var stack: StackState = state.get_stack(developer.stack_id)

	_assert_equal(stack.processing_state.active_recipe_id, "recipe.burnout_recovery.pizza", "Pizza should beat normal burnout recovery.")
	_assert_equal(stack.processing_state.duration, 5.0, "Pizza recovery should use the short recovery duration.")

func _test_stress_course_removes_burnout_immediately() -> void:
	var controller: RunController = _create_controller()
	var state: RunState = controller.start_new_run(504)
	var developer: CardInstance = _find_card_by_definition(state, "card.employee.developer")
	controller.call("_spawn_attached_card", developer.instance_id, "card.problem.burnout", "burnout")
	var course: CardInstance = _spawn_card(controller, "card.consumable.stress_course", Vector2(960.0, 360.0))

	controller.move_card_to_stack(course.instance_id, developer.stack_id)
	controller.advance_time(0.1)

	_assert_equal(_count_cards_by_definition(state, "card.problem.burnout"), 0, "Stress course should remove burnout.")
	_assert_equal(_count_cards_by_definition(state, "card.consumable.stress_course"), 0, "Stress course should be consumed.")
	_assert_equal(developer.values.get("burnout_progress", 0.0), 0.0, "Burnout progress should stay reset after removal.")

func _test_burnout_attachment_survives_save_load() -> void:
	var controller: RunController = _create_controller()
	var state: RunState = controller.start_new_run(505)
	var developer: CardInstance = _find_card_by_definition(state, "card.employee.developer")
	var burnout: CardInstance = controller.call("_spawn_attached_card", developer.instance_id, "card.problem.burnout", "burnout") as CardInstance
	controller.advance_time(3.0)
	controller.set_paused(true)
	var stack_before: StackState = state.get_stack(developer.stack_id)

	_assert_true(controller.save_current_run(SAVE_PATH), "Paused burnout run should save.")

	var loaded_controller: RunController = _create_controller()
	_assert_true(loaded_controller.load_run_from_file(SAVE_PATH), "Burnout save should load.")
	var loaded_state: RunState = loaded_controller.state
	var loaded_burnout: CardInstance = loaded_state.get_card(burnout.instance_id)
	var loaded_stack: StackState = loaded_state.get_stack(stack_before.stack_id)

	_assert_equal(loaded_burnout.parent_card_id, developer.instance_id, "Loaded burnout should keep parent employee.")
	_assert_equal(loaded_burnout.attachment_slot, "burnout", "Loaded burnout should keep attachment slot.")
	_assert_equal(loaded_stack.processing_state.active_recipe_id, "recipe.burnout_recovery.employee", "Loaded recovery should keep active recipe.")
	_assert_equal(loaded_stack.processing_state.elapsed, 3.0, "Loaded recovery should keep elapsed progress.")

func _create_controller() -> RunController:
	var catalog: ContentCatalog = ContentCatalog.new()
	_assert_true(catalog.load_default_content(), "Default content should load.")
	catalog.balance = catalog.balance.duplicate(true) as BalanceDefinition
	catalog.balance.bug_chance = 0.0
	catalog.balance.tech_debt_chance = 0.0
	catalog.balance.burnout_increment_per_completed_work = 1.0
	return RunController.new(catalog)

func _spawn_card(controller: RunController, definition_id: String, position: Vector2) -> CardInstance:
	return controller.call("_spawn_card_as_new_stack", definition_id, position) as CardInstance

func _count_cards_by_definition(state: RunState, definition_id: String) -> int:
	var count: int = 0
	for card: CardInstance in state.cards.values():
		if card.definition_id == definition_id:
			count += 1
	return count

func _find_card_by_definition(state: RunState, definition_id: String) -> CardInstance:
	for card: CardInstance in state.cards.values():
		if card.definition_id == definition_id:
			return card
	_assert_true(false, "Missing card with definition '%s'." % definition_id)
	return null

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

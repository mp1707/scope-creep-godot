extends SceneTree

var _failed: bool = false

func _init() -> void:
	_test_bugfix_alternatives_have_expected_durations()
	_test_bugfix_alternatives_remove_bug()
	_test_bugfix_patch_consumes_patch()
	_test_external_dev_bugfix_marks_completed_task()
	_test_tech_debt_extends_bugfix_work()
	_test_checked_release_money_is_blocked_by_prod_crash()

	if _failed:
		quit(1)
		return

	print("PoC2 phase 4 problem economy tests passed.")
	quit(0)

func _test_bugfix_alternatives_have_expected_durations() -> void:
	var controller: RunController = _create_controller()
	var state: RunState = controller.start_new_run(401)

	_assert_bugfix_duration(controller, state, "card.employee.developer", "recipe.debug_bug.developer", 12.0)
	_assert_bugfix_duration(controller, state, "card.employee.tester", "recipe.debug_bug.tester", 16.0)
	_assert_bugfix_duration(controller, state, "card.employee.external_dev", "recipe.debug_bug.external_dev", 6.0)
	_assert_bugfix_duration(controller, state, "card.consumable.bugfix_patch", "recipe.debug_bug.bugfix_patch", 0.1)

func _test_bugfix_alternatives_remove_bug() -> void:
	_assert_bugfix_completion_removes_bug("card.employee.developer", 12.0)
	_assert_bugfix_completion_removes_bug("card.employee.tester", 16.0)
	_assert_bugfix_completion_removes_bug("card.employee.external_dev", 6.0)

func _test_bugfix_patch_consumes_patch() -> void:
	var controller: RunController = _create_controller()
	var state: RunState = controller.start_new_run(402)
	var patch: CardInstance = _spawn_card(controller, "card.consumable.bugfix_patch", Vector2(620.0, 360.0))
	var bug: CardInstance = _spawn_card(controller, "card.problem.bug", Vector2(820.0, 360.0))

	controller.move_card_to_stack(bug.instance_id, patch.stack_id)
	controller.advance_time(0.1)

	_assert_equal(_count_cards_by_definition(state, "card.problem.bug"), 0, "Bugfix patch should remove bug.")
	_assert_equal(_count_cards_by_definition(state, "card.consumable.bugfix_patch"), 0, "Bugfix patch should be consumed.")

func _test_external_dev_bugfix_marks_completed_task() -> void:
	var controller: RunController = _create_controller()
	var state: RunState = controller.start_new_run(403)
	var external_dev: CardInstance = _spawn_card(controller, "card.employee.external_dev", Vector2(620.0, 360.0))
	var bug: CardInstance = _spawn_card(controller, "card.problem.bug", Vector2(820.0, 360.0))

	controller.move_card_to_stack(bug.instance_id, external_dev.stack_id)
	controller.advance_time(6.0)

	_assert_equal(external_dev.values["completed_task"], true, "External dev should record completed task after bugfix.")

func _test_tech_debt_extends_bugfix_work() -> void:
	var controller: RunController = _create_controller()
	var state: RunState = controller.start_new_run(404)
	var developer: CardInstance = _find_card_by_definition(state, "card.employee.developer")
	var bug: CardInstance = _spawn_card(controller, "card.problem.bug", Vector2(820.0, 360.0))
	_spawn_card(controller, "card.problem.tech_debt", Vector2(1040.0, 360.0))

	controller.move_card_to_stack(bug.instance_id, developer.stack_id)
	var stack: StackState = state.get_stack(developer.stack_id)

	_assert_equal(stack.processing_state.active_recipe_id, "recipe.debug_bug.developer", "Developer bugfix should still match with tech debt on board.")
	_assert_equal(stack.processing_state.duration, 17.0, "One Tech Debt should add 5s to developer bugfix work.")

func _test_checked_release_money_is_blocked_by_prod_crash() -> void:
	var controller: RunController = _create_controller()
	var state: RunState = controller.start_new_run(405)
	var software: CardInstance = _find_card_by_definition(state, "card.product.software")
	var checked_feature: CardInstance = _spawn_card(controller, "card.output.checked_feature", Vector2(820.0, 360.0))
	checked_feature.values["feature_value"] = 2
	_spawn_card(controller, "card.problem.prod_crash", Vector2(1040.0, 360.0))
	var money_before: int = _count_cards_by_definition(state, "card.resource.money")

	controller.move_card_to_stack(checked_feature.instance_id, software.stack_id)
	controller.advance_time(6.0)

	_assert_equal(_count_cards_by_definition(state, "card.output.checked_feature"), 0, "Checked release should still consume checked feature during Prod-Crash.")
	_assert_equal(_count_cards_by_definition(state, "card.resource.money"), money_before, "Prod-Crash should block checked release money.")

func _assert_bugfix_duration(
	controller: RunController,
	state: RunState,
	worker_definition_id: String,
	expected_recipe_id: String,
	expected_duration: float
) -> void:
	var worker: CardInstance = _get_or_spawn_worker(controller, state, worker_definition_id)
	var bug: CardInstance = _spawn_card(controller, "card.problem.bug", Vector2(820.0 + float(state.cards.size()) * 8.0, 360.0))

	controller.move_card_to_stack(bug.instance_id, worker.stack_id)
	var stack: StackState = state.get_stack(worker.stack_id)
	_assert_equal(stack.processing_state.active_recipe_id, expected_recipe_id, "Bugfix worker should start expected recipe.")
	_assert_equal(stack.processing_state.duration, expected_duration, "Bugfix worker should use expected duration.")
	controller.split_stack_from_card(bug.instance_id, Vector2(1120.0 + float(state.cards.size()) * 8.0, 360.0))

func _assert_bugfix_completion_removes_bug(worker_definition_id: String, duration: float) -> void:
	var controller: RunController = _create_controller()
	var state: RunState = controller.start_new_run(406)
	var worker: CardInstance = _get_or_spawn_worker(controller, state, worker_definition_id)
	var bug: CardInstance = _spawn_card(controller, "card.problem.bug", Vector2(820.0, 360.0))

	controller.move_card_to_stack(bug.instance_id, worker.stack_id)
	controller.advance_time(duration)

	_assert_equal(_count_cards_by_definition(state, "card.problem.bug"), 0, "Completed bugfix should remove bug.")
	_assert_equal(_count_cards_by_definition(state, worker_definition_id), 1, "Completed bugfix should keep worker.")

func _get_or_spawn_worker(controller: RunController, state: RunState, definition_id: String) -> CardInstance:
	if definition_id == "card.employee.developer":
		return _find_card_by_definition(state, definition_id)
	return _spawn_card(controller, definition_id, Vector2(620.0 + float(state.cards.size()) * 8.0, 360.0))

func _create_controller() -> RunController:
	var catalog: ContentCatalog = ContentCatalog.new()
	_assert_true(catalog.load_default_content(), "Default content should load.")
	catalog.balance = catalog.balance.duplicate(true) as BalanceDefinition
	catalog.balance.bug_chance = 0.0
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

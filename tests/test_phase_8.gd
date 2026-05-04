extends SceneTree

var _failed: bool = false

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_unchecked_release_can_spawn_bug()
	_test_bug_formation_happens_before_duplication()
	_test_duplicated_bugs_crash_only_on_next_sprint_start()
	_test_tech_debt_adds_duration_to_feature_work()
	_test_problem_recipes_use_requested_progress_texts()
	_test_developer_can_debug_bug()
	_test_developer_can_hotfix_prod_crash()
	_test_developer_can_clean_up_tech_debt()
	_test_prod_crash_blocks_release_money()

	if _failed:
		quit(1)
		return

	print("Phase 8 tests passed.")
	quit(0)

func _test_unchecked_release_can_spawn_bug() -> void:
	var controller: RunController = _create_controller(60.0)
	controller.content.balance.bug_chance = 1.0
	var state: RunState = controller.start_new_run(11)
	var software: CardInstance = _find_card_by_definition(state, "card.product.software")
	var feature: CardInstance = _spawn_card(controller, "card.output.feature", Vector2(1120.0, 320.0))
	var money_before: int = _count_cards_by_definition(state, "card.resource.money")

	controller.move_card_to_stack(feature.instance_id, software.stack_id)
	controller.advance_time(6.0)

	_assert_equal(_count_cards_by_definition(state, "card.resource.money"), money_before + 1, "Unchecked release should still spawn one 1-money card.")
	_assert_equal(_count_cards_by_definition(state, "card.problem.bug"), 1, "Unchecked release should spawn a bug when bug chance succeeds.")

func _test_bug_formation_happens_before_duplication() -> void:
	var controller: RunController = _create_controller(1.0)
	var state: RunState = controller.start_new_run(1)
	for index: int in 4:
		_spawn_card(controller, "card.problem.bug", Vector2(1200.0 + float(index) * 24.0, 300.0))

	_pay_and_start_next_sprint(controller, state)

	_assert_equal(_count_cards_by_definition(state, "card.problem.prod_crash"), 1, "Three existing bugs should form one Prod-Crash first.")
	_assert_equal(_count_cards_by_definition(state, "card.problem.bug"), 2, "Only the remaining fourth bug should duplicate after formation.")

func _test_duplicated_bugs_crash_only_on_next_sprint_start() -> void:
	var controller: RunController = _create_controller(1.0)
	var state: RunState = controller.start_new_run(1)
	for index: int in 2:
		_spawn_card(controller, "card.problem.bug", Vector2(1200.0 + float(index) * 24.0, 300.0))

	_pay_and_start_next_sprint(controller, state)

	_assert_equal(_count_cards_by_definition(state, "card.problem.prod_crash"), 0, "Two existing bugs should not form a Prod-Crash.")
	_assert_equal(_count_cards_by_definition(state, "card.problem.bug"), 4, "Two existing bugs should duplicate to four bugs.")

	_pay_and_start_next_sprint(controller, state)

	_assert_equal(_count_cards_by_definition(state, "card.problem.prod_crash"), 1, "Duplicated bugs should be eligible at the next sprint start.")
	_assert_equal(_count_cards_by_definition(state, "card.problem.bug"), 2, "Four bugs next sprint should form one crash and duplicate the one leftover bug.")

func _test_tech_debt_adds_duration_to_feature_work() -> void:
	var controller: RunController = _create_controller(60.0)
	var state: RunState = controller.start_new_run(1)
	var developer: CardInstance = _find_card_by_definition(state, "card.employee.developer")
	var idea: CardInstance = _find_card_by_definition(state, "card.input.idea")
	_spawn_card(controller, "card.problem.tech_debt", Vector2(1200.0, 360.0))

	controller.move_card_to_stack(idea.instance_id, developer.stack_id)

	var stack: StackState = state.get_stack(developer.stack_id)
	_assert_equal(stack.processing_state.active_recipe_id, "recipe.feature_from_idea.developer", "Developer + idea should still start feature work.")
	_assert_equal(stack.processing_state.duration, 13.0, "One Tech-Debt card should add 5s to the 8s feature recipe.")

func _test_problem_recipes_use_requested_progress_texts() -> void:
	var controller: RunController = _create_controller(60.0)

	_assert_equal(
		controller.content.get_recipe_definition("recipe.debug_bug.developer").display_text,
		"Debugging...",
		"Bug repair progress should use the requested label."
	)
	_assert_equal(
		controller.content.get_recipe_definition("recipe.hotfix_prod_crash.developer").display_text,
		"Hotfixing...",
		"Prod-Crash repair progress should use the requested label."
	)
	_assert_equal(
		controller.content.get_recipe_definition("recipe.cleanup_tech_debt.developer").display_text,
		"Aufräumen...",
		"Tech-Debt cleanup progress should use the requested label."
	)

func _test_developer_can_debug_bug() -> void:
	var controller: RunController = _create_controller(60.0)
	var state: RunState = controller.start_new_run(1)
	var developer: CardInstance = _find_card_by_definition(state, "card.employee.developer")
	var bug: CardInstance = _spawn_card(controller, "card.problem.bug", Vector2(1200.0, 320.0))

	controller.move_card_to_stack(bug.instance_id, developer.stack_id)
	var stack: StackState = state.get_stack(developer.stack_id)
	_assert_equal(stack.processing_state.active_recipe_id, "recipe.debug_bug.developer", "Bug + developer should start debugging.")
	_assert_equal(stack.processing_state.duration, 12.0, "Debugging should use the PoC bugfix duration without Tech Debt.")

	controller.advance_time(12.0)

	_assert_equal(_count_cards_by_definition(state, "card.problem.bug"), 0, "Completed debugging should remove the bug.")
	_assert_equal(_count_cards_by_definition(state, "card.employee.developer"), 1, "Completed debugging should keep the developer.")

func _test_developer_can_hotfix_prod_crash() -> void:
	var controller: RunController = _create_controller(60.0)
	var state: RunState = controller.start_new_run(1)
	var developer: CardInstance = _find_card_by_definition(state, "card.employee.developer")
	var crash: CardInstance = _spawn_card(controller, "card.problem.prod_crash", Vector2(1200.0, 320.0))

	controller.move_card_to_stack(crash.instance_id, developer.stack_id)
	var stack: StackState = state.get_stack(developer.stack_id)
	_assert_equal(stack.processing_state.active_recipe_id, "recipe.hotfix_prod_crash.developer", "Prod-Crash + developer should start hotfixing.")
	_assert_equal(stack.processing_state.duration, 45.0, "Hotfixing should use the GDD 45s duration.")

	controller.advance_time(45.0)

	_assert_equal(_count_cards_by_definition(state, "card.problem.prod_crash"), 0, "Completed hotfixing should remove the Prod-Crash.")
	_assert_equal(_count_cards_by_definition(state, "card.employee.developer"), 1, "Completed hotfixing should keep the developer.")

func _test_developer_can_clean_up_tech_debt() -> void:
	var controller: RunController = _create_controller(60.0)
	var state: RunState = controller.start_new_run(1)
	var developer: CardInstance = _find_card_by_definition(state, "card.employee.developer")
	var tech_debt: CardInstance = _spawn_card(controller, "card.problem.tech_debt", Vector2(1200.0, 320.0))

	controller.move_card_to_stack(tech_debt.instance_id, developer.stack_id)
	var stack: StackState = state.get_stack(developer.stack_id)
	_assert_equal(stack.processing_state.active_recipe_id, "recipe.cleanup_tech_debt.developer", "Tech Debt + developer should start cleanup.")
	_assert_equal(stack.processing_state.duration, 10.0, "Tech-Debt cleanup should use the PoC cleanup duration.")

	controller.advance_time(10.0)

	_assert_equal(_count_cards_by_definition(state, "card.problem.tech_debt"), 0, "Completed cleanup should remove Tech Debt.")
	_assert_equal(_count_cards_by_definition(state, "card.employee.developer"), 1, "Completed cleanup should keep the developer.")

func _test_prod_crash_blocks_release_money() -> void:
	var controller: RunController = _create_controller(60.0)
	controller.content.balance.bug_chance = 0.0
	var state: RunState = controller.start_new_run(3)
	var software: CardInstance = _find_card_by_definition(state, "card.product.software")
	var feature: CardInstance = _spawn_card(controller, "card.output.feature", Vector2(1120.0, 320.0))
	_spawn_card(controller, "card.problem.prod_crash", Vector2(1280.0, 320.0))
	var money_before: int = _count_cards_by_definition(state, "card.resource.money")

	controller.move_card_to_stack(feature.instance_id, software.stack_id)
	controller.advance_time(6.0)

	_assert_equal(_count_cards_by_definition(state, "card.output.feature"), 0, "Release should still consume the feature during Prod-Crash.")
	_assert_equal(_count_cards_by_definition(state, "card.resource.money"), money_before, "Prod-Crash should block release money.")

func _pay_and_start_next_sprint(controller: RunController, state: RunState) -> void:
	var developer: CardInstance = _find_card_by_definition(state, "card.employee.developer")
	var money: CardInstance = _find_card_by_definition(state, "card.resource.money")
	controller.advance_time(1.0)
	controller.move_card_to_stack(money.instance_id, developer.stack_id)
	controller.start_next_sprint()

func _create_controller(sprint_duration: float) -> RunController:
	var catalog: ContentCatalog = ContentCatalog.new()
	_assert_true(catalog.load_default_content(), "Default content should load.")
	catalog.balance = catalog.balance.duplicate(true) as BalanceDefinition
	catalog.balance.sprint_duration_seconds = sprint_duration
	return RunController.new(catalog)

func _spawn_card(controller: RunController, definition_id: String, position: Vector2) -> CardInstance:
	return controller.call("_spawn_card_as_new_stack", definition_id, position) as CardInstance

func _find_card_by_definition(state: RunState, definition_id: String) -> CardInstance:
	for card: CardInstance in state.cards.values():
		if card.definition_id == definition_id:
			return card
	_assert_true(false, "Missing card with definition '%s'." % definition_id)
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

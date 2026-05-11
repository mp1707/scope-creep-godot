extends SceneTree

var _failed: bool = false

func _init() -> void:
	_test_basic_recipe_starts()
	_test_coffee_adds_base_duration_progress()
	_test_three_coffees_complete_after_quarter_progress()
	_test_four_coffees_complete_running_work()
	_test_coffee_affects_product_owner_tester_external_dev_and_burnout_work()
	_test_coffee_does_not_affect_object_processing()
	_test_more_than_four_coffees_consume_only_four()
	_test_mixed_stack_does_not_trigger_processing_interaction()
	_test_neutral_extra_card_cancels_processing()
	_test_idea_to_feature_completion()
	_test_feature_to_money_completion()
	_test_ambiguous_matches_are_visible()

	if _failed:
		quit(1)
		return

	print("Phase 4 tests passed.")
	quit(0)

func _test_basic_recipe_starts() -> void:
	var controller: RunController = _create_controller()
	var state: RunState = controller.start_new_run(1)
	var developer: CardInstance = _find_card_by_definition(state, "card.employee.developer")
	var idea: CardInstance = _find_card_by_definition(state, "card.input.idea")

	controller.move_card_to_stack(idea.instance_id, developer.stack_id)

	var stack: StackState = state.get_stack(developer.stack_id)
	_assert_equal(stack.processing_state.active_recipe_id, "recipe.feature_from_idea.developer", "Developer + idea should start base feature recipe.")
	_assert_equal(stack.processing_state.status, ScopeEnums.ProcessingStatus.ACTIVE, "Matched recipe should become active.")
	_assert_equal(stack.processing_state.duration, 8.0, "Base feature recipe should use resource duration.")

func _test_coffee_adds_base_duration_progress() -> void:
	var controller: RunController = _create_controller()
	var state: RunState = controller.start_new_run(1)
	var developer: CardInstance = _find_card_by_definition(state, "card.employee.developer")
	var idea: CardInstance = _find_card_by_definition(state, "card.input.idea")
	var coffee: CardInstance = _find_card_by_definition(state, "card.consumable.coffee")

	controller.move_card_to_stack(idea.instance_id, developer.stack_id)
	controller.advance_time(4.0)
	controller.move_card_to_stack(coffee.instance_id, developer.stack_id)

	var stack: StackState = state.get_stack(developer.stack_id)
	_assert_equal(stack.processing_state.active_recipe_id, "recipe.feature_from_idea.developer", "Coffee should not change the active recipe.")
	_assert_float_equal(stack.processing_state.duration, 8.0, "Coffee should not change the recipe duration.")
	_assert_float_equal(stack.processing_state.elapsed, 6.0, "One coffee should add 25% of the base duration as progress.")
	_assert_equal(_count_cards_by_definition(state, "card.consumable.coffee"), 0, "Applied coffee should be consumed immediately.")

func _test_three_coffees_complete_after_quarter_progress() -> void:
	var controller: RunController = _create_controller()
	var state: RunState = controller.start_new_run(1)
	var developer: CardInstance = _find_card_by_definition(state, "card.employee.developer")
	var burnout: CardInstance = controller.call("_spawn_attached_card", developer.instance_id, "card.problem.burnout", "burnout") as CardInstance
	var coffee: CardInstance = _find_card_by_definition(state, "card.consumable.coffee")
	var coffee_2: CardInstance = _spawn_card(controller, "card.consumable.coffee", Vector2(1200.0, 360.0))
	var coffee_3: CardInstance = _spawn_card(controller, "card.consumable.coffee", Vector2(1400.0, 360.0))

	controller.move_card_to_stack(coffee_2.instance_id, coffee.stack_id)
	controller.move_card_to_stack(coffee_3.instance_id, coffee.stack_id)
	controller.advance_time(11.25)
	controller.move_card_to_stack(coffee.instance_id, developer.stack_id)

	var stack: StackState = state.get_stack(developer.stack_id)
	_assert_equal(burnout.parent_card_id, developer.instance_id, "Burnout should stay attached to the developer.")
	_assert_equal(stack.processing_state.status, ScopeEnums.ProcessingStatus.IDLE, "Three coffees after 25% progress should complete burnout recovery.")
	_assert_equal(_count_cards_by_definition(state, "card.consumable.coffee"), 0, "All three applied coffees should be consumed.")
	_assert_equal(_count_cards_by_definition(state, "card.problem.burnout"), 0, "Instant completion should execute burnout recovery effects.")

func _test_four_coffees_complete_running_work() -> void:
	var controller: RunController = _create_controller()
	var state: RunState = controller.start_new_run(1)
	var developer: CardInstance = _find_card_by_definition(state, "card.employee.developer")
	var idea: CardInstance = _find_card_by_definition(state, "card.input.idea")
	var coffee: CardInstance = _find_card_by_definition(state, "card.consumable.coffee")
	var coffee_2: CardInstance = _spawn_card(controller, "card.consumable.coffee", Vector2(1200.0, 360.0))
	var coffee_3: CardInstance = _spawn_card(controller, "card.consumable.coffee", Vector2(1400.0, 360.0))
	var coffee_4: CardInstance = _spawn_card(controller, "card.consumable.coffee", Vector2(1600.0, 360.0))

	controller.move_card_to_stack(coffee_2.instance_id, coffee.stack_id)
	controller.move_card_to_stack(coffee_3.instance_id, coffee.stack_id)
	controller.move_card_to_stack(coffee_4.instance_id, coffee.stack_id)
	controller.move_card_to_stack(idea.instance_id, developer.stack_id)
	controller.advance_time(1.0)
	controller.move_card_to_stack(coffee.instance_id, developer.stack_id)

	var stack: StackState = state.get_stack(developer.stack_id)
	_assert_equal(stack.processing_state.status, ScopeEnums.ProcessingStatus.IDLE, "Four coffees should complete active employee work immediately.")
	_assert_equal(_count_cards_by_definition(state, "card.input.idea"), 0, "Instant completion should execute recipe effects.")
	_assert_equal(_count_cards_by_definition(state, "card.output.feature"), 1, "Instant completion should spawn the recipe output.")
	_assert_equal(_count_cards_by_definition(state, "card.consumable.coffee"), 0, "The four applied coffees should be consumed.")

func _test_coffee_affects_product_owner_tester_external_dev_and_burnout_work() -> void:
	_assert_coffee_reduces_recipe_for_spawned_employee("card.employee.product_owner", "card.input.idea", "recipe.user_story_from_idea.product_owner")
	_assert_coffee_reduces_recipe_for_spawned_employee("card.employee.tester", "card.output.feature", "recipe.checked_feature_from_feature.tester")
	_assert_coffee_reduces_recipe_for_spawned_employee("card.employee.external_dev", "card.problem.bug", "recipe.debug_bug.external_dev")

	var controller: RunController = _create_controller()
	var state: RunState = controller.start_new_run(1)
	var developer: CardInstance = _find_card_by_definition(state, "card.employee.developer")
	controller.call("_spawn_attached_card", developer.instance_id, "card.problem.burnout", "burnout")
	var coffee: CardInstance = _find_card_by_definition(state, "card.consumable.coffee")
	controller.advance_time(5.0)
	controller.move_card_to_stack(coffee.instance_id, developer.stack_id)

	var stack: StackState = state.get_stack(developer.stack_id)
	_assert_equal(stack.processing_state.active_recipe_id, "recipe.burnout_recovery.employee", "Coffee should affect burnout recovery because it is employee work.")
	_assert_float_equal(stack.processing_state.elapsed, 16.25, "Coffee should add 25% of burnout recovery duration as progress.")

func _test_coffee_does_not_affect_object_processing() -> void:
	var controller: RunController = _create_controller()
	var state: RunState = controller.start_new_run(7)
	var developer: CardInstance = _find_card_by_definition(state, "card.employee.developer")
	var idea: CardInstance = _find_card_by_definition(state, "card.input.idea")
	var coffee: CardInstance = _find_card_by_definition(state, "card.consumable.coffee")

	controller.move_card_to_stack(idea.instance_id, developer.stack_id)
	controller.advance_time(8.0)

	var feature: CardInstance = _find_card_by_definition(state, "card.output.feature")
	var software: CardInstance = _find_card_by_definition(state, "card.product.software")
	controller.move_card_to_stack(feature.instance_id, software.stack_id)
	controller.advance_time(1.0)
	controller.move_card_to_stack(coffee.instance_id, software.stack_id)

	var stack: StackState = state.get_stack(software.stack_id)
	_assert_equal(coffee.stack_id, software.stack_id, "Coffee should normally stack onto ineligible object processing.")
	_assert_equal(stack.processing_state.active_recipe_id, "", "Coffee should not accelerate object processing and should follow neutral stack cancellation.")

func _test_more_than_four_coffees_consume_only_four() -> void:
	var controller: RunController = _create_controller()
	var state: RunState = controller.start_new_run(1)
	var developer: CardInstance = _find_card_by_definition(state, "card.employee.developer")
	var idea: CardInstance = _find_card_by_definition(state, "card.input.idea")
	var coffee: CardInstance = _find_card_by_definition(state, "card.consumable.coffee")

	for index: int in 4:
		var extra_coffee: CardInstance = _spawn_card(controller, "card.consumable.coffee", Vector2(1200.0 + float(index) * 180.0, 360.0))
		controller.move_card_to_stack(extra_coffee.instance_id, coffee.stack_id)

	controller.move_card_to_stack(idea.instance_id, developer.stack_id)
	controller.move_card_to_stack(coffee.instance_id, developer.stack_id)

	_assert_equal(_count_cards_by_definition(state, "card.consumable.coffee"), 1, "Only four coffees should be consumed per drop.")
	_assert_equal(_count_cards_by_definition(state, "card.output.feature"), 1, "Four applied coffees should complete the work.")

func _test_mixed_stack_does_not_trigger_processing_interaction() -> void:
	var controller: RunController = _create_controller()
	var state: RunState = controller.start_new_run(1)
	var developer: CardInstance = _find_card_by_definition(state, "card.employee.developer")
	var idea: CardInstance = _find_card_by_definition(state, "card.input.idea")
	var coffee: CardInstance = _find_card_by_definition(state, "card.consumable.coffee")
	var money: CardInstance = _find_card_by_definition(state, "card.resource.money")

	controller.move_card_to_stack(money.instance_id, coffee.stack_id)
	controller.move_card_to_stack(idea.instance_id, developer.stack_id)
	controller.advance_time(1.0)
	controller.move_card_to_stack(coffee.instance_id, developer.stack_id)

	var stack: StackState = state.get_stack(developer.stack_id)
	_assert_equal(coffee.stack_id, developer.stack_id, "Mixed stack should move normally.")
	_assert_equal(money.stack_id, developer.stack_id, "Mixed stack should move normally.")
	_assert_equal(stack.processing_state.active_recipe_id, "", "Mixed coffee stacks should not trigger the processing interaction.")

func _test_neutral_extra_card_cancels_processing() -> void:
	var controller: RunController = _create_controller()
	var state: RunState = controller.start_new_run(1)
	var developer: CardInstance = _find_card_by_definition(state, "card.employee.developer")
	var idea: CardInstance = _find_card_by_definition(state, "card.input.idea")
	var money: CardInstance = _find_card_by_definition(state, "card.resource.money")

	controller.move_card_to_stack(idea.instance_id, developer.stack_id)
	controller.advance_time(2.0)
	controller.move_card_to_stack(money.instance_id, developer.stack_id)

	var stack: StackState = state.get_stack(developer.stack_id)
	_assert_equal(stack.processing_state.active_recipe_id, "", "Neutral extra card should cancel the active recipe.")
	_assert_equal(stack.processing_state.status, ScopeEnums.ProcessingStatus.IDLE, "Cancelled processing should return to idle.")
	_assert_equal(stack.processing_state.elapsed, 0.0, "Cancelled processing should reset elapsed time.")

func _test_idea_to_feature_completion() -> void:
	var controller: RunController = _create_controller()
	var state: RunState = controller.start_new_run(1)
	var developer: CardInstance = _find_card_by_definition(state, "card.employee.developer")
	var idea: CardInstance = _find_card_by_definition(state, "card.input.idea")

	controller.move_card_to_stack(idea.instance_id, developer.stack_id)
	controller.advance_time(8.0)

	_assert_equal(_count_cards_by_definition(state, "card.input.idea"), 0, "Feature recipe should consume the idea.")
	_assert_equal(_count_cards_by_definition(state, "card.output.feature"), 1, "Feature recipe should spawn one feature.")
	_assert_equal(_count_cards_by_definition(state, "card.employee.developer"), 1, "Feature recipe should keep the developer.")

func _test_feature_to_money_completion() -> void:
	var controller: RunController = _create_controller()
	var state: RunState = controller.start_new_run(7)
	var developer: CardInstance = _find_card_by_definition(state, "card.employee.developer")
	var idea: CardInstance = _find_card_by_definition(state, "card.input.idea")

	controller.move_card_to_stack(idea.instance_id, developer.stack_id)
	controller.advance_time(8.0)

	var feature: CardInstance = _find_card_by_definition(state, "card.output.feature")
	var software: CardInstance = _find_card_by_definition(state, "card.product.software")
	controller.move_card_to_stack(feature.instance_id, software.stack_id)
	controller.advance_time(6.0)

	_assert_equal(_count_cards_by_definition(state, "card.output.feature"), 0, "Release recipe should consume the feature.")
	_assert_equal(_count_cards_by_definition(state, "card.product.software"), 1, "Release recipe should keep software.")
	_assert_equal(_count_cards_by_definition(state, "card.resource.money"), 4, "Release recipe should spawn one 1-money card.")

func _test_ambiguous_matches_are_visible() -> void:
	var controller: RunController = _create_controller()
	var state: RunState = controller.start_new_run(1)
	var developer: CardInstance = _find_card_by_definition(state, "card.employee.developer")
	var idea: CardInstance = _find_card_by_definition(state, "card.input.idea")
	controller.move_card_to_stack(idea.instance_id, developer.stack_id)
	var stack: StackState = state.get_stack(developer.stack_id)

	var catalog: ContentCatalog = ContentCatalog.new()
	_assert_true(catalog.load_default_content(), "Default content should load.")
	var base_recipe: RecipeDefinition = catalog.get_recipe_definition("recipe.feature_from_idea.developer")
	var duplicate_recipe: RecipeDefinition = base_recipe.duplicate(true) as RecipeDefinition
	duplicate_recipe.id = "recipe.feature_from_idea.developer_duplicate"
	catalog.recipes[duplicate_recipe.id] = duplicate_recipe

	var result: RecipeMatchResult = RecipeEngine.new().find_best_match(stack, state, catalog)
	_assert_true(result.is_ambiguous(), "Equal specificity and priority should be reported as ambiguous.")
	_assert_true(result.ambiguous_recipe_ids.has("recipe.feature_from_idea.developer"), "Ambiguous result should include original recipe.")
	_assert_true(result.ambiguous_recipe_ids.has("recipe.feature_from_idea.developer_duplicate"), "Ambiguous result should include duplicate recipe.")

func _create_controller() -> RunController:
	var catalog: ContentCatalog = ContentCatalog.new()
	_assert_true(catalog.load_default_content(), "Default content should load.")
	return RunController.new(catalog)

func _assert_coffee_reduces_recipe_for_spawned_employee(
	employee_definition_id: String,
	work_definition_id: String,
	expected_recipe_id: String
) -> void:
	var controller: RunController = _create_controller()
	var state: RunState = controller.start_new_run(1)
	var employee: CardInstance = _spawn_card(controller, employee_definition_id, Vector2(1200.0, 360.0))
	var work: CardInstance = _spawn_card(controller, work_definition_id, Vector2(1400.0, 360.0))
	var coffee: CardInstance = _find_card_by_definition(state, "card.consumable.coffee")

	controller.move_card_to_stack(work.instance_id, employee.stack_id)
	controller.advance_time(1.0)
	controller.move_card_to_stack(coffee.instance_id, employee.stack_id)

	var stack: StackState = state.get_stack(employee.stack_id)
	_assert_equal(stack.processing_state.active_recipe_id, expected_recipe_id, "Coffee should keep the active employee recipe.")
	_assert_true(stack.processing_state.elapsed > 1.0, "Coffee should add progress for '%s'." % expected_recipe_id)

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

func _assert_float_equal(actual: float, expected: float, message: String) -> void:
	if is_equal_approx(actual, expected):
		return
	_failed = true
	printerr("Assertion failed: %s Expected '%s', got '%s'." % [message, expected, actual])

extends SceneTree

var _failed: bool = false

func _init() -> void:
	_test_basic_recipe_starts()
	_test_specific_coffee_recipe_wins()
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

func _test_specific_coffee_recipe_wins() -> void:
	var controller: RunController = _create_controller()
	var state: RunState = controller.start_new_run(1)
	var developer: CardInstance = _find_card_by_definition(state, "card.employee.developer")
	var idea: CardInstance = _find_card_by_definition(state, "card.input.idea")
	var coffee: CardInstance = _find_card_by_definition(state, "card.consumable.coffee")

	controller.move_card_to_stack(idea.instance_id, developer.stack_id)
	controller.move_card_to_stack(coffee.instance_id, developer.stack_id)

	var stack: StackState = state.get_stack(developer.stack_id)
	_assert_equal(stack.processing_state.active_recipe_id, "recipe.feature_from_idea.developer_coffee", "Coffee recipe should beat the less specific base recipe.")
	_assert_equal(stack.processing_state.duration, 4.0, "Coffee recipe should use shorter duration.")

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

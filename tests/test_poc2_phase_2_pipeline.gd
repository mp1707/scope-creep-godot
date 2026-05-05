extends SceneTree

var _failed: bool = false

func _init() -> void:
	_test_idea_and_product_owner_create_user_story()
	_test_customer_request_and_product_owner_create_promising_user_story()
	_test_user_story_and_developer_create_feature()
	_test_promising_user_story_and_developer_create_feature()
	_test_feature_and_tester_create_checked_feature()
	_test_pipeline_recipe_order_is_irrelevant()
	_test_unrelated_extra_card_makes_stack_neutral()

	if _failed:
		quit(1)
		return

	print("PoC2 phase 2 pipeline tests passed.")
	quit(0)

func _test_idea_and_product_owner_create_user_story() -> void:
	var controller: RunController = _create_controller()
	var state: RunState = controller.start_new_run(201)
	var product_owner: CardInstance = _spawn_card(controller, "card.employee.product_owner", Vector2(420.0, 360.0))
	var idea: CardInstance = _find_card_by_definition(state, "card.input.idea")

	controller.move_card_to_stack(idea.instance_id, product_owner.stack_id)
	var stack: StackState = state.get_stack(product_owner.stack_id)
	_assert_equal(stack.processing_state.active_recipe_id, "recipe.user_story_from_idea.product_owner", "Idea + PO should start user story recipe.")
	_assert_equal(stack.processing_state.duration, 6.0, "PO recipe should use PoC2 planning duration.")

	controller.advance_time(6.0)
	_assert_equal(_count_cards_by_definition(state, "card.input.idea"), 0, "PO recipe should consume the idea.")
	_assert_equal(_count_cards_by_definition(state, "card.task.user_story"), 1, "PO recipe should spawn a user story.")
	_assert_equal(_count_cards_by_definition(state, "card.employee.product_owner"), 1, "PO recipe should keep the Product Owner.")

func _test_customer_request_and_product_owner_create_promising_user_story() -> void:
	var controller: RunController = _create_controller()
	var state: RunState = controller.start_new_run(202)
	var product_owner: CardInstance = _spawn_card(controller, "card.employee.product_owner", Vector2(420.0, 360.0))
	var customer_request: CardInstance = _spawn_card(controller, "card.input.customer_request", Vector2(620.0, 360.0))

	controller.move_card_to_stack(customer_request.instance_id, product_owner.stack_id)
	var stack: StackState = state.get_stack(product_owner.stack_id)
	_assert_equal(stack.processing_state.active_recipe_id, "recipe.promising_user_story_from_customer_request.product_owner", "Customer request + PO should start promising story recipe.")

	controller.advance_time(6.0)
	_assert_equal(_count_cards_by_definition(state, "card.input.customer_request"), 0, "Promising story recipe should consume the customer request.")
	_assert_equal(_count_cards_by_definition(state, "card.task.promising_user_story"), 1, "Promising story recipe should spawn a promising user story.")

func _test_user_story_and_developer_create_feature() -> void:
	var controller: RunController = _create_controller()
	var state: RunState = controller.start_new_run(203)
	var developer: CardInstance = _find_card_by_definition(state, "card.employee.developer")
	var user_story: CardInstance = _spawn_card(controller, "card.task.user_story", Vector2(620.0, 360.0))

	controller.move_card_to_stack(user_story.instance_id, developer.stack_id)
	var stack: StackState = state.get_stack(developer.stack_id)
	_assert_equal(stack.processing_state.active_recipe_id, "recipe.feature_from_user_story.developer", "User story + developer should start feature recipe.")

	controller.advance_time(8.0)
	_assert_equal(_count_cards_by_definition(state, "card.task.user_story"), 0, "Story feature recipe should consume the user story.")
	_assert_equal(_count_cards_by_definition(state, "card.output.feature"), 1, "Story feature recipe should spawn a feature.")

func _test_promising_user_story_and_developer_create_feature() -> void:
	var controller: RunController = _create_controller()
	var state: RunState = controller.start_new_run(204)
	var developer: CardInstance = _find_card_by_definition(state, "card.employee.developer")
	var promising_user_story: CardInstance = _spawn_card(controller, "card.task.promising_user_story", Vector2(620.0, 360.0))

	controller.move_card_to_stack(promising_user_story.instance_id, developer.stack_id)
	var stack: StackState = state.get_stack(developer.stack_id)
	_assert_equal(stack.processing_state.active_recipe_id, "recipe.feature_from_promising_user_story.developer", "Promising story + developer should start promising feature recipe.")

	controller.advance_time(8.0)
	_assert_equal(_count_cards_by_definition(state, "card.task.promising_user_story"), 0, "Promising story feature recipe should consume the promising story.")
	_assert_equal(_count_cards_by_definition(state, "card.output.feature"), 1, "Promising story feature recipe should spawn a feature.")

func _test_feature_and_tester_create_checked_feature() -> void:
	var controller: RunController = _create_controller()
	var state: RunState = controller.start_new_run(205)
	var tester: CardInstance = _spawn_card(controller, "card.employee.tester", Vector2(420.0, 360.0))
	var feature: CardInstance = _spawn_card(controller, "card.output.feature", Vector2(620.0, 360.0))

	controller.move_card_to_stack(feature.instance_id, tester.stack_id)
	var stack: StackState = state.get_stack(tester.stack_id)
	_assert_equal(stack.processing_state.active_recipe_id, "recipe.checked_feature_from_feature.tester", "Feature + tester should start checked feature recipe.")
	_assert_equal(stack.processing_state.duration, 7.0, "Tester recipe should use PoC2 testing duration.")

	controller.advance_time(7.0)
	_assert_equal(_count_cards_by_definition(state, "card.output.feature"), 0, "Tester recipe should consume the untested feature.")
	_assert_equal(_count_cards_by_definition(state, "card.output.checked_feature"), 1, "Tester recipe should spawn a checked feature.")
	_assert_equal(_count_cards_by_definition(state, "card.employee.tester"), 1, "Tester recipe should keep the tester.")

func _test_pipeline_recipe_order_is_irrelevant() -> void:
	var controller: RunController = _create_controller()
	var state: RunState = controller.start_new_run(206)
	var product_owner: CardInstance = _spawn_card(controller, "card.employee.product_owner", Vector2(420.0, 360.0))
	var idea: CardInstance = _find_card_by_definition(state, "card.input.idea")

	controller.move_card_to_stack(product_owner.instance_id, idea.stack_id)
	var stack: StackState = state.get_stack(idea.stack_id)
	_assert_equal(stack.processing_state.active_recipe_id, "recipe.user_story_from_idea.product_owner", "Recipe should match regardless of stack order.")

func _test_unrelated_extra_card_makes_stack_neutral() -> void:
	var controller: RunController = _create_controller()
	var state: RunState = controller.start_new_run(207)
	var product_owner: CardInstance = _spawn_card(controller, "card.employee.product_owner", Vector2(420.0, 360.0))
	var idea: CardInstance = _find_card_by_definition(state, "card.input.idea")
	var money: CardInstance = _find_card_by_definition(state, "card.resource.money")

	controller.move_card_to_stack(idea.instance_id, product_owner.stack_id)
	controller.advance_time(2.0)
	controller.move_card_to_stack(money.instance_id, product_owner.stack_id)

	var stack: StackState = state.get_stack(product_owner.stack_id)
	_assert_equal(stack.processing_state.active_recipe_id, "", "Unrelated extra card should make PoC2 pipeline stack neutral.")
	_assert_equal(stack.processing_state.status, ScopeEnums.ProcessingStatus.IDLE, "Neutral PoC2 stack should cancel processing.")

func _create_controller() -> RunController:
	var catalog: ContentCatalog = ContentCatalog.new()
	_assert_true(catalog.load_default_content(), "Default content should load.")
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

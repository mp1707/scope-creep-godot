extends SceneTree

var _failed: bool = false

func _init() -> void:
	_test_recipe_preview_marks_real_target()
	_test_payment_preview_respects_phase()
	_test_coffee_preview_marks_only_employee_processing()
	_test_feature_preview_marks_software_and_order_not_freelance()
	_test_money_preview_marks_freelance_order_shop()
	_test_recycling_preview_requires_three_recyclable_cards()
	_test_partial_money_preview_marks_expensive_shop_slot()
	_test_hidden_shop_slot_does_not_preview_payment()
	_test_preview_matches_controller_drop_query_for_all_stacks()

	if _failed:
		quit(1)
		return

	print("Drop interaction preview tests passed.")
	quit(0)

func _test_recipe_preview_marks_real_target() -> void:
	var controller: RunController = _create_controller(60.0)
	var state: RunState = _start_run_with_opened_startup(controller, 2000)
	var idea: CardInstance = _find_card_by_definition(state, "card.input.idea")
	var developer: CardInstance = _find_card_by_definition(state, "card.employee.developer")
	var money: CardInstance = _find_card_by_definition(state, "card.resource.money")

	var idea_preview: PackedStringArray = controller.get_drop_interaction_preview_stack_ids(idea.instance_id)
	_assert_true(idea_preview.has(developer.stack_id), "Idea should preview the developer as a recipe target.")
	_assert_true(not idea_preview.has(money.stack_id), "Idea should not preview unrelated money.")

	controller.move_card_to_stack(idea.instance_id, developer.stack_id)
	var money_preview: PackedStringArray = controller.get_drop_interaction_preview_stack_ids(money.instance_id)
	_assert_true(not money_preview.has(developer.stack_id), "Neutral money should not preview an active developer recipe stack.")

func _test_payment_preview_respects_phase() -> void:
	var sprint_controller: RunController = _create_controller(60.0)
	var sprint_state: RunState = _start_run_with_opened_startup(sprint_controller, 2001)
	var sprint_money: CardInstance = _find_top_card_by_definition(sprint_state, "card.resource.money")
	var sprint_developer: CardInstance = _find_card_by_definition(sprint_state, "card.employee.developer")
	var sprint_preview: PackedStringArray = sprint_controller.get_drop_interaction_preview_stack_ids(sprint_money.instance_id)
	_assert_true(not sprint_preview.has(sprint_developer.stack_id), "Money should not preview salary payment during the sprint phase.")

	var payment_controller: RunController = _create_controller(1.0)
	var payment_state: RunState = _start_run_with_opened_startup(payment_controller, 2002)
	payment_controller.advance_time(1.0)
	var payment_money: CardInstance = _find_top_card_by_definition(payment_state, "card.resource.money")
	var payment_developer: CardInstance = _find_card_by_definition(payment_state, "card.employee.developer")
	var payment_preview: PackedStringArray = payment_controller.get_drop_interaction_preview_stack_ids(payment_money.instance_id)
	_assert_true(payment_preview.has(payment_developer.stack_id), "Money should preview unpaid salary targets during payment.")

func _test_coffee_preview_marks_only_employee_processing() -> void:
	var controller: RunController = _create_controller(60.0)
	var state: RunState = _start_run_with_opened_startup(controller, 2003)
	var developer: CardInstance = _find_card_by_definition(state, "card.employee.developer")
	var idea: CardInstance = _find_card_by_definition(state, "card.input.idea")
	var coffee: CardInstance = _find_card_by_definition(state, "card.consumable.coffee")

	controller.move_card_to_stack(idea.instance_id, developer.stack_id)
	controller.advance_time(1.0)

	var coffee_preview: PackedStringArray = controller.get_drop_interaction_preview_stack_ids(coffee.instance_id)
	_assert_true(coffee_preview.has(developer.stack_id), "Coffee should preview active employee processing.")

	var object_controller: RunController = _create_controller(60.0)
	var object_state: RunState = _start_run_with_opened_startup(object_controller, 2004)
	var object_developer: CardInstance = _find_card_by_definition(object_state, "card.employee.developer")
	var object_idea: CardInstance = _find_card_by_definition(object_state, "card.input.idea")
	var object_coffee: CardInstance = _find_card_by_definition(object_state, "card.consumable.coffee")
	object_controller.move_card_to_stack(object_idea.instance_id, object_developer.stack_id)
	object_controller.advance_time(8.0)

	var feature: CardInstance = _find_card_by_definition(object_state, "card.output.feature")
	var software: CardInstance = _find_card_by_definition(object_state, "card.product.software")
	object_controller.move_card_to_stack(feature.instance_id, software.stack_id)
	object_controller.advance_time(1.0)

	var object_coffee_preview: PackedStringArray = object_controller.get_drop_interaction_preview_stack_ids(object_coffee.instance_id)
	_assert_true(not object_coffee_preview.has(software.stack_id), "Coffee should not preview active object processing.")

func _test_feature_preview_marks_software_and_order_not_freelance() -> void:
	var controller: RunController = _create_controller(60.0)
	var state: RunState = _start_run_with_opened_startup(controller, 2005)
	var feature: CardInstance = _spawn_card(controller, "card.output.feature", Vector2(1400.0, 320.0))
	var order: CardInstance = _spawn_card(controller, "card.value_source.order", Vector2(1450.0, 320.0))
	var software: CardInstance = _find_card_by_definition(state, "card.product.software")
	var freelance: CardInstance = _find_card_by_definition(state, "card.shop.freelance_order")

	var preview: PackedStringArray = controller.get_drop_interaction_preview_stack_ids(feature.instance_id)
	_assert_true(preview.has(software.stack_id), "Feature should preview software integration.")
	_assert_true(preview.has(order.stack_id), "Feature should preview visible order cards.")
	_assert_true(not preview.has(freelance.stack_id), "Feature should not preview the Freelance shop slot directly.")

func _test_money_preview_marks_freelance_order_shop() -> void:
	var controller: RunController = _create_controller(60.0)
	var state: RunState = _start_run_with_opened_startup(controller, 2010)
	var money: CardInstance = _find_top_card_by_definition(state, "card.resource.money")
	var freelance: CardInstance = _find_card_by_definition(state, "card.shop.freelance_order")

	var preview: PackedStringArray = controller.get_drop_interaction_preview_stack_ids(money.instance_id)
	_assert_true(preview.has(freelance.stack_id), "Money should preview the Freelance slot because it buys an order card.")

func _test_recycling_preview_requires_three_recyclable_cards() -> void:
	var controller: RunController = _create_controller(60.0)
	var state: RunState = _start_run_with_opened_startup(controller, 2006)
	var recycling_bin: CardInstance = _find_card_by_definition(state, "card.shop.recycling_bin")
	var first: CardInstance = _spawn_card(controller, "card.input.idea", Vector2(1600.0, 320.0))
	var second: CardInstance = _spawn_card(controller, "card.consumable.pizza_party", Vector2(1640.0, 320.0))
	var third: CardInstance = _spawn_card(controller, "card.consumable.stress_course", Vector2(1680.0, 320.0))

	var one_card_preview: PackedStringArray = controller.get_drop_interaction_preview_stack_ids(first.instance_id)
	_assert_true(not one_card_preview.has(recycling_bin.stack_id), "A single recyclable card should not preview recycling.")

	controller.move_card_to_stack(second.instance_id, first.stack_id)
	controller.move_card_to_stack(third.instance_id, first.stack_id)
	var three_card_preview: PackedStringArray = controller.get_drop_interaction_preview_stack_ids(first.instance_id)
	_assert_true(three_card_preview.has(recycling_bin.stack_id), "Three recyclable cards should preview the recycling bin.")

func _test_partial_money_preview_marks_expensive_shop_slot() -> void:
	var controller: RunController = _create_controller(60.0)
	var state: RunState = _start_run_with_opened_startup(controller, 2007)
	var money: CardInstance = _spawn_card(controller, "card.resource.money", Vector2(5000.0, 5000.0))
	var talent_pool: CardInstance = _find_card_by_definition(state, "card.shop.booster_slot.talent_pool")

	var preview: PackedStringArray = controller.get_drop_interaction_preview_stack_ids(money.instance_id)
	_assert_true(preview.has(talent_pool.stack_id), "One money card should preview the two-money Talent-Pool slot as a partial payment.")

func _test_hidden_shop_slot_does_not_preview_payment() -> void:
	var controller: RunController = _create_controller(60.0)
	var state: RunState = _start_run_with_opened_startup(controller, 2011)
	var money: CardInstance = _find_top_card_by_definition(state, "card.resource.money")
	var customer_chaos: CardInstance = _find_card_by_definition(state, "card.shop.booster_slot.customer_chaos")

	var preview: PackedStringArray = controller.get_drop_interaction_preview_stack_ids(money.instance_id)
	_assert_true(not preview.has(customer_chaos.stack_id), "Hidden shop slots should not preview payment.")

func _test_preview_matches_controller_drop_query_for_all_stacks() -> void:
	var controller: RunController = _create_controller(60.0)
	var state: RunState = _start_run_with_opened_startup(controller, 2008)
	var feature: CardInstance = _spawn_card(controller, "card.output.feature", Vector2(5300.0, 5000.0))
	var preview: PackedStringArray = controller.get_drop_interaction_preview_stack_ids(feature.instance_id)

	for stack: StackState in state.stacks.values():
		if stack.card_ids.has(feature.instance_id):
			continue
		var can_drop: bool = controller.can_move_card_to_stack(feature.instance_id, stack.stack_id)
		_assert_equal(preview.has(stack.stack_id), can_drop, "Preview should mirror the controller drop query for stack '%s'." % stack.stack_id)

func _create_controller(sprint_duration: float) -> RunController:
	var catalog: ContentCatalog = ContentCatalog.new()
	_assert_true(catalog.load_default_content(), "Default content should load.")
	if catalog.balance != null:
		catalog.balance = catalog.balance.duplicate(true)
		catalog.balance.sprint_duration_seconds = sprint_duration
	return RunController.new(catalog)

func _start_run_with_opened_startup(controller: RunController, run_seed: int) -> RunState:
	var state: RunState = controller.start_new_run(run_seed)
	var startup_pack: CardInstance = _find_card_by_definition(state, "card.resource.startup_booster_pack")
	while state.get_card(startup_pack.instance_id) != null:
		_assert_true(controller.open_booster_pack_step(startup_pack.instance_id), "Startup booster should open one card per step.")
	return state

func _spawn_card(controller: RunController, definition_id: String, position: Vector2) -> CardInstance:
	return controller.call("_spawn_card_as_new_stack", definition_id, position, false) as CardInstance

func _find_card_by_definition(state: RunState, definition_id: String) -> CardInstance:
	for card: CardInstance in state.cards.values():
		if card.definition_id == definition_id:
			return card
	_assert_true(false, "Missing card with definition '%s'." % definition_id)
	return null

func _find_top_card_by_definition(state: RunState, definition_id: String) -> CardInstance:
	for stack: StackState in state.stacks.values():
		for index: int in range(stack.card_ids.size() - 1, -1, -1):
			var card: CardInstance = state.get_card(stack.card_ids[index])
			if card != null and card.definition_id == definition_id:
				return card
	_assert_true(false, "Missing top card with definition '%s'." % definition_id)
	return null

func _assert_true(value: bool, message: String) -> void:
	if value:
		return
	_failed = true
	push_error(message)

func _assert_equal(actual: Variant, expected: Variant, message: String) -> void:
	if actual == expected:
		return
	_failed = true
	push_error("%s Expected '%s', got '%s'." % [message, str(expected), str(actual)])

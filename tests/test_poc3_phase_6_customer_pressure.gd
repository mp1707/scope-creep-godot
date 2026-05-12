extends SceneTree

const PRODUCT_STAGE_VALUE: String = "product_stage"
const PRODUCT_STAGE_LIVE: String = "live"

var _failed: bool = false

func _init() -> void:
	_test_old_customer_request_attaches_unhappy_to_random_satisfied_customer()
	_test_completed_customer_request_does_not_spawn_unhappy_customer()
	_test_all_customers_unhappy_makes_old_requests_noop()
	_test_product_owner_removes_attached_unhappy_customer()
	_test_unhappy_customers_do_not_quit_or_tick()
	_test_prod_crash_customer_tick_attaches_unhappy_customer()
	_test_developer_can_process_customer_request_slower_than_product_owner()

	if _failed:
		quit(1)
		return

	print("PoC3 phase 6 customer pressure tests passed.")
	quit(0)

func _test_old_customer_request_attaches_unhappy_to_random_satisfied_customer() -> void:
	var controller: RunController = _create_controller()
	var state: RunState = controller.start_new_run(3601)
	_make_live(controller)
	_remove_all_cards_by_definition(controller, state, "card.value_source.freelance_order")
	var first_customer: CardInstance = _spawn_card(controller, "card.value_source.customer", Vector2(860.0, 360.0))
	var second_customer: CardInstance = _spawn_card(controller, "card.value_source.customer", Vector2(1040.0, 360.0))
	var request: CardInstance = _spawn_card(controller, "card.input.customer_request", Vector2(1040.0, 360.0))
	request.values["spawned_sprint_index"] = state.sprint_index

	_enter_next_sprint(controller)

	var unhappy: CardInstance = _find_card_by_definition(state, "card.problem.unhappy_customer")
	_assert_equal(_count_cards_by_definition(state, "card.problem.unhappy_customer"), 1, "Old customer request should attach one Unzufrieden card.")
	_assert_true(unhappy.parent_card_id == first_customer.instance_id or unhappy.parent_card_id == second_customer.instance_id, "Unzufrieden should be attached to one existing customer.")
	_assert_equal(unhappy.attachment_slot, "unhappy_customer", "Unzufrieden should use the customer unhappy attachment slot.")
	_assert_true(unhappy.state.is_locked, "Attached Unzufrieden should be locked against mouse removal.")
	_assert_equal(_count_cards_by_definition(state, "card.input.customer_request"), 2, "Old request should remain and only the still-satisfied customer should spawn one new request.")

func _test_completed_customer_request_does_not_spawn_unhappy_customer() -> void:
	var controller: RunController = _create_controller()
	var state: RunState = controller.start_new_run(3602)
	_make_live(controller)
	_remove_all_cards_by_definition(controller, state, "card.value_source.freelance_order")
	_spawn_card(controller, "card.value_source.customer", Vector2(860.0, 360.0))
	var request: CardInstance = _spawn_card(controller, "card.input.customer_request", Vector2(1040.0, 360.0))
	request.values["spawned_sprint_index"] = state.sprint_index
	var product_owner: CardInstance = _spawn_card(controller, "card.employee.product_owner", Vector2(1220.0, 360.0))

	controller.move_card_to_stack(request.instance_id, product_owner.stack_id)
	controller.advance_time(6.0)
	_assert_equal(_count_cards_by_definition(state, "card.input.customer_request"), 0, "Customer request recipe should consume the request before sprint start.")

	_enter_next_sprint(controller)

	_assert_equal(_count_cards_by_definition(state, "card.problem.unhappy_customer"), 0, "Completed customer request should not create Unzufrieden.")

func _test_all_customers_unhappy_makes_old_requests_noop() -> void:
	var controller: RunController = _create_controller()
	var state: RunState = controller.start_new_run(3603)
	_make_live(controller)
	_remove_all_cards_by_definition(controller, state, "card.value_source.freelance_order")
	var customer: CardInstance = _spawn_card(controller, "card.value_source.customer", Vector2(860.0, 360.0))
	_spawn_attached_unhappy(controller, customer)
	var request: CardInstance = _spawn_card(controller, "card.input.customer_request", Vector2(1040.0, 360.0))
	request.values["spawned_sprint_index"] = state.sprint_index
	var money_before: int = _count_cards_by_definition(state, "card.resource.money")

	_enter_next_sprint(controller)

	_assert_equal(_count_cards_by_definition(state, "card.problem.unhappy_customer"), 1, "Old request should not add Unzufrieden when every customer is already unhappy.")
	_assert_equal(_count_cards_by_definition(state, "card.resource.money"), money_before - 1, "Unhappy customer should not generate money.")
	_assert_equal(_count_cards_by_definition(state, "card.input.customer_request"), 1, "Unhappy customer should not generate another customer request.")

func _test_product_owner_removes_attached_unhappy_customer() -> void:
	var controller: RunController = _create_controller()
	var state: RunState = controller.start_new_run(3604)
	var customer: CardInstance = _spawn_card(controller, "card.value_source.customer", Vector2(860.0, 360.0))
	var unhappy: CardInstance = _spawn_attached_unhappy(controller, customer)
	var product_owner: CardInstance = _spawn_card(controller, "card.employee.product_owner", Vector2(1040.0, 360.0))

	_assert_true(controller.split_stack_from_card(unhappy.instance_id, Vector2(1200.0, 360.0)) == null, "Attached Unzufrieden should not be manually split from its customer.")
	controller.move_card_to_stack(product_owner.instance_id, customer.stack_id)
	_assert_equal(state.get_stack(customer.stack_id).processing_state.active_recipe_id, "recipe.manage_unhappy_customer.product_owner", "Customer + attached Unzufrieden + PO should start expectation management.")
	controller.advance_time(8.0)

	_assert_equal(_count_cards_by_definition(state, "card.problem.unhappy_customer"), 0, "PO expectation management should remove attached Unzufrieden.")
	_assert_true(state.get_card(customer.instance_id) != null, "Customer should remain after expectation management.")
	_assert_true(state.get_card(product_owner.instance_id) != null, "PO should not be consumed by expectation management.")

func _test_unhappy_customers_do_not_quit_or_tick() -> void:
	var controller: RunController = _create_controller()
	var state: RunState = controller.start_new_run(3605)
	_make_live(controller)
	_remove_all_cards_by_definition(controller, state, "card.value_source.freelance_order")
	for index: int in 2:
		var customer: CardInstance = _spawn_card(controller, "card.value_source.customer", Vector2(860.0 + float(index) * 180.0, 360.0))
		_spawn_attached_unhappy(controller, customer)
	var money_before: int = _count_cards_by_definition(state, "card.resource.money")

	_enter_next_sprint(controller)

	_assert_equal(_count_cards_by_definition(state, "card.value_source.customer"), 2, "Unhappy customers should not quit.")
	_assert_equal(_count_cards_by_definition(state, "card.problem.unhappy_customer"), 2, "Unhappy attachments should remain until processed.")
	_assert_equal(_count_cards_by_definition(state, "card.resource.money"), money_before - 1, "Unhappy customers should not generate money.")
	_assert_equal(_count_cards_by_definition(state, "card.input.customer_request"), 0, "Unhappy customers should not generate requests.")

func _test_prod_crash_customer_tick_attaches_unhappy_customer() -> void:
	var controller: RunController = _create_controller()
	var state: RunState = controller.start_new_run(3606)
	_make_live(controller)
	_remove_all_cards_by_definition(controller, state, "card.value_source.freelance_order")
	for index: int in 2:
		_spawn_card(controller, "card.value_source.customer", Vector2(860.0 + float(index) * 180.0, 360.0))
	_spawn_card(controller, "card.problem.prod_crash", Vector2(1220.0, 360.0))
	var money_before: int = _count_cards_by_definition(state, "card.resource.money")

	_enter_next_sprint(controller)

	_assert_equal(_count_cards_by_definition(state, "card.resource.money"), money_before - 1, "Prod crash should still block customer money.")
	_assert_equal(_count_cards_by_definition(state, "card.input.customer_request"), 0, "Prod crash should block normal customer requests.")
	_assert_equal(_count_cards_by_definition(state, "card.problem.unhappy_customer"), 2, "Prod crash should attach Unzufrieden to each satisfied customer.")
	for unhappy: CardInstance in _find_cards_by_definition(state, "card.problem.unhappy_customer"):
		_assert_true(not unhappy.parent_card_id.is_empty(), "Prod crash Unzufrieden should be attached to a customer.")

func _test_developer_can_process_customer_request_slower_than_product_owner() -> void:
	var controller: RunController = _create_controller()
	var state: RunState = controller.start_new_run(3607)
	var request: CardInstance = _spawn_card(controller, "card.input.customer_request", Vector2(860.0, 360.0))
	var developer: CardInstance = _find_card_by_definition(state, "card.employee.developer")

	controller.move_card_to_stack(request.instance_id, developer.stack_id)
	var stack: StackState = state.get_stack(developer.stack_id)
	_assert_equal(stack.processing_state.active_recipe_id, "recipe.promising_user_story_from_customer_request.developer", "Customer request + developer should start the slower developer request recipe.")
	_assert_equal(stack.processing_state.duration, 9.0, "Developer request recipe should take 50 percent longer than the 6s PO recipe.")
	controller.advance_time(9.0)

	_assert_equal(_count_cards_by_definition(state, "card.input.customer_request"), 0, "Developer request recipe should consume the request.")
	_assert_equal(_count_cards_by_definition(state, "card.task.promising_user_story"), 1, "Developer request recipe should create a promising user story.")

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

func _spawn_card(controller: RunController, definition_id: String, position: Vector2) -> CardInstance:
	return controller.call("_spawn_card_as_new_stack", definition_id, position) as CardInstance

func _spawn_attached_unhappy(controller: RunController, customer: CardInstance) -> CardInstance:
	return controller.call("_spawn_attached_card", customer.instance_id, "card.problem.unhappy_customer", "unhappy_customer") as CardInstance

func _remove_all_cards_by_definition(controller: RunController, state: RunState, definition_id: String) -> void:
	for card: CardInstance in _find_cards_by_definition(state, definition_id):
		controller.call("_remove_card_instance", card.instance_id)

func _find_cards_by_definition(state: RunState, definition_id: String) -> Array[CardInstance]:
	var cards: Array[CardInstance] = []
	for card: CardInstance in state.cards.values():
		if card.definition_id == definition_id:
			cards.append(card)
	return cards

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

extends SceneTree

const PRODUCT_STAGE_VALUE: String = "product_stage"
const PRODUCT_STAGE_LIVE: String = "live"

var _failed: bool = false

func _init() -> void:
	_test_live_customers_spawn_money_and_requests_at_sprint_start()
	_test_prod_crash_blocks_customer_tick()
	_test_software_integration_still_does_not_spawn_money_after_launch()

	if _failed:
		quit(1)
		return

	print("PoC3 phase 5 customer income tests passed.")
	quit(0)

func _test_live_customers_spawn_money_and_requests_at_sprint_start() -> void:
	var controller: RunController = _create_controller()
	var state: RunState = controller.start_new_run(3501)
	controller.get_software_card().values[PRODUCT_STAGE_VALUE] = PRODUCT_STAGE_LIVE
	_remove_all_cards_by_definition(controller, state, "card.value_source.freelance_order")
	for index: int in 3:
		_spawn_card(controller, "card.value_source.customer", Vector2(860.0 + float(index) * 180.0, 360.0))
	var money_before: int = _count_cards_by_definition(state, "card.resource.money")
	var requests_before: int = _count_cards_by_definition(state, "card.input.customer_request")

	_enter_next_sprint(controller)

	_assert_equal(_count_cards_by_definition(state, "card.resource.money"), money_before - 1 + 3, "Three live customers should spawn three money cards after salary payment.")
	_assert_equal(_count_cards_by_definition(state, "card.input.customer_request"), requests_before + 3, "Three live customers should spawn three customer requests.")
	for request: CardInstance in _find_cards_by_definition(state, "card.input.customer_request"):
		_assert_equal(int(request.values.get("spawned_sprint_index", 0)), state.sprint_index, "Spawned customer requests should remember their sprint index.")

func _test_prod_crash_blocks_customer_tick() -> void:
	var controller: RunController = _create_controller()
	var state: RunState = controller.start_new_run(3502)
	controller.get_software_card().values[PRODUCT_STAGE_VALUE] = PRODUCT_STAGE_LIVE
	_remove_all_cards_by_definition(controller, state, "card.value_source.freelance_order")
	for index: int in 2:
		_spawn_card(controller, "card.value_source.customer", Vector2(860.0 + float(index) * 180.0, 360.0))
	_spawn_card(controller, "card.problem.prod_crash", Vector2(1220.0, 360.0))
	var money_before: int = _count_cards_by_definition(state, "card.resource.money")
	var requests_before: int = _count_cards_by_definition(state, "card.input.customer_request")

	_enter_next_sprint(controller)

	_assert_equal(_count_cards_by_definition(state, "card.resource.money"), money_before - 1, "Prod crash should block customer money after salary payment.")
	_assert_equal(_count_cards_by_definition(state, "card.input.customer_request"), requests_before, "Prod crash should block normal customer requests.")
	_assert_equal(_count_cards_by_definition(state, "card.problem.unhappy_customer"), 2, "Prod crash should attach Unzufrieden to each satisfied customer.")

func _test_software_integration_still_does_not_spawn_money_after_launch() -> void:
	var controller: RunController = _create_controller()
	var state: RunState = controller.start_new_run(3503)
	var software: CardInstance = controller.get_software_card()
	software.values[PRODUCT_STAGE_VALUE] = PRODUCT_STAGE_LIVE
	var feature: CardInstance = _spawn_card(controller, "card.output.feature", Vector2(860.0, 360.0))
	var money_before: int = _count_cards_by_definition(state, "card.resource.money")

	controller.move_card_to_stack(feature.instance_id, software.stack_id)
	controller.advance_time(6.0)

	_assert_equal(_count_cards_by_definition(state, "card.resource.money"), money_before, "Software should not directly create money after launch.")

func _enter_next_sprint(controller: RunController) -> void:
	controller.advance_time(60.0)
	_assert_true(controller.auto_pay_all_employees(), "Auto-pay should be possible before next sprint.")
	controller.start_next_sprint()

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

func _remove_all_cards_by_definition(controller: RunController, state: RunState, definition_id: String) -> void:
	for card: CardInstance in _find_cards_by_definition(state, definition_id):
		controller.call("_remove_card_instance", card.instance_id)

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

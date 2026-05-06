extends SceneTree

var _failed: bool = false

func _init() -> void:
	_test_customer_and_coffee_machine_spawn_at_sprint_start()
	_test_order_bonus_and_expiry()

	if _failed:
		quit(1)
		return

	print("PoC2 phase 6 value source tests passed.")
	quit(0)

func _test_customer_and_coffee_machine_spawn_at_sprint_start() -> void:
	var controller: RunController = _create_controller()
	var state: RunState = controller.start_new_run(601)
	_spawn_card(controller, "card.value_source.customer", Vector2(820.0, 360.0))
	_spawn_card(controller, "card.value_source.coffee_machine", Vector2(1020.0, 360.0))
	var requests_before: int = _count_cards_by_definition(state, "card.input.customer_request")
	var coffee_before: int = _count_cards_by_definition(state, "card.consumable.coffee")

	_enter_next_sprint(controller)

	_assert_equal(_count_cards_by_definition(state, "card.input.customer_request"), requests_before + 1, "Customer should spawn one customer request at sprint start.")
	_assert_equal(_count_cards_by_definition(state, "card.consumable.coffee"), coffee_before + 1, "Coffee machine should spawn one coffee at sprint start.")

func _test_order_bonus_and_expiry() -> void:
	var controller: RunController = _create_controller()
	var state: RunState = controller.start_new_run(602)
	state.content_version = "poc2"
	var order: CardInstance = _spawn_card(controller, "card.value_source.order", Vector2(820.0, 360.0))
	var feature: CardInstance = _spawn_card(controller, "card.output.feature", Vector2(1020.0, 360.0))
	var money_before: int = _count_cards_by_definition(state, "card.resource.money")

	controller.move_card_to_stack(feature.instance_id, order.stack_id)
	controller.advance_time(1.0)

	_assert_equal(_count_cards_by_definition(state, "card.value_source.order"), 0, "Fulfilled order should be consumed.")
	_assert_equal(_count_cards_by_definition(state, "card.output.feature"), 1, "Order bonus should not consume the feature.")
	_assert_equal(_count_cards_by_definition(state, "card.resource.money"), money_before + 2, "Order should spawn balance-defined bonus money.")

	_spawn_card(controller, "card.value_source.order", Vector2(1220.0, 360.0))
	_enter_next_sprint(controller)
	_assert_equal(_count_cards_by_definition(state, "card.value_source.order"), 0, "Unfulfilled order should expire at sprint start.")

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
	catalog.balance.order_bonus_money_cards = 2
	return RunController.new(catalog)

func _spawn_card(controller: RunController, definition_id: String, position: Vector2) -> CardInstance:
	return controller.call("_spawn_card_as_new_stack", definition_id, position) as CardInstance

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

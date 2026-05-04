extends SceneTree

var _failed: bool = false

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_money_on_booster_slot_creates_pack()
	_test_money_on_booster_pack_opens_three_pool_cards()
	_test_booster_draws_are_deterministic()

	if _failed:
		quit(1)
		return

	print("Phase 9 tests passed.")
	quit(0)

func _test_money_on_booster_slot_creates_pack() -> void:
	var controller: RunController = _create_controller()
	var state: RunState = controller.start_new_run(9)
	var booster_slot: CardInstance = _find_card_by_definition(state, "card.shop.booster_slot")
	var money: CardInstance = _find_card_by_definition(state, "card.resource.money")

	controller.move_card_to_stack(money.instance_id, booster_slot.stack_id)
	var stack: StackState = state.get_stack(booster_slot.stack_id)
	_assert_equal(stack.processing_state.active_recipe_id, "recipe.booster_pack_from_money.slot", "Money + booster slot should start the buy recipe.")

	controller.advance_time(1.0)

	_assert_equal(_count_cards_by_definition(state, "card.resource.money"), 2, "Buying a booster pack should consume exactly one 1-money card.")
	_assert_equal(_count_cards_by_definition(state, "card.resource.booster_pack"), 1, "Buying should spawn one booster pack.")
	_assert_equal(_count_cards_by_definition(state, "card.shop.booster_slot"), 1, "Booster slot should stay on the board.")

func _test_money_on_booster_pack_opens_three_pool_cards() -> void:
	var result: Dictionary = _open_founder_booster_and_get_result(21)
	var drawn_definitions: Array[String] = result["drawn_definitions"] as Array[String]
	var state: RunState = result["state"] as RunState

	_assert_equal(drawn_definitions.size(), 3, "Opening a booster should draw three cards.")
	_assert_equal(_count_cards_by_definition(state, "card.resource.booster_pack"), 0, "Opening should consume the booster pack.")
	for definition_id: String in drawn_definitions:
		_assert_true(_is_founder_pool_card(definition_id), "Drawn card should come from the founder booster pool: %s" % definition_id)

func _test_booster_draws_are_deterministic() -> void:
	var first: Dictionary = _open_founder_booster_and_get_result(44)
	var second: Dictionary = _open_founder_booster_and_get_result(44)

	_assert_equal(first["drawn_definitions"], second["drawn_definitions"], "Same seed should produce the same booster draw order.")
	_assert_equal(first["rng_state"], second["rng_state"], "Same seed should leave the same RNG state after opening.")

func _open_founder_booster_and_get_result(run_seed: int) -> Dictionary:
	var controller: RunController = _create_controller()
	var state: RunState = controller.start_new_run(run_seed)
	var booster_slot: CardInstance = _find_card_by_definition(state, "card.shop.booster_slot")
	var buy_money: CardInstance = _find_card_by_definition(state, "card.resource.money")

	controller.move_card_to_stack(buy_money.instance_id, booster_slot.stack_id)
	controller.advance_time(1.0)

	var booster_pack: CardInstance = _find_card_by_definition(state, "card.resource.booster_pack")
	var open_money: CardInstance = _find_card_by_definition(state, "card.resource.money")
	var existing_card_ids: Dictionary = {}
	for card_id: String in state.cards.keys():
		existing_card_ids[card_id] = true

	controller.move_card_to_stack(open_money.instance_id, booster_pack.stack_id)
	var stack: StackState = state.get_stack(booster_pack.stack_id)
	_assert_equal(stack.processing_state.active_recipe_id, "recipe.open_founder_booster.pack", "Money + booster pack should start the open recipe.")
	controller.advance_time(1.0)

	var new_card_ids: Array[String] = []
	for card_id: String in state.cards.keys():
		if not existing_card_ids.has(card_id):
			new_card_ids.append(card_id)
	new_card_ids.sort()

	var drawn_definitions: Array[String] = []
	for card_id: String in new_card_ids:
		var card: CardInstance = state.get_card(card_id)
		if card != null:
			drawn_definitions.append(card.definition_id)

	return {
		"drawn_definitions": drawn_definitions,
		"rng_state": state.rng_state,
		"state": state,
	}

func _is_founder_pool_card(definition_id: String) -> bool:
	return definition_id == "card.input.idea" \
		or definition_id == "card.consumable.coffee" \
		or definition_id == "card.resource.money"

func _create_controller() -> RunController:
	var catalog: ContentCatalog = ContentCatalog.new()
	_assert_true(catalog.load_default_content(), "Default content should load.")
	catalog.balance = catalog.balance.duplicate(true) as BalanceDefinition
	catalog.balance.sprint_duration_seconds = 60.0
	return RunController.new(catalog)

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

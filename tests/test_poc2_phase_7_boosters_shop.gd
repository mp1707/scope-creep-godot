extends SceneTree

var _failed: bool = false

func _init() -> void:
	_test_themed_booster_slots_create_matching_pack()
	_test_bugfix_patch_shop_buys_patch()
	_test_paused_multiple_shop_payments_queue_booster_purchases()
	_test_each_booster_draws_deterministically_from_own_pool()

	if _failed:
		quit(1)
		return

	print("PoC2 phase 7 booster/shop tests passed.")
	quit(0)

func _test_themed_booster_slots_create_matching_pack() -> void:
	_assert_slot_creates_booster("card.shop.booster_slot.talent_pool", "booster.talent_pool")
	_assert_slot_creates_booster("card.shop.booster_slot.office_invest", "booster.office_invest")
	_assert_slot_creates_booster("card.shop.booster_slot.customer_chaos", "booster.customer_chaos")

func _test_bugfix_patch_shop_buys_patch() -> void:
	var controller: RunController = _create_controller(703)
	var state: RunState = controller.start_new_run(703)
	var slot: CardInstance = _find_card_by_definition(state, "card.shop.bugfix_patch_slot")
	var money: CardInstance = _find_card_by_definition(state, "card.resource.money")
	var patches_before: int = _count_cards_by_definition(state, "card.consumable.bugfix_patch")

	controller.move_card_to_stack(money.instance_id, slot.stack_id)
	controller.advance_time(1.0)

	_assert_equal(_count_cards_by_definition(state, "card.consumable.bugfix_patch"), patches_before + 1, "Patch shop should spawn one Bugfix-Patch.")

func _test_paused_multiple_shop_payments_queue_booster_purchases() -> void:
	var controller: RunController = _create_controller(704)
	var state: RunState = controller.start_new_run(704)
	var slot: CardInstance = _find_card_by_definition(state, "card.shop.booster_slot.talent_pool")
	var money_ids: PackedStringArray = _find_card_ids_by_definition(state, "card.resource.money")
	controller.set_paused(true)

	controller.move_card_to_stack(money_ids[0], slot.stack_id)
	var stack: StackState = state.get_stack(slot.stack_id)
	_assert_equal(stack.processing_state.active_recipe_id, "recipe.booster_pack_from_money.slot", "First paused shop payment should start the buy recipe.")

	controller.move_card_to_stack(money_ids[1], slot.stack_id)
	_assert_equal(stack.processing_state.active_recipe_id, "recipe.booster_pack_from_money.slot", "Second paused shop payment should keep the buy recipe queued.")

	controller.set_paused(false)
	controller.advance_time(0.2)
	_assert_equal(_count_cards_by_definition(state, "card.resource.booster_pack"), 1, "First queued shop payment should spawn one booster pack after unpausing.")
	_assert_equal(stack.processing_state.active_recipe_id, "recipe.booster_pack_from_money.slot", "Remaining queued money should start the next shop purchase.")

	controller.advance_time(0.2)
	_assert_equal(_count_cards_by_definition(state, "card.resource.booster_pack"), 2, "Second queued shop payment should spawn a second booster pack.")
	_assert_equal(_count_cards_by_definition(state, "card.resource.money"), 1, "Two queued shop payments should consume exactly two money cards.")

func _test_each_booster_draws_deterministically_from_own_pool() -> void:
	for booster_id: String in ["booster.talent_pool", "booster.office_invest", "booster.customer_chaos", "booster.hot_fix_kit"]:
		var first: Array[String] = _open_booster_and_get_draws(booster_id, 777)
		var second: Array[String] = _open_booster_and_get_draws(booster_id, 777)
		_assert_equal(first, second, "Booster '%s' should draw deterministically for the same seed." % booster_id)
		for definition_id: String in first:
			_assert_true(_booster_pool_contains(booster_id, definition_id), "Booster '%s' drew outside its pool: %s" % [booster_id, definition_id])

func _assert_slot_creates_booster(slot_definition_id: String, booster_id: String) -> void:
	var controller: RunController = _create_controller(701)
	var state: RunState = controller.start_new_run(701)
	var slot: CardInstance = _find_card_by_definition(state, slot_definition_id)
	var money: CardInstance = _find_card_by_definition(state, "card.resource.money")

	controller.move_card_to_stack(money.instance_id, slot.stack_id)
	controller.advance_time(1.0)

	var pack: CardInstance = _find_card_by_definition(state, "card.resource.booster_pack")
	_assert_equal(pack.values.get("booster_definition_id", ""), booster_id, "Themed slot should stamp the bought booster pack.")

func _open_booster_and_get_draws(booster_id: String, run_seed: int) -> Array[String]:
	var controller: RunController = _create_controller(run_seed)
	var state: RunState = controller.start_new_run(run_seed)
	var pack: CardInstance = _spawn_card(controller, "card.resource.booster_pack", Vector2(920.0, 360.0))
	pack.values["booster_definition_id"] = booster_id
	var existing_card_ids: Dictionary = {}
	for card_id: String in state.cards.keys():
		existing_card_ids[card_id] = true

	controller.open_booster_pack_step(pack.instance_id)
	controller.open_booster_pack_step(pack.instance_id)
	controller.open_booster_pack_step(pack.instance_id)

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
	return drawn_definitions

func _booster_pool_contains(booster_id: String, definition_id: String) -> bool:
	var catalog: ContentCatalog = ContentCatalog.new()
	_assert_true(catalog.load_default_content(), "Default content should load.")
	var booster: BoosterDefinition = catalog.get_booster_definition(booster_id)
	if booster == null:
		return false
	for entry: BoosterPoolEntry in booster.pool_entries:
		if entry != null and entry.card_definition_id == definition_id:
			return true
	return false

func _create_controller(run_seed: int) -> RunController:
	var catalog: ContentCatalog = ContentCatalog.new()
	_assert_true(catalog.load_default_content(), "Default content should load.")
	catalog.balance = catalog.balance.duplicate(true) as BalanceDefinition
	catalog.balance.bug_chance = 0.0
	catalog.balance.tech_debt_chance = 0.0
	catalog.balance.burnout_increment_per_completed_work = 0.0
	var controller: RunController = RunController.new(catalog)
	controller.start_new_run(run_seed)
	return controller

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

func _find_card_ids_by_definition(state: RunState, definition_id: String) -> PackedStringArray:
	var card_ids: PackedStringArray = PackedStringArray()
	for card: CardInstance in state.cards.values():
		if card.definition_id == definition_id:
			card_ids.append(card.instance_id)
	_assert_true(card_ids.size() > 0, "Missing cards with definition '%s'." % definition_id)
	return card_ids

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

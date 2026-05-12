extends SceneTree

const FEATURE_COUNT_VALUE: String = "feature_count"

var _failed: bool = false

func _init() -> void:
	_test_poc3_start_setup_uses_scoped_shop_slots()
	_test_active_poc3_shop_slots_can_be_bought()
	_test_customer_chaos_slot_appears_after_launch()

	if _failed:
		quit(1)
		return

	print("PoC3 phase 8 shop scope tests passed.")
	quit(0)

func _test_poc3_start_setup_uses_scoped_shop_slots() -> void:
	var controller: RunController = _create_controller(3801)
	var state: RunState = controller.start_new_run(3801)

	_assert_equal(_count_cards_by_definition(state, "card.product.software"), 1, "PoC3 start should include one MVP software card.")
	_assert_equal(_count_cards_by_definition(state, "card.employee.developer"), 1, "PoC3 start should include one developer.")
	_assert_equal(_count_cards_by_definition(state, "card.input.idea"), 1, "PoC3 start should include one idea.")
	_assert_equal(_count_cards_by_definition(state, "card.consumable.coffee"), 1, "PoC3 start should include one coffee.")
	_assert_equal(_count_cards_by_definition(state, "card.value_source.freelance_order"), 1, "PoC3 start should include one freelance order.")
	_assert_equal(_count_cards_by_definition(state, "card.resource.money"), 30, "PoC3 playtest start should include 30 money cards.")
	_assert_equal(_count_cards_by_definition(state, "card.output.checked_feature"), 0, "PoC3 start should not include checked-feature launch scaffolding.")
	_assert_equal(_count_cards_by_definition(state, "card.shop.booster_slot"), 1, "PoC3 start should include Gründerpanik.")
	_assert_equal(_count_cards_by_definition(state, "card.shop.booster_slot.office_invest"), 1, "PoC3 start should include Wohlbefinden.")
	_assert_equal(_count_cards_by_definition(state, "card.shop.bugfix_patch_slot"), 1, "PoC3 start should include Externe Hilfe.")
	_assert_equal(_count_cards_by_definition(state, "card.shop.booster_slot.talent_pool"), 0, "Talent-Pool should not be active in the normal PoC3 start.")
	_assert_equal(_count_cards_by_definition(state, "card.shop.booster_slot.customer_chaos"), 0, "Kundenchaos should not be active before launch.")
	_assert_equal(_get_shop_order(state, "card.shop.booster_slot"), 10, "Gründerpanik should be the leftmost PoC3 shop slot.")
	_assert_equal(_get_shop_order(state, "card.shop.booster_slot.office_invest"), 20, "Wohlbefinden should be the second PoC3 shop slot.")
	_assert_equal(_get_shop_order(state, "card.shop.bugfix_patch_slot"), 30, "Externe Hilfe should be the third PoC3 shop slot.")

func _test_active_poc3_shop_slots_can_be_bought() -> void:
	_assert_slot_creates_booster("card.shop.booster_slot", "booster.founder.test_pack", 3802)
	_assert_slot_creates_booster("card.shop.booster_slot.office_invest", "booster.office_invest", 3803)
	_assert_patch_shop_creates_patch()

func _test_customer_chaos_slot_appears_after_launch() -> void:
	var controller: RunController = _create_controller(3805)
	var state: RunState = controller.start_new_run(3805)
	var software: CardInstance = _find_card_by_definition(state, "card.product.software")
	var developer: CardInstance = _find_card_by_definition(state, "card.employee.developer")
	software.values[FEATURE_COUNT_VALUE] = 10

	controller.move_card_to_stack(developer.instance_id, software.stack_id)
	controller.advance_time(4.0)

	_assert_equal(_count_cards_by_definition(state, "card.shop.booster_slot.customer_chaos"), 1, "Kundenchaos should become available after launch.")
	_assert_equal(_get_shop_order(state, "card.shop.booster_slot.customer_chaos"), 40, "Kundenchaos should be ordered after the initial PoC3 shop slots.")
	_assert_slot_creates_booster_in_state(controller, state, "card.shop.booster_slot.customer_chaos", "booster.customer_chaos")

func _assert_slot_creates_booster(slot_definition_id: String, booster_id: String, run_seed: int) -> void:
	var controller: RunController = _create_controller(run_seed)
	var state: RunState = controller.start_new_run(run_seed)
	_assert_slot_creates_booster_in_state(controller, state, slot_definition_id, booster_id)

func _assert_slot_creates_booster_in_state(controller: RunController, state: RunState, slot_definition_id: String, booster_id: String) -> void:
	var slot: CardInstance = _find_card_by_definition(state, slot_definition_id)
	var money: CardInstance = _find_card_by_definition(state, "card.resource.money")

	controller.move_card_to_stack(money.instance_id, slot.stack_id)
	controller.advance_time(1.0)

	var pack: CardInstance = _find_newest_card_by_definition(state, "card.resource.booster_pack")
	_assert_equal(pack.values.get("booster_definition_id", ""), booster_id, "PoC3 shop slot should stamp the bought booster pack.")

func _assert_patch_shop_creates_patch() -> void:
	var controller: RunController = _create_controller(3804)
	var state: RunState = controller.start_new_run(3804)
	var slot: CardInstance = _find_card_by_definition(state, "card.shop.bugfix_patch_slot")
	var money: CardInstance = _find_card_by_definition(state, "card.resource.money")
	var patches_before: int = _count_cards_by_definition(state, "card.consumable.bugfix_patch")

	controller.move_card_to_stack(money.instance_id, slot.stack_id)
	controller.advance_time(1.0)

	_assert_equal(_count_cards_by_definition(state, "card.consumable.bugfix_patch"), patches_before + 1, "Externe Hilfe should spawn one Bugfix (extern).")

func _create_controller(run_seed: int) -> RunController:
	var catalog: ContentCatalog = ContentCatalog.new()
	_assert_true(catalog.load_default_content(), "Default content should load.")
	catalog.balance = catalog.balance.duplicate(true) as BalanceDefinition
	catalog.balance.bug_chance = 0.0
	catalog.balance.tech_debt_chance = 0.0
	catalog.balance.burnout_increment_per_completed_work = 0.0
	return RunController.new(catalog)

func _find_card_by_definition(state: RunState, definition_id: String) -> CardInstance:
	for card: CardInstance in state.cards.values():
		if card.definition_id == definition_id:
			return card
	_assert_true(false, "Missing card with definition '%s'." % definition_id)
	return null

func _find_newest_card_by_definition(state: RunState, definition_id: String) -> CardInstance:
	var newest: CardInstance = null
	for card: CardInstance in state.cards.values():
		if card.definition_id != definition_id:
			continue
		if newest == null or card.instance_id > newest.instance_id:
			newest = card
	_assert_true(newest != null, "Missing card with definition '%s'." % definition_id)
	return newest

func _count_cards_by_definition(state: RunState, definition_id: String) -> int:
	var count: int = 0
	for card: CardInstance in state.cards.values():
		if card.definition_id == definition_id:
			count += 1
	return count

func _get_shop_order(state: RunState, definition_id: String) -> int:
	var card: CardInstance = _find_card_by_definition(state, definition_id)
	return int(card.values.get("shop_dock_order", -1))

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

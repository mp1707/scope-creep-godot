extends SceneTree

const FEATURE_COUNT_VALUE: String = "feature_count"

var _failed: bool = false

func _init() -> void:
	_test_quick_feature_integrates_without_money_and_can_spawn_bug()
	_test_checked_feature_integrates_without_bug_risk()

	if _failed:
		quit(1)
		return

	print("PoC3 phase 2 feature integration tests passed.")
	quit(0)

func _test_quick_feature_integrates_without_money_and_can_spawn_bug() -> void:
	var controller: RunController = _create_controller(1.0)
	var state: RunState = controller.start_new_run(3201)
	var software: CardInstance = controller.get_software_card()
	var feature: CardInstance = _spawn_card(controller, "card.output.feature", Vector2(820.0, 360.0))
	var money_before: int = _count_cards_by_definition(state, "card.resource.money")

	controller.move_card_to_stack(feature.instance_id, software.stack_id)
	_assert_equal(state.get_stack(software.stack_id).processing_state.active_recipe_id, "recipe.money_from_feature.software", "Feature + software should start integration recipe.")
	controller.advance_time(6.0)

	_assert_equal(int(software.values[FEATURE_COUNT_VALUE]), 1, "Integrated feature should increase software feature_count.")
	_assert_equal(_count_cards_by_definition(state, "card.output.feature"), 0, "Integrated feature should be consumed.")
	_assert_equal(_count_cards_by_definition(state, "card.resource.money"), money_before, "Software integration must not spawn money.")
	_assert_equal(_count_cards_by_definition(state, "card.problem.bug"), 1, "Unchecked integration should keep bug risk.")

func _test_checked_feature_integrates_without_bug_risk() -> void:
	var controller: RunController = _create_controller(1.0)
	var state: RunState = controller.start_new_run(3202)
	var software: CardInstance = controller.get_software_card()
	var checked_feature: CardInstance = _spawn_card(controller, "card.output.checked_feature", Vector2(820.0, 360.0))
	var money_before: int = _count_cards_by_definition(state, "card.resource.money")
	var checked_features_before: int = _count_cards_by_definition(state, "card.output.checked_feature")

	controller.move_card_to_stack(checked_feature.instance_id, software.stack_id)
	_assert_equal(state.get_stack(software.stack_id).processing_state.active_recipe_id, "recipe.money_from_checked_feature.software", "Checked feature + software should start checked integration recipe.")
	controller.advance_time(6.0)

	_assert_equal(int(software.values[FEATURE_COUNT_VALUE]), 1, "Checked integration should increase software feature_count.")
	_assert_equal(_count_cards_by_definition(state, "card.output.checked_feature"), checked_features_before - 1, "Checked integration should consume one checked feature.")
	_assert_equal(_count_cards_by_definition(state, "card.resource.money"), money_before, "Checked software integration must not spawn money.")
	_assert_equal(_count_cards_by_definition(state, "card.problem.bug"), 0, "Checked integration should not roll bug risk.")

func _create_controller(bug_chance: float) -> RunController:
	var catalog: ContentCatalog = ContentCatalog.new()
	_assert_true(catalog.load_default_content(), "Default content should load.")
	catalog.balance = catalog.balance.duplicate(true) as BalanceDefinition
	catalog.balance.bug_chance = bug_chance
	catalog.balance.tech_debt_chance = 0.0
	catalog.balance.burnout_increment_per_completed_work = 0.0
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

extends SceneTree

const CARD_SIZE: Vector2 = Vector2(144.0, 196.0)

var _failed: bool = false

func _init() -> void:
	_test_quick_feature_can_spawn_tech_debt()
	_test_promising_story_creates_higher_value_feature()
	_test_tester_copies_feature_value_to_checked_feature()
	_test_unchecked_release_uses_feature_value_and_can_spawn_bug()
	_test_checked_release_uses_feature_value_without_bug()
	_test_parallel_release_spawns_do_not_overlap()

	if _failed:
		quit(1)
		return

	print("PoC2 phase 3 release quality tests passed.")
	quit(0)

func _test_quick_feature_can_spawn_tech_debt() -> void:
	var controller: RunController = _create_controller(0.0, 1.0)
	var state: RunState = controller.start_new_run(301)
	var developer: CardInstance = _find_card_by_definition(state, "card.employee.developer")
	var idea: CardInstance = _find_card_by_definition(state, "card.input.idea")

	controller.move_card_to_stack(idea.instance_id, developer.stack_id)
	controller.advance_time(8.0)

	var feature: CardInstance = _find_card_by_definition(state, "card.output.feature")
	_assert_equal(feature.values["feature_value"], 1, "Quick feature should carry feature_value 1.")
	_assert_equal(feature.values["source_quality"], "quick", "Quick feature should be marked as quick source quality.")
	_assert_equal(feature.state.markers, PackedStringArray(["1"]), "Quick feature should expose its value as marker.")
	_assert_equal(_count_cards_by_definition(state, "card.problem.tech_debt"), 1, "Quick direct feature work should be able to spawn tech debt.")

func _test_promising_story_creates_higher_value_feature() -> void:
	var controller: RunController = _create_controller(0.0, 0.0)
	var state: RunState = controller.start_new_run(302)
	var developer: CardInstance = _find_card_by_definition(state, "card.employee.developer")
	var promising_story: CardInstance = _spawn_card(controller, "card.task.promising_user_story", Vector2(700.0, 360.0))

	controller.move_card_to_stack(promising_story.instance_id, developer.stack_id)
	controller.advance_time(8.0)

	var feature: CardInstance = _find_card_by_definition(state, "card.output.feature")
	_assert_equal(feature.values["feature_value"], 2, "Promising story should create a higher-value feature.")
	_assert_equal(feature.values["source_quality"], "promising", "Promising story feature should preserve source quality.")
	_assert_equal(feature.state.markers, PackedStringArray(["2"]), "Promising feature should expose value marker.")

func _test_tester_copies_feature_value_to_checked_feature() -> void:
	var controller: RunController = _create_controller(0.0, 0.0)
	var state: RunState = controller.start_new_run(303)
	var tester: CardInstance = _spawn_card(controller, "card.employee.tester", Vector2(520.0, 360.0))
	var feature: CardInstance = _spawn_card(controller, "card.output.feature", Vector2(700.0, 360.0))
	feature.values["feature_value"] = 2
	feature.values["source_quality"] = "promising"
	feature.state.markers = PackedStringArray(["2"])

	controller.move_card_to_stack(feature.instance_id, tester.stack_id)
	controller.advance_time(7.0)

	var checked_feature: CardInstance = _find_card_by_definition(state, "card.output.checked_feature")
	_assert_equal(checked_feature.values["feature_value"], 2, "Checked feature should copy feature_value.")
	_assert_equal(checked_feature.values["is_checked"], true, "Checked feature should set is_checked.")
	_assert_equal(checked_feature.values["source_quality"], "checked", "Checked feature should mark checked source quality.")
	_assert_equal(checked_feature.state.markers, PackedStringArray(["2"]), "Checked feature should expose copied value marker.")

func _test_unchecked_release_uses_feature_value_and_can_spawn_bug() -> void:
	var controller: RunController = _create_controller(1.0, 0.0)
	var state: RunState = controller.start_new_run(304)
	var software: CardInstance = _find_card_by_definition(state, "card.product.software")
	var feature: CardInstance = _spawn_card(controller, "card.output.feature", Vector2(700.0, 360.0))
	feature.values["feature_value"] = 2
	feature.state.markers = PackedStringArray(["2"])
	var money_before: int = _count_cards_by_definition(state, "card.resource.money")

	controller.move_card_to_stack(feature.instance_id, software.stack_id)
	controller.advance_time(6.0)

	_assert_equal(_count_cards_by_definition(state, "card.output.feature"), 0, "Unchecked release should consume feature.")
	_assert_equal(_count_cards_by_definition(state, "card.resource.money"), money_before + 2, "Unchecked release should spawn money equal to feature_value.")
	_assert_equal(_count_cards_by_definition(state, "card.problem.bug"), 1, "Unchecked release should be able to spawn a bug.")

func _test_checked_release_uses_feature_value_without_bug() -> void:
	var controller: RunController = _create_controller(1.0, 0.0)
	var state: RunState = controller.start_new_run(305)
	var software: CardInstance = _find_card_by_definition(state, "card.product.software")
	var checked_feature: CardInstance = _spawn_card(controller, "card.output.checked_feature", Vector2(700.0, 360.0))
	checked_feature.values["feature_value"] = 2
	checked_feature.values["is_checked"] = true
	checked_feature.state.markers = PackedStringArray(["2"])
	var money_before: int = _count_cards_by_definition(state, "card.resource.money")

	controller.move_card_to_stack(checked_feature.instance_id, software.stack_id)
	controller.advance_time(6.0)

	_assert_equal(_count_cards_by_definition(state, "card.output.checked_feature"), 0, "Checked release should consume checked feature.")
	_assert_equal(_count_cards_by_definition(state, "card.resource.money"), money_before + 2, "Checked release should spawn money equal to feature_value.")
	_assert_equal(_count_cards_by_definition(state, "card.problem.bug"), 0, "Checked release should not spawn release bugs.")

func _test_parallel_release_spawns_do_not_overlap() -> void:
	var controller: RunController = _create_controller(1.0, 0.0)
	var state: RunState = controller.start_new_run(306)
	var software: CardInstance = _find_card_by_definition(state, "card.product.software")
	var feature: CardInstance = _spawn_card(controller, "card.output.feature", Vector2(700.0, 360.0))
	feature.values["feature_value"] = 2
	var existing_card_ids: Dictionary = {}
	for card_id: String in state.cards.keys():
		existing_card_ids[card_id] = true

	controller.move_card_to_stack(feature.instance_id, software.stack_id)
	controller.advance_time(6.0)

	var spawned_cards: Array[CardInstance] = []
	for card_id: String in state.cards.keys():
		if not existing_card_ids.has(card_id):
			spawned_cards.append(state.get_card(card_id))
	_assert_equal(spawned_cards.size(), 3, "Release should spawn two money cards plus one bug in this setup.")

	for left_index: int in spawned_cards.size():
		for right_index: int in range(left_index + 1, spawned_cards.size()):
			var left_rect: Rect2 = Rect2(spawned_cards[left_index].position, CARD_SIZE)
			var right_rect: Rect2 = Rect2(spawned_cards[right_index].position, CARD_SIZE)
			_assert_true(not left_rect.intersects(right_rect), "Parallel release spawns should not overlap.")

func _create_controller(bug_chance: float, tech_debt_chance: float) -> RunController:
	var catalog: ContentCatalog = ContentCatalog.new()
	_assert_true(catalog.load_default_content(), "Default content should load.")
	catalog.balance = catalog.balance.duplicate(true) as BalanceDefinition
	catalog.balance.bug_chance = bug_chance
	catalog.balance.tech_debt_chance = tech_debt_chance
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

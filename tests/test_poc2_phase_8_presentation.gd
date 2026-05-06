extends SceneTree

var _failed: bool = false

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_card_view_keeps_runtime_details_in_tooltips_only()
	_test_card_view_hides_payment_and_burnout_markers()
	_test_attached_burnout_stays_opaque()
	_test_board_view_uses_recipe_action_text()
	_test_spawn_placement_spreads_multiple_cards()

	if _failed:
		quit(1)
		return

	print("PoC2 phase 8 presentation tests passed.")
	quit(0)

func _test_card_view_keeps_runtime_details_in_tooltips_only() -> void:
	var catalog: ContentCatalog = _load_catalog()
	var stack: StackState = _create_stack()
	var feature: CardInstance = _create_card("card.output.feature", stack.stack_id)
	feature.values["feature_value"] = 2
	feature.values["is_checked"] = false
	stack.card_ids.append(feature.instance_id)

	var view: CardView = _setup_card_view(feature, catalog.get_card_definition(feature.definition_id), stack)
	var marker: Label = view.get_node("MarkerLabel") as Label
	var short_text: Label = view.get_node("ShortTextLabel") as Label
	_assert_equal(marker.text, "W2", "Unchecked feature should show feature value marker.")
	_assert_true(not marker.visible, "Feature value marker should stay hidden on the card.")
	_assert_true(not short_text.visible, "Card short text should stay hidden on the card.")
	_assert_true(view.tooltip_text.contains("Wert: 2"), "Feature tooltip should include runtime value.")

	var checked: CardInstance = _create_card("card.output.checked_feature", stack.stack_id)
	checked.values["feature_value"] = 3
	checked.values["is_checked"] = true
	view.setup(checked, catalog.get_card_definition(checked.definition_id), stack)

	_assert_equal(marker.text, "OK3", "Checked feature should show checked value marker.")
	_assert_true(not marker.visible, "Checked feature marker should stay hidden on the card.")
	_assert_true(view.tooltip_text.contains("Status: geprueft"), "Checked feature tooltip should include checked status.")
	view.queue_free()

func _test_card_view_hides_payment_and_burnout_markers() -> void:
	var catalog: ContentCatalog = _load_catalog()
	var stack: StackState = _create_stack()
	var developer: CardInstance = _create_card("card.employee.developer", stack.stack_id)
	developer.state.is_payment_target = true
	stack.card_ids.append(developer.instance_id)

	var view: CardView = _setup_card_view(developer, catalog.get_card_definition(developer.definition_id), stack)
	var marker: Label = view.get_node("MarkerLabel") as Label
	_assert_equal(marker.text, "$", "Unpaid employee should show salary marker.")
	_assert_true(not marker.visible, "Salary marker should stay hidden on the card.")
	_assert_true(view.tooltip_text.contains("Gehalt offen"), "Payment target tooltip should explain salary.")

	developer.state.is_payment_target = false
	developer.state.is_paid = true
	view.setup(developer, catalog.get_card_definition(developer.definition_id), stack)
	_assert_equal(marker.text, "OK", "Paid employee should show paid marker.")
	_assert_true(not marker.visible, "Paid marker should stay hidden on the card.")

	developer.state.is_paid = false
	developer.state.markers = PackedStringArray(["BO"])
	view.setup(developer, catalog.get_card_definition(developer.definition_id), stack)
	_assert_equal(marker.text, "BO", "Employee with attached burnout should show burnout marker.")
	_assert_true(not marker.visible, "Burnout marker should stay hidden on the card.")
	view.queue_free()

func _test_attached_burnout_stays_opaque() -> void:
	var catalog: ContentCatalog = _load_catalog()
	var stack: StackState = _create_stack()
	var burnout: CardInstance = _create_card("card.problem.burnout", stack.stack_id)
	burnout.parent_card_id = "card_parent"
	burnout.attachment_slot = "burnout"
	burnout.state.is_locked = true

	var view: CardView = _setup_card_view(burnout, catalog.get_card_definition(burnout.definition_id), stack)
	_assert_equal(view.modulate.a, 1.0, "Attached burnout should not become semi-transparent.")
	view.queue_free()

func _test_board_view_uses_recipe_action_text() -> void:
	var controller: RunController = _create_controller(801)
	var state: RunState = controller.start_new_run(801)
	var developer: CardInstance = _find_card_by_definition(state, "card.employee.developer")
	var idea: CardInstance = _find_card_by_definition(state, "card.input.idea")
	controller.move_card_to_stack(idea.instance_id, developer.stack_id)

	var board: BoardView = BoardView.new()
	board.content = controller.content
	var stack: StackState = state.get_stack(developer.stack_id)
	var action_text: String = board.call("_get_stack_action_text", stack) as String
	_assert_equal(action_text, "Funktion bauen", "Board progress label should use recipe display_text.")
	board.queue_free()

func _test_spawn_placement_spreads_multiple_cards() -> void:
	var controller: RunController = _create_controller(802)
	var state: RunState = controller.start_new_run(802)
	var source: CardInstance = _find_card_by_definition(state, "card.product.software")
	var bounds: Rect2 = Rect2(Vector2(56.0, 56.0), state.board.size - Vector2(112.0, 112.0))
	var placed_rects: Array[Rect2] = []

	for index: int in 18:
		var position: Vector2 = controller.call("_get_spawn_position_near_stack", source.stack_id, index) as Vector2
		var rect: Rect2 = Rect2(position, Vector2(144.0, 196.0))
		_assert_true(bounds.encloses(rect), "Spawn position should stay inside board bounds.")
		for previous_rect: Rect2 in placed_rects:
			_assert_true(not rect.intersects(previous_rect), "Spawn placement should avoid previous spawn positions.")
		placed_rects.append(rect)

func _setup_card_view(card: CardInstance, definition: CardDefinition, stack: StackState) -> CardView:
	var view: CardView = CardView.new()
	get_root().add_child(view)
	view.setup(card, definition, stack)
	return view

func _load_catalog() -> ContentCatalog:
	var catalog: ContentCatalog = ContentCatalog.new()
	_assert_true(catalog.load_default_content(), "Default content should load.")
	return catalog

func _create_controller(run_seed: int) -> RunController:
	var catalog: ContentCatalog = _load_catalog()
	catalog.balance = catalog.balance.duplicate(true) as BalanceDefinition
	catalog.balance.bug_chance = 0.0
	catalog.balance.tech_debt_chance = 0.0
	catalog.balance.burnout_increment_per_completed_work = 0.0
	return RunController.new(catalog)

func _create_stack() -> StackState:
	var stack: StackState = StackState.new()
	stack.stack_id = "stack_test"
	stack.base_position = Vector2(320.0, 240.0)
	return stack

func _create_card(definition_id: String, stack_id: String) -> CardInstance:
	var card: CardInstance = CardInstance.new()
	card.instance_id = "card_test"
	card.definition_id = definition_id
	card.stack_id = stack_id
	return card

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

extends SceneTree

var _failed: bool = false

func _init() -> void:
	_test_board_builds_card_views()
	_test_stack_layout_offsets_cards()
	_test_snap_finds_near_stack()
	_test_dragging_upper_card_requests_split()

	if _failed:
		quit(1)
		return

	print("Phase 5 tests passed.")
	quit(0)

func _test_board_builds_card_views() -> void:
	var context: Dictionary = _create_bound_board()
	var board: BoardView = context["board"] as BoardView
	var state: RunState = context["state"] as RunState

	_assert_equal(board.get_child_count(), state.cards.size(), "BoardView should create one CardView per card.")
	for card_id: String in state.cards.keys():
		_assert_true(board.get_card_view(card_id) != null, "BoardView should expose created CardView.")

func _test_stack_layout_offsets_cards() -> void:
	var context: Dictionary = _create_bound_board()
	var board: BoardView = context["board"] as BoardView
	var controller: RunController = context["controller"] as RunController
	var state: RunState = context["state"] as RunState

	var developer: CardInstance = _find_card_by_definition(state, "card.employee.developer")
	var idea: CardInstance = _find_card_by_definition(state, "card.input.idea")
	controller.move_card_to_stack(idea.instance_id, developer.stack_id)
	board.apply_events(controller.drain_events())

	var developer_view: CardView = board.get_card_view(developer.instance_id)
	var idea_view: CardView = board.get_card_view(idea.instance_id)
	_assert_equal(idea_view.position, developer_view.position + board.stack_offset, "Stacked cards should share x and use vertical offset.")

func _test_snap_finds_near_stack() -> void:
	var context: Dictionary = _create_bound_board()
	var board: BoardView = context["board"] as BoardView
	var state: RunState = context["state"] as RunState

	var idea: CardInstance = _find_card_by_definition(state, "card.input.idea")
	var developer: CardInstance = _find_card_by_definition(state, "card.employee.developer")
	var developer_stack: StackState = state.get_stack(developer.stack_id)
	var snap_position: Vector2 = developer_stack.base_position + Vector2(board.card_size.x * 0.5, 4.0)
	var result: StackState = board.find_snap_stack(idea.instance_id, snap_position)

	_assert_true(result != null, "Snap should find a nearby target stack.")
	_assert_equal(result.stack_id, developer.stack_id, "Snap should choose the nearby developer stack.")

func _test_dragging_upper_card_requests_split() -> void:
	var context: Dictionary = _create_bound_board()
	var board: BoardView = context["board"] as BoardView
	var controller: RunController = context["controller"] as RunController
	var state: RunState = context["state"] as RunState

	var developer: CardInstance = _find_card_by_definition(state, "card.employee.developer")
	var idea: CardInstance = _find_card_by_definition(state, "card.input.idea")
	controller.move_card_to_stack(idea.instance_id, developer.stack_id)
	board.apply_events(controller.drain_events())

	var split_result: Dictionary = {
		"card_id": "",
		"position": Vector2.ZERO,
	}
	board.split_stack_requested.connect(func(card_id: String, position: Vector2) -> void:
		split_result["card_id"] = card_id
		split_result["position"] = position
	)

	board._on_card_drag_started(idea.instance_id, Vector2.ZERO)
	board._on_card_drag_ended(idea.instance_id, Vector2(3000.0, 2000.0))

	_assert_equal(split_result["card_id"], idea.instance_id, "Dragging an upper stack card to empty board should request a split.")
	_assert_equal(split_result["position"], Vector2(3000.0, 2000.0), "Split intent should keep the drop position.")

func _create_bound_board() -> Dictionary:
	var catalog: ContentCatalog = ContentCatalog.new()
	_assert_true(catalog.load_default_content(), "Default content should load.")
	var controller: RunController = RunController.new(catalog)
	var state: RunState = controller.start_new_run(1)
	var board: BoardView = BoardView.new()
	get_root().add_child(board)
	board.bind_run(state, catalog)
	return {
		"catalog": catalog,
		"controller": controller,
		"state": state,
		"board": board,
	}

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

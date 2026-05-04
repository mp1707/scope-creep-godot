extends SceneTree

var _failed: bool = false

func _init() -> void:
	_test_board_builds_card_views()
	_test_cards_show_name_and_tooltip_only()
	_test_stack_layout_offsets_cards()
	_test_snap_finds_near_stack()
	_test_dragging_upper_card_requests_split()
	_test_dragging_stack_to_stack_moves_whole_stack()

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

func _test_cards_show_name_and_tooltip_only() -> void:
	var context: Dictionary = _create_bound_board()
	var board: BoardView = context["board"] as BoardView
	var state: RunState = context["state"] as RunState
	var developer: CardInstance = _find_card_by_definition(state, "card.employee.developer")
	var developer_view: CardView = board.get_card_view(developer.instance_id)
	var title_label: Label = developer_view.get_node("TitleLabel") as Label
	var header_band: Control = developer_view.get_node("HeaderBand") as Control
	var short_text_label: Label = developer_view.get_node("ShortTextLabel") as Label
	var marker_label: Label = developer_view.get_node("MarkerLabel") as Label

	_assert_equal(title_label.text, "Entwickler", "Card face should show the display name.")
	_assert_true(header_band != null, "Card face should include a visible title band.")
	_assert_true(title_label.position.y + title_label.size.y <= board.stack_offset.y, "Card title should fit inside the visible stacked header area.")
	_assert_equal(short_text_label.visible, false, "Card face should not show explanatory text.")
	_assert_equal(marker_label.visible, false, "Card face should not show type abbreviations.")
	_assert_equal(developer_view.tooltip_text, "Baut Features", "Card tooltip should carry the explanation text.")

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

	var idea_view: CardView = board.get_card_view(idea.instance_id)
	var press_position: Vector2 = idea_view.position + Vector2(12.0, 12.0)
	var release_position: Vector2 = Vector2(3000.0, 2000.0)
	_send_mouse_button(board, press_position, true)
	_send_mouse_motion(board, release_position)
	_send_mouse_button(board, release_position, false)

	_assert_equal(split_result["card_id"], idea.instance_id, "Dragging an upper stack card to empty board should request a split.")
	_assert_equal(split_result["position"], release_position - Vector2(12.0, 12.0), "Split intent should keep the dropped card top-left position.")

func _test_dragging_stack_to_stack_moves_whole_stack() -> void:
	var context: Dictionary = _create_bound_board()
	var board: BoardView = context["board"] as BoardView
	var controller: RunController = context["controller"] as RunController
	var state: RunState = context["state"] as RunState

	var developer: CardInstance = _find_card_by_definition(state, "card.employee.developer")
	var idea: CardInstance = _find_card_by_definition(state, "card.input.idea")
	var software: CardInstance = _find_card_by_definition(state, "card.product.software")
	controller.move_card_to_stack(idea.instance_id, developer.stack_id)
	board.apply_events(controller.drain_events())

	controller.move_card_to_stack(developer.instance_id, software.stack_id)
	board.apply_events(controller.drain_events())

	var software_stack: StackState = state.get_stack(software.stack_id)
	_assert_true(software_stack.card_ids.has(developer.instance_id), "Dragging the base card of a stack onto another stack should move the base card.")
	_assert_true(software_stack.card_ids.has(idea.instance_id), "Dragging the base card of a stack onto another stack should move cards above it too.")

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

func _send_mouse_button(board: BoardView, board_position: Vector2, pressed: bool) -> void:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = board.get_global_transform_with_canvas() * board_position
	board._unhandled_input(event)

func _send_mouse_motion(board: BoardView, board_position: Vector2) -> void:
	var event: InputEventMouseMotion = InputEventMouseMotion.new()
	event.position = board.get_global_transform_with_canvas() * board_position
	board._unhandled_input(event)

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

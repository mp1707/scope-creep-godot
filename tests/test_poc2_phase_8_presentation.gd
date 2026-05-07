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
	_test_board_is_four_times_initial_viewport_area()
	_test_board_camera_clamps_and_zooms_to_full_board()
	_test_trackpad_pan_gesture_zooms_camera()
	_test_trackpad_magnify_gesture_zooms_camera()
	_test_empty_board_drag_requests_camera_pan()

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

func _test_board_is_four_times_initial_viewport_area() -> void:
	var controller: RunController = _create_controller(803)
	var state: RunState = controller.start_new_run(803)
	_assert_equal(state.board.size, BoardState.INITIAL_VIEWPORT_SIZE * 2.0, "Board should be twice as wide and high as the initial viewport.")
	_assert_equal(state.board.size.x * state.board.size.y, BoardState.INITIAL_VIEWPORT_SIZE.x * BoardState.INITIAL_VIEWPORT_SIZE.y * 4.0, "Board area should be four times the initial viewport area.")

func _test_board_camera_clamps_and_zooms_to_full_board() -> void:
	var board_state: BoardState = BoardState.new()
	var camera: BoardCamera = BoardCamera.new()
	get_root().add_child(camera)
	camera.bind_board(board_state)

	camera.call("_apply_zoom", 0.1)
	_assert_equal(camera.zoom, Vector2(0.5, 0.5), "Camera should zoom out far enough to show the whole default board.")

	camera.position = Vector2(-1000.0, -1000.0)
	camera.call("_clamp_and_persist")
	_assert_equal(camera.position, board_state.size * 0.5, "Zoomed-out camera should clamp to the board center when the full board is visible.")
	_assert_equal(board_state.camera_position, camera.position, "Camera should persist its position into BoardState.")
	_assert_equal(board_state.camera_zoom, camera.zoom, "Camera should persist its zoom into BoardState.")

	camera.queue_free()

func _test_trackpad_pan_gesture_zooms_camera() -> void:
	var board_state: BoardState = BoardState.new()
	var camera: BoardCamera = BoardCamera.new()
	get_root().add_child(camera)
	camera.bind_board(board_state)

	var pan_event: InputEventPanGesture = InputEventPanGesture.new()
	pan_event.delta = Vector2(0.0, 4.0)
	camera._unhandled_input(pan_event)

	_assert_true(camera.zoom.x < 1.0, "Trackpad pan gesture with positive vertical delta should zoom out.")
	_assert_equal(board_state.camera_zoom, camera.zoom, "Trackpad zoom should persist into BoardState.")

	camera.queue_free()

func _test_trackpad_magnify_gesture_zooms_camera() -> void:
	var board_state: BoardState = BoardState.new()
	var camera: BoardCamera = BoardCamera.new()
	get_root().add_child(camera)
	camera.bind_board(board_state)

	var magnify_event: InputEventMagnifyGesture = InputEventMagnifyGesture.new()
	magnify_event.factor = 1.2
	camera._unhandled_input(magnify_event)

	_assert_true(camera.zoom.x > 1.0, "Trackpad magnify gesture above 1 should zoom in.")
	_assert_true(camera.zoom.x <= 1.06, "Trackpad magnify gesture should stay deliberately low sensitivity.")
	_assert_equal(board_state.camera_zoom, camera.zoom, "Trackpad magnify zoom should persist into BoardState.")

	camera.queue_free()

func _test_empty_board_drag_requests_camera_pan() -> void:
	var board: BoardView = BoardView.new()
	get_root().add_child(board)
	var pan_result: Dictionary = {"relative": Vector2.ZERO}
	board.board_pan_requested.connect(func(relative: Vector2) -> void:
		pan_result["relative"] = relative
	)

	_send_viewport_mouse_button(board, Vector2(1700.0, 920.0), true)
	_send_viewport_mouse_motion(board, Vector2(1680.0, 912.0))
	_send_viewport_mouse_button(board, Vector2(1680.0, 912.0), false)

	_assert_equal(pan_result["relative"], Vector2(-20.0, -8.0), "Dragging empty board should request camera pan with viewport-relative movement.")
	board.queue_free()

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

func _send_viewport_mouse_button(board: BoardView, viewport_position: Vector2, pressed: bool) -> void:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = viewport_position
	board._unhandled_input(event)

func _send_viewport_mouse_motion(board: BoardView, viewport_position: Vector2) -> void:
	var event: InputEventMouseMotion = InputEventMouseMotion.new()
	event.position = viewport_position
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

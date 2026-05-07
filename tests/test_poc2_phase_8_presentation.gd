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
	_test_shop_cards_are_docked_and_not_rendered_on_board()
	_test_board_drag_can_drop_money_on_shop_dock()
	_test_application_drag_overlay_sits_above_shop_dock()

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

func _test_shop_cards_are_docked_and_not_rendered_on_board() -> void:
	var controller: RunController = _create_controller(804)
	var state: RunState = controller.start_new_run(804)
	var shop_card: CardInstance = _find_card_by_definition(state, "card.shop.booster_slot.talent_pool")
	var money: CardInstance = _find_card_by_definition(state, "card.resource.money")

	var board: BoardView = BoardView.new()
	get_root().add_child(board)
	board.bind_run(state, controller.content)
	board.apply_events(controller.drain_events())
	_assert_true(board.get_card_view(shop_card.instance_id) == null, "BoardView should not render shop cards as board cards.")
	_assert_true((board.get("_queued_visual_events") as Array).is_empty(), "Initial shop spawn events should not queue BoardView visual effects.")
	_assert_true(board.find_snap_stack(money.instance_id, state.get_stack(shop_card.stack_id).base_position) != state.get_stack(shop_card.stack_id), "Board snap should ignore hidden shop stacks.")

	var dock: Control = _create_shop_dock()
	get_root().add_child(dock)
	dock.call("bind_run", state, controller.content)
	var shop_view: CardView = dock.call("get_card_view", shop_card.instance_id) as CardView
	var viewport_height: float = dock.get_viewport().get_visible_rect().size.y
	_assert_true(shop_view != null, "ShopDockView should render shop cards.")
	_assert_true(shop_view.position.y >= viewport_height - (dock.get("visible_height") as float) - 0.01, "Shop cards should start only partially visible at the viewport bottom.")

	var base_y: float = shop_view.position.y
	dock.call("set_hovered_stack_id", shop_card.stack_id)
	_assert_equal(shop_view.position.y, base_y - (dock.get("hover_raise") as float), "Hovered shop card should raise to signal the active dropzone.")

	board.queue_free()
	dock.queue_free()

func _test_board_drag_can_drop_money_on_shop_dock() -> void:
	var controller: RunController = _create_controller(805)
	var state: RunState = controller.start_new_run(805)
	var money: CardInstance = _find_card_by_definition(state, "card.resource.money")
	var shop_card: CardInstance = _find_card_by_definition(state, "card.shop.booster_slot.talent_pool")

	var board: BoardView = BoardView.new()
	var dock: Control = _create_shop_dock()
	get_root().add_child(board)
	get_root().add_child(dock)
	board.bind_run(state, controller.content)
	dock.call("bind_run", state, controller.content)
	board.screen_drop_target_resolver = Callable(dock, "find_drop_stack_id")
	board.move_card_to_stack_requested.connect(func(card_id: String, target_stack_id: String) -> void:
		controller.move_card_to_stack(card_id, target_stack_id)
	)

	var money_view: CardView = board.get_card_view(money.instance_id)
	var shop_view: CardView = dock.call("get_card_view", shop_card.instance_id) as CardView
	var pointer_start: Vector2 = money_view.position + Vector2(8.0, 8.0)
	var pointer_drop: Vector2 = shop_view.position + Vector2(8.0, 8.0)

	board.call("_begin_drag", money.instance_id, pointer_start, pointer_start)
	board.call("_finish_drag", pointer_drop, pointer_drop)

	_assert_equal(money.stack_id, shop_card.stack_id, "Dropping a single money card on a docked shop card should move it into the shop stack.")
	_assert_true(board.get_card_view(money.instance_id) == null, "Money in a shop stack should not reappear on the board during buy processing.")

	board.queue_free()
	dock.queue_free()

func _test_application_drag_overlay_sits_above_shop_dock() -> void:
	var scene: PackedScene = ResourceLoader.load("res://scenes/application/Main.tscn") as PackedScene
	var app: MainApplication = scene.instantiate() as MainApplication
	get_root().add_child(app)

	var board: BoardView = app.get_board_view()
	var state: RunState = app.run_state
	var camera: BoardCamera = app.get_node("Camera2D") as BoardCamera
	camera.call("_apply_zoom", 0.5)
	var idea: CardInstance = _find_card_by_definition(state, "card.input.idea")
	var idea_view: CardView = board.get_card_view(idea.instance_id)
	var ui_layer: CanvasLayer = app.get_node("UiLayer") as CanvasLayer
	var overlay_layer: CanvasLayer = app.get_node("DragOverlayLayer") as CanvasLayer
	var screen_drag_layer: Control = app.get_node("DragOverlayLayer/ScreenDragLayer") as Control
	var press_position: Vector2 = idea_view.position + Vector2(12.0, 12.0)
	var viewport_press_position: Vector2 = board.get_global_transform_with_canvas() * press_position

	board.call("_begin_drag", idea.instance_id, press_position, viewport_press_position)

	_assert_true(overlay_layer.layer > ui_layer.layer, "Drag overlay should draw above the shop/HUD CanvasLayer.")
	_assert_true(idea_view.get_parent() == screen_drag_layer, "Dragged cards should move to the screen drag overlay while dragging.")
	_assert_equal(idea_view.scale, Vector2(0.5, 0.5), "Dragged cards in the screen overlay should keep the board camera zoom scale.")

	board.call("_finish_drag", press_position + Vector2(220.0, 0.0), viewport_press_position + Vector2(220.0, 0.0))
	_assert_equal(idea_view.scale, Vector2.ONE, "Dragged cards should reset to board-local scale after the drag ends.")
	app.queue_free()

func _setup_card_view(card: CardInstance, definition: CardDefinition, stack: StackState) -> CardView:
	var view: CardView = CardView.new()
	get_root().add_child(view)
	view.setup(card, definition, stack)
	return view

func _create_shop_dock() -> Control:
	var script: Script = ResourceLoader.load("res://scripts/presentation/shop_dock_view.gd") as Script
	return script.new() as Control

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

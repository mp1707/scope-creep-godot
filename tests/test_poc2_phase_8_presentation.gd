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
	_test_spawn_placement_reuses_freed_positions()
	_test_board_is_four_times_initial_viewport_area()
	_test_board_camera_clamps_and_zooms_to_full_board()
	_test_trackpad_pan_gesture_zooms_camera()
	_test_trackpad_magnify_gesture_zooms_camera()
	_test_empty_board_drag_requests_camera_pan()
	_test_shop_cards_are_docked_and_not_rendered_on_board()
	_test_board_drag_can_drop_money_on_shop_dock()
	_test_application_drag_overlay_sits_above_shop_dock()
	_test_zoomed_drag_lift_uses_screen_space_shadow_offset()
	_test_zoomed_drag_lift_resets_spawn_pivot_for_employee_cards()
	_test_zoomed_stack_drag_progress_stays_aligned_with_lifted_stack()
	_test_money_uses_specific_drop_and_stack_audio()
	_test_auto_stacked_spawn_events_request_stack_audio()

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
		controller.call("_spawn_card_as_new_stack", "card.problem.bug", position)
		var rect: Rect2 = Rect2(position, Vector2(144.0, 196.0))
		_assert_true(bounds.encloses(rect), "Spawn position should stay inside board bounds.")
		for previous_rect: Rect2 in placed_rects:
			_assert_true(not rect.intersects(previous_rect), "Spawn placement should avoid previous spawn positions.")
		placed_rects.append(rect)

func _test_spawn_placement_reuses_freed_positions() -> void:
	var controller: RunController = _create_controller(806)
	var state: RunState = controller.start_new_run(806)
	var source: CardInstance = _find_card_by_definition(state, "card.product.software")
	var first_position: Vector2 = controller.call("_get_spawn_position_near_stack", source.stack_id, 0) as Vector2
	var spawned_bug: CardInstance = controller.call("_spawn_card_as_new_stack", "card.problem.bug", first_position) as CardInstance

	controller.call("_remove_card_instance", spawned_bug.instance_id)
	var second_position: Vector2 = controller.call("_get_spawn_position_near_stack", source.stack_id, 0) as Vector2

	_assert_equal(second_position, first_position, "Spawn placement should reuse a freed position near the source stack.")

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
	var money_stack: StackState = state.get_stack(money.stack_id)
	money = state.get_card(money_stack.card_ids[money_stack.card_ids.size() - 1])
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

func _test_zoomed_drag_lift_uses_screen_space_shadow_offset() -> void:
	var scene: PackedScene = ResourceLoader.load("res://scenes/application/Main.tscn") as PackedScene
	var app: MainApplication = scene.instantiate() as MainApplication
	get_root().add_child(app)

	var board: BoardView = app.get_board_view()
	var state: RunState = app.run_state
	var camera: BoardCamera = app.get_node("Camera2D") as BoardCamera
	camera.call("_apply_zoom", 2.0)

	var idea: CardInstance = _find_card_by_definition(state, "card.input.idea")
	var idea_view: CardView = board.get_card_view(idea.instance_id)
	var shadow: Control = idea_view.get_node("DragShadow") as Control
	var original_position: Vector2 = idea_view.position
	var press_position: Vector2 = original_position + Vector2(12.0, 12.0)
	var viewport_press_position: Vector2 = board.call("_board_position_to_viewport", press_position) as Vector2
	var board_canvas_scale: Vector2 = board.call("_get_board_canvas_scale") as Vector2
	var expected_position: Vector2 = board.call(
		"_board_position_to_screen_drag_layer",
		original_position + idea_view.get_drag_lift_offset_for_canvas_scale(board_canvas_scale)
	) as Vector2
	var expected_shadow_anchor: Vector2 = board.call("_board_position_to_screen_drag_layer", original_position) as Vector2

	board.call("_begin_drag", idea.instance_id, press_position, viewport_press_position)

	_assert_vector_approx(idea_view.position, expected_position, 0.01, "Zoomed drag lift should stay at the screen-space shadow offset.")
	_assert_vector_approx(idea_view.position + shadow.position * idea_view.scale, expected_shadow_anchor, 0.01, "Zoomed drag shadow should remain anchored on the original card footprint.")
	_assert_vector_approx(shadow.position * idea_view.scale, CardView.DRAG_SHADOW_OFFSET, 0.01, "Zoomed drag shadow offset should not grow with camera zoom.")

	board.call("_finish_drag", press_position, viewport_press_position)
	app.queue_free()

func _test_zoomed_drag_lift_resets_spawn_pivot_for_employee_cards() -> void:
	var scene: PackedScene = ResourceLoader.load("res://scenes/application/Main.tscn") as PackedScene
	var app: MainApplication = scene.instantiate() as MainApplication
	get_root().add_child(app)

	var board: BoardView = app.get_board_view()
	var camera: BoardCamera = app.get_node("Camera2D") as BoardCamera
	camera.call("_apply_zoom", 2.0)

	var employee_definition_ids: PackedStringArray = PackedStringArray([
		"card.employee.product_owner",
		"card.employee.tester",
	])
	for index: int in employee_definition_ids.size():
		var spawned_card: CardInstance = app.controller.call(
			"_spawn_card_as_new_stack",
			employee_definition_ids[index],
			Vector2(720.0 + float(index) * 180.0, 540.0)
		) as CardInstance
		app.call("_apply_pending_events")

		var spawned_view: CardView = board.get_card_view(spawned_card.instance_id)
		var shadow: Control = spawned_view.get_node("DragShadow") as Control
		spawned_view.play_spawn_pop()
		_assert_equal(spawned_view.pivot_offset, CardView.DEFAULT_CARD_SIZE * 0.5, "Spawn pop should temporarily use a center pivot.")

		var original_position: Vector2 = spawned_view.position
		var press_position: Vector2 = original_position + Vector2(12.0, 12.0)
		var viewport_press_position: Vector2 = board.call("_board_position_to_viewport", press_position) as Vector2
		var board_canvas_scale: Vector2 = board.call("_get_board_canvas_scale") as Vector2
		var expected_position: Vector2 = board.call(
			"_board_position_to_screen_drag_layer",
			original_position + spawned_view.get_drag_lift_offset_for_canvas_scale(board_canvas_scale)
		) as Vector2
		var expected_shadow_anchor: Vector2 = board.call("_board_position_to_screen_drag_layer", original_position) as Vector2

		board.call("_begin_drag", spawned_card.instance_id, press_position, viewport_press_position)

		_assert_equal(spawned_view.pivot_offset, Vector2.ZERO, "Dragging a spawned card should restore top-left pivot positioning.")
		_assert_vector_approx(spawned_view.position, expected_position, 0.01, "Zoomed spawned employee drag lift should stay at the shadow offset.")
		_assert_vector_approx(spawned_view.position + shadow.position * spawned_view.scale, expected_shadow_anchor, 0.01, "Zoomed spawned employee shadow should stay on the old footprint.")

		board.call("_finish_drag", press_position, viewport_press_position)

	app.queue_free()

func _test_zoomed_stack_drag_progress_stays_aligned_with_lifted_stack() -> void:
	var scene: PackedScene = ResourceLoader.load("res://scenes/application/Main.tscn") as PackedScene
	var app: MainApplication = scene.instantiate() as MainApplication
	get_root().add_child(app)

	var board: BoardView = app.get_board_view()
	var state: RunState = app.run_state
	var camera: BoardCamera = app.get_node("Camera2D") as BoardCamera
	camera.call("_apply_zoom", 2.0)

	var developer: CardInstance = _find_card_by_definition(state, "card.employee.developer")
	var idea: CardInstance = _find_card_by_definition(state, "card.input.idea")
	app.call("request_move_card_to_stack", idea.instance_id, developer.stack_id)
	app.call("advance_run", 0.25)

	var developer_view: CardView = board.get_card_view(developer.instance_id)
	var progress_view: Control = board.get_stack_progress_view(developer.stack_id)
	var original_position: Vector2 = developer_view.position
	var press_position: Vector2 = original_position + Vector2(20.0, 10.0)
	var viewport_press_position: Vector2 = board.call("_board_position_to_viewport", press_position) as Vector2
	var board_canvas_scale: Vector2 = board.call("_get_board_canvas_scale") as Vector2
	var lifted_base_position: Vector2 = original_position + developer_view.get_drag_lift_offset_for_canvas_scale(board_canvas_scale)
	var expected_progress_position: Vector2 = board.call(
		"_board_position_to_screen_drag_layer",
		lifted_base_position + BoardView.PROGRESS_OFFSET
	) as Vector2

	board.call("_begin_drag", developer.instance_id, press_position, viewport_press_position)

	_assert_vector_approx(progress_view.position, expected_progress_position, 0.01, "Zoomed stack drag should keep progress overlay aligned to the lifted stack.")
	_assert_vector_approx(progress_view.scale, board.call("_get_screen_drag_scale") as Vector2, 0.01, "Dragged progress overlay should use the same screen scale as dragged cards.")
	_assert_vector_approx(progress_view.position + Vector2(0.0, -BoardView.PROGRESS_OFFSET.y) * progress_view.scale, developer_view.position, 0.01, "Progress overlay should remain centered above the dragged stack card.")

	board.call("_finish_drag", press_position, viewport_press_position)
	app.queue_free()

func _test_money_uses_specific_drop_and_stack_audio() -> void:
	var catalog: ContentCatalog = _load_catalog()
	var money_definition: CardDefinition = catalog.get_card_definition("card.resource.money")
	var money_audio: CardAudioDefinition = money_definition.audio
	var audio_player: BoardAudioPlayer = BoardAudioPlayer.new()

	_assert_true(money_audio != null, "Money should define card-specific audio overrides.")
	_assert_true(money_audio.drop_stream != null, "Money should override single-card drop audio.")
	_assert_true(money_audio.stack_stream != null, "Money should override stack-drop audio.")
	_assert_equal(audio_player.call("_get_drop_stream", money_definition), money_audio.drop_stream, "Money drop should use money_place.wav.")
	_assert_equal(audio_player.call("_get_stack_stream", money_definition), money_audio.stack_stream, "Money stack-drop should use money_stack.wav.")
	_assert_equal(audio_player.call("_get_drag_stream", money_definition), audio_player.default_drag_stream, "Money drag should fall back to the default drag audio.")
	_assert_equal(audio_player.call("_get_create_stream", money_definition), audio_player.default_create_stream, "Money create should fall back to the default create audio.")
	_assert_equal(audio_player.call("_get_destroy_stream", money_definition), audio_player.default_destroy_stream, "Money destroy should fall back to the default destroy audio.")

func _test_auto_stacked_spawn_events_request_stack_audio() -> void:
	var controller: RunController = _create_controller(807)
	var state: RunState = controller.start_new_run(807)
	controller.drain_events()

	var money: CardInstance = _find_card_by_definition(state, "card.resource.money")
	var money_stack: StackState = state.get_stack(money.stack_id)
	var spawned_money: CardInstance = controller.call("_spawn_card_as_new_stack", "card.resource.money", money_stack.base_position) as CardInstance
	var spawned_bug: CardInstance = controller.call("_spawn_card_as_new_stack", "card.problem.bug", Vector2(1440.0, 720.0)) as CardInstance
	var events: Array[SimulationEvent] = controller.drain_events()
	var money_spawn_event: SimulationEvent = _find_spawn_event(events, spawned_money.instance_id)
	var bug_spawn_event: SimulationEvent = _find_spawn_event(events, spawned_bug.instance_id)

	_assert_true(money_spawn_event.was_stacked_on_spawn, "Auto-stacked money spawn should request stack audio.")
	_assert_true(not bug_spawn_event.was_stacked_on_spawn, "Fresh non-stacked spawn should request create audio.")

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

func _find_spawn_event(events: Array[SimulationEvent], card_id: String) -> SimulationEvent:
	for event: SimulationEvent in events:
		if event.type == ScopeEnums.SimulationEventType.CARD_SPAWNED and event.card_id == card_id:
			return event
	_assert_true(false, "Missing spawn event for card '%s'." % card_id)
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

func _assert_vector_approx(actual: Vector2, expected: Vector2, tolerance: float, message: String) -> void:
	if actual.distance_to(expected) <= tolerance:
		return
	_failed = true
	printerr("Assertion failed: %s Expected approximately '%s', got '%s'." % [message, expected, actual])

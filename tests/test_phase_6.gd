extends SceneTree

const CARD_SIZE: Vector2 = Vector2(144.0, 196.0)

var _failed: bool = false

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_application_bootstrap_binds_board()
	_test_card_view_controls_do_not_consume_mouse()
	_test_board_mouse_input_drags_card_to_stack()
	_test_frame_tick_does_not_reset_drag_preview()
	_test_active_stack_tick_does_not_reset_drag_preview()
	_test_empty_board_drop_uses_free_preview_position()
	_test_non_recipe_cards_can_be_stacked()
	_test_stack_drag_preview_moves_all_cards()
	_test_dropped_card_draws_above_target_card()
	_test_dropped_stack_draws_above_all_other_cards()
	_test_repeated_drags_keep_drag_layer_above_board_cards()
	await _test_board_audio_player_uses_imported_stream_resources()
	_test_board_view_preserves_editor_audio_child_on_rebuild()
	_test_editor_pipeline_updates_progress_and_spawns_feature()
	_test_feature_release_spawns_money_without_covering_stack()

	if _failed:
		quit(1)
		return

	print("Phase 6 tests passed.")
	quit(0)

func _test_application_bootstrap_binds_board() -> void:
	var app: Node = _create_app()
	var board: BoardView = app.call("get_board_view") as BoardView
	_assert_true(app.content != null, "Application should load content.")
	_assert_true(app.controller != null, "Application should create a RunController.")
	_assert_true(app.run_state != null, "Application should start a run.")
	_assert_equal(board.state, app.run_state, "BoardView should bind to the application RunState.")
	_assert_equal(board.content, app.content, "BoardView should bind to the application ContentCatalog.")
	for card_id: String in app.run_state.cards.keys():
		_assert_true(board.get_card_view(card_id) != null, "BoardView should create card views for the start run.")
	app.queue_free()

func _test_card_view_controls_do_not_consume_mouse() -> void:
	var app: Node = _create_app()
	var state: RunState = app.run_state
	var board: BoardView = app.call("get_board_view") as BoardView
	var idea: CardInstance = _find_card_by_definition(state, "card.input.idea")
	var idea_view: CardView = board.get_card_view(idea.instance_id)
	var drag_shadow: Panel = idea_view.get_node("DragShadow") as Panel

	_assert_equal(idea_view.mouse_filter, Control.MOUSE_FILTER_PASS, "CardView root should allow tooltip hover without accepting drag input.")
	_assert_true(drag_shadow != null, "CardView drag shadow should use a rounded Panel.")
	_assert_true(drag_shadow.has_theme_stylebox_override("panel"), "CardView drag shadow should have a custom opaque rounded style.")
	for child: Node in idea_view.get_children():
		if child is Control:
			var control: Control = child as Control
			_assert_equal(control.mouse_filter, Control.MOUSE_FILTER_IGNORE, "CardView child '%s' should not consume mouse input." % control.name)
	app.queue_free()

func _test_board_mouse_input_drags_card_to_stack() -> void:
	var app: Node = _create_app()
	var state: RunState = app.run_state
	var board: BoardView = app.call("get_board_view") as BoardView
	var developer: CardInstance = _find_card_by_definition(state, "card.employee.developer")
	var idea: CardInstance = _find_card_by_definition(state, "card.input.idea")
	var idea_view: CardView = board.get_card_view(idea.instance_id)
	var developer_stack: StackState = state.get_stack(developer.stack_id)

	var press_position: Vector2 = idea_view.position + CARD_SIZE * 0.5
	var release_position: Vector2 = developer_stack.base_position + Vector2(CARD_SIZE.x * 0.5, 4.0)
	_send_mouse_button(board, press_position, true)
	_send_mouse_motion(board, release_position)
	_send_mouse_button(board, release_position, false)

	_assert_equal(idea.stack_id, developer.stack_id, "World-space mouse input should drag idea onto developer stack.")
	_assert_equal(state.get_stack(developer.stack_id).processing_state.active_recipe_id, "recipe.feature_from_idea.developer", "Dropping idea on developer via mouse input should start processing.")
	app.queue_free()

func _test_frame_tick_does_not_reset_drag_preview() -> void:
	var app: Node = _create_app()
	var state: RunState = app.run_state
	var board: BoardView = app.call("get_board_view") as BoardView
	var idea: CardInstance = _find_card_by_definition(state, "card.input.idea")
	var idea_view: CardView = board.get_card_view(idea.instance_id)

	var original_position: Vector2 = idea_view.position
	var press_position: Vector2 = original_position + CARD_SIZE * 0.5
	var drag_position: Vector2 = press_position + Vector2(96.0, -72.0)
	_send_mouse_button(board, press_position, true)
	_send_mouse_motion(board, drag_position)
	var preview_position: Vector2 = idea_view.position

	app.call("advance_run", 0.016)

	_assert_equal(idea_view.position, preview_position, "Application frame tick should not reset an active drag preview.")
	_assert_true(idea_view.position != original_position, "Active drag preview should visibly move away from the state position.")
	_send_mouse_button(board, drag_position, false)
	app.queue_free()

func _test_active_stack_tick_does_not_reset_drag_preview() -> void:
	var app: Node = _create_app()
	var state: RunState = app.run_state
	var board: BoardView = app.call("get_board_view") as BoardView
	var developer: CardInstance = _find_card_by_definition(state, "card.employee.developer")
	var idea: CardInstance = _find_card_by_definition(state, "card.input.idea")
	app.call("request_move_card_to_stack", idea.instance_id, developer.stack_id)
	app.call("advance_run", 0.25)

	var developer_view: CardView = board.get_card_view(developer.instance_id)
	var idea_view: CardView = board.get_card_view(idea.instance_id)
	var progress_view: Control = board.get_stack_progress_view(developer.stack_id)
	var press_position: Vector2 = developer_view.position + Vector2(20.0, 10.0)
	var drag_position: Vector2 = press_position + Vector2(210.0, -80.0)

	_send_mouse_button(board, press_position, true)
	_send_mouse_motion(board, drag_position)
	var developer_preview_position: Vector2 = developer_view.position
	var idea_preview_position: Vector2 = idea_view.position
	var progress_preview_position: Vector2 = progress_view.position

	app.call("advance_run", 0.5)

	_assert_equal(developer_view.position, developer_preview_position, "Active processing tick should not reset dragged base card preview.")
	_assert_equal(idea_view.position, idea_preview_position, "Active processing tick should not reset dragged upper card preview.")
	_assert_equal(progress_view.position, progress_preview_position, "Active processing tick should not reset dragged progress overlay.")
	_send_mouse_button(board, drag_position, false)
	app.queue_free()

func _test_empty_board_drop_uses_free_preview_position() -> void:
	var app: Node = _create_app()
	var state: RunState = app.run_state
	var board: BoardView = app.call("get_board_view") as BoardView
	var idea: CardInstance = _find_card_by_definition(state, "card.input.idea")
	var idea_view: CardView = board.get_card_view(idea.instance_id)

	var press_position: Vector2 = idea_view.position + Vector2(22.0, 35.0)
	var release_position: Vector2 = Vector2(1700.0, 850.0)
	var expected_drop_position: Vector2 = release_position - Vector2(22.0, 35.0)
	_send_mouse_button(board, press_position, true)
	_send_mouse_motion(board, release_position)
	_send_mouse_button(board, release_position, false)

	var stack: StackState = state.get_stack(idea.stack_id)
	_assert_equal(stack.base_position, expected_drop_position, "Dropping on empty board should keep the free preview top-left position.")
	_assert_equal(idea_view.position, expected_drop_position, "Card view should remain where the player dropped it.")
	app.queue_free()

func _test_non_recipe_cards_can_be_stacked() -> void:
	var app: Node = _create_app()
	var state: RunState = app.run_state
	var board: BoardView = app.call("get_board_view") as BoardView
	var money: CardInstance = _find_card_by_definition(state, "card.resource.money")
	var coffee: CardInstance = _find_card_by_definition(state, "card.consumable.coffee")
	var money_view: CardView = board.get_card_view(money.instance_id)
	var coffee_stack: StackState = state.get_stack(coffee.stack_id)

	var press_position: Vector2 = money_view.position + CARD_SIZE * 0.5
	var release_position: Vector2 = coffee_stack.base_position + Vector2(CARD_SIZE.x * 0.5, CARD_SIZE.y - 12.0)
	_send_mouse_button(board, press_position, true)
	_send_mouse_motion(board, release_position)
	_send_mouse_button(board, release_position, false)

	_assert_equal(money.stack_id, coffee.stack_id, "Cards without a matching recipe should still be stackable for organization.")
	_assert_equal(state.get_stack(coffee.stack_id).processing_state.active_recipe_id, "", "Neutral non-recipe stack should not start processing.")
	app.queue_free()

func _test_stack_drag_preview_moves_all_cards() -> void:
	var app: Node = _create_app()
	var state: RunState = app.run_state
	var board: BoardView = app.call("get_board_view") as BoardView
	var developer: CardInstance = _find_card_by_definition(state, "card.employee.developer")
	var idea: CardInstance = _find_card_by_definition(state, "card.input.idea")
	app.call("request_move_card_to_stack", idea.instance_id, developer.stack_id)

	var developer_view: CardView = board.get_card_view(developer.instance_id)
	var idea_view: CardView = board.get_card_view(idea.instance_id)
	var original_developer_position: Vector2 = developer_view.position
	var original_idea_position: Vector2 = idea_view.position
	var press_position: Vector2 = developer_view.position + Vector2(20.0, 10.0)
	var drag_position: Vector2 = press_position + Vector2(180.0, -64.0)

	_send_mouse_button(board, press_position, true)
	_send_mouse_motion(board, drag_position)

	_assert_true(developer_view.position != original_developer_position, "Dragging a stack base should visibly move the base card preview.")
	_assert_true(idea_view.position != original_idea_position, "Dragging a stack base should visibly move cards above it.")
	_assert_equal(idea_view.position, developer_view.position + board.stack_offset, "Dragged stack preview should preserve stack offset.")
	_send_mouse_button(board, drag_position, false)
	app.queue_free()

func _test_dropped_card_draws_above_target_card() -> void:
	var app: Node = _create_app()
	var state: RunState = app.run_state
	var board: BoardView = app.call("get_board_view") as BoardView
	var software: CardInstance = _find_card_by_definition(state, "card.product.software")
	var developer: CardInstance = _find_card_by_definition(state, "card.employee.developer")
	var idea: CardInstance = _find_card_by_definition(state, "card.input.idea")
	app.call("request_move_card_to_stack", idea.instance_id, developer.stack_id)
	app.call("advance_run", 8.0)
	var feature: CardInstance = _find_card_by_definition(state, "card.output.feature")

	app.call("request_move_card_to_stack", software.instance_id, feature.stack_id)
	var software_view: CardView = board.get_card_view(software.instance_id)
	var feature_view: CardView = board.get_card_view(feature.instance_id)

	_assert_true(software_view.z_index > feature_view.z_index, "A card dropped onto a target stack should draw above the target card.")
	app.queue_free()

func _test_dropped_stack_draws_above_all_other_cards() -> void:
	var app: Node = _create_app()
	var state: RunState = app.run_state
	var board: BoardView = app.call("get_board_view") as BoardView
	var developer: CardInstance = _find_card_by_definition(state, "card.employee.developer")
	var idea: CardInstance = _find_card_by_definition(state, "card.input.idea")
	var coffee: CardInstance = _find_card_by_definition(state, "card.consumable.coffee")
	app.call("request_move_card_to_stack", idea.instance_id, developer.stack_id)
	board.refresh()

	var developer_view: CardView = board.get_card_view(developer.instance_id)
	var coffee_view: CardView = board.get_card_view(coffee.instance_id)
	var press_position: Vector2 = developer_view.position + Vector2(20.0, 10.0)
	var release_position: Vector2 = coffee_view.position + Vector2(20.0, 10.0)
	_send_mouse_button(board, press_position, true)
	_send_mouse_motion(board, release_position)
	_send_mouse_button(board, release_position, false)

	var top_dragged_z: int = maxi(board.get_card_view(developer.instance_id).z_index, board.get_card_view(idea.instance_id).z_index)
	for card: CardInstance in state.cards.values():
		if card.instance_id == developer.instance_id or card.instance_id == idea.instance_id:
			continue
		var view: CardView = board.get_card_view(card.instance_id)
		_assert_true(top_dragged_z > view.z_index, "Last dropped stack should draw above every other board card.")
	app.queue_free()

func _test_repeated_drags_keep_drag_layer_above_board_cards() -> void:
	var app: Node = _create_app()
	var state: RunState = app.run_state
	var board: BoardView = app.call("get_board_view") as BoardView
	var idea: CardInstance = _find_card_by_definition(state, "card.input.idea")
	var idea_view: CardView = board.get_card_view(idea.instance_id)

	for index: int in 420:
		var press_position: Vector2 = idea_view.position + Vector2(12.0, 12.0)
		var release_position: Vector2 = idea_view.position + Vector2(160.0 + float(index % 5), 32.0)
		_send_mouse_button(board, press_position, true)
		_send_mouse_motion(board, release_position)
		_assert_true(idea_view.get_parent().name == "DragLayer", "Dragged card should be temporarily parented to DragLayer.")
		_assert_true(idea_view.get_parent().z_index > idea_view.z_index, "DragLayer should remain above dragged card local z.")
		_send_mouse_button(board, release_position, false)

	var max_board_z: int = -2147483648
	for card: CardInstance in state.cards.values():
		var view: CardView = board.get_card_view(card.instance_id)
		max_board_z = maxi(max_board_z, view.z_index)
	_assert_true(max_board_z < 4090, "Board card z-indices should remain below the DragLayer after many drags.")
	app.queue_free()

func _test_board_audio_player_uses_imported_stream_resources() -> void:
	var audio: BoardAudioPlayer = BoardAudioPlayer.new()
	get_root().add_child(audio)
	await process_frame

	_assert_true(audio.drag_start_stream != null, "BoardAudioPlayer should use the imported drag-start AudioStream resource.")
	_assert_true(audio.card_flip_stream != null, "BoardAudioPlayer should use the imported card-flip AudioStream resource.")
	_assert_true(audio.card_destroy_stream != null, "BoardAudioPlayer should use the imported card-destroy AudioStream resource.")
	_assert_equal(audio.get_child_count(), 6, "BoardAudioPlayer should create a small polyphonic player pool.")

	audio.queue_free()
	await process_frame

func _test_board_view_preserves_editor_audio_child_on_rebuild() -> void:
	var catalog: ContentCatalog = ContentCatalog.new()
	_assert_true(catalog.load_default_content(), "Default content should load for editor audio child rebuild test.")
	var controller: RunController = RunController.new(catalog)
	var state: RunState = controller.start_new_run(6)
	var board: BoardView = BoardView.new()
	var audio: BoardAudioPlayer = BoardAudioPlayer.new()
	audio.name = "BoardAudioPlayer"
	board.add_child(audio)

	board.bind_run(state, catalog)

	_assert_equal(board.get_node_or_null("BoardAudioPlayer"), audio, "BoardView rebuild should preserve an editor-authored BoardAudioPlayer child.")
	board.queue_free()

func _test_editor_pipeline_updates_progress_and_spawns_feature() -> void:
	var app: Node = _create_app()
	var state: RunState = app.run_state
	var board: BoardView = app.call("get_board_view") as BoardView
	var developer: CardInstance = _find_card_by_definition(state, "card.employee.developer")
	var idea: CardInstance = _find_card_by_definition(state, "card.input.idea")

	app.call("request_move_card_to_stack", idea.instance_id, developer.stack_id)
	app.call("advance_run", 2.0)

	var stack: StackState = state.get_stack(developer.stack_id)
	var developer_view: CardView = board.get_card_view(developer.instance_id)
	var card_progress_bar: ProgressBar = developer_view.get_node("ProgressBar") as ProgressBar
	var stack_progress_view: Control = board.get_stack_progress_view(developer.stack_id)
	var progress_bar: FramedProgressBar = stack_progress_view.get_node("ProgressBar") as FramedProgressBar
	var action_label: Label = stack_progress_view.get_node("ActionLabel") as Label
	_assert_equal(stack.processing_state.active_recipe_id, "recipe.feature_from_idea.developer", "Developer + idea should start the feature recipe through Application.")
	_assert_false(card_progress_bar.visible, "Processing progress should not be rendered on the card itself.")
	_assert_true(stack_progress_view != null, "Processing progress should be visible above the stack.")
	_assert_equal(stack_progress_view.position, stack.base_position + Vector2(0.0, -82.0), "Processing progress should sit above the stack without covering card titles.")
	_assert_equal(progress_bar.value, 2.0, "Application ticks should update the visible progress bar.")
	_assert_equal(action_label.text, "Funktion bauen", "Visible action text should come from the active recipe.")
	_assert_equal(action_label.autowrap_mode, TextServer.AUTOWRAP_WORD_SMART, "Progress label should support multi-line recipe titles.")
	_assert_true(action_label.position.y + action_label.size.y <= progress_bar.position.y, "Progress label should stay above the framed progress bar.")
	_assert_equal(action_label.get_theme_color("font_color"), Color(0.055, 0.052, 0.047, 1.0), "Progress label should stay readable on the whiteboard.")
	_assert_equal(progress_bar.border_width, 5, "Progress bar frame should match the card border thickness.")
	_assert_equal(progress_bar.border_color, Color(0.055, 0.052, 0.047, 1.0), "Progress bar frame should use the same black border as cards.")

	app.call("advance_run", 6.0)

	var feature: CardInstance = _find_card_by_definition(state, "card.output.feature")
	_assert_true(board.get_card_view(feature.instance_id) != null, "Feature completion should be visible as a new CardView.")
	_assert_false(_stack_rect(state.get_stack(feature.stack_id)).intersects(_stack_rect(state.get_stack(developer.stack_id))), "Spawned feature should not cover the source stack.")
	app.queue_free()

func _test_feature_release_spawns_money_without_covering_stack() -> void:
	var app: Node = _create_app()
	var state: RunState = app.run_state
	var developer: CardInstance = _find_card_by_definition(state, "card.employee.developer")
	var idea: CardInstance = _find_card_by_definition(state, "card.input.idea")

	app.call("request_move_card_to_stack", idea.instance_id, developer.stack_id)
	app.call("advance_run", 8.0)

	var software: CardInstance = _find_card_by_definition(state, "card.product.software")
	var feature: CardInstance = _find_card_by_definition(state, "card.output.feature")
	var money_before: int = _count_cards_by_definition(state, "card.resource.money")

	app.call("request_move_card_to_stack", feature.instance_id, software.stack_id)
	app.call("advance_run", 6.0)

	var money_after: int = _count_cards_by_definition(state, "card.resource.money")
	_assert_equal(money_after, money_before + 1, "Feature + software should spawn exactly one 1-money card.")
	var newest_money: CardInstance = _find_newest_card_by_definition(state, "card.resource.money")
	_assert_false(_stack_rect(state.get_stack(newest_money.stack_id)).intersects(_stack_rect(state.get_stack(software.stack_id))), "Spawned money should not cover the software stack.")
	app.queue_free()

func _create_app() -> Node:
	var scene: PackedScene = ResourceLoader.load("res://scenes/application/Main.tscn") as PackedScene
	var app: Node = scene.instantiate()
	get_root().add_child(app)
	return app

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
	_assert_true(newest != null, "Missing newest card with definition '%s'." % definition_id)
	return newest

func _count_cards_by_definition(state: RunState, definition_id: String) -> int:
	var count: int = 0
	for card: CardInstance in state.cards.values():
		if card.definition_id == definition_id:
			count += 1
	return count

func _stack_rect(stack: StackState) -> Rect2:
	if stack == null:
		return Rect2()
	var bottom_position: Vector2 = stack.base_position + Vector2(0.0, 40.0) * float(stack.card_ids.size() - 1)
	var min_position: Vector2 = Vector2(minf(stack.base_position.x, bottom_position.x), minf(stack.base_position.y, bottom_position.y))
	var max_position: Vector2 = Vector2(maxf(stack.base_position.x + CARD_SIZE.x, bottom_position.x + CARD_SIZE.x), maxf(stack.base_position.y + CARD_SIZE.y, bottom_position.y + CARD_SIZE.y))
	return Rect2(min_position, max_position - min_position)

func _assert_true(value: bool, message: String) -> void:
	if value:
		return
	_failed = true
	printerr("Assertion failed: %s" % message)

func _assert_false(value: bool, message: String) -> void:
	_assert_true(not value, message)

func _assert_equal(actual: Variant, expected: Variant, message: String) -> void:
	if actual == expected:
		return
	_failed = true
	printerr("Assertion failed: %s Expected '%s', got '%s'." % [message, expected, actual])

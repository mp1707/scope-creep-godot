class_name BoardView
extends Node2D

const DRAG_LAYER_Z: int = 4090
const STACK_Z_STEP: int = 8
const STACK_PROGRESS_Z_OFFSET: int = 4
const MAX_STACK_LAYER: int = 360
const BOARD_RECT_POSITION: Vector2 = Vector2(72.0, 96.0)
const BOARD_RECT_END_MARGIN: Vector2 = Vector2(72.0, 96.0)
const BOARD_OUTER_RECT_POSITION: Vector2 = Vector2(56.0, 80.0)
const BOARD_OUTER_RECT_END_MARGIN: Vector2 = Vector2(56.0, 80.0)
const BOARD_BACKGROUND_COLOR: Color = Color(0.955, 0.948, 0.918, 1.0)
const BOARD_OUTER_COLOR: Color = Color(0.99, 0.985, 0.955, 1.0)
const BOARD_BORDER_COLOR: Color = Color(0.055, 0.052, 0.047, 1.0)
const BOARD_GRID_COLOR: Color = Color(0.58, 0.64, 0.62, 0.12)
const BOARD_NOTE_COLOR: Color = Color(0.38, 0.52, 0.58, 0.16)
const BOARD_CORNER_RADIUS: int = 22
const BOARD_BORDER_WIDTH: int = 7
const PROGRESS_OFFSET: Vector2 = Vector2(0.0, -82.0)
const PROGRESS_CONTAINER_SIZE: Vector2 = Vector2(144.0, 72.0)
const PROGRESS_LABEL_SIZE: Vector2 = Vector2(144.0, 42.0)
const PROGRESS_BAR_POSITION: Vector2 = Vector2(0.0, 46.0)
const PROGRESS_BAR_SIZE: Vector2 = Vector2(144.0, 24.0)
const PROGRESS_BORDER_WIDTH: int = 5
const PROGRESS_CORNER_RADIUS: int = 7
const PROGRESS_BACKGROUND_COLOR: Color = Color(0.99, 0.985, 0.955, 1.0)
const PROGRESS_FILL_COLOR: Color = Color(0.56, 0.78, 0.90, 1.0)
const PROGRESS_TEXT_COLOR: Color = Color(0.055, 0.052, 0.047, 1.0)
const CLICK_DRAG_THRESHOLD: float = 8.0
const VISUAL_EVENT_STEP_SECONDS: float = 0.12

signal move_stack_requested(stack_id: String, position: Vector2)
signal move_card_to_stack_requested(card_id: String, target_stack_id: String)
signal split_stack_requested(card_id: String, position: Vector2)
signal card_clicked(card_id: String)
signal board_pan_requested(relative: Vector2)

@export var card_view_scene: PackedScene
@export var card_size: Vector2 = Vector2(144.0, 196.0)
@export var stack_offset: Vector2 = Vector2(0.0, 40.0)
@export var snap_distance: float = 96.0

var state: RunState = null
var content: ContentCatalog = null

var _card_views: Dictionary = {}
var _stack_progress_views: Dictionary = {}
var _stack_layers: Dictionary = {}
var _next_stack_layer: int = 1
var _drag_preview_card_ids: PackedStringArray = PackedStringArray()
var _drag_layer: Node2D = null
var _layout: StackLayout = StackLayout.new()
var _dragging_card_id: String = ""
var _drag_start_stack_id: String = ""
var _drag_start_card_index: int = -1
var _drag_pointer_offset: Vector2 = Vector2.ZERO
var _pending_click_card_id: String = ""
var _pending_click_position: Vector2 = Vector2.ZERO
var _is_board_panning: bool = false
var _last_board_pan_viewport_position: Vector2 = Vector2.ZERO
var _queued_visual_events: Array[SimulationEvent] = []
var _is_processing_visual_events: bool = false
var _audio: BoardAudioPlayer = null

func _ready() -> void:
	set_process_unhandled_input(true)
	set_process(true)
	queue_redraw()

func _process(_delta: float) -> void:
	if _dragging_card_id.is_empty():
		return
	var viewport: Viewport = get_viewport()
	if viewport == null:
		return
	_update_drag_preview(_viewport_position_to_board(viewport.get_mouse_position()))

func _draw() -> void:
	var board_rect: Rect2 = _get_board_rect()
	var board_outer_rect: Rect2 = _get_board_outer_rect()

	var outer_style: StyleBoxFlat = StyleBoxFlat.new()
	outer_style.bg_color = BOARD_OUTER_COLOR
	outer_style.border_color = BOARD_OUTER_COLOR
	outer_style.corner_radius_bottom_left = BOARD_CORNER_RADIUS + 8
	outer_style.corner_radius_bottom_right = BOARD_CORNER_RADIUS + 8
	outer_style.corner_radius_top_left = BOARD_CORNER_RADIUS + 8
	outer_style.corner_radius_top_right = BOARD_CORNER_RADIUS + 8
	draw_style_box(outer_style, board_outer_rect)

	var board_style: StyleBoxFlat = StyleBoxFlat.new()
	board_style.bg_color = BOARD_BACKGROUND_COLOR
	board_style.border_color = BOARD_BORDER_COLOR
	board_style.border_width_bottom = BOARD_BORDER_WIDTH
	board_style.border_width_left = BOARD_BORDER_WIDTH
	board_style.border_width_right = BOARD_BORDER_WIDTH
	board_style.border_width_top = BOARD_BORDER_WIDTH
	board_style.corner_radius_bottom_left = BOARD_CORNER_RADIUS
	board_style.corner_radius_bottom_right = BOARD_CORNER_RADIUS
	board_style.corner_radius_top_left = BOARD_CORNER_RADIUS
	board_style.corner_radius_top_right = BOARD_CORNER_RADIUS
	draw_style_box(board_style, board_rect)

	for x_index: int in range(int(board_rect.position.x) + 96, int(board_rect.end.x), 160):
		var x: float = float(x_index)
		draw_line(Vector2(x, board_rect.position.y + 16.0), Vector2(x, board_rect.end.y - 16.0), BOARD_GRID_COLOR, 1.0)
	for y_index: int in range(int(board_rect.position.y) + 96, int(board_rect.end.y), 160):
		var y: float = float(y_index)
		draw_line(Vector2(board_rect.position.x + 16.0, y), Vector2(board_rect.end.x - 16.0, y), BOARD_GRID_COLOR, 1.0)

	draw_arc(Vector2(350.0, 845.0), 34.0, 0.15, 2.8, 16, BOARD_NOTE_COLOR, 2.0)
	draw_arc(board_rect.end - Vector2(338.0, 193.0), 42.0, 3.5, 5.9, 16, BOARD_NOTE_COLOR, 2.0)
	draw_line(board_rect.position + Vector2(board_rect.size.x - 408.0, 94.0), board_rect.position + Vector2(board_rect.size.x - 346.0, 94.0), BOARD_NOTE_COLOR, 2.0)
	draw_line(board_rect.position + Vector2(board_rect.size.x - 408.0, 118.0), board_rect.position + Vector2(board_rect.size.x - 312.0, 118.0), BOARD_NOTE_COLOR, 2.0)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.button_index != MOUSE_BUTTON_LEFT:
			return
		var board_position: Vector2 = _viewport_position_to_board(mouse_event.position)
		if mouse_event.pressed:
			var hit_card_id: String = _find_card_at_board_position(board_position)
			if hit_card_id.is_empty():
				_is_board_panning = true
				_last_board_pan_viewport_position = mouse_event.position
				_mark_input_as_handled()
				return
			if _is_click_openable_card(hit_card_id):
				_pending_click_card_id = hit_card_id
				_pending_click_position = board_position
				_mark_input_as_handled()
				return
			_begin_drag(hit_card_id, board_position)
			_mark_input_as_handled()
		elif not _pending_click_card_id.is_empty():
			card_clicked.emit(_pending_click_card_id)
			_pending_click_card_id = ""
			_mark_input_as_handled()
		elif not _dragging_card_id.is_empty():
			_finish_drag(board_position)
			_mark_input_as_handled()
		elif _is_board_panning:
			_is_board_panning = false
			_mark_input_as_handled()

	if event is InputEventMouseMotion and _is_board_panning:
		var board_pan_motion_event: InputEventMouseMotion = event as InputEventMouseMotion
		var relative: Vector2 = board_pan_motion_event.position - _last_board_pan_viewport_position
		_last_board_pan_viewport_position = board_pan_motion_event.position
		board_pan_requested.emit(relative)
		_mark_input_as_handled()

	if event is InputEventMouseMotion and not _pending_click_card_id.is_empty():
		var pending_motion_event: InputEventMouseMotion = event as InputEventMouseMotion
		var pending_position: Vector2 = _viewport_position_to_board(pending_motion_event.position)
		if pending_position.distance_to(_pending_click_position) >= CLICK_DRAG_THRESHOLD:
			var pending_card_id: String = _pending_click_card_id
			_pending_click_card_id = ""
			_begin_drag(pending_card_id, _pending_click_position)
			_update_drag_preview(pending_position)
		_mark_input_as_handled()

	if event is InputEventMouseMotion and not _dragging_card_id.is_empty():
		var motion_event: InputEventMouseMotion = event as InputEventMouseMotion
		_update_drag_preview(_viewport_position_to_board(motion_event.position))
		_mark_input_as_handled()

func bind_run(run_state: RunState, content_catalog: ContentCatalog) -> void:
	state = run_state
	content = content_catalog
	if content != null and content.balance != null:
		stack_offset = content.balance.stack_offset
		snap_distance = content.balance.board_snap_distance
	_layout.card_size = card_size
	_layout.stack_offset = stack_offset
	_rebuild()
	queue_redraw()

func apply_events(events: Array[SimulationEvent]) -> void:
	for event: SimulationEvent in events:
		match event.type:
			ScopeEnums.SimulationEventType.CARD_REMOVED:
				_queue_visual_event(event)
			ScopeEnums.SimulationEventType.CARD_SPAWNED:
				if _card_views.has(event.card_id):
					_update_stack(event.stack_id)
				else:
					var spawned_view: CardView = _ensure_card_view(event.card_id)
					spawned_view.visible = false
					_update_stack(event.stack_id)
					_queue_visual_event(event)
			ScopeEnums.SimulationEventType.STACK_CHANGED, \
			ScopeEnums.SimulationEventType.RECIPE_STARTED, \
			ScopeEnums.SimulationEventType.RECIPE_CANCELLED, \
			ScopeEnums.SimulationEventType.RECIPE_COMPLETED:
				_update_stack(event.stack_id)
			ScopeEnums.SimulationEventType.PHASE_CHANGED, \
			ScopeEnums.SimulationEventType.PAUSE_CHANGED:
				refresh()
			_:
				pass

func refresh() -> void:
	if state == null:
		return
	for stack_id: String in state.stacks.keys():
		_update_stack(stack_id)

func get_card_view(card_id: String) -> CardView:
	return _card_views.get(card_id, null) as CardView

func get_stack_progress_view(stack_id: String) -> Control:
	return _stack_progress_views.get(stack_id, null) as Control

func find_snap_stack(card_id: String, board_position: Vector2) -> StackState:
	if not _can_interact_with_board():
		return null

	var best_stack: StackState = null
	var best_distance: float = snap_distance
	for stack: StackState in state.stacks.values():
		if stack.card_ids.has(card_id):
			continue
		var rect: Rect2 = _layout.get_stack_rect(stack)
		var distance: float = _distance_to_rect(board_position, rect)
		if distance <= best_distance:
			best_distance = distance
			best_stack = stack

	return best_stack

func _rebuild() -> void:
	for child: Node in get_children():
		if child == _drag_layer:
			continue
		if child is BoardAudioPlayer:
			_audio = child as BoardAudioPlayer
			continue
		child.queue_free()
	_card_views.clear()
	_stack_progress_views.clear()
	_stack_layers.clear()
	_next_stack_layer = 1

	for card_id: String in state.cards.keys():
		_ensure_card_view(card_id)
	refresh()

func _ensure_card_view(card_id: String) -> CardView:
	if _card_views.has(card_id):
		return _card_views[card_id] as CardView

	var view: CardView = null
	if card_view_scene != null:
		view = card_view_scene.instantiate() as CardView
	if view == null:
		view = CardView.new()

	add_child(view)
	_card_views[card_id] = view
	_update_card_view(card_id)
	return view

func _remove_card_view(card_id: String) -> void:
	var view: CardView = get_card_view(card_id)
	if view != null:
		view.queue_free()
	_card_views.erase(card_id)

func _update_stack(stack_id: String) -> void:
	if state == null or not state.stacks.has(stack_id):
		_remove_stack_progress_view(stack_id)
		return

	var stack: StackState = state.get_stack(stack_id)
	_ensure_stack_layer(stack.stack_id)
	for index: int in stack.card_ids.size():
		var card_id: String = stack.card_ids[index]
		var view: CardView = _ensure_card_view(card_id)
		if not _drag_preview_card_ids.has(card_id):
			view.position = _layout.get_card_position(stack, card_id)
			view.z_index = _get_stack_base_z(stack.stack_id) + index
		_update_card_view(card_id)
	_update_stack_progress_view(stack)

func _update_card_view(card_id: String) -> void:
	if state == null or content == null:
		return
	var card: CardInstance = state.get_card(card_id)
	if card == null:
		_remove_card_view(card_id)
		return

	var definition: CardDefinition = content.get_card_definition(card.definition_id)
	var stack: StackState = state.get_stack(card.stack_id)
	if definition == null or stack == null:
		return

	var view: CardView = _ensure_card_view(card_id)
	view.setup(card, definition, stack)

func _begin_drag(card_id: String, board_position: Vector2) -> void:
	var card: CardInstance = state.get_card(card_id)
	if card == null:
		return
	var view: CardView = get_card_view(card_id)
	if view == null:
		return
	var start_card_index: int = _get_card_index_in_stack(card_id, card.stack_id)
	var preview_card_ids: PackedStringArray = _get_drag_preview_card_ids(card.stack_id, start_card_index)
	if preview_card_ids.is_empty() or not _can_interact_with_board():
		return
	_dragging_card_id = card_id
	_drag_start_stack_id = card.stack_id
	_drag_start_card_index = start_card_index
	_drag_pointer_offset = board_position - view.position
	_drag_preview_card_ids = preview_card_ids
	_move_drag_views_to_layer()
	_bring_stack_to_front(card.stack_id)
	_play_drag_started_audio()
	_update_drag_preview(board_position)

func _update_drag_preview(board_position: Vector2) -> void:
	if _drag_preview_card_ids.is_empty():
		return
	var preview_base_position: Vector2 = board_position - _drag_pointer_offset
	for index: int in _drag_preview_card_ids.size():
		var card_id: String = _drag_preview_card_ids[index]
		var view: CardView = get_card_view(card_id)
		if view == null:
			continue
		view.set_elevated(true)
		view.set_drag_preview_position(preview_base_position + stack_offset * float(index))
		view.z_index = index
	_update_drag_progress_preview(preview_base_position)

func _finish_drag(board_position: Vector2) -> void:
	var snap_stack: StackState = find_snap_stack(_dragging_card_id, board_position)
	var target_stack_id: String = ""
	if snap_stack != null:
		target_stack_id = snap_stack.stack_id
		move_card_to_stack_requested.emit(_dragging_card_id, snap_stack.stack_id)
	else:
		var card: CardInstance = state.get_card(_dragging_card_id)
		var drop_position: Vector2 = board_position - _drag_pointer_offset
		if card != null and card.stack_id == _drag_start_stack_id and _drag_start_card_index == 0:
			target_stack_id = card.stack_id
			move_stack_requested.emit(card.stack_id, drop_position)
		else:
			split_stack_requested.emit(_dragging_card_id, drop_position)
			var moved_card: CardInstance = state.get_card(_dragging_card_id)
			if moved_card != null:
				target_stack_id = moved_card.stack_id

	for card_id: String in _drag_preview_card_ids:
		var view: CardView = get_card_view(card_id)
		if view != null:
			view.clear_drag_preview()
	_restore_drag_views_to_board()
	if not target_stack_id.is_empty():
		_bring_stack_to_front(target_stack_id)
	_play_card_dropped_audio()
	_dragging_card_id = ""
	_drag_start_stack_id = ""
	_drag_start_card_index = -1
	_drag_preview_card_ids = PackedStringArray()
	refresh()

func _get_card_index_in_stack(card_id: String, stack_id: String) -> int:
	if state == null or not state.stacks.has(stack_id):
		return -1
	var stack: StackState = state.get_stack(stack_id)
	return stack.card_ids.find(card_id)

func _get_drag_preview_card_ids(stack_id: String, start_index: int) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	if state == null or not state.stacks.has(stack_id):
		return result
	var stack: StackState = state.get_stack(stack_id)
	for index: int in range(maxi(start_index, 0), stack.card_ids.size()):
		result.append(stack.card_ids[index])
	return result

func _move_drag_views_to_layer() -> void:
	_ensure_drag_layer()
	for card_id: String in _drag_preview_card_ids:
		var view: CardView = get_card_view(card_id)
		if view != null and view.get_parent() != _drag_layer:
			view.reparent(_drag_layer, true)
	var progress_view: Control = get_stack_progress_view(_drag_start_stack_id)
	if progress_view != null and progress_view.get_parent() != _drag_layer:
		progress_view.reparent(_drag_layer, true)

func _restore_drag_views_to_board() -> void:
	for card_id: String in _drag_preview_card_ids:
		var view: CardView = get_card_view(card_id)
		if view != null and view.get_parent() != self:
			view.reparent(self, true)
	var progress_view: Control = get_stack_progress_view(_drag_start_stack_id)
	if progress_view != null and progress_view.get_parent() != self:
		progress_view.reparent(self, true)

func _ensure_drag_layer() -> void:
	if _drag_layer != null and is_instance_valid(_drag_layer):
		return
	_drag_layer = Node2D.new()
	_drag_layer.name = "DragLayer"
	_drag_layer.z_index = DRAG_LAYER_Z
	add_child(_drag_layer)

func _ensure_audio() -> void:
	if _audio != null and is_instance_valid(_audio):
		return
	_audio = get_node_or_null("BoardAudioPlayer") as BoardAudioPlayer
	if _audio != null:
		return
	_audio = BoardAudioPlayer.new()
	_audio.name = "BoardAudioPlayer"
	add_child(_audio, false, Node.INTERNAL_MODE_BACK)

func _play_drag_started_audio() -> void:
	if not _should_use_presentation_effects():
		return
	_ensure_audio()
	_audio.play_drag_started()

func _play_card_dropped_audio() -> void:
	if not _should_use_presentation_effects():
		return
	_ensure_audio()
	_audio.play_card_dropped()

func _play_card_spawned_audio() -> void:
	if not _should_use_presentation_effects():
		return
	_ensure_audio()
	_audio.play_card_spawned()

func _play_card_destroyed_audio() -> void:
	if not _should_use_presentation_effects():
		return
	_ensure_audio()
	_audio.play_card_destroyed()

func _is_click_openable_card(card_id: String) -> bool:
	if state == null or content == null:
		return false
	var card: CardInstance = state.get_card(card_id)
	if card == null:
		return false
	var definition: CardDefinition = content.get_card_definition(card.definition_id)
	return definition != null and definition.tags.has("booster") and definition.tags.has("pack")

func _queue_visual_event(event: SimulationEvent) -> void:
	if not _should_use_presentation_effects():
		_apply_visual_event(event, false)
		return
	_queued_visual_events.append(event)
	if not _is_processing_visual_events:
		_process_visual_event_queue()

func _process_visual_event_queue() -> void:
	_is_processing_visual_events = true
	_ensure_audio()
	while not _queued_visual_events.is_empty():
		var event: SimulationEvent = _queued_visual_events.pop_front() as SimulationEvent
		_apply_visual_event(event, true)
		await get_tree().create_timer(VISUAL_EVENT_STEP_SECONDS).timeout
	_is_processing_visual_events = false

func _apply_visual_event(event: SimulationEvent, with_effects: bool) -> void:
	match event.type:
		ScopeEnums.SimulationEventType.CARD_REMOVED:
			if with_effects:
				_play_card_destroyed_audio()
			_remove_card_view(event.card_id)
		ScopeEnums.SimulationEventType.CARD_SPAWNED:
			var view: CardView = _ensure_card_view(event.card_id)
			_update_stack(event.stack_id)
			if view != null:
				view.visible = true
				if with_effects:
					view.play_spawn_pop()
			if with_effects:
				_play_card_spawned_audio()
		_:
			pass

func _should_use_presentation_effects() -> bool:
	return DisplayServer.get_name() != "headless"

func _find_card_at_board_position(board_position: Vector2) -> String:
	var best_card_id: String = ""
	var best_z_index: int = -2147483648
	var best_child_index: int = -1

	for card_id: String in _card_views.keys():
		var view: CardView = get_card_view(card_id)
		if view == null:
			continue
		var rect: Rect2 = Rect2(view.position, card_size)
		if not rect.has_point(board_position):
			continue
		if view.z_index > best_z_index or (view.z_index == best_z_index and view.get_index() > best_child_index):
			best_card_id = card_id
			best_z_index = view.z_index
			best_child_index = view.get_index()

	return best_card_id

func _viewport_position_to_board(viewport_position: Vector2) -> Vector2:
	return get_global_transform_with_canvas().affine_inverse() * viewport_position

func _mark_input_as_handled() -> void:
	var viewport: Viewport = get_viewport()
	if viewport != null:
		viewport.set_input_as_handled()

func _distance_to_rect(point: Vector2, rect: Rect2) -> float:
	if rect.has_point(point):
		return 0.0
	var closest_point: Vector2 = Vector2(
		clampf(point.x, rect.position.x, rect.position.x + rect.size.x),
		clampf(point.y, rect.position.y, rect.position.y + rect.size.y)
	)
	return point.distance_to(closest_point)

func _can_interact_with_board() -> bool:
	if state == null:
		return false
	return state.phase == ScopeEnums.RunPhase.SPRINT or state.phase == ScopeEnums.RunPhase.PAYMENT

func _update_stack_progress_view(stack: StackState) -> void:
	var processing: ProcessingState = stack.processing_state
	var is_active: bool = processing.status == ScopeEnums.ProcessingStatus.ACTIVE and processing.duration > 0.0
	if not is_active:
		_remove_stack_progress_view(stack.stack_id)
		return

	var container: Control = _ensure_stack_progress_view(stack.stack_id)
	if _drag_start_stack_id == stack.stack_id and not _drag_preview_card_ids.is_empty():
		container.z_index = _drag_preview_card_ids.size() + STACK_PROGRESS_Z_OFFSET
	else:
		container.position = stack.base_position + PROGRESS_OFFSET
		container.z_index = _get_stack_base_z(stack.stack_id) + STACK_PROGRESS_Z_OFFSET

	var label: Label = container.get_node("ActionLabel") as Label
	var progress_bar: FramedProgressBar = container.get_node("ProgressBar") as FramedProgressBar
	label.text = _get_stack_action_text(stack)
	progress_bar.max_value = processing.duration
	progress_bar.value = processing.elapsed

func _update_drag_progress_preview(preview_base_position: Vector2) -> void:
	var progress_view: Control = get_stack_progress_view(_drag_start_stack_id)
	if progress_view == null:
		return
	progress_view.position = preview_base_position + PROGRESS_OFFSET
	progress_view.z_index = _drag_preview_card_ids.size() + STACK_PROGRESS_Z_OFFSET

func _ensure_stack_progress_view(stack_id: String) -> Control:
	if _stack_progress_views.has(stack_id):
		return _stack_progress_views[stack_id] as Control

	var container: Control = Control.new()
	container.name = "StackProgress_%s" % stack_id
	container.size = PROGRESS_CONTAINER_SIZE
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.z_index = 2000

	var label: Label = Label.new()
	label.name = "ActionLabel"
	label.position = Vector2(0.0, 0.0)
	label.size = PROGRESS_LABEL_SIZE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.clip_text = true
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override("font_color", PROGRESS_TEXT_COLOR)
	label.add_theme_font_size_override("font_size", 16)
	container.add_child(label)

	var progress_bar: FramedProgressBar = FramedProgressBar.new()
	progress_bar.name = "ProgressBar"
	progress_bar.position = PROGRESS_BAR_POSITION
	progress_bar.size = PROGRESS_BAR_SIZE
	progress_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	progress_bar.background_color = PROGRESS_BACKGROUND_COLOR
	progress_bar.fill_color = PROGRESS_FILL_COLOR
	progress_bar.border_color = BOARD_BORDER_COLOR
	progress_bar.border_width = PROGRESS_BORDER_WIDTH
	progress_bar.corner_radius = PROGRESS_CORNER_RADIUS
	container.add_child(progress_bar)

	add_child(container)
	_stack_progress_views[stack_id] = container
	return container

func _remove_stack_progress_view(stack_id: String) -> void:
	var view: Control = _stack_progress_views.get(stack_id, null) as Control
	if view != null:
		view.queue_free()
	_stack_progress_views.erase(stack_id)

func _ensure_stack_layer(stack_id: String) -> void:
	if _stack_layers.has(stack_id):
		return
	_stack_layers[stack_id] = _next_stack_layer
	_next_stack_layer += 1

func _bring_stack_to_front(stack_id: String) -> void:
	if stack_id.is_empty():
		return
	_compact_stack_layers_if_needed()
	_stack_layers[stack_id] = _next_stack_layer
	_next_stack_layer += 1

func _get_stack_base_z(stack_id: String) -> int:
	_ensure_stack_layer(stack_id)
	return (_stack_layers[stack_id] as int) * STACK_Z_STEP

func _compact_stack_layers_if_needed() -> void:
	if _next_stack_layer <= MAX_STACK_LAYER:
		return

	var stack_ids: Array[String] = []
	for stack_id: String in _stack_layers.keys():
		stack_ids.append(stack_id)
	stack_ids.sort_custom(func(left: String, right: String) -> bool:
		return (_stack_layers[left] as int) < (_stack_layers[right] as int)
	)

	_stack_layers.clear()
	_next_stack_layer = 1
	for stack_id: String in stack_ids:
		if state != null and state.stacks.has(stack_id):
			_stack_layers[stack_id] = _next_stack_layer
			_next_stack_layer += 1

func _get_stack_action_text(stack: StackState) -> String:
	if content == null or stack.processing_state.active_recipe_id.is_empty():
		return ""
	var recipe: RecipeDefinition = content.get_recipe_definition(stack.processing_state.active_recipe_id)
	if recipe == null:
		return ""
	return recipe.display_text

func _get_board_rect() -> Rect2:
	var board_size: Vector2 = _get_board_size()
	var rect_size: Vector2 = Vector2(
		maxf(0.0, board_size.x - BOARD_RECT_POSITION.x - BOARD_RECT_END_MARGIN.x),
		maxf(0.0, board_size.y - BOARD_RECT_POSITION.y - BOARD_RECT_END_MARGIN.y)
	)
	return Rect2(BOARD_RECT_POSITION, rect_size)

func _get_board_outer_rect() -> Rect2:
	var board_size: Vector2 = _get_board_size()
	var rect_size: Vector2 = Vector2(
		maxf(0.0, board_size.x - BOARD_OUTER_RECT_POSITION.x - BOARD_OUTER_RECT_END_MARGIN.x),
		maxf(0.0, board_size.y - BOARD_OUTER_RECT_POSITION.y - BOARD_OUTER_RECT_END_MARGIN.y)
	)
	return Rect2(BOARD_OUTER_RECT_POSITION, rect_size)

func _get_board_size() -> Vector2:
	if state != null and state.board != null:
		return state.board.size
	return BoardState.DEFAULT_SIZE

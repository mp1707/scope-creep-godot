class_name BoardView
extends Node2D

const DRAG_LAYER_Z: int = 4090
const STACK_Z_STEP: int = 8
const STACK_PROGRESS_Z_OFFSET: int = 4
const MAX_STACK_LAYER: int = 360

signal move_stack_requested(stack_id: String, position: Vector2)
signal move_card_to_stack_requested(card_id: String, target_stack_id: String)
signal split_stack_requested(card_id: String, position: Vector2)

@export var card_view_scene: PackedScene
@export var card_size: Vector2 = Vector2(144.0, 196.0)
@export var stack_offset: Vector2 = Vector2(0.0, 28.0)
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

func _ready() -> void:
	set_process_unhandled_input(true)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.button_index != MOUSE_BUTTON_LEFT:
			return
		var board_position: Vector2 = _viewport_position_to_board(mouse_event.position)
		if mouse_event.pressed:
			var hit_card_id: String = _find_card_at_board_position(board_position)
			if hit_card_id.is_empty():
				return
			_begin_drag(hit_card_id, board_position)
			_mark_input_as_handled()
		elif not _dragging_card_id.is_empty():
			_finish_drag(board_position)
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

func apply_events(events: Array[SimulationEvent]) -> void:
	for event: SimulationEvent in events:
		match event.type:
			ScopeEnums.SimulationEventType.CARD_REMOVED:
				_remove_card_view(event.card_id)
			ScopeEnums.SimulationEventType.CARD_SPAWNED:
				_ensure_card_view(event.card_id)
			ScopeEnums.SimulationEventType.STACK_CHANGED, \
			ScopeEnums.SimulationEventType.RECIPE_STARTED, \
			ScopeEnums.SimulationEventType.RECIPE_CANCELLED, \
			ScopeEnums.SimulationEventType.RECIPE_COMPLETED:
				_update_stack(event.stack_id)
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
	if state == null:
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
		if child != _drag_layer:
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
	_dragging_card_id = card_id
	_drag_start_stack_id = card.stack_id
	_drag_start_card_index = _get_card_index_in_stack(card_id, card.stack_id)
	_drag_pointer_offset = board_position - view.position
	_drag_preview_card_ids = _get_drag_preview_card_ids(card.stack_id, _drag_start_card_index)
	_move_drag_views_to_layer()
	_bring_stack_to_front(card.stack_id)
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
		container.position = stack.base_position + Vector2(0.0, -34.0)
		container.z_index = _get_stack_base_z(stack.stack_id) + STACK_PROGRESS_Z_OFFSET

	var label: Label = container.get_node("ActionLabel") as Label
	var progress_bar: ProgressBar = container.get_node("ProgressBar") as ProgressBar
	label.text = _get_stack_action_text(stack)
	progress_bar.max_value = processing.duration
	progress_bar.value = processing.elapsed

func _update_drag_progress_preview(preview_base_position: Vector2) -> void:
	var progress_view: Control = get_stack_progress_view(_drag_start_stack_id)
	if progress_view == null:
		return
	progress_view.position = preview_base_position + Vector2(0.0, -34.0)
	progress_view.z_index = _drag_preview_card_ids.size() + STACK_PROGRESS_Z_OFFSET

func _ensure_stack_progress_view(stack_id: String) -> Control:
	if _stack_progress_views.has(stack_id):
		return _stack_progress_views[stack_id] as Control

	var container: Control = Control.new()
	container.name = "StackProgress_%s" % stack_id
	container.size = Vector2(card_size.x, 28.0)
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.z_index = 2000

	var label: Label = Label.new()
	label.name = "ActionLabel"
	label.position = Vector2(0.0, 0.0)
	label.size = Vector2(card_size.x, 14.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.clip_text = true
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(label)

	var progress_bar: ProgressBar = ProgressBar.new()
	progress_bar.name = "ProgressBar"
	progress_bar.position = Vector2(0.0, 16.0)
	progress_bar.size = Vector2(card_size.x, 10.0)
	progress_bar.show_percentage = false
	progress_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
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

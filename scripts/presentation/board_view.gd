class_name BoardView
extends Node2D

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
var _layout: StackLayout = StackLayout.new()
var _dragging_card_id: String = ""
var _drag_start_stack_id: String = ""
var _drag_start_card_index: int = -1
var _drag_pointer_offset: Vector2 = Vector2.ZERO

func bind_run(run_state: RunState, content_catalog: ContentCatalog) -> void:
	state = run_state
	content = content_catalog
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

func find_snap_stack(card_id: String, board_position: Vector2) -> StackState:
	if state == null:
		return null

	var best_stack: StackState = null
	var best_distance: float = snap_distance
	for stack: StackState in state.stacks.values():
		if stack.card_ids.has(card_id):
			continue
		var rect: Rect2 = _layout.get_stack_rect(stack)
		var target_position: Vector2 = rect.position + Vector2(rect.size.x * 0.5, 0.0)
		var distance: float = board_position.distance_to(target_position)
		if distance <= best_distance:
			best_distance = distance
			best_stack = stack

	return best_stack

func _rebuild() -> void:
	for child: Node in get_children():
		child.queue_free()
	_card_views.clear()

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
	view.drag_started.connect(_on_card_drag_started)
	view.drag_moved.connect(_on_card_drag_moved)
	view.drag_ended.connect(_on_card_drag_ended)
	_update_card_view(card_id)
	return view

func _remove_card_view(card_id: String) -> void:
	var view: CardView = get_card_view(card_id)
	if view != null:
		view.queue_free()
	_card_views.erase(card_id)

func _update_stack(stack_id: String) -> void:
	if state == null or not state.stacks.has(stack_id):
		return

	var stack: StackState = state.get_stack(stack_id)
	for index: int in stack.card_ids.size():
		var card_id: String = stack.card_ids[index]
		var view: CardView = _ensure_card_view(card_id)
		view.position = _layout.get_card_position(stack, card_id)
		view.z_index = index
		_update_card_view(card_id)

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

func _on_card_drag_started(card_id: String, pointer_offset: Vector2) -> void:
	var card: CardInstance = state.get_card(card_id)
	if card == null:
		return
	_dragging_card_id = card_id
	_drag_start_stack_id = card.stack_id
	_drag_start_card_index = _get_card_index_in_stack(card_id, card.stack_id)
	_drag_pointer_offset = pointer_offset
	var view: CardView = get_card_view(card_id)
	if view != null and get_viewport() != null:
		view.set_drag_preview_position(get_global_mouse_position() - global_position - _drag_pointer_offset)

func _on_card_drag_moved(card_id: String, global_board_position: Vector2) -> void:
	if _dragging_card_id != card_id:
		return
	var view: CardView = get_card_view(card_id)
	if view != null:
		view.set_drag_preview_position(global_board_position - global_position)

func _on_card_drag_ended(card_id: String, global_board_position: Vector2) -> void:
	if _dragging_card_id != card_id:
		return

	var board_position: Vector2 = global_board_position - global_position
	var snap_stack: StackState = find_snap_stack(card_id, board_position)
	if snap_stack != null:
		move_card_to_stack_requested.emit(card_id, snap_stack.stack_id)
	else:
		var card: CardInstance = state.get_card(card_id)
		if card != null and card.stack_id == _drag_start_stack_id and _drag_start_card_index == 0:
			move_stack_requested.emit(card.stack_id, board_position)
		else:
			split_stack_requested.emit(card_id, board_position)

	var view: CardView = get_card_view(card_id)
	if view != null:
		view.clear_drag_preview()
	refresh()
	_dragging_card_id = ""
	_drag_start_stack_id = ""
	_drag_start_card_index = -1

func _get_card_index_in_stack(card_id: String, stack_id: String) -> int:
	if state == null or not state.stacks.has(stack_id):
		return -1
	var stack: StackState = state.get_stack(stack_id)
	return stack.card_ids.find(card_id)

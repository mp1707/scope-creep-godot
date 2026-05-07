class_name BoardCamera
extends Camera2D

@export var zoom_step: float = 0.1
@export var trackpad_zoom_sensitivity: float = 0.035
@export var magnify_zoom_sensitivity: float = 0.25
@export var min_zoom: float = 0.5
@export var max_zoom: float = 2.0

var board: BoardState = null

func _ready() -> void:
	make_current()
	_clamp_and_persist()

func bind_board(board_state: BoardState) -> void:
	board = board_state
	if board == null:
		return
	position = board.camera_position
	zoom = _get_sanitized_zoom(board.camera_zoom)
	_clamp_and_persist()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_apply_zoom(zoom.x + zoom_step)
			_mark_input_as_handled()
		elif mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_apply_zoom(zoom.x - zoom_step)
			_mark_input_as_handled()

	if event is InputEventPanGesture:
		var pan_event: InputEventPanGesture = event as InputEventPanGesture
		_apply_zoom(zoom.x - pan_event.delta.y * trackpad_zoom_sensitivity)
		_mark_input_as_handled()

	if event is InputEventMagnifyGesture:
		var magnify_event: InputEventMagnifyGesture = event as InputEventMagnifyGesture
		_apply_zoom(zoom.x + (magnify_event.factor - 1.0) * magnify_zoom_sensitivity)
		_mark_input_as_handled()

func _apply_zoom(value: float) -> void:
	var mouse_world_before: Vector2 = get_global_mouse_position()
	var clamped_zoom: float = clampf(value, _get_effective_min_zoom(), max_zoom)
	zoom = Vector2(clamped_zoom, clamped_zoom)
	var mouse_world_after: Vector2 = get_global_mouse_position()
	position += mouse_world_before - mouse_world_after
	_clamp_and_persist()

func pan_by_viewport_delta(relative: Vector2) -> void:
	position -= relative / zoom.x
	_clamp_and_persist()

func _clamp_and_persist() -> void:
	position = _get_clamped_position(position)
	if board != null:
		board.camera_position = position
		board.camera_zoom = zoom

func _get_clamped_position(value: Vector2) -> Vector2:
	var board_size: Vector2 = _get_board_size()
	var visible_size: Vector2 = _get_visible_world_size()
	var half_visible: Vector2 = visible_size * 0.5
	var clamped_position: Vector2 = value

	if visible_size.x >= board_size.x:
		clamped_position.x = board_size.x * 0.5
	else:
		clamped_position.x = clampf(value.x, half_visible.x, board_size.x - half_visible.x)

	if visible_size.y >= board_size.y:
		clamped_position.y = board_size.y * 0.5
	else:
		clamped_position.y = clampf(value.y, half_visible.y, board_size.y - half_visible.y)

	return clamped_position

func _get_sanitized_zoom(value: Vector2) -> Vector2:
	var zoom_value: float = value.x
	if zoom_value <= 0.0:
		zoom_value = 1.0
	zoom_value = clampf(zoom_value, _get_effective_min_zoom(), max_zoom)
	return Vector2(zoom_value, zoom_value)

func _get_effective_min_zoom() -> float:
	var viewport_size: Vector2 = _get_viewport_size()
	var board_size: Vector2 = _get_board_size()
	if board_size.x <= 0.0 or board_size.y <= 0.0:
		return min_zoom
	var fit_zoom: float = minf(viewport_size.x / board_size.x, viewport_size.y / board_size.y)
	return minf(min_zoom, fit_zoom)

func _get_visible_world_size() -> Vector2:
	var safe_zoom: float = maxf(0.001, zoom.x)
	return _get_viewport_size() / safe_zoom

func _get_viewport_size() -> Vector2:
	var viewport: Viewport = get_viewport()
	if viewport == null:
		return BoardState.INITIAL_VIEWPORT_SIZE
	return viewport.get_visible_rect().size

func _get_board_size() -> Vector2:
	if board != null:
		return board.size
	return BoardState.DEFAULT_SIZE

func _mark_input_as_handled() -> void:
	var viewport: Viewport = get_viewport()
	if viewport != null:
		viewport.set_input_as_handled()

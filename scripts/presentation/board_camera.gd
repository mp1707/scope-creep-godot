class_name BoardCamera
extends Camera2D

@export var pan_speed: float = 900.0
@export var zoom_step: float = 0.1
@export var min_zoom: float = 0.5
@export var max_zoom: float = 2.0

var _is_panning: bool = false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_MIDDLE:
			_is_panning = mouse_event.pressed
		elif mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_apply_zoom(zoom.x + zoom_step)
		elif mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_apply_zoom(zoom.x - zoom_step)

	if event is InputEventMouseMotion and _is_panning:
		var motion_event: InputEventMouseMotion = event as InputEventMouseMotion
		position -= motion_event.relative / zoom

func _process(delta: float) -> void:
	var input_vector: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if input_vector != Vector2.ZERO:
		position += input_vector * pan_speed * delta / zoom

func _apply_zoom(value: float) -> void:
	var clamped_zoom: float = clampf(value, min_zoom, max_zoom)
	zoom = Vector2(clamped_zoom, clamped_zoom)

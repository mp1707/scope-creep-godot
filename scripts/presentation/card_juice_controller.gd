class_name CardJuiceController
extends Node

enum CardJuiceState {
	IDLE,
	HOVERED,
	DRAGGING,
	SNAPPING,
	DISABLED,
}

const HOVER_SCALE: Vector2 = Vector2(1.04, 1.04)
const DRAG_SCALE: Vector2 = Vector2(1.07, 1.07)
const SNAP_SQUASH_SCALE: Vector2 = Vector2(0.97, 0.97)
const DROP_TARGET_SCALE: Vector2 = Vector2(1.03, 1.03)
const SPAWN_START_SCALE: Vector2 = Vector2(0.84, 0.84)
const SPAWN_PEAK_SCALE: Vector2 = Vector2(1.06, 1.06)

const HOVER_Y_OFFSET: float = -6.0
const DRAG_Y_OFFSET: float = -10.0
const DROP_TARGET_Y_OFFSET: float = -2.0

const HOVER_DURATION: float = 0.12
const DRAG_LIFT_DURATION: float = 0.10
const SNAP_DURATION: float = 0.16
const SNAP_BOUNCE_DURATION: float = 0.10
const SPAWN_UP_DURATION: float = 0.08
const SPAWN_DOWN_DURATION: float = 0.07

const DRAG_FOLLOW_SPEED: float = 22.0
const DRAG_ROTATION_SPEED: float = 18.0
const DRAG_TILT_STRENGTH: float = 0.004
const MAX_DRAG_TILT: float = deg_to_rad(6.0)

const IDLE_SHADOW_OFFSET: Vector2 = Vector2(3.0, 4.0)
const HOVER_SHADOW_OFFSET: Vector2 = Vector2(5.0, 8.0)
const DRAG_SHADOW_OFFSET: Vector2 = Vector2(8.0, 14.0)
const IDLE_SHADOW_SCALE: Vector2 = Vector2.ONE
const HOVER_SHADOW_SCALE: Vector2 = Vector2.ONE
const DRAG_SHADOW_SCALE: Vector2 = Vector2.ONE
const IDLE_SHADOW_OPACITY: float = 0.25
const HOVER_SHADOW_OPACITY: float = 0.32
const DRAG_SHADOW_OPACITY: float = 0.40

var state: int = CardJuiceState.IDLE
var idle_rotation: float = 0.0

var _host: Control = null
var _visual_root: Control = null
var _shadow: Control = null
var _drop_feedback: Control = null
var _active_tween: Tween = null
var _feedback_tween: Tween = null
var _drag_target_position: Vector2 = Vector2.ZERO
var _previous_position: Vector2 = Vector2.ZERO
var _shadow_canvas_scale: Vector2 = Vector2.ONE
var _drop_feedback_active: bool = false

func setup(host: Control, visual_root: Control, shadow: Control, drop_feedback: Control) -> void:
	var needs_initial_state: bool = _host == null or _visual_root == null or _shadow == null
	_host = host
	_visual_root = visual_root
	_shadow = shadow
	_drop_feedback = drop_feedback
	if needs_initial_state:
		set_process(false)
		_apply_immediate(Vector2.ONE, Vector2.ZERO, idle_rotation)
		_apply_shadow_immediate(IDLE_SHADOW_OFFSET, IDLE_SHADOW_SCALE, IDLE_SHADOW_OPACITY)
	if needs_initial_state and _drop_feedback != null:
		_drop_feedback.visible = false
		_drop_feedback.modulate.a = 0.0

func set_idle_rotation(value: float) -> void:
	idle_rotation = value
	if state == CardJuiceState.IDLE and _visual_root != null:
		_visual_root.rotation = idle_rotation

func is_hovered() -> bool:
	return state == CardJuiceState.HOVERED

func play_idle(immediate: bool = false) -> void:
	if state == CardJuiceState.DISABLED:
		return
	state = CardJuiceState.IDLE
	set_process(false)
	_kill_active_tween()
	if immediate or not _can_tween():
		_apply_immediate(Vector2.ONE, Vector2.ZERO, idle_rotation)
		_apply_shadow_immediate(IDLE_SHADOW_OFFSET, IDLE_SHADOW_SCALE, IDLE_SHADOW_OPACITY)
		return
	_active_tween = create_tween()
	_active_tween.set_parallel(true)
	_tween_visual(_active_tween, Vector2.ONE, Vector2.ZERO, idle_rotation, HOVER_DURATION)
	_tween_shadow(_active_tween, IDLE_SHADOW_OFFSET, IDLE_SHADOW_SCALE, IDLE_SHADOW_OPACITY, HOVER_DURATION)
	_active_tween.finished.connect(_on_state_tween_finished)

func play_hover() -> void:
	if state == CardJuiceState.DRAGGING or state == CardJuiceState.SNAPPING or state == CardJuiceState.DISABLED:
		return
	state = CardJuiceState.HOVERED
	set_process(false)
	_kill_active_tween()
	if not _can_tween():
		_apply_immediate(HOVER_SCALE, Vector2(0.0, HOVER_Y_OFFSET), 0.0)
		_apply_shadow_immediate(HOVER_SHADOW_OFFSET, HOVER_SHADOW_SCALE, HOVER_SHADOW_OPACITY)
		return
	_active_tween = create_tween()
	_active_tween.set_parallel(true)
	_tween_visual(_active_tween, HOVER_SCALE, Vector2(0.0, HOVER_Y_OFFSET), 0.0, HOVER_DURATION)
	_tween_shadow(_active_tween, HOVER_SHADOW_OFFSET, HOVER_SHADOW_SCALE, HOVER_SHADOW_OPACITY, HOVER_DURATION)
	_active_tween.finished.connect(_on_state_tween_finished)

func play_drag_start(target_position: Vector2) -> void:
	if _host == null:
		return
	state = CardJuiceState.DRAGGING
	_drag_target_position = target_position
	_previous_position = _host.position
	set_process(true)
	_kill_active_tween()
	if not _can_tween():
		_apply_immediate(DRAG_SCALE, Vector2(0.0, DRAG_Y_OFFSET), 0.0)
		_apply_shadow_immediate(DRAG_SHADOW_OFFSET, DRAG_SHADOW_SCALE, DRAG_SHADOW_OPACITY)
		return
	_active_tween = create_tween()
	_active_tween.set_parallel(true)
	_tween_visual(_active_tween, DRAG_SCALE, Vector2(0.0, DRAG_Y_OFFSET), 0.0, DRAG_LIFT_DURATION)
	_tween_shadow(_active_tween, DRAG_SHADOW_OFFSET, DRAG_SHADOW_SCALE, DRAG_SHADOW_OPACITY, DRAG_LIFT_DURATION)
	_active_tween.finished.connect(_on_state_tween_finished)

func set_drag_target_position(target_position: Vector2) -> void:
	_drag_target_position = target_position
	if state != CardJuiceState.DRAGGING and _host != null:
		_host.position = target_position

func set_shadow_canvas_scale(canvas_scale: Vector2) -> void:
	_shadow_canvas_scale = Vector2(maxf(0.001, canvas_scale.x), maxf(0.001, canvas_scale.y))
	if state == CardJuiceState.DRAGGING:
		_apply_shadow_immediate(DRAG_SHADOW_OFFSET, DRAG_SHADOW_SCALE, DRAG_SHADOW_OPACITY)

func play_snap(target_position: Vector2, target_idle_rotation: float) -> void:
	if _host == null:
		return
	idle_rotation = target_idle_rotation
	state = CardJuiceState.SNAPPING
	set_process(false)
	_kill_active_tween()
	if not _can_tween():
		_host.position = target_position
		_apply_immediate(Vector2.ONE, Vector2.ZERO, idle_rotation)
		_apply_shadow_immediate(IDLE_SHADOW_OFFSET, IDLE_SHADOW_SCALE, IDLE_SHADOW_OPACITY)
		state = CardJuiceState.IDLE
		return
	_active_tween = create_tween()
	_active_tween.set_parallel(true)
	_active_tween.tween_property(_host, "position", target_position, SNAP_DURATION)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)
	_active_tween.tween_property(_visual_root, "position", Vector2.ZERO, SNAP_DURATION)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
	_active_tween.tween_property(_visual_root, "rotation", idle_rotation, 0.14)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
	_active_tween.tween_property(_visual_root, "scale", SNAP_SQUASH_SCALE, 0.08)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
	_tween_shadow(_active_tween, IDLE_SHADOW_OFFSET, IDLE_SHADOW_SCALE, IDLE_SHADOW_OPACITY, 0.14)
	_active_tween.chain().tween_property(_visual_root, "scale", Vector2.ONE, SNAP_BOUNCE_DURATION)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)
	_active_tween.finished.connect(_on_snap_finished)

func play_spawn_pop() -> void:
	if _visual_root == null:
		return
	_kill_active_tween()
	if not _can_tween():
		_apply_immediate(Vector2.ONE, Vector2.ZERO, idle_rotation)
		return
	state = CardJuiceState.IDLE
	_visual_root.scale = SPAWN_START_SCALE
	_visual_root.position = Vector2.ZERO
	_visual_root.rotation = idle_rotation
	_active_tween = create_tween()
	_active_tween.tween_property(_visual_root, "scale", SPAWN_PEAK_SCALE, SPAWN_UP_DURATION)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
	_active_tween.tween_property(_visual_root, "scale", Vector2.ONE, SPAWN_DOWN_DURATION)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)
	_active_tween.finished.connect(_on_state_tween_finished)

func set_drop_target_feedback(active: bool) -> void:
	if _drop_feedback == null or _drop_feedback_active == active:
		return
	_drop_feedback_active = active
	_kill_feedback_tween()
	if not _can_tween():
		_drop_feedback.visible = active
		_drop_feedback.modulate.a = 1.0 if active else 0.0
		return
	_drop_feedback.visible = true
	_feedback_tween = create_tween()
	_feedback_tween.tween_property(_drop_feedback, "modulate:a", 1.0 if active else 0.0, 0.10)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
	if not active:
		_feedback_tween.tween_callback(func() -> void:
			if _drop_feedback != null and not _drop_feedback_active:
				_drop_feedback.visible = false
		)

func play_drop_target_pulse() -> void:
	if _drop_feedback == null or _visual_root == null:
		return
	_kill_feedback_tween()
	if not _can_tween():
		return
	_drop_feedback.visible = true
	_drop_feedback.modulate.a = 1.0
	_feedback_tween = create_tween()
	_feedback_tween.set_parallel(true)
	_feedback_tween.tween_property(_visual_root, "scale", DROP_TARGET_SCALE, 0.07)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
	_feedback_tween.tween_property(_visual_root, "position", Vector2(0.0, DROP_TARGET_Y_OFFSET), 0.07)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
	_feedback_tween.tween_property(_drop_feedback, "modulate:a", 1.0, 0.04)
	_feedback_tween.chain().set_parallel(true)
	_feedback_tween.tween_property(_visual_root, "scale", Vector2.ONE, 0.10)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)
	_feedback_tween.tween_property(_visual_root, "position", Vector2.ZERO, 0.10)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
	_feedback_tween.tween_property(_drop_feedback, "modulate:a", 0.0, 0.10)
	_feedback_tween.finished.connect(func() -> void:
		if _drop_feedback != null and not _drop_feedback_active:
			_drop_feedback.visible = false
		_feedback_tween = null
	)

func _process(delta: float) -> void:
	if state != CardJuiceState.DRAGGING or _host == null or _visual_root == null:
		return
	var follow_weight: float = 1.0 - exp(-DRAG_FOLLOW_SPEED * delta)
	_host.position = _host.position.lerp(_drag_target_position, follow_weight)

	var velocity: Vector2 = (_host.position - _previous_position) / maxf(delta, 0.001)
	var target_rotation: float = clampf(
		velocity.x * DRAG_TILT_STRENGTH,
		-MAX_DRAG_TILT,
		MAX_DRAG_TILT
	)
	var rotation_weight: float = 1.0 - exp(-DRAG_ROTATION_SPEED * delta)
	_visual_root.rotation = lerp_angle(_visual_root.rotation, target_rotation, rotation_weight)
	_previous_position = _host.position

func _tween_visual(tween: Tween, target_scale: Vector2, target_position: Vector2, target_rotation: float, duration: float) -> void:
	tween.tween_property(_visual_root, "scale", target_scale, duration)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)
	tween.tween_property(_visual_root, "position", target_position, duration)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
	tween.tween_property(_visual_root, "rotation", target_rotation, duration)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)

func _tween_shadow(tween: Tween, target_offset: Vector2, target_scale: Vector2, target_opacity: float, duration: float) -> void:
	if _shadow == null:
		return
	_shadow.visible = true
	tween.tween_property(_shadow, "position", _scaled_shadow_offset(target_offset), duration)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
	tween.tween_property(_shadow, "scale", target_scale, duration)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
	tween.tween_property(_shadow, "modulate:a", target_opacity, duration)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)

func _apply_immediate(target_scale: Vector2, target_position: Vector2, target_rotation: float) -> void:
	if _visual_root == null:
		return
	_visual_root.scale = target_scale
	_visual_root.position = target_position
	_visual_root.rotation = target_rotation

func _apply_shadow_immediate(target_offset: Vector2, target_scale: Vector2, target_opacity: float) -> void:
	if _shadow == null:
		return
	_shadow.visible = true
	_shadow.position = _scaled_shadow_offset(target_offset)
	_shadow.scale = target_scale
	_shadow.modulate.a = target_opacity

func _scaled_shadow_offset(offset: Vector2) -> Vector2:
	return Vector2(offset.x / _shadow_canvas_scale.x, offset.y / _shadow_canvas_scale.y)

func _can_tween() -> bool:
	return is_inside_tree() and DisplayServer.get_name() != "headless" and _visual_root != null

func _kill_active_tween() -> void:
	if _active_tween != null and _active_tween.is_valid():
		_active_tween.kill()
	_active_tween = null

func _kill_feedback_tween() -> void:
	if _feedback_tween != null and _feedback_tween.is_valid():
		_feedback_tween.kill()
	_feedback_tween = null

func _on_state_tween_finished() -> void:
	_active_tween = null

func _on_snap_finished() -> void:
	state = CardJuiceState.IDLE
	_active_tween = null
	_apply_immediate(Vector2.ONE, Vector2.ZERO, idle_rotation)
	_apply_shadow_immediate(IDLE_SHADOW_OFFSET, IDLE_SHADOW_SCALE, IDLE_SHADOW_OPACITY)

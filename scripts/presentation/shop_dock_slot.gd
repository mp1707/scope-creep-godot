@tool
class_name ShopDockSlot
extends Control

const PREVIEW_CARD_SIZE: Vector2 = Vector2(144.0, 196.0)
const PREVIEW_FILL_COLOR: Color = Color(0.98, 0.88, 0.58, 0.42)
const PREVIEW_HEADER_COLOR: Color = Color(0.76, 0.60, 0.32, 0.42)
const PREVIEW_HAIRLINE_COLOR: Color = Color(0.055, 0.052, 0.047, 0.22)
const PREVIEW_HOVER_COLOR: Color = Color(0.28, 0.56, 0.78, 0.18)
const DROP_FEEDBACK_FILL_COLOR: Color = Color(0.055, 0.052, 0.047, 0.08)
const PREVIEW_TEXT_COLOR: Color = Color(0.055, 0.052, 0.047, 0.78)
const PREVIEW_FONT_SIZE: int = 18
const PREVIEW_HEADER_HEIGHT: float = 24.0
const PULSE_DURATION: float = 0.08

@export var card_definition_id: String = "":
	set(value):
		card_definition_id = value
		queue_redraw()
@export var preview_label: String = "":
	set(value):
		preview_label = value
		queue_redraw()
@export var card_offset: Vector2 = Vector2.ZERO:
	set(value):
		card_offset = value
		queue_redraw()
@export var hover_offset: Vector2 = Vector2(0.0, -54.0):
	set(value):
		hover_offset = value
		queue_redraw()
@export var show_editor_preview: bool = true:
	set(value):
		show_editor_preview = value
		queue_redraw()

var pulse_amount: float = 0.0:
	set(value):
		pulse_amount = value
		queue_redraw()

var _drop_feedback_active: bool = false
var _pulse_tween: Tween = null

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = PREVIEW_CARD_SIZE
	queue_redraw()

func get_card_position(is_hovered: bool) -> Vector2:
	if is_hovered:
		return card_offset + hover_offset
	return card_offset

func set_drop_feedback(active: bool) -> void:
	if _drop_feedback_active == active:
		return
	_drop_feedback_active = active
	queue_redraw()

func play_drop_pulse() -> void:
	if not is_inside_tree() or Engine.is_editor_hint() or DisplayServer.get_name() == "headless":
		pulse_amount = 0.0
		return
	if _pulse_tween != null and _pulse_tween.is_valid():
		_pulse_tween.kill()
	_pulse_tween = create_tween()
	_pulse_tween.tween_property(self, "pulse_amount", 1.0, PULSE_DURATION)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
	_pulse_tween.tween_property(self, "pulse_amount", 0.0, PULSE_DURATION)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)
	_pulse_tween.finished.connect(func() -> void:
		_pulse_tween = null
	)

func _draw() -> void:
	if _drop_feedback_active or pulse_amount > 0.0:
		_draw_drop_feedback()
	if Engine.is_editor_hint() and show_editor_preview:
		_draw_editor_preview()

func _draw_drop_feedback() -> void:
	var feedback_rect: Rect2 = Rect2(card_offset + hover_offset, PREVIEW_CARD_SIZE)
	var pulse_scale: float = 1.0 + pulse_amount * 0.05
	var center: Vector2 = feedback_rect.get_center()
	feedback_rect.size *= pulse_scale
	feedback_rect.position = center - feedback_rect.size * 0.5
	var fill: Color = DROP_FEEDBACK_FILL_COLOR
	fill.a *= 1.0 if _drop_feedback_active else pulse_amount
	draw_rect(feedback_rect, fill, true)

func _draw_editor_preview() -> void:
	var card_rect: Rect2 = Rect2(card_offset, PREVIEW_CARD_SIZE)
	draw_rect(card_rect, PREVIEW_FILL_COLOR, true)
	draw_rect(Rect2(card_rect.position, Vector2(card_rect.size.x, PREVIEW_HEADER_HEIGHT)), PREVIEW_HEADER_COLOR, true)
	draw_line(
		card_rect.position + Vector2(0.0, PREVIEW_HEADER_HEIGHT),
		card_rect.position + Vector2(card_rect.size.x, PREVIEW_HEADER_HEIGHT),
		PREVIEW_HAIRLINE_COLOR,
		1.0
	)

	var hover_rect: Rect2 = Rect2(card_offset + hover_offset, PREVIEW_CARD_SIZE)
	draw_rect(hover_rect, PREVIEW_HOVER_COLOR, true)
	draw_line(card_rect.get_center(), hover_rect.get_center(), Color(PREVIEW_HOVER_COLOR, 0.55), 2.0)

	var font: Font = get_theme_default_font()
	if font == null:
		return
	var label: String = _get_preview_label()
	draw_string(font, card_rect.position + Vector2(10.0, 18.0), label, HORIZONTAL_ALIGNMENT_LEFT, card_rect.size.x - 20.0, PREVIEW_FONT_SIZE, PREVIEW_TEXT_COLOR)
	draw_string(font, card_rect.position + Vector2(10.0, 62.0), "ShopDockSlot", HORIZONTAL_ALIGNMENT_LEFT, card_rect.size.x - 20.0, PREVIEW_FONT_SIZE, Color(PREVIEW_TEXT_COLOR, 0.52))

func _get_preview_label() -> String:
	if not preview_label.is_empty():
		return preview_label
	if not card_definition_id.is_empty():
		return card_definition_id.get_slice(".", card_definition_id.get_slice_count(".") - 1).capitalize()
	return name

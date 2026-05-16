class_name InteractionHighlightView
extends Control

const DEFAULT_DASH_LENGTH: float = 10.0
const DEFAULT_DASH_GAP: float = 7.0
const DEFAULT_LINE_WIDTH: float = 2.0
const DEFAULT_ALPHA: float = 1.0
const DEFAULT_PULSE_ALPHA: float = 0.0
const DEFAULT_PULSE_WIDTH: float = 0.0
const DEFAULT_DASH_SPEED: float = 23.4
const DEFAULT_PULSE_SPEED: float = 2.4
const DEFAULT_INSET: float = 8.0
const DEFAULT_LINE_COLOR: Color = Color(0.075, 0.095, 0.12, 1.0)
const SHOW_SCALE_START: Vector2 = Vector2(0.965, 0.965)
const SHOW_DURATION: float = 0.12

@export var dash_length: float = DEFAULT_DASH_LENGTH
@export var dash_gap: float = DEFAULT_DASH_GAP
@export var line_width: float = DEFAULT_LINE_WIDTH
@export var base_alpha: float = DEFAULT_ALPHA
@export var pulse_alpha: float = DEFAULT_PULSE_ALPHA
@export var pulse_width: float = DEFAULT_PULSE_WIDTH
@export var dash_speed: float = DEFAULT_DASH_SPEED
@export var pulse_speed: float = DEFAULT_PULSE_SPEED
@export var line_inset: float = DEFAULT_INSET

var line_color: Color = DEFAULT_LINE_COLOR:
	set(value):
		line_color = value
		queue_redraw()

var _dash_offset: float = 0.0
var _pulse_seconds: float = 0.0
var _show_tween: Tween = null

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	pivot_offset = size * 0.5
	set_process(true)

func configure(highlight_size: Vector2, visual_theme: Resource = null) -> void:
	apply_visual_theme(visual_theme)
	size = highlight_size
	custom_minimum_size = size
	pivot_offset = size * 0.5
	queue_redraw()

func apply_visual_theme(visual_theme: Resource) -> void:
	if visual_theme == null:
		return
	dash_length = _get_theme_float(visual_theme, "interaction_preview_dash_length", dash_length)
	dash_gap = _get_theme_float(visual_theme, "interaction_preview_dash_gap", dash_gap)
	line_width = _get_theme_float(visual_theme, "interaction_preview_line_width", line_width)
	base_alpha = _get_theme_float(visual_theme, "interaction_preview_alpha", base_alpha)
	pulse_alpha = _get_theme_float(visual_theme, "interaction_preview_pulse_alpha", pulse_alpha)
	pulse_width = _get_theme_float(visual_theme, "interaction_preview_pulse_width", pulse_width)
	dash_speed = _get_theme_float(visual_theme, "interaction_preview_dash_speed", dash_speed)
	pulse_speed = _get_theme_float(visual_theme, "interaction_preview_pulse_speed", pulse_speed)
	line_inset = _get_theme_float(visual_theme, "interaction_preview_line_inset", line_inset)
	var theme_line_color: Variant = visual_theme.get("card_text_color")
	if theme_line_color is Color:
		line_color = theme_line_color as Color

func play_show() -> void:
	if DisplayServer.get_name() == "headless" or not is_inside_tree():
		scale = Vector2.ONE
		modulate.a = 1.0
		return
	if _show_tween != null and _show_tween.is_valid():
		_show_tween.kill()
	scale = SHOW_SCALE_START
	modulate.a = 0.0
	_show_tween = create_tween()
	_show_tween.set_parallel(true)
	_show_tween.tween_property(self, "scale", Vector2.ONE, SHOW_DURATION)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)
	_show_tween.tween_property(self, "modulate:a", 1.0, SHOW_DURATION * 0.75)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
	_show_tween.finished.connect(func() -> void:
		_show_tween = null
	)

func is_animating() -> bool:
	return is_processing()

func _process(delta: float) -> void:
	_dash_offset = fmod(_dash_offset + dash_speed * delta, maxf(0.001, dash_length + dash_gap))
	_pulse_seconds += delta
	queue_redraw()

func _draw() -> void:
	if size.x <= line_inset * 2.0 or size.y <= line_inset * 2.0:
		return
	var pulse: float = (sin(_pulse_seconds * pulse_speed) + 1.0) * 0.5
	var draw_color: Color = line_color
	draw_color.a *= clampf(base_alpha + pulse * pulse_alpha, 0.0, 1.0)
	var width: float = line_width + pulse * pulse_width
	var rect: Rect2 = Rect2(Vector2(line_inset, line_inset), size - Vector2(line_inset * 2.0, line_inset * 2.0))
	var corner_gap: float = maxf(roundf(width * 1.5), 3.0)
	if rect.size.x <= corner_gap * 2.0 or rect.size.y <= corner_gap * 2.0:
		return
	var top_left: Vector2 = rect.position
	var top_right: Vector2 = rect.position + Vector2(rect.size.x, 0.0)
	var bottom_right: Vector2 = rect.end
	var bottom_left: Vector2 = rect.position + Vector2(0.0, rect.size.y)
	_draw_dashed_line(top_left + Vector2(corner_gap, 0.0), top_right - Vector2(corner_gap, 0.0), draw_color, width)
	_draw_dashed_line(top_right + Vector2(0.0, corner_gap), bottom_right - Vector2(0.0, corner_gap), draw_color, width)
	_draw_dashed_line(bottom_right - Vector2(corner_gap, 0.0), bottom_left + Vector2(corner_gap, 0.0), draw_color, width)
	_draw_dashed_line(bottom_left - Vector2(0.0, corner_gap), top_left + Vector2(0.0, corner_gap), draw_color, width)

func _draw_dashed_line(from: Vector2, to: Vector2, color: Color, width: float) -> void:
	var vector: Vector2 = to - from
	var length: float = vector.length()
	if length <= 0.001:
		return
	var direction: Vector2 = vector / length
	var cycle: float = maxf(0.001, dash_length + dash_gap)
	var cursor: float = -fmod(_dash_offset, cycle)
	while cursor < length:
		var start_distance: float = maxf(0.0, cursor)
		var end_distance: float = minf(length, cursor + dash_length)
		if end_distance > start_distance:
			_draw_dash_segment(from + direction * start_distance, from + direction * end_distance, color, width)
		cursor += cycle

func _draw_dash_segment(from: Vector2, to: Vector2, color: Color, width: float) -> void:
	if from.is_equal_approx(to):
		return
	var pixel_width: float = maxf(1.0, roundf(width))
	var radius: float = pixel_width * 0.5
	if is_equal_approx(from.y, to.y):
		var left: float = roundf(minf(from.x, to.x))
		var right: float = roundf(maxf(from.x, to.x))
		var y: float = roundf(from.y - pixel_width * 0.5)
		draw_rect(Rect2(Vector2(left, y), Vector2(maxf(1.0, right - left), pixel_width)), color, true)
		draw_circle(Vector2(left, y + radius), radius, color)
		draw_circle(Vector2(right, y + radius), radius, color)
		return
	var top: float = roundf(minf(from.y, to.y))
	var bottom: float = roundf(maxf(from.y, to.y))
	var x: float = roundf(from.x - pixel_width * 0.5)
	draw_rect(Rect2(Vector2(x, top), Vector2(pixel_width, maxf(1.0, bottom - top))), color, true)
	draw_circle(Vector2(x + radius, top), radius, color)
	draw_circle(Vector2(x + radius, bottom), radius, color)

func _get_theme_float(visual_theme: Resource, property_name: String, fallback: float) -> float:
	var value: Variant = visual_theme.get(property_name)
	if value is float or value is int:
		return float(value)
	return fallback

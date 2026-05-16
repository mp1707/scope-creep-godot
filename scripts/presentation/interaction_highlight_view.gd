class_name InteractionHighlightView
extends Control

const DEFAULT_DASH_LENGTH: float = 10.0
const DEFAULT_DASH_GAP: float = 7.0
const DEFAULT_LINE_WIDTH: float = 2.5
const DEFAULT_ALPHA: float = 0.86
const DEFAULT_PULSE_ALPHA: float = 0.12
const DEFAULT_PULSE_WIDTH: float = 0.7
const DEFAULT_DASH_SPEED: float = 23.4
const DEFAULT_PULSE_SPEED: float = 2.4
const DEFAULT_INSET: float = 8.0
const DEFAULT_COLOR_DARKEN: float = 0.08
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
@export_range(0.0, 1.0, 0.01) var color_darken: float = DEFAULT_COLOR_DARKEN

var target_color: Color = Color.WHITE:
	set(value):
		target_color = value
		queue_redraw()

var paper_texture: Texture2D = null
var _dash_offset: float = 0.0
var _pulse_seconds: float = 0.0
var _show_tween: Tween = null

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	pivot_offset = size * 0.5
	set_process(true)

func configure(highlight_color: Color, highlight_size: Vector2, visual_theme: Resource = null) -> void:
	apply_visual_theme(visual_theme)
	target_color = highlight_color
	size = highlight_size
	custom_minimum_size = highlight_size
	pivot_offset = highlight_size * 0.5
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
	color_darken = _get_theme_float(visual_theme, "interaction_preview_color_darken", color_darken)
	var theme_paper_texture: Variant = visual_theme.get("card_paper_texture")
	if theme_paper_texture is Texture2D:
		paper_texture = theme_paper_texture as Texture2D

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
	var draw_color: Color = target_color.darkened(color_darken)
	draw_color.a *= clampf(base_alpha + pulse * pulse_alpha, 0.0, 1.0)
	var width: float = line_width + pulse * pulse_width
	var rect: Rect2 = Rect2(Vector2(line_inset, line_inset), size - Vector2(line_inset * 2.0, line_inset * 2.0))
	_draw_dashed_line(rect.position, rect.position + Vector2(rect.size.x, 0.0), draw_color, width)
	_draw_dashed_line(rect.position + Vector2(rect.size.x, 0.0), rect.end, draw_color, width)
	_draw_dashed_line(rect.end, rect.position + Vector2(0.0, rect.size.y), draw_color, width)
	_draw_dashed_line(rect.position + Vector2(0.0, rect.size.y), rect.position, draw_color, width)

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
	if paper_texture == null:
		draw_line(from, to, color, width, true)
		var radius: float = width * 0.5
		draw_circle(from, radius, color)
		draw_circle(to, radius, color)
	else:
		_draw_textured_axis_aligned_dash(from, to, color, width, true)
		_draw_textured_cap(from, color, width)
		_draw_textured_cap(to, color, width)

func _draw_textured_axis_aligned_dash(from: Vector2, to: Vector2, color: Color, width: float, skip_caps: bool = false) -> void:
	var min_position: Vector2 = Vector2(minf(from.x, to.x), minf(from.y, to.y))
	var max_position: Vector2 = Vector2(maxf(from.x, to.x), maxf(from.y, to.y))
	var rect: Rect2
	if is_equal_approx(from.y, to.y):
		var left: float = min_position.x + (width * 0.5 if skip_caps else 0.0)
		var right: float = max_position.x - (width * 0.5 if skip_caps else 0.0)
		rect = Rect2(Vector2(left, from.y - width * 0.5), Vector2(maxf(1.0, right - left), width))
	else:
		var top: float = min_position.y + (width * 0.5 if skip_caps else 0.0)
		var bottom: float = max_position.y - (width * 0.5 if skip_caps else 0.0)
		rect = Rect2(Vector2(from.x - width * 0.5, top), Vector2(width, maxf(1.0, bottom - top)))
	var source_position: Vector2 = Vector2(fmod(rect.position.x, paper_texture.get_width()), fmod(rect.position.y, paper_texture.get_height()))
	var source_rect: Rect2 = Rect2(source_position, Vector2(minf(rect.size.x, paper_texture.get_width()), minf(rect.size.y, paper_texture.get_height())))
	draw_texture_rect_region(paper_texture, rect, source_rect, color)

func _draw_textured_cap(center: Vector2, color: Color, width: float) -> void:
	var radius: float = width * 0.5
	var rect: Rect2 = Rect2(center - Vector2(radius, radius), Vector2(width, width))
	var source_position: Vector2 = Vector2(fmod(rect.position.x, paper_texture.get_width()), fmod(rect.position.y, paper_texture.get_height()))
	var source_rect: Rect2 = Rect2(source_position, Vector2(minf(rect.size.x, paper_texture.get_width()), minf(rect.size.y, paper_texture.get_height())))
	draw_texture_rect_region(paper_texture, rect, source_rect, color)

func _get_theme_float(visual_theme: Resource, property_name: String, fallback: float) -> float:
	var value: Variant = visual_theme.get(property_name)
	if value is float or value is int:
		return float(value)
	return fallback

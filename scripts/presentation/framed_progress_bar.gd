class_name FramedProgressBar
extends Control

@export var background_color: Color = Color(0.99, 0.985, 0.955, 1.0):
	set(new_value):
		background_color = new_value
		queue_redraw()
@export var fill_color: Color = Color(0.56, 0.78, 0.90, 1.0):
	set(new_value):
		fill_color = new_value
		queue_redraw()
@export var border_color: Color = Color(0.055, 0.052, 0.047, 1.0):
	set(new_value):
		border_color = new_value
		queue_redraw()
@export_range(0, 16, 1, "or_greater") var border_width: int = 4:
	set(new_value):
		border_width = maxi(new_value, 0)
		queue_redraw()
@export_range(0, 32, 1, "or_greater") var corner_radius: int = 7:
	set(new_value):
		corner_radius = maxi(new_value, 0)
		queue_redraw()

var max_value: float = 100.0:
	set(new_value):
		max_value = maxf(new_value, 0.001)
		queue_redraw()
var value: float = 0.0:
	set(new_value):
		value = maxf(new_value, 0.0)
		queue_redraw()

func _draw() -> void:
	var bar_rect: Rect2 = Rect2(Vector2.ZERO, size)
	if bar_rect.size.x <= 0.0 or bar_rect.size.y <= 0.0:
		return

	draw_style_box(_create_background_style(), bar_rect)
	_draw_fill()
	draw_style_box(_create_frame_style(), bar_rect)

func _draw_fill() -> void:
	var inset: float = float(border_width)
	var inner_size: Vector2 = size - Vector2(inset * 2.0, inset * 2.0)
	if inner_size.x <= 0.0 or inner_size.y <= 0.0:
		return

	var ratio: float = clampf(value / max_value, 0.0, 1.0)
	if ratio <= 0.0:
		return

	var fill_rect: Rect2 = Rect2(Vector2(inset, inset), Vector2(inner_size.x * ratio, inner_size.y))
	var fill_style: StyleBoxFlat = StyleBoxFlat.new()
	fill_style.bg_color = fill_color
	var fill_radius: int = maxi(corner_radius - border_width, 0)
	fill_style.corner_radius_bottom_left = fill_radius
	fill_style.corner_radius_bottom_right = fill_radius
	fill_style.corner_radius_top_left = fill_radius
	fill_style.corner_radius_top_right = fill_radius
	draw_style_box(fill_style, fill_rect)

func _create_background_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = background_color
	style.corner_radius_bottom_left = corner_radius
	style.corner_radius_bottom_right = corner_radius
	style.corner_radius_top_left = corner_radius
	style.corner_radius_top_right = corner_radius
	return style

func _create_frame_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	style.border_color = border_color
	style.border_width_bottom = border_width
	style.border_width_left = border_width
	style.border_width_right = border_width
	style.border_width_top = border_width
	style.corner_radius_bottom_left = corner_radius
	style.corner_radius_bottom_right = corner_radius
	style.corner_radius_top_left = corner_radius
	style.corner_radius_top_right = corner_radius
	return style

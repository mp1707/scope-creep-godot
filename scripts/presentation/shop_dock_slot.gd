@tool
class_name ShopDockSlot
extends Control

const PREVIEW_CARD_SIZE: Vector2 = Vector2(144.0, 196.0)
const PREVIEW_FILL_COLOR: Color = Color(0.98, 0.88, 0.58, 0.42)
const PREVIEW_HEADER_COLOR: Color = Color(0.76, 0.60, 0.32, 0.42)
const PREVIEW_HAIRLINE_COLOR: Color = Color(0.055, 0.052, 0.047, 0.22)
const PREVIEW_HOVER_COLOR: Color = Color(0.28, 0.56, 0.78, 0.18)
const PREVIEW_TEXT_COLOR: Color = Color(0.055, 0.052, 0.047, 0.78)
const PREVIEW_FONT_SIZE: int = 15
const PREVIEW_HEADER_HEIGHT: float = 34.0

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

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = PREVIEW_CARD_SIZE
	queue_redraw()

func get_card_position(is_hovered: bool) -> Vector2:
	if is_hovered:
		return card_offset + hover_offset
	return card_offset

func _draw() -> void:
	if not Engine.is_editor_hint() or not show_editor_preview:
		return

	var card_rect: Rect2 = Rect2(card_offset, PREVIEW_CARD_SIZE)
	draw_rect(card_rect, PREVIEW_FILL_COLOR, true)
	draw_rect(Rect2(card_rect.position, Vector2(card_rect.size.x, PREVIEW_HEADER_HEIGHT)), PREVIEW_HEADER_COLOR, true)
	draw_rect(card_rect, PREVIEW_HAIRLINE_COLOR, false, 1.0)

	var hover_rect: Rect2 = Rect2(card_offset + hover_offset, PREVIEW_CARD_SIZE)
	draw_rect(hover_rect, PREVIEW_HOVER_COLOR, true)
	draw_line(card_rect.get_center(), hover_rect.get_center(), Color(PREVIEW_HOVER_COLOR, 0.55), 2.0)

	var font: Font = get_theme_default_font()
	if font == null:
		return
	var label: String = _get_preview_label()
	draw_string(font, card_rect.position + Vector2(10.0, 24.0), label, HORIZONTAL_ALIGNMENT_LEFT, card_rect.size.x - 20.0, PREVIEW_FONT_SIZE, PREVIEW_TEXT_COLOR)
	draw_string(font, card_rect.position + Vector2(10.0, 58.0), "ShopDockSlot", HORIZONTAL_ALIGNMENT_LEFT, card_rect.size.x - 20.0, 11, Color(PREVIEW_TEXT_COLOR, 0.52))

func _get_preview_label() -> String:
	if not preview_label.is_empty():
		return preview_label
	if not card_definition_id.is_empty():
		return card_definition_id.get_slice(".", card_definition_id.get_slice_count(".") - 1).capitalize()
	return name

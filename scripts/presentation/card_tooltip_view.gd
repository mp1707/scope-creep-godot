class_name CardTooltipView
extends PanelContainer

const TOOLTIP_BACKGROUND_COLOR: Color = Color(0.18, 0.22, 0.24, 0.98)
const TOOLTIP_TEXT_COLOR: Color = Color(0.075, 0.095, 0.12, 1.0)
const TOOLTIP_MAX_WIDTH: float = 286.0
const TOOLTIP_MIN_WIDTH: float = 150.0
const TOOLTIP_FONT_SIZE: int = 18
const TOOLTIP_TIME_FONT_SIZE: int = 18
const TOOLTIP_CONTENT_MARGIN: int = 12
const TOOLTIP_SHADOW_OFFSET: Vector2 = Vector2(3.0, 4.0)
const TOOLTIP_SHADOW_OPACITY: float = 0.25
const TOOLTIP_CURSOR_OFFSET: Vector2 = Vector2(22.0, 24.0)
const TOOLTIP_VIEWPORT_MARGIN: float = 12.0
const CARD_FONT_PATH: String = "res://assets/fonts/PatrickHand-Regular.ttf"

@export var plain_label_path: NodePath = NodePath("PlainLabel")
@export var processing_container_path: NodePath = NodePath("ProcessingContainer")
@export var processing_title_label_path: NodePath = NodePath("ProcessingContainer/TitleLabel")
@export var processing_duration_row_path: NodePath = NodePath("ProcessingContainer/DurationRow")
@export var processing_duration_label_path: NodePath = NodePath("ProcessingContainer/DurationRow/DurationLabel")
@export var processing_duration_value_label_path: NodePath = NodePath("ProcessingContainer/DurationRow/DurationValueLabel")

var visual_theme: Resource = null

var _plain_label: Label = null
var _processing_container: VBoxContainer = null
var _processing_title_label: Label = null
var _processing_duration_row: HBoxContainer = null
var _processing_duration_label: Label = null
var _processing_duration_value_label: Label = null
var _card_font: FontFile = null

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_resolve_required_nodes()
	_apply_style()

func set_visual_theme(new_visual_theme: Resource) -> void:
	visual_theme = new_visual_theme
	_resolve_required_nodes()
	_apply_style()

func show_plain(text: String) -> void:
	_resolve_required_nodes()
	if _plain_label == null:
		return
	_plain_label.visible = true
	if _processing_container != null:
		_processing_container.visible = false
	_plain_label.text = text
	_plain_label.custom_minimum_size.x = _get_tooltip_text_width(text, _plain_label.get_theme_font("font"))
	visible = true
	reset_size()

func show_processing(action_title: String, remaining_seconds: float) -> void:
	_resolve_required_nodes()
	if _processing_container == null or _processing_title_label == null or _processing_duration_row == null:
		return
	if _plain_label != null:
		_plain_label.visible = false
	_processing_container.visible = true
	var title_text: String = _get_processing_title_text(action_title)
	var remaining_text: String = "%d Sek" % ceili(maxf(remaining_seconds, 0.0))
	var content_width: float = _get_processing_tooltip_width(title_text, remaining_text)

	_processing_title_label.text = title_text
	_processing_title_label.custom_minimum_size.x = content_width
	_processing_duration_row.custom_minimum_size.x = content_width
	if _processing_duration_label != null:
		_processing_duration_label.text = "Restdauer:"
	if _processing_duration_value_label != null:
		_processing_duration_value_label.text = remaining_text
	visible = true
	reset_size()

func hide_tooltip() -> void:
	visible = false

func position_near_pointer(viewport: Viewport, mouse_position: Vector2) -> void:
	if viewport == null:
		return
	var viewport_size: Vector2 = viewport.get_visible_rect().size
	var tooltip_size: Vector2 = get_combined_minimum_size()
	var target_position: Vector2 = mouse_position + TOOLTIP_CURSOR_OFFSET

	if target_position.x + tooltip_size.x > viewport_size.x - TOOLTIP_VIEWPORT_MARGIN:
		target_position.x = mouse_position.x - TOOLTIP_CURSOR_OFFSET.x - tooltip_size.x
	if target_position.y + tooltip_size.y > viewport_size.y - TOOLTIP_VIEWPORT_MARGIN:
		target_position.y = mouse_position.y - TOOLTIP_CURSOR_OFFSET.y - tooltip_size.y

	target_position.x = clampf(
		target_position.x,
		TOOLTIP_VIEWPORT_MARGIN,
		maxf(TOOLTIP_VIEWPORT_MARGIN, viewport_size.x - tooltip_size.x - TOOLTIP_VIEWPORT_MARGIN)
	)
	target_position.y = clampf(
		target_position.y,
		TOOLTIP_VIEWPORT_MARGIN,
		maxf(TOOLTIP_VIEWPORT_MARGIN, viewport_size.y - tooltip_size.y - TOOLTIP_VIEWPORT_MARGIN)
	)
	position = target_position

func _resolve_required_nodes() -> void:
	if _plain_label == null:
		_plain_label = get_node_or_null(plain_label_path) as Label
	if _processing_container == null:
		_processing_container = get_node_or_null(processing_container_path) as VBoxContainer
	if _processing_title_label == null:
		_processing_title_label = get_node_or_null(processing_title_label_path) as Label
	if _processing_duration_row == null:
		_processing_duration_row = get_node_or_null(processing_duration_row_path) as HBoxContainer
	if _processing_duration_label == null:
		_processing_duration_label = get_node_or_null(processing_duration_label_path) as Label
	if _processing_duration_value_label == null:
		_processing_duration_value_label = get_node_or_null(processing_duration_value_label_path) as Label

	if _plain_label == null:
		push_error("CardTooltipView needs a Label at '%s'." % plain_label_path)
	if _processing_container == null:
		push_error("CardTooltipView needs a VBoxContainer at '%s'." % processing_container_path)
	if _processing_title_label == null:
		push_error("CardTooltipView needs a title Label at '%s'." % processing_title_label_path)
	if _processing_duration_row == null:
		push_error("CardTooltipView needs a duration HBoxContainer at '%s'." % processing_duration_row_path)
	if _processing_duration_label == null:
		push_error("CardTooltipView needs a duration Label at '%s'." % processing_duration_label_path)
	if _processing_duration_value_label == null:
		push_error("CardTooltipView needs a duration value Label at '%s'." % processing_duration_value_label_path)

func _apply_style() -> void:
	var style_box: StyleBoxFlat = StyleBoxFlat.new()
	style_box.bg_color = _get_tooltip_background_color()
	var shadow_color: Color = _get_card_shadow_color()
	shadow_color.a *= TOOLTIP_SHADOW_OPACITY
	style_box.shadow_color = shadow_color
	style_box.shadow_offset = TOOLTIP_SHADOW_OFFSET
	style_box.shadow_size = 0
	style_box.content_margin_bottom = TOOLTIP_CONTENT_MARGIN
	style_box.content_margin_left = TOOLTIP_CONTENT_MARGIN
	style_box.content_margin_right = TOOLTIP_CONTENT_MARGIN
	style_box.content_margin_top = TOOLTIP_CONTENT_MARGIN
	add_theme_stylebox_override("panel", style_box)

	if _card_font == null:
		_card_font = ResourceLoader.load(CARD_FONT_PATH) as FontFile
	for node: Variant in [_plain_label, _processing_title_label, _processing_duration_label, _processing_duration_value_label]:
		var label: Label = node as Label
		if label == null:
			continue
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.add_theme_color_override("font_color", _get_tooltip_text_color())
		if _card_font != null:
			label.add_theme_font_override("font", _card_font)
		var font_size: int = TOOLTIP_TIME_FONT_SIZE
		if label == _plain_label or label == _processing_title_label:
			font_size = TOOLTIP_FONT_SIZE
		label.add_theme_font_size_override("font_size", font_size)

func _get_processing_title_text(action_title: String) -> String:
	var clean_title: String = action_title.strip_edges()
	if clean_title.ends_with("..."):
		return clean_title
	return "%s..." % clean_title

func _get_processing_tooltip_width(title_text: String, remaining_text: String) -> float:
	var title_width: float = TOOLTIP_MIN_WIDTH - float(TOOLTIP_CONTENT_MARGIN * 2)
	var title_font: Font = _processing_title_label.get_theme_font("font") if _processing_title_label != null else null
	if title_font != null:
		title_width = title_font.get_string_size(title_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, TOOLTIP_FONT_SIZE).x

	var duration_width: float = TOOLTIP_MIN_WIDTH - float(TOOLTIP_CONTENT_MARGIN * 2)
	var time_font: Font = _processing_duration_label.get_theme_font("font") if _processing_duration_label != null else null
	if time_font != null:
		duration_width = time_font.get_string_size("Restdauer:", HORIZONTAL_ALIGNMENT_LEFT, -1.0, TOOLTIP_TIME_FONT_SIZE).x
		duration_width += 32.0
		duration_width += time_font.get_string_size(remaining_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, TOOLTIP_TIME_FONT_SIZE).x

	return clampf(
		maxf(title_width, duration_width),
		TOOLTIP_MIN_WIDTH - float(TOOLTIP_CONTENT_MARGIN * 2),
		TOOLTIP_MAX_WIDTH - float(TOOLTIP_CONTENT_MARGIN * 2)
	)

func _get_tooltip_text_width(text: String, font: Font) -> float:
	if font == null:
		return TOOLTIP_MAX_WIDTH - float(TOOLTIP_CONTENT_MARGIN * 2)
	var widest_line: float = 0.0
	for line: String in text.split("\n"):
		widest_line = maxf(widest_line, font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1.0, TOOLTIP_FONT_SIZE).x)
	return clampf(
		widest_line,
		TOOLTIP_MIN_WIDTH - float(TOOLTIP_CONTENT_MARGIN * 2),
		TOOLTIP_MAX_WIDTH - float(TOOLTIP_CONTENT_MARGIN * 2)
	)

func _get_tooltip_background_color() -> Color:
	return _get_theme_color("tooltip_background_color", TOOLTIP_BACKGROUND_COLOR)

func _get_tooltip_text_color() -> Color:
	return _get_theme_color("tooltip_text_color", TOOLTIP_TEXT_COLOR)

func _get_card_shadow_color() -> Color:
	return _get_theme_color("card_shadow_color", Color(0.18, 0.15, 0.11, 1.0))

func _get_theme_color(property_name: String, fallback: Color) -> Color:
	if visual_theme == null:
		return fallback
	var value: Variant = visual_theme.get(property_name)
	if value is Color:
		return value as Color
	return fallback

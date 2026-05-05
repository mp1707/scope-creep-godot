class_name CardView
extends Control

const DEFAULT_CARD_SIZE: Vector2 = Vector2(144.0, 196.0)
const CARD_CORNER_RADIUS: int = 8
const CARD_BORDER_WIDTH: int = 5
const HEADER_HEIGHT: float = 34.0
const CARD_BORDER_COLOR: Color = Color(0.055, 0.052, 0.047, 1.0)
const DRAG_SHADOW_COLOR: Color = Color(0.18, 0.17, 0.15, 1.0)
const CARD_FONT_PATH: String = "res://assets/fonts/PatrickHand-Regular.ttf"
const DEFAULT_ICON_CENTER: Vector2 = Vector2(72.0, 108.0)
const ICON_MASK_SHADER_CODE: String = "shader_type canvas_item;\nuniform vec4 icon_color : source_color = vec4(0.06, 0.055, 0.05, 1.0);\nvoid fragment() {\n\tvec4 texture_color = texture(TEXTURE, UV);\n\tCOLOR = vec4(icon_color.rgb, texture_color.a * icon_color.a);\n}\n"

@export var background_path: NodePath
@export var title_label_path: NodePath
@export var icon_texture_rect_path: NodePath
@export var short_text_label_path: NodePath
@export var marker_label_path: NodePath
@export var progress_bar_path: NodePath
@export var action_label_path: NodePath

var card_id: String = ""
var stack_id: String = ""

var _shadow: Control = null
var _background: Control = null
var _header_band: Control = null
var _title_label: Label = null
var _icon_texture_rect: TextureRect = null
var _short_text_label: Label = null
var _marker_label: Label = null
var _progress_bar: ProgressBar = null
var _action_label: Label = null
var _default_marker_text: String = ""
var _card_font: FontFile = null
var _icon_mask_material: ShaderMaterial = null
var _layout_initialized: bool = false

func _ready() -> void:
	_set_top_left_layout(self)
	custom_minimum_size = DEFAULT_CARD_SIZE
	size = DEFAULT_CARD_SIZE
	mouse_filter = Control.MOUSE_FILTER_PASS
	_resolve_or_create_nodes()

func setup(card: CardInstance, definition: CardDefinition, stack: StackState) -> void:
	card_id = card.instance_id
	stack_id = card.stack_id
	_resolve_or_create_nodes()
	_apply_definition(definition)
	update_runtime(card, stack)

func update_runtime(card: CardInstance, stack: StackState) -> void:
	card_id = card.instance_id
	stack_id = card.stack_id
	_update_progress(stack)
	_update_runtime_marker(card)
	_update_runtime_tint(card)

func set_drag_preview_position(board_position: Vector2) -> void:
	position = board_position

func clear_drag_preview() -> void:
	set_elevated(false)

func set_elevated(elevated: bool) -> void:
	_resolve_or_create_nodes()
	_shadow.visible = elevated

func play_spawn_pop() -> void:
	pivot_offset = DEFAULT_CARD_SIZE * 0.5
	scale = Vector2(0.84, 0.84)
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.06, 1.06), 0.08)
	tween.tween_property(self, "scale", Vector2.ONE, 0.07)

func _resolve_or_create_nodes() -> void:
	if _background == null:
		_background = get_node_or_null(background_path) as Control
	if _header_band == null:
		_header_band = get_node_or_null("HeaderBand") as Control
	if _title_label == null:
		_title_label = get_node_or_null(title_label_path) as Label
	if _icon_texture_rect == null:
		_icon_texture_rect = get_node_or_null(icon_texture_rect_path) as TextureRect
	if _icon_texture_rect == null:
		_icon_texture_rect = get_node_or_null("IconTextureRect") as TextureRect
	if _short_text_label == null:
		_short_text_label = get_node_or_null(short_text_label_path) as Label
	if _marker_label == null:
		_marker_label = get_node_or_null(marker_label_path) as Label
	if _progress_bar == null:
		_progress_bar = get_node_or_null(progress_bar_path) as ProgressBar
	if _action_label == null:
		_action_label = get_node_or_null(action_label_path) as Label

	if _shadow == null:
		_shadow = get_node_or_null("DragShadow") as Control
	if _shadow == null:
		_shadow = Panel.new()
		_shadow.name = "DragShadow"
		_shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_shadow.visible = false
		add_child(_shadow)
		move_child(_shadow, 0)

	if _background == null:
		_background = Panel.new()
		_background.name = "Background"
		_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_background)
		move_child(_background, 0)

	if _header_band == null:
		_header_band = Panel.new()
		_header_band.name = "HeaderBand"
		_header_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_header_band)

	if _card_font == null:
		_card_font = ResourceLoader.load(CARD_FONT_PATH) as FontFile
	if _title_label == null:
		_title_label = _create_label("TitleLabel", Vector2(9.0, 3.0), Vector2(126.0, 25.0), HORIZONTAL_ALIGNMENT_CENTER)
	if _marker_label == null:
		_marker_label = _create_label("MarkerLabel", Vector2(98.0, 42.0), Vector2(34.0, 24.0), HORIZONTAL_ALIGNMENT_CENTER)
	if _icon_texture_rect == null:
		_icon_texture_rect = TextureRect.new()
		_icon_texture_rect.name = "IconTextureRect"
		_icon_texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_icon_texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_icon_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_icon_texture_rect.clip_contents = true
		add_child(_icon_texture_rect)
	if _short_text_label == null:
		_short_text_label = _create_label("ShortTextLabel", Vector2(12.0, 74.0), Vector2(120.0, 62.0), HORIZONTAL_ALIGNMENT_LEFT)
		_short_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if _progress_bar == null:
		_progress_bar = ProgressBar.new()
		_progress_bar.name = "ProgressBar"
		_progress_bar.position = Vector2(12.0, 148.0)
		_progress_bar.size = Vector2(120.0, 12.0)
		_progress_bar.show_percentage = false
		_progress_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_progress_bar)
	if _action_label == null:
		_action_label = _create_label("ActionLabel", Vector2(12.0, 164.0), Vector2(120.0, 20.0), HORIZONTAL_ALIGNMENT_CENTER)
	move_child(_shadow, 0)
	move_child(_background, 1)
	move_child(_header_band, 2)
	move_child(_icon_texture_rect, 3)
	move_child(_title_label, 4)
	move_child(_marker_label, 5)
	move_child(_short_text_label, 6)
	move_child(_progress_bar, 7)
	move_child(_action_label, 8)
	if not _layout_initialized:
		_apply_default_layout()
		_layout_initialized = true

func _create_label(node_name: String, label_position: Vector2, label_size: Vector2, alignment: HorizontalAlignment) -> Label:
	var label: Label = Label.new()
	label.name = node_name
	label.position = label_position
	label.size = label_size
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.clip_text = true
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label

func _apply_default_layout() -> void:
	_set_top_left_layout(self)
	mouse_filter = Control.MOUSE_FILTER_PASS
	custom_minimum_size = DEFAULT_CARD_SIZE
	size = DEFAULT_CARD_SIZE
	_set_top_left_layout(_shadow)
	_shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shadow.position = Vector2(8.0, 10.0)
	_shadow.size = DEFAULT_CARD_SIZE
	_apply_shadow_style()
	_set_top_left_layout(_background)
	_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_background.position = Vector2.ZERO
	_background.size = DEFAULT_CARD_SIZE
	_set_top_left_layout(_header_band)
	_header_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_header_band.position = Vector2(CARD_BORDER_WIDTH, CARD_BORDER_WIDTH)
	_header_band.size = Vector2(DEFAULT_CARD_SIZE.x - float(CARD_BORDER_WIDTH * 2), HEADER_HEIGHT)
	_set_top_left_layout(_title_label)
	_title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title_label.position = Vector2(9.0, 3.0)
	_title_label.size = Vector2(126.0, 25.0)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_title_label.clip_text = true
	if _card_font != null:
		_title_label.add_theme_font_override("font", _card_font)
	_title_label.add_theme_font_size_override("font_size", 22)
	_set_top_left_layout(_icon_texture_rect)
	_icon_texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_icon_texture_rect.custom_minimum_size = Vector2.ZERO
	_icon_texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon_texture_rect.position = DEFAULT_ICON_CENTER - Vector2(39.0, 39.0)
	_icon_texture_rect.size = Vector2(78.0, 78.0)
	_icon_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon_texture_rect.clip_contents = true
	_set_top_left_layout(_marker_label)
	_marker_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_marker_label.position = Vector2(98.0, 42.0)
	_marker_label.size = Vector2(34.0, 24.0)
	_marker_label.visible = false
	_set_top_left_layout(_short_text_label)
	_short_text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_short_text_label.position = Vector2(12.0, 74.0)
	_short_text_label.size = Vector2(120.0, 62.0)
	_short_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_short_text_label.visible = false
	_set_top_left_layout(_progress_bar)
	_progress_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_progress_bar.position = Vector2(12.0, 148.0)
	_progress_bar.size = Vector2(120.0, 12.0)
	_set_top_left_layout(_action_label)
	_action_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_action_label.position = Vector2(12.0, 164.0)
	_action_label.size = Vector2(120.0, 20.0)

func _set_top_left_layout(control: Control) -> void:
	control.anchor_left = 0.0
	control.anchor_top = 0.0
	control.anchor_right = 0.0
	control.anchor_bottom = 0.0

func _apply_definition(definition: CardDefinition) -> void:
	_title_label.text = definition.display_name
	_short_text_label.text = ""
	tooltip_text = definition.tooltip_text if not definition.tooltip_text.is_empty() else definition.short_text

	var visual: CardVisualDefinition = definition.visual
	if visual == null:
		visual = CardVisualDefinition.new()

	_marker_label.text = visual.marker_text
	_default_marker_text = visual.marker_text
	_apply_icon_style(visual)
	for label: Label in [_title_label, _short_text_label, _marker_label, _action_label]:
		label.add_theme_color_override("font_color", visual.text_color)

	if _background is ColorRect:
		(_background as ColorRect).color = visual.background_color
	else:
		var style_box: StyleBoxFlat = StyleBoxFlat.new()
		style_box.bg_color = visual.background_color
		style_box.border_color = CARD_BORDER_COLOR
		style_box.border_width_bottom = CARD_BORDER_WIDTH
		style_box.border_width_left = CARD_BORDER_WIDTH
		style_box.border_width_right = CARD_BORDER_WIDTH
		style_box.border_width_top = CARD_BORDER_WIDTH
		style_box.corner_radius_bottom_left = CARD_CORNER_RADIUS
		style_box.corner_radius_bottom_right = CARD_CORNER_RADIUS
		style_box.corner_radius_top_left = CARD_CORNER_RADIUS
		style_box.corner_radius_top_right = CARD_CORNER_RADIUS
		_background.add_theme_stylebox_override("panel", style_box)
	_apply_header_style(visual)

func _apply_icon_style(visual: CardVisualDefinition) -> void:
	_icon_texture_rect.texture = visual.icon_texture
	_icon_texture_rect.visible = visual.icon_texture != null
	_icon_texture_rect.custom_minimum_size = Vector2.ZERO
	_icon_texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon_texture_rect.size = visual.icon_size
	_icon_texture_rect.position = DEFAULT_ICON_CENTER - (visual.icon_size * 0.5) + visual.icon_offset
	_icon_texture_rect.self_modulate = Color.WHITE
	if visual.icon_texture == null:
		_icon_texture_rect.material = null
		return
	if visual.icon_recolor_alpha_mask:
		_icon_texture_rect.material = _get_icon_mask_material()
		_icon_mask_material.set_shader_parameter("icon_color", visual.icon_color)
	else:
		_icon_texture_rect.material = null
		_icon_texture_rect.self_modulate = visual.icon_color

func _get_icon_mask_material() -> ShaderMaterial:
	if _icon_mask_material != null:
		return _icon_mask_material
	var shader: Shader = Shader.new()
	shader.code = ICON_MASK_SHADER_CODE
	_icon_mask_material = ShaderMaterial.new()
	_icon_mask_material.shader = shader
	return _icon_mask_material

func _apply_header_style(visual: CardVisualDefinition) -> void:
	if _header_band == null:
		return
	if _header_band is ColorRect:
		(_header_band as ColorRect).color = visual.accent_color.lightened(0.35)
		return
	var header_style: StyleBoxFlat = StyleBoxFlat.new()
	header_style.bg_color = visual.accent_color.lightened(0.35)
	header_style.border_color = CARD_BORDER_COLOR
	header_style.border_width_bottom = CARD_BORDER_WIDTH
	header_style.corner_radius_top_left = maxi(CARD_CORNER_RADIUS - 3, 0)
	header_style.corner_radius_top_right = maxi(CARD_CORNER_RADIUS - 3, 0)
	_header_band.add_theme_stylebox_override("panel", header_style)

func _apply_shadow_style() -> void:
	if _shadow == null:
		return
	if _shadow is ColorRect:
		(_shadow as ColorRect).color = DRAG_SHADOW_COLOR
		return
	var shadow_style: StyleBoxFlat = StyleBoxFlat.new()
	shadow_style.bg_color = DRAG_SHADOW_COLOR
	shadow_style.corner_radius_bottom_left = CARD_CORNER_RADIUS
	shadow_style.corner_radius_bottom_right = CARD_CORNER_RADIUS
	shadow_style.corner_radius_top_left = CARD_CORNER_RADIUS
	shadow_style.corner_radius_top_right = CARD_CORNER_RADIUS
	_shadow.add_theme_stylebox_override("panel", shadow_style)

func _update_progress(_stack: StackState) -> void:
	_progress_bar.visible = false
	_progress_bar.value = 0.0
	_action_label.visible = false
	_action_label.text = ""

func _update_runtime_marker(card: CardInstance) -> void:
	if card.state == null:
		return
	if card.state.is_paid:
		_marker_label.text = "OK"
		return
	if card.state.is_payment_target:
		_marker_label.text = "$"
		return
	if card.state.markers.is_empty():
		_marker_label.text = _default_marker_text
		return
	_marker_label.text = card.state.markers[0]

func _update_runtime_tint(card: CardInstance) -> void:
	if card.state == null:
		modulate = Color.WHITE
		return
	if card.state.is_locked:
		modulate = Color(0.55, 0.55, 0.55, 0.72)
	elif card.state.is_paid:
		modulate = Color(0.68, 0.86, 0.68, 0.88)
	elif card.state.is_payment_target:
		modulate = Color(1.0, 0.96, 0.72, 1.0)
	else:
		modulate = Color.WHITE

class_name CardView
extends Control

const DEFAULT_CARD_SIZE: Vector2 = Vector2(144.0, 196.0)
const CARD_EDGE_INSET: float = 0.0
const CARD_HAIRLINE_WIDTH: int = 1
const CARD_HAIRLINE_COLOR: Color = Color(0.055, 0.052, 0.047, 0.22)
const HEADER_HEIGHT: float = 24.0
const CARD_TEXT_COLOR: Color = Color(0.075, 0.095, 0.12, 1.0)
const TOOLTIP_SHOW_DELAY_SECONDS: float = 0.35
const TOOLTIP_LAYER: int = 1200
const CARD_HOVER_Z_INDEX: int = 1000
const CARD_DRAG_Z_INDEX: int = 2000
const SHADOW_COLOR: Color = Color(0.18, 0.15, 0.11, 1.0)
const DROP_TARGET_FILL_COLOR: Color = Color(0.055, 0.052, 0.047, 0.08)
const STATUS_BADGE_TEXT_COLOR: Color = Color(0.055, 0.052, 0.047, 1.0)
const STATUS_BADGE_COLOR: Color = Color(0.98, 0.91, 0.65, 0.96)
const STATUS_BADGE_ALERT_COLOR: Color = Color(0.98, 0.64, 0.58, 0.96)
const STATUS_BADGE_PAID_COLOR: Color = Color(0.64, 0.86, 0.64, 0.96)
const CARD_FONT_PATH: String = "res://assets/fonts/PatrickHand-Regular.ttf"
const CARD_PAPER_TEXTURE_PATH: String = "res://assets/card/paperTexture.png"
const ICON_SCRIBBLE_TEXTURE_PATH: String = "res://assets/icons/handdrawn/ui/scribbleCricle.png"
const TITLE_MAX_FONT_SIZE: int = 18
const TITLE_MIN_FONT_SIZE: int = 8
const DEFAULT_ICON_CENTER: Vector2 = Vector2(72.0, 108.0)
const DEFAULT_ICON_SCRIBBLE_PADDING: float = 24.0
const ICON_MASK_SHADER_CODE: String = "shader_type canvas_item;\nuniform vec4 icon_color : source_color = vec4(0.06, 0.055, 0.05, 1.0);\nvoid fragment() {\n\tvec4 texture_color = texture(TEXTURE, UV);\n\tCOLOR = vec4(icon_color.rgb, texture_color.a * icon_color.a);\n}\n"
const ProductLifecycleServiceScript: Script = preload("res://scripts/simulation/product_lifecycle_service.gd")
const CardJuiceControllerScript: Script = preload("res://scripts/presentation/card_juice_controller.gd")
const CARD_TOOLTIP_VIEW_SCENE: PackedScene = preload("res://scenes/presentation/CardTooltipView.tscn")

static var _active_tooltip_owner: Control = null
static var _shared_tooltip_layer: CanvasLayer = null
static var _shared_tooltip_view: Control = null
static var _shared_paper_texture: Texture2D = null
static var _paper_texture_load_attempted: bool = false
static var _shared_icon_scribble_texture: Texture2D = null
static var _icon_scribble_texture_load_attempted: bool = false

@export var visual_root_path: NodePath = NodePath("VisualRoot")
@export var shadow_path: NodePath = NodePath("VisualRoot/CardShadow")
@export var background_path: NodePath
@export var header_band_path: NodePath = NodePath("VisualRoot/HeaderBand")
@export var header_hairline_path: NodePath = NodePath("VisualRoot/HeaderHairline")
@export var title_label_path: NodePath
@export var icon_scribble_texture_rect_path: NodePath = NodePath("VisualRoot/IconScribbleTextureRect")
@export var icon_texture_rect_path: NodePath
@export var short_text_label_path: NodePath
@export var marker_label_path: NodePath
@export var drop_target_feedback_path: NodePath = NodePath("VisualRoot/DropTargetFeedback")
@export var juice_controller_path: NodePath = NodePath("CardJuiceController")

var card_id: String = ""
var stack_id: String = ""
var visual_theme: Resource = null

var _visual_root: Control = null
var _shadow: Control = null
var _background: Control = null
var _header_band: Control = null
var _header_hairline: Control = null
var _title_label: Label = null
var _icon_scribble_texture_rect: TextureRect = null
var _icon_texture_rect: TextureRect = null
var _short_text_label: Label = null
var _marker_label: Label = null
var _drop_target_feedback: Panel = null
var _juice = null
var _default_marker_text: String = ""
var _card_font: FontFile = null
var _scribble_mask_material: ShaderMaterial = null
var _icon_mask_material: ShaderMaterial = null
var _product_lifecycle: RefCounted = ProductLifecycleServiceScript.new()
var _custom_tooltip_text: String = ""
var _processing_tooltip_title: String = ""
var _processing_tooltip_remaining_seconds: float = 0.0
var _uses_processing_tooltip: bool = false
var _hover_seconds: float = 0.0
var _is_hovering: bool = false
var _is_tooltip_shown: bool = false
var _pointer_hover_enabled: bool = true
var _visual_hover_active: bool = false
var _z_index_before_hover: int = 0

func _ready() -> void:
	_set_top_left_layout(self)
	custom_minimum_size = DEFAULT_CARD_SIZE
	size = DEFAULT_CARD_SIZE
	mouse_filter = Control.MOUSE_FILTER_PASS
	_resolve_or_create_nodes()
	if not mouse_entered.is_connected(_on_card_mouse_entered):
		mouse_entered.connect(_on_card_mouse_entered)
	if not mouse_exited.is_connected(_on_card_mouse_exited):
		mouse_exited.connect(_on_card_mouse_exited)
	set_process(false)

func _process(delta: float) -> void:
	if not _has_custom_tooltip():
		_stop_tooltip_hover()
		return
	if not _is_hovering:
		if not _is_tooltip_shown:
			set_process(false)
		return
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_hover_seconds = 0.0
		_hide_custom_tooltip()
		return

	_hover_seconds += delta
	if not _is_tooltip_shown and _hover_seconds >= TOOLTIP_SHOW_DELAY_SECONDS:
		_show_custom_tooltip()
	if _is_tooltip_shown:
		_position_shared_tooltip()

func _exit_tree() -> void:
	_stop_tooltip_hover()

func _get_tooltip(_at_position: Vector2) -> String:
	return ""

func set_visual_theme(theme: Resource) -> void:
	visual_theme = theme
	if _shadow != null:
		_apply_shadow_style()
	if _header_hairline != null:
		_apply_header_hairline_style()
	if _drop_target_feedback != null:
		_apply_drop_target_feedback_style()
	if _active_tooltip_owner == self and _shared_tooltip_view != null and is_instance_valid(_shared_tooltip_view):
		_shared_tooltip_view.set_visual_theme(visual_theme)

func set_processing_tooltip(action_title: String, remaining_seconds: float) -> void:
	_processing_tooltip_title = action_title.strip_edges()
	_processing_tooltip_remaining_seconds = maxf(remaining_seconds, 0.0)
	_uses_processing_tooltip = not _processing_tooltip_title.is_empty()
	if _active_tooltip_owner == self and _is_tooltip_shown:
		_show_custom_tooltip()

func clear_processing_tooltip() -> void:
	if not _uses_processing_tooltip:
		return
	_uses_processing_tooltip = false
	_processing_tooltip_title = ""
	_processing_tooltip_remaining_seconds = 0.0
	if _active_tooltip_owner == self and _is_tooltip_shown:
		if _custom_tooltip_text.is_empty():
			_stop_tooltip_hover()
		else:
			_show_custom_tooltip()

func setup(card: CardInstance, definition: CardDefinition, stack: StackState) -> void:
	card_id = card.instance_id
	stack_id = card.stack_id
	_resolve_or_create_nodes()
	_juice.set_idle_rotation(_get_idle_rotation_for_card_id(card_id))
	_apply_definition(definition)
	update_runtime(card, stack, definition)

func update_runtime(card: CardInstance, _stack: StackState, definition: CardDefinition = null) -> void:
	card_id = card.instance_id
	stack_id = card.stack_id
	_update_runtime_marker(card, definition)
	_update_runtime_short_text(card, definition)
	_update_runtime_tint(card)
	if definition != null:
		_update_tooltip(card, definition)

func set_drag_preview_position(board_position: Vector2) -> void:
	_resolve_or_create_nodes()
	_juice.set_drag_target_position(board_position)

func get_drag_lift_offset() -> Vector2:
	return Vector2.ZERO

func get_drag_lift_offset_for_canvas_scale(canvas_scale: Vector2) -> Vector2:
	_juice.set_shadow_canvas_scale(canvas_scale)
	return Vector2.ZERO

func begin_drag_preview(target_position: Vector2, canvas_scale: Vector2) -> void:
	_resolve_or_create_nodes()
	set_visual_hovered(false)
	_stop_tooltip_hover()
	_z_index_before_hover = z_index
	z_index = CARD_DRAG_Z_INDEX
	_juice.set_shadow_canvas_scale(canvas_scale)
	_juice.play_drag_start(target_position)

func set_drag_elevation_canvas_scale(canvas_scale: Vector2) -> void:
	_resolve_or_create_nodes()
	_juice.set_shadow_canvas_scale(canvas_scale)

func clear_drag_preview() -> void:
	_resolve_or_create_nodes()
	_visual_hover_active = false
	z_index = _z_index_before_hover
	_juice.set_shadow_canvas_scale(Vector2.ONE)
	_juice.play_idle()

func set_elevated(elevated: bool) -> void:
	_resolve_or_create_nodes()
	if elevated:
		_shadow.visible = true

func play_snap_to(target_position: Vector2) -> void:
	_resolve_or_create_nodes()
	_visual_hover_active = false
	z_index = _z_index_before_hover
	_juice.set_shadow_canvas_scale(Vector2.ONE)
	_juice.play_snap(target_position, _get_idle_rotation_for_card_id(card_id))

func play_spawn_pop() -> void:
	_resolve_or_create_nodes()
	_juice.play_spawn_pop()

func set_drop_target_feedback(active: bool) -> void:
	_resolve_or_create_nodes()
	_juice.set_drop_target_feedback(active)

func play_drop_target_pulse() -> void:
	_resolve_or_create_nodes()
	_juice.play_drop_target_pulse()

func set_pointer_hover_enabled(enabled: bool) -> void:
	if _pointer_hover_enabled == enabled:
		return
	_pointer_hover_enabled = enabled
	if not _pointer_hover_enabled:
		set_visual_hovered(false)
	mouse_filter = Control.MOUSE_FILTER_PASS if _pointer_hover_enabled else Control.MOUSE_FILTER_IGNORE

func set_visual_hovered(hovered: bool, hover_z_index: int = CARD_HOVER_Z_INDEX, tooltip_active: bool = false) -> void:
	_resolve_or_create_nodes()
	if hovered:
		if not _visual_hover_active:
			_z_index_before_hover = z_index
			_visual_hover_active = true
		z_index = hover_z_index
		_juice.play_hover()
		if tooltip_active and _has_custom_tooltip():
			_is_hovering = true
			_hover_seconds = 0.0
			set_process(true)
		else:
			_stop_tooltip_hover()
		return

	if _visual_hover_active:
		z_index = _z_index_before_hover
		_visual_hover_active = false
	if bool(_juice.call("is_hovered")):
		_juice.play_idle()
	_stop_tooltip_hover()

func _resolve_or_create_nodes() -> void:
	if _visual_root == null:
		_visual_root = _resolve_control(visual_root_path, "VisualRoot")
	if _shadow == null:
		_shadow = _resolve_control(shadow_path, "CardShadow")
	if _background == null:
		_background = _resolve_control(background_path, "Background")
	if _header_band == null:
		_header_band = _resolve_control(header_band_path, "HeaderBand")
	if _header_hairline == null:
		_header_hairline = _resolve_control(header_hairline_path, "HeaderHairline")
	if _title_label == null:
		_title_label = _resolve_control(title_label_path, "TitleLabel") as Label
	if _icon_scribble_texture_rect == null:
		_icon_scribble_texture_rect = _resolve_control(icon_scribble_texture_rect_path, "IconScribbleTextureRect") as TextureRect
	if _icon_texture_rect == null:
		_icon_texture_rect = _resolve_control(icon_texture_rect_path, "IconTextureRect") as TextureRect
	if _short_text_label == null:
		_short_text_label = _resolve_control(short_text_label_path, "ShortTextLabel") as Label
	if _marker_label == null:
		_marker_label = _resolve_control(marker_label_path, "MarkerLabel") as Label
	if _drop_target_feedback == null:
		_drop_target_feedback = _resolve_control(drop_target_feedback_path, "DropTargetFeedback") as Panel
	_report_missing_required_nodes()
	if _card_font == null:
		_card_font = ResourceLoader.load(CARD_FONT_PATH) as FontFile
	_apply_scene_node_defaults()
	_ensure_juice_controller()

func _resolve_control(path: NodePath, fallback_name: String) -> Control:
	var path_text: String = String(path)
	if not path_text.is_empty():
		var node: Control = get_node_or_null(path) as Control
		if node != null:
			return node
		if _visual_root != null:
			node = _visual_root.get_node_or_null(path) as Control
			if node != null:
				return node
	var direct: Control = get_node_or_null(fallback_name) as Control
	if direct != null:
		return direct
	if _visual_root != null:
		return _visual_root.get_node_or_null(fallback_name) as Control
	return null

func _report_missing_required_nodes() -> void:
	var required_nodes: Dictionary = {
		"VisualRoot": _visual_root,
		"CardShadow": _shadow,
		"Background": _background,
		"HeaderBand": _header_band,
		"HeaderHairline": _header_hairline,
		"TitleLabel": _title_label,
		"IconScribbleTextureRect": _icon_scribble_texture_rect,
		"IconTextureRect": _icon_texture_rect,
		"ShortTextLabel": _short_text_label,
		"MarkerLabel": _marker_label,
		"DropTargetFeedback": _drop_target_feedback,
	}
	for node_name: String in required_nodes.keys():
		if required_nodes[node_name] == null:
			push_error("CardView scene is missing required node '%s'." % node_name)

func _apply_scene_node_defaults() -> void:
	_set_top_left_layout(self)
	custom_minimum_size = DEFAULT_CARD_SIZE
	size = DEFAULT_CARD_SIZE
	mouse_filter = Control.MOUSE_FILTER_PASS
	if _visual_root != null:
		_visual_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_visual_root.pivot_offset = DEFAULT_CARD_SIZE * 0.5
	if _shadow != null:
		_shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_apply_shadow_style()
	if _background != null:
		_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _header_band != null:
		_header_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _header_hairline != null:
		_header_hairline.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_apply_header_hairline_style()
	if _icon_scribble_texture_rect != null:
		_icon_scribble_texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _icon_texture_rect != null:
		_icon_texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _title_label != null:
		_title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if _card_font != null:
			_title_label.add_theme_font_override("font", _card_font)
		_title_label.add_theme_font_size_override("font_size", TITLE_MAX_FONT_SIZE)
	if _marker_label != null:
		_marker_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_marker_label.add_theme_font_size_override("font_size", 18)
		_marker_label.add_theme_color_override("font_color", _get_status_badge_text_color())
	if _short_text_label != null:
		_short_text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if _card_font != null:
			_short_text_label.add_theme_font_override("font", _card_font)
		_short_text_label.add_theme_font_size_override("font_size", 18)
	if _drop_target_feedback != null:
		_drop_target_feedback.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_apply_drop_target_feedback_style()

func _ensure_juice_controller() -> void:
	if _juice == null:
		_juice = get_node_or_null(juice_controller_path)
	if _juice == null:
		_juice = CardJuiceControllerScript.new() as Node
		_juice.name = "CardJuiceController"
		add_child(_juice)
	if _visual_root == null or _shadow == null or _drop_target_feedback == null:
		return
	_juice.setup(self, _visual_root, _shadow, _drop_target_feedback)
	_juice.set_idle_rotation(_get_idle_rotation_for_card_id(card_id))

func _set_top_left_layout(control: Control) -> void:
	control.anchor_left = 0.0
	control.anchor_top = 0.0
	control.anchor_right = 0.0
	control.anchor_bottom = 0.0

func _apply_definition(definition: CardDefinition) -> void:
	_title_label.text = definition.display_name
	_fit_title_to_single_line()
	_short_text_label.text = ""
	_set_card_tooltip_text(definition.tooltip_text if not definition.tooltip_text.is_empty() else definition.short_text)

	var visual: CardVisualDefinition = definition.visual
	if visual == null:
		visual = CardVisualDefinition.new()

	_marker_label.text = visual.marker_text
	_default_marker_text = visual.marker_text
	_apply_icon_style(visual)
	_short_text_label.visible = false
	for label: Label in [_title_label, _short_text_label, _marker_label]:
		label.add_theme_color_override("font_color", _get_card_text_color(visual))
	_title_label.add_theme_color_override("font_color", _get_card_header_text_color())
	_marker_label.add_theme_color_override("font_color", _get_status_badge_text_color())

	_apply_card_surface_style(_background, _get_card_background_color(visual))
	_apply_header_style(visual)

func _fit_title_to_single_line() -> void:
	_title_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_title_label.clip_text = false
	var font: Font = _title_label.get_theme_font("font")
	if font == null:
		font = _card_font
	if font == null:
		_title_label.add_theme_font_size_override("font_size", TITLE_MAX_FONT_SIZE)
		return

	var available_width: float = maxf(1.0, _title_label.size.x - 2.0)
	var font_size: int = TITLE_MAX_FONT_SIZE
	while font_size > TITLE_MIN_FONT_SIZE:
		var text_size: Vector2 = font.get_string_size(_title_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size)
		if text_size.x <= available_width:
			break
		font_size -= 1
	_title_label.add_theme_font_size_override("font_size", font_size)

func _apply_icon_style(visual: CardVisualDefinition) -> void:
	_icon_texture_rect.texture = visual.icon_texture
	_icon_texture_rect.visible = visual.icon_texture != null
	_icon_texture_rect.custom_minimum_size = Vector2.ZERO
	_icon_texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon_texture_rect.size = visual.icon_size
	_icon_texture_rect.position = DEFAULT_ICON_CENTER - (visual.icon_size * 0.5) + visual.icon_offset
	_icon_texture_rect.self_modulate = Color.WHITE
	_apply_icon_scribble_style(visual)
	if visual.icon_texture == null:
		_icon_texture_rect.material = null
		return
	if visual.icon_recolor_alpha_mask:
		_icon_texture_rect.material = _get_icon_mask_material()
		_icon_mask_material.set_shader_parameter("icon_color", _get_card_icon_color(visual))
	else:
		_icon_texture_rect.material = null
		_icon_texture_rect.self_modulate = _get_card_icon_color(visual)

func _apply_icon_scribble_style(visual: CardVisualDefinition) -> void:
	if _icon_scribble_texture_rect == null:
		return
	var scribble_texture: Texture2D = _get_icon_scribble_texture()
	_icon_scribble_texture_rect.texture = scribble_texture
	_icon_scribble_texture_rect.visible = visual.icon_texture != null and scribble_texture != null
	if not _icon_scribble_texture_rect.visible:
		_icon_scribble_texture_rect.material = null
		return
	var scribble_size: float = clampf(
		maxf(visual.icon_size.x, visual.icon_size.y) + DEFAULT_ICON_SCRIBBLE_PADDING,
		92.0,
		128.0
	)
	_icon_scribble_texture_rect.size = Vector2(scribble_size, scribble_size)
	_icon_scribble_texture_rect.position = DEFAULT_ICON_CENTER - (_icon_scribble_texture_rect.size * 0.5) + visual.icon_offset
	_icon_scribble_texture_rect.self_modulate = Color.WHITE
	_icon_scribble_texture_rect.material = _get_scribble_mask_material()
	_scribble_mask_material.set_shader_parameter("icon_color", _get_card_scribble_color(visual))

func _get_icon_mask_material() -> ShaderMaterial:
	if _icon_mask_material == null:
		_icon_mask_material = _create_alpha_mask_material()
	return _icon_mask_material

func _get_scribble_mask_material() -> ShaderMaterial:
	if _scribble_mask_material == null:
		_scribble_mask_material = _create_alpha_mask_material()
	return _scribble_mask_material

func _create_alpha_mask_material() -> ShaderMaterial:
	var shader: Shader = Shader.new()
	shader.code = ICON_MASK_SHADER_CODE
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = shader
	return material

func _apply_header_style(visual: CardVisualDefinition) -> void:
	if _header_band == null:
		return
	_apply_card_surface_style(_header_band, _get_card_accent_color(visual).lightened(0.35))

func _apply_card_surface_style(control: Control, tint_color: Color) -> void:
	if control == null:
		return
	if control is ColorRect:
		(control as ColorRect).color = tint_color
		return
	var paper_texture: Texture2D = _get_paper_texture()
	if paper_texture == null:
		var flat_style: StyleBoxFlat = StyleBoxFlat.new()
		flat_style.bg_color = tint_color
		control.add_theme_stylebox_override("panel", flat_style)
		return
	var texture_style: StyleBoxTexture = StyleBoxTexture.new()
	texture_style.texture = paper_texture
	texture_style.modulate_color = tint_color
	texture_style.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	texture_style.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	control.add_theme_stylebox_override("panel", texture_style)

func _get_paper_texture() -> Texture2D:
	if visual_theme != null and visual_theme.get("card_paper_texture") != null:
		return visual_theme.get("card_paper_texture") as Texture2D
	if _shared_paper_texture != null:
		return _shared_paper_texture
	if _paper_texture_load_attempted:
		return null
	_paper_texture_load_attempted = true
	_shared_paper_texture = ResourceLoader.load(CARD_PAPER_TEXTURE_PATH) as Texture2D
	return _shared_paper_texture

func _get_icon_scribble_texture() -> Texture2D:
	if visual_theme != null and visual_theme.get("card_icon_scribble_texture") != null:
		return visual_theme.get("card_icon_scribble_texture") as Texture2D
	if _shared_icon_scribble_texture != null:
		return _shared_icon_scribble_texture
	if _icon_scribble_texture_load_attempted:
		return null
	_icon_scribble_texture_load_attempted = true
	_shared_icon_scribble_texture = ResourceLoader.load(ICON_SCRIBBLE_TEXTURE_PATH) as Texture2D
	return _shared_icon_scribble_texture

func _apply_header_hairline_style() -> void:
	if _header_hairline == null:
		return
	if _header_hairline is ColorRect:
		(_header_hairline as ColorRect).color = _get_card_hairline_color()
		return
	var hairline_style: StyleBoxFlat = StyleBoxFlat.new()
	hairline_style.bg_color = _get_card_hairline_color()
	_header_hairline.add_theme_stylebox_override("panel", hairline_style)

func _apply_shadow_style() -> void:
	if _shadow == null:
		return
	if _shadow is ColorRect:
		(_shadow as ColorRect).color = _get_card_shadow_color()
		return
	var shadow_style: StyleBoxFlat = StyleBoxFlat.new()
	shadow_style.bg_color = _get_card_shadow_color()
	_shadow.add_theme_stylebox_override("panel", shadow_style)

func _apply_drop_target_feedback_style() -> void:
	if _drop_target_feedback == null:
		return
	var style_box: StyleBoxFlat = StyleBoxFlat.new()
	style_box.bg_color = _get_card_drop_target_fill_color()
	_drop_target_feedback.add_theme_stylebox_override("panel", style_box)

func _get_idle_rotation_for_card_id(value: String) -> float:
	if value.is_empty():
		return 0.0
	var normalized: float = float(abs(value.hash()) % 1000) / 999.0
	return deg_to_rad(lerpf(-2.0, 2.0, normalized))

func _update_runtime_marker(card: CardInstance, definition: CardDefinition) -> void:
	if card.state == null:
		return
	var marker_text: String = _get_runtime_marker_text(card, definition)
	_marker_label.text = marker_text
	_marker_label.visible = false
	_apply_marker_style(card, marker_text)

func _update_runtime_short_text(card: CardInstance, definition: CardDefinition) -> void:
	_short_text_label.text = ""
	_short_text_label.visible = false
	if definition == null:
		return
	if definition.tags.has("business_goal"):
		_short_text_label.text = "Goal %d\n%d/%d Geld" % [
			maxi(1, int(card.values.get("goal_index", 1))),
			maxi(0, int(card.values.get("paid_money", 0))),
			maxi(1, int(card.values.get("required_money", 1))),
		]
		_short_text_label.visible = true
		_short_text_label.position = Vector2(12.0, DEFAULT_ICON_CENTER.y - 44.0)
		_short_text_label.size = Vector2(120.0, 88.0)
		_short_text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_short_text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_short_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_short_text_label.add_theme_font_size_override("font_size", 18)
		return
	if not definition.tags.has("software"):
		return
	var status_text: String = _product_lifecycle.get_status_text(card)
	if status_text.is_empty():
		return
	_set_runtime_short_text(status_text, 18)

func _set_runtime_short_text(text: String, font_size: int) -> void:
	_short_text_label.text = text
	_short_text_label.visible = true
	_short_text_label.position = Vector2(12.0, DEFAULT_ICON_CENTER.y - 44.0)
	_short_text_label.size = Vector2(120.0, 88.0)
	_short_text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_short_text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_short_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if _card_font != null:
		_short_text_label.add_theme_font_override("font", _card_font)
	_short_text_label.add_theme_font_size_override("font_size", font_size)

func _get_runtime_marker_text(card: CardInstance, definition: CardDefinition) -> String:
	if card.state.is_paid:
		return "OK"
	if card.state.is_payment_target:
		return "$"
	if not card.state.markers.is_empty():
		return card.state.markers[0]
	if definition != null and definition.tags.has("feature"):
		var value: int = int(card.values.get("feature_value", 1))
		if bool(card.values.get("is_checked", false)) or definition.tags.has("checked"):
			return "OK%d" % value
		return "W%d" % value
	if not card.parent_card_id.is_empty():
		return "AN"
	return _default_marker_text

func _apply_marker_style(card: CardInstance, marker_text: String) -> void:
	if marker_text.is_empty():
		return
	var style_box: StyleBoxFlat = StyleBoxFlat.new()
	if card.state != null and card.state.is_paid:
		style_box.bg_color = _get_status_badge_paid_color()
	elif marker_text == "BO" or marker_text == "!!!" or marker_text == "$":
		style_box.bg_color = _get_status_badge_alert_color()
	else:
		style_box.bg_color = _get_status_badge_color()
	_marker_label.add_theme_stylebox_override("normal", style_box)

func _update_tooltip(card: CardInstance, definition: CardDefinition) -> void:
	var details: PackedStringArray = PackedStringArray()
	var base_text: String = definition.tooltip_text if not definition.tooltip_text.is_empty() else definition.short_text
	if definition.tags.has("software"):
		var feature_count: int = _product_lifecycle.get_feature_count(card)
		var required_features: int = _product_lifecycle.get_mvp_required_features(card)
		var stage: String = _product_lifecycle.get_product_stage(card)
		if stage == ProductLifecycleService.PRODUCT_STAGE_LIVE:
			details.append("Live: %d Features." % feature_count)
		elif feature_count >= required_features:
			details.append("Launchbereit: %d/%d Features." % [feature_count, required_features])
		else:
			details.append("MVP: %d/%d Features." % [feature_count, required_features])
	if definition.tags.has("feature"):
		details.append("Wert: %d Feature." % int(card.values.get("feature_value", 1)))
		if bool(card.values.get("is_checked", false)) or definition.tags.has("checked"):
			details.append("Geprueft.")
	if definition.tags.has("business_goal"):
		details.append("Geld: %d/%d." % [
			maxi(0, int(card.values.get("paid_money", 0))),
			maxi(1, int(card.values.get("required_money", 1))),
		])
	if card.state != null and card.state.is_paid:
		details.append("Gehalt fuer den naechsten Sprint ist bezahlt.")
	elif card.state != null and card.state.is_payment_target:
		details.append("Gehalt offen: 1 Geldkarte.")

	if details.is_empty():
		_set_card_tooltip_text(base_text)
	elif base_text.is_empty():
		_set_card_tooltip_text("\n".join(details))
	else:
		_set_card_tooltip_text("%s\n%s" % [base_text, "\n".join(details)])

func _set_card_tooltip_text(text: String) -> void:
	_custom_tooltip_text = text.strip_edges()
	tooltip_text = ""
	if not _has_custom_tooltip():
		_stop_tooltip_hover()
		return
	if _active_tooltip_owner == self and _is_tooltip_shown:
		_show_custom_tooltip()

func _on_card_mouse_entered() -> void:
	if not _pointer_hover_enabled:
		return
	set_visual_hovered(true, CARD_HOVER_Z_INDEX, true)

func _has_custom_tooltip() -> bool:
	return _uses_processing_tooltip or not _custom_tooltip_text.is_empty()

func _on_card_mouse_exited() -> void:
	if not _pointer_hover_enabled:
		return
	set_visual_hovered(false)

func _stop_tooltip_hover() -> void:
	_is_hovering = false
	_hover_seconds = 0.0
	_hide_custom_tooltip()
	if not _is_tooltip_shown:
		set_process(false)

func _show_custom_tooltip() -> void:
	_ensure_shared_tooltip()
	if _shared_tooltip_view == null:
		return
	if _active_tooltip_owner != null and _active_tooltip_owner != self and is_instance_valid(_active_tooltip_owner):
		_active_tooltip_owner.call("_mark_custom_tooltip_hidden")
	_active_tooltip_owner = self
	_is_tooltip_shown = true
	if _uses_processing_tooltip:
		_shared_tooltip_view.call("show_processing", _processing_tooltip_title, _processing_tooltip_remaining_seconds)
	else:
		_shared_tooltip_view.call("show_plain", _custom_tooltip_text)
	_position_shared_tooltip()

func _hide_custom_tooltip() -> void:
	if _active_tooltip_owner != self:
		_is_tooltip_shown = false
		return
	_is_tooltip_shown = false
	_active_tooltip_owner = null
	if _shared_tooltip_view != null and is_instance_valid(_shared_tooltip_view):
		_shared_tooltip_view.call("hide_tooltip")

func _mark_custom_tooltip_hidden() -> void:
	_is_tooltip_shown = false

func _ensure_shared_tooltip() -> void:
	if _shared_tooltip_layer == null or not is_instance_valid(_shared_tooltip_layer):
		_shared_tooltip_layer = CanvasLayer.new()
		_shared_tooltip_layer.name = "CardTooltipLayer"
		_shared_tooltip_layer.layer = TOOLTIP_LAYER
		get_tree().root.add_child(_shared_tooltip_layer)
	if _shared_tooltip_view != null and is_instance_valid(_shared_tooltip_view):
		_shared_tooltip_view.call("set_visual_theme", visual_theme)
		return

	_shared_tooltip_view = CARD_TOOLTIP_VIEW_SCENE.instantiate() as Control
	_shared_tooltip_view.name = "CardTooltip"
	_shared_tooltip_view.call("set_visual_theme", visual_theme)
	_shared_tooltip_layer.add_child(_shared_tooltip_view)

func _position_shared_tooltip() -> void:
	if _shared_tooltip_view == null or not is_instance_valid(_shared_tooltip_view):
		return
	var viewport: Viewport = get_viewport()
	if viewport == null:
		return
	var mouse_position: Vector2 = viewport.get_mouse_position()
	_shared_tooltip_view.call("position_near_pointer", viewport, mouse_position)

func _update_runtime_tint(card: CardInstance) -> void:
	if card.state == null:
		modulate = Color.WHITE
		return
	if card.state.is_locked and card.parent_card_id.is_empty():
		modulate = _get_card_disabled_modulate()
	elif card.state.is_paid:
		modulate = _get_card_paid_modulate()
	elif card.state.is_payment_target:
		modulate = _get_card_payment_target_modulate()
	else:
		modulate = Color.WHITE

func _get_card_background_color(visual: CardVisualDefinition) -> Color:
	if visual_theme != null:
		return visual_theme.call("get_card_background_color", visual) as Color
	return visual.background_color if visual != null else Color(0.18, 0.20, 0.24, 1.0)

func _get_card_accent_color(visual: CardVisualDefinition) -> Color:
	if visual_theme != null:
		return visual_theme.call("get_card_accent_color", visual) as Color
	return visual.accent_color if visual != null else Color(0.42, 0.72, 0.95, 1.0)

func _get_card_text_color(visual: CardVisualDefinition) -> Color:
	if visual_theme != null:
		return visual_theme.call("get_card_text_color", visual) as Color
	return visual.text_color if visual != null else CARD_TEXT_COLOR

func _get_card_header_text_color() -> Color:
	return _get_theme_color("card_text_color", CARD_TEXT_COLOR)

func _get_card_icon_color(visual: CardVisualDefinition) -> Color:
	if visual_theme != null:
		return visual_theme.call("get_card_icon_color", visual) as Color
	if visual != null and visual.override_icon_color:
		return visual.icon_color
	var background_color: Color = _get_card_background_color(visual)
	var accent_color: Color = _get_card_accent_color(visual)
	var derived: Color = background_color.lerp(accent_color, 0.96).darkened(0.70)
	derived.a = 1.0
	return derived

func _get_card_scribble_color(visual: CardVisualDefinition) -> Color:
	if visual_theme != null:
		return visual_theme.call("get_card_scribble_color", visual) as Color
	var background_color: Color = _get_card_background_color(visual)
	var accent_color: Color = _get_card_accent_color(visual)
	var derived: Color = background_color.lerp(accent_color, 0.72).darkened(0.22)
	derived.a = 0.64
	return derived

func _get_card_hairline_color() -> Color:
	return _get_theme_color("card_hairline_color", CARD_HAIRLINE_COLOR)

func _get_card_shadow_color() -> Color:
	return _get_theme_color("card_shadow_color", SHADOW_COLOR)

func _get_card_drop_target_fill_color() -> Color:
	return _get_theme_color("card_drop_target_fill_color", DROP_TARGET_FILL_COLOR)

func _get_status_badge_text_color() -> Color:
	return _get_theme_color("status_badge_text_color", STATUS_BADGE_TEXT_COLOR)

func _get_status_badge_color() -> Color:
	return _get_theme_color("status_badge_color", STATUS_BADGE_COLOR)

func _get_status_badge_alert_color() -> Color:
	return _get_theme_color("status_badge_alert_color", STATUS_BADGE_ALERT_COLOR)

func _get_status_badge_paid_color() -> Color:
	return _get_theme_color("status_badge_paid_color", STATUS_BADGE_PAID_COLOR)

func _get_card_disabled_modulate() -> Color:
	return _get_theme_color("card_disabled_modulate", Color(0.68, 0.68, 0.68, 1.0))

func _get_card_paid_modulate() -> Color:
	return _get_theme_color("card_paid_modulate", Color(0.68, 0.86, 0.68, 1.0))

func _get_card_payment_target_modulate() -> Color:
	return _get_theme_color("card_payment_target_modulate", Color(1.0, 0.96, 0.72, 1.0))

func _get_theme_color(property_name: String, fallback: Color) -> Color:
	if visual_theme == null:
		return fallback
	var value: Variant = visual_theme.get(property_name)
	if value is Color:
		return value as Color
	return fallback

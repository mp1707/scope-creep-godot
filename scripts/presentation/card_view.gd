class_name CardView
extends Control

const DEFAULT_CARD_SIZE: Vector2 = Vector2(144.0, 196.0)
const CARD_EDGE_INSET: float = 0.0
const CARD_HAIRLINE_WIDTH: int = 1
const CARD_HAIRLINE_COLOR: Color = Color(0.055, 0.052, 0.047, 0.22)
const HEADER_HEIGHT: float = 24.0
const CARD_TEXT_COLOR: Color = Color(0.055, 0.052, 0.047, 1.0)
const TOOLTIP_BACKGROUND_COLOR: Color = Color(0.76, 0.76, 0.72, 1.0)
const TOOLTIP_MAX_WIDTH: float = 286.0
const TOOLTIP_MIN_WIDTH: float = 150.0
const TOOLTIP_FONT_SIZE: int = 18
const TOOLTIP_TIME_FONT_SIZE: int = 18
const TOOLTIP_CONTENT_MARGIN: int = 12
const TOOLTIP_SHOW_DELAY_SECONDS: float = 0.35
const TOOLTIP_CURSOR_OFFSET: Vector2 = Vector2(22.0, 24.0)
const TOOLTIP_VIEWPORT_MARGIN: float = 12.0
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
const TITLE_MAX_FONT_SIZE: int = 18
const TITLE_MIN_FONT_SIZE: int = 8
const DEFAULT_ICON_CENTER: Vector2 = Vector2(72.0, 108.0)
const ICON_MASK_SHADER_CODE: String = "shader_type canvas_item;\nuniform vec4 icon_color : source_color = vec4(0.06, 0.055, 0.05, 1.0);\nvoid fragment() {\n\tvec4 texture_color = texture(TEXTURE, UV);\n\tCOLOR = vec4(icon_color.rgb, texture_color.a * icon_color.a);\n}\n"
const ProductLifecycleServiceScript: Script = preload("res://scripts/simulation/product_lifecycle_service.gd")
const CardJuiceControllerScript: Script = preload("res://scripts/presentation/card_juice_controller.gd")

static var _active_tooltip_owner: Control = null
static var _shared_tooltip_layer: CanvasLayer = null
static var _shared_tooltip_panel: PanelContainer = null
static var _shared_tooltip_label: Label = null
static var _shared_processing_tooltip_container: VBoxContainer = null
static var _shared_processing_title_label: Label = null
static var _shared_processing_duration_row: HBoxContainer = null
static var _shared_processing_duration_label: Label = null
static var _shared_processing_duration_value_label: Label = null

@export var background_path: NodePath
@export var title_label_path: NodePath
@export var icon_texture_rect_path: NodePath
@export var short_text_label_path: NodePath
@export var marker_label_path: NodePath

var card_id: String = ""
var stack_id: String = ""

var _visual_root: Control = null
var _shadow: Control = null
var _background: Control = null
var _header_band: Control = null
var _header_hairline: Control = null
var _title_label: Label = null
var _icon_texture_rect: TextureRect = null
var _short_text_label: Label = null
var _marker_label: Label = null
var _drop_target_feedback: Panel = null
var _juice = null
var _default_marker_text: String = ""
var _card_font: FontFile = null
var _icon_mask_material: ShaderMaterial = null
var _product_lifecycle: RefCounted = ProductLifecycleServiceScript.new()
var _layout_initialized: bool = false
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
	_ensure_visual_root()
	if _background == null:
		_background = _resolve_control(background_path, "Background")
	if _header_band == null:
		_header_band = _resolve_control(NodePath("HeaderBand"), "HeaderBand")
	if _header_hairline == null:
		_header_hairline = _resolve_control(NodePath("HeaderHairline"), "HeaderHairline")
	if _header_hairline == null:
		_header_hairline = _resolve_control(NodePath("HairlineFrame"), "HairlineFrame")
	if _title_label == null:
		_title_label = _resolve_control(title_label_path, "TitleLabel") as Label
	if _icon_texture_rect == null:
		_icon_texture_rect = _resolve_control(icon_texture_rect_path, "IconTextureRect") as TextureRect
	if _icon_texture_rect == null:
		_icon_texture_rect = _resolve_control(NodePath("IconTextureRect"), "IconTextureRect") as TextureRect
	if _short_text_label == null:
		_short_text_label = _resolve_control(short_text_label_path, "ShortTextLabel") as Label
	if _marker_label == null:
		_marker_label = _resolve_control(marker_label_path, "MarkerLabel") as Label

	if _shadow == null:
		_shadow = _resolve_control(NodePath("CardShadow"), "CardShadow")
	if _shadow == null:
		_shadow = _resolve_control(NodePath("DragShadow"), "DragShadow")
	if _shadow == null:
		_shadow = Panel.new()
		_shadow.name = "CardShadow"
		_shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_shadow.visible = false
		_visual_root.add_child(_shadow)

	if _background == null:
		_background = Panel.new()
		_background.name = "Background"
		_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_visual_root.add_child(_background)

	if _header_band == null:
		_header_band = Panel.new()
		_header_band.name = "HeaderBand"
		_header_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_visual_root.add_child(_header_band)

	if _header_hairline == null:
		_header_hairline = Panel.new()
		_header_hairline.name = "HeaderHairline"
		_header_hairline.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_visual_root.add_child(_header_hairline)

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
		_visual_root.add_child(_icon_texture_rect)
	if _short_text_label == null:
		_short_text_label = _create_label("ShortTextLabel", Vector2(12.0, 74.0), Vector2(120.0, 62.0), HORIZONTAL_ALIGNMENT_LEFT)
		_short_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_move_visual_child_to_root(_shadow)
	_move_visual_child_to_root(_background)
	_move_visual_child_to_root(_header_band)
	_move_visual_child_to_root(_icon_texture_rect)
	_move_visual_child_to_root(_title_label)
	_move_visual_child_to_root(_marker_label)
	_move_visual_child_to_root(_short_text_label)
	_move_visual_child_to_root(_header_hairline)
	_ensure_drop_target_feedback()
	_visual_root.move_child(_shadow, 0)
	_visual_root.move_child(_background, 1)
	_visual_root.move_child(_header_band, 2)
	_visual_root.move_child(_icon_texture_rect, 3)
	_visual_root.move_child(_title_label, 4)
	_visual_root.move_child(_marker_label, 5)
	_visual_root.move_child(_short_text_label, 6)
	_visual_root.move_child(_header_hairline, 7)
	_visual_root.move_child(_drop_target_feedback, 8)
	if not _layout_initialized:
		_apply_default_layout()
		_layout_initialized = true
	_ensure_juice_controller()

func _ensure_visual_root() -> void:
	if _visual_root != null and is_instance_valid(_visual_root):
		return
	_visual_root = get_node_or_null("VisualRoot") as Control
	if _visual_root == null:
		_visual_root = Control.new()
		_visual_root.name = "VisualRoot"
		_visual_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_visual_root)
		move_child(_visual_root, 0)
	_set_top_left_layout(_visual_root)
	_visual_root.position = Vector2.ZERO
	_visual_root.size = DEFAULT_CARD_SIZE
	_visual_root.custom_minimum_size = DEFAULT_CARD_SIZE
	_visual_root.pivot_offset = DEFAULT_CARD_SIZE * 0.5
	_visual_root.mouse_filter = Control.MOUSE_FILTER_IGNORE

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

func _move_visual_child_to_root(child: Control) -> void:
	if child == null or child == _visual_root or child.get_parent() == _visual_root:
		return
	child.reparent(_visual_root, false)

func _ensure_drop_target_feedback() -> void:
	if _drop_target_feedback == null:
		_drop_target_feedback = _resolve_control(NodePath("DropTargetFeedback"), "DropTargetFeedback") as Panel
	if _drop_target_feedback == null:
		_drop_target_feedback = Panel.new()
		_drop_target_feedback.name = "DropTargetFeedback"
		_drop_target_feedback.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_drop_target_feedback.visible = false
		_visual_root.add_child(_drop_target_feedback)
	_set_top_left_layout(_drop_target_feedback)
	_drop_target_feedback.position = Vector2.ZERO
	_drop_target_feedback.size = DEFAULT_CARD_SIZE
	_drop_target_feedback.pivot_offset = DEFAULT_CARD_SIZE * 0.5
	_drop_target_feedback.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_drop_target_feedback_style()

func _ensure_juice_controller() -> void:
	if _juice == null:
		_juice = get_node_or_null("CardJuiceController")
	if _juice == null:
		_juice = CardJuiceControllerScript.new() as Node
		_juice.name = "CardJuiceController"
		add_child(_juice)
	_juice.setup(self, _visual_root, _shadow, _drop_target_feedback)
	_juice.set_idle_rotation(_get_idle_rotation_for_card_id(card_id))

func _create_label(node_name: String, label_position: Vector2, label_size: Vector2, alignment: HorizontalAlignment) -> Label:
	var label: Label = Label.new()
	label.name = node_name
	label.position = label_position
	label.size = label_size
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.clip_text = true
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_visual_root.add_child(label)
	return label

func _apply_default_layout() -> void:
	_set_top_left_layout(self)
	mouse_filter = Control.MOUSE_FILTER_PASS
	custom_minimum_size = DEFAULT_CARD_SIZE
	size = DEFAULT_CARD_SIZE
	_set_top_left_layout(_visual_root)
	_visual_root.position = Vector2.ZERO
	_visual_root.size = DEFAULT_CARD_SIZE
	_visual_root.pivot_offset = DEFAULT_CARD_SIZE * 0.5
	_set_top_left_layout(_shadow)
	_shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shadow.position = Vector2(3.0, 4.0)
	_shadow.size = DEFAULT_CARD_SIZE
	_shadow.pivot_offset = Vector2.ZERO
	_apply_shadow_style()
	_set_top_left_layout(_background)
	_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_background.position = Vector2.ZERO
	_background.size = DEFAULT_CARD_SIZE
	_set_top_left_layout(_header_band)
	_header_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_header_band.position = Vector2(CARD_EDGE_INSET, CARD_EDGE_INSET)
	_header_band.size = Vector2(DEFAULT_CARD_SIZE.x - CARD_EDGE_INSET * 2.0, HEADER_HEIGHT)
	_set_top_left_layout(_header_hairline)
	_header_hairline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_header_hairline.position = Vector2(0.0, HEADER_HEIGHT)
	_header_hairline.size = Vector2(DEFAULT_CARD_SIZE.x, float(CARD_HAIRLINE_WIDTH))
	_apply_header_hairline_style()
	_set_top_left_layout(_title_label)
	_title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title_label.position = Vector2(10.0, CARD_EDGE_INSET)
	_title_label.size = Vector2(124.0, HEADER_HEIGHT)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_title_label.clip_text = true
	if _card_font != null:
		_title_label.add_theme_font_override("font", _card_font)
	_title_label.add_theme_font_size_override("font_size", TITLE_MAX_FONT_SIZE)
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
	_marker_label.add_theme_font_size_override("font_size", 18)
	_marker_label.add_theme_color_override("font_color", STATUS_BADGE_TEXT_COLOR)
	_set_top_left_layout(_short_text_label)
	_short_text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_short_text_label.position = Vector2(12.0, 74.0)
	_short_text_label.size = Vector2(120.0, 62.0)
	_short_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_short_text_label.visible = false
	if _card_font != null:
		_short_text_label.add_theme_font_override("font", _card_font)
	_short_text_label.add_theme_font_size_override("font_size", 18)

func _make_custom_tooltip(for_text: String) -> Object:
	if for_text.strip_edges().is_empty():
		return null
	var panel: PanelContainer = PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_tooltip_panel_style(panel)

	var label: Label = _create_tooltip_label(for_text)
	panel.add_child(label)
	return panel

func _apply_tooltip_panel_style(panel: PanelContainer) -> void:
	var style_box: StyleBoxFlat = StyleBoxFlat.new()
	style_box.bg_color = TOOLTIP_BACKGROUND_COLOR
	style_box.shadow_color = Color.TRANSPARENT
	style_box.shadow_offset = Vector2.ZERO
	style_box.shadow_size = 0
	style_box.content_margin_bottom = TOOLTIP_CONTENT_MARGIN
	style_box.content_margin_left = TOOLTIP_CONTENT_MARGIN
	style_box.content_margin_right = TOOLTIP_CONTENT_MARGIN
	style_box.content_margin_top = TOOLTIP_CONTENT_MARGIN
	panel.add_theme_stylebox_override("panel", style_box)

func _create_tooltip_label(for_text: String) -> Label:
	var label: Label = Label.new()
	label.text = for_text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.clip_text = false
	label.add_theme_color_override("font_color", CARD_TEXT_COLOR)
	if _card_font == null:
		_card_font = ResourceLoader.load(CARD_FONT_PATH) as FontFile
	if _card_font != null:
		label.add_theme_font_override("font", _card_font)
	label.add_theme_font_size_override("font_size", TOOLTIP_FONT_SIZE)
	label.custom_minimum_size.x = _get_tooltip_text_width(for_text, label.get_theme_font("font"))
	return label

func _create_processing_tooltip_container() -> VBoxContainer:
	var container: VBoxContainer = VBoxContainer.new()
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_theme_constant_override("separation", 4)

	_shared_processing_title_label = _create_tooltip_label("")
	container.add_child(_shared_processing_title_label)

	_shared_processing_duration_row = HBoxContainer.new()
	_shared_processing_duration_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shared_processing_duration_row.add_theme_constant_override("separation", 12)

	_shared_processing_duration_label = _create_processing_tooltip_label("Restdauer:")
	_shared_processing_duration_row.add_child(_shared_processing_duration_label)

	var spacer: Control = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shared_processing_duration_row.add_child(spacer)

	_shared_processing_duration_value_label = _create_processing_tooltip_label("")
	_shared_processing_duration_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_shared_processing_duration_row.add_child(_shared_processing_duration_value_label)

	container.add_child(_shared_processing_duration_row)
	return container

func _create_processing_tooltip_label(for_text: String) -> Label:
	var label: Label = Label.new()
	label.text = for_text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.clip_text = false
	label.add_theme_color_override("font_color", CARD_TEXT_COLOR)
	if _card_font == null:
		_card_font = ResourceLoader.load(CARD_FONT_PATH) as FontFile
	if _card_font != null:
		label.add_theme_font_override("font", _card_font)
	label.add_theme_font_size_override("font_size", TOOLTIP_TIME_FONT_SIZE)
	return label

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
		label.add_theme_color_override("font_color", visual.text_color)
	_marker_label.add_theme_color_override("font_color", STATUS_BADGE_TEXT_COLOR)

	if _background is ColorRect:
		(_background as ColorRect).color = visual.background_color
	else:
		var style_box: StyleBoxFlat = StyleBoxFlat.new()
		style_box.bg_color = visual.background_color
		_background.add_theme_stylebox_override("panel", style_box)
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
	_header_band.add_theme_stylebox_override("panel", header_style)

func _apply_header_hairline_style() -> void:
	if _header_hairline == null:
		return
	if _header_hairline is ColorRect:
		(_header_hairline as ColorRect).color = CARD_HAIRLINE_COLOR
		return
	var hairline_style: StyleBoxFlat = StyleBoxFlat.new()
	hairline_style.bg_color = CARD_HAIRLINE_COLOR
	_header_hairline.add_theme_stylebox_override("panel", hairline_style)

func _apply_shadow_style() -> void:
	if _shadow == null:
		return
	if _shadow is ColorRect:
		(_shadow as ColorRect).color = SHADOW_COLOR
		return
	var shadow_style: StyleBoxFlat = StyleBoxFlat.new()
	shadow_style.bg_color = SHADOW_COLOR
	_shadow.add_theme_stylebox_override("panel", shadow_style)

func _apply_drop_target_feedback_style() -> void:
	if _drop_target_feedback == null:
		return
	var style_box: StyleBoxFlat = StyleBoxFlat.new()
	style_box.bg_color = DROP_TARGET_FILL_COLOR
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
		style_box.bg_color = STATUS_BADGE_PAID_COLOR
	elif marker_text == "BO" or marker_text == "!!!" or marker_text == "$":
		style_box.bg_color = STATUS_BADGE_ALERT_COLOR
	else:
		style_box.bg_color = STATUS_BADGE_COLOR
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
	if _shared_tooltip_panel == null or _shared_tooltip_label == null:
		return
	if _active_tooltip_owner != null and _active_tooltip_owner != self and is_instance_valid(_active_tooltip_owner):
		_active_tooltip_owner.call("_mark_custom_tooltip_hidden")
	_active_tooltip_owner = self
	_is_tooltip_shown = true
	if _uses_processing_tooltip:
		_apply_processing_tooltip_content()
	else:
		_apply_plain_tooltip_content()
	_shared_tooltip_panel.visible = true
	_shared_tooltip_panel.reset_size()
	_position_shared_tooltip()

func _apply_plain_tooltip_content() -> void:
	if _shared_tooltip_label == null:
		return
	_shared_tooltip_label.visible = true
	if _shared_processing_tooltip_container != null:
		_shared_processing_tooltip_container.visible = false
	_shared_tooltip_label.text = _custom_tooltip_text
	_shared_tooltip_label.custom_minimum_size.x = _get_tooltip_text_width(
		_custom_tooltip_text,
		_shared_tooltip_label.get_theme_font("font")
	)

func _apply_processing_tooltip_content() -> void:
	if _shared_processing_tooltip_container == null:
		return
	if _shared_tooltip_label != null:
		_shared_tooltip_label.visible = false
	_shared_processing_tooltip_container.visible = true
	var tooltip_title: String = _get_processing_tooltip_title_text()
	var remaining_text: String = "%d Sek" % ceili(_processing_tooltip_remaining_seconds)
	var content_width: float = _get_processing_tooltip_width(tooltip_title, remaining_text)

	_shared_processing_title_label.text = tooltip_title
	_shared_processing_title_label.custom_minimum_size.x = content_width
	_shared_processing_duration_row.custom_minimum_size.x = content_width
	_shared_processing_duration_label.text = "Restdauer:"
	_shared_processing_duration_value_label.text = remaining_text

func _get_processing_tooltip_title_text() -> String:
	if _processing_tooltip_title.ends_with("..."):
		return _processing_tooltip_title
	return "%s..." % _processing_tooltip_title

func _get_processing_tooltip_width(title_text: String, remaining_text: String) -> float:
	var title_width: float = TOOLTIP_MIN_WIDTH - float(TOOLTIP_CONTENT_MARGIN * 2)
	var title_font: Font = _shared_processing_title_label.get_theme_font("font") if _shared_processing_title_label != null else null
	if title_font != null:
		title_width = title_font.get_string_size(title_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, TOOLTIP_FONT_SIZE).x

	var duration_width: float = TOOLTIP_MIN_WIDTH - float(TOOLTIP_CONTENT_MARGIN * 2)
	var time_font: Font = _shared_processing_duration_label.get_theme_font("font") if _shared_processing_duration_label != null else null
	if time_font != null:
		duration_width = time_font.get_string_size("Restdauer:", HORIZONTAL_ALIGNMENT_LEFT, -1.0, TOOLTIP_TIME_FONT_SIZE).x
		duration_width += 32.0
		duration_width += time_font.get_string_size(remaining_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, TOOLTIP_TIME_FONT_SIZE).x

	return clampf(
		maxf(title_width, duration_width),
		TOOLTIP_MIN_WIDTH - float(TOOLTIP_CONTENT_MARGIN * 2),
		TOOLTIP_MAX_WIDTH - float(TOOLTIP_CONTENT_MARGIN * 2)
	)

func _hide_custom_tooltip() -> void:
	if _active_tooltip_owner != self:
		_is_tooltip_shown = false
		return
	_is_tooltip_shown = false
	_active_tooltip_owner = null
	if _shared_tooltip_panel != null and is_instance_valid(_shared_tooltip_panel):
		_shared_tooltip_panel.visible = false

func _mark_custom_tooltip_hidden() -> void:
	_is_tooltip_shown = false

func _ensure_shared_tooltip() -> void:
	if _shared_tooltip_layer == null or not is_instance_valid(_shared_tooltip_layer):
		_shared_tooltip_layer = CanvasLayer.new()
		_shared_tooltip_layer.name = "CardTooltipLayer"
		_shared_tooltip_layer.layer = TOOLTIP_LAYER
		get_tree().root.add_child(_shared_tooltip_layer)
	if _shared_tooltip_panel != null and is_instance_valid(_shared_tooltip_panel):
		return

	_shared_tooltip_panel = PanelContainer.new()
	_shared_tooltip_panel.name = "CardTooltip"
	_shared_tooltip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shared_tooltip_panel.visible = false
	_apply_tooltip_panel_style(_shared_tooltip_panel)
	_shared_tooltip_label = _create_tooltip_label("")
	_shared_tooltip_panel.add_child(_shared_tooltip_label)
	_shared_processing_tooltip_container = _create_processing_tooltip_container()
	_shared_processing_tooltip_container.visible = false
	_shared_tooltip_panel.add_child(_shared_processing_tooltip_container)
	_shared_tooltip_layer.add_child(_shared_tooltip_panel)

func _position_shared_tooltip() -> void:
	if _shared_tooltip_panel == null or not is_instance_valid(_shared_tooltip_panel):
		return
	var viewport: Viewport = get_viewport()
	if viewport == null:
		return
	var viewport_size: Vector2 = viewport.get_visible_rect().size
	var mouse_position: Vector2 = viewport.get_mouse_position()
	var tooltip_size: Vector2 = _shared_tooltip_panel.get_combined_minimum_size()
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
	_shared_tooltip_panel.position = target_position

func _update_runtime_tint(card: CardInstance) -> void:
	if card.state == null:
		modulate = Color.WHITE
		return
	if card.state.is_locked and card.parent_card_id.is_empty():
		modulate = Color(0.68, 0.68, 0.68, 1.0)
	elif card.state.is_paid:
		modulate = Color(0.68, 0.86, 0.68, 1.0)
	elif card.state.is_payment_target:
		modulate = Color(1.0, 0.96, 0.72, 1.0)
	else:
		modulate = Color.WHITE

class_name StackDropHighlightView
extends Control

const DEFAULT_TEXTURE_PATH: String = "res://assets/card/cornerHighlightStripes.png"
const DEFAULT_CORNER_SIZE: float = 42.0
const DEFAULT_CORNER_MARGIN: float = 0.0
const DEFAULT_COLOR: Color = Color(0.20, 0.68, 0.94, 0.88)
const SNAP_SCALE_START: Vector2 = Vector2(0.88, 0.88)
const SNAP_SCALE_PEAK: Vector2 = Vector2(1.04, 1.04)
const SNAP_IN_SECONDS: float = 0.08
const SNAP_HOLD_SECONDS: float = 0.06
const SNAP_OUT_SECONDS: float = 0.12

@export var top_corner_path: NodePath = NodePath("TopCorner")
@export var bottom_corner_path: NodePath = NodePath("BottomCorner")

static var _shared_corner_texture: Texture2D = null
static var _corner_texture_load_attempted: bool = false

var _top_corner: TextureRect = null
var _bottom_corner: TextureRect = null
var _uses_right_top_corner: bool = true

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_resolve_nodes()

func configure(highlight_size: Vector2, visual_theme: Resource = null, target_visual: CardVisualDefinition = null) -> void:
	_resolve_nodes()
	size = highlight_size
	custom_minimum_size = highlight_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var texture: Texture2D = _get_corner_texture(visual_theme)
	var corner_size: float = _get_theme_float(visual_theme, "stack_drop_corner_size", DEFAULT_CORNER_SIZE)
	var corner_margin: float = _get_theme_float(visual_theme, "stack_drop_corner_margin", DEFAULT_CORNER_MARGIN)
	var corner_color: Color = _get_corner_color(visual_theme, target_visual)
	_configure_corner(_top_corner, texture, corner_size, corner_margin, true, corner_color)
	_configure_corner(_bottom_corner, texture, corner_size, corner_margin, false, corner_color)

func randomize_orientation() -> void:
	_uses_right_top_corner = bool(randi() & 1)

func play_snap_feedback() -> void:
	if DisplayServer.get_name() == "headless" or not is_inside_tree():
		queue_free()
		return
	pivot_offset = size * 0.5
	scale = SNAP_SCALE_START
	modulate.a = 0.0
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, SNAP_IN_SECONDS)
	tween.parallel().tween_property(self, "scale", SNAP_SCALE_PEAK, SNAP_IN_SECONDS)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)
	tween.tween_interval(SNAP_HOLD_SECONDS)
	tween.tween_property(self, "modulate:a", 0.0, SNAP_OUT_SECONDS)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "scale", Vector2.ONE, SNAP_OUT_SECONDS)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
	tween.finished.connect(queue_free)

func _resolve_nodes() -> void:
	if _top_corner == null:
		_top_corner = get_node_or_null(top_corner_path) as TextureRect
	if _bottom_corner == null:
		_bottom_corner = get_node_or_null(bottom_corner_path) as TextureRect

func _configure_corner(
	corner: TextureRect,
	texture: Texture2D,
	corner_size: float,
	corner_margin: float,
	is_top: bool,
	corner_color: Color
) -> void:
	if corner == null:
		return
	corner.texture = texture
	corner.visible = texture != null
	corner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	corner.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	corner.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	corner.size = Vector2(corner_size, corner_size)
	corner.self_modulate = corner_color
	var is_right: bool = _uses_right_top_corner if is_top else not _uses_right_top_corner
	corner.position = Vector2(
		size.x - corner_size + corner_margin if is_right else -corner_margin,
		-corner_margin if is_top else size.y - corner_size + corner_margin
	)
	corner.flip_h = is_right
	corner.flip_v = not is_top

func _get_corner_texture(visual_theme: Resource) -> Texture2D:
	if visual_theme != null and visual_theme.get("stack_drop_corner_texture") != null:
		return visual_theme.get("stack_drop_corner_texture") as Texture2D
	if _shared_corner_texture != null:
		return _shared_corner_texture
	if _corner_texture_load_attempted:
		return null
	_corner_texture_load_attempted = true
	_shared_corner_texture = ResourceLoader.load(DEFAULT_TEXTURE_PATH) as Texture2D
	return _shared_corner_texture

func _get_corner_color(visual_theme: Resource, target_visual: CardVisualDefinition) -> Color:
	if visual_theme != null and visual_theme.has_method("get_stack_drop_corner_color"):
		return visual_theme.call("get_stack_drop_corner_color", target_visual) as Color
	return DEFAULT_COLOR

func _get_theme_float(visual_theme: Resource, property_name: String, fallback: float) -> float:
	if visual_theme == null:
		return fallback
	var value: Variant = visual_theme.get(property_name)
	if value is float or value is int:
		return float(value)
	return fallback

class_name InteractionHighlightView
extends Control

const DEFAULT_TEXTURE_PATH: String = "res://assets/icons/handdrawn/cardIcons/arrowBottomRight.png"
const DEFAULT_TINT: Color = Color(0.075, 0.095, 0.12, 1.0)
const DEFAULT_ARROW_SIZE: Vector2 = Vector2(56.0, 56.0)
const DEFAULT_ARROW_OFFSET: Vector2 = Vector2(-20.0, -38.0)
const SHOW_SCALE_START: Vector2 = Vector2(0.965, 0.965)
const SHOW_DURATION: float = 0.12

@export var texture_rect_path: NodePath = NodePath("ArrowTextureRect")

var tint_color: Color = DEFAULT_TINT:
	set(value):
		tint_color = value
		if _texture_rect != null:
			_texture_rect.self_modulate = tint_color

static var _shared_default_texture: Texture2D = null
static var _default_texture_load_attempted: bool = false

var _texture_rect: TextureRect = null
var _show_tween: Tween = null

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	pivot_offset = size * 0.5
	_resolve_nodes()
	set_process(false)

func configure(highlight_size: Vector2, visual_theme: Resource = null, target_visual: CardVisualDefinition = null) -> void:
	_resolve_nodes()
	size = highlight_size
	custom_minimum_size = size
	pivot_offset = size * 0.5
	apply_visual_theme(visual_theme, target_visual)

func apply_visual_theme(visual_theme: Resource, target_visual: CardVisualDefinition = null) -> void:
	if _texture_rect == null:
		return
	_texture_rect.texture = _get_preview_texture(visual_theme)
	_texture_rect.visible = _texture_rect.texture != null
	var arrow_size: Vector2 = _get_arrow_size(visual_theme)
	_texture_rect.size = arrow_size
	_texture_rect.position = Vector2(size.x, 0.0) + _get_arrow_offset(visual_theme)
	_texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_texture_rect.flip_h = true
	_texture_rect.flip_v = false
	tint_color = _get_preview_color(visual_theme, target_visual)

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

func _resolve_nodes() -> void:
	if _texture_rect == null:
		_texture_rect = get_node_or_null(texture_rect_path) as TextureRect

func _get_preview_texture(visual_theme: Resource) -> Texture2D:
	if visual_theme != null:
		var themed_texture: Texture2D = visual_theme.get("interaction_preview_arrow_texture") as Texture2D
		if themed_texture != null:
			return themed_texture
	return _get_default_texture()

func _get_default_texture() -> Texture2D:
	if _shared_default_texture != null or _default_texture_load_attempted:
		return _shared_default_texture
	_default_texture_load_attempted = true
	_shared_default_texture = ResourceLoader.load(DEFAULT_TEXTURE_PATH) as Texture2D
	return _shared_default_texture

func _get_preview_color(visual_theme: Resource, target_visual: CardVisualDefinition) -> Color:
	if visual_theme != null and visual_theme.has_method("get_interaction_preview_color"):
		return visual_theme.call("get_interaction_preview_color", target_visual) as Color
	return DEFAULT_TINT

func _get_arrow_size(visual_theme: Resource) -> Vector2:
	if visual_theme == null:
		return DEFAULT_ARROW_SIZE
	var value: Variant = visual_theme.get("interaction_preview_arrow_size")
	if value is Vector2:
		return value as Vector2
	return DEFAULT_ARROW_SIZE

func _get_arrow_offset(visual_theme: Resource) -> Vector2:
	if visual_theme == null:
		return DEFAULT_ARROW_OFFSET
	var value: Variant = visual_theme.get("interaction_preview_arrow_offset")
	if value is Vector2:
		return value as Vector2
	return DEFAULT_ARROW_OFFSET

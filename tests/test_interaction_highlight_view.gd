extends SceneTree

var _failed: bool = false

func _init() -> void:
	var visual_theme: Resource = ResourceLoader.load("res://data/visual_themes/poc_default_visual_theme.tres")
	var scene: PackedScene = ResourceLoader.load("res://scenes/presentation/InteractionHighlightView.tscn") as PackedScene
	_assert_true(scene != null, "InteractionHighlightView scene should load.")
	if scene == null:
		quit(1)
		return

	var view: Control = scene.instantiate() as Control
	root.add_child(view)
	var highlight_size: Vector2 = Vector2(180.0, 244.0)
	view.call("configure", highlight_size, visual_theme)
	view.call("play_show")

	_assert_equal(view.mouse_filter, Control.MOUSE_FILTER_IGNORE, "Interaction highlight should ignore mouse input.")
	_assert_true(view.get("tint_color") is Color, "Interaction highlight should expose a texture tint color.")
	_assert_vector_equal(view.size, highlight_size, "Interaction highlight should keep stable bounds.")
	_assert_vector_equal(view.custom_minimum_size, highlight_size, "Interaction highlight should expose stable minimum bounds.")
	_assert_true(not (view.call("is_animating") as bool), "Interaction highlight should not run a per-frame dash animation.")
	_assert_equal(_get_texture_rect(view).texture, visual_theme.get("interaction_preview_arrow_texture"), "Interaction highlight should use the themed arrow texture.")
	_assert_vector_equal(_get_texture_rect(view).size, visual_theme.get("interaction_preview_arrow_size") as Vector2, "Interaction highlight should use the themed arrow size.")
	var arrow_offset: Vector2 = visual_theme.get("interaction_preview_arrow_offset") as Vector2
	var expected_arrow_position: Vector2 = Vector2(highlight_size.x, 0.0) + arrow_offset
	_assert_vector_equal(_get_texture_rect(view).position, expected_arrow_position, "Interaction highlight should anchor the arrow at the top-right card corner.")
	_assert_true(_get_texture_rect(view).flip_h, "Interaction highlight should mirror the bottom-right arrow horizontally.")
	_assert_color_equal(view.get("tint_color") as Color, visual_theme.get("card_text_color") as Color, "Interaction highlight should use the card header text color.")

	view.free()
	if _failed:
		quit(1)
		return

	print("Interaction highlight view test passed.")
	quit(0)

func _assert_true(value: bool, message: String) -> void:
	if value:
		return
	_failed = true
	push_error(message)

func _assert_equal(actual: Variant, expected: Variant, message: String) -> void:
	if actual == expected:
		return
	_failed = true
	push_error("%s Expected '%s', got '%s'." % [message, str(expected), str(actual)])

func _assert_vector_equal(actual: Vector2, expected: Vector2, message: String) -> void:
	if actual.is_equal_approx(expected):
		return
	_failed = true
	push_error("%s Expected '%s', got '%s'." % [message, str(expected), str(actual)])

func _assert_color_equal(actual: Color, expected: Color, message: String) -> void:
	if actual.is_equal_approx(expected):
		return
	_failed = true
	push_error("%s Expected '%s', got '%s'." % [message, str(expected), str(actual)])

func _get_texture_rect(view: Control) -> TextureRect:
	return view.get_node_or_null("ArrowTextureRect") as TextureRect

extends SceneTree

var _failed: bool = false

func _init() -> void:
	var visual_theme: Resource = ResourceLoader.load("res://data/visual_themes/poc_default_visual_theme.tres")
	var scene: PackedScene = ResourceLoader.load("res://scenes/presentation/StackDropHighlightView.tscn") as PackedScene
	_assert_true(scene != null, "StackDropHighlightView scene should load.")
	if scene == null:
		quit(1)
		return

	var view: Control = scene.instantiate() as Control
	root.add_child(view)
	var highlight_size: Vector2 = Vector2(180.0, 244.0)
	view.call("configure", highlight_size, visual_theme)

	var top_corner: TextureRect = view.get_node_or_null("TopCorner") as TextureRect
	var bottom_corner: TextureRect = view.get_node_or_null("BottomCorner") as TextureRect
	_assert_true(top_corner != null, "Stack drop highlight should have a top corner texture.")
	_assert_true(bottom_corner != null, "Stack drop highlight should have a bottom corner texture.")
	_assert_equal(view.mouse_filter, Control.MOUSE_FILTER_IGNORE, "Stack drop highlight should ignore mouse input.")
	_assert_vector_equal(view.size, highlight_size, "Stack drop highlight should keep stable bounds.")
	if top_corner != null and bottom_corner != null:
		_assert_equal(top_corner.texture, visual_theme.get("stack_drop_corner_texture"), "Top corner should use themed stripes.")
		_assert_equal(bottom_corner.texture, visual_theme.get("stack_drop_corner_texture"), "Bottom corner should use themed stripes.")
		_assert_true(not is_equal_approx(top_corner.position.y, bottom_corner.position.y), "Stack drop stripes should sit at top and bottom of the stack bounds.")
		_assert_true(top_corner.flip_h != bottom_corner.flip_h, "Stack drop stripes should use diagonal opposite corners.")

	view.free()
	if _failed:
		quit(1)
		return

	print("Stack drop highlight view test passed.")
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

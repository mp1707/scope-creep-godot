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
	view.set_process(true)
	var highlight_size: Vector2 = Vector2(180.0, 244.0)
	view.call("configure", highlight_size, visual_theme)
	view.call("play_show")

	_assert_equal(view.mouse_filter, Control.MOUSE_FILTER_IGNORE, "Interaction highlight should ignore mouse input.")
	_assert_color_equal(view.get("line_color") as Color, visual_theme.get("card_text_color") as Color, "Interaction highlight should use the shared card text color.")
	_assert_vector_equal(view.size, highlight_size, "Interaction highlight should keep stable bounds.")
	_assert_vector_equal(view.custom_minimum_size, highlight_size, "Interaction highlight should expose stable minimum bounds.")
	_assert_true(view.call("is_animating") as bool, "Interaction highlight should keep its marching-dash animation active.")
	_assert_equal(view.get("dash_length"), visual_theme.get("interaction_preview_dash_length"), "Interaction highlight should read dash length from the visual theme.")
	_assert_equal(view.get("dash_speed"), visual_theme.get("interaction_preview_dash_speed"), "Interaction highlight should read dash speed from the visual theme.")

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

func _assert_color_equal(actual: Color, expected: Color, message: String) -> void:
	if actual.is_equal_approx(expected):
		return
	_failed = true
	push_error("%s Expected '%s', got '%s'." % [message, str(expected), str(actual)])

func _assert_vector_equal(actual: Vector2, expected: Vector2, message: String) -> void:
	if actual.is_equal_approx(expected):
		return
	_failed = true
	push_error("%s Expected '%s', got '%s'." % [message, str(expected), str(actual)])

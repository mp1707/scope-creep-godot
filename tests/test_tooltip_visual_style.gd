extends SceneTree

var _failed: bool = false

func _init() -> void:
	var visual_theme: Resource = ResourceLoader.load("res://data/visual_themes/poc_default_visual_theme.tres")
	var card_scene: PackedScene = ResourceLoader.load("res://scenes/presentation/CardView.tscn") as PackedScene
	var view: CardView = card_scene.instantiate() as CardView
	root.add_child(view)
	view.set_visual_theme(visual_theme)

	var tooltip: PanelContainer = view.call("_make_custom_tooltip", "Kontrasttest") as PanelContainer
	_assert_true(tooltip != null, "CardView should create a tooltip panel.")
	if tooltip != null:
		var style_box: StyleBoxFlat = tooltip.get_theme_stylebox("panel") as StyleBoxFlat
		_assert_true(style_box != null, "Tooltip panel should use a flat stylebox.")
		if style_box != null:
			var expected_shadow_color: Color = visual_theme.get("card_shadow_color") as Color
			expected_shadow_color.a *= 0.25
			_assert_color_equal(style_box.bg_color, visual_theme.get("tooltip_background_color") as Color, "Tooltip should use the visual theme background color.")
			_assert_color_equal(style_box.shadow_color, expected_shadow_color, "Tooltip shadow should match idle card shadow opacity.")
			_assert_vector_equal(style_box.shadow_offset, Vector2(3.0, 4.0), "Tooltip shadow should match idle card shadow offset.")
			_assert_equal(style_box.shadow_size, 0, "Tooltip shadow should stay sharp like the card shadow panel.")

	if tooltip != null:
		tooltip.free()
	view.free()

	if _failed:
		quit(1)
		return

	print("Tooltip visual style test passed.")
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

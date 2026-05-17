extends SceneTree

var _failed: bool = false

func _init() -> void:
	var content: ContentCatalog = ContentCatalog.new()
	_assert_true(content.load_default_content(), "Default content should load.")

	var card_scene: PackedScene = ResourceLoader.load("res://scenes/presentation/CardView.tscn") as PackedScene
	_assert_true(card_scene != null, "CardView scene should load.")
	if card_scene == null:
		quit(1)
		return

	var view: CardView = card_scene.instantiate() as CardView
	root.add_child(view)
	view.set_visual_theme(content.visual_theme)

	var definition: CardDefinition = content.get_card_definition("card.candidate.product_owner")
	_assert_true(definition != null, "Product Owner candidate definition should exist.")
	var card: CardInstance = _create_test_card(definition)
	var stack: StackState = _create_test_stack(card)
	view.setup(card, definition, stack)

	var title_label: Label = view.get_node("VisualRoot/TitleLabel") as Label
	var fitted_font_size: int = title_label.get_theme_font_size("font_size")
	_assert_true(fitted_font_size < 18, "Long title should shrink below max font size.")

	view.begin_drag_preview(Vector2(64.0, 64.0), Vector2.ONE)
	view.clear_drag_preview()
	view.play_snap_to(Vector2(96.0, 96.0))

	var after_drag_font_size: int = title_label.get_theme_font_size("font_size")
	_assert_equal(after_drag_font_size, fitted_font_size, "Drag/drop should not reset fitted title font size.")

	var shop_definition: CardDefinition = content.get_card_definition("card.shop.freelance_order")
	_assert_true(shop_definition != null, "Freelance shop definition should exist.")
	var shop_card: CardInstance = _create_test_card(shop_definition)
	shop_card.values["shop_price_money_cards"] = 1
	var shop_stack: StackState = _create_test_stack(shop_card)
	view.setup(shop_card, shop_definition, shop_stack)
	var price_root: Control = view.get_node("VisualRoot/ShopPriceRoot") as Control
	_assert_true(price_root.visible, "Shop price should be visible after setup.")
	view.set_visual_hovered(true)
	_assert_true(price_root.visible, "Shop price should stay visible after hover starts.")
	view.set_visual_hovered(false)
	_assert_true(price_root.visible, "Shop price should stay visible after hover ends.")

	var hidden_shop_definition: CardDefinition = content.get_card_definition("card.shop.booster_slot.customer_chaos")
	_assert_true(hidden_shop_definition != null, "Customer chaos shop definition should exist.")
	var hidden_shop_card: CardInstance = _create_test_card(hidden_shop_definition)
	hidden_shop_card.values["shop_revealed"] = false
	var hidden_shop_stack: StackState = _create_test_stack(hidden_shop_card)
	view.setup(hidden_shop_card, hidden_shop_definition, hidden_shop_stack)
	var icon_texture_rect: TextureRect = view.get_node("VisualRoot/IconTextureRect") as TextureRect
	_assert_equal(title_label.text, "??????", "Hidden shop cards should show the masked title.")
	_assert_true(not price_root.visible, "Hidden shop cards should not show a price.")
	_assert_true(icon_texture_rect.texture != null and icon_texture_rect.texture.resource_path.ends_with("questionmark.png"), "Hidden shop cards should use the questionmark icon.")

	view.free()
	if _failed:
		quit(1)
		return

	print("Card title fit test passed.")
	quit(0)

func _create_test_card(definition: CardDefinition) -> CardInstance:
	var card: CardInstance = CardInstance.new()
	card.instance_id = "test.card.long_title"
	card.definition_id = definition.id
	card.stack_id = "test.stack"
	card.state = CardRuntimeState.new()
	return card

func _create_test_stack(card: CardInstance) -> StackState:
	var stack: StackState = StackState.new()
	stack.stack_id = card.stack_id
	stack.card_ids.append(card.instance_id)
	return stack

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

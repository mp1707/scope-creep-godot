extends SceneTree

const SOFTWARE_DEFINITION_ID: String = "card.product.software"
const PRODUCT_STAGE_VALUE: String = "product_stage"
const FEATURE_COUNT_VALUE: String = "feature_count"
const MVP_REQUIRED_FEATURES_VALUE: String = "mvp_required_features"
const LAUNCH_FEATURE_COUNT_VALUE: String = "launch_feature_count"
const PRODUCT_STAGE_MVP: String = "mvp"
const PRODUCT_STAGE_LIVE: String = "live"

var _failed: bool = false

func _init() -> void:
	_test_start_run_initializes_mvp_software()
	_test_launch_ready_query_uses_software_runtime_values()
	_test_legacy_software_values_get_defaults_on_load()
	_test_card_view_shows_software_status()

	if _failed:
		quit(1)
		return

	print("PoC3 phase 1 software status tests passed.")
	quit(0)

func _test_start_run_initializes_mvp_software() -> void:
	var controller: RunController = _create_controller()
	var state: RunState = controller.start_new_run(301)
	var software: CardInstance = controller.get_software_card()

	_assert_true(software != null, "Start run should expose the software card.")
	_assert_equal(software.values[PRODUCT_STAGE_VALUE], PRODUCT_STAGE_MVP, "Software should start as MVP.")
	_assert_equal(software.values[FEATURE_COUNT_VALUE], 0, "Software should start with zero features.")
	_assert_equal(software.values[MVP_REQUIRED_FEATURES_VALUE], 10, "Software should need ten MVP features.")
	_assert_equal(software.values[LAUNCH_FEATURE_COUNT_VALUE], 0, "Software should not have launch feature count before launch.")
	_assert_true(not controller.is_software_launch_ready(), "Fresh MVP software should not be launch-ready.")
	_assert_equal(_count_cards_by_definition(state, SOFTWARE_DEFINITION_ID), 1, "Run should contain exactly one software card.")

func _test_launch_ready_query_uses_software_runtime_values() -> void:
	var controller: RunController = _create_controller()
	controller.start_new_run(302)
	var software: CardInstance = controller.get_software_card()

	software.values[FEATURE_COUNT_VALUE] = 9
	_assert_true(not controller.is_software_launch_ready(), "Nine features should not be launch-ready.")

	software.values[FEATURE_COUNT_VALUE] = 10
	_assert_true(controller.is_software_launch_ready(), "Ten features should be launch-ready.")

	software.values[PRODUCT_STAGE_VALUE] = PRODUCT_STAGE_LIVE
	_assert_true(not controller.is_software_launch_ready(), "Live software should not match launch-ready MVP queries.")

func _test_legacy_software_values_get_defaults_on_load() -> void:
	var controller: RunController = _create_controller()
	var state: RunState = controller.start_new_run(303)
	var software: CardInstance = controller.get_software_card()
	software.values.clear()

	controller.load_run(state)
	software = controller.get_software_card()
	_assert_equal(software.values[PRODUCT_STAGE_VALUE], PRODUCT_STAGE_MVP, "Loaded legacy software should receive product_stage.")
	_assert_equal(software.values[FEATURE_COUNT_VALUE], 0, "Loaded legacy software should receive feature_count.")
	_assert_equal(software.values[MVP_REQUIRED_FEATURES_VALUE], 10, "Loaded legacy software should receive mvp_required_features.")

func _test_card_view_shows_software_status() -> void:
	var catalog: ContentCatalog = _load_catalog()
	var stack: StackState = _create_stack()
	var software: CardInstance = _create_card(SOFTWARE_DEFINITION_ID, stack.stack_id)
	software.values[PRODUCT_STAGE_VALUE] = PRODUCT_STAGE_MVP
	software.values[FEATURE_COUNT_VALUE] = 7
	software.values[MVP_REQUIRED_FEATURES_VALUE] = 10
	stack.card_ids.append(software.instance_id)

	var view: CardView = _setup_card_view(software, catalog.get_card_definition(software.definition_id), stack)
	var short_text: Label = view.get_node("ShortTextLabel") as Label
	var icon: TextureRect = view.get_node("IconTextureRect") as TextureRect
	_assert_true(not icon.visible, "Software should not render an icon over product status.")
	_assert_true(short_text.visible, "Software should show product status on the card.")
	_assert_equal(short_text.text, "MVP\n7/10 Features", "Software card should show MVP feature progress.")
	_assert_true(view.tooltip_text.contains("Status: MVP"), "Software tooltip should include product stage.")
	_assert_true(view.tooltip_text.contains("Features: 7/10"), "Software tooltip should include feature progress.")

	software.values[FEATURE_COUNT_VALUE] = 10
	view.setup(software, catalog.get_card_definition(software.definition_id), stack)
	_assert_equal(short_text.text, "Launchbereit\n10/10 Features", "Software card should show launch-ready state.")

	software.values[PRODUCT_STAGE_VALUE] = PRODUCT_STAGE_LIVE
	software.values[FEATURE_COUNT_VALUE] = 12
	view.setup(software, catalog.get_card_definition(software.definition_id), stack)
	_assert_equal(short_text.text, "Live\n12 Features", "Live software should show live feature count.")
	view.queue_free()

func _create_controller() -> RunController:
	var catalog: ContentCatalog = _load_catalog()
	return RunController.new(catalog)

func _load_catalog() -> ContentCatalog:
	var catalog: ContentCatalog = ContentCatalog.new()
	_assert_true(catalog.load_default_content(), "Default content should load.")
	return catalog

func _setup_card_view(card: CardInstance, definition: CardDefinition, stack: StackState) -> CardView:
	var view: CardView = CardView.new()
	get_root().add_child(view)
	view.setup(card, definition, stack)
	return view

func _create_stack() -> StackState:
	var stack: StackState = StackState.new()
	stack.stack_id = "stack_test"
	stack.base_position = Vector2(320.0, 240.0)
	return stack

func _create_card(definition_id: String, stack_id: String) -> CardInstance:
	var card: CardInstance = CardInstance.new()
	card.instance_id = "card_test"
	card.definition_id = definition_id
	card.stack_id = stack_id
	card.state = CardRuntimeState.new()
	return card

func _count_cards_by_definition(state: RunState, definition_id: String) -> int:
	var count: int = 0
	for card: CardInstance in state.cards.values():
		if card.definition_id == definition_id:
			count += 1
	return count

func _assert_true(value: bool, message: String) -> void:
	if value:
		return
	_failed = true
	printerr("Assertion failed: %s" % message)

func _assert_equal(actual: Variant, expected: Variant, message: String) -> void:
	if actual == expected:
		return
	_failed = true
	printerr("Assertion failed: %s Expected '%s', got '%s'." % [message, expected, actual])

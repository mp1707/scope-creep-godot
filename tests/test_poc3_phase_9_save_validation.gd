extends SceneTree

const SAVE_PATH: String = "user://scope_creep_poc3_phase_9_test.json"
const PRODUCT_STAGE_VALUE: String = "product_stage"
const PRODUCT_STAGE_LIVE: String = "live"
const FEATURE_COUNT_VALUE: String = "feature_count"
const MVP_REQUIRED_FEATURES_VALUE: String = "mvp_required_features"
const LAUNCH_FEATURE_COUNT_VALUE: String = "launch_feature_count"

var _failed: bool = false

func _init() -> void:
	_test_new_runs_use_poc3_content_version()
	_test_save_load_keeps_pre_launch_software_state()
	_test_save_load_keeps_post_launch_goal_and_customer_pressure()
	_test_old_poc2_saves_fail_with_clear_error()
	_test_content_validator_accepts_poc3_content()

	if _failed:
		quit(1)
		return

	print("PoC3 phase 9 save/validation tests passed.")
	quit(0)

func _test_new_runs_use_poc3_content_version() -> void:
	var controller: RunController = _create_controller(3901)
	var state: RunState = controller.start_new_run(3901)

	_assert_equal(state.content_version, "poc3", "New runs should stamp the PoC3 content version.")

func _test_save_load_keeps_pre_launch_software_state() -> void:
	var controller: RunController = _create_controller(3902)
	var state: RunState = controller.start_new_run(3902)
	var software: CardInstance = controller.get_software_card()
	software.values[FEATURE_COUNT_VALUE] = 10
	software.values[MVP_REQUIRED_FEATURES_VALUE] = 10
	software.values[LAUNCH_FEATURE_COUNT_VALUE] = 0
	controller.set_paused(true)

	_assert_true(controller.save_current_run(SAVE_PATH), "Paused PoC3 pre-launch run should save.")

	var loaded_controller: RunController = _create_controller(3903)
	_assert_true(loaded_controller.load_run_from_file(SAVE_PATH), "PoC3 pre-launch save should load.")
	var loaded_software: CardInstance = loaded_controller.get_software_card()

	_assert_true(loaded_controller.state.is_paused, "Loaded sprint run should stay frozen.")
	_assert_equal(loaded_controller.state.content_version, "poc3", "Loaded run should keep PoC3 content version.")
	_assert_equal(loaded_software.values[FEATURE_COUNT_VALUE], 10, "Software feature count should survive save/load.")
	_assert_equal(loaded_software.values[MVP_REQUIRED_FEATURES_VALUE], 10, "Software MVP threshold should survive save/load.")
	_assert_equal(loaded_software.values[LAUNCH_FEATURE_COUNT_VALUE], 0, "Pre-launch launch feature count should survive save/load.")

func _test_save_load_keeps_post_launch_goal_and_customer_pressure() -> void:
	var controller: RunController = _create_controller(3904)
	var state: RunState = controller.start_new_run(3904)
	var software: CardInstance = controller.get_software_card()
	software.values[PRODUCT_STAGE_VALUE] = PRODUCT_STAGE_LIVE
	software.values[FEATURE_COUNT_VALUE] = 12
	software.values[LAUNCH_FEATURE_COUNT_VALUE] = 10
	var customer: CardInstance = _spawn_card(controller, "card.value_source.customer", Vector2(860.0, 360.0))
	var request: CardInstance = _spawn_card(controller, "card.input.customer_request", Vector2(1040.0, 360.0))
	var unhappy: CardInstance = controller.call("_spawn_attached_card", customer.instance_id, "card.problem.unhappy_customer", "unhappy_customer") as CardInstance
	var goal: CardInstance = _spawn_card(controller, "card.goal.business_goal", Vector2(1220.0, 360.0))
	request.values["spawned_sprint_index"] = 3
	goal.values["goal_index"] = 2
	goal.values["required_money"] = 5
	goal.values["paid_money"] = 2
	goal.state.markers = PackedStringArray(["G2"])
	state.completed_business_goal_count = 1
	controller.set_paused(true)

	_assert_true(controller.save_current_run(SAVE_PATH), "Paused PoC3 post-launch run should save.")

	var loaded_controller: RunController = _create_controller(3905)
	_assert_true(loaded_controller.load_run_from_file(SAVE_PATH), "PoC3 post-launch save should load.")
	var loaded_state: RunState = loaded_controller.state
	var loaded_software: CardInstance = loaded_controller.get_software_card()
	var loaded_request: CardInstance = loaded_state.get_card(request.instance_id)
	var loaded_unhappy: CardInstance = loaded_state.get_card(unhappy.instance_id)
	var loaded_goal: CardInstance = loaded_state.get_card(goal.instance_id)

	_assert_equal(loaded_software.values[PRODUCT_STAGE_VALUE], PRODUCT_STAGE_LIVE, "Live software stage should survive save/load.")
	_assert_equal(loaded_software.values[FEATURE_COUNT_VALUE], 12, "Live feature count should survive save/load.")
	_assert_equal(loaded_software.values[LAUNCH_FEATURE_COUNT_VALUE], 10, "Launch feature count should survive save/load.")
	_assert_equal(loaded_request.values["spawned_sprint_index"], 3, "Customer request sprint marker should survive save/load.")
	_assert_equal(loaded_unhappy.parent_card_id, customer.instance_id, "Unhappy attachment parent should survive save/load.")
	_assert_equal(loaded_unhappy.attachment_slot, "unhappy_customer", "Unhappy attachment slot should survive save/load.")
	_assert_equal(int(loaded_goal.values["goal_index"]), 2, "Business goal index should survive save/load.")
	_assert_equal(int(loaded_goal.values["required_money"]), 5, "Business goal requirement should survive save/load.")
	_assert_equal(int(loaded_goal.values["paid_money"]), 2, "Business goal payment progress should survive save/load.")
	_assert_equal(loaded_state.completed_business_goal_count, 1, "Completed business goal count should survive save/load.")

func _test_old_poc2_saves_fail_with_clear_error() -> void:
	var controller: RunController = _create_controller(3906)
	var state: RunState = controller.start_new_run(3906)
	state.content_version = "poc2"
	controller.set_paused(true)
	var serializer: RunSaveSerializer = RunSaveSerializer.new()
	var data: Dictionary = serializer.serialize_run(state)
	var loaded: RunState = serializer.deserialize_run(data, controller.content)

	_assert_true(loaded == null, "PoC2 saves should not load silently in the PoC3 build.")
	_assert_true(serializer.errors.size() == 1 and serializer.errors[0].contains("Unsupported save content version"), "PoC2 save rejection should explain the content-version mismatch.")

func _test_content_validator_accepts_poc3_content() -> void:
	var validator: ContentValidator = ContentValidator.new()
	var errors: PackedStringArray = validator.validate_content()
	for error: String in errors:
		printerr(error)
	_assert_equal(errors.size(), 0, "PoC3 content validation should pass.")

func _create_controller(run_seed: int) -> RunController:
	var catalog: ContentCatalog = ContentCatalog.new()
	_assert_true(catalog.load_default_content(), "Default content should load.")
	catalog.balance = catalog.balance.duplicate(true) as BalanceDefinition
	catalog.balance.bug_chance = 0.0
	catalog.balance.tech_debt_chance = 0.0
	catalog.balance.burnout_increment_per_completed_work = 0.0
	return RunController.new(catalog)

func _spawn_card(controller: RunController, definition_id: String, position: Vector2) -> CardInstance:
	return controller.call("_spawn_card_as_new_stack", definition_id, position) as CardInstance

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

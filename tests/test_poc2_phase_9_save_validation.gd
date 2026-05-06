extends SceneTree

const SAVE_PATH: String = "user://scope_creep_poc2_phase_9_test.json"
const PAYMENT_SAVE_PATH: String = "user://scope_creep_poc2_phase_9_payment_test.json"

var _failed: bool = false

func _init() -> void:
	_test_new_runs_use_poc2_content_version()
	_test_save_load_keeps_poc2_runtime_state()
	_test_save_is_allowed_only_when_frozen()
	_test_content_validator_accepts_poc2_content()

	if _failed:
		quit(1)
		return

	print("PoC2 phase 9 save/validation tests passed.")
	quit(0)

func _test_new_runs_use_poc2_content_version() -> void:
	var controller: RunController = _create_controller(901)
	var state: RunState = controller.start_new_run(901)
	_assert_equal(state.content_version, "poc2", "New runs should stamp the PoC2 content version.")

func _test_save_load_keeps_poc2_runtime_state() -> void:
	var controller: RunController = _create_controller(902)
	var state: RunState = controller.start_new_run(902)
	var developer: CardInstance = _find_card_by_definition(state, "card.employee.developer")
	var burnout: CardInstance = controller.call("_spawn_attached_card", developer.instance_id, "card.problem.burnout", "burnout") as CardInstance
	var feature: CardInstance = _spawn_card(controller, "card.output.feature", Vector2(980.0, 320.0))
	var external_dev: CardInstance = _spawn_card(controller, "card.employee.external_dev", Vector2(1160.0, 320.0))
	var order: CardInstance = _spawn_card(controller, "card.value_source.order", Vector2(1340.0, 320.0))
	_spawn_card(controller, "card.value_source.customer", Vector2(980.0, 560.0))
	_spawn_card(controller, "card.value_source.coffee_machine", Vector2(1160.0, 560.0))
	var pack: CardInstance = _spawn_card(controller, "card.resource.booster_pack", Vector2(1340.0, 560.0))

	feature.values["feature_value"] = 3
	feature.values["is_checked"] = true
	feature.values["source_quality"] = "checked"
	external_dev.values["completed_task"] = true
	pack.values["booster_definition_id"] = "booster.office_invest"
	_assert_true(controller.open_booster_pack_step(pack.instance_id), "Booster pack should open once before saving.")
	controller.advance_time(4.0)
	controller.set_paused(true)

	var recovery_stack: StackState = state.get_stack(developer.stack_id)
	var rng_before_save: int = state.rng_state
	var remaining_before: PackedStringArray = _variant_to_packed_string_array(pack.values["booster_remaining_card_ids"])
	_assert_true(controller.save_current_run(SAVE_PATH), "Paused PoC2 run should save.")

	var loaded_controller: RunController = _create_controller(903)
	_assert_true(loaded_controller.load_run_from_file(SAVE_PATH), "PoC2 save should load.")
	var loaded_state: RunState = loaded_controller.state
	var loaded_feature: CardInstance = loaded_state.get_card(feature.instance_id)
	var loaded_burnout: CardInstance = loaded_state.get_card(burnout.instance_id)
	var loaded_external_dev: CardInstance = loaded_state.get_card(external_dev.instance_id)
	var loaded_order: CardInstance = loaded_state.get_card(order.instance_id)
	var loaded_pack: CardInstance = loaded_state.get_card(pack.instance_id)
	var loaded_recovery_stack: StackState = loaded_state.get_stack(recovery_stack.stack_id)

	_assert_true(loaded_state.is_paused, "Loaded sprint run should be frozen.")
	_assert_equal(loaded_state.content_version, "poc2", "Loaded run should keep content version.")
	_assert_equal(loaded_feature.values["feature_value"], 3, "Feature value should survive save/load.")
	_assert_equal(loaded_feature.values["is_checked"], true, "Checked feature state should survive save/load.")
	_assert_equal(loaded_feature.values["source_quality"], "checked", "Source quality should survive save/load.")
	_assert_equal(loaded_burnout.parent_card_id, developer.instance_id, "Burnout parent should survive save/load.")
	_assert_equal(loaded_burnout.attachment_slot, "burnout", "Burnout attachment slot should survive save/load.")
	_assert_equal(loaded_recovery_stack.processing_state.active_recipe_id, "recipe.burnout_recovery.employee", "Active burnout recovery should survive save/load.")
	_assert_equal(loaded_recovery_stack.processing_state.elapsed, 4.0, "Processing elapsed time should survive save/load.")
	_assert_equal(loaded_external_dev.values["completed_task"], true, "External dev lifecycle value should survive save/load.")
	_assert_equal(loaded_order.created_at_sprint, order.created_at_sprint, "Order lifecycle sprint should survive save/load.")
	_assert_equal(_variant_to_packed_string_array(loaded_pack.values["booster_remaining_card_ids"]), remaining_before, "Booster remaining draws should survive save/load.")
	_assert_equal(loaded_state.rng_state, rng_before_save, "RNG state should survive save/load.")

func _test_save_is_allowed_only_when_frozen() -> void:
	var controller: RunController = _create_controller(904)
	controller.content.balance.sprint_duration_seconds = 1.0
	var state: RunState = controller.start_new_run(904)

	_assert_true(not controller.save_current_run(SAVE_PATH), "Unpaused sprint run should not save.")
	controller.set_paused(true)
	_assert_true(controller.save_current_run(SAVE_PATH), "Paused sprint run should save.")
	controller.set_paused(false)
	controller.advance_time(1.0)
	_assert_equal(state.phase, ScopeEnums.RunPhase.PAYMENT, "Test run should enter payment phase.")
	_assert_true(controller.save_current_run(PAYMENT_SAVE_PATH), "Payment phase run should save.")

func _test_content_validator_accepts_poc2_content() -> void:
	var validator: ContentValidator = ContentValidator.new()
	var errors: PackedStringArray = validator.validate_content()
	for error: String in errors:
		printerr(error)
	_assert_equal(errors.size(), 0, "PoC2 content validation should pass.")

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

func _variant_to_packed_string_array(value: Variant) -> PackedStringArray:
	if value is PackedStringArray:
		return value as PackedStringArray
	var result: PackedStringArray = PackedStringArray()
	if value is Array:
		for item: Variant in value as Array:
			result.append(str(item))
	return result

func _find_card_by_definition(state: RunState, definition_id: String) -> CardInstance:
	for card: CardInstance in state.cards.values():
		if card.definition_id == definition_id:
			return card
	_assert_true(false, "Missing card with definition '%s'." % definition_id)
	return null

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

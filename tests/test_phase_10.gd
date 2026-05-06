extends SceneTree

const SAVE_PATH: String = "user://scope_creep_phase_10_test.json"

var _failed: bool = false

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_save_is_only_allowed_when_frozen()
	_test_save_load_restores_run_state()
	_test_loaded_run_keeps_rng_deterministic_and_runtime_ids_unique()
	await _test_dev_buttons_do_not_keep_keyboard_focus()
	await _test_presentation_rebuilds_board_view_after_load()

	if _failed:
		quit(1)
		return

	print("Phase 10 tests passed.")
	quit(0)

func _test_save_is_only_allowed_when_frozen() -> void:
	var controller: RunController = _create_controller(60.0)
	var state: RunState = controller.start_new_run(10)

	_assert_true(not controller.can_save_current_run(), "Running sprint should not be saveable.")
	_assert_true(not controller.save_current_run(SAVE_PATH), "Save should fail during an unpaused sprint.")

	controller.set_paused(true)
	_assert_true(controller.can_save_current_run(), "Paused sprint should be saveable.")
	_assert_true(controller.save_current_run(SAVE_PATH), "Save should succeed during pause.")

	controller.set_paused(false)
	controller.advance_time(60.0)
	_assert_equal(state.phase, ScopeEnums.RunPhase.PAYMENT, "Sprint should enter payment.")
	_assert_true(controller.can_save_current_run(), "Payment phase should be saveable because processing is frozen.")
	_assert_true(controller.save_current_run(SAVE_PATH), "Save should succeed during payment.")

func _test_save_load_restores_run_state() -> void:
	var controller: RunController = _create_controller(60.0)
	var state: RunState = controller.start_new_run(31)
	var developer: CardInstance = _find_card_by_definition(state, "card.employee.developer")
	var idea: CardInstance = _find_card_by_definition(state, "card.input.idea")

	controller.move_card_to_stack(idea.instance_id, developer.stack_id)
	controller.advance_time(3.0)
	var stack_before: StackState = state.get_stack(developer.stack_id)
	var bug_attachment: CardInstance = _spawn_card(controller, "card.problem.bug", Vector2(1300.0, 360.0))
	bug_attachment.parent_card_id = developer.instance_id
	bug_attachment.attachment_slot = "problem"
	bug_attachment.values["target_employee_id"] = developer.instance_id
	controller.set_paused(true)

	var timer_before: float = state.active_timers[RunController.SPRINT_TIMER_ID] as float
	var rng_before: int = state.rng_state
	_assert_true(controller.save_current_run(SAVE_PATH), "Paused run should save.")

	var loaded_controller: RunController = _create_controller(60.0)
	_assert_true(loaded_controller.load_run_from_file(SAVE_PATH), "Saved run should load.")
	var loaded_state: RunState = loaded_controller.state
	var loaded_developer: CardInstance = loaded_state.get_card(developer.instance_id)
	var loaded_stack: StackState = loaded_state.get_stack(stack_before.stack_id)
	var loaded_attachment: CardInstance = loaded_state.get_card(bug_attachment.instance_id)

	_assert_true(loaded_state.is_paused, "Loaded run should stay paused.")
	_assert_equal(loaded_state.phase, ScopeEnums.RunPhase.SPRINT, "Loaded phase should match the saved sprint phase.")
	_assert_equal(loaded_state.active_timers[RunController.SPRINT_TIMER_ID], timer_before, "Loaded sprint timer should preserve remaining time.")
	_assert_equal(loaded_state.rng_state, rng_before, "Loaded run should preserve RNG state.")
	_assert_true(loaded_developer != null, "Loaded run should contain the developer by original instance id.")
	_assert_equal(loaded_stack.card_ids, stack_before.card_ids, "Loaded stack should preserve card order.")
	_assert_equal(loaded_stack.processing_state.active_recipe_id, "recipe.feature_from_idea.developer", "Loaded processing should preserve active recipe.")
	_assert_equal(loaded_stack.processing_state.elapsed, 3.0, "Loaded processing should preserve elapsed progress.")
	_assert_equal(loaded_stack.processing_state.duration, stack_before.processing_state.duration, "Loaded processing should preserve duration.")
	_assert_equal(loaded_attachment.parent_card_id, developer.instance_id, "Loaded attachment should preserve parent card id.")
	_assert_equal(loaded_attachment.attachment_slot, "problem", "Loaded attachment should preserve attachment slot.")
	_assert_equal(loaded_attachment.values["target_employee_id"], developer.instance_id, "Loaded card values should preserve attachment target data.")

func _test_loaded_run_keeps_rng_deterministic_and_runtime_ids_unique() -> void:
	var controller: RunController = _create_controller(60.0)
	var state: RunState = controller.start_new_run(44)
	var booster_slot: CardInstance = _find_card_by_definition(state, "card.shop.booster_slot")
	var buy_money: CardInstance = _find_card_by_definition(state, "card.resource.money")

	controller.move_card_to_stack(buy_money.instance_id, booster_slot.stack_id)
	controller.advance_time(1.0)
	controller.set_paused(true)
	_assert_true(controller.save_current_run(SAVE_PATH), "Run before booster opening should save.")

	var first_loaded: RunController = _create_controller(60.0)
	var second_loaded: RunController = _create_controller(60.0)
	_assert_true(first_loaded.load_run_from_file(SAVE_PATH), "First loaded run should load.")
	_assert_true(second_loaded.load_run_from_file(SAVE_PATH), "Second loaded run should load.")

	var first_result: Dictionary = _open_existing_booster_and_get_result(first_loaded)
	var second_result: Dictionary = _open_existing_booster_and_get_result(second_loaded)

	_assert_equal(first_result["drawn_definitions"], second_result["drawn_definitions"], "Loaded runs with the same RNG state should draw the same booster cards.")
	_assert_equal(first_result["rng_state"], second_result["rng_state"], "Loaded runs should end with the same RNG state after identical draws.")
	_assert_true((first_result["new_card_ids"] as Array[String]).has("card_0014"), "Loaded controller should continue card ids after the saved cards.")

func _test_presentation_rebuilds_board_view_after_load() -> void:
	var controller: RunController = _create_controller(60.0)
	var state: RunState = controller.start_new_run(55)
	var board_view: BoardView = BoardView.new()
	board_view.card_view_scene = ResourceLoader.load("res://scenes/presentation/CardView.tscn") as PackedScene
	get_root().add_child(board_view)
	await process_frame

	var developer: CardInstance = _find_card_by_definition(state, "card.employee.developer")
	var idea: CardInstance = _find_card_by_definition(state, "card.input.idea")
	board_view.bind_run(state, controller.content)
	controller.move_card_to_stack(idea.instance_id, developer.stack_id)
	controller.set_paused(true)
	_assert_true(controller.save_current_run(SAVE_PATH), "Paused run should save before presentation rebuild.")

	var saved_stack_id: String = developer.stack_id
	var loaded_controller: RunController = _create_controller(60.0)
	_assert_true(loaded_controller.load_run_from_file(SAVE_PATH), "Saved run should load for presentation rebuild.")
	board_view.bind_run(loaded_controller.state, loaded_controller.content)
	await process_frame

	var loaded_stack: StackState = loaded_controller.state.get_stack(saved_stack_id)
	var idea_view: CardView = board_view.get_card_view(idea.instance_id)
	_assert_true(loaded_stack != null and loaded_stack.card_ids.has(idea.instance_id), "Loaded run should restore the saved stack.")
	_assert_true(idea_view != null, "BoardView should rebuild CardViews from the loaded RunState.")

	board_view.queue_free()
	await process_frame
	await process_frame

func _test_dev_buttons_do_not_keep_keyboard_focus() -> void:
	var scene: PackedScene = ResourceLoader.load("res://scenes/application/Main.tscn") as PackedScene
	var app: MainApplication = scene.instantiate() as MainApplication
	get_root().add_child(app)
	await process_frame

	var layer: CanvasLayer = app.get_node("Camera2D/CanvasLayer") as CanvasLayer
	var auto_pay_button: Button = layer.get_node("AutoPayButton") as Button
	var next_sprint_button: Button = layer.get_node("NextSprintButton") as Button
	var save_button: Button = layer.get_node("SaveButton") as Button
	var load_button: Button = layer.get_node("LoadButton") as Button

	_assert_equal(auto_pay_button.focus_mode, Control.FOCUS_NONE, "Auto-Pay button should not capture Space focus.")
	_assert_equal(next_sprint_button.focus_mode, Control.FOCUS_NONE, "Next sprint button should not capture Space focus.")
	_assert_equal(save_button.focus_mode, Control.FOCUS_NONE, "Save button should not capture Space focus.")
	_assert_equal(load_button.focus_mode, Control.FOCUS_NONE, "Load button should not capture Space focus.")

	app.queue_free()
	await process_frame
	await process_frame

func _open_existing_booster_and_get_result(controller: RunController) -> Dictionary:
	var state: RunState = controller.state
	var booster_pack: CardInstance = _find_card_by_definition(state, "card.resource.booster_pack")
	var existing_card_ids: Dictionary = {}
	for card_id: String in state.cards.keys():
		existing_card_ids[card_id] = true

	controller.open_booster_pack_step(booster_pack.instance_id)
	controller.open_booster_pack_step(booster_pack.instance_id)
	controller.open_booster_pack_step(booster_pack.instance_id)

	var new_card_ids: Array[String] = []
	for card_id: String in state.cards.keys():
		if not existing_card_ids.has(card_id):
			new_card_ids.append(card_id)
	new_card_ids.sort()

	var drawn_definitions: Array[String] = []
	for card_id: String in new_card_ids:
		var card: CardInstance = state.get_card(card_id)
		if card != null:
			drawn_definitions.append(card.definition_id)

	return {
		"drawn_definitions": drawn_definitions,
		"rng_state": state.rng_state,
		"new_card_ids": new_card_ids,
	}

func _create_controller(sprint_duration: float) -> RunController:
	var catalog: ContentCatalog = ContentCatalog.new()
	_assert_true(catalog.load_default_content(), "Default content should load.")
	catalog.balance = catalog.balance.duplicate(true) as BalanceDefinition
	catalog.balance.sprint_duration_seconds = sprint_duration
	return RunController.new(catalog)

func _spawn_card(controller: RunController, definition_id: String, position: Vector2) -> CardInstance:
	return controller.call("_spawn_card_as_new_stack", definition_id, position) as CardInstance

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

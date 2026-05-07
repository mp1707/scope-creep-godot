extends SceneTree

var _failed: bool = false

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_sprint_timer_pause_and_payment_freeze()
	_test_payment_allows_mixed_stack_reorganization()
	_test_manual_payment_consumes_one_money_and_marks_employee()
	_test_auto_pay_consumes_money_from_employee_stack_first()
	_test_auto_pay_fails_without_money()
	_test_application_auto_pay_without_money_does_not_prevent_quit()
	_test_application_second_auto_pay_without_money_does_not_prevent_quit()
	_test_application_hud_uses_static_viewport_layer()
	_test_application_hud_can_be_disabled()
	_test_auto_pay_button_is_disabled_without_money()
	_test_auto_pay_fails_when_no_employee_needs_payment()
	_test_start_next_sprint_resets_timer_and_keeps_paid_employee()
	_test_unpaid_employee_quits_on_next_sprint_start()

	if _failed:
		quit(1)
		return

	print("Phase 7 tests passed.")
	quit(0)

func _test_sprint_timer_pause_and_payment_freeze() -> void:
	var controller: RunController = _create_controller(3.0)
	var state: RunState = controller.start_new_run(1)
	var developer: CardInstance = _find_card_by_definition(state, "card.employee.developer")
	var idea: CardInstance = _find_card_by_definition(state, "card.input.idea")

	controller.move_card_to_stack(idea.instance_id, developer.stack_id)
	controller.advance_time(1.0)
	var stack: StackState = state.get_stack(developer.stack_id)
	_assert_equal(stack.processing_state.elapsed, 1.0, "Processing should advance during sprint.")

	controller.set_paused(true)
	controller.advance_time(5.0)
	_assert_equal(state.active_timers[RunController.SPRINT_TIMER_ID], 2.0, "Pause should freeze sprint timer.")
	_assert_equal(stack.processing_state.elapsed, 1.0, "Pause should freeze processing timers.")

	controller.set_paused(false)
	controller.advance_time(5.0)
	_assert_equal(state.phase, ScopeEnums.RunPhase.PAYMENT, "Sprint timer should switch to payment when it expires.")
	_assert_equal(state.active_timers[RunController.SPRINT_TIMER_ID], 0.0, "Expired sprint timer should clamp to zero.")
	_assert_equal(stack.processing_state.elapsed, 3.0, "Processing should only advance until sprint expiry, not through payment.")

	controller.advance_time(10.0)
	_assert_equal(stack.processing_state.elapsed, 3.0, "Payment phase should freeze processing.")

func _test_payment_allows_mixed_stack_reorganization() -> void:
	var controller: RunController = _create_controller(1.0)
	var state: RunState = controller.start_new_run(1)
	var coffee: CardInstance = _find_card_by_definition(state, "card.consumable.coffee")
	var money: CardInstance = _find_card_by_definition(state, "card.resource.money")
	var developer: CardInstance = _find_card_by_definition(state, "card.employee.developer")

	controller.advance_time(1.0)
	_assert_false(coffee.state.is_locked, "Payment should keep non-payment cards movable for stack cleanup.")
	_assert_false(money.state.is_locked, "Payment should keep money movable.")
	_assert_false(developer.state.is_locked, "Payment should keep employees movable.")
	_assert_true(developer.state.is_payment_target, "Unpaid employees should be marked as payment targets.")

	var money_stack_id: String = money.stack_id
	controller.move_card_to_stack(coffee.instance_id, money_stack_id)
	_assert_equal(coffee.stack_id, money_stack_id, "Payment should allow mixed cards to be stacked for organization.")

	var split_stack: StackState = controller.split_stack_from_card(coffee.instance_id, Vector2(900.0, 100.0))
	_assert_true(split_stack != null, "Payment should allow mixed stacks to be split again.")
	_assert_equal(coffee.stack_id, split_stack.stack_id, "Split card should move into the new payment cleanup stack.")

func _test_manual_payment_consumes_one_money_and_marks_employee() -> void:
	var controller: RunController = _create_controller(1.0)
	var state: RunState = controller.start_new_run(1)
	var developer: CardInstance = _find_card_by_definition(state, "card.employee.developer")
	var money: CardInstance = _find_card_by_definition(state, "card.resource.money")
	var money_before: int = _count_cards_by_definition(state, "card.resource.money")

	controller.advance_time(1.0)
	controller.move_card_to_stack(money.instance_id, developer.stack_id)

	_assert_equal(_count_cards_by_definition(state, "card.resource.money"), money_before - 1, "Manual pay should consume exactly one money card.")
	_assert_true(state.paid_employee_ids.has(developer.instance_id), "Manual pay should remember the paid employee.")
	_assert_true(developer.state.is_paid, "Manual pay should mark the employee as paid.")
	_assert_false(developer.state.is_payment_target, "Paid employees should no longer be payment targets.")

func _test_auto_pay_consumes_money_from_employee_stack_first() -> void:
	var controller: RunController = _create_controller(1.0)
	var state: RunState = controller.start_new_run(1)
	var developer: CardInstance = _find_card_by_definition(state, "card.employee.developer")
	var money: CardInstance = _find_card_by_definition(state, "card.resource.money")
	var stacked_money_id: String = money.instance_id
	var money_before: int = _count_cards_by_definition(state, "card.resource.money")

	controller.move_card_to_stack(money.instance_id, developer.stack_id)
	controller.advance_time(1.0)
	var paid: bool = controller.auto_pay_all_employees()

	_assert_true(paid, "Auto-pay should succeed when enough money exists.")
	_assert_true(state.paid_employee_ids.has(developer.instance_id), "Auto-pay should mark the employee as paid.")
	_assert_equal(_count_cards_by_definition(state, "card.resource.money"), money_before - 1, "Auto-pay should consume exactly one money card.")
	_assert_true(state.get_card(stacked_money_id) == null, "Auto-pay should consume money already stacked with the employee first.")

func _test_auto_pay_fails_without_money() -> void:
	var controller: RunController = _create_controller(1.0)
	var state: RunState = controller.start_new_run(1)
	var developer: CardInstance = _find_card_by_definition(state, "card.employee.developer")
	var money_ids: PackedStringArray = _find_card_ids_by_definition(state, "card.resource.money")
	for money_id: String in money_ids:
		controller.call("_remove_card_instance", money_id)

	controller.advance_time(1.0)
	var paid: bool = controller.auto_pay_all_employees()

	_assert_false(paid, "Auto-pay should fail when no money cards exist.")
	_assert_false(state.paid_employee_ids.has(developer.instance_id), "Auto-pay without money must not mark the employee as paid.")
	_assert_false(developer.state.is_paid, "Auto-pay without money must not set the paid marker.")
	_assert_true(developer.state.is_payment_target, "Unpaid employee should remain a payment target.")

func _test_application_auto_pay_without_money_does_not_prevent_quit() -> void:
	var app: Node = _create_app()
	var state: RunState = app.run_state
	var controller: RunController = app.controller
	var developer: CardInstance = _find_card_by_definition(state, "card.employee.developer")
	var money_ids: PackedStringArray = _find_card_ids_by_definition(state, "card.resource.money")
	for money_id: String in money_ids:
		controller.call("_remove_card_instance", money_id)
	app.call("_apply_pending_events")

	app.call("advance_run", 60.0)
	app.call("request_auto_pay")
	app.call("request_start_next_sprint")

	_assert_true(state.get_card(developer.instance_id) == null, "Application auto-pay without money must not prevent unpaid employee quit.")
	_assert_equal(state.phase, ScopeEnums.RunPhase.GAME_OVER, "Application should reach game over when the only employee cannot be paid.")
	app.queue_free()

func _test_application_second_auto_pay_without_money_does_not_prevent_quit() -> void:
	var app: Node = _create_app()
	var state: RunState = app.run_state
	var developer: CardInstance = _find_card_by_definition(state, "card.employee.developer")
	_keep_only_one_money_card(app)

	app.call("advance_run", 60.0)
	app.call("request_auto_pay")
	_assert_true(state.paid_employee_ids.has(developer.instance_id), "First auto-pay should pay the developer with the only money card.")
	_assert_equal(_count_cards_by_definition(state, "card.resource.money"), 0, "First auto-pay should consume the only money card.")
	app.call("request_start_next_sprint")

	_assert_equal(state.phase, ScopeEnums.RunPhase.SPRINT, "Paid developer should start sprint 2.")
	_assert_false(state.paid_employee_ids.has(developer.instance_id), "Paid employee ids must reset at sprint start.")
	_assert_false(developer.state.is_paid, "Paid marker must clear at sprint 2 start.")

	app.call("advance_run", 60.0)
	app.call("request_auto_pay")
	_assert_false(state.paid_employee_ids.has(developer.instance_id), "Second auto-pay without money must not mark developer paid.")
	_assert_false(developer.state.is_paid, "Second auto-pay without money must not set paid marker.")
	app.call("request_start_next_sprint")

	_assert_true(state.get_card(developer.instance_id) == null, "Developer should quit after unpaid sprint 2.")
	_assert_equal(state.phase, ScopeEnums.RunPhase.GAME_OVER, "Run should end when developer cannot be paid in sprint 2.")
	app.queue_free()

func _test_auto_pay_button_is_disabled_without_money() -> void:
	var app: Node = _create_app()
	var state: RunState = app.run_state
	var developer: CardInstance = _find_card_by_definition(state, "card.employee.developer")
	_keep_only_one_money_card(app)

	app.call("advance_run", 60.0)
	app.call("request_auto_pay")
	app.call("request_start_next_sprint")
	app.call("advance_run", 60.0)

	var auto_pay_button: Button = app.get_node("UiLayer/Hud/StatusPanel/ButtonRow/AutoPayButton") as Button
	_assert_true(auto_pay_button.disabled, "Auto-pay button should be disabled in payment when no money exists.")
	auto_pay_button.pressed.emit()
	_assert_false(state.paid_employee_ids.has(developer.instance_id), "Disabled auto-pay button path must not mark developer paid.")
	_assert_false(developer.state.is_paid, "Disabled auto-pay button path must not set paid marker.")
	app.queue_free()

func _test_application_hud_uses_static_viewport_layer() -> void:
	var app: Node = _create_app()
	var ui_layer: CanvasLayer = app.get_node("UiLayer") as CanvasLayer
	var hud: Control = app.get_node("UiLayer/Hud") as Control
	var status_panel: Panel = hud.get_node("StatusPanel") as Panel
	var status_label: Label = hud.get_node("StatusPanel/StatusLabel") as Label
	var auto_pay_button: Button = hud.get_node("StatusPanel/ButtonRow/AutoPayButton") as Button

	_assert_true(ui_layer.get_parent() == app, "Application HUD should live in a viewport-static CanvasLayer under Main.")
	_assert_true(hud != null, "Application HUD should be an editable Hud scene instance.")
	_assert_equal(status_panel.position, Vector2(116.0, 116.0), "Application HUD should keep a stable layout anchor.")
	_assert_equal(status_label.get_theme_color("font_color"), Color(0.055, 0.052, 0.047, 1.0), "HUD text should be dark on the offwhite board.")
	_assert_equal(auto_pay_button.focus_mode, Control.FOCUS_NONE, "HUD buttons should not capture Space focus.")
	app.queue_free()

func _test_application_hud_can_be_disabled() -> void:
	var scene: PackedScene = ResourceLoader.load("res://scenes/application/Main.tscn") as PackedScene
	var app: MainApplication = scene.instantiate() as MainApplication
	app.show_hud = false
	get_root().add_child(app)

	var hud: Control = app.get_node("UiLayer/Hud") as Control
	_assert_true(not hud.visible, "Disabled HUD should keep the editable scene instance but hide it.")
	app.queue_free()

func _test_auto_pay_fails_when_no_employee_needs_payment() -> void:
	var controller: RunController = _create_controller(1.0)
	var state: RunState = controller.start_new_run(1)
	var developer: CardInstance = _find_card_by_definition(state, "card.employee.developer")
	var money: CardInstance = _find_card_by_definition(state, "card.resource.money")

	controller.advance_time(1.0)
	controller.move_card_to_stack(money.instance_id, developer.stack_id)
	var paid_again: bool = controller.auto_pay_all_employees()

	_assert_false(paid_again, "Auto-pay should be disabled once all employees are already paid.")
	_assert_true(state.paid_employee_ids.has(developer.instance_id), "Already paid employee should stay paid.")

func _test_start_next_sprint_resets_timer_and_keeps_paid_employee() -> void:
	var controller: RunController = _create_controller(3.0)
	var state: RunState = controller.start_new_run(1)
	var developer: CardInstance = _find_card_by_definition(state, "card.employee.developer")
	var idea: CardInstance = _find_card_by_definition(state, "card.input.idea")
	var money: CardInstance = _find_card_by_definition(state, "card.resource.money")

	controller.move_card_to_stack(idea.instance_id, developer.stack_id)
	controller.advance_time(3.0)
	controller.move_card_to_stack(money.instance_id, developer.stack_id)
	controller.start_next_sprint()

	var stack: StackState = state.get_stack(developer.stack_id)
	_assert_equal(state.phase, ScopeEnums.RunPhase.SPRINT, "Paid run should return to sprint phase.")
	_assert_equal(state.sprint_index, 2, "Starting the next sprint should increment the sprint index.")
	_assert_equal(state.active_timers[RunController.SPRINT_TIMER_ID], 3.0, "Next sprint should reset the sprint timer.")
	_assert_false(developer.state.is_paid, "Payment markers should clear at the start of the next sprint.")
	_assert_equal(stack.processing_state.elapsed, 3.0, "Running processing should carry over into the next sprint.")

	controller.advance_time(1.0)
	_assert_equal(stack.processing_state.elapsed, 4.0, "Carried processing should continue in the next sprint.")

func _test_unpaid_employee_quits_on_next_sprint_start() -> void:
	var controller: RunController = _create_controller(1.0)
	var state: RunState = controller.start_new_run(1)
	var developer: CardInstance = _find_card_by_definition(state, "card.employee.developer")

	controller.advance_time(1.0)
	controller.start_next_sprint()

	_assert_true(state.get_card(developer.instance_id) == null, "Unpaid employees should quit on next sprint start.")
	_assert_equal(state.phase, ScopeEnums.RunPhase.GAME_OVER, "Losing the last employee should immediately end the run.")

func _create_controller(sprint_duration: float) -> RunController:
	var catalog: ContentCatalog = ContentCatalog.new()
	_assert_true(catalog.load_default_content(), "Default content should load.")
	catalog.balance = catalog.balance.duplicate(true) as BalanceDefinition
	catalog.balance.sprint_duration_seconds = sprint_duration
	return RunController.new(catalog)

func _create_app() -> Node:
	var scene: PackedScene = ResourceLoader.load("res://scenes/application/Main.tscn") as PackedScene
	var app: Node = scene.instantiate()
	get_root().add_child(app)
	return app

func _keep_only_one_money_card(app: Node) -> void:
	var state: RunState = app.run_state
	var controller: RunController = app.controller
	var money_ids: PackedStringArray = _find_card_ids_by_definition(state, "card.resource.money")
	for index: int in range(1, money_ids.size()):
		controller.call("_remove_card_instance", money_ids[index])
	app.call("_apply_pending_events")

func _find_card_by_definition(state: RunState, definition_id: String) -> CardInstance:
	for card: CardInstance in state.cards.values():
		if card.definition_id == definition_id:
			return card
	_assert_true(false, "Missing card with definition '%s'." % definition_id)
	return null

func _count_cards_by_definition(state: RunState, definition_id: String) -> int:
	var count: int = 0
	for card: CardInstance in state.cards.values():
		if card.definition_id == definition_id:
			count += 1
	return count

func _find_card_ids_by_definition(state: RunState, definition_id: String) -> PackedStringArray:
	var card_ids: PackedStringArray = PackedStringArray()
	for card: CardInstance in state.cards.values():
		if card.definition_id == definition_id:
			card_ids.append(card.instance_id)
	return card_ids

func _assert_true(value: bool, message: String) -> void:
	if value:
		return
	_failed = true
	printerr("Assertion failed: %s" % message)

func _assert_false(value: bool, message: String) -> void:
	_assert_true(not value, message)

func _assert_equal(actual: Variant, expected: Variant, message: String) -> void:
	if actual == expected:
		return
	_failed = true
	printerr("Assertion failed: %s Expected '%s', got '%s'." % [message, expected, actual])

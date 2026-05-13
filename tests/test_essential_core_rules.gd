extends SceneTree

const SAVE_PATH: String = "user://scope_creep_essential_core_rules_test.json"

var _failed: bool = false

func _init() -> void:
	_test_money_exists_as_single_cards()
	_test_neutral_extra_card_cancels_processing()
	_test_coffee_accelerates_employee_work_only()
	_test_bug_formation_happens_before_duplication()
	_test_save_is_only_allowed_when_frozen_and_restores_state()
	_test_booster_draws_are_deterministic()
	_test_talent_pool_costs_two_money_and_draws_no_regular_employee()
	_test_interview_recipes_are_deterministic_and_recruiter_specific()
	_test_offer_hiring_in_payment_defers_salary_and_attaches_onboarding()
	_test_onboarding_blocks_work_and_accepts_coffee()

	if _failed:
		quit(1)
		return

	print("Essential core rule tests passed.")
	quit(0)

func _test_money_exists_as_single_cards() -> void:
	var controller: RunController = _create_controller(60.0)
	var state: RunState = controller.start_new_run(1001)
	var money_cards: Array[CardInstance] = _find_cards_by_definition(state, "card.resource.money")

	_assert_equal(money_cards.size(), controller.content.balance.poc3_start_money_cards, "Start money should be represented as one card per money.")

func _test_neutral_extra_card_cancels_processing() -> void:
	var controller: RunController = _create_controller(60.0)
	var state: RunState = controller.start_new_run(1002)
	var developer: CardInstance = _find_card_by_definition(state, "card.employee.developer")
	var idea: CardInstance = _find_card_by_definition(state, "card.input.idea")
	var money: CardInstance = _find_card_by_definition(state, "card.resource.money")

	controller.move_card_to_stack(idea.instance_id, developer.stack_id)
	controller.advance_time(2.0)
	controller.move_card_to_stack(money.instance_id, developer.stack_id)

	var stack: StackState = state.get_stack(developer.stack_id)
	_assert_equal(stack.processing_state.active_recipe_id, "", "Neutral extra cards should cancel active processing.")
	_assert_equal(stack.processing_state.status, ScopeEnums.ProcessingStatus.IDLE, "Cancelled processing should return to idle.")
	_assert_equal(stack.processing_state.elapsed, 0.0, "Cancelled processing should reset elapsed time.")

func _test_coffee_accelerates_employee_work_only() -> void:
	var employee_controller: RunController = _create_controller(60.0)
	var employee_state: RunState = employee_controller.start_new_run(1003)
	var developer: CardInstance = _find_card_by_definition(employee_state, "card.employee.developer")
	var idea: CardInstance = _find_card_by_definition(employee_state, "card.input.idea")
	var coffee: CardInstance = _find_card_by_definition(employee_state, "card.consumable.coffee")

	employee_controller.move_card_to_stack(idea.instance_id, developer.stack_id)
	employee_controller.advance_time(1.0)
	employee_controller.move_card_to_stack(coffee.instance_id, developer.stack_id)

	var employee_stack: StackState = employee_state.get_stack(developer.stack_id)
	_assert_equal(employee_stack.processing_state.active_recipe_id, "recipe.feature_from_idea.developer", "Coffee should keep the running employee recipe.")
	_assert_true(employee_stack.processing_state.elapsed > 1.0, "Coffee should add progress to employee work.")
	_assert_equal(_count_cards_by_definition(employee_state, "card.consumable.coffee"), 0, "Applied coffee should be consumed.")

	var object_controller: RunController = _create_controller(60.0)
	var object_state: RunState = object_controller.start_new_run(1004)
	var object_developer: CardInstance = _find_card_by_definition(object_state, "card.employee.developer")
	var object_idea: CardInstance = _find_card_by_definition(object_state, "card.input.idea")
	var object_coffee: CardInstance = _find_card_by_definition(object_state, "card.consumable.coffee")

	object_controller.move_card_to_stack(object_idea.instance_id, object_developer.stack_id)
	object_controller.advance_time(8.0)

	var feature: CardInstance = _find_card_by_definition(object_state, "card.output.feature")
	var software: CardInstance = _find_card_by_definition(object_state, "card.product.software")
	object_controller.move_card_to_stack(feature.instance_id, software.stack_id)
	object_controller.advance_time(1.0)
	object_controller.move_card_to_stack(object_coffee.instance_id, software.stack_id)

	var object_stack: StackState = object_state.get_stack(software.stack_id)
	_assert_equal(object_coffee.stack_id, software.stack_id, "Coffee should move normally onto object work.")
	_assert_equal(object_stack.processing_state.active_recipe_id, "", "Coffee should not accelerate object processing or act as a recipe input.")

func _test_bug_formation_happens_before_duplication() -> void:
	var controller: RunController = _create_controller(1.0)
	var state: RunState = controller.start_new_run(1005)
	for index: int in 4:
		_spawn_card(controller, "card.problem.bug", Vector2(1200.0 + float(index) * 24.0, 300.0))

	_pay_and_start_next_sprint(controller, state)

	_assert_equal(_count_cards_by_definition(state, "card.problem.prod_crash"), 1, "Three existing bugs should form one Prod-Crash first.")
	_assert_equal(_count_cards_by_definition(state, "card.problem.bug"), 2, "Only the remaining fourth bug should duplicate after formation.")

func _test_save_is_only_allowed_when_frozen_and_restores_state() -> void:
	var controller: RunController = _create_controller(60.0)
	var state: RunState = controller.start_new_run(1006)
	var developer: CardInstance = _find_card_by_definition(state, "card.employee.developer")
	var idea: CardInstance = _find_card_by_definition(state, "card.input.idea")

	_assert_true(not controller.can_save_current_run(), "Running sprint should not be saveable.")
	_assert_true(not controller.save_current_run(SAVE_PATH), "Running sprint save should fail.")

	controller.move_card_to_stack(idea.instance_id, developer.stack_id)
	controller.advance_time(3.0)
	controller.set_paused(true)

	var saved_stack_id: String = developer.stack_id
	var saved_timer: float = state.active_timers[RunController.SPRINT_TIMER_ID] as float
	_assert_true(controller.can_save_current_run(), "Paused sprint should be saveable.")
	_assert_true(controller.save_current_run(SAVE_PATH), "Paused sprint save should succeed.")

	var loaded_controller: RunController = _create_controller(60.0)
	_assert_true(loaded_controller.load_run_from_file(SAVE_PATH), "Saved run should load.")
	var loaded_state: RunState = loaded_controller.state
	var loaded_stack: StackState = loaded_state.get_stack(saved_stack_id)

	_assert_true(loaded_state.is_paused, "Loaded run should stay paused.")
	_assert_equal(loaded_state.active_timers[RunController.SPRINT_TIMER_ID], saved_timer, "Loaded run should preserve sprint timer.")
	_assert_equal(loaded_stack.processing_state.active_recipe_id, "recipe.feature_from_idea.developer", "Loaded run should preserve active processing.")
	_assert_equal(loaded_stack.processing_state.elapsed, 3.0, "Loaded run should preserve processing progress.")

	controller.set_paused(false)
	controller.advance_time(60.0)
	_assert_equal(state.phase, ScopeEnums.RunPhase.PAYMENT, "Sprint should enter payment.")
	_assert_true(controller.can_save_current_run(), "Payment phase should be saveable because processing is frozen.")

func _test_booster_draws_are_deterministic() -> void:
	var first: Dictionary = _open_spawned_booster_and_get_result(1007)
	var second: Dictionary = _open_spawned_booster_and_get_result(1007)

	_assert_equal(first["drawn_definitions"], second["drawn_definitions"], "Same seed should produce the same booster draw order.")
	_assert_equal(first["rng_state"], second["rng_state"], "Same seed should leave the same RNG state after opening.")

func _test_talent_pool_costs_two_money_and_draws_no_regular_employee() -> void:
	var controller: RunController = _create_controller(60.0)
	var state: RunState = controller.start_new_run(1008)
	var talent_pool_slot: CardInstance = _find_card_by_definition(state, "card.shop.booster_slot.talent_pool")
	var first_money: CardInstance = _spawn_card(controller, "card.resource.money", Vector2(5000.0, 5000.0))
	_spawn_card(controller, "card.resource.money", Vector2(5010.0, 5000.0))
	_spawn_card(controller, "card.resource.money", Vector2(5020.0, 5000.0))
	_spawn_card(controller, "card.resource.money", Vector2(5030.0, 5000.0))
	var money_count_before: int = _count_cards_by_definition(state, "card.resource.money")

	controller.move_card_to_stack(first_money.instance_id, talent_pool_slot.stack_id)

	_assert_equal(_count_cards_by_definition(state, "card.resource.money"), money_count_before - 2, "Talent-Pool should consume exactly 2 money cards.")
	_assert_equal(_count_money_cards_in_stack(state, talent_pool_slot.stack_id), 0, "Talent-Pool should drop unspent money back onto the board.")
	var booster_pack: CardInstance = _find_card_by_definition(state, "card.resource.booster_pack")
	_assert_equal(booster_pack.values.get(RunController.BOOSTER_DEFINITION_ID_VALUE, ""), "booster.talent_pool", "Talent-Pool buy should create a Talent-Pool booster pack.")

	while state.get_card(booster_pack.instance_id) != null:
		_assert_true(controller.open_booster_pack_step(booster_pack.instance_id), "Talent-Pool pack should open one card per step.")

	_assert_equal(_count_cards_by_definition(state, "card.employee.developer"), 1, "Talent-Pool should not draw a direct developer.")
	_assert_equal(_count_cards_by_definition(state, "card.employee.product_owner"), 0, "Talent-Pool should not draw a direct Product Owner.")
	_assert_equal(_count_cards_by_definition(state, "card.employee.tester"), 0, "Talent-Pool should not draw a direct tester.")
	_assert_equal(_count_cards_by_definition(state, "card.employee.recruiter"), 0, "Talent-Pool should not draw a direct recruiter.")
	_assert_equal(_count_cards_by_definition(state, "card.employee.external_dev"), 0, "Talent-Pool should not draw an external dev.")

func _test_interview_recipes_are_deterministic_and_recruiter_specific() -> void:
	var controller: RunController = _create_controller(60.0)
	controller.content.balance.poc4_normal_interview_success_chance = 1.0
	controller.content.balance.poc4_recruiter_interview_success_chance = 1.0
	controller.content.apply_balance_overrides()
	var state: RunState = controller.start_new_run(1009)
	var developer: CardInstance = _find_card_by_definition(state, "card.employee.developer")
	var candidate: CardInstance = _spawn_card(controller, "card.candidate.developer", Vector2(1200.0, 300.0))

	controller.move_card_to_stack(candidate.instance_id, developer.stack_id)
	var normal_stack: StackState = state.get_stack(developer.stack_id)
	_assert_equal(normal_stack.processing_state.active_recipe_id, "recipe.interview_candidate.regular_employee", "Regular employees should interview candidates through the normal interview recipe.")
	controller.advance_time(20.0)
	_assert_equal(_count_cards_by_definition(state, "card.offer.developer"), 1, "Successful normal interview should spawn the mapped offer.")
	_assert_equal(_count_cards_by_definition(state, "card.candidate.developer"), 0, "Interview completion should consume the candidate.")

	var recruiter: CardInstance = _spawn_card(controller, "card.employee.recruiter", Vector2(1600.0, 300.0))
	var recruiter_candidate: CardInstance = _spawn_card(controller, "card.candidate.tester", Vector2(1620.0, 300.0))
	controller.move_card_to_stack(recruiter_candidate.instance_id, recruiter.stack_id)
	var recruiter_stack: StackState = state.get_stack(recruiter.stack_id)
	_assert_equal(recruiter_stack.processing_state.active_recipe_id, "recipe.interview_candidate.recruiter", "Recruiter interview should win over the regular employee interview recipe.")
	_assert_equal(recruiter_stack.processing_state.duration, 10.0, "Recruiter interview should use the recruiter duration.")

func _test_offer_hiring_in_payment_defers_salary_and_attaches_onboarding() -> void:
	var controller: RunController = _create_controller(1.0)
	var state: RunState = controller.start_new_run(1010)
	var offer: CardInstance = _spawn_card(controller, "card.offer.tester", Vector2(1200.0, 300.0))
	var money: CardInstance = _spawn_card(controller, "card.resource.money", Vector2(1250.0, 300.0))

	controller.advance_time(1.0)
	_assert_equal(state.phase, ScopeEnums.RunPhase.PAYMENT, "Short sprint should enter payment before hiring offer.")
	controller.move_card_to_stack(money.instance_id, offer.stack_id)

	var hired_tester: CardInstance = _find_new_hire_with_salary_due(state, "card.employee.tester", 2)
	_assert_true(hired_tester != null, "Hiring an offer in payment should spawn the target employee with deferred salary.")
	_assert_true(not hired_tester.state.is_payment_target, "Payment-phase hire should not become a salary target in the same payment phase.")
	var onboarding: CardInstance = _find_attachment(state, hired_tester.instance_id, "onboarding")
	_assert_true(onboarding != null and onboarding.definition_id == "card.blocker.onboarding", "New hire should receive an onboarding attachment.")
	_assert_equal(_count_cards_by_definition(state, "card.offer.tester"), 0, "Hiring should consume the offer.")

func _test_onboarding_blocks_work_and_accepts_coffee() -> void:
	var controller: RunController = _create_controller(60.0)
	var state: RunState = controller.start_new_run(1011)
	var developer: CardInstance = _find_card_by_definition(state, "card.employee.developer")
	var idea: CardInstance = _find_card_by_definition(state, "card.input.idea")
	var coffee: CardInstance = _find_card_by_definition(state, "card.consumable.coffee")
	controller.call("_spawn_attached_card", developer.instance_id, "card.blocker.onboarding", "onboarding")

	var stack: StackState = state.get_stack(developer.stack_id)
	_assert_equal(stack.processing_state.active_recipe_id, "recipe.onboarding.employee", "Attached onboarding should start onboarding instead of normal work.")
	controller.move_card_to_stack(idea.instance_id, developer.stack_id)
	_assert_equal(stack.processing_state.active_recipe_id, "recipe.onboarding.employee", "Onboarding should keep normal work queued until it is removed.")
	controller.advance_time(1.0)
	controller.move_card_to_stack(coffee.instance_id, developer.stack_id)
	_assert_equal(stack.processing_state.active_recipe_id, "recipe.onboarding.employee", "Coffee should keep the onboarding recipe active.")
	_assert_true(stack.processing_state.elapsed > 1.0, "Coffee should accelerate onboarding because an employee is working.")
	_assert_equal(_count_cards_by_definition(state, "card.consumable.coffee"), 0, "Coffee used on onboarding should be consumed.")
	controller.advance_time(30.0)
	_assert_equal(_count_cards_by_definition(state, "card.blocker.onboarding"), 0, "Completed onboarding should remove only the onboarding card.")
	_assert_equal(stack.processing_state.active_recipe_id, "recipe.feature_from_idea.developer", "Queued normal work should start after onboarding is removed.")

func _open_spawned_booster_and_get_result(run_seed: int) -> Dictionary:
	var controller: RunController = _create_controller(60.0)
	var state: RunState = controller.start_new_run(run_seed)
	var booster_pack: CardInstance = _spawn_card(controller, "card.resource.booster_pack", Vector2(1200.0, 360.0))
	var existing_card_ids: Dictionary = {}
	for card_id: String in state.cards.keys():
		existing_card_ids[card_id] = true

	while state.get_card(booster_pack.instance_id) != null:
		_assert_true(controller.open_booster_pack_step(booster_pack.instance_id), "Booster pack should open one card per step.")

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
	}

func _pay_and_start_next_sprint(controller: RunController, state: RunState) -> void:
	controller.advance_time(1.0)
	_assert_equal(state.phase, ScopeEnums.RunPhase.PAYMENT, "Short sprint should enter payment before starting the next sprint.")
	_assert_true(controller.auto_pay_all_employees(), "Auto-pay should keep employees for the next sprint.")
	controller.start_next_sprint()

func _create_controller(sprint_duration: float) -> RunController:
	var catalog: ContentCatalog = ContentCatalog.new()
	_assert_true(catalog.load_default_content(), "Default content should load.")
	catalog.balance = catalog.balance.duplicate(true) as BalanceDefinition
	catalog.balance.sprint_duration_seconds = sprint_duration
	catalog.balance.bug_chance = 0.0
	catalog.balance.tech_debt_chance = 0.0
	catalog.balance.burnout_increment_per_completed_work = 0.0
	return RunController.new(catalog)

func _spawn_card(controller: RunController, definition_id: String, position: Vector2) -> CardInstance:
	return controller.call("_spawn_card_as_new_stack", definition_id, position) as CardInstance

func _find_card_by_definition(state: RunState, definition_id: String) -> CardInstance:
	for card: CardInstance in state.cards.values():
		if card.definition_id == definition_id:
			return card
	_assert_true(false, "Missing card with definition '%s'." % definition_id)
	return null

func _find_cards_by_definition(state: RunState, definition_id: String) -> Array[CardInstance]:
	var cards: Array[CardInstance] = []
	for card: CardInstance in state.cards.values():
		if card.definition_id == definition_id:
			cards.append(card)
	return cards

func _count_cards_by_definition(state: RunState, definition_id: String) -> int:
	var count: int = 0
	for card: CardInstance in state.cards.values():
		if card.definition_id == definition_id:
			count += 1
	return count

func _count_money_cards_in_stack(state: RunState, stack_id: String) -> int:
	var stack: StackState = state.get_stack(stack_id)
	if stack == null:
		return 0
	var count: int = 0
	for card_id: String in stack.card_ids:
		var card: CardInstance = state.get_card(card_id)
		if card != null and card.definition_id == "card.resource.money":
			count += 1
	return count

func _find_new_hire_with_salary_due(state: RunState, definition_id: String, salary_due_from_sprint: int) -> CardInstance:
	for card: CardInstance in state.cards.values():
		if card.definition_id == definition_id and int(card.values.get(RunController.SALARY_DUE_FROM_SPRINT_VALUE, 0)) == salary_due_from_sprint:
			return card
	return null

func _find_attachment(state: RunState, parent_card_id: String, attachment_slot: String) -> CardInstance:
	for card: CardInstance in state.cards.values():
		if card.parent_card_id == parent_card_id and card.attachment_slot == attachment_slot:
			return card
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

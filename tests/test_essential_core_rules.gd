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
	_test_recycling_bin_is_rightmost_shop_slot()
	_test_recycling_bin_requires_three_recyclable_cards()
	_test_recycling_bin_consumes_top_three_and_drops_leftovers()
	_test_recycling_bin_rejects_money_and_mixed_stacks()
	_test_recyclable_cards_do_not_drop_on_booster_slots()
	_test_freelance_order_is_permanent_shop_slot()
	_test_freelance_slot_pays_three_and_rolls_bug_for_unchecked_feature()
	_test_freelance_slot_pays_checked_feature_without_bug()
	_test_mvp_launch_threshold_and_customer_scaling()
	_test_customer_spawn_creates_initial_money_and_request_without_passive_tick_income()
	_test_customer_demo_and_feedback_are_repeatable_active_work()
	_test_old_customer_requests_make_only_one_customer_unhappy_per_sprint()
	_test_business_goal_costs_scale_linearly_from_one()
	_test_interview_recipes_are_deterministic_and_recruiter_specific()
	_test_offer_hiring_in_payment_defers_salary_and_attaches_onboarding()
	_test_onboarding_blocks_work_and_accepts_coffee()
	_test_recruiter_halves_active_onboarding_remaining_time()
	_test_work_student_is_temporary_unsalaried_work_capacity()
	_test_recruiter_fallback_work_is_slow_but_available()
	_test_poc4_save_load_preserves_hiring_cards_and_rng_state()

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

	var seeded_controller: RunController = _create_controller(60.0)
	var seeded_state: RunState = seeded_controller.start_new_run(1)
	var seeded_slot: CardInstance = _find_card_by_definition(seeded_state, "card.shop.booster_slot.talent_pool")
	var seeded_money: CardInstance = _spawn_card(seeded_controller, "card.resource.money", Vector2(5200.0, 5000.0))
	_spawn_card(seeded_controller, "card.resource.money", Vector2(5210.0, 5000.0))
	seeded_controller.move_card_to_stack(seeded_money.instance_id, seeded_slot.stack_id)
	var seeded_pack: CardInstance = _find_card_by_definition(seeded_state, "card.resource.booster_pack")
	while seeded_state.get_card(seeded_pack.instance_id) != null:
		_assert_true(seeded_controller.open_booster_pack_step(seeded_pack.instance_id), "Seeded Talent-Pool pack should open one card per step.")
	_assert_true(_count_cards_by_definition(seeded_state, "card.candidate.recruiter") >= 1, "Default playtest seed should expose a recruiter candidate in the first Talent-Pool pack.")

func _test_recycling_bin_is_rightmost_shop_slot() -> void:
	var controller: RunController = _create_controller(60.0)
	var state: RunState = controller.start_new_run(1017)
	var recycling_bin: CardInstance = _find_card_by_definition(state, "card.shop.recycling_bin")
	_assert_true(recycling_bin != null, "Start run should include the recycling bin shop slot.")

	var shop_dock: ShopDockView = ShopDockView.new()
	shop_dock.state = state
	shop_dock.content = controller.content
	var shop_card_ids: PackedStringArray = shop_dock.call("_get_shop_card_ids") as PackedStringArray
	_assert_true(not shop_card_ids.is_empty(), "Shop dock should find shop cards.")
	var rightmost_card: CardInstance = state.get_card(shop_card_ids[shop_card_ids.size() - 1])
	_assert_equal(rightmost_card.definition_id, "card.shop.recycling_bin", "Recycling bin should be the rightmost shop slot.")

func _test_recycling_bin_requires_three_recyclable_cards() -> void:
	var controller: RunController = _create_controller(60.0)
	var state: RunState = controller.start_new_run(1018)
	var recycling_bin: CardInstance = _find_card_by_definition(state, "card.shop.recycling_bin")
	var bottom: CardInstance = _spawn_card(controller, "card.input.idea", Vector2(5000.0, 300.0))
	var top: CardInstance = _spawn_card(controller, "card.consumable.coffee", Vector2(5100.0, 300.0))
	controller.move_card_to_stack(top.instance_id, bottom.stack_id)
	var original_stack_id: String = bottom.stack_id
	var money_before: int = _count_cards_by_definition(state, "card.resource.money")

	controller.move_card_to_stack(bottom.instance_id, recycling_bin.stack_id)

	_assert_equal(_count_cards_by_definition(state, "card.resource.money"), money_before, "Two recyclable cards should not produce money.")
	_assert_equal(bottom.stack_id, original_stack_id, "Too few recyclable cards should stay in their original stack.")
	_assert_equal(top.stack_id, original_stack_id, "Too few recyclable cards should not move onto the recycling bin.")
	_assert_equal(state.get_stack(recycling_bin.stack_id).card_ids.size(), 1, "Recycling bin stack should keep only the slot card after rejected drops.")

func _test_recycling_bin_consumes_top_three_and_drops_leftovers() -> void:
	var controller: RunController = _create_controller(60.0)
	var state: RunState = controller.start_new_run(1019)
	var recycling_bin: CardInstance = _find_card_by_definition(state, "card.shop.recycling_bin")
	var bottom: CardInstance = _spawn_card(controller, "card.input.idea", Vector2(5000.0, 600.0))
	var consumed_a: CardInstance = _spawn_card(controller, "card.consumable.coffee", Vector2(5100.0, 600.0))
	var consumed_b: CardInstance = _spawn_card(controller, "card.consumable.pizza_party", Vector2(5200.0, 600.0))
	var consumed_c: CardInstance = _spawn_card(controller, "card.consumable.stress_course", Vector2(5300.0, 600.0))
	controller.move_card_to_stack(consumed_a.instance_id, bottom.stack_id)
	controller.move_card_to_stack(consumed_b.instance_id, bottom.stack_id)
	controller.move_card_to_stack(consumed_c.instance_id, bottom.stack_id)
	var money_before: int = _count_cards_by_definition(state, "card.resource.money")

	controller.move_card_to_stack(bottom.instance_id, recycling_bin.stack_id)

	_assert_equal(_count_cards_by_definition(state, "card.resource.money"), money_before + 1, "Four recyclable cards should produce exactly one money.")
	_assert_true(state.get_card(bottom.instance_id) != null, "Bottom leftover card should remain after recycling four cards.")
	_assert_true(bottom.stack_id != recycling_bin.stack_id, "Leftover card should be dropped back onto the board.")
	_assert_true(state.get_card(consumed_a.instance_id) == null, "First top card should be consumed.")
	_assert_true(state.get_card(consumed_b.instance_id) == null, "Second top card should be consumed.")
	_assert_true(state.get_card(consumed_c.instance_id) == null, "Third top card should be consumed.")

func _test_recycling_bin_rejects_money_and_mixed_stacks() -> void:
	var controller: RunController = _create_controller(60.0)
	var state: RunState = controller.start_new_run(1020)
	var recycling_bin: CardInstance = _find_card_by_definition(state, "card.shop.recycling_bin")
	var money: CardInstance = _spawn_card(controller, "card.resource.money", Vector2(5000.0, 900.0))
	var money_stack_id: String = money.stack_id
	var money_before: int = _count_cards_by_definition(state, "card.resource.money")

	controller.move_card_to_stack(money.instance_id, recycling_bin.stack_id)

	_assert_equal(_count_cards_by_definition(state, "card.resource.money"), money_before, "Money on recycling bin should not create money.")
	_assert_equal(money.stack_id, money_stack_id, "Money should not move onto the recycling bin.")

	var bottom: CardInstance = _spawn_card(controller, "card.input.idea", Vector2(5200.0, 900.0))
	var mixed_money: CardInstance = _spawn_card(controller, "card.resource.money", Vector2(5300.0, 900.0))
	var top: CardInstance = _spawn_card(controller, "card.consumable.coffee", Vector2(5400.0, 900.0))
	controller.move_card_to_stack(mixed_money.instance_id, bottom.stack_id)
	controller.move_card_to_stack(top.instance_id, bottom.stack_id)
	var mixed_stack_id: String = bottom.stack_id
	var mixed_money_before: int = _count_cards_by_definition(state, "card.resource.money")

	controller.move_card_to_stack(bottom.instance_id, recycling_bin.stack_id)

	_assert_equal(_count_cards_by_definition(state, "card.resource.money"), mixed_money_before, "Mixed stacks should not be recycled.")
	_assert_equal(bottom.stack_id, mixed_stack_id, "Mixed stack should not move onto the recycling bin.")
	_assert_equal(mixed_money.stack_id, mixed_stack_id, "Mixed money card should stay in the rejected stack.")
	_assert_equal(top.stack_id, mixed_stack_id, "Mixed recyclable card should stay in the rejected stack.")

func _test_recyclable_cards_do_not_drop_on_booster_slots() -> void:
	var controller: RunController = _create_controller(60.0)
	var state: RunState = controller.start_new_run(1021)
	var booster_slot: CardInstance = _find_card_by_definition(state, "card.shop.booster_slot")
	var bottom: CardInstance = _spawn_card(controller, "card.input.idea", Vector2(5000.0, 1200.0))
	var middle: CardInstance = _spawn_card(controller, "card.consumable.coffee", Vector2(5100.0, 1200.0))
	var top: CardInstance = _spawn_card(controller, "card.consumable.pizza_party", Vector2(5200.0, 1200.0))
	controller.move_card_to_stack(middle.instance_id, bottom.stack_id)
	controller.move_card_to_stack(top.instance_id, bottom.stack_id)
	var original_stack_id: String = bottom.stack_id

	controller.move_card_to_stack(bottom.instance_id, booster_slot.stack_id)

	_assert_equal(bottom.stack_id, original_stack_id, "Recyclable stack should not drop onto normal booster slots.")
	_assert_equal(middle.stack_id, original_stack_id, "Recyclable stack should stay together after rejected booster-slot drop.")
	_assert_equal(top.stack_id, original_stack_id, "Recyclable stack should stay together after rejected booster-slot drop.")

func _test_freelance_order_is_permanent_shop_slot() -> void:
	var controller: RunController = _create_controller(1.0)
	var state: RunState = controller.start_new_run(1031)
	var freelance_slot: CardInstance = _find_card_by_definition(state, "card.shop.freelance_order")
	_assert_true(freelance_slot != null, "Start run should include the permanent Freelance shop slot.")
	_assert_equal(_count_cards_by_definition(state, "card.value_source.freelance_order"), 0, "Freelance should no longer spawn as a pre-launch value-source card.")

	_pay_and_start_next_sprint(controller, state)

	_assert_equal(_count_cards_by_definition(state, "card.shop.freelance_order"), 1, "Freelance shop slot should persist across sprint starts.")
	_assert_equal(_count_cards_by_definition(state, "card.value_source.freelance_order"), 0, "Sprint start should not spawn legacy Freelance order cards.")

func _test_freelance_slot_pays_three_and_rolls_bug_for_unchecked_feature() -> void:
	var controller: RunController = _create_controller(60.0)
	controller.content.balance.bug_chance = 1.0
	var state: RunState = controller.start_new_run(1032)
	var freelance_slot: CardInstance = _find_card_by_definition(state, "card.shop.freelance_order")
	var feature: CardInstance = _spawn_card(controller, "card.output.feature", Vector2(5000.0, 1500.0))
	var money_before: int = _count_cards_by_definition(state, "card.resource.money")
	var bugs_before: int = _count_cards_by_definition(state, "card.problem.bug")

	controller.move_card_to_stack(feature.instance_id, freelance_slot.stack_id)

	_assert_true(state.get_card(feature.instance_id) == null, "Freelance slot should consume the dumped unchecked feature.")
	_assert_equal(_count_cards_by_definition(state, "card.resource.money"), money_before + 3, "Unchecked feature Freelance dump should create 3 money cards.")
	_assert_equal(_count_cards_by_definition(state, "card.problem.bug"), bugs_before + 1, "Unchecked feature Freelance dump should use the release bug chance.")

func _test_freelance_slot_pays_checked_feature_without_bug() -> void:
	var controller: RunController = _create_controller(60.0)
	controller.content.balance.bug_chance = 1.0
	var state: RunState = controller.start_new_run(1033)
	var freelance_slot: CardInstance = _find_card_by_definition(state, "card.shop.freelance_order")
	var checked_feature: CardInstance = _spawn_card(controller, "card.output.checked_feature", Vector2(5000.0, 1700.0))
	var money_before: int = _count_cards_by_definition(state, "card.resource.money")
	var bugs_before: int = _count_cards_by_definition(state, "card.problem.bug")

	controller.move_card_to_stack(checked_feature.instance_id, freelance_slot.stack_id)

	_assert_true(state.get_card(checked_feature.instance_id) == null, "Freelance slot should consume the dumped checked feature.")
	_assert_equal(_count_cards_by_definition(state, "card.resource.money"), money_before + 3, "Checked feature Freelance dump should create 3 money cards.")
	_assert_equal(_count_cards_by_definition(state, "card.problem.bug"), bugs_before, "Checked feature Freelance dump should not create release bugs.")

func _test_mvp_launch_threshold_and_customer_scaling() -> void:
	var threshold_controller: RunController = _create_controller(60.0)
	var threshold_state: RunState = threshold_controller.start_new_run(1022)
	var threshold_software: CardInstance = _find_card_by_definition(threshold_state, "card.product.software")
	threshold_software.values[ProductLifecycleService.FEATURE_COUNT_VALUE] = 4
	_assert_true(not threshold_controller.is_software_launch_ready(), "Four features should not be launch-ready.")
	threshold_software.values[ProductLifecycleService.FEATURE_COUNT_VALUE] = 5
	_assert_true(threshold_controller.is_software_launch_ready(), "Five features should be launch-ready.")

	for feature_count: int in [5, 10, 15]:
		var controller: RunController = _create_controller(60.0)
		var state: RunState = controller.start_new_run(1022 + feature_count)
		var software: CardInstance = _find_card_by_definition(state, "card.product.software")
		var developer: CardInstance = _find_card_by_definition(state, "card.employee.developer")
		software.values[ProductLifecycleService.FEATURE_COUNT_VALUE] = feature_count
		controller.move_card_to_stack(developer.instance_id, software.stack_id)
		controller.advance_time(4.0)
		_assert_equal(_count_cards_by_definition(state, "card.value_source.customer"), floori(float(feature_count) / 5.0), "Launch should spawn one customer per five launch features.")

func _test_customer_spawn_creates_initial_money_and_request_without_passive_tick_income() -> void:
	var controller: RunController = _create_controller(1.0)
	var state: RunState = controller.start_new_run(1023)
	_make_software_live(state)
	var money_before_customer: int = _count_cards_by_definition(state, "card.resource.money")
	var requests_before_customer: int = _count_cards_by_definition(state, "card.input.customer_request")
	_spawn_card(controller, "card.value_source.customer", Vector2(1200.0, 300.0))

	_assert_equal(_count_cards_by_definition(state, "card.resource.money"), money_before_customer + 1, "A newly spawned live customer should create one initial money card.")
	_assert_equal(_count_cards_by_definition(state, "card.input.customer_request"), requests_before_customer + 1, "A newly spawned live customer should create one initial request.")

	var money_before_next_sprint: int = _count_cards_by_definition(state, "card.resource.money")
	var requests_before_next_sprint: int = _count_cards_by_definition(state, "card.input.customer_request")
	_pay_and_start_next_sprint(controller, state)

	_assert_equal(_count_cards_by_definition(state, "card.resource.money"), money_before_next_sprint - 1, "Customers should not create passive sprintstart money anymore; only salary payment should consume one money.")
	_assert_equal(_count_cards_by_definition(state, "card.input.customer_request"), requests_before_next_sprint, "Customers should not create passive sprintstart requests anymore.")

func _test_customer_demo_and_feedback_are_repeatable_active_work() -> void:
	var demo_controller: RunController = _create_controller(60.0)
	var demo_state: RunState = demo_controller.start_new_run(1024)
	_make_software_live(demo_state)
	var developer: CardInstance = _find_card_by_definition(demo_state, "card.employee.developer")
	var customer: CardInstance = _spawn_card(demo_controller, "card.value_source.customer", Vector2(1200.0, 300.0))
	var money_before_demo: int = _count_cards_by_definition(demo_state, "card.resource.money")
	var requests_before_demo: int = _count_cards_by_definition(demo_state, "card.input.customer_request")

	demo_controller.move_card_to_stack(developer.instance_id, customer.stack_id)
	var demo_stack: StackState = demo_state.get_stack(customer.stack_id)
	_assert_equal(demo_stack.processing_state.active_recipe_id, "recipe.demo_customer.developer", "Developer plus satisfied customer should start the demo recipe.")
	_assert_equal(demo_stack.processing_state.duration, 10.0, "Customer demos should take 10 seconds.")
	demo_controller.advance_time(10.0)
	_assert_equal(_count_cards_by_definition(demo_state, "card.resource.money"), money_before_demo + 1, "A completed demo should create one money card.")
	_assert_equal(_count_cards_by_definition(demo_state, "card.input.customer_request"), requests_before_demo + 1, "A completed demo should create one customer request.")
	_assert_equal(demo_stack.processing_state.active_recipe_id, "recipe.demo_customer.developer", "Demo work should restart while developer and customer remain stacked.")

	var request_controller: RunController = _create_controller(60.0)
	var request_state: RunState = request_controller.start_new_run(1030)
	var request_developer: CardInstance = _find_card_by_definition(request_state, "card.employee.developer")
	var request: CardInstance = _spawn_card(request_controller, "card.input.customer_request", Vector2(1200.0, 300.0))
	request_controller.move_card_to_stack(request.instance_id, request_developer.stack_id)
	var request_stack: StackState = request_state.get_stack(request_developer.stack_id)
	_assert_equal(request_stack.processing_state.active_recipe_id, "recipe.clear_customer_request.developer", "Developer should be able to clear customer requests.")
	_assert_equal(request_stack.processing_state.duration, 4.5, "Developer customer request handling should take half the previous 9 seconds.")

	var unhappy_controller: RunController = _create_controller(60.0)
	var unhappy_state: RunState = unhappy_controller.start_new_run(1025)
	_make_software_live(unhappy_state)
	var unhappy_developer: CardInstance = _find_card_by_definition(unhappy_state, "card.employee.developer")
	var unhappy_customer: CardInstance = _spawn_card(unhappy_controller, "card.value_source.customer", Vector2(1200.0, 300.0))
	unhappy_controller.call("_spawn_attached_card", unhappy_customer.instance_id, "card.problem.unhappy_customer", "unhappy_customer")
	unhappy_controller.move_card_to_stack(unhappy_developer.instance_id, unhappy_customer.stack_id)
	var unhappy_stack: StackState = unhappy_state.get_stack(unhappy_customer.stack_id)
	_assert_equal(unhappy_stack.processing_state.active_recipe_id, "recipe.manage_unhappy_customer.developer", "Developer should manage expectations instead of showing demos to unhappy customers.")
	_assert_equal(unhappy_stack.processing_state.duration, 16.0, "Developer expectation management should be slower than Product Owner expectation management.")
	unhappy_controller.advance_time(16.0)
	_assert_equal(_count_cards_by_definition(unhappy_state, "card.problem.unhappy_customer"), 0, "Developer expectation management should remove the unhappy attachment.")
	_assert_equal(unhappy_stack.processing_state.active_recipe_id, "recipe.demo_customer.developer", "After expectations are managed, the developer should be able to demo to the customer.")

	var crash_controller: RunController = _create_controller(60.0)
	var crash_state: RunState = crash_controller.start_new_run(1028)
	_make_software_live(crash_state)
	var crash_developer: CardInstance = _find_card_by_definition(crash_state, "card.employee.developer")
	var crash_customer: CardInstance = _spawn_card(crash_controller, "card.value_source.customer", Vector2(1200.0, 300.0))
	_spawn_card(crash_controller, "card.problem.prod_crash", Vector2(1400.0, 300.0))
	crash_controller.move_card_to_stack(crash_developer.instance_id, crash_customer.stack_id)
	_assert_equal(crash_state.get_stack(crash_customer.stack_id).processing_state.active_recipe_id, "", "Prod-Crash should block customer demo work immediately.")

	var feedback_controller: RunController = _create_controller(60.0)
	var feedback_state: RunState = feedback_controller.start_new_run(1026)
	_make_software_live(feedback_state)
	var product_owner: CardInstance = _spawn_card(feedback_controller, "card.employee.product_owner", Vector2(1000.0, 300.0))
	var feedback_customer: CardInstance = _spawn_card(feedback_controller, "card.value_source.customer", Vector2(1200.0, 300.0))
	var stories_before_feedback: int = _count_cards_by_definition(feedback_state, "card.task.user_story")

	feedback_controller.move_card_to_stack(product_owner.instance_id, feedback_customer.stack_id)
	var feedback_stack: StackState = feedback_state.get_stack(feedback_customer.stack_id)
	_assert_equal(feedback_stack.processing_state.active_recipe_id, "recipe.feedback_from_customer.product_owner", "Product Owner plus satisfied customer should start feedback work.")
	_assert_equal(feedback_stack.processing_state.duration, 30.0, "Customer feedback should take 30 seconds.")
	feedback_controller.advance_time(30.0)
	_assert_equal(_count_cards_by_definition(feedback_state, "card.task.user_story"), stories_before_feedback + 1, "Completed customer feedback should create one normal User Story.")
	_assert_equal(feedback_stack.processing_state.active_recipe_id, "recipe.feedback_from_customer.product_owner", "Feedback work should restart while Product Owner and customer remain stacked.")

func _test_old_customer_requests_make_only_one_customer_unhappy_per_sprint() -> void:
	var controller: RunController = _create_controller(1.0)
	var state: RunState = controller.start_new_run(1027)
	_make_software_live(state)
	_spawn_card(controller, "card.value_source.customer", Vector2(1200.0, 300.0))
	_spawn_card(controller, "card.value_source.customer", Vector2(1400.0, 300.0))
	_spawn_card(controller, "card.value_source.customer", Vector2(1600.0, 300.0))
	var request_count_before: int = _count_cards_by_definition(state, "card.input.customer_request")

	_pay_and_start_next_sprint(controller, state)

	_assert_equal(_count_cards_by_definition(state, "card.problem.unhappy_customer"), 1, "Any number of old customer requests should make at most one customer unhappy per sprintstart.")
	_assert_equal(_count_cards_by_definition(state, "card.input.customer_request"), request_count_before, "Old customer requests should remain on the board after causing one unhappy customer.")

func _test_business_goal_costs_scale_linearly_from_one() -> void:
	var controller: RunController = _create_controller(60.0)
	controller.start_new_run(1029)

	_assert_equal(controller.call("_get_required_money_for_business_goal_index", 1), 1, "First Business Goal should cost 1 money.")
	_assert_equal(controller.call("_get_required_money_for_business_goal_index", 2), 2, "Second Business Goal should cost 2 money.")
	_assert_equal(controller.call("_get_required_money_for_business_goal_index", 3), 3, "Third Business Goal should cost 3 money.")
	_assert_equal(controller.call("_get_required_money_for_business_goal_index", 5), 5, "Fifth Business Goal should cost 5 money.")
	_assert_equal(controller.call("_get_required_money_for_business_goal_index", 8), 8, "Business Goals beyond the configured list should continue with the goal index.")

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

func _test_recruiter_halves_active_onboarding_remaining_time() -> void:
	var controller: RunController = _create_controller(60.0)
	var state: RunState = controller.start_new_run(1015)
	var developer: CardInstance = _find_card_by_definition(state, "card.employee.developer")
	var recruiter: CardInstance = _spawn_card(controller, "card.employee.recruiter", Vector2(1200.0, 300.0))
	controller.call("_spawn_attached_card", developer.instance_id, "card.blocker.onboarding", "onboarding")

	var stack: StackState = state.get_stack(developer.stack_id)
	_assert_equal(stack.processing_state.active_recipe_id, "recipe.onboarding.employee", "Attached onboarding should start onboarding.")
	controller.advance_time(4.0)
	controller.move_card_to_stack(recruiter.instance_id, developer.stack_id)

	_assert_equal(_count_cards_by_definition(state, "card.employee.recruiter"), 1, "Recruiter should not be consumed by onboarding assistance.")
	_assert_equal(recruiter.stack_id, developer.stack_id, "Recruiter should be stacked onto the onboarding employee after assisting.")
	_assert_equal(stack.processing_state.active_recipe_id, "recipe.onboarding.employee", "Recruiter assistance should keep onboarding active.")
	_assert_equal(stack.processing_state.elapsed, 4.0, "Recruiter should not jump onboarding progress when added.")
	controller.advance_time(2.0)
	_assert_equal(stack.processing_state.elapsed, 8.0, "Onboarding should progress twice as fast while recruiter assists.")
	controller.split_stack_from_card(recruiter.instance_id, Vector2(1500.0, 300.0))
	_assert_equal(recruiter.stack_id != developer.stack_id, true, "Recruiter should be removable from the onboarding stack.")
	_assert_equal(stack.processing_state.elapsed, 8.0, "Removing recruiter should not jump onboarding progress.")
	controller.advance_time(12.0)
	_assert_equal(_count_cards_by_definition(state, "card.blocker.onboarding"), 0, "Onboarding should complete at normal speed after recruiter leaves.")

func _test_work_student_is_temporary_unsalaried_work_capacity() -> void:
	var controller: RunController = _create_controller(60.0)
	var state: RunState = controller.start_new_run(1012)
	var work_student: CardInstance = _spawn_card(controller, "card.temp_worker.work_student", Vector2(1200.0, 300.0))
	var idea: CardInstance = _spawn_card(controller, "card.input.idea", Vector2(1220.0, 300.0))

	controller.move_card_to_stack(idea.instance_id, work_student.stack_id)
	var stack: StackState = state.get_stack(work_student.stack_id)
	_assert_equal(stack.processing_state.active_recipe_id, "recipe.feature_from_idea.work_student", "Work student should be able to perform selected work recipes.")
	_assert_equal(stack.processing_state.duration, 16.0, "Work student work should use the configured +100% duration.")
	controller.advance_time(16.0)

	_assert_equal(_count_cards_by_definition(state, "card.output.feature"), 1, "Work student should complete the selected task.")
	_assert_equal(_count_cards_by_definition(state, "card.temp_worker.work_student"), 0, "Work student should disappear after one completed task.")

	var payment_controller: RunController = _create_controller(1.0)
	var payment_state: RunState = payment_controller.start_new_run(1013)
	_spawn_card(payment_controller, "card.temp_worker.work_student", Vector2(1400.0, 300.0))
	payment_controller.advance_time(1.0)
	_assert_equal(payment_state.phase, ScopeEnums.RunPhase.PAYMENT, "Short sprint should enter payment for work-student salary check.")
	_assert_equal(_count_payment_targets(payment_state), 1, "Only the regular developer should be a payment target.")
	_assert_true(payment_controller.can_auto_pay(), "Auto-pay should ignore the unsalaried work student.")
	payment_controller.start_next_sprint()
	_assert_equal(payment_state.phase, ScopeEnums.RunPhase.GAME_OVER, "Work student should not prevent game over when all regular employees quit.")

func _test_recruiter_fallback_work_is_slow_but_available() -> void:
	var controller: RunController = _create_controller(60.0)
	var state: RunState = controller.start_new_run(1016)
	var recruiter: CardInstance = _spawn_card(controller, "card.employee.recruiter", Vector2(1200.0, 300.0))
	var idea: CardInstance = _spawn_card(controller, "card.input.idea", Vector2(1220.0, 300.0))

	controller.move_card_to_stack(idea.instance_id, recruiter.stack_id)
	var stack: StackState = state.get_stack(recruiter.stack_id)
	_assert_equal(stack.processing_state.active_recipe_id, "recipe.feature_from_idea.recruiter", "Recruiter should have a data-driven fallback for normal work.")
	_assert_true(stack.processing_state.duration > 8.0, "Recruiter fallback work should be slower than the primary developer path.")

func _test_poc4_save_load_preserves_hiring_cards_and_rng_state() -> void:
	var controller: RunController = _create_controller(60.0)
	var state: RunState = controller.start_new_run(1014)
	var recruiter: CardInstance = _spawn_card(controller, "card.employee.recruiter", Vector2(1200.0, 300.0))
	var candidate: CardInstance = _spawn_card(controller, "card.candidate.recruiter", Vector2(1220.0, 300.0))
	var offer: CardInstance = _spawn_card(controller, "card.offer.developer", Vector2(1240.0, 300.0))
	var work_student: CardInstance = _spawn_card(controller, "card.temp_worker.work_student", Vector2(1260.0, 300.0))
	controller.call("_spawn_attached_card", recruiter.instance_id, "card.blocker.onboarding", "onboarding")
	state.rng_state = 123456789
	controller.set_paused(true)

	_assert_true(controller.save_current_run(SAVE_PATH), "PoC4 paused save should succeed.")
	var loaded_controller: RunController = _create_controller(60.0)
	_assert_true(loaded_controller.load_run_from_file(SAVE_PATH), "PoC4 save should load.")
	var loaded_state: RunState = loaded_controller.state

	_assert_equal(_count_cards_by_definition(loaded_state, candidate.definition_id), 1, "Save/load should preserve candidates.")
	_assert_equal(_count_cards_by_definition(loaded_state, offer.definition_id), 1, "Save/load should preserve offers.")
	_assert_equal(_count_cards_by_definition(loaded_state, recruiter.definition_id), 1, "Save/load should preserve recruiter.")
	_assert_equal(_count_cards_by_definition(loaded_state, work_student.definition_id), 1, "Save/load should preserve work student.")
	var loaded_recruiter: CardInstance = _find_card_by_definition(loaded_state, "card.employee.recruiter")
	_assert_true(_find_attachment(loaded_state, loaded_recruiter.instance_id, "onboarding") != null, "Save/load should preserve onboarding attachment.")
	_assert_equal(loaded_state.rng_state, 123456789, "Save/load should preserve RNG state.")

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

func _make_software_live(state: RunState) -> void:
	var software: CardInstance = _find_card_by_definition(state, "card.product.software")
	software.values[ProductLifecycleService.PRODUCT_STAGE_VALUE] = ProductLifecycleService.PRODUCT_STAGE_LIVE

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

func _count_payment_targets(state: RunState) -> int:
	var count: int = 0
	for card: CardInstance in state.cards.values():
		if card.state.is_payment_target:
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

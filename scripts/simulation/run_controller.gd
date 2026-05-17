class_name RunController
extends RefCounted

const SPRINT_TIMER_ID: String = "sprint_remaining_seconds"
const START_LAYOUT_ORIGIN: Vector2 = Vector2(420.0, 322.0)
const START_LAYOUT_COLUMNS: int = 6
const START_LAYOUT_STEP: Vector2 = Vector2(192.0, 240.0)
const STARTUP_BOOSTER_PACK_DEFINITION_ID: String = "card.resource.startup_booster_pack"
const STARTUP_BOOSTER_POSITION: Vector2 = Vector2(888.0, 442.0)
const DEFAULT_BOOSTER_DEFINITION_ID: String = "booster.founder.test_pack"
const CONTENT_VERSION: String = "poc_cleanup1"
const BOOSTER_DEFINITION_ID_VALUE: String = "booster_definition_id"
const BOOSTER_REMAINING_CARD_IDS_VALUE: String = "booster_remaining_card_ids"
const BURNOUT_ATTACHMENT_SLOT: String = "burnout"
const UNHAPPY_CUSTOMER_ATTACHMENT_SLOT: String = "unhappy_customer"
const ONBOARDING_ATTACHMENT_SLOT: String = "onboarding"
const BURNOUT_PROGRESS_VALUE: String = "burnout_progress"
const SALARY_DUE_FROM_SPRINT_VALUE: String = "salary_due_from_sprint"
const COMPLETED_TASK_LIFETIME_VALUE: String = "completed_task_lifetime"
const ONBOARDING_RECIPE_ID: String = "recipe.onboarding.employee"
const RECRUITER_ONBOARDING_MODIFIER_KEY: String = "recruiter_onboarding"
const CUSTOMER_DEFINITION_ID: String = "card.value_source.customer"
const CUSTOMER_REQUEST_DEFINITION_ID: String = "card.input.customer_request"
const MONEY_DEFINITION_ID: String = "card.resource.money"
const CHECKED_FEATURE_DEFINITION_ID: String = "card.output.checked_feature"
const UNHAPPY_CUSTOMER_DEFINITION_ID: String = "card.problem.unhappy_customer"
const BUSINESS_GOAL_DEFINITION_ID: String = "card.goal.business_goal"
const INVESTOR_PANIC_DEFINITION_ID: String = "card.problem.investor_panic"
const START_CHECKED_FEATURE_CARD_COUNT: int = 0
const ActiveProcessingInteractionServiceScript: Script = preload("res://scripts/simulation/active_processing_interaction_service.gd")
const ProductLifecycleServiceScript: Script = preload("res://scripts/simulation/product_lifecycle_service.gd")
const ShopInteractionServiceScript: Script = preload("res://scripts/simulation/shop_interaction_service.gd")
const HiringLifecycleServiceScript: Script = preload("res://scripts/simulation/hiring_lifecycle_service.gd")
const SprintStartPipelineServiceScript: Script = preload("res://scripts/simulation/sprint_start_pipeline_service.gd")
const SpawnPlacementServiceScript: Script = preload("res://scripts/simulation/spawn_placement_service.gd")
const DropInteractionPreviewServiceScript: Script = preload("res://scripts/simulation/drop_interaction_preview_service.gd")
const START_SHOP_CARD_IDS: Array[String] = [
	"card.shop.freelance_order",
	"card.shop.booster_slot",
	"card.shop.booster_slot.office_invest",
	"card.shop.bugfix_patch_slot",
	"card.shop.booster_slot.talent_pool",
	"card.shop.recycling_bin",
]

var content: ContentCatalog = null
var state: RunState = null
var pending_events: Array[SimulationEvent] = []
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _recipe_engine: RecipeEngine = RecipeEngine.new()
var _effect_pipeline: EffectPipeline = EffectPipeline.new()
var _tech_debt_modifiers: TechDebtModifierService = TechDebtModifierService.new()
var _processing_interactions: ActiveProcessingInteractionService = ActiveProcessingInteractionServiceScript.new() as ActiveProcessingInteractionService
var _product_lifecycle: RefCounted = ProductLifecycleServiceScript.new()
var _shop_interactions: RefCounted = ShopInteractionServiceScript.new()
var _hiring_lifecycle: RefCounted = HiringLifecycleServiceScript.new()
var _sprint_start_pipeline: RefCounted = SprintStartPipelineServiceScript.new()
var _spawn_placement: RefCounted = SpawnPlacementServiceScript.new()
var _drop_interaction_preview: RefCounted = DropInteractionPreviewServiceScript.new() as RefCounted
var _save_serializer: RunSaveSerializer = RunSaveSerializer.new()
var _next_card_index: int = 1
var _next_stack_index: int = 1

func _init(content_catalog: ContentCatalog = null) -> void:
	content = content_catalog
	if content == null:
		content = ContentCatalog.new()
		content.load_default_content()

func start_new_run(run_seed: int = 1) -> RunState:
	pending_events.clear()
	_next_card_index = 1
	_next_stack_index = 1

	state = RunState.new()
	state.run_id = "run_%d" % run_seed
	state.sprint_index = 1
	state.phase = ScopeEnums.RunPhase.SPRINT
	state.is_paused = false
	state.rng_seed = run_seed
	_rng.seed = run_seed
	state.rng_state = _rng.state
	state.content_version = CONTENT_VERSION
	state.active_timers[SPRINT_TIMER_ID] = _get_sprint_duration()
	_shop_interactions.setup(state, content)
	_hiring_lifecycle.setup(state, content)
	_spawn_placement.setup(state, content)
	_drop_interaction_preview.call("setup", state, Callable(self, "can_move_card_to_stack"))

	var startup_pack: CardInstance = _spawn_card_as_new_stack(STARTUP_BOOSTER_PACK_DEFINITION_ID, STARTUP_BOOSTER_POSITION)
	if startup_pack != null:
		_get_or_create_booster_remaining_card_ids(startup_pack)

	for index: int in START_SHOP_CARD_IDS.size():
		var column: int = index % START_LAYOUT_COLUMNS
		var row: int = floori(float(index) / float(START_LAYOUT_COLUMNS))
		var position: Vector2 = START_LAYOUT_ORIGIN + Vector2(float(column), float(row)) * START_LAYOUT_STEP
		_spawn_card_as_new_stack(START_SHOP_CARD_IDS[index], position)

	for checked_feature_index: int in START_CHECKED_FEATURE_CARD_COUNT:
		var layout_index: int = START_SHOP_CARD_IDS.size() + checked_feature_index
		var column: int = layout_index % START_LAYOUT_COLUMNS
		var row: int = floori(float(layout_index) / float(START_LAYOUT_COLUMNS))
		var position: Vector2 = START_LAYOUT_ORIGIN + Vector2(float(column), float(row)) * START_LAYOUT_STEP
		_spawn_card_as_new_stack(CHECKED_FEATURE_DEFINITION_ID, position)
	_product_lifecycle.ensure_software_defaults(state, _get_mvp_required_features())
	var software: CardInstance = get_software_card()
	if software != null:
		software.values[ProductLifecycleService.MVP_REQUIRED_FEATURES_VALUE] = _get_mvp_required_features()

	_emit(SimulationEvent.phase_changed(state.phase))
	_emit(SimulationEvent.timer_updated(SPRINT_TIMER_ID, state.active_timers[SPRINT_TIMER_ID] as float))
	return state

func get_software_card() -> CardInstance:
	_require_state()
	return _product_lifecycle.get_software_card(state)

func is_software_launch_ready() -> bool:
	_require_state()
	return _product_lifecycle.is_launch_ready(state)

func drain_events() -> Array[SimulationEvent]:
	var events: Array[SimulationEvent] = pending_events.duplicate()
	pending_events.clear()
	return events

func can_save_current_run() -> bool:
	return _save_serializer.can_save_run(state)

func save_current_run(path: String) -> bool:
	_require_state()
	return _save_serializer.save_to_file(state, path)

func load_run_from_file(path: String) -> bool:
	var loaded_state: RunState = _save_serializer.load_from_file(path, content)
	if loaded_state == null:
		for error: String in _save_serializer.errors:
			push_error(error)
		return false
	load_run(loaded_state)
	return true

func load_run(loaded_state: RunState) -> void:
	assert(loaded_state != null, "Loaded RunState must not be null.")
	pending_events.clear()
	state = loaded_state
	_shop_interactions.setup(state, content)
	_hiring_lifecycle.setup(state, content)
	_spawn_placement.setup(state, content)
	_drop_interaction_preview.call("setup", state, Callable(self, "can_move_card_to_stack"))
	_rng.seed = state.rng_seed
	_rng.state = state.rng_state
	_sync_next_runtime_ids()
	_prune_stale_spawn_history()
	_product_lifecycle.ensure_software_defaults(state, _get_mvp_required_features())
	_refresh_attachment_runtime_states()
	_emit(SimulationEvent.phase_changed(state.phase))
	_emit(SimulationEvent.pause_changed(state.is_paused))
	_emit(SimulationEvent.timer_updated(SPRINT_TIMER_ID, state.active_timers.get(SPRINT_TIMER_ID, 0.0) as float))
	_emit_all_stacks_changed()

func get_save_errors() -> PackedStringArray:
	return _save_serializer.errors.duplicate()

func set_paused(paused: bool) -> void:
	_require_state()
	if state.phase != ScopeEnums.RunPhase.SPRINT:
		paused = false
	if state.is_paused == paused:
		return
	state.is_paused = paused
	_emit(SimulationEvent.pause_changed(paused))

func advance_time(delta_seconds: float) -> void:
	_require_state()
	if state.phase != ScopeEnums.RunPhase.SPRINT or state.is_paused:
		return

	var safe_delta: float = maxf(0.0, delta_seconds)
	var remaining_before: float = state.active_timers.get(SPRINT_TIMER_ID, 0.0) as float
	var elapsed_this_tick: float = minf(safe_delta, remaining_before)
	var remaining_after: float = maxf(0.0, remaining_before - safe_delta)
	state.active_timers[SPRINT_TIMER_ID] = remaining_after
	_emit(SimulationEvent.timer_updated(SPRINT_TIMER_ID, remaining_after))

	if elapsed_this_tick > 0.0:
		_advance_processing(elapsed_this_tick)

	if remaining_after <= 0.0:
		_enter_payment_phase()

func _advance_processing(delta_seconds: float) -> void:
	var stack_ids: Array = state.stacks.keys()
	for stack_id: String in stack_ids:
		if not state.stacks.has(stack_id):
			continue
		var stack: StackState = _get_existing_stack(stack_id)
		if not stack.processing_state.is_active():
			continue
		stack.processing_state.elapsed += delta_seconds * _get_processing_speed_multiplier(stack.processing_state)
		if stack.processing_state.elapsed >= stack.processing_state.duration:
			_complete_processing(stack)
		elif state.stacks.has(stack.stack_id):
			_emit(SimulationEvent.stack_changed(stack.stack_id))

func move_stack(stack_id: String, position: Vector2) -> void:
	_require_state()
	var stack: StackState = _get_existing_stack(stack_id)
	if not _can_interact_with_board():
		return
	stack.base_position = position
	for card_id: String in stack.card_ids:
		var card: CardInstance = _get_existing_card(card_id)
		card.position = position
	_emit(SimulationEvent.stack_changed(stack.stack_id))

func move_card_to_stack(card_id: String, target_stack_id: String) -> void:
	_require_state()
	var card: CardInstance = _get_existing_card(card_id)
	if not card.parent_card_id.is_empty():
		return
	var source_stack: StackState = _get_existing_stack(card.stack_id)
	var target_stack: StackState = _get_existing_stack(target_stack_id)
	if source_stack.stack_id == target_stack.stack_id:
		return

	var start_index: int = source_stack.card_ids.find(card_id)
	if start_index < 0:
		push_error("Card '%s' is not in its source stack." % card_id)
		return
	var moving_card_ids: PackedStringArray = source_stack.card_ids.slice(start_index)
	if not _can_interact_with_board():
		return
	if _try_buy_shop_with_money_stack(card, moving_card_ids, target_stack):
		return
	if _try_recycle_card_stack(moving_card_ids, target_stack):
		return
	if _try_hire_offer_with_money_stack(card, moving_card_ids, target_stack):
		return
	if _try_pay_employee_with_money(card, moving_card_ids, target_stack):
		return
	if _try_pay_business_goal_with_money(card, moving_card_ids, target_stack):
		return
	if _is_shop_stack(target_stack):
		return
	if _try_apply_processing_interaction(moving_card_ids, target_stack):
		return
	source_stack.card_ids = source_stack.card_ids.slice(0, start_index)

	for moving_card_id: String in moving_card_ids:
		target_stack.card_ids.append(moving_card_id)
		var moving_card: CardInstance = _get_existing_card(moving_card_id)
		moving_card.stack_id = target_stack.stack_id
		moving_card.position = target_stack.base_position

	_refresh_attachment_runtime_states()
	_emit(SimulationEvent.stack_changed(source_stack.stack_id))
	_emit(SimulationEvent.stack_changed(target_stack.stack_id))
	_delete_stack_if_empty(source_stack)
	_refresh_stack_recipe_if_present(source_stack.stack_id)
	_refresh_stack_recipe_if_present(target_stack.stack_id)

func _can_drop_on_shop(card: CardInstance, moving_card_ids: PackedStringArray, target_stack: StackState) -> bool:
	var shop_card: CardInstance = _shop_interactions.find_shop_card_in_stack(target_stack)
	if shop_card == null:
		return false
	return _shop_interactions.can_drop_card_on_shop(card.instance_id, moving_card_ids.size(), shop_card)

func _can_hire_offer_with_money_stack(card: CardInstance, moving_card_ids: PackedStringArray, target_stack: StackState) -> bool:
	return _hiring_lifecycle.can_hire_offer_with_money_stack(
		card,
		moving_card_ids,
		target_stack,
		_get_offer_hire_cost_money_cards()
	)

func _can_pay_employee_with_money(card: CardInstance, moving_card_ids: PackedStringArray, target_stack: StackState) -> bool:
	if state.phase != ScopeEnums.RunPhase.PAYMENT:
		return false
	if moving_card_ids.size() != 1 or not _is_money_card(card):
		return false
	return not _find_unpaid_employee_in_stack(target_stack).is_empty()

func _can_pay_business_goal_with_money(card: CardInstance, moving_card_ids: PackedStringArray, target_stack: StackState) -> bool:
	if not _is_money_card(card):
		return false
	for moving_card_id: String in moving_card_ids:
		var moving_card: CardInstance = state.get_card(moving_card_id)
		if moving_card == null or not _is_money_card(moving_card):
			return false

	var goal: CardInstance = _find_business_goal_in_stack(target_stack)
	if goal == null:
		return false
	return _get_business_goal_paid_money(goal) < _get_business_goal_required_money(goal)

func _can_form_recipe_stack(moving_card_ids: PackedStringArray, target_stack: StackState) -> bool:
	var temporary_stack: StackState = StackState.new()
	temporary_stack.stack_id = target_stack.stack_id
	temporary_stack.base_position = target_stack.base_position
	temporary_stack.card_ids = target_stack.card_ids.duplicate()
	for moving_card_id: String in moving_card_ids:
		temporary_stack.card_ids.append(moving_card_id)

	var match_result: RecipeMatchResult = _recipe_engine.find_best_match(temporary_stack, state, content)
	return match_result.has_match()

func _try_apply_processing_interaction(moving_card_ids: PackedStringArray, target_stack: StackState) -> bool:
	var result: ActiveProcessingInteractionResult = _processing_interactions.calculate(moving_card_ids, target_stack, state, content)
	if not result.applied:
		return false

	for consumed_card_id: String in result.consumed_card_ids:
		_remove_card_instance(consumed_card_id)

	if not state.stacks.has(target_stack.stack_id):
		return true

	_move_unconsumed_interaction_cards_to_target(moving_card_ids, result.consumed_card_ids, target_stack.stack_id)

	var updated_target_stack: StackState = _get_existing_stack(target_stack.stack_id)
	if not updated_target_stack.processing_state.is_active():
		return true

	updated_target_stack.processing_state.elapsed = result.new_elapsed
	_refresh_reversible_processing_modifiers(updated_target_stack)
	if result.should_complete and _can_complete_processing_from_interaction():
		_complete_processing(updated_target_stack)
	elif state.stacks.has(updated_target_stack.stack_id):
		_emit(SimulationEvent.stack_changed(updated_target_stack.stack_id))

	return true

func _move_unconsumed_interaction_cards_to_target(
	moving_card_ids: PackedStringArray,
	consumed_card_ids: PackedStringArray,
	target_stack_id: String
) -> void:
	var target_stack: StackState = state.get_stack(target_stack_id)
	if target_stack == null:
		return

	var touched_stack_ids: PackedStringArray = PackedStringArray()
	for moving_card_id: String in moving_card_ids:
		if consumed_card_ids.has(moving_card_id):
			continue
		var moving_card: CardInstance = state.get_card(moving_card_id)
		if moving_card == null or moving_card.stack_id == target_stack_id:
			continue
		var source_stack: StackState = state.get_stack(moving_card.stack_id)
		if source_stack != null:
			_remove_card_from_stack(source_stack, moving_card_id)
			if not touched_stack_ids.has(source_stack.stack_id):
				touched_stack_ids.append(source_stack.stack_id)
		target_stack.card_ids.append(moving_card_id)
		moving_card.stack_id = target_stack.stack_id
		moving_card.position = target_stack.base_position

	for stack_id: String in touched_stack_ids:
		if not state.stacks.has(stack_id):
			continue
		var stack: StackState = _get_existing_stack(stack_id)
		_emit(SimulationEvent.stack_changed(stack.stack_id))
		_delete_stack_if_empty(stack)

func _can_complete_processing_from_interaction() -> bool:
	return state.phase == ScopeEnums.RunPhase.SPRINT and not state.is_paused

func _try_buy_shop_with_money_stack(card: CardInstance, moving_card_ids: PackedStringArray, target_stack: StackState) -> bool:
	return _shop_interactions.try_buy_shop_with_money_stack(
		card,
		moving_card_ids,
		target_stack,
		Callable(self, "_consume_money_card"),
		Callable(self, "_spawn_card_as_new_stack"),
		Callable(self, "_move_existing_cards_to_new_stack"),
		Callable(self, "_get_spawn_position_near_stack"),
		Callable(self, "_emit_stack_changed")
	)

func _try_recycle_card_stack(moving_card_ids: PackedStringArray, target_stack: StackState) -> bool:
	return _shop_interactions.try_recycle_card_stack(
		moving_card_ids,
		target_stack,
		Callable(self, "_remove_card_instance"),
		Callable(self, "_spawn_card_as_new_stack"),
		Callable(self, "_move_existing_cards_to_new_stack"),
		Callable(self, "_get_spawn_position_near_stack"),
		Callable(self, "_emit_stack_changed")
	)

func split_stack_from_card(card_id: String, new_position: Vector2) -> StackState:
	_require_state()
	var card: CardInstance = _get_existing_card(card_id)
	if not card.parent_card_id.is_empty():
		return null
	var source_stack: StackState = _get_existing_stack(card.stack_id)
	var start_index: int = source_stack.card_ids.find(card_id)
	if start_index < 0:
		push_error("Card '%s' is not in its source stack." % card_id)
		return null

	var new_stack: StackState = _create_stack(new_position)
	var moving_card_ids: PackedStringArray = source_stack.card_ids.slice(start_index)
	if not _can_interact_with_board():
		state.stacks.erase(new_stack.stack_id)
		return null
	source_stack.card_ids = source_stack.card_ids.slice(0, start_index)

	for moving_card_id: String in moving_card_ids:
		new_stack.card_ids.append(moving_card_id)
		var moving_card: CardInstance = _get_existing_card(moving_card_id)
		moving_card.stack_id = new_stack.stack_id
		moving_card.position = new_position

	_refresh_attachment_runtime_states()
	_emit(SimulationEvent.stack_changed(source_stack.stack_id))
	_emit(SimulationEvent.stack_changed(new_stack.stack_id))
	_delete_stack_if_empty(source_stack)
	_refresh_stack_recipe_if_present(source_stack.stack_id)
	_refresh_stack_recipe_if_present(new_stack.stack_id)
	return new_stack

func _move_existing_cards_to_new_stack(card_ids: PackedStringArray, new_position: Vector2) -> StackState:
	var new_stack: StackState = _create_stack(new_position)
	var touched_stack_ids: PackedStringArray = PackedStringArray()

	for card_id: String in card_ids:
		var moving_card: CardInstance = state.get_card(card_id)
		if moving_card == null:
			continue
		var source_stack: StackState = state.get_stack(moving_card.stack_id)
		if source_stack != null:
			_remove_card_from_stack(source_stack, card_id)
			if not touched_stack_ids.has(source_stack.stack_id):
				touched_stack_ids.append(source_stack.stack_id)
		new_stack.card_ids.append(card_id)
		moving_card.stack_id = new_stack.stack_id
		moving_card.position = new_position

	for stack_id: String in touched_stack_ids:
		if not state.stacks.has(stack_id):
			continue
		var stack: StackState = _get_existing_stack(stack_id)
		_emit(SimulationEvent.stack_changed(stack.stack_id))
		_delete_stack_if_empty(stack)
		_refresh_stack_recipe_if_present(stack_id)

	_emit(SimulationEvent.stack_changed(new_stack.stack_id))
	_refresh_stack_recipe_if_present(new_stack.stack_id)
	return new_stack

func auto_pay_all_employees() -> bool:
	_require_state()
	if not can_auto_pay():
		return false

	var unpaid_employee_ids: PackedStringArray = _get_unpaid_employee_ids()
	var money_ids: PackedStringArray = _get_money_card_ids()

	for employee_id: String in unpaid_employee_ids:
		var money_id: String = _take_best_auto_pay_money_id(employee_id, money_ids)
		if money_id.is_empty() or not _consume_money_card(money_id):
			return false
		money_ids.remove_at(money_ids.find(money_id))
		_mark_employee_paid(employee_id)
	_refresh_payment_card_states()
	_emit_all_stacks_changed()
	return true

func can_auto_pay() -> bool:
	_require_state()
	if state.phase != ScopeEnums.RunPhase.PAYMENT:
		return false
	var unpaid_employee_ids: PackedStringArray = _get_unpaid_employee_ids()
	if unpaid_employee_ids.is_empty():
		return false
	return _get_money_card_ids().size() >= unpaid_employee_ids.size()

func can_move_card_to_stack(card_id: String, target_stack_id: String) -> bool:
	_require_state()
	var card: CardInstance = state.get_card(card_id)
	if card == null or not card.parent_card_id.is_empty():
		return false
	var source_stack: StackState = state.get_stack(card.stack_id)
	var target_stack: StackState = state.get_stack(target_stack_id)
	if source_stack == null or target_stack == null or source_stack.stack_id == target_stack.stack_id:
		return false

	var start_index: int = source_stack.card_ids.find(card_id)
	if start_index < 0:
		return false
	var moving_card_ids: PackedStringArray = source_stack.card_ids.slice(start_index)
	if moving_card_ids.is_empty():
		return false
	if not _can_interact_with_board():
		return false

	if _can_drop_on_shop(card, moving_card_ids, target_stack):
		return true
	if _can_hire_offer_with_money_stack(card, moving_card_ids, target_stack):
		return true
	if _can_pay_employee_with_money(card, moving_card_ids, target_stack):
		return true
	if _can_pay_business_goal_with_money(card, moving_card_ids, target_stack):
		return true
	if _is_shop_stack(target_stack):
		return false
	if _processing_interactions.calculate(moving_card_ids, target_stack, state, content).applied:
		return true
	return _can_form_recipe_stack(moving_card_ids, target_stack)

func get_drop_interaction_preview_stack_ids(card_id: String) -> PackedStringArray:
	_require_state()
	return _drop_interaction_preview.call("get_preview_stack_ids", card_id) as PackedStringArray

func open_booster_pack_step(card_id: String) -> bool:
	_require_state()
	if not _can_interact_with_board():
		return false

	var booster_pack: CardInstance = state.get_card(card_id)
	if booster_pack == null or not _is_booster_pack_card(booster_pack):
		return false

	var remaining_card_ids: PackedStringArray = _get_or_create_booster_remaining_card_ids(booster_pack)
	if remaining_card_ids.is_empty():
		_remove_card_instance(booster_pack.instance_id)
		return false

	var spawned_card_definition_id: String = remaining_card_ids[0]
	remaining_card_ids.remove_at(0)
	booster_pack.values[BOOSTER_REMAINING_CARD_IDS_VALUE] = remaining_card_ids
	_set_booster_pack_marker(booster_pack, remaining_card_ids.size())

	_spawn_card_as_new_stack(spawned_card_definition_id, _get_booster_spawn_position_near_stack(booster_pack.stack_id))
	if remaining_card_ids.is_empty():
		_remove_card_instance(booster_pack.instance_id)
	else:
		_emit(SimulationEvent.stack_changed(booster_pack.stack_id))
	return true

func start_next_sprint() -> void:
	_require_state()
	if state.phase != ScopeEnums.RunPhase.PAYMENT:
		return

	if not _run_sprint_start_pipeline():
		return
	state.phase = ScopeEnums.RunPhase.SPRINT
	state.is_paused = false
	state.paid_employee_ids = PackedStringArray()
	state.active_timers[SPRINT_TIMER_ID] = _get_sprint_duration()
	_clear_payment_card_states()
	_emit(SimulationEvent.phase_changed(state.phase))
	_emit(SimulationEvent.pause_changed(false))
	_emit(SimulationEvent.timer_updated(SPRINT_TIMER_ID, state.active_timers[SPRINT_TIMER_ID] as float))
	_emit_all_stacks_changed()

func _enter_payment_phase() -> void:
	if state.phase != ScopeEnums.RunPhase.SPRINT:
		return
	state.phase = ScopeEnums.RunPhase.PAYMENT
	if state.is_paused:
		state.is_paused = false
		_emit(SimulationEvent.pause_changed(false))
	state.active_timers[SPRINT_TIMER_ID] = 0.0
	_refresh_payment_card_states()
	_emit(SimulationEvent.phase_changed(state.phase))
	_emit(SimulationEvent.timer_updated(SPRINT_TIMER_ID, 0.0))
	_emit_all_stacks_changed()

func _enter_game_over() -> void:
	state.phase = ScopeEnums.RunPhase.GAME_OVER
	state.is_paused = false
	state.active_timers[SPRINT_TIMER_ID] = 0.0
	_clear_payment_card_states()
	_emit(SimulationEvent.phase_changed(state.phase))
	_emit(SimulationEvent.pause_changed(false))
	_emit(SimulationEvent.timer_updated(SPRINT_TIMER_ID, 0.0))
	_emit_all_stacks_changed()

func _enter_victory() -> void:
	state.phase = ScopeEnums.RunPhase.VICTORY
	state.is_paused = false
	state.active_timers[SPRINT_TIMER_ID] = 0.0
	_clear_payment_card_states()
	_emit(SimulationEvent.phase_changed(state.phase))
	_emit(SimulationEvent.pause_changed(false))
	_emit(SimulationEvent.timer_updated(SPRINT_TIMER_ID, 0.0))
	_emit_all_stacks_changed()

func _try_pay_employee_with_money(card: CardInstance, moving_card_ids: PackedStringArray, target_stack: StackState) -> bool:
	if not _can_pay_employee_with_money(card, moving_card_ids, target_stack):
		return false

	var employee_id: String = _find_unpaid_employee_in_stack(target_stack)
	if not _consume_money_card(card.instance_id):
		return false
	_mark_employee_paid(employee_id)
	_refresh_payment_card_states()
	_emit(SimulationEvent.stack_changed(target_stack.stack_id))
	return true

func _try_hire_offer_with_money_stack(card: CardInstance, moving_card_ids: PackedStringArray, target_stack: StackState) -> bool:
	return _hiring_lifecycle.try_hire_offer_with_money_stack(
		card,
		moving_card_ids,
		target_stack,
		_get_offer_hire_cost_money_cards(),
		_get_salary_due_from_sprint_for_new_hire(),
		Callable(self, "_consume_money_card"),
		Callable(self, "_remove_card_instance"),
		Callable(self, "_spawn_card_as_new_stack"),
		Callable(self, "_spawn_attached_card"),
		Callable(self, "_move_existing_cards_to_new_stack"),
		Callable(self, "_get_spawn_position_near_stack"),
		Callable(self, "_refresh_payment_card_states")
	)

func _try_pay_business_goal_with_money(card: CardInstance, moving_card_ids: PackedStringArray, target_stack: StackState) -> bool:
	if not _can_interact_with_board():
		return false
	if not _can_pay_business_goal_with_money(card, moving_card_ids, target_stack):
		return false

	var goal: CardInstance = _find_business_goal_in_stack(target_stack)
	var required_money: int = _get_business_goal_required_money(goal)
	var paid_money: int = _get_business_goal_paid_money(goal)
	if paid_money >= required_money:
		return false

	var needed_money: int = required_money - paid_money
	var consumed_count: int = 0
	for moving_card_id: String in moving_card_ids:
		if consumed_count >= needed_money:
			break
		if _consume_money_card(moving_card_id):
			consumed_count += 1

	if consumed_count <= 0:
		return false

	goal.values["paid_money"] = paid_money + consumed_count
	_refresh_business_goal_runtime_state(goal)
	_emit(SimulationEvent.stack_changed(target_stack.stack_id))
	return true

func _mark_employee_paid(employee_id: String) -> void:
	if not state.paid_employee_ids.has(employee_id):
		state.paid_employee_ids.append(employee_id)
	var employee: CardInstance = _get_existing_card(employee_id)
	employee.state.is_paid = true
	employee.state.is_payment_target = false

func _can_interact_with_board() -> bool:
	return state.phase == ScopeEnums.RunPhase.SPRINT or state.phase == ScopeEnums.RunPhase.PAYMENT

func _find_unpaid_employee_in_stack(stack: StackState) -> String:
	if stack == null:
		return ""
	for card_id: String in stack.card_ids:
		var card: CardInstance = state.get_card(card_id)
		if card != null and _requires_salary(card) and not state.paid_employee_ids.has(card.instance_id):
			return card.instance_id
	return ""

func _get_unpaid_employee_ids() -> PackedStringArray:
	var employee_ids: PackedStringArray = PackedStringArray()
	for card: CardInstance in state.cards.values():
		if _requires_salary(card) and not state.paid_employee_ids.has(card.instance_id):
			employee_ids.append(card.instance_id)
	return employee_ids

func _get_money_card_ids() -> PackedStringArray:
	var money_ids: PackedStringArray = PackedStringArray()
	for card: CardInstance in state.cards.values():
		if _is_money_card(card):
			money_ids.append(card.instance_id)
	return money_ids

func _consume_money_card(card_id: String) -> bool:
	var card: CardInstance = state.get_card(card_id)
	if card == null or not _is_money_card(card):
		return false
	_remove_card_instance(card_id)
	return true

func _take_best_auto_pay_money_id(employee_id: String, available_money_ids: PackedStringArray) -> String:
	var employee: CardInstance = state.get_card(employee_id)
	if employee != null:
		var employee_stack: StackState = state.get_stack(employee.stack_id)
		if employee_stack != null:
			for card_id: String in employee_stack.card_ids:
				if available_money_ids.has(card_id):
					return card_id
	if available_money_ids.is_empty():
		return ""
	return available_money_ids[0]

func _quit_unpaid_employees() -> void:
	var unpaid_employee_ids: PackedStringArray = _get_unpaid_employee_ids()
	for employee_id: String in unpaid_employee_ids:
		var employee: CardInstance = state.get_card(employee_id)
		if employee == null:
			continue
		var stack: StackState = state.get_stack(employee.stack_id)
		if stack != null and stack.processing_state.is_active():
			_cancel_processing(stack)
		_remove_card_instance(employee_id)

func _run_sprint_start_pipeline() -> bool:
	return _sprint_start_pipeline.run(
		state,
		Callable(self, "_quit_unpaid_employees"),
		Callable(self, "_has_no_employees"),
		Callable(self, "_enter_game_over"),
		Callable(self, "_advance_sprint_index"),
		Callable(self, "_form_prod_crashes_from_bugs"),
		Callable(self, "_duplicate_remaining_bugs"),
		Callable(self, "_expire_open_orders"),
		Callable(self, "_expire_unused_external_devs"),
		Callable(self, "_attach_unhappy_customers_from_old_requests"),
		Callable(self, "_resolve_active_business_goal"),
		Callable(self, "_spawn_persistent_tick_cards")
	)

func _advance_sprint_index() -> void:
	state.sprint_index += 1

func _form_prod_crashes_from_bugs() -> void:
	var bug_ids: PackedStringArray = _find_card_ids_with_tag("bug")
	var crash_count: int = floori(float(bug_ids.size()) / 3.0)
	for crash_index: int in crash_count:
		var first_bug: CardInstance = state.get_card(bug_ids[crash_index * 3])
		var spawn_position: Vector2 = Vector2.ZERO
		if first_bug != null:
			spawn_position = _get_spawn_position_near_stack(first_bug.stack_id, crash_index)

		for offset: int in 3:
			_remove_card_instance(bug_ids[crash_index * 3 + offset])
		_spawn_card_as_new_stack("card.problem.prod_crash", spawn_position)

func _duplicate_remaining_bugs() -> void:
	var bug_ids: PackedStringArray = _find_card_ids_with_tag("bug")
	for index: int in bug_ids.size():
		var bug: CardInstance = state.get_card(bug_ids[index])
		if bug == null:
			continue
		_spawn_card_as_new_stack("card.problem.bug", _get_spawn_position_near_stack(bug.stack_id, index))

func _expire_open_orders() -> void:
	var order_ids: PackedStringArray = _find_card_ids_with_tag("order")
	for card_id: String in order_ids:
		_remove_card_instance(card_id)

func _expire_unused_external_devs() -> void:
	var external_dev_ids: PackedStringArray = _find_card_ids_with_tag("external_dev")
	for card_id: String in external_dev_ids:
		var card: CardInstance = state.get_card(card_id)
		if card != null and not bool(card.values.get("completed_task", false)):
			_remove_card_instance(card_id)

func _spawn_persistent_tick_cards() -> void:
	var spawner_ids: PackedStringArray = _find_card_ids_with_tag("sprint_tick_spawner")
	for card_id: String in spawner_ids:
		var spawner: CardInstance = state.get_card(card_id)
		if spawner == null:
			continue
		var spawned_card_definition_id: String = spawner.values.get("sprint_tick_spawn_card_id", "") as String
		if spawned_card_definition_id.is_empty():
			continue
		_spawn_card_as_new_stack(spawned_card_definition_id, _get_spawn_position_near_stack(spawner.stack_id, 0))

func _attach_unhappy_customers_from_old_requests() -> void:
	if not _is_software_live():
		return
	var request_ids: PackedStringArray = _find_card_ids_by_definition(CUSTOMER_REQUEST_DEFINITION_ID)
	var available_customer_ids: PackedStringArray = _get_satisfied_customer_ids()
	if available_customer_ids.is_empty():
		return
	_rng.state = state.rng_state
	for request_id: String in request_ids:
		var request: CardInstance = state.get_card(request_id)
		if request == null:
			continue
		var spawned_sprint_index: int = int(request.values.get("spawned_sprint_index", request.created_at_sprint))
		if spawned_sprint_index < state.sprint_index:
			var customer_index: int = _rng.randi_range(0, available_customer_ids.size() - 1)
			var customer_id: String = available_customer_ids[customer_index]
			_spawn_attached_card(customer_id, UNHAPPY_CUSTOMER_DEFINITION_ID, UNHAPPY_CUSTOMER_ATTACHMENT_SLOT)
			break
	state.rng_state = _rng.state

func _resolve_active_business_goal() -> void:
	if state.phase == ScopeEnums.RunPhase.GAME_OVER:
		return
	if not _is_software_live():
		return

	var goal: CardInstance = _find_active_business_goal()
	if goal == null:
		if state.completed_business_goal_count < _get_business_goal_win_count():
			_spawn_business_goal(state.completed_business_goal_count + 1, _get_business_goal_spawn_source_stack_id())
		return

	var goal_index: int = _get_business_goal_index(goal)
	var was_fulfilled: bool = _get_business_goal_paid_money(goal) >= _get_business_goal_required_money(goal)
	var goal_position: Vector2 = goal.position
	_remove_card_instance(goal.instance_id)

	if was_fulfilled:
		state.completed_business_goal_count += 1
		if state.completed_business_goal_count >= _get_business_goal_win_count():
			_enter_victory()
			return
	else:
		var panic_spawn_position: Vector2 = _get_spawn_position_near_position(goal_position, 0)
		_spawn_card_as_new_stack(INVESTOR_PANIC_DEFINITION_ID, panic_spawn_position)
		_enter_game_over_if_investor_panic_limit_reached()
		if state.phase == ScopeEnums.RunPhase.GAME_OVER:
			return

	var next_goal_spawn_position: Vector2 = _get_spawn_position_near_position(goal_position, 1)
	_spawn_business_goal_at_position(goal_index + 1, next_goal_spawn_position)

func _spawn_business_goal(goal_index: int, source_stack_id: String) -> CardInstance:
	return _spawn_business_goal_at_position(goal_index, _get_spawn_position_near_stack(source_stack_id, 1))

func _spawn_business_goal_at_position(goal_index: int, position: Vector2) -> CardInstance:
	var goal: CardInstance = _spawn_card_as_new_stack(BUSINESS_GOAL_DEFINITION_ID, position)
	if goal == null:
		return null
	goal.values["goal_index"] = goal_index
	goal.values["required_money"] = _get_required_money_for_business_goal_index(goal_index)
	goal.values["paid_money"] = 0
	_refresh_business_goal_runtime_state(goal)
	return goal

func _enter_game_over_if_investor_panic_limit_reached() -> void:
	if _find_card_ids_by_definition(INVESTOR_PANIC_DEFINITION_ID).size() >= _get_investor_panic_game_over_count():
		_enter_game_over()

func _find_business_goal_in_stack(stack: StackState) -> CardInstance:
	if stack == null:
		return null
	for card_id: String in stack.card_ids:
		var card: CardInstance = state.get_card(card_id)
		if card != null and card.definition_id == BUSINESS_GOAL_DEFINITION_ID:
			return card
	return null

func _find_active_business_goal() -> CardInstance:
	for card: CardInstance in state.cards.values():
		if card.definition_id == BUSINESS_GOAL_DEFINITION_ID:
			return card
	return null

func _refresh_business_goal_runtime_state(goal: CardInstance) -> void:
	if goal == null:
		return
	goal.state.markers = PackedStringArray(["G%d" % _get_business_goal_index(goal)])

func _get_business_goal_index(goal: CardInstance) -> int:
	return maxi(1, int(goal.values.get("goal_index", 1)))

func _get_business_goal_paid_money(goal: CardInstance) -> int:
	return maxi(0, int(goal.values.get("paid_money", 0)))

func _get_business_goal_required_money(goal: CardInstance) -> int:
	return maxi(1, int(goal.values.get("required_money", _get_required_money_for_business_goal_index(_get_business_goal_index(goal)))))

func _get_required_money_for_business_goal_index(goal_index: int) -> int:
	var required_money_values: Array[int] = _get_business_goal_required_money_values()
	if goal_index <= required_money_values.size():
		return required_money_values[maxi(0, goal_index - 1)]
	return maxi(1, goal_index)

func _get_mvp_required_features() -> int:
	if content.balance == null:
		return ProductLifecycleService.DEFAULT_MVP_REQUIRED_FEATURES
	return maxi(1, content.balance.poc3_mvp_required_features)

func _get_start_money_card_count() -> int:
	if content.balance == null:
		return 30
	return maxi(0, content.balance.poc3_start_money_cards)

func _get_offer_hire_cost_money_cards() -> int:
	if content.balance == null:
		return 1
	return maxi(1, content.balance.poc4_offer_hire_cost_money_cards)

func _get_salary_due_from_sprint_for_new_hire() -> int:
	if state.phase == ScopeEnums.RunPhase.PAYMENT:
		return state.sprint_index + 1
	return state.sprint_index

func _get_initial_customer_money_card_count() -> int:
	if content.balance == null:
		return 1
	return maxi(0, content.balance.poc5_initial_customer_money_cards)

func _get_initial_customer_request_card_count() -> int:
	if content.balance == null:
		return 1
	return maxi(0, content.balance.poc5_initial_customer_request_cards)

func _get_business_goal_required_money_values() -> Array[int]:
	if content.balance == null or content.balance.poc3_business_goal_required_money.is_empty():
		return [1, 2, 3, 4, 5]
	var values: Array[int] = []
	for value: int in content.balance.poc3_business_goal_required_money:
		values.append(maxi(1, value))
	return values

func _get_business_goal_win_count() -> int:
	if content.balance == null:
		return 3
	return maxi(1, content.balance.poc3_business_goal_win_count)

func _get_investor_panic_game_over_count() -> int:
	if content.balance == null:
		return 2
	return maxi(1, content.balance.poc3_investor_panic_game_over_count)

func _get_business_goal_spawn_source_stack_id() -> String:
	var software: CardInstance = get_software_card()
	if software != null:
		return software.stack_id
	return ""

func _is_software_live() -> bool:
	var software: CardInstance = get_software_card()
	return software != null and _product_lifecycle.get_product_stage(software) == ProductLifecycleService.PRODUCT_STAGE_LIVE

func _get_satisfied_customer_ids() -> PackedStringArray:
	var customer_ids: PackedStringArray = PackedStringArray()
	for card_id: String in _find_card_ids_by_definition(CUSTOMER_DEFINITION_ID):
		var customer: CardInstance = state.get_card(card_id)
		if customer != null and not _has_attachment(customer.instance_id, UNHAPPY_CUSTOMER_ATTACHMENT_SLOT):
			customer_ids.append(customer.instance_id)
	return customer_ids

func _find_card_ids_with_tag(tag: String) -> PackedStringArray:
	var card_ids: PackedStringArray = PackedStringArray()
	for card: CardInstance in state.cards.values():
		var definition: CardDefinition = content.get_card_definition(card.definition_id)
		if definition != null and definition.tags.has(tag):
			card_ids.append(card.instance_id)
	return card_ids

func _find_card_ids_by_definition(definition_id: String) -> PackedStringArray:
	var card_ids: PackedStringArray = PackedStringArray()
	for card: CardInstance in state.cards.values():
		if card.definition_id == definition_id:
			card_ids.append(card.instance_id)
	return card_ids

func _has_no_employees() -> bool:
	for card: CardInstance in state.cards.values():
		if is_regular_employee(card):
			return false
	return true

func _refresh_payment_card_states() -> void:
	for card: CardInstance in state.cards.values():
		var is_employee: bool = _requires_salary(card)
		card.state.is_locked = false
		card.state.is_paid = is_employee and state.paid_employee_ids.has(card.instance_id)
		card.state.is_payment_target = state.phase == ScopeEnums.RunPhase.PAYMENT and is_employee and not card.state.is_paid
	_refresh_attachment_runtime_states()

func _clear_payment_card_states() -> void:
	for card: CardInstance in state.cards.values():
		card.state.is_locked = false
		card.state.is_paid = false
		card.state.is_payment_target = false
	_refresh_attachment_runtime_states()

func _is_employee_card(card: CardInstance) -> bool:
	var definition: CardDefinition = content.get_card_definition(card.definition_id)
	return definition != null and definition.type == ScopeEnums.CardType.EMPLOYEE

func is_regular_employee(card: CardInstance) -> bool:
	var definition: CardDefinition = content.get_card_definition(card.definition_id)
	return definition != null and definition.type == ScopeEnums.CardType.EMPLOYEE and definition.tags.has("regular_employee")

func _requires_salary(card: CardInstance) -> bool:
	var definition: CardDefinition = content.get_card_definition(card.definition_id)
	if definition == null or definition.type != ScopeEnums.CardType.EMPLOYEE or not definition.tags.has("salary_required"):
		return false
	return int(card.values.get(SALARY_DUE_FROM_SPRINT_VALUE, state.sprint_index)) <= state.sprint_index

func _is_money_card(card: CardInstance) -> bool:
	var definition: CardDefinition = content.get_card_definition(card.definition_id)
	return definition != null and definition.tags.has("money")

func _is_booster_pack_card(card: CardInstance) -> bool:
	var definition: CardDefinition = content.get_card_definition(card.definition_id)
	return definition != null and definition.tags.has("booster") and definition.tags.has("pack")

func _get_or_create_booster_remaining_card_ids(booster_pack: CardInstance) -> PackedStringArray:
	if booster_pack.values.has(BOOSTER_REMAINING_CARD_IDS_VALUE):
		return _variant_to_packed_string_array(booster_pack.values[BOOSTER_REMAINING_CARD_IDS_VALUE])

	var booster_id: String = booster_pack.values.get(BOOSTER_DEFINITION_ID_VALUE, DEFAULT_BOOSTER_DEFINITION_ID) as String
	var booster: BoosterDefinition = content.get_booster_definition(booster_id)
	if booster == null:
		push_error("Missing booster definition: %s" % booster_id)
		return PackedStringArray()

	_rng.state = state.rng_state
	var drawn_card_ids: PackedStringArray = PackedStringArray()
	if not booster.fixed_card_definition_ids.is_empty():
		drawn_card_ids = booster.fixed_card_definition_ids.duplicate()
	else:
		for _draw_index: int in booster.draw_count:
			var card_definition_id: String = _draw_card_from_booster(booster)
			if not card_definition_id.is_empty():
				drawn_card_ids.append(card_definition_id)
		state.rng_state = _rng.state

	booster_pack.values[BOOSTER_DEFINITION_ID_VALUE] = booster_id
	booster_pack.values[BOOSTER_REMAINING_CARD_IDS_VALUE] = drawn_card_ids
	_set_booster_pack_marker(booster_pack, drawn_card_ids.size())
	return drawn_card_ids

func _draw_card_from_booster(booster: BoosterDefinition) -> String:
	var total_weight: int = 0
	for entry: BoosterPoolEntry in booster.pool_entries:
		if entry != null:
			total_weight += maxi(entry.weight, 0)
	if total_weight <= 0:
		return ""

	var roll: int = _rng.randi_range(1, total_weight)
	var running_weight: int = 0
	for entry: BoosterPoolEntry in booster.pool_entries:
		if entry == null:
			continue
		running_weight += maxi(entry.weight, 0)
		if roll <= running_weight:
			return entry.card_definition_id
	return ""

func _variant_to_packed_string_array(value: Variant) -> PackedStringArray:
	if value is PackedStringArray:
		return value as PackedStringArray
	var result: PackedStringArray = PackedStringArray()
	if value is Array:
		for item: Variant in value as Array:
			result.append(str(item))
	return result

func _set_booster_pack_marker(booster_pack: CardInstance, remaining_count: int) -> void:
	booster_pack.state.markers = PackedStringArray([str(remaining_count)])

func _emit_all_stacks_changed() -> void:
	for stack_id: String in state.stacks.keys():
		_emit(SimulationEvent.stack_changed(stack_id))

func _emit_stack_changed(stack_id: String) -> void:
	_emit(SimulationEvent.stack_changed(stack_id))

func _refresh_stack_recipe_if_present(stack_id: String) -> void:
	if state.stacks.has(stack_id):
		_refresh_stack_recipe(_get_existing_stack(stack_id))

func _refresh_stack_recipe(stack: StackState) -> void:
	var match_result: RecipeMatchResult = _recipe_engine.find_best_match(stack, state, content)
	if match_result.is_ambiguous():
		push_warning("Ambiguous recipe match for stack '%s': %s" % [stack.stack_id, ", ".join(match_result.ambiguous_recipe_ids)])

	var current_recipe_id: String = stack.processing_state.active_recipe_id
	var matched_recipe_id: String = ""
	if match_result.recipe != null:
		matched_recipe_id = match_result.recipe.id

	if not current_recipe_id.is_empty():
		if current_recipe_id == matched_recipe_id and _active_processing_inputs_still_present(stack):
			if _refresh_reversible_processing_modifiers(stack):
				_emit(SimulationEvent.stack_changed(stack.stack_id))
			return
		if _active_processing_inputs_still_present(stack):
			if _should_replace_active_processing(current_recipe_id, match_result):
				_replace_active_processing(stack, match_result)
			else:
				if _refresh_reversible_processing_modifiers(stack):
					_emit(SimulationEvent.stack_changed(stack.stack_id))
			return
		_cancel_processing(stack)

	if match_result.recipe != null:
		_start_processing(stack, match_result)

func _start_processing(stack: StackState, match_result: RecipeMatchResult) -> void:
	var recipe: RecipeDefinition = match_result.recipe
	stack.processing_state.active_recipe_id = recipe.id
	stack.processing_state.active_input_card_ids = match_result.active_input_card_ids
	stack.processing_state.status = ScopeEnums.ProcessingStatus.ACTIVE
	stack.processing_state.elapsed = 0.0
	stack.processing_state.duration = _tech_debt_modifiers.get_duration_seconds(recipe, state, content, stack, match_result.active_input_card_ids)
	stack.processing_state.active_modifier_keys = PackedStringArray()
	_refresh_reversible_processing_modifiers(stack)
	_emit(SimulationEvent.recipe_started(stack.stack_id))
	_emit(SimulationEvent.stack_changed(stack.stack_id))

func _replace_active_processing(stack: StackState, match_result: RecipeMatchResult) -> void:
	var recipe: RecipeDefinition = match_result.recipe
	if recipe == null:
		return
	var elapsed: float = stack.processing_state.elapsed
	stack.processing_state.active_recipe_id = recipe.id
	stack.processing_state.active_input_card_ids = match_result.active_input_card_ids
	stack.processing_state.duration = _tech_debt_modifiers.get_duration_seconds(recipe, state, content, stack, match_result.active_input_card_ids)
	stack.processing_state.elapsed = minf(elapsed, stack.processing_state.duration)
	stack.processing_state.active_modifier_keys = PackedStringArray()
	_refresh_reversible_processing_modifiers(stack)
	_emit(SimulationEvent.recipe_started(stack.stack_id))
	_emit(SimulationEvent.stack_changed(stack.stack_id))

func _should_replace_active_processing(current_recipe_id: String, match_result: RecipeMatchResult) -> bool:
	if match_result.recipe == null or match_result.recipe.id == current_recipe_id:
		return false
	var current_recipe: RecipeDefinition = content.get_recipe_definition(current_recipe_id)
	if current_recipe == null:
		return true
	if _recipe_uses_burnout(match_result.recipe) or _recipe_uses_employee_blocker(match_result.recipe):
		return true
	return _recipe_uses_burnout(current_recipe) or _recipe_uses_employee_blocker(current_recipe)

func _cancel_processing(stack: StackState) -> void:
	_clear_processing(stack)
	_emit(SimulationEvent.recipe_cancelled(stack.stack_id))
	_emit(SimulationEvent.stack_changed(stack.stack_id))

func _complete_processing(stack: StackState) -> void:
	var recipe: RecipeDefinition = content.get_recipe_definition(stack.processing_state.active_recipe_id)
	var active_input_card_ids: PackedStringArray = stack.processing_state.active_input_card_ids
	var productive_employee_ids: PackedStringArray = _get_productive_employee_ids(stack, recipe)
	_clear_processing(stack)
	if recipe == null:
		_emit(SimulationEvent.stack_changed(stack.stack_id))
		return

	_execute_effects(recipe.effects_on_complete, stack, recipe, active_input_card_ids)
	_apply_burnout_risk(productive_employee_ids)
	_consume_one_task_lifetime_workers(productive_employee_ids)
	_emit(SimulationEvent.recipe_completed(stack.stack_id))
	if state.stacks.has(stack.stack_id):
		_delete_stack_if_empty(stack)
		_refresh_stack_recipe_if_present(stack.stack_id)

func _clear_processing(stack: StackState) -> void:
	stack.processing_state.active_recipe_id = ""
	stack.processing_state.active_input_card_ids = PackedStringArray()
	stack.processing_state.status = ScopeEnums.ProcessingStatus.IDLE
	stack.processing_state.elapsed = 0.0
	stack.processing_state.duration = 0.0
	stack.processing_state.active_modifier_keys = PackedStringArray()

func _refresh_reversible_processing_modifiers(stack: StackState) -> bool:
	if stack == null or not stack.processing_state.is_active():
		return false
	if stack.processing_state.active_recipe_id != ONBOARDING_RECIPE_ID:
		return _set_processing_modifier_active(stack.processing_state, RECRUITER_ONBOARDING_MODIFIER_KEY, false)

	var should_apply_recruiter: bool = _stack_has_recruiter_onboarding_helper(stack)
	return _set_processing_modifier_active(stack.processing_state, RECRUITER_ONBOARDING_MODIFIER_KEY, should_apply_recruiter)

func _set_processing_modifier_active(processing: ProcessingState, modifier_key: String, active: bool) -> bool:
	var was_active: bool = processing.active_modifier_keys.has(modifier_key)
	if was_active == active:
		return false

	if active:
		processing.active_modifier_keys.append(modifier_key)
	else:
		processing.active_modifier_keys.remove_at(processing.active_modifier_keys.find(modifier_key))
	return true

func _get_processing_speed_multiplier(processing: ProcessingState) -> float:
	var multiplier: float = 1.0
	if processing.active_modifier_keys.has(RECRUITER_ONBOARDING_MODIFIER_KEY):
		multiplier *= 2.0
	return multiplier

func _stack_has_recruiter_onboarding_helper(stack: StackState) -> bool:
	for card_id: String in stack.card_ids:
		if stack.processing_state.active_input_card_ids.has(card_id):
			continue
		var card: CardInstance = state.get_card(card_id)
		if card != null and _has_definition_tag(card, "recruiter"):
			return true
	return false

func _active_processing_inputs_still_present(stack: StackState) -> bool:
	for card_id: String in stack.processing_state.active_input_card_ids:
		if not stack.card_ids.has(card_id):
			return false
	return true

func _execute_effects(
	effects: Array[EffectDefinition],
	stack: StackState,
	recipe: RecipeDefinition,
	active_input_card_ids: PackedStringArray = PackedStringArray()
) -> void:
	_rng.state = state.rng_state
	var context: EffectContext = EffectContext.new()
	context.state = state
	context.stack = stack
	context.recipe = recipe
	context.active_input_card_ids = active_input_card_ids
	context.content = content
	context.rng = _rng
	context.spawn_card = Callable(self, "_spawn_card_as_new_stack")
	context.remove_card = Callable(self, "_remove_card_instance")
	context.get_spawn_position = Callable(self, "_get_spawn_position_near_stack")
	_effect_pipeline.execute(effects, context)
	state.rng_state = _rng.state

func _spawn_card_as_new_stack(card_definition_id: String, position: Vector2) -> CardInstance:
	if not content.has_card_definition(card_definition_id):
		push_error("Missing card definition: %s" % card_definition_id)
		return null

	var definition: CardDefinition = content.get_card_definition(card_definition_id)
	var stack: StackState = _find_auto_stack_spawn_target(definition, position)
	var was_stacked_on_spawn: bool = stack != null
	if stack == null:
		stack = _create_stack(position)
	else:
		position = stack.base_position

	var card: CardInstance = CardInstance.new()
	card.instance_id = _create_card_instance_id()
	card.definition_id = card_definition_id
	card.stack_id = stack.stack_id
	card.position = position
	card.created_at_sprint = state.sprint_index
	if definition != null:
		card.values = definition.base_values.duplicate(true)
	_product_lifecycle.ensure_card_defaults(card, _get_mvp_required_features())
	stack.card_ids.append(card.instance_id)
	state.cards[card.instance_id] = card

	_emit(SimulationEvent.card_spawned(card.instance_id, stack.stack_id, card.definition_id, was_stacked_on_spawn))
	_emit(SimulationEvent.stack_changed(stack.stack_id))
	_refresh_stack_recipe_if_present(stack.stack_id)
	if card.definition_id == CUSTOMER_DEFINITION_ID:
		_spawn_initial_customer_cards(card)
	return card

func _spawn_initial_customer_cards(customer: CardInstance) -> void:
	if customer == null or not _is_software_live():
		return
	if _has_attachment(customer.instance_id, UNHAPPY_CUSTOMER_ATTACHMENT_SLOT):
		return

	var spawn_index: int = 0
	for money_index: int in _get_initial_customer_money_card_count():
		_spawn_card_as_new_stack(MONEY_DEFINITION_ID, _get_spawn_position_near_stack(customer.stack_id, spawn_index))
		spawn_index += 1
	for request_index: int in _get_initial_customer_request_card_count():
		var request: CardInstance = _spawn_card_as_new_stack(CUSTOMER_REQUEST_DEFINITION_ID, _get_spawn_position_near_stack(customer.stack_id, spawn_index))
		spawn_index += 1
		if request != null:
			request.values["spawned_sprint_index"] = state.sprint_index

func _get_spawn_position_near_position(source_position: Vector2, spawn_index: int = 0) -> Vector2:
	return _spawn_placement.get_spawn_position_near_position(source_position, spawn_index)

func _find_auto_stack_spawn_target(definition: CardDefinition, position: Vector2) -> StackState:
	return _spawn_placement.find_auto_stack_spawn_target(definition, position)

func _spawn_attached_card(parent_card_id: String, card_definition_id: String, attachment_slot: String) -> CardInstance:
	if not content.has_card_definition(card_definition_id):
		push_error("Missing card definition: %s" % card_definition_id)
		return null

	var parent_card: CardInstance = state.get_card(parent_card_id)
	if parent_card == null:
		return null

	var existing_attachment: CardInstance = _find_attachment(parent_card_id, attachment_slot)
	if existing_attachment != null:
		return existing_attachment

	var stack: StackState = _get_existing_stack(parent_card.stack_id)
	var card: CardInstance = CardInstance.new()
	card.instance_id = _create_card_instance_id()
	card.definition_id = card_definition_id
	card.stack_id = stack.stack_id
	card.parent_card_id = parent_card_id
	card.attachment_slot = attachment_slot
	card.position = parent_card.position
	card.created_at_sprint = state.sprint_index
	var definition: CardDefinition = content.get_card_definition(card_definition_id)
	if definition != null:
		card.values = definition.base_values.duplicate(true)
	_product_lifecycle.ensure_card_defaults(card, _get_mvp_required_features())

	var parent_index: int = stack.card_ids.find(parent_card_id)
	if parent_index < 0 or parent_index == stack.card_ids.size() - 1:
		stack.card_ids.append(card.instance_id)
	else:
		stack.card_ids.insert(parent_index + 1, card.instance_id)
	state.cards[card.instance_id] = card
	_refresh_attachment_runtime_states()

	_emit(SimulationEvent.card_spawned(card.instance_id, stack.stack_id, card.definition_id))
	_emit(SimulationEvent.stack_changed(stack.stack_id))
	_refresh_stack_recipe_if_present(stack.stack_id)
	return card

func _remove_card_instance(card_id: String) -> void:
	var card: CardInstance = state.get_card(card_id)
	if card == null:
		return

	var attached_card_ids: PackedStringArray = _get_attachment_ids(card_id)
	for attached_card_id: String in attached_card_ids:
		_remove_card_instance(attached_card_id)

	var stack_id: String = card.stack_id
	if state.stacks.has(stack_id):
		var stack: StackState = _get_existing_stack(stack_id)
		_remove_card_from_stack(stack, card_id)
		_emit(SimulationEvent.stack_changed(stack.stack_id))
		_delete_stack_if_empty(stack)

	state.cards.erase(card_id)
	_refresh_attachment_runtime_states()
	var event: SimulationEvent = SimulationEvent.new()
	event.type = ScopeEnums.SimulationEventType.CARD_REMOVED
	event.card_id = card_id
	event.card_definition_id = card.definition_id
	event.stack_id = stack_id
	_emit(event)

func _get_productive_employee_ids(stack: StackState, recipe: RecipeDefinition) -> PackedStringArray:
	var employee_ids: PackedStringArray = PackedStringArray()
	if recipe == null or _recipe_uses_burnout(recipe) or _recipe_uses_employee_blocker(recipe):
		return employee_ids

	for card_id: String in stack.card_ids:
		var card: CardInstance = state.get_card(card_id)
		if card == null:
			continue
		var definition: CardDefinition = content.get_card_definition(card.definition_id)
		if definition != null and definition.tags.has("employee"):
			employee_ids.append(card.instance_id)
	return employee_ids

func _recipe_uses_burnout(recipe: RecipeDefinition) -> bool:
	for input: RecipeInputMatcher in recipe.inputs:
		if input.card_definition_id == "card.problem.burnout" or input.required_tags.has("burnout"):
			return true
	return false

func _recipe_uses_employee_blocker(recipe: RecipeDefinition) -> bool:
	for input: RecipeInputMatcher in recipe.inputs:
		if input.required_tags.has("employee_blocker") or input.card_definition_id == "card.blocker.onboarding":
			return true
	return false

func _apply_burnout_risk(employee_ids: PackedStringArray) -> void:
	if employee_ids.is_empty():
		return
	var increment: float = _get_burnout_increment()
	if increment <= 0.0:
		return

	_rng.state = state.rng_state
	for employee_id: String in employee_ids:
		var employee: CardInstance = state.get_card(employee_id)
		if employee == null or _has_attachment(employee.instance_id, BURNOUT_ATTACHMENT_SLOT):
			continue
		if _is_temp_worker(employee):
			continue
		var burnout_progress: float = clampf(float(employee.values.get(BURNOUT_PROGRESS_VALUE, 0.0)) + increment, 0.0, 1.0)
		employee.values[BURNOUT_PROGRESS_VALUE] = burnout_progress
		if _rng.randf() <= burnout_progress:
			employee.values[BURNOUT_PROGRESS_VALUE] = 0.0
			_spawn_attached_card(employee.instance_id, "card.problem.burnout", BURNOUT_ATTACHMENT_SLOT)
	state.rng_state = _rng.state
	_refresh_attachment_runtime_states()

func _consume_one_task_lifetime_workers(employee_ids: PackedStringArray) -> void:
	for employee_id: String in employee_ids:
		var employee: CardInstance = state.get_card(employee_id)
		if employee == null or not _has_definition_tag(employee, "one_task_lifetime"):
			continue
		var remaining_tasks: int = int(employee.values.get(COMPLETED_TASK_LIFETIME_VALUE, _get_default_completed_task_lifetime()))
		remaining_tasks -= 1
		employee.values[COMPLETED_TASK_LIFETIME_VALUE] = remaining_tasks
		if remaining_tasks <= 0:
			_remove_card_instance(employee.instance_id)

func _get_default_completed_task_lifetime() -> int:
	if content.balance == null:
		return 1
	return maxi(1, content.balance.poc4_work_student_completed_task_lifetime)

func _is_temp_worker(card: CardInstance) -> bool:
	return _has_definition_tag(card, "temp_worker")

func _has_definition_tag(card: CardInstance, tag: String) -> bool:
	var definition: CardDefinition = content.get_card_definition(card.definition_id)
	return definition != null and definition.tags.has(tag)

func _get_burnout_increment() -> float:
	if content.balance == null:
		return 0.1
	return content.balance.burnout_increment_per_completed_work

func _find_attachment(parent_card_id: String, attachment_slot: String) -> CardInstance:
	for card: CardInstance in state.cards.values():
		if card.parent_card_id == parent_card_id and card.attachment_slot == attachment_slot:
			return card
	return null

func _has_attachment(parent_card_id: String, attachment_slot: String) -> bool:
	return _find_attachment(parent_card_id, attachment_slot) != null

func _get_attachment_ids(parent_card_id: String) -> PackedStringArray:
	var attachment_ids: PackedStringArray = PackedStringArray()
	for card: CardInstance in state.cards.values():
		if card.parent_card_id == parent_card_id:
			attachment_ids.append(card.instance_id)
	return attachment_ids

func _refresh_attachment_runtime_states() -> void:
	for card: CardInstance in state.cards.values():
		if card.state == null:
			card.state = CardRuntimeState.new()
		if not card.parent_card_id.is_empty():
			card.state.is_locked = true
			continue
		if card.state.is_locked:
			card.state.is_locked = false
		if not _is_employee_card(card):
			continue
		var markers: PackedStringArray = PackedStringArray()
		if _has_attachment(card.instance_id, BURNOUT_ATTACHMENT_SLOT):
			markers.append("BO")
		if _has_attachment(card.instance_id, ONBOARDING_ATTACHMENT_SLOT):
			markers.append("ON")
		card.state.markers = markers

func _create_stack(position: Vector2) -> StackState:
	var stack: StackState = StackState.new()
	stack.stack_id = _create_stack_id()
	stack.base_position = position
	state.stacks[stack.stack_id] = stack
	return stack

func _remove_card_from_stack(stack: StackState, card_id: String) -> void:
	var index: int = stack.card_ids.find(card_id)
	if index >= 0:
		stack.card_ids.remove_at(index)

func _delete_stack_if_empty(stack: StackState) -> void:
	if stack.card_ids.is_empty():
		state.stacks.erase(stack.stack_id)

func _get_spawn_position_near_stack(source_stack_id: String, spawn_index: int = 0) -> Vector2:
	return _spawn_placement.get_spawn_position_near_stack(source_stack_id, spawn_index)

func _get_booster_spawn_position_near_stack(source_stack_id: String) -> Vector2:
	return _spawn_placement.get_booster_spawn_position_near_stack(source_stack_id)

func _prune_stale_spawn_history() -> void:
	_spawn_placement.prune_stale_spawn_history()

func _is_shop_stack(stack: StackState) -> bool:
	return _spawn_placement.is_shop_stack(stack)

func _get_sprint_duration() -> float:
	if content.balance == null:
		return 60.0
	return content.balance.sprint_duration_seconds

func _get_existing_card(card_id: String) -> CardInstance:
	var card: CardInstance = state.get_card(card_id)
	assert(card != null, "Missing card instance: %s" % card_id)
	return card

func _get_existing_stack(stack_id: String) -> StackState:
	var stack: StackState = state.get_stack(stack_id)
	assert(stack != null, "Missing stack: %s" % stack_id)
	return stack

func _require_state() -> void:
	assert(state != null, "RunController.start_new_run must be called first.")

func _create_card_instance_id() -> String:
	var id: String = "card_%04d" % _next_card_index
	_next_card_index += 1
	return id

func _create_stack_id() -> String:
	var id: String = "stack_%04d" % _next_stack_index
	_next_stack_index += 1
	return id

func _sync_next_runtime_ids() -> void:
	_next_card_index = 1
	_next_stack_index = 1
	for card_id: String in state.cards.keys():
		_next_card_index = maxi(_next_card_index, _get_index_after_runtime_id(card_id, "card_"))
	for stack_id: String in state.stacks.keys():
		_next_stack_index = maxi(_next_stack_index, _get_index_after_runtime_id(stack_id, "stack_"))

func _get_index_after_runtime_id(id: String, prefix: String) -> int:
	if not id.begins_with(prefix):
		return 1
	var suffix: String = id.substr(prefix.length())
	if not suffix.is_valid_int():
		return 1
	return int(suffix) + 1

func _emit(event: SimulationEvent) -> void:
	pending_events.append(event)

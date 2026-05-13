class_name RunController
extends RefCounted

const SPRINT_TIMER_ID: String = "sprint_remaining_seconds"
const SPAWN_CARD_SIZE: Vector2 = Vector2(144.0, 196.0)
const SPAWN_GAP: float = 36.0
const SPAWN_BOARD_MARGIN: float = 56.0
const SPAWN_SEARCH_RINGS: int = 7
const INVALID_SPAWN_POSITION: Vector2 = Vector2(100000000.0, 100000000.0)
const START_LAYOUT_ORIGIN: Vector2 = Vector2(420.0, 322.0)
const START_LAYOUT_COLUMNS: int = 6
const START_LAYOUT_STEP: Vector2 = Vector2(192.0, 240.0)
const DEFAULT_BOOSTER_DEFINITION_ID: String = "booster.founder.test_pack"
const CONTENT_VERSION: String = "poc5"
const BOOSTER_DEFINITION_ID_VALUE: String = "booster_definition_id"
const BOOSTER_REMAINING_CARD_IDS_VALUE: String = "booster_remaining_card_ids"
const BOOSTER_PACK_DEFINITION_ID: String = "card.resource.booster_pack"
const BUGFIX_PATCH_DEFINITION_ID: String = "card.consumable.bugfix_patch"
const RECYCLING_BIN_DEFINITION_ID: String = "card.shop.recycling_bin"
const RECYCLABLE_TAG: String = "recyclable"
const RECYCLING_CARD_COUNT: int = 3
const BURNOUT_ATTACHMENT_SLOT: String = "burnout"
const UNHAPPY_CUSTOMER_ATTACHMENT_SLOT: String = "unhappy_customer"
const ONBOARDING_ATTACHMENT_SLOT: String = "onboarding"
const BURNOUT_PROGRESS_VALUE: String = "burnout_progress"
const SALARY_DUE_FROM_SPRINT_VALUE: String = "salary_due_from_sprint"
const COMPLETED_TASK_LIFETIME_VALUE: String = "completed_task_lifetime"
const ONBOARDING_RECIPE_ID: String = "recipe.onboarding.employee"
const RECRUITER_ONBOARDING_MODIFIER_KEY: String = "recruiter_onboarding"
const FREELANCE_SLOT_DEFINITION_ID: String = "card.shop.freelance_order"
const CUSTOMER_DEFINITION_ID: String = "card.value_source.customer"
const CUSTOMER_REQUEST_DEFINITION_ID: String = "card.input.customer_request"
const MONEY_DEFINITION_ID: String = "card.resource.money"
const FEATURE_DEFINITION_ID: String = "card.output.feature"
const CHECKED_FEATURE_DEFINITION_ID: String = "card.output.checked_feature"
const BUG_DEFINITION_ID: String = "card.problem.bug"
const UNHAPPY_CUSTOMER_DEFINITION_ID: String = "card.problem.unhappy_customer"
const BUSINESS_GOAL_DEFINITION_ID: String = "card.goal.business_goal"
const INVESTOR_PANIC_DEFINITION_ID: String = "card.problem.investor_panic"
const START_CHECKED_FEATURE_CARD_COUNT: int = 0
const ActiveProcessingInteractionServiceScript: Script = preload("res://scripts/simulation/active_processing_interaction_service.gd")
const ProductLifecycleServiceScript: Script = preload("res://scripts/simulation/product_lifecycle_service.gd")
const START_CARD_IDS: Array[String] = [
	"card.product.software",
	"card.employee.developer",
	"card.input.idea",
	"card.consumable.coffee",
	"card.shop.freelance_order",
	"card.shop.booster_slot",
	"card.resource.money",
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

	for index: int in START_CARD_IDS.size():
		var column: int = index % START_LAYOUT_COLUMNS
		var row: int = floori(float(index) / float(START_LAYOUT_COLUMNS))
		var position: Vector2 = START_LAYOUT_ORIGIN + Vector2(float(column), float(row)) * START_LAYOUT_STEP
		var card_definition_id: String = START_CARD_IDS[index]
		if card_definition_id == MONEY_DEFINITION_ID:
			for money_index: int in _get_start_money_card_count():
				_spawn_card_as_new_stack(MONEY_DEFINITION_ID, position)
		else:
			_spawn_card_as_new_stack(card_definition_id, position)

	for checked_feature_index: int in START_CHECKED_FEATURE_CARD_COUNT:
		var layout_index: int = START_CARD_IDS.size() + checked_feature_index
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
	if _try_buy_shop_with_money_stack(card, moving_card_ids, target_stack):
		return
	if _try_recycle_card_stack(moving_card_ids, target_stack):
		return
	if _try_dump_freelance_feature_stack(moving_card_ids, target_stack):
		return
	if _try_hire_offer_with_money_stack(card, moving_card_ids, target_stack):
		return
	if _try_pay_employee_with_money(card, moving_card_ids, target_stack):
		return
	if _try_pay_business_goal_with_money(card, moving_card_ids, target_stack):
		return
	if not _can_interact_with_board():
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
	if not _can_interact_with_board():
		return false
	if not _is_money_card(card):
		return false
	if not _are_all_money_cards(moving_card_ids):
		return false

	var target_shop_card: CardInstance = _find_shop_card_in_stack(target_stack)
	if target_shop_card == null:
		return false
	var purchase: Dictionary = _get_shop_purchase(target_shop_card)
	if purchase.is_empty():
		return false

	var cost_money_cards: int = purchase["cost_money_cards"] as int
	if moving_card_ids.size() < cost_money_cards:
		return false

	var consumed_money_ids: PackedStringArray = PackedStringArray()
	var leftover_money_ids: PackedStringArray = PackedStringArray()
	for index: int in moving_card_ids.size():
		if index < cost_money_cards:
			consumed_money_ids.append(moving_card_ids[index])
		else:
			leftover_money_ids.append(moving_card_ids[index])

	for consumed_money_id: String in consumed_money_ids:
		_consume_money_card(consumed_money_id)

	var spawned_card_definition_id: String = purchase["spawned_card_definition_id"] as String
	var spawned_card: CardInstance = _spawn_card_as_new_stack(spawned_card_definition_id, _get_spawn_position_near_stack(target_stack.stack_id, 0))
	if spawned_card != null:
		var copied_values: Dictionary = purchase.get("values", {}) as Dictionary
		for key: Variant in copied_values.keys():
			spawned_card.values[key] = copied_values[key]

	if not leftover_money_ids.is_empty():
		_move_existing_cards_to_new_stack(leftover_money_ids, _get_spawn_position_near_stack(target_stack.stack_id, 1))

	_emit(SimulationEvent.stack_changed(target_stack.stack_id))
	return true

func _try_recycle_card_stack(moving_card_ids: PackedStringArray, target_stack: StackState) -> bool:
	if not _can_interact_with_board():
		return false

	var target_shop_card: CardInstance = _find_shop_card_in_stack(target_stack)
	if target_shop_card == null or not _is_recycling_bin_card(target_shop_card):
		return false
	if moving_card_ids.size() < RECYCLING_CARD_COUNT:
		return false
	if not _are_all_recyclable_cards(moving_card_ids):
		return false

	var consumed_card_ids: PackedStringArray = PackedStringArray()
	var leftover_card_ids: PackedStringArray = PackedStringArray()
	var first_consumed_index: int = moving_card_ids.size() - RECYCLING_CARD_COUNT
	for index: int in moving_card_ids.size():
		if index >= first_consumed_index:
			consumed_card_ids.append(moving_card_ids[index])
		else:
			leftover_card_ids.append(moving_card_ids[index])

	for consumed_card_id: String in consumed_card_ids:
		_remove_card_instance(consumed_card_id)

	_spawn_card_as_new_stack(MONEY_DEFINITION_ID, _get_spawn_position_near_stack(target_stack.stack_id, 0))

	if not leftover_card_ids.is_empty():
		_move_existing_cards_to_new_stack(leftover_card_ids, _get_spawn_position_near_stack(target_stack.stack_id, 1))

	_emit(SimulationEvent.stack_changed(target_stack.stack_id))
	return true

func _try_dump_freelance_feature_stack(moving_card_ids: PackedStringArray, target_stack: StackState) -> bool:
	if not _can_interact_with_board():
		return false

	var target_shop_card: CardInstance = _find_shop_card_in_stack(target_stack)
	if target_shop_card == null or target_shop_card.definition_id != FREELANCE_SLOT_DEFINITION_ID:
		return false
	if not _are_all_freelance_feature_cards(moving_card_ids):
		return false

	var spawn_index: int = 0
	_rng.state = state.rng_state
	for moving_card_id: String in moving_card_ids:
		var moving_card: CardInstance = state.get_card(moving_card_id)
		if moving_card == null:
			continue
		var is_unchecked_feature: bool = moving_card.definition_id == FEATURE_DEFINITION_ID
		var money_card_count: int = _get_freelance_money_card_count()
		_remove_card_instance(moving_card_id)
		for money_index: int in money_card_count:
			_spawn_card_as_new_stack(MONEY_DEFINITION_ID, _get_spawn_position_near_stack(target_stack.stack_id, spawn_index))
			spawn_index += 1
		if is_unchecked_feature and _rng.randf() <= _get_bug_chance():
			_spawn_card_as_new_stack(BUG_DEFINITION_ID, _get_spawn_position_near_stack(target_stack.stack_id, spawn_index))
			spawn_index += 1
	state.rng_state = _rng.state

	_emit(SimulationEvent.stack_changed(target_stack.stack_id))
	return true

func _are_all_money_cards(card_ids: PackedStringArray) -> bool:
	if card_ids.is_empty():
		return false
	for card_id: String in card_ids:
		var card: CardInstance = state.get_card(card_id)
		if card == null or not _is_money_card(card):
			return false
	return true

func _are_all_recyclable_cards(card_ids: PackedStringArray) -> bool:
	if card_ids.is_empty():
		return false
	for card_id: String in card_ids:
		var card: CardInstance = state.get_card(card_id)
		if card == null or not _is_recyclable_card(card):
			return false
	return true

func _are_all_freelance_feature_cards(card_ids: PackedStringArray) -> bool:
	if card_ids.is_empty():
		return false
	for card_id: String in card_ids:
		var card: CardInstance = state.get_card(card_id)
		if card == null or not _is_freelance_feature_card(card):
			return false
	return true

func _find_shop_card_in_stack(stack: StackState) -> CardInstance:
	for card_id: String in stack.card_ids:
		var card: CardInstance = state.get_card(card_id)
		if card == null:
			continue
		var definition: CardDefinition = content.get_card_definition(card.definition_id)
		if definition != null and definition.tags.has("shop"):
			return card
	return null

func _is_recycling_bin_card(card: CardInstance) -> bool:
	return card != null and card.definition_id == RECYCLING_BIN_DEFINITION_ID

func _is_recyclable_card(card: CardInstance) -> bool:
	if card == null:
		return false
	if not card.parent_card_id.is_empty():
		return false
	var definition: CardDefinition = content.get_card_definition(card.definition_id)
	return definition != null and definition.tags.has(RECYCLABLE_TAG)

func _is_freelance_feature_card(card: CardInstance) -> bool:
	if card == null:
		return false
	if not card.parent_card_id.is_empty():
		return false
	return card.definition_id == FEATURE_DEFINITION_ID or card.definition_id == CHECKED_FEATURE_DEFINITION_ID

func _get_shop_purchase(shop_card: CardInstance) -> Dictionary:
	var definition: CardDefinition = content.get_card_definition(shop_card.definition_id)
	if definition == null:
		return {}

	var booster_id: String = shop_card.values.get(BOOSTER_DEFINITION_ID_VALUE, "") as String
	if booster_id.is_empty():
		booster_id = definition.base_values.get(BOOSTER_DEFINITION_ID_VALUE, "") as String
	if not booster_id.is_empty():
		var booster: BoosterDefinition = content.get_booster_definition(booster_id)
		if booster == null:
			return {}
		return {
			"cost_money_cards": maxi(1, booster.cost_money_cards),
			"spawned_card_definition_id": BOOSTER_PACK_DEFINITION_ID,
			"values": {BOOSTER_DEFINITION_ID_VALUE: booster_id},
		}

	if definition.tags.has("bugfix_patch_slot"):
		return {
			"cost_money_cards": 1,
			"spawned_card_definition_id": BUGFIX_PATCH_DEFINITION_ID,
			"values": {},
		}

	return {}

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

	_spawn_card_as_new_stack(spawned_card_definition_id, _get_spawn_position_near_stack(booster_pack.stack_id, 0))
	if remaining_card_ids.is_empty():
		_remove_card_instance(booster_pack.instance_id)
	else:
		_emit(SimulationEvent.stack_changed(booster_pack.stack_id))
	return true

func start_next_sprint() -> void:
	_require_state()
	if state.phase != ScopeEnums.RunPhase.PAYMENT:
		return

	_quit_unpaid_employees()
	if _has_no_employees():
		_enter_game_over()
		return

	state.sprint_index += 1
	_run_sprint_start_effects()
	if state.phase == ScopeEnums.RunPhase.GAME_OVER or state.phase == ScopeEnums.RunPhase.VICTORY:
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
	if state.phase != ScopeEnums.RunPhase.PAYMENT:
		return false
	if moving_card_ids.size() != 1:
		return false
	if not _is_money_card(card):
		return false

	var employee_id: String = _find_unpaid_employee_in_stack(target_stack)
	if employee_id.is_empty():
		return false

	if not _consume_money_card(card.instance_id):
		return false
	_mark_employee_paid(employee_id)
	_refresh_payment_card_states()
	_emit(SimulationEvent.stack_changed(target_stack.stack_id))
	return true

func _try_hire_offer_with_money_stack(card: CardInstance, moving_card_ids: PackedStringArray, target_stack: StackState) -> bool:
	if not _can_interact_with_board():
		return false
	if not _is_money_card(card):
		return false
	if not _are_all_money_cards(moving_card_ids):
		return false
	var offer: CardInstance = _find_offer_in_stack(target_stack)
	if offer == null:
		return false
	var offer_definition: CardDefinition = content.get_card_definition(offer.definition_id)
	if offer_definition == null:
		return false
	var target_employee_definition_id: String = offer.values.get("target_employee_card_definition_id", "") as String
	if target_employee_definition_id.is_empty():
		target_employee_definition_id = offer_definition.base_values.get("target_employee_card_definition_id", "") as String
	if target_employee_definition_id.is_empty() or not content.has_card_definition(target_employee_definition_id):
		return false

	var hire_cost: int = _get_offer_hire_cost_money_cards()
	if moving_card_ids.size() < hire_cost:
		return false

	var spawn_position: Vector2 = _get_spawn_position_near_stack(target_stack.stack_id, 0)
	var leftover_position: Vector2 = _get_spawn_position_near_stack(target_stack.stack_id, 1)
	var consumed_money_ids: PackedStringArray = PackedStringArray()
	var leftover_money_ids: PackedStringArray = PackedStringArray()
	for index: int in moving_card_ids.size():
		if index < hire_cost:
			consumed_money_ids.append(moving_card_ids[index])
		else:
			leftover_money_ids.append(moving_card_ids[index])

	for consumed_money_id: String in consumed_money_ids:
		_consume_money_card(consumed_money_id)
	_remove_card_instance(offer.instance_id)

	var employee: CardInstance = _spawn_card_as_new_stack(target_employee_definition_id, spawn_position)
	if employee != null:
		employee.values[SALARY_DUE_FROM_SPRINT_VALUE] = _get_salary_due_from_sprint_for_new_hire()
		_spawn_attached_card(employee.instance_id, "card.blocker.onboarding", ONBOARDING_ATTACHMENT_SLOT)

	if not leftover_money_ids.is_empty():
		_move_existing_cards_to_new_stack(leftover_money_ids, leftover_position)

	_refresh_payment_card_states()
	return true

func _try_pay_business_goal_with_money(card: CardInstance, moving_card_ids: PackedStringArray, target_stack: StackState) -> bool:
	if not _is_money_card(card):
		return false
	for moving_card_id: String in moving_card_ids:
		var moving_card: CardInstance = state.get_card(moving_card_id)
		if moving_card == null or not _is_money_card(moving_card):
			return false

	var goal: CardInstance = _find_business_goal_in_stack(target_stack)
	if goal == null:
		return false

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

func _run_sprint_start_effects() -> void:
	_form_prod_crashes_from_bugs()
	_duplicate_remaining_bugs()
	_expire_open_orders()
	_expire_unused_external_devs()
	_attach_unhappy_customers_from_old_requests()
	_resolve_active_business_goal()
	if state.phase == ScopeEnums.RunPhase.GAME_OVER or state.phase == ScopeEnums.RunPhase.VICTORY:
		return
	_spawn_persistent_tick_cards()

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
		var spawner_definition: CardDefinition = content.get_card_definition(spawner.definition_id)
		if spawner_definition != null and spawner_definition.tags.has("customer"):
			_spawn_customer_tick_cards(spawner)
			continue
		var spawned_card_definition_id: String = spawner.values.get("sprint_tick_spawn_card_id", "") as String
		if spawned_card_definition_id.is_empty():
			continue
		_spawn_card_as_new_stack(spawned_card_definition_id, _get_spawn_position_near_stack(spawner.stack_id, 0))

func _spawn_customer_tick_cards(customer: CardInstance) -> void:
	var software: CardInstance = get_software_card()
	if software == null:
		return
	if _product_lifecycle.get_product_stage(software) != ProductLifecycleService.PRODUCT_STAGE_LIVE:
		return
	if _has_attachment(customer.instance_id, UNHAPPY_CUSTOMER_ATTACHMENT_SLOT):
		return
	if _has_card_with_tag("prod_crash"):
		_spawn_attached_card(customer.instance_id, UNHAPPY_CUSTOMER_DEFINITION_ID, UNHAPPY_CUSTOMER_ATTACHMENT_SLOT)
		return

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

func _find_offer_in_stack(stack: StackState) -> CardInstance:
	if stack == null:
		return null
	for card_id: String in stack.card_ids:
		var card: CardInstance = state.get_card(card_id)
		if card != null and _is_offer_card(card):
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

func _get_freelance_money_card_count() -> int:
	if content.balance == null:
		return 3
	return maxi(0, content.balance.poc3_freelance_dump_money_cards)

func _get_bug_chance() -> float:
	if content.balance == null:
		return 0.5
	return clampf(content.balance.bug_chance, 0.0, 1.0)

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

func _has_card_with_tag(tag: String) -> bool:
	return not _find_card_ids_with_tag(tag).is_empty()

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

func _is_offer_card(card: CardInstance) -> bool:
	var definition: CardDefinition = content.get_card_definition(card.definition_id)
	return definition != null and definition.tags.has("offer")

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
	var temporary_source_stack: StackState = _create_stack(source_position)
	var spawn_position: Vector2 = _get_spawn_position_near_stack(temporary_source_stack.stack_id, spawn_index)
	state.stacks.erase(temporary_source_stack.stack_id)
	return spawn_position

func _find_auto_stack_spawn_target(definition: CardDefinition, position: Vector2) -> StackState:
	if definition == null or not definition.auto_stack_on_spawn:
		return null

	var radius: float = _get_auto_stack_spawn_radius()
	if radius <= 0.0:
		return null

	var best_stack: StackState = null
	var best_distance: float = radius
	for stack: StackState in state.stacks.values():
		if _is_shop_stack(stack):
			continue
		if not _is_pure_stack_for_definition(stack, definition.id):
			continue
		var distance: float = stack.base_position.distance_to(position)
		if distance <= best_distance:
			best_distance = distance
			best_stack = stack
	return best_stack

func _is_pure_stack_for_definition(stack: StackState, card_definition_id: String) -> bool:
	if stack == null or stack.card_ids.is_empty():
		return false

	for card_id: String in stack.card_ids:
		var card: CardInstance = state.get_card(card_id)
		if card == null:
			return false
		if card.definition_id != card_definition_id:
			return false
		if not card.parent_card_id.is_empty():
			return false
	return true

func _get_auto_stack_spawn_radius() -> float:
	if content.balance == null:
		return 180.0
	return content.balance.auto_stack_spawn_radius

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
	_prune_stale_spawn_history()
	var source_position: Vector2 = _get_spawn_source_position(source_stack_id)

	var step_x: float = SPAWN_CARD_SIZE.x + SPAWN_GAP
	var step_y: float = SPAWN_CARD_SIZE.y + SPAWN_GAP
	var candidates: Array[Vector2] = []
	var directions: Array[Vector2] = [
		Vector2.RIGHT,
		Vector2.DOWN,
		Vector2.LEFT,
		Vector2.UP,
		Vector2(1.0, 1.0),
		Vector2(-1.0, 1.0),
		Vector2(1.0, -1.0),
		Vector2(-1.0, -1.0),
	]

	var radius: float = 160.0
	if content.balance != null:
		radius = maxf(radius, content.balance.spawn_placement_radius)
	for ring: int in SPAWN_SEARCH_RINGS:
		var ring_distance: Vector2 = Vector2(radius + float(ring) * step_x, radius + float(ring) * step_y)
		for direction: Vector2 in directions:
			candidates.append(source_position + Vector2(direction.x * ring_distance.x, direction.y * ring_distance.y))

	var spawn_row: int = floori(float(spawn_index) / 4.0)
	var spawn_column: int = spawn_index % 4
	if spawn_index > 0:
		candidates.append(source_position + Vector2(float(spawn_column + 1) * step_x, float(spawn_row) * step_y))

	for candidate: Vector2 in candidates:
		if not _does_spawn_overlap(candidate):
			state.board.spawn_history.append(candidate)
			return candidate

	var grid_position: Vector2 = _find_free_spawn_grid_position(source_position)
	if grid_position != INVALID_SPAWN_POSITION:
		state.board.spawn_history.append(grid_position)
		return grid_position

	var fallback: Vector2 = _clamp_spawn_position_to_board(source_position + Vector2(step_x * float(spawn_index + 1), step_y))
	state.board.spawn_history.append(fallback)
	return fallback

func _prune_stale_spawn_history() -> void:
	if state == null or state.board.spawn_history.is_empty():
		return

	var active_history: Array[Vector2] = []
	for previous_position: Vector2 in state.board.spawn_history:
		if _is_spawn_history_position_occupied(previous_position):
			active_history.append(previous_position)
	state.board.spawn_history = active_history

func _is_spawn_history_position_occupied(position: Vector2) -> bool:
	var history_rect: Rect2 = Rect2(position, SPAWN_CARD_SIZE)
	for stack: StackState in state.stacks.values():
		if _is_shop_stack(stack):
			continue
		if history_rect.intersects(_get_stack_rect(stack)):
			return true
	return false

func _does_spawn_overlap(position: Vector2) -> bool:
	var spawn_rect: Rect2 = Rect2(position, SPAWN_CARD_SIZE)
	if not _get_spawn_bounds().encloses(spawn_rect):
		return true
	for reserved_area: Rect2 in state.board.reserved_areas:
		if spawn_rect.intersects(reserved_area):
			return true
	for previous_position: Vector2 in state.board.spawn_history:
		if spawn_rect.intersects(Rect2(previous_position, SPAWN_CARD_SIZE)):
			return true
	for stack: StackState in state.stacks.values():
		if _is_shop_stack(stack):
			continue
		if spawn_rect.intersects(_get_stack_rect(stack)):
			return true
	return false

func _get_spawn_source_position(source_stack_id: String) -> Vector2:
	if not state.stacks.has(source_stack_id):
		return Vector2.ZERO

	var source_stack: StackState = _get_existing_stack(source_stack_id)
	if _is_shop_stack(source_stack):
		return _get_shop_spawn_source_position()
	return source_stack.base_position

func _get_shop_spawn_source_position() -> Vector2:
	var safe_zoom: float = 1.0
	if state.board.camera_zoom.x > 0.0:
		safe_zoom = state.board.camera_zoom.x
	var visible_size: Vector2 = BoardState.INITIAL_VIEWPORT_SIZE / safe_zoom
	var source_position: Vector2 = state.board.camera_position + Vector2(
		0.0,
		visible_size.y * 0.5 - SPAWN_CARD_SIZE.y - 160.0
	)
	return _clamp_spawn_position_to_board(source_position)

func _is_shop_stack(stack: StackState) -> bool:
	if stack == null:
		return false
	for card_id: String in stack.card_ids:
		var card: CardInstance = state.get_card(card_id)
		if card == null:
			continue
		var definition: CardDefinition = content.get_card_definition(card.definition_id)
		if definition != null and definition.tags.has("shop"):
			return true
	return false

func _get_spawn_bounds() -> Rect2:
	var board_size: Vector2 = state.board.size
	var available_size: Vector2 = Vector2(
		maxf(SPAWN_CARD_SIZE.x, board_size.x - SPAWN_BOARD_MARGIN * 2.0),
		maxf(SPAWN_CARD_SIZE.y, board_size.y - SPAWN_BOARD_MARGIN * 2.0)
	)
	return Rect2(Vector2(SPAWN_BOARD_MARGIN, SPAWN_BOARD_MARGIN), available_size)

func _clamp_spawn_position_to_board(position: Vector2) -> Vector2:
	var bounds: Rect2 = _get_spawn_bounds()
	return Vector2(
		clampf(position.x, bounds.position.x, bounds.end.x - SPAWN_CARD_SIZE.x),
		clampf(position.y, bounds.position.y, bounds.end.y - SPAWN_CARD_SIZE.y)
	)

func _find_free_spawn_grid_position(source_position: Vector2) -> Vector2:
	var bounds: Rect2 = _get_spawn_bounds()
	var step: Vector2 = SPAWN_CARD_SIZE + Vector2(SPAWN_GAP, SPAWN_GAP)
	var column_count: int = maxi(1, floori((bounds.size.x - SPAWN_CARD_SIZE.x) / step.x) + 1)
	var row_count: int = maxi(1, floori((bounds.size.y - SPAWN_CARD_SIZE.y) / step.y) + 1)
	var candidates: Array[Vector2] = []
	for row: int in row_count:
		for column: int in column_count:
			candidates.append(bounds.position + Vector2(float(column) * step.x, float(row) * step.y))

	candidates.sort_custom(func(left: Vector2, right: Vector2) -> bool:
		return left.distance_squared_to(source_position) < right.distance_squared_to(source_position)
	)

	for candidate: Vector2 in candidates:
		if not _does_spawn_overlap(candidate):
			return candidate
	return INVALID_SPAWN_POSITION

func _get_stack_rect(stack: StackState) -> Rect2:
	if stack.card_ids.is_empty():
		return Rect2(stack.base_position, SPAWN_CARD_SIZE)

	var stack_offset: Vector2 = Vector2(0.0, 40.0)
	if content.balance != null:
		stack_offset = content.balance.stack_offset
	var bottom_position: Vector2 = stack.base_position + stack_offset * float(stack.card_ids.size() - 1)
	var min_position: Vector2 = Vector2(
		minf(stack.base_position.x, bottom_position.x),
		minf(stack.base_position.y, bottom_position.y)
	)
	var max_position: Vector2 = Vector2(
		maxf(stack.base_position.x + SPAWN_CARD_SIZE.x, bottom_position.x + SPAWN_CARD_SIZE.x),
		maxf(stack.base_position.y + SPAWN_CARD_SIZE.y, bottom_position.y + SPAWN_CARD_SIZE.y)
	)
	return Rect2(min_position, max_position - min_position)

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

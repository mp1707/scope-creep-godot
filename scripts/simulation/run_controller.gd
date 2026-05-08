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
const CONTENT_VERSION: String = "poc2"
const BOOSTER_DEFINITION_ID_VALUE: String = "booster_definition_id"
const BOOSTER_REMAINING_CARD_IDS_VALUE: String = "booster_remaining_card_ids"
const BURNOUT_ATTACHMENT_SLOT: String = "burnout"
const BURNOUT_PROGRESS_VALUE: String = "burnout_progress"
const START_CARD_IDS: Array[String] = [
	"card.product.software",
	"card.employee.developer",
	"card.input.idea",
	"card.consumable.coffee",
	"card.shop.booster_slot",
	"card.shop.booster_slot.talent_pool",
	"card.shop.booster_slot.office_invest",
	"card.shop.booster_slot.customer_chaos",
	"card.shop.bugfix_patch_slot",
	"card.resource.money",
	"card.resource.money",
	"card.resource.money",
]

var content: ContentCatalog = null
var state: RunState = null
var pending_events: Array[SimulationEvent] = []
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _recipe_engine: RecipeEngine = RecipeEngine.new()
var _effect_pipeline: EffectPipeline = EffectPipeline.new()
var _tech_debt_modifiers: TechDebtModifierService = TechDebtModifierService.new()
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
		_spawn_card_as_new_stack(START_CARD_IDS[index], position)

	_emit(SimulationEvent.phase_changed(state.phase))
	_emit(SimulationEvent.timer_updated(SPRINT_TIMER_ID, state.active_timers[SPRINT_TIMER_ID] as float))
	return state

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
		stack.processing_state.elapsed += delta_seconds
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
	if _try_pay_employee_with_money(card, moving_card_ids, target_stack):
		return
	if not _can_interact_with_board():
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
		var spawned_card_definition_id: String = spawner.values.get("sprint_tick_spawn_card_id", "") as String
		if spawned_card_definition_id.is_empty():
			continue
		_spawn_card_as_new_stack(spawned_card_definition_id, _get_spawn_position_near_stack(spawner.stack_id, 0))

func _find_card_ids_with_tag(tag: String) -> PackedStringArray:
	var card_ids: PackedStringArray = PackedStringArray()
	for card: CardInstance in state.cards.values():
		var definition: CardDefinition = content.get_card_definition(card.definition_id)
		if definition != null and definition.tags.has(tag):
			card_ids.append(card.instance_id)
	return card_ids

func _has_no_employees() -> bool:
	for card: CardInstance in state.cards.values():
		if _is_employee_card(card):
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

func _requires_salary(card: CardInstance) -> bool:
	var definition: CardDefinition = content.get_card_definition(card.definition_id)
	return definition != null and definition.type == ScopeEnums.CardType.EMPLOYEE and not definition.tags.has("external_dev")

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
		if current_recipe_id == matched_recipe_id:
			return
		_cancel_processing(stack)

	if match_result.recipe != null:
		_start_processing(stack, match_result.recipe)

func _start_processing(stack: StackState, recipe: RecipeDefinition) -> void:
	stack.processing_state.active_recipe_id = recipe.id
	stack.processing_state.status = ScopeEnums.ProcessingStatus.ACTIVE
	stack.processing_state.elapsed = 0.0
	stack.processing_state.duration = _tech_debt_modifiers.get_duration_seconds(recipe, state, content)
	_emit(SimulationEvent.recipe_started(stack.stack_id))
	_emit(SimulationEvent.stack_changed(stack.stack_id))

func _cancel_processing(stack: StackState) -> void:
	_clear_processing(stack)
	_emit(SimulationEvent.recipe_cancelled(stack.stack_id))
	_emit(SimulationEvent.stack_changed(stack.stack_id))

func _complete_processing(stack: StackState) -> void:
	var recipe: RecipeDefinition = content.get_recipe_definition(stack.processing_state.active_recipe_id)
	var productive_employee_ids: PackedStringArray = _get_productive_employee_ids(stack, recipe)
	_clear_processing(stack)
	if recipe == null:
		_emit(SimulationEvent.stack_changed(stack.stack_id))
		return

	_execute_effects(recipe.effects_on_complete, stack, recipe)
	_apply_burnout_risk(productive_employee_ids)
	_emit(SimulationEvent.recipe_completed(stack.stack_id))
	if state.stacks.has(stack.stack_id):
		_delete_stack_if_empty(stack)
		_refresh_stack_recipe_if_present(stack.stack_id)

func _clear_processing(stack: StackState) -> void:
	stack.processing_state.active_recipe_id = ""
	stack.processing_state.status = ScopeEnums.ProcessingStatus.IDLE
	stack.processing_state.elapsed = 0.0
	stack.processing_state.duration = 0.0

func _execute_effects(effects: Array[EffectDefinition], stack: StackState, recipe: RecipeDefinition) -> void:
	_rng.state = state.rng_state
	var context: EffectContext = EffectContext.new()
	context.state = state
	context.stack = stack
	context.recipe = recipe
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

	var stack: StackState = _create_stack(position)
	var card: CardInstance = CardInstance.new()
	card.instance_id = _create_card_instance_id()
	card.definition_id = card_definition_id
	card.stack_id = stack.stack_id
	card.position = position
	card.created_at_sprint = state.sprint_index
	var definition: CardDefinition = content.get_card_definition(card_definition_id)
	if definition != null:
		card.values = definition.base_values.duplicate(true)
	stack.card_ids.append(card.instance_id)
	state.cards[card.instance_id] = card

	_emit(SimulationEvent.card_spawned(card.instance_id, stack.stack_id))
	_emit(SimulationEvent.stack_changed(stack.stack_id))
	return card

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

	var parent_index: int = stack.card_ids.find(parent_card_id)
	if parent_index < 0 or parent_index == stack.card_ids.size() - 1:
		stack.card_ids.append(card.instance_id)
	else:
		stack.card_ids.insert(parent_index + 1, card.instance_id)
	state.cards[card.instance_id] = card
	_refresh_attachment_runtime_states()

	_emit(SimulationEvent.card_spawned(card.instance_id, stack.stack_id))
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
	event.stack_id = stack_id
	_emit(event)

func _get_productive_employee_ids(stack: StackState, recipe: RecipeDefinition) -> PackedStringArray:
	var employee_ids: PackedStringArray = PackedStringArray()
	if recipe == null or _recipe_uses_burnout(recipe):
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
		var burnout_progress: float = clampf(float(employee.values.get(BURNOUT_PROGRESS_VALUE, 0.0)) + increment, 0.0, 1.0)
		employee.values[BURNOUT_PROGRESS_VALUE] = burnout_progress
		if _rng.randf() <= burnout_progress:
			employee.values[BURNOUT_PROGRESS_VALUE] = 0.0
			_spawn_attached_card(employee.instance_id, "card.problem.burnout", BURNOUT_ATTACHMENT_SLOT)
	state.rng_state = _rng.state
	_refresh_attachment_runtime_states()

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

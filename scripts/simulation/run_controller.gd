class_name RunController
extends RefCounted

const SPRINT_TIMER_ID: String = "sprint_remaining_seconds"
const START_CARD_IDS: Array[String] = [
	"card.product.software",
	"card.employee.developer",
	"card.input.idea",
	"card.consumable.coffee",
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
var _next_card_index: int = 1
var _next_stack_index: int = 1

func _init(content_catalog: ContentCatalog = null) -> void:
	content = content_catalog
	if content == null:
		content = ContentCatalog.new()
		content.load_default_content()

func start_new_run(seed: int = 1) -> RunState:
	pending_events.clear()
	_next_card_index = 1
	_next_stack_index = 1

	state = RunState.new()
	state.run_id = "run_%d" % seed
	state.sprint_index = 1
	state.phase = ScopeEnums.RunPhase.SPRINT
	state.is_paused = false
	state.rng_seed = seed
	_rng.seed = seed
	state.rng_state = _rng.state
	state.content_version = "poc"
	state.active_timers[SPRINT_TIMER_ID] = _get_sprint_duration()

	var position: Vector2 = Vector2(160.0, 160.0)
	for card_definition_id: String in START_CARD_IDS:
		_spawn_card_as_new_stack(card_definition_id, position)
		position.x += 180.0

	_emit(SimulationEvent.phase_changed(state.phase))
	_emit(SimulationEvent.timer_updated(SPRINT_TIMER_ID, state.active_timers[SPRINT_TIMER_ID] as float))
	return state

func drain_events() -> Array[SimulationEvent]:
	var events: Array[SimulationEvent] = pending_events.duplicate()
	pending_events.clear()
	return events

func set_paused(paused: bool) -> void:
	_require_state()
	if state.is_paused == paused:
		return
	state.is_paused = paused
	_emit(SimulationEvent.pause_changed(paused))

func advance_time(delta_seconds: float) -> void:
	_require_state()
	if state.is_paused:
		return

	var remaining: float = state.active_timers.get(SPRINT_TIMER_ID, 0.0) as float
	remaining = maxf(0.0, remaining - maxf(0.0, delta_seconds))
	state.active_timers[SPRINT_TIMER_ID] = remaining
	_emit(SimulationEvent.timer_updated(SPRINT_TIMER_ID, remaining))

	var stack_ids: Array = state.stacks.keys()
	for stack_id: String in stack_ids:
		if not state.stacks.has(stack_id):
			continue
		var stack: StackState = _get_existing_stack(stack_id)
		if not stack.processing_state.is_active():
			continue
		stack.processing_state.elapsed += maxf(0.0, delta_seconds)
		if stack.processing_state.elapsed >= stack.processing_state.duration:
			_complete_processing(stack)

func move_stack(stack_id: String, position: Vector2) -> void:
	_require_state()
	var stack: StackState = _get_existing_stack(stack_id)
	stack.base_position = position
	for card_id: String in stack.card_ids:
		var card: CardInstance = _get_existing_card(card_id)
		card.position = position
	_emit(SimulationEvent.stack_changed(stack.stack_id))

func move_card_to_stack(card_id: String, target_stack_id: String) -> void:
	_require_state()
	var card: CardInstance = _get_existing_card(card_id)
	var source_stack: StackState = _get_existing_stack(card.stack_id)
	var target_stack: StackState = _get_existing_stack(target_stack_id)
	if source_stack.stack_id == target_stack.stack_id:
		return

	_remove_card_from_stack(source_stack, card_id)
	target_stack.card_ids.append(card_id)
	card.stack_id = target_stack.stack_id
	card.position = target_stack.base_position

	_emit(SimulationEvent.stack_changed(source_stack.stack_id))
	_emit(SimulationEvent.stack_changed(target_stack.stack_id))
	_delete_stack_if_empty(source_stack)
	_refresh_stack_recipe_if_present(source_stack.stack_id)
	_refresh_stack_recipe_if_present(target_stack.stack_id)

func split_stack_from_card(card_id: String, new_position: Vector2) -> StackState:
	_require_state()
	var card: CardInstance = _get_existing_card(card_id)
	var source_stack: StackState = _get_existing_stack(card.stack_id)
	var start_index: int = source_stack.card_ids.find(card_id)
	if start_index < 0:
		push_error("Card '%s' is not in its source stack." % card_id)
		return null

	var new_stack: StackState = _create_stack(new_position)
	var moving_card_ids: PackedStringArray = source_stack.card_ids.slice(start_index)
	source_stack.card_ids = source_stack.card_ids.slice(0, start_index)

	for moving_card_id: String in moving_card_ids:
		new_stack.card_ids.append(moving_card_id)
		var moving_card: CardInstance = _get_existing_card(moving_card_id)
		moving_card.stack_id = new_stack.stack_id
		moving_card.position = new_position

	_emit(SimulationEvent.stack_changed(source_stack.stack_id))
	_emit(SimulationEvent.stack_changed(new_stack.stack_id))
	_delete_stack_if_empty(source_stack)
	_refresh_stack_recipe_if_present(source_stack.stack_id)
	_refresh_stack_recipe_if_present(new_stack.stack_id)
	return new_stack

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
	stack.processing_state.duration = recipe.duration.base_seconds
	_emit(SimulationEvent.recipe_started(stack.stack_id))
	_emit(SimulationEvent.stack_changed(stack.stack_id))

func _cancel_processing(stack: StackState) -> void:
	_clear_processing(stack)
	_emit(SimulationEvent.recipe_cancelled(stack.stack_id))
	_emit(SimulationEvent.stack_changed(stack.stack_id))

func _complete_processing(stack: StackState) -> void:
	var recipe: RecipeDefinition = content.get_recipe_definition(stack.processing_state.active_recipe_id)
	_clear_processing(stack)
	if recipe == null:
		_emit(SimulationEvent.stack_changed(stack.stack_id))
		return

	_execute_effects(recipe.effects_on_complete, stack, recipe)
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
	var context: EffectContext = EffectContext.new()
	context.state = state
	context.stack = stack
	context.recipe = recipe
	context.content = content
	context.rng = _rng
	context.spawn_card = Callable(self, "_spawn_card_as_new_stack")
	context.remove_card = Callable(self, "_remove_card_instance")
	_effect_pipeline.execute(effects, context)

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
	stack.card_ids.append(card.instance_id)
	state.cards[card.instance_id] = card

	_emit(SimulationEvent.card_spawned(card.instance_id, stack.stack_id))
	_emit(SimulationEvent.stack_changed(stack.stack_id))
	return card

func _remove_card_instance(card_id: String) -> void:
	var card: CardInstance = state.get_card(card_id)
	if card == null:
		return

	var stack_id: String = card.stack_id
	if state.stacks.has(stack_id):
		var stack: StackState = _get_existing_stack(stack_id)
		_remove_card_from_stack(stack, card_id)
		_emit(SimulationEvent.stack_changed(stack.stack_id))
		_delete_stack_if_empty(stack)

	state.cards.erase(card_id)
	var event: SimulationEvent = SimulationEvent.new()
	event.type = ScopeEnums.SimulationEventType.CARD_REMOVED
	event.card_id = card_id
	event.stack_id = stack_id
	_emit(event)

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

func _emit(event: SimulationEvent) -> void:
	pending_events.append(event)

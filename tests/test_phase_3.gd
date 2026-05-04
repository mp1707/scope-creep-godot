extends SceneTree

var _failed: bool = false

func _init() -> void:
	_test_start_run()
	_test_stack_and_split()
	_test_neutral_stacks_and_pause()

	if _failed:
		quit(1)
		return

	print("Phase 3 tests passed.")
	quit(0)

func _test_start_run() -> void:
	var controller: RunController = _create_controller()
	var state: RunState = controller.start_new_run(123)

	_assert_equal(state.cards.size(), 7, "Start run should create 7 cards.")
	_assert_equal(state.stacks.size(), 7, "Start run should place each card in its own stack.")
	_assert_equal(_count_cards_by_definition(state, "card.resource.money"), 3, "Start run should create three 1-money cards.")
	_assert_equal(_count_cards_by_definition(state, "card.employee.developer"), 1, "Start run should create one developer.")
	_assert_true(state.rng_seed == 123 and state.rng_state != 0, "Start run should prepare deterministic RNG state.")
	for stack: StackState in state.stacks.values():
		_assert_true(stack.base_position.x >= 560.0 and stack.base_position.x <= 1220.0, "Start stack should spawn in the central horizontal board area.")
		_assert_true(stack.base_position.y >= 300.0 and stack.base_position.y <= 620.0, "Start stack should spawn in the central vertical board area.")

	var events: Array[SimulationEvent] = controller.drain_events()
	_assert_true(_has_event(events, ScopeEnums.SimulationEventType.CARD_SPAWNED), "Start run should emit CardSpawned.")
	_assert_true(_has_event(events, ScopeEnums.SimulationEventType.STACK_CHANGED), "Start run should emit StackChanged.")
	_assert_true(_has_event(events, ScopeEnums.SimulationEventType.PHASE_CHANGED), "Start run should emit PhaseChanged.")
	_assert_true(_has_event(events, ScopeEnums.SimulationEventType.TIMER_UPDATED), "Start run should emit TimerUpdated.")

func _test_stack_and_split() -> void:
	var controller: RunController = _create_controller()
	var state: RunState = controller.start_new_run(1)
	controller.drain_events()

	var idea: CardInstance = _find_card_by_definition(state, "card.input.idea")
	var developer: CardInstance = _find_card_by_definition(state, "card.employee.developer")
	var idea_source_stack_id: String = idea.stack_id
	var developer_stack_id: String = developer.stack_id

	controller.move_card_to_stack(idea.instance_id, developer_stack_id)
	_assert_false(state.stacks.has(idea_source_stack_id), "Empty source stack should be removed after stacking.")

	var developer_stack: StackState = state.get_stack(developer_stack_id)
	_assert_equal(developer_stack.card_ids.size(), 2, "Developer stack should contain two cards.")
	_assert_equal(idea.stack_id, developer_stack_id, "Moved card should point to target stack.")

	var split_stack: StackState = controller.split_stack_from_card(idea.instance_id, Vector2(500.0, 500.0))
	_assert_true(split_stack != null, "Splitting should create a new stack.")
	_assert_equal(split_stack.card_ids.size(), 1, "Split stack should contain the moved card.")
	_assert_equal(idea.stack_id, split_stack.stack_id, "Split card should point to new stack.")
	_assert_equal(developer_stack.card_ids.size(), 1, "Original stack should keep the lower card.")

func _test_neutral_stacks_and_pause() -> void:
	var controller: RunController = _create_controller()
	var state: RunState = controller.start_new_run(1)
	controller.drain_events()

	var developer: CardInstance = _find_card_by_definition(state, "card.employee.developer")
	var coffee: CardInstance = _find_card_by_definition(state, "card.consumable.coffee")
	var money: CardInstance = _find_card_by_definition(state, "card.resource.money")
	var target_stack_id: String = developer.stack_id

	controller.move_card_to_stack(coffee.instance_id, target_stack_id)
	controller.move_card_to_stack(money.instance_id, target_stack_id)

	var target_stack: StackState = state.get_stack(target_stack_id)
	_assert_equal(target_stack.card_ids.size(), 3, "Neutral mixed stacks should remain allowed and movable.")

	controller.move_stack(target_stack_id, Vector2(720.0, 360.0))
	_assert_equal(target_stack.base_position, Vector2(720.0, 360.0), "Moved stack should update base position.")

	var remaining_before_pause: float = state.active_timers[RunController.SPRINT_TIMER_ID] as float
	controller.set_paused(true)
	controller.advance_time(10.0)
	_assert_equal(state.active_timers[RunController.SPRINT_TIMER_ID], remaining_before_pause, "Paused run should not advance timers.")

	controller.set_paused(false)
	controller.advance_time(5.0)
	_assert_equal(state.active_timers[RunController.SPRINT_TIMER_ID], remaining_before_pause - 5.0, "Unpaused run should advance timers.")

func _create_controller() -> RunController:
	var catalog: ContentCatalog = ContentCatalog.new()
	_assert_true(catalog.load_default_content(), "Default content should load.")
	return RunController.new(catalog)

func _count_cards_by_definition(state: RunState, definition_id: String) -> int:
	var count: int = 0
	for card: CardInstance in state.cards.values():
		if card.definition_id == definition_id:
			count += 1
	return count

func _find_card_by_definition(state: RunState, definition_id: String) -> CardInstance:
	for card: CardInstance in state.cards.values():
		if card.definition_id == definition_id:
			return card
	_assert_true(false, "Missing card with definition '%s'." % definition_id)
	return null

func _has_event(events: Array[SimulationEvent], type: ScopeEnums.SimulationEventType) -> bool:
	for event: SimulationEvent in events:
		if event.type == type:
			return true
	return false

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

class_name SimulationEvent
extends Resource

@export var type: ScopeEnums.SimulationEventType = ScopeEnums.SimulationEventType.STACK_CHANGED
@export var card_id: String = ""
@export var stack_id: String = ""
@export var phase: ScopeEnums.RunPhase = ScopeEnums.RunPhase.SPRINT
@export var timer_id: String = ""
@export var timer_seconds: float = 0.0
@export var is_paused: bool = false

static func card_spawned(spawned_card_id: String, target_stack_id: String) -> SimulationEvent:
	var event: SimulationEvent = SimulationEvent.new()
	event.type = ScopeEnums.SimulationEventType.CARD_SPAWNED
	event.card_id = spawned_card_id
	event.stack_id = target_stack_id
	return event

static func stack_changed(changed_stack_id: String) -> SimulationEvent:
	var event: SimulationEvent = SimulationEvent.new()
	event.type = ScopeEnums.SimulationEventType.STACK_CHANGED
	event.stack_id = changed_stack_id
	return event

static func phase_changed(new_phase: ScopeEnums.RunPhase) -> SimulationEvent:
	var event: SimulationEvent = SimulationEvent.new()
	event.type = ScopeEnums.SimulationEventType.PHASE_CHANGED
	event.phase = new_phase
	return event

static func timer_updated(changed_timer_id: String, seconds: float) -> SimulationEvent:
	var event: SimulationEvent = SimulationEvent.new()
	event.type = ScopeEnums.SimulationEventType.TIMER_UPDATED
	event.timer_id = changed_timer_id
	event.timer_seconds = seconds
	return event

static func pause_changed(paused: bool) -> SimulationEvent:
	var event: SimulationEvent = SimulationEvent.new()
	event.type = ScopeEnums.SimulationEventType.PAUSE_CHANGED
	event.is_paused = paused
	return event

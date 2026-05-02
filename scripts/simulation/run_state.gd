class_name RunState
extends Resource

@export var run_id: String = ""
@export var sprint_index: int = 1
@export var phase: ScopeEnums.RunPhase = ScopeEnums.RunPhase.SPRINT
@export var is_paused: bool = false
@export var rng_seed: int = 0
@export var rng_state: int = 0
@export var cards: Dictionary = {}
@export var stacks: Dictionary = {}
@export var board: BoardState = BoardState.new()
@export var active_timers: Dictionary = {}
@export var paid_employee_ids: PackedStringArray = PackedStringArray()
@export var content_version: String = ""

func get_card(card_id: String) -> CardInstance:
	return cards.get(card_id, null) as CardInstance

func get_stack(stack_id: String) -> StackState:
	return stacks.get(stack_id, null) as StackState

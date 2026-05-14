class_name SprintStartPipelineService
extends RefCounted

func run(
	state: RunState,
	quit_unpaid_employees: Callable,
	has_no_employees: Callable,
	enter_game_over: Callable,
	advance_sprint_index: Callable,
	form_prod_crashes_from_bugs: Callable,
	duplicate_remaining_bugs: Callable,
	expire_open_orders: Callable,
	expire_unused_external_devs: Callable,
	attach_unhappy_customers_from_old_requests: Callable,
	resolve_active_business_goal: Callable,
	spawn_persistent_tick_cards: Callable
) -> bool:
	quit_unpaid_employees.call()
	if has_no_employees.call() as bool:
		enter_game_over.call()
		return false

	advance_sprint_index.call()
	form_prod_crashes_from_bugs.call()
	duplicate_remaining_bugs.call()
	expire_open_orders.call()
	expire_unused_external_devs.call()
	attach_unhappy_customers_from_old_requests.call()
	resolve_active_business_goal.call()
	if _is_terminal(state):
		return false
	spawn_persistent_tick_cards.call()
	return not _is_terminal(state)

func _is_terminal(state: RunState) -> bool:
	return state.phase == ScopeEnums.RunPhase.GAME_OVER or state.phase == ScopeEnums.RunPhase.VICTORY

class_name ScopeEnums
extends RefCounted

enum CardType {
	EMPLOYEE,
	INPUT,
	TASK,
	OUTPUT,
	PROBLEM,
	RESOURCE,
	PROCESS,
	VALUE_SOURCE,
	PRODUCT,
	CONSUMABLE,
}

enum RunPhase {
	SPRINT,
	PAYMENT,
	GAME_OVER,
}

enum ProcessingStatus {
	IDLE,
	ACTIVE,
	PAUSED,
	BLOCKED,
}

enum SimulationEventType {
	CARD_SPAWNED,
	CARD_REMOVED,
	STACK_CHANGED,
	PHASE_CHANGED,
	TIMER_UPDATED,
	PAUSE_CHANGED,
}

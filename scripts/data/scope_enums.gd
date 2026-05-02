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

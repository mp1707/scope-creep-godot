class_name ProcessingState
extends Resource

@export var active_recipe_id: String = ""
@export var status: ScopeEnums.ProcessingStatus = ScopeEnums.ProcessingStatus.IDLE
@export_range(0.0, 3600.0, 0.01, "or_greater") var elapsed: float = 0.0
@export_range(0.0, 3600.0, 0.01, "or_greater") var duration: float = 0.0

func is_active() -> bool:
	return status == ScopeEnums.ProcessingStatus.ACTIVE

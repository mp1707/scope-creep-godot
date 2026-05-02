class_name BalanceDefinition
extends Resource

@export var id: String = "balance.default"
@export_range(1.0, 3600.0, 0.1, "or_greater") var sprint_duration_seconds: float = 60.0
@export_range(0.0, 3600.0, 0.1, "or_greater") var release_duration_seconds: float = 5.0
@export_range(0.0, 1.0, 0.01) var bug_chance: float = 0.25
@export_range(0.0, 512.0, 1.0, "or_greater") var board_snap_distance: float = 96.0
@export var stack_offset: Vector2 = Vector2(0.0, 28.0)
@export_range(0.0, 2048.0, 1.0, "or_greater") var spawn_placement_radius: float = 160.0

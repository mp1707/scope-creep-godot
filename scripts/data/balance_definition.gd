class_name BalanceDefinition
extends Resource

@export var id: String = "balance.default"
@export_range(1.0, 3600.0, 0.1, "or_greater") var sprint_duration_seconds: float = 60.0
@export_range(0.0, 3600.0, 0.1, "or_greater") var release_duration_seconds: float = 5.0
@export_range(0.0, 1.0, 0.01) var bug_chance: float = 0.5
@export_range(0.0, 3600.0, 0.1, "or_greater") var tech_debt_duration_seconds_per_card: float = 5.0
@export_range(0.0, 3600.0, 0.1, "or_greater") var product_owner_duration_seconds: float = 6.0
@export_range(0.0, 3600.0, 0.1, "or_greater") var tester_duration_seconds: float = 7.0
@export_range(0.0, 1.0, 0.01) var tech_debt_chance: float = 0.25
@export_range(0.0, 10.0, 0.01, "or_greater") var burnout_increment_per_completed_work: float = 0.1
@export_range(0.0, 3600.0, 0.1, "or_greater") var burnout_recovery_duration_seconds: float = 45.0
@export_range(0.0, 3600.0, 0.1, "or_greater") var pizza_recovery_duration_seconds: float = 5.0
@export_range(0.0, 3600.0, 0.1, "or_greater") var developer_bugfix_duration_seconds: float = 8.0
@export_range(0.0, 3600.0, 0.1, "or_greater") var tester_bugfix_duration_seconds: float = 11.0
@export_range(0.0, 3600.0, 0.1, "or_greater") var external_dev_bugfix_duration_seconds: float = 4.0
@export_range(0.0, 3600.0, 0.1, "or_greater") var prod_crash_fix_duration_seconds: float = 18.0
@export_range(0, 100, 1, "or_greater") var order_bonus_money_cards: int = 2
@export_range(0.0, 512.0, 1.0, "or_greater") var board_snap_distance: float = 96.0
@export var stack_offset: Vector2 = Vector2(0.0, 40.0)
@export_range(0.0, 2048.0, 1.0, "or_greater") var spawn_placement_radius: float = 160.0
@export_range(0.0, 2048.0, 1.0, "or_greater") var auto_stack_spawn_radius: float = 180.0

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
@export_group("PoC3")
@export_range(1, 100, 1, "or_greater") var poc3_mvp_required_features: int = 10
@export_range(0, 200, 1, "or_greater") var poc3_start_money_cards: int = 30
@export_range(0, 100, 1, "or_greater") var poc3_freelance_feature_money_cards: int = 2
@export_range(0, 100, 1, "or_greater") var poc3_freelance_checked_feature_money_cards: int = 3
@export_range(1, 100, 1, "or_greater") var poc3_launch_features_per_start_customer: int = 5
@export_range(0, 100, 1, "or_greater") var poc3_customer_tick_money_cards: int = 1
@export_range(0, 100, 1, "or_greater") var poc3_customer_tick_request_cards: int = 1
@export var poc3_business_goal_required_money: Array[int] = [3, 5, 7]
@export_range(1, 20, 1, "or_greater") var poc3_business_goal_win_count: int = 3
@export_range(1, 20, 1, "or_greater") var poc3_investor_panic_game_over_count: int = 2
@export_range(0.0, 3600.0, 0.1, "or_greater") var poc3_developer_customer_request_duration_seconds: float = 9.0
@export_group("PoC4")
@export_range(0.0, 3600.0, 0.1, "or_greater") var poc4_normal_interview_duration_seconds: float = 20.0
@export_range(0.0, 1.0, 0.01) var poc4_normal_interview_success_chance: float = 0.4
@export_range(0.0, 3600.0, 0.1, "or_greater") var poc4_recruiter_interview_duration_seconds: float = 10.0
@export_range(0.0, 1.0, 0.01) var poc4_recruiter_interview_success_chance: float = 0.7
@export_range(0, 100, 1, "or_greater") var poc4_offer_hire_cost_money_cards: int = 1
@export_range(0.0, 3600.0, 0.1, "or_greater") var poc4_onboarding_duration_seconds: float = 20.0
@export_range(0.0, 3600.0, 0.1, "or_greater") var poc4_recruiter_onboarding_duration_seconds: float = 10.0
@export_range(1.0, 10.0, 0.01, "or_greater") var poc4_work_student_duration_multiplier: float = 2.0
@export_range(1, 100, 1, "or_greater") var poc4_work_student_completed_task_lifetime: int = 1
@export_range(0.0, 512.0, 1.0, "or_greater") var board_snap_distance: float = 96.0
@export var stack_offset: Vector2 = Vector2(0.0, 40.0)
@export_range(0.0, 2048.0, 1.0, "or_greater") var spawn_placement_radius: float = 160.0
@export_range(0.0, 2048.0, 1.0, "or_greater") var auto_stack_spawn_radius: float = 180.0

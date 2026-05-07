class_name HudView
extends Control

signal auto_pay_requested()
signal next_sprint_requested()
signal save_requested()
signal load_requested()

@export var status_label_path: NodePath = NodePath("StatusPanel/StatusLabel")
@export var auto_pay_button_path: NodePath = NodePath("StatusPanel/ButtonRow/AutoPayButton")
@export var next_sprint_button_path: NodePath = NodePath("StatusPanel/ButtonRow/NextSprintButton")
@export var save_button_path: NodePath = NodePath("StatusPanel/ButtonRow/SaveButton")
@export var load_button_path: NodePath = NodePath("StatusPanel/ButtonRow/LoadButton")

var _status_label: Label = null
var _auto_pay_button: Button = null
var _next_sprint_button: Button = null
var _save_button: Button = null
var _load_button: Button = null

func _ready() -> void:
	_status_label = get_node_or_null(status_label_path) as Label
	_auto_pay_button = get_node_or_null(auto_pay_button_path) as Button
	_next_sprint_button = get_node_or_null(next_sprint_button_path) as Button
	_save_button = get_node_or_null(save_button_path) as Button
	_load_button = get_node_or_null(load_button_path) as Button

	if _auto_pay_button != null and not _auto_pay_button.pressed.is_connected(_on_auto_pay_pressed):
		_auto_pay_button.pressed.connect(_on_auto_pay_pressed)
	if _next_sprint_button != null and not _next_sprint_button.pressed.is_connected(_on_next_sprint_pressed):
		_next_sprint_button.pressed.connect(_on_next_sprint_pressed)
	if _save_button != null and not _save_button.pressed.is_connected(_on_save_pressed):
		_save_button.pressed.connect(_on_save_pressed)
	if _load_button != null and not _load_button.pressed.is_connected(_on_load_pressed):
		_load_button.pressed.connect(_on_load_pressed)

func update_from_run(run_state: RunState, sprint_remaining: float, can_auto_pay: bool, can_save: bool, can_load: bool) -> void:
	if run_state == null:
		return
	if _status_label != null:
		var pause_text: String = " · Pause" if run_state.is_paused else ""
		_status_label.text = "Sprint %d · %s · %.1fs%s" % [
			run_state.sprint_index,
			_get_phase_display_text(run_state.phase),
			sprint_remaining,
			pause_text
		]
	if _auto_pay_button != null:
		_auto_pay_button.visible = run_state.phase == ScopeEnums.RunPhase.PAYMENT
		_auto_pay_button.disabled = not can_auto_pay
	if _next_sprint_button != null:
		_next_sprint_button.visible = run_state.phase == ScopeEnums.RunPhase.PAYMENT
		_next_sprint_button.text = "Sprint %d starten" % (run_state.sprint_index + 1)
	if _save_button != null:
		_save_button.disabled = not can_save
	if _load_button != null:
		_load_button.disabled = not can_load

func _get_phase_display_text(phase: ScopeEnums.RunPhase) -> String:
	match phase:
		ScopeEnums.RunPhase.SPRINT:
			return "Sprint"
		ScopeEnums.RunPhase.PAYMENT:
			return "Bezahlen"
		ScopeEnums.RunPhase.GAME_OVER:
			return "Game Over"
		_:
			return ScopeEnums.RunPhase.keys()[phase].capitalize()

func _on_auto_pay_pressed() -> void:
	auto_pay_requested.emit()

func _on_next_sprint_pressed() -> void:
	next_sprint_requested.emit()

func _on_save_pressed() -> void:
	save_requested.emit()

func _on_load_pressed() -> void:
	load_requested.emit()

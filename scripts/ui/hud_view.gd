class_name HudView
extends Control

signal auto_pay_requested()
signal next_sprint_requested()
signal save_requested()
signal load_requested()

const MASTER_BUS_NAME: StringName = &"Master"
const DEFAULT_MASTER_VOLUME_PERCENT: float = 30.0
const MIN_VOLUME_DB: float = -80.0

@export var status_label_path: NodePath = NodePath("StatusPanel/StatusLabel")
@export var auto_pay_button_path: NodePath = NodePath("StatusPanel/ButtonRow/AutoPayButton")
@export var next_sprint_button_path: NodePath = NodePath("StatusPanel/ButtonRow/NextSprintButton")
@export var save_button_path: NodePath = NodePath("StatusPanel/ButtonRow/SaveButton")
@export var load_button_path: NodePath = NodePath("StatusPanel/ButtonRow/LoadButton")
@export var master_volume_row_path: NodePath = NodePath("MasterVolumeRow")
@export var master_volume_slider_path: NodePath = NodePath("MasterVolumeRow/MasterVolumeSlider")
@export var master_volume_value_label_path: NodePath = NodePath("MasterVolumeRow/MasterVolumeValueLabel")

var _status_label: Label = null
var _auto_pay_button: Button = null
var _next_sprint_button: Button = null
var _save_button: Button = null
var _load_button: Button = null
var _master_volume_row: Control = null
var _master_volume_slider: HSlider = null
var _master_volume_value_label: Label = null
var _master_bus_index: int = -1
var _visual_theme: Resource = null

func _ready() -> void:
	_status_label = get_node_or_null(status_label_path) as Label
	_auto_pay_button = get_node_or_null(auto_pay_button_path) as Button
	_next_sprint_button = get_node_or_null(next_sprint_button_path) as Button
	_save_button = get_node_or_null(save_button_path) as Button
	_load_button = get_node_or_null(load_button_path) as Button
	_master_volume_row = get_node_or_null(master_volume_row_path) as Control
	_master_volume_slider = get_node_or_null(master_volume_slider_path) as HSlider
	_master_volume_value_label = get_node_or_null(master_volume_value_label_path) as Label
	_master_bus_index = AudioServer.get_bus_index(MASTER_BUS_NAME)

	if _auto_pay_button != null and not _auto_pay_button.pressed.is_connected(_on_auto_pay_pressed):
		_auto_pay_button.pressed.connect(_on_auto_pay_pressed)
	if _next_sprint_button != null and not _next_sprint_button.pressed.is_connected(_on_next_sprint_pressed):
		_next_sprint_button.pressed.connect(_on_next_sprint_pressed)
	if _save_button != null and not _save_button.pressed.is_connected(_on_save_pressed):
		_save_button.pressed.connect(_on_save_pressed)
	if _load_button != null and not _load_button.pressed.is_connected(_on_load_pressed):
		_load_button.pressed.connect(_on_load_pressed)
	_initialize_master_volume_control()
	_apply_visual_theme()

func set_visual_theme(new_visual_theme: Resource) -> void:
	_visual_theme = new_visual_theme
	_apply_visual_theme()

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
	var options_visible: bool = run_state.is_paused or run_state.phase == ScopeEnums.RunPhase.PAYMENT
	if _save_button != null:
		_save_button.visible = options_visible
		_save_button.disabled = not options_visible or not can_save
	if _load_button != null:
		_load_button.visible = options_visible
		_load_button.disabled = not options_visible or not can_load
	if _master_volume_row != null:
		_master_volume_row.visible = options_visible

func _get_phase_display_text(phase: ScopeEnums.RunPhase) -> String:
	match phase:
		ScopeEnums.RunPhase.SPRINT:
			return "Sprint"
		ScopeEnums.RunPhase.PAYMENT:
			return "Bezahlen"
		ScopeEnums.RunPhase.GAME_OVER:
			return "Game Over"
		ScopeEnums.RunPhase.VICTORY:
			return "Gewonnen"
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

func _initialize_master_volume_control() -> void:
	if _master_volume_slider == null:
		return
	_master_volume_slider.min_value = 0.0
	_master_volume_slider.max_value = 100.0
	_master_volume_slider.step = 1.0
	_master_volume_slider.value = DEFAULT_MASTER_VOLUME_PERCENT
	_apply_master_volume(DEFAULT_MASTER_VOLUME_PERCENT)
	if not _master_volume_slider.value_changed.is_connected(_on_master_volume_changed):
		_master_volume_slider.value_changed.connect(_on_master_volume_changed)

func _on_master_volume_changed(value: float) -> void:
	_apply_master_volume(value)

func _apply_master_volume(value: float) -> void:
	if _master_bus_index < 0:
		return
	var linear_volume: float = clampf(value / 100.0, 0.0, 1.0)
	var volume_db: float = MIN_VOLUME_DB if is_zero_approx(linear_volume) else linear_to_db(linear_volume)
	AudioServer.set_bus_volume_db(_master_bus_index, volume_db)
	AudioServer.set_bus_mute(_master_bus_index, is_zero_approx(linear_volume))
	_update_master_volume_label(value)

func _update_master_volume_label(value: float) -> void:
	if _master_volume_value_label != null:
		_master_volume_value_label.text = "%d%%" % roundi(value)

func _apply_visual_theme() -> void:
	if _visual_theme == null:
		return
	var color: Variant = _visual_theme.get("hud_text_color")
	if color is Color:
		_apply_text_color_recursive(self, color as Color)

func _apply_text_color_recursive(node: Node, color: Color) -> void:
	if node is Label:
		(node as Label).add_theme_color_override("font_color", color)
	elif node is Button:
		(node as Button).add_theme_color_override("font_color", color)
	for child: Node in node.get_children():
		_apply_text_color_recursive(child, color)

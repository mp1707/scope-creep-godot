class_name MainApplication
extends Node

const CARD_VIEW_SCENE_PATH: String = "res://scenes/presentation/CardView.tscn"
const DEV_SAVE_PATH: String = "user://scope_creep_poc_slot_1.json"
const UI_BUTTON_COLOR: Color = Color(0.62, 0.82, 0.92, 1.0)
const UI_BUTTON_HOVER_COLOR: Color = Color(0.70, 0.88, 0.96, 1.0)
const UI_BUTTON_PRESSED_COLOR: Color = Color(0.50, 0.72, 0.84, 1.0)
const UI_DISABLED_COLOR: Color = Color(0.78, 0.78, 0.74, 1.0)
const UI_BORDER_COLOR: Color = Color(0.055, 0.052, 0.047, 1.0)
const UI_TEXT_COLOR: Color = Color(0.055, 0.052, 0.047, 1.0)
const UI_CORNER_RADIUS: int = 8
const UI_BORDER_WIDTH: int = 4
const HUD_ORIGIN: Vector2 = Vector2(116.0, 116.0)
const HUD_BUTTON_Y_OFFSET: float = 34.0

@export var board_view_path: NodePath = NodePath("BoardView")
@export var debug_layer_path: NodePath = NodePath("Camera2D/CanvasLayer")
@export var show_dev_overlay: bool = true

var content: ContentCatalog = null
var controller: RunController = null
var run_state: RunState = null

var _board_view: BoardView = null
var _debug_panel: Panel = null
var _debug_label: Label = null
var _next_sprint_button: Button = null
var _auto_pay_button: Button = null
var _save_button: Button = null
var _load_button: Button = null

func _ready() -> void:
	set_process_unhandled_input(true)
	_board_view = get_node_or_null(board_view_path) as BoardView
	if _board_view == null:
		push_error("MainApplication needs a BoardView at '%s'." % board_view_path)
		return

	content = ContentCatalog.new()
	if not content.load_default_content():
		push_error("Default content could not be loaded.")
		return

	controller = RunController.new(content)
	run_state = controller.start_new_run(1)

	_apply_board_defaults()
	_connect_board_signals()
	_board_view.bind_run(run_state, content)
	_apply_pending_events()
	if show_dev_overlay:
		_create_debug_overlay()
		_update_debug_overlay()

func _process(delta: float) -> void:
	advance_run(delta)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.pressed and not key_event.echo and key_event.keycode == KEY_SPACE:
			request_toggle_pause()
			get_viewport().set_input_as_handled()

func advance_run(delta_seconds: float) -> void:
	if controller == null or _board_view == null:
		return
	controller.advance_time(delta_seconds)
	_apply_pending_events()
	_update_debug_overlay()

func request_move_stack(stack_id: String, position: Vector2) -> void:
	if controller == null:
		return
	controller.move_stack(stack_id, position)
	_apply_pending_events()

func request_move_card_to_stack(card_id: String, target_stack_id: String) -> void:
	if controller == null:
		return
	controller.move_card_to_stack(card_id, target_stack_id)
	_apply_pending_events()

func request_split_stack(card_id: String, position: Vector2) -> void:
	if controller == null:
		return
	controller.split_stack_from_card(card_id, position)
	_apply_pending_events()

func request_set_paused(paused: bool) -> void:
	if controller == null:
		return
	controller.set_paused(paused)
	_apply_pending_events()
	_update_debug_overlay()

func request_toggle_pause() -> void:
	if run_state == null:
		return
	request_set_paused(not run_state.is_paused)

func request_start_next_sprint() -> void:
	if controller == null:
		return
	controller.start_next_sprint()
	_apply_pending_events()
	_update_debug_overlay()

func request_auto_pay() -> void:
	if controller == null:
		return
	controller.auto_pay_all_employees()
	_apply_pending_events()
	_update_debug_overlay()

func request_save_current_run() -> bool:
	if controller == null:
		return false
	var saved: bool = controller.save_current_run(DEV_SAVE_PATH)
	if not saved:
		for error: String in controller.get_save_errors():
			push_warning(error)
	_update_debug_overlay()
	return saved

func request_load_saved_run() -> bool:
	if controller == null:
		return false
	var loaded: bool = controller.load_run_from_file(DEV_SAVE_PATH)
	if not loaded:
		for error: String in controller.get_save_errors():
			push_warning(error)
		return false
	run_state = controller.state
	_board_view.bind_run(run_state, content)
	_apply_pending_events()
	_update_debug_overlay()
	return true

func get_board_view() -> BoardView:
	return _board_view

func _apply_board_defaults() -> void:
	if _board_view.card_view_scene == null:
		_board_view.card_view_scene = ResourceLoader.load(CARD_VIEW_SCENE_PATH) as PackedScene
	if content.balance != null:
		_board_view.stack_offset = content.balance.stack_offset
		_board_view.snap_distance = content.balance.board_snap_distance

func _connect_board_signals() -> void:
	if not _board_view.move_stack_requested.is_connected(request_move_stack):
		_board_view.move_stack_requested.connect(request_move_stack)
	if not _board_view.move_card_to_stack_requested.is_connected(request_move_card_to_stack):
		_board_view.move_card_to_stack_requested.connect(request_move_card_to_stack)
	if not _board_view.split_stack_requested.is_connected(request_split_stack):
		_board_view.split_stack_requested.connect(request_split_stack)

func _apply_pending_events() -> void:
	if controller == null or _board_view == null:
		return
	var events: Array[SimulationEvent] = controller.drain_events()
	if not events.is_empty():
		_board_view.apply_events(events)

func _create_debug_overlay() -> void:
	var layer: CanvasLayer = get_node_or_null(debug_layer_path) as CanvasLayer
	if layer == null:
		return

	_debug_panel = layer.get_node_or_null("DebugPanel") as Panel
	if _debug_panel == null:
		_debug_panel = Panel.new()
		_debug_panel.name = "DebugPanel"
		_debug_panel.position = HUD_ORIGIN
		_debug_panel.size = Vector2(584.0, 72.0)
		_debug_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.add_child(_debug_panel)
		layer.move_child(_debug_panel, 0)
	_apply_panel_style(_debug_panel)

	_debug_label = layer.get_node_or_null("DebugStatusLabel") as Label
	if _debug_label == null:
		_debug_label = Label.new()
		_debug_label.name = "DebugStatusLabel"
		_debug_label.position = HUD_ORIGIN
		_debug_label.size = Vector2(392.0, 28.0)
		_debug_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.add_child(_debug_label)
	_debug_label.add_theme_color_override("font_color", UI_TEXT_COLOR)
	_debug_label.add_theme_font_size_override("font_size", 19)

	_auto_pay_button = layer.get_node_or_null("AutoPayButton") as Button
	if _auto_pay_button == null:
		_auto_pay_button = Button.new()
		_auto_pay_button.name = "AutoPayButton"
		_auto_pay_button.text = "Auto-Pay"
		_auto_pay_button.position = HUD_ORIGIN + Vector2(0.0, HUD_BUTTON_Y_OFFSET)
		_auto_pay_button.size = Vector2(120.0, 32.0)
		layer.add_child(_auto_pay_button)
	_apply_button_style(_auto_pay_button)
	if not _auto_pay_button.pressed.is_connected(request_auto_pay):
		_auto_pay_button.pressed.connect(request_auto_pay)

	_next_sprint_button = layer.get_node_or_null("NextSprintButton") as Button
	if _next_sprint_button == null:
		_next_sprint_button = Button.new()
		_next_sprint_button.name = "NextSprintButton"
		_next_sprint_button.text = "Sprint 2 starten"
		_next_sprint_button.position = HUD_ORIGIN + Vector2(132.0, HUD_BUTTON_Y_OFFSET)
		_next_sprint_button.size = Vector2(190.0, 32.0)
		layer.add_child(_next_sprint_button)
	_apply_button_style(_next_sprint_button)
	if not _next_sprint_button.pressed.is_connected(request_start_next_sprint):
		_next_sprint_button.pressed.connect(request_start_next_sprint)

	_save_button = layer.get_node_or_null("SaveButton") as Button
	if _save_button == null:
		_save_button = Button.new()
		_save_button.name = "SaveButton"
		_save_button.text = "Speichern"
		_save_button.position = HUD_ORIGIN + Vector2(334.0, HUD_BUTTON_Y_OFFSET)
		_save_button.size = Vector2(104.0, 32.0)
		layer.add_child(_save_button)
	_apply_button_style(_save_button)
	if not _save_button.pressed.is_connected(request_save_current_run):
		_save_button.pressed.connect(request_save_current_run)

	_load_button = layer.get_node_or_null("LoadButton") as Button
	if _load_button == null:
		_load_button = Button.new()
		_load_button.name = "LoadButton"
		_load_button.text = "Laden"
		_load_button.position = HUD_ORIGIN + Vector2(450.0, HUD_BUTTON_Y_OFFSET)
		_load_button.size = Vector2(86.0, 32.0)
		layer.add_child(_load_button)
	_apply_button_style(_load_button)
	if not _load_button.pressed.is_connected(request_load_saved_run):
		_load_button.pressed.connect(request_load_saved_run)

func _apply_panel_style(panel: Panel) -> void:
	panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())

func _apply_button_style(button: Button) -> void:
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_color_override("font_color", UI_TEXT_COLOR)
	button.add_theme_color_override("font_hover_color", UI_TEXT_COLOR)
	button.add_theme_color_override("font_pressed_color", UI_TEXT_COLOR)
	button.add_theme_color_override("font_disabled_color", Color(0.28, 0.28, 0.26, 1.0))
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_stylebox_override("normal", _create_ui_style(UI_BUTTON_COLOR))
	button.add_theme_stylebox_override("hover", _create_ui_style(UI_BUTTON_HOVER_COLOR))
	button.add_theme_stylebox_override("pressed", _create_ui_style(UI_BUTTON_PRESSED_COLOR))
	button.add_theme_stylebox_override("disabled", _create_ui_style(UI_DISABLED_COLOR))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

func _create_ui_style(background_color: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = background_color
	style.border_color = UI_BORDER_COLOR
	style.border_width_bottom = UI_BORDER_WIDTH
	style.border_width_left = UI_BORDER_WIDTH
	style.border_width_right = UI_BORDER_WIDTH
	style.border_width_top = UI_BORDER_WIDTH
	style.corner_radius_bottom_left = UI_CORNER_RADIUS
	style.corner_radius_bottom_right = UI_CORNER_RADIUS
	style.corner_radius_top_left = UI_CORNER_RADIUS
	style.corner_radius_top_right = UI_CORNER_RADIUS
	return style

func _update_debug_overlay() -> void:
	if _debug_label == null or run_state == null:
		return
	var phase_name: String = _get_phase_display_text(run_state.phase)
	var sprint_remaining: float = run_state.active_timers.get(RunController.SPRINT_TIMER_ID, 0.0) as float
	var pause_text: String = " · Pause" if run_state.is_paused else ""
	_debug_label.text = "Sprint %d · %s · %.1fs%s" % [run_state.sprint_index, phase_name, sprint_remaining, pause_text]
	if _auto_pay_button != null:
		_auto_pay_button.visible = run_state.phase == ScopeEnums.RunPhase.PAYMENT
		_auto_pay_button.disabled = not _can_auto_pay()
	if _next_sprint_button != null:
		_next_sprint_button.visible = run_state.phase == ScopeEnums.RunPhase.PAYMENT
		_next_sprint_button.text = "Sprint %d starten" % (run_state.sprint_index + 1)
	if _save_button != null:
		_save_button.disabled = not controller.can_save_current_run()
	if _load_button != null:
		_load_button.disabled = not FileAccess.file_exists(DEV_SAVE_PATH)

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

func _can_auto_pay() -> bool:
	if controller == null or run_state == null:
		return false
	return controller.can_auto_pay()

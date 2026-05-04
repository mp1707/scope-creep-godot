class_name MainApplication
extends Node

const CARD_VIEW_SCENE_PATH: String = "res://scenes/presentation/CardView.tscn"

@export var board_view_path: NodePath = NodePath("BoardView")
@export var debug_layer_path: NodePath = NodePath("Camera2D/CanvasLayer")

var content: ContentCatalog = null
var controller: RunController = null
var run_state: RunState = null

var _board_view: BoardView = null
var _debug_label: Label = null
var _next_sprint_button: Button = null
var _auto_pay_button: Button = null

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

	_debug_label = layer.get_node_or_null("DebugStatusLabel") as Label
	if _debug_label == null:
		_debug_label = Label.new()
		_debug_label.name = "DebugStatusLabel"
		_debug_label.position = Vector2(24.0, 18.0)
		_debug_label.size = Vector2(420.0, 32.0)
		_debug_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.add_child(_debug_label)

	_auto_pay_button = layer.get_node_or_null("AutoPayButton") as Button
	if _auto_pay_button == null:
		_auto_pay_button = Button.new()
		_auto_pay_button.name = "AutoPayButton"
		_auto_pay_button.text = "Auto-Pay"
		_auto_pay_button.position = Vector2(24.0, 54.0)
		_auto_pay_button.size = Vector2(120.0, 32.0)
		layer.add_child(_auto_pay_button)
	if not _auto_pay_button.pressed.is_connected(request_auto_pay):
		_auto_pay_button.pressed.connect(request_auto_pay)

	_next_sprint_button = layer.get_node_or_null("NextSprintButton") as Button
	if _next_sprint_button == null:
		_next_sprint_button = Button.new()
		_next_sprint_button.name = "NextSprintButton"
		_next_sprint_button.text = "Sprint 2 starten"
		_next_sprint_button.position = Vector2(156.0, 54.0)
		_next_sprint_button.size = Vector2(190.0, 32.0)
		layer.add_child(_next_sprint_button)
	if not _next_sprint_button.pressed.is_connected(request_start_next_sprint):
		_next_sprint_button.pressed.connect(request_start_next_sprint)

func _update_debug_overlay() -> void:
	if _debug_label == null or run_state == null:
		return
	var phase_name: String = ScopeEnums.RunPhase.keys()[run_state.phase]
	var sprint_remaining: float = run_state.active_timers.get(RunController.SPRINT_TIMER_ID, 0.0) as float
	var pause_text: String = " | PAUSE" if run_state.is_paused else ""
	_debug_label.text = "Sprint %d | %s | %.1fs%s" % [run_state.sprint_index, phase_name, sprint_remaining, pause_text]
	if _auto_pay_button != null:
		_auto_pay_button.visible = run_state.phase == ScopeEnums.RunPhase.PAYMENT
		_auto_pay_button.disabled = not _can_auto_pay()
	if _next_sprint_button != null:
		_next_sprint_button.visible = run_state.phase == ScopeEnums.RunPhase.PAYMENT
		_next_sprint_button.text = "Sprint %d starten" % (run_state.sprint_index + 1)

func _can_auto_pay() -> bool:
	if controller == null or run_state == null:
		return false
	return controller.can_auto_pay()

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

func _ready() -> void:
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
	if _debug_label != null:
		return

	_debug_label = Label.new()
	_debug_label.name = "DebugStatusLabel"
	_debug_label.position = Vector2(24.0, 18.0)
	_debug_label.size = Vector2(420.0, 32.0)
	_debug_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_debug_label)

func _update_debug_overlay() -> void:
	if _debug_label == null or run_state == null:
		return
	var phase_name: String = ScopeEnums.RunPhase.keys()[run_state.phase]
	var sprint_remaining: float = run_state.active_timers.get(RunController.SPRINT_TIMER_ID, 0.0) as float
	_debug_label.text = "Sprint %d | %s | %.1fs" % [run_state.sprint_index, phase_name, sprint_remaining]

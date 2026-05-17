class_name MainApplication
extends Node

const CARD_VIEW_SCENE_PATH: String = "res://scenes/presentation/CardView.tscn"
const DEV_SAVE_PATH: String = "user://scope_creep_poc_slot_1.json"
const DRAG_OVERLAY_LAYER: int = 20

@export var board_view_path: NodePath = NodePath("BoardView")
@export var board_camera_path: NodePath = NodePath("Camera2D")
@export var hud_path: NodePath = NodePath("UiLayer/Hud")
@export var shop_board_slots_path: NodePath = NodePath("BoardView/ShopSlots")
@export var drag_overlay_path: NodePath = NodePath("DragOverlayLayer/ScreenDragLayer")
@export var show_hud: bool = true

var content: ContentCatalog = null
var controller: RunController = null
var run_state: RunState = null

var _board_view: BoardView = null
var _board_camera: BoardCamera = null
var _hud: Control = null
var _screen_drag_layer: Control = null

func _ready() -> void:
	set_process_unhandled_input(true)
	_board_view = get_node_or_null(board_view_path) as BoardView
	if _board_view == null:
		push_error("MainApplication needs a BoardView at '%s'." % board_view_path)
		return
	_board_camera = get_node_or_null(board_camera_path) as BoardCamera
	_hud = get_node_or_null(hud_path) as Control
	if show_hud and _hud == null:
		push_error("MainApplication needs a HudView at '%s'." % hud_path)
		return
	if _hud != null:
		_hud.visible = show_hud

	content = ContentCatalog.new()
	if not content.load_default_content():
		push_error("Default content could not be loaded.")
		return

	_apply_visual_theme()
	controller = RunController.new(content)
	run_state = controller.start_new_run(1)
	_apply_shop_board_slot_positions()

	_apply_board_defaults()
	_ensure_screen_drag_layer()
	_bind_board_camera()
	_connect_board_signals()
	if show_hud:
		_connect_hud_signals()
	_board_view.bind_run(run_state, content)
	_apply_pending_events()
	_update_hud()

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
	_update_hud()

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
	_update_hud()

func request_toggle_pause() -> void:
	if run_state == null:
		return
	request_set_paused(not run_state.is_paused)

func request_start_next_sprint() -> void:
	if controller == null:
		return
	controller.start_next_sprint()
	_apply_pending_events()
	_update_hud()

func request_auto_pay() -> void:
	if controller == null:
		return
	controller.auto_pay_all_employees()
	_apply_pending_events()
	_update_hud()

func request_save_current_run() -> bool:
	if controller == null:
		return false
	var saved: bool = controller.save_current_run(DEV_SAVE_PATH)
	if not saved:
		for error: String in controller.get_save_errors():
			push_warning(error)
	_update_hud()
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
	_apply_shop_board_slot_positions()
	_bind_board_camera()
	_board_view.bind_run(run_state, content)
	_apply_pending_events()
	_update_hud()
	return true

func get_board_view() -> BoardView:
	return _board_view

func _apply_board_defaults() -> void:
	if _board_view.card_view_scene == null:
		_board_view.card_view_scene = ResourceLoader.load(CARD_VIEW_SCENE_PATH) as PackedScene
	if content.balance != null:
		_board_view.stack_offset = content.balance.stack_offset
		_board_view.snap_distance = content.balance.board_snap_distance

func _apply_visual_theme() -> void:
	if _hud != null and _hud.has_method("set_visual_theme"):
		_hud.call("set_visual_theme", content.visual_theme)

func _apply_shop_board_slot_positions() -> void:
	if run_state == null:
		return
	var slot_root: Node = get_node_or_null(shop_board_slots_path)
	if slot_root == null:
		return
	var slots: Array[ShopBoardSlot] = []
	_collect_shop_board_slots(slot_root, slots)
	for slot: ShopBoardSlot in slots:
		if slot.card_definition_id.strip_edges().is_empty():
			continue
		var shop_card: CardInstance = _find_card_by_definition_id(slot.card_definition_id)
		if shop_card == null:
			continue
		var stack: StackState = run_state.get_stack(shop_card.stack_id)
		if stack == null:
			continue
		stack.base_position = _board_view.to_local(slot.global_position)
		for card_id: String in stack.card_ids:
			var card: CardInstance = run_state.get_card(card_id)
			if card != null:
				card.position = stack.base_position

func _collect_shop_board_slots(node: Node, slots: Array[ShopBoardSlot]) -> void:
	for child: Node in node.get_children():
		if child is ShopBoardSlot:
			slots.append(child as ShopBoardSlot)
		_collect_shop_board_slots(child, slots)

func _find_card_by_definition_id(card_definition_id: String) -> CardInstance:
	if run_state == null:
		return null
	for card: CardInstance in run_state.cards.values():
		if card.definition_id == card_definition_id:
			return card
	return null

func _ensure_screen_drag_layer() -> void:
	_screen_drag_layer = get_node_or_null(drag_overlay_path) as Control
	if _screen_drag_layer != null:
		_board_view.screen_drag_layer = _screen_drag_layer
		return

	var overlay_layer: CanvasLayer = get_node_or_null("DragOverlayLayer") as CanvasLayer
	if overlay_layer == null:
		overlay_layer = CanvasLayer.new()
		overlay_layer.name = "DragOverlayLayer"
		overlay_layer.layer = DRAG_OVERLAY_LAYER
		add_child(overlay_layer)

	_screen_drag_layer = Control.new()
	_screen_drag_layer.name = "ScreenDragLayer"
	_screen_drag_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_screen_drag_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay_layer.add_child(_screen_drag_layer)
	_board_view.screen_drag_layer = _screen_drag_layer

func _bind_board_camera() -> void:
	if _board_camera == null or run_state == null:
		return
	_board_camera.bind_board(run_state.board)

func _connect_board_signals() -> void:
	_board_view.screen_drop_target_resolver = Callable()
	_board_view.screen_drag_finished_callback = Callable()
	_board_view.drop_interaction_preview_resolver = Callable(self, "_resolve_drop_interaction_preview_stacks")
	if not _board_view.move_stack_requested.is_connected(request_move_stack):
		_board_view.move_stack_requested.connect(request_move_stack)
	if not _board_view.move_card_to_stack_requested.is_connected(request_move_card_to_stack):
		_board_view.move_card_to_stack_requested.connect(request_move_card_to_stack)
	if not _board_view.split_stack_requested.is_connected(request_split_stack):
		_board_view.split_stack_requested.connect(request_split_stack)
	if not _board_view.card_clicked.is_connected(request_card_clicked):
		_board_view.card_clicked.connect(request_card_clicked)
	if _board_camera != null and not _board_view.board_pan_requested.is_connected(_board_camera.pan_by_viewport_delta):
		_board_view.board_pan_requested.connect(_board_camera.pan_by_viewport_delta)

func _connect_hud_signals() -> void:
	if _hud == null:
		return
	if not _hud.is_connected("auto_pay_requested", request_auto_pay):
		_hud.connect("auto_pay_requested", request_auto_pay)
	if not _hud.is_connected("next_sprint_requested", request_start_next_sprint):
		_hud.connect("next_sprint_requested", request_start_next_sprint)
	if not _hud.is_connected("save_requested", request_save_current_run):
		_hud.connect("save_requested", request_save_current_run)
	if not _hud.is_connected("load_requested", request_load_saved_run):
		_hud.connect("load_requested", request_load_saved_run)

func request_card_clicked(card_id: String) -> void:
	if controller == null:
		return
	controller.open_booster_pack_step(card_id)
	_apply_pending_events()
	_update_hud()

func _apply_pending_events() -> void:
	if controller == null or _board_view == null:
		return
	var events: Array[SimulationEvent] = controller.drain_events()
	if not events.is_empty():
		_apply_shop_board_slot_positions()
		_board_view.apply_events(events)

func _resolve_drop_interaction_preview_stacks(card_id: String) -> PackedStringArray:
	if controller == null:
		return PackedStringArray()
	return controller.get_drop_interaction_preview_stack_ids(card_id)

func _update_hud() -> void:
	if not show_hud or _hud == null or run_state == null or controller == null:
		return
	var sprint_remaining: float = run_state.active_timers.get(RunController.SPRINT_TIMER_ID, 0.0) as float
	_hud.call(
		"update_from_run",
		run_state,
		sprint_remaining,
		controller.can_auto_pay(),
		controller.can_save_current_run(),
		FileAccess.file_exists(DEV_SAVE_PATH)
	)

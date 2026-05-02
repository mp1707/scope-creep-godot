class_name CardView
extends Control

signal drag_started(card_id: String, pointer_offset: Vector2)
signal drag_moved(card_id: String, global_position: Vector2)
signal drag_ended(card_id: String, global_position: Vector2)

const DEFAULT_CARD_SIZE: Vector2 = Vector2(144.0, 196.0)

@export var background_path: NodePath
@export var title_label_path: NodePath
@export var short_text_label_path: NodePath
@export var marker_label_path: NodePath
@export var progress_bar_path: NodePath
@export var action_label_path: NodePath

var card_id: String = ""
var stack_id: String = ""

var _background: Control = null
var _title_label: Label = null
var _short_text_label: Label = null
var _marker_label: Label = null
var _progress_bar: ProgressBar = null
var _action_label: Label = null
var _is_dragging: bool = false
var _pointer_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	custom_minimum_size = DEFAULT_CARD_SIZE
	size = DEFAULT_CARD_SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP
	_resolve_or_create_nodes()

func setup(card: CardInstance, definition: CardDefinition, stack: StackState) -> void:
	card_id = card.instance_id
	stack_id = card.stack_id
	_resolve_or_create_nodes()
	_apply_definition(definition)
	update_runtime(card, stack)

func update_runtime(card: CardInstance, stack: StackState) -> void:
	card_id = card.instance_id
	stack_id = card.stack_id
	_update_progress(stack)
	_update_runtime_marker(card)

func set_drag_preview_position(board_position: Vector2) -> void:
	position = board_position
	z_index = 1000

func clear_drag_preview() -> void:
	z_index = 0

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.button_index != MOUSE_BUTTON_LEFT:
			return
		if mouse_event.pressed:
			_is_dragging = true
			_pointer_offset = get_global_mouse_position() - global_position
			drag_started.emit(card_id, _pointer_offset)
		else:
			if _is_dragging:
				_is_dragging = false
				drag_ended.emit(card_id, get_global_mouse_position() - _pointer_offset)

	if event is InputEventMouseMotion and _is_dragging:
		drag_moved.emit(card_id, get_global_mouse_position() - _pointer_offset)

func _resolve_or_create_nodes() -> void:
	if _background == null:
		_background = get_node_or_null(background_path) as Control
	if _title_label == null:
		_title_label = get_node_or_null(title_label_path) as Label
	if _short_text_label == null:
		_short_text_label = get_node_or_null(short_text_label_path) as Label
	if _marker_label == null:
		_marker_label = get_node_or_null(marker_label_path) as Label
	if _progress_bar == null:
		_progress_bar = get_node_or_null(progress_bar_path) as ProgressBar
	if _action_label == null:
		_action_label = get_node_or_null(action_label_path) as Label

	if _background == null:
		_background = ColorRect.new()
		_background.name = "Background"
		_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_background)
		move_child(_background, 0)

	if _title_label == null:
		_title_label = _create_label("TitleLabel", Vector2(12.0, 10.0), Vector2(120.0, 26.0), HORIZONTAL_ALIGNMENT_LEFT)
	if _marker_label == null:
		_marker_label = _create_label("MarkerLabel", Vector2(98.0, 42.0), Vector2(34.0, 24.0), HORIZONTAL_ALIGNMENT_CENTER)
	if _short_text_label == null:
		_short_text_label = _create_label("ShortTextLabel", Vector2(12.0, 74.0), Vector2(120.0, 62.0), HORIZONTAL_ALIGNMENT_LEFT)
		_short_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if _progress_bar == null:
		_progress_bar = ProgressBar.new()
		_progress_bar.name = "ProgressBar"
		_progress_bar.position = Vector2(12.0, 148.0)
		_progress_bar.size = Vector2(120.0, 12.0)
		_progress_bar.show_percentage = false
		_progress_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_progress_bar)
	if _action_label == null:
		_action_label = _create_label("ActionLabel", Vector2(12.0, 164.0), Vector2(120.0, 20.0), HORIZONTAL_ALIGNMENT_CENTER)

func _create_label(node_name: String, label_position: Vector2, label_size: Vector2, alignment: HorizontalAlignment) -> Label:
	var label: Label = Label.new()
	label.name = node_name
	label.position = label_position
	label.size = label_size
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.clip_text = true
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label

func _apply_definition(definition: CardDefinition) -> void:
	_title_label.text = definition.display_name
	_short_text_label.text = definition.short_text

	var visual: CardVisualDefinition = definition.visual
	if visual == null:
		visual = CardVisualDefinition.new()

	_marker_label.text = visual.marker_text
	for label: Label in [_title_label, _short_text_label, _marker_label, _action_label]:
		label.add_theme_color_override("font_color", visual.text_color)

	if _background is ColorRect:
		(_background as ColorRect).color = visual.background_color
	else:
		var style_box: StyleBoxFlat = StyleBoxFlat.new()
		style_box.bg_color = visual.background_color
		style_box.border_color = visual.accent_color
		style_box.border_width_bottom = 2
		style_box.border_width_left = 2
		style_box.border_width_right = 2
		style_box.border_width_top = 2
		_background.add_theme_stylebox_override("panel", style_box)

func _update_progress(stack: StackState) -> void:
	var processing: ProcessingState = stack.processing_state
	var is_active: bool = processing.status == ScopeEnums.ProcessingStatus.ACTIVE and processing.duration > 0.0
	_progress_bar.visible = is_active
	_action_label.visible = is_active
	if not is_active:
		_progress_bar.value = 0.0
		_action_label.text = ""
		return

	_progress_bar.max_value = processing.duration
	_progress_bar.value = processing.elapsed
	_action_label.text = "..."

func _update_runtime_marker(card: CardInstance) -> void:
	if card.state == null or card.state.markers.is_empty():
		return
	_marker_label.text = card.state.markers[0]

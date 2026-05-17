class_name BoardDropFeedbackPresenter
extends RefCounted

const INTERACTION_HIGHLIGHT_Z_OFFSET: int = 6
const INTERACTION_HIGHLIGHT_VIEW_SCENE: PackedScene = preload("res://scenes/presentation/InteractionHighlightView.tscn")
const STACK_DROP_HIGHLIGHT_MARGIN: float = 26.0
const STACK_DROP_HIGHLIGHT_Z_OFFSET: int = 7
const STACK_DROP_HIGHLIGHT_VIEW_SCENE: PackedScene = preload("res://scenes/presentation/StackDropHighlightView.tscn")

var board_view: Node = null
var state: RunState = null
var content: ContentCatalog = null
var visual_theme: Resource = null
var card_size: Vector2 = Vector2(144.0, 180.0)
var stack_offset: Vector2 = Vector2(0.0, 26.0)

var _interaction_highlight_views: Dictionary = {}
var _drag_preview_card_ids: PackedStringArray = PackedStringArray()
var _layout: StackLayout = StackLayout.new()

func setup(
	host: Node,
	run_state: RunState,
	content_catalog: ContentCatalog,
	theme: Resource,
	current_card_size: Vector2,
	current_stack_offset: Vector2
) -> void:
	board_view = host
	state = run_state
	content = content_catalog
	visual_theme = theme
	card_size = current_card_size
	stack_offset = current_stack_offset
	_layout.card_size = card_size
	_layout.stack_offset = stack_offset
	update_interaction_highlight_layouts()

func set_drag_preview_card_ids(card_ids: PackedStringArray) -> void:
	_drag_preview_card_ids = card_ids.duplicate()

func sync_interaction_preview_stack_ids(stack_ids: PackedStringArray) -> void:
	var board_stack_ids: PackedStringArray = PackedStringArray()
	for stack_id: String in stack_ids:
		if _should_show_board_interaction_highlight(stack_id):
			board_stack_ids.append(stack_id)

	var old_stack_ids: Array = _interaction_highlight_views.keys()
	for old_stack_id: String in old_stack_ids:
		if board_stack_ids.has(old_stack_id):
			continue
		_remove_interaction_highlight(old_stack_id)

	for stack_id: String in board_stack_ids:
		var highlight: Control = _ensure_interaction_highlight(stack_id)
		_update_interaction_highlight(stack_id, highlight)

func clear_interaction_preview() -> void:
	var stack_ids: Array = _interaction_highlight_views.keys()
	for stack_id: String in stack_ids:
		_remove_interaction_highlight(stack_id)

func clear_all() -> void:
	clear_interaction_preview()
	_drag_preview_card_ids = PackedStringArray()

func update_interaction_highlight_layouts() -> void:
	var stack_ids: Array = _interaction_highlight_views.keys()
	for stack_id: String in stack_ids:
		if not _should_show_board_interaction_highlight(stack_id):
			_remove_interaction_highlight(stack_id)
			continue
		_update_interaction_highlight(stack_id, _interaction_highlight_views[stack_id] as Control)

func play_stack_drop_highlight(card_id: String) -> void:
	if card_id.is_empty() or board_view == null:
		return
	var view: CardView = _get_card_view(card_id)
	if view == null:
		return
	var highlight: Control = STACK_DROP_HIGHLIGHT_VIEW_SCENE.instantiate() as Control
	highlight.name = "StackDropHighlight"
	highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board_view.add_child(highlight)
	highlight.call("randomize_orientation")
	_configure_stack_drop_highlight(card_id, view, highlight)
	highlight.call("play_snap_feedback")

func _configure_stack_drop_highlight(card_id: String, view: CardView, highlight: Control) -> void:
	if view == null or highlight == null:
		return
	var target_position: Vector2 = _get_card_layout_position(card_id, view.position)
	highlight.position = target_position - Vector2(STACK_DROP_HIGHLIGHT_MARGIN, STACK_DROP_HIGHLIGHT_MARGIN)
	highlight.z_index = view.z_index + STACK_DROP_HIGHLIGHT_Z_OFFSET
	highlight.call(
		"configure",
		card_size + Vector2(STACK_DROP_HIGHLIGHT_MARGIN * 2.0, STACK_DROP_HIGHLIGHT_MARGIN * 2.0),
		visual_theme,
		_get_card_visual(card_id)
	)

func _get_card_layout_position(card_id: String, fallback_position: Vector2) -> Vector2:
	if state == null:
		return fallback_position
	var card: CardInstance = state.get_card(card_id)
	if card == null:
		return fallback_position
	var stack: StackState = state.get_stack(card.stack_id)
	if stack == null:
		return fallback_position
	return _layout.get_card_position(stack, card_id)

func _should_show_board_interaction_highlight(stack_id: String) -> bool:
	if state == null or not state.stacks.has(stack_id):
		return false
	var stack: StackState = state.get_stack(stack_id)
	if _is_shop_stack(stack):
		return false
	if _drag_preview_card_ids.is_empty():
		return true
	for card_id: String in _drag_preview_card_ids:
		if stack.card_ids.has(card_id):
			return false
	return true

func _ensure_interaction_highlight(stack_id: String) -> Control:
	if _interaction_highlight_views.has(stack_id):
		return _interaction_highlight_views[stack_id] as Control
	var highlight: Control = INTERACTION_HIGHLIGHT_VIEW_SCENE.instantiate() as Control
	highlight.name = "InteractionHighlight_%s" % stack_id
	highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board_view.add_child(highlight)
	_interaction_highlight_views[stack_id] = highlight
	highlight.call("play_show")
	return highlight

func _remove_interaction_highlight(stack_id: String) -> void:
	var highlight: Control = _interaction_highlight_views.get(stack_id, null) as Control
	if highlight != null:
		highlight.queue_free()
	_interaction_highlight_views.erase(stack_id)

func _update_interaction_highlight(stack_id: String, highlight: Control) -> void:
	if state == null or highlight == null or not state.stacks.has(stack_id):
		return
	var card_id: String = _get_stack_top_rendered_card_id(stack_id)
	var view: CardView = _get_card_view(card_id)
	if view == null:
		return
	highlight.position = view.position
	highlight.z_index = view.z_index + INTERACTION_HIGHLIGHT_Z_OFFSET
	highlight.call(
		"configure",
		card_size,
		visual_theme,
		_get_card_visual(card_id)
	)

func _get_stack_top_rendered_card_id(stack_id: String) -> String:
	if state == null or not state.stacks.has(stack_id):
		return ""
	var stack: StackState = state.get_stack(stack_id)
	for index: int in range(stack.card_ids.size() - 1, -1, -1):
		var card_id: String = stack.card_ids[index]
		if _should_render_card_on_board(card_id):
			return card_id
	return ""

func _get_card_view(card_id: String) -> CardView:
	if board_view == null or not board_view.has_method("get_card_view"):
		return null
	return board_view.call("get_card_view", card_id) as CardView

func _get_card_visual(card_id: String) -> CardVisualDefinition:
	if state == null or content == null:
		return null
	var card: CardInstance = state.get_card(card_id)
	if card == null:
		return null
	var definition: CardDefinition = content.get_card_definition(card.definition_id)
	return definition.visual if definition != null else null

func _should_render_card_on_board(card_id: String) -> bool:
	if state == null or content == null:
		return false
	var card: CardInstance = state.get_card(card_id)
	if card == null:
		return false
	var stack: StackState = state.get_stack(card.stack_id)
	if stack != null and _is_shop_stack(stack):
		return false
	var definition: CardDefinition = content.get_card_definition(card.definition_id)
	return definition != null and not definition.tags.has("shop")

func _is_shop_stack(stack: StackState) -> bool:
	if stack == null or state == null or content == null:
		return false
	for card_id: String in stack.card_ids:
		var card: CardInstance = state.get_card(card_id)
		if card == null:
			continue
		var definition: CardDefinition = content.get_card_definition(card.definition_id)
		if definition != null and definition.tags.has("shop"):
			return true
	return false

class_name ShopDockView
extends Control

const SHOP_DOCK_Z: int = 100
const SHOP_HOVER_Z_OFFSET: int = 100
const SHOP_ORDER_VALUE: String = "shop_dock_order"
const ShopDockSlotScript: Script = preload("res://scripts/presentation/shop_dock_slot.gd")
const ShopInteractionServiceScript: Script = preload("res://scripts/simulation/shop_interaction_service.gd")

@export var card_view_scene: PackedScene
@export var card_size: Vector2 = Vector2(144.0, 196.0)
@export var visible_height: float = 72.0
@export var hover_raise: float = 54.0
@export var slot_gap: float = 20.0
@export var side_margin: float = 32.0
@export var bottom_margin: float = 0.0
@export var hover_tween_seconds: float = 0.10
@export var use_editor_slots: bool = true

var state: RunState = null
var content: ContentCatalog = null

var _card_views: Dictionary = {}
var _base_positions: Dictionary = {}
var _hovered_stack_id: String = ""
var _shop_interactions: RefCounted = ShopInteractionServiceScript.new()

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = SHOP_DOCK_Z
	var viewport: Viewport = get_viewport()
	if viewport != null and not viewport.size_changed.is_connected(_layout_shop_cards):
		viewport.size_changed.connect(_layout_shop_cards)

func bind_run(run_state: RunState, content_catalog: ContentCatalog) -> void:
	state = run_state
	content = content_catalog
	_shop_interactions.setup(state, content)
	refresh()

func apply_events(_events: Array[SimulationEvent]) -> void:
	refresh()

func refresh() -> void:
	if state == null or content == null:
		return

	var shop_card_ids: PackedStringArray = _get_shop_card_ids()
	for card_id: String in _card_views.keys():
		if not shop_card_ids.has(card_id):
			_remove_card_view(card_id)

	for card_id: String in shop_card_ids:
		_ensure_card_view(card_id)
		_update_card_view(card_id)
	_layout_shop_cards()

func find_drop_stack_id(card_id: String, viewport_position: Vector2, moving_card_count: int) -> String:
	var stack_id: String = ""
	for shop_card_id: String in _get_shop_card_ids():
		var view: CardView = get_card_view(shop_card_id)
		var shop_card: CardInstance = state.get_card(shop_card_id)
		if view == null or shop_card == null:
			continue
		if _get_drop_rect(view).has_point(viewport_position) and _shop_interactions.can_drop_card_on_shop(card_id, moving_card_count, shop_card):
			stack_id = shop_card.stack_id
			break

	set_hovered_stack_id(stack_id)
	return stack_id

func set_hovered_stack_id(stack_id: String) -> void:
	if _hovered_stack_id == stack_id:
		return
	_hovered_stack_id = stack_id
	_layout_shop_cards()

func get_card_view(card_id: String) -> CardView:
	return _card_views.get(card_id, null) as CardView

func _ensure_card_view(card_id: String) -> CardView:
	if _card_views.has(card_id):
		return _card_views[card_id] as CardView

	var view: CardView = null
	if card_view_scene != null:
		view = card_view_scene.instantiate() as CardView
	if view == null:
		view = CardView.new()

	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(view)
	_card_views[card_id] = view
	return view

func _remove_card_view(card_id: String) -> void:
	var view: CardView = get_card_view(card_id)
	if view != null:
		view.queue_free()
	_card_views.erase(card_id)
	_base_positions.erase(card_id)

func _update_card_view(card_id: String) -> void:
	var card: CardInstance = state.get_card(card_id)
	if card == null:
		_remove_card_view(card_id)
		return
	var definition: CardDefinition = content.get_card_definition(card.definition_id)
	var stack: StackState = state.get_stack(card.stack_id)
	if definition == null or stack == null:
		return
	var view: CardView = _ensure_card_view(card_id)
	view.setup(card, definition, stack)

func _layout_shop_cards() -> void:
	if state == null or content == null:
		return

	var shop_card_ids: PackedStringArray = _get_shop_card_ids()
	var auto_layout_card_ids: PackedStringArray = PackedStringArray()
	for card_id: String in shop_card_ids:
		var slot: Control = _get_editor_slot_for_card_id(card_id)
		if slot == null:
			auto_layout_card_ids.append(card_id)
			continue
		_layout_card_in_editor_slot(card_id, slot)

	_layout_auto_cards(auto_layout_card_ids)

func _layout_card_in_editor_slot(card_id: String, slot: Control) -> void:
	var card: CardInstance = state.get_card(card_id)
	var view: CardView = get_card_view(card_id)
	if card == null or view == null:
		return

	if view.get_parent() != slot:
		view.reparent(slot, false)
	var is_hovered: bool = card.stack_id == _hovered_stack_id
	var card_offset: Vector2 = slot.get("card_offset") as Vector2
	_base_positions[card_id] = card_offset
	view.z_index = SHOP_DOCK_Z + slot.get_index() + (SHOP_HOVER_Z_OFFSET if is_hovered else 0)
	_move_view(view, slot.call("get_card_position", is_hovered) as Vector2)

func _layout_auto_cards(shop_card_ids: PackedStringArray) -> void:
	var count: int = shop_card_ids.size()
	if count <= 0:
		return

	var viewport_size: Vector2 = _get_viewport_size()
	var total_width: float = card_size.x * float(count) + slot_gap * float(count - 1)
	var start_x: float = maxf(side_margin, (viewport_size.x - total_width) * 0.5)
	var base_y: float = viewport_size.y - visible_height + bottom_margin

	for index: int in count:
		var card_id: String = shop_card_ids[index]
		var card: CardInstance = state.get_card(card_id)
		var view: CardView = get_card_view(card_id)
		if card == null or view == null:
			continue

		if view.get_parent() != self:
			view.reparent(self, false)
		var base_position: Vector2 = Vector2(start_x + float(index) * (card_size.x + slot_gap), base_y)
		var target_position: Vector2 = base_position
		var is_hovered: bool = card.stack_id == _hovered_stack_id
		if is_hovered:
			target_position.y -= hover_raise
		_base_positions[card_id] = base_position
		view.z_index = SHOP_DOCK_Z + index + (SHOP_HOVER_Z_OFFSET if is_hovered else 0)
		_move_view(view, target_position)

func _move_view(view: CardView, target_position: Vector2) -> void:
	if DisplayServer.get_name() == "headless" or not is_inside_tree():
		view.position = target_position
		return

	var tween: Tween = view.create_tween()
	tween.tween_property(view, "position", target_position, hover_tween_seconds)

func _get_shop_card_ids() -> PackedStringArray:
	var shop_card_ids: Array[String] = []
	for card: CardInstance in state.cards.values():
		var definition: CardDefinition = content.get_card_definition(card.definition_id)
		if definition != null and definition.tags.has("shop"):
			shop_card_ids.append(card.instance_id)

	shop_card_ids.sort_custom(func(left: String, right: String) -> bool:
		return _get_shop_order(left) < _get_shop_order(right)
	)

	var result: PackedStringArray = PackedStringArray()
	for card_id: String in shop_card_ids:
		result.append(card_id)
	return result

func _get_editor_slot_for_card_id(card_id: String) -> Control:
	if not use_editor_slots:
		return null
	var card: CardInstance = state.get_card(card_id)
	if card == null:
		return null
	for slot: Control in _get_editor_slots():
		if slot.get("card_definition_id") as String == card.definition_id:
			return slot
	return null

func _get_editor_slots() -> Array[Control]:
	var slots: Array[Control] = []
	for child: Node in get_children():
		if child is Control and child.get_script() == ShopDockSlotScript:
			var slot: Control = child as Control
			if not (slot.get("card_definition_id") as String).is_empty():
				slots.append(slot)
	return slots

func _get_shop_order(card_id: String) -> int:
	var card: CardInstance = state.get_card(card_id)
	if card == null:
		return 100000
	var order_value: Variant = card.values.get(SHOP_ORDER_VALUE, null)
	if order_value != null:
		return int(order_value)
	var definition: CardDefinition = content.get_card_definition(card.definition_id)
	if definition == null:
		return 100000
	return definition.display_name.hash()

func _get_drop_rect(view: CardView) -> Rect2:
	if _is_view_in_editor_slot(view):
		return view.get_global_rect()
	var viewport_size: Vector2 = _get_viewport_size()
	var visible_bottom: float = viewport_size.y
	var visible_height_for_view: float = maxf(0.0, visible_bottom - view.position.y)
	return Rect2(view.position, Vector2(card_size.x, maxf(visible_height, visible_height_for_view)))

func _is_view_in_editor_slot(view: CardView) -> bool:
	return view != null and view.get_parent() != null and view.get_parent().get_script() == ShopDockSlotScript

func _get_viewport_size() -> Vector2:
	var viewport: Viewport = get_viewport()
	if viewport == null:
		return BoardState.INITIAL_VIEWPORT_SIZE
	return viewport.get_visible_rect().size

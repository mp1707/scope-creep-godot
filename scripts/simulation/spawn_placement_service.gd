class_name SpawnPlacementService
extends RefCounted

const CARD_SIZE: Vector2 = Vector2(144.0, 196.0)
const GAP: float = 36.0
const BOARD_MARGIN: float = 56.0
const SEARCH_RINGS: int = 7
const INVALID_POSITION: Vector2 = Vector2(100000000.0, 100000000.0)

var state: RunState = null
var content: ContentCatalog = null

func setup(run_state: RunState, content_catalog: ContentCatalog) -> void:
	state = run_state
	content = content_catalog

func get_spawn_position_near_stack(source_stack_id: String, spawn_index: int = 0) -> Vector2:
	prune_stale_spawn_history()
	var source_position: Vector2 = _get_spawn_source_position(source_stack_id)

	var step_x: float = CARD_SIZE.x + GAP
	var step_y: float = CARD_SIZE.y + GAP
	var candidates: Array[Vector2] = []
	var directions: Array[Vector2] = [
		Vector2.RIGHT,
		Vector2.DOWN,
		Vector2.LEFT,
		Vector2.UP,
		Vector2(1.0, 1.0),
		Vector2(-1.0, 1.0),
		Vector2(1.0, -1.0),
		Vector2(-1.0, -1.0),
	]

	var radius: float = 160.0
	if content.balance != null:
		radius = maxf(radius, content.balance.spawn_placement_radius)
	for ring: int in SEARCH_RINGS:
		var ring_distance: Vector2 = Vector2(radius + float(ring) * step_x, radius + float(ring) * step_y)
		for direction: Vector2 in directions:
			candidates.append(source_position + Vector2(direction.x * ring_distance.x, direction.y * ring_distance.y))

	var spawn_row: int = floori(float(spawn_index) / 4.0)
	var spawn_column: int = spawn_index % 4
	if spawn_index > 0:
		candidates.append(source_position + Vector2(float(spawn_column + 1) * step_x, float(spawn_row) * step_y))

	for candidate: Vector2 in candidates:
		if not _does_spawn_overlap(candidate):
			state.board.spawn_history.append(candidate)
			return candidate

	var grid_position: Vector2 = _find_free_spawn_grid_position(source_position)
	if grid_position != INVALID_POSITION:
		state.board.spawn_history.append(grid_position)
		return grid_position

	var fallback: Vector2 = _clamp_spawn_position_to_board(source_position + Vector2(step_x * float(spawn_index + 1), step_y))
	state.board.spawn_history.append(fallback)
	return fallback

func get_spawn_position_near_position(source_position: Vector2, spawn_index: int = 0) -> Vector2:
	prune_stale_spawn_history()
	var step_x: float = CARD_SIZE.x + GAP
	var fallback_source: Vector2 = _clamp_spawn_position_to_board(source_position)
	var temporary_stack: StackState = StackState.new()
	temporary_stack.stack_id = "__spawn_source"
	temporary_stack.base_position = fallback_source
	state.stacks[temporary_stack.stack_id] = temporary_stack
	var position: Vector2 = get_spawn_position_near_stack(temporary_stack.stack_id, spawn_index)
	state.stacks.erase(temporary_stack.stack_id)
	if position == INVALID_POSITION:
		return _clamp_spawn_position_to_board(fallback_source + Vector2(step_x * float(spawn_index + 1), CARD_SIZE.y + GAP))
	return position

func find_auto_stack_spawn_target(definition: CardDefinition, position: Vector2) -> StackState:
	if definition == null or not definition.auto_stack_on_spawn:
		return null

	var radius: float = _get_auto_stack_spawn_radius()
	if radius <= 0.0:
		return null

	var best_stack: StackState = null
	var best_distance: float = radius
	for stack: StackState in state.stacks.values():
		if is_shop_stack(stack):
			continue
		if not _is_pure_stack_for_definition(stack, definition.id):
			continue
		var distance: float = stack.base_position.distance_to(position)
		if distance <= best_distance:
			best_distance = distance
			best_stack = stack
	return best_stack

func prune_stale_spawn_history() -> void:
	if state == null or state.board.spawn_history.is_empty():
		return

	var active_history: Array[Vector2] = []
	for previous_position: Vector2 in state.board.spawn_history:
		if _is_spawn_history_position_occupied(previous_position):
			active_history.append(previous_position)
	state.board.spawn_history = active_history

func is_shop_stack(stack: StackState) -> bool:
	if stack == null:
		return false
	for card_id: String in stack.card_ids:
		var card: CardInstance = state.get_card(card_id)
		if card == null:
			continue
		var definition: CardDefinition = content.get_card_definition(card.definition_id)
		if definition != null and definition.tags.has("shop"):
			return true
	return false

func _is_spawn_history_position_occupied(position: Vector2) -> bool:
	var history_rect: Rect2 = Rect2(position, CARD_SIZE)
	for stack: StackState in state.stacks.values():
		if is_shop_stack(stack):
			continue
		if history_rect.intersects(_get_stack_rect(stack)):
			return true
	return false

func _does_spawn_overlap(position: Vector2) -> bool:
	var spawn_rect: Rect2 = Rect2(position, CARD_SIZE)
	if not _get_spawn_bounds().encloses(spawn_rect):
		return true
	for reserved_area: Rect2 in state.board.reserved_areas:
		if spawn_rect.intersects(reserved_area):
			return true
	for previous_position: Vector2 in state.board.spawn_history:
		if spawn_rect.intersects(Rect2(previous_position, CARD_SIZE)):
			return true
	for stack: StackState in state.stacks.values():
		if is_shop_stack(stack):
			continue
		if spawn_rect.intersects(_get_stack_rect(stack)):
			return true
	return false

func _get_spawn_source_position(source_stack_id: String) -> Vector2:
	if not state.stacks.has(source_stack_id):
		return Vector2.ZERO

	var source_stack: StackState = state.get_stack(source_stack_id)
	if is_shop_stack(source_stack):
		return _get_shop_spawn_source_position()
	return source_stack.base_position

func _get_shop_spawn_source_position() -> Vector2:
	var safe_zoom: float = 1.0
	if state.board.camera_zoom.x > 0.0:
		safe_zoom = state.board.camera_zoom.x
	var visible_size: Vector2 = BoardState.INITIAL_VIEWPORT_SIZE / safe_zoom
	var source_position: Vector2 = state.board.camera_position + Vector2(
		0.0,
		visible_size.y * 0.5 - CARD_SIZE.y - 160.0
	)
	return _clamp_spawn_position_to_board(source_position)

func _get_spawn_bounds() -> Rect2:
	var board_size: Vector2 = state.board.size
	var available_size: Vector2 = Vector2(
		maxf(CARD_SIZE.x, board_size.x - BOARD_MARGIN * 2.0),
		maxf(CARD_SIZE.y, board_size.y - BOARD_MARGIN * 2.0)
	)
	return Rect2(Vector2(BOARD_MARGIN, BOARD_MARGIN), available_size)

func _clamp_spawn_position_to_board(position: Vector2) -> Vector2:
	var bounds: Rect2 = _get_spawn_bounds()
	return Vector2(
		clampf(position.x, bounds.position.x, bounds.end.x - CARD_SIZE.x),
		clampf(position.y, bounds.position.y, bounds.end.y - CARD_SIZE.y)
	)

func _find_free_spawn_grid_position(source_position: Vector2) -> Vector2:
	var bounds: Rect2 = _get_spawn_bounds()
	var step: Vector2 = CARD_SIZE + Vector2(GAP, GAP)
	var column_count: int = maxi(1, floori((bounds.size.x - CARD_SIZE.x) / step.x) + 1)
	var row_count: int = maxi(1, floori((bounds.size.y - CARD_SIZE.y) / step.y) + 1)
	var candidates: Array[Vector2] = []
	for row: int in row_count:
		for column: int in column_count:
			candidates.append(bounds.position + Vector2(float(column) * step.x, float(row) * step.y))

	candidates.sort_custom(func(left: Vector2, right: Vector2) -> bool:
		return left.distance_squared_to(source_position) < right.distance_squared_to(source_position)
	)

	for candidate: Vector2 in candidates:
		if not _does_spawn_overlap(candidate):
			return candidate
	return INVALID_POSITION

func _get_stack_rect(stack: StackState) -> Rect2:
	if stack.card_ids.is_empty():
		return Rect2(stack.base_position, CARD_SIZE)

	var stack_offset: Vector2 = Vector2(0.0, 26.0)
	if content.balance != null:
		stack_offset = content.balance.stack_offset
	var bottom_position: Vector2 = stack.base_position + stack_offset * float(stack.card_ids.size() - 1)
	var min_position: Vector2 = Vector2(
		minf(stack.base_position.x, bottom_position.x),
		minf(stack.base_position.y, bottom_position.y)
	)
	var max_position: Vector2 = Vector2(
		maxf(stack.base_position.x + CARD_SIZE.x, bottom_position.x + CARD_SIZE.x),
		maxf(stack.base_position.y + CARD_SIZE.y, bottom_position.y + CARD_SIZE.y)
	)
	return Rect2(min_position, max_position - min_position)

func _is_pure_stack_for_definition(stack: StackState, card_definition_id: String) -> bool:
	if stack == null or stack.card_ids.is_empty():
		return false

	for card_id: String in stack.card_ids:
		var card: CardInstance = state.get_card(card_id)
		if card == null:
			return false
		if card.definition_id != card_definition_id:
			return false
		if not card.parent_card_id.is_empty():
			return false
	return true

func _get_auto_stack_spawn_radius() -> float:
	if content.balance == null:
		return 180.0
	return content.balance.auto_stack_spawn_radius

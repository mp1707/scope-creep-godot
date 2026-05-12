class_name RunSaveSerializer
extends RefCounted

const SCHEMA_VERSION: int = 1

var errors: PackedStringArray = PackedStringArray()

func can_save_run(state: RunState) -> bool:
	if state == null:
		return false
	if state.phase == ScopeEnums.RunPhase.PAYMENT:
		return true
	return state.phase == ScopeEnums.RunPhase.SPRINT and state.is_paused

func save_to_file(state: RunState, path: String) -> bool:
	errors = PackedStringArray()
	if not can_save_run(state):
		errors.append("Save is only allowed while the run is paused or in payment.")
		return false

	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		errors.append("Could not open save file for writing: %s" % path)
		return false

	file.store_string(JSON.stringify(serialize_run(state), "\t"))
	return true

func load_from_file(path: String, content: ContentCatalog) -> RunState:
	errors = PackedStringArray()
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		errors.append("Could not open save file for reading: %s" % path)
		return null

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		errors.append("Save file is not valid JSON object data: %s" % path)
		return null

	return deserialize_run(parsed as Dictionary, content)

func serialize_run(state: RunState) -> Dictionary:
	var card_snapshots: Array[Dictionary] = []
	var card_ids: Array[String] = []
	for card_id: String in state.cards.keys():
		card_ids.append(card_id)
	card_ids.sort()
	for card_id: String in card_ids:
		var card: CardInstance = state.get_card(card_id)
		if card != null:
			card_snapshots.append(_serialize_card(card))

	var stack_snapshots: Array[Dictionary] = []
	var stack_ids: Array[String] = []
	for stack_id: String in state.stacks.keys():
		stack_ids.append(stack_id)
	stack_ids.sort()
	for stack_id: String in stack_ids:
		var stack: StackState = state.get_stack(stack_id)
		if stack != null:
			stack_snapshots.append(_serialize_stack(stack))

	return {
		"schema_version": SCHEMA_VERSION,
		"run_id": state.run_id,
		"sprint_index": state.sprint_index,
		"phase": int(state.phase),
		"is_paused": state.is_paused,
		"rng_seed": state.rng_seed,
		"rng_state": str(state.rng_state),
		"content_version": state.content_version,
		"completed_business_goal_count": state.completed_business_goal_count,
		"active_timers": _encode_value(state.active_timers),
		"paid_employee_ids": _packed_string_array_to_array(state.paid_employee_ids),
		"board": _serialize_board(state.board),
		"cards": card_snapshots,
		"stacks": stack_snapshots,
	}

func deserialize_run(data: Dictionary, content: ContentCatalog) -> RunState:
	errors = PackedStringArray()
	if content == null:
		errors.append("Content catalog is required for loading.")
		return null
	if int(data.get("schema_version", 0)) != SCHEMA_VERSION:
		errors.append("Unsupported save schema version: %s" % str(data.get("schema_version", null)))
		return null

	var loaded_state: RunState = RunState.new()
	loaded_state.run_id = data.get("run_id", "") as String
	loaded_state.sprint_index = int(data.get("sprint_index", 1))
	loaded_state.phase = int(data.get("phase", ScopeEnums.RunPhase.SPRINT)) as ScopeEnums.RunPhase
	loaded_state.is_paused = bool(data.get("is_paused", false))
	loaded_state.rng_seed = int(data.get("rng_seed", 0))
	loaded_state.rng_state = int(str(data.get("rng_state", "0")))
	loaded_state.content_version = data.get("content_version", "") as String
	loaded_state.completed_business_goal_count = int(data.get("completed_business_goal_count", 0))
	loaded_state.active_timers = _decode_value(data.get("active_timers", {})) as Dictionary
	loaded_state.paid_employee_ids = _array_to_packed_string_array(data.get("paid_employee_ids", []))
	loaded_state.board = _deserialize_board(data.get("board", {}) as Dictionary)
	loaded_state.cards = {}
	loaded_state.stacks = {}

	var cards_data: Array = data.get("cards", []) as Array
	for card_data: Dictionary in cards_data:
		var card: CardInstance = _deserialize_card(card_data)
		if card.instance_id.is_empty():
			errors.append("Save contains a card without instance_id.")
			continue
		if loaded_state.cards.has(card.instance_id):
			errors.append("Duplicate card instance_id in save: %s" % card.instance_id)
			continue
		if not content.has_card_definition(card.definition_id):
			errors.append("Save references missing card definition: %s" % card.definition_id)
			continue
		loaded_state.cards[card.instance_id] = card

	var stacks_data: Array = data.get("stacks", []) as Array
	for stack_data: Dictionary in stacks_data:
		var stack: StackState = _deserialize_stack(stack_data)
		if stack.stack_id.is_empty():
			errors.append("Save contains a stack without stack_id.")
			continue
		if loaded_state.stacks.has(stack.stack_id):
			errors.append("Duplicate stack_id in save: %s" % stack.stack_id)
			continue
		_validate_stack_cards(stack, loaded_state, content)
		loaded_state.stacks[stack.stack_id] = stack

	_validate_card_stack_references(loaded_state)
	if not errors.is_empty():
		return null

	loaded_state.is_paused = loaded_state.phase == ScopeEnums.RunPhase.SPRINT or loaded_state.phase == ScopeEnums.RunPhase.PAYMENT
	return loaded_state

func _serialize_card(card: CardInstance) -> Dictionary:
	return {
		"instance_id": card.instance_id,
		"definition_id": card.definition_id,
		"stack_id": card.stack_id,
		"parent_card_id": card.parent_card_id,
		"attachment_slot": card.attachment_slot,
		"position": _serialize_vector2(card.position),
		"state": _serialize_card_runtime_state(card.state),
		"values": _encode_value(card.values),
		"created_at_sprint": card.created_at_sprint,
	}

func _deserialize_card(data: Dictionary) -> CardInstance:
	var card: CardInstance = CardInstance.new()
	card.instance_id = data.get("instance_id", "") as String
	card.definition_id = data.get("definition_id", "") as String
	card.stack_id = data.get("stack_id", "") as String
	card.parent_card_id = data.get("parent_card_id", "") as String
	card.attachment_slot = data.get("attachment_slot", "") as String
	card.position = _deserialize_vector2(data.get("position", {}) as Dictionary)
	card.state = _deserialize_card_runtime_state(data.get("state", {}) as Dictionary)
	card.values = _decode_value(data.get("values", {})) as Dictionary
	card.created_at_sprint = int(data.get("created_at_sprint", 0))
	return card

func _serialize_card_runtime_state(state: CardRuntimeState) -> Dictionary:
	return {
		"is_locked": state.is_locked,
		"is_paid": state.is_paid,
		"is_payment_target": state.is_payment_target,
		"is_exhausted": state.is_exhausted,
		"markers": _packed_string_array_to_array(state.markers),
	}

func _deserialize_card_runtime_state(data: Dictionary) -> CardRuntimeState:
	var state: CardRuntimeState = CardRuntimeState.new()
	state.is_locked = bool(data.get("is_locked", false))
	state.is_paid = bool(data.get("is_paid", false))
	state.is_payment_target = bool(data.get("is_payment_target", false))
	state.is_exhausted = bool(data.get("is_exhausted", false))
	state.markers = _array_to_packed_string_array(data.get("markers", []))
	return state

func _serialize_stack(stack: StackState) -> Dictionary:
	return {
		"stack_id": stack.stack_id,
		"card_ids": _packed_string_array_to_array(stack.card_ids),
		"base_position": _serialize_vector2(stack.base_position),
		"processing_state": _serialize_processing_state(stack.processing_state),
	}

func _deserialize_stack(data: Dictionary) -> StackState:
	var stack: StackState = StackState.new()
	stack.stack_id = data.get("stack_id", "") as String
	stack.card_ids = _array_to_packed_string_array(data.get("card_ids", []))
	stack.base_position = _deserialize_vector2(data.get("base_position", {}) as Dictionary)
	stack.processing_state = _deserialize_processing_state(data.get("processing_state", {}) as Dictionary)
	return stack

func _serialize_processing_state(processing: ProcessingState) -> Dictionary:
	return {
		"active_recipe_id": processing.active_recipe_id,
		"status": int(processing.status),
		"elapsed": processing.elapsed,
		"duration": processing.duration,
	}

func _deserialize_processing_state(data: Dictionary) -> ProcessingState:
	var processing: ProcessingState = ProcessingState.new()
	processing.active_recipe_id = data.get("active_recipe_id", "") as String
	processing.status = int(data.get("status", ScopeEnums.ProcessingStatus.IDLE)) as ScopeEnums.ProcessingStatus
	processing.elapsed = float(data.get("elapsed", 0.0))
	processing.duration = float(data.get("duration", 0.0))
	return processing

func _serialize_board(board: BoardState) -> Dictionary:
	return {
		"size": _serialize_vector2(board.size),
		"camera_position": _serialize_vector2(board.camera_position),
		"camera_zoom": _serialize_vector2(board.camera_zoom),
		"reserved_areas": _encode_value(board.reserved_areas),
	}

func _deserialize_board(data: Dictionary) -> BoardState:
	var board: BoardState = BoardState.new()
	board.size = _deserialize_vector2(data.get("size", {}) as Dictionary)
	board.camera_position = _deserialize_vector2(data.get("camera_position", {}) as Dictionary)
	board.camera_zoom = _deserialize_vector2(data.get("camera_zoom", {"x": 1.0, "y": 1.0}) as Dictionary)
	board.reserved_areas = _decode_rect2_array(data.get("reserved_areas", []))
	board.spawn_history = _decode_vector2_array(data.get("spawn_history", []))
	return board

func _validate_stack_cards(stack: StackState, loaded_state: RunState, content: ContentCatalog) -> void:
	if not stack.processing_state.active_recipe_id.is_empty() and content.get_recipe_definition(stack.processing_state.active_recipe_id) == null:
		errors.append("Save references missing recipe definition: %s" % stack.processing_state.active_recipe_id)
	for card_id: String in stack.card_ids:
		if not loaded_state.cards.has(card_id):
			errors.append("Stack '%s' references missing card '%s'." % [stack.stack_id, card_id])

func _validate_card_stack_references(loaded_state: RunState) -> void:
	for paid_employee_id: String in loaded_state.paid_employee_ids:
		if not loaded_state.cards.has(paid_employee_id):
			errors.append("Paid employee list references missing card '%s'." % paid_employee_id)

	for card: CardInstance in loaded_state.cards.values():
		if not loaded_state.stacks.has(card.stack_id):
			errors.append("Card '%s' references missing stack '%s'." % [card.instance_id, card.stack_id])
			continue
		var stack: StackState = loaded_state.get_stack(card.stack_id)
		if stack != null and not stack.card_ids.has(card.instance_id):
			errors.append("Card '%s' is missing from its stack '%s'." % [card.instance_id, card.stack_id])
		if not card.parent_card_id.is_empty() and not loaded_state.cards.has(card.parent_card_id):
			errors.append("Card '%s' references missing parent card '%s'." % [card.instance_id, card.parent_card_id])

func _serialize_vector2(value: Vector2) -> Dictionary:
	return {"x": value.x, "y": value.y}

func _deserialize_vector2(data: Dictionary) -> Vector2:
	return Vector2(float(data.get("x", 0.0)), float(data.get("y", 0.0)))

func _serialize_rect2(value: Rect2) -> Dictionary:
	return {
		"position": _serialize_vector2(value.position),
		"size": _serialize_vector2(value.size),
	}

func _deserialize_rect2(data: Dictionary) -> Rect2:
	return Rect2(
		_deserialize_vector2(data.get("position", {}) as Dictionary),
		_deserialize_vector2(data.get("size", {}) as Dictionary)
	)

func _encode_value(value: Variant) -> Variant:
	match typeof(value):
		TYPE_VECTOR2:
			return {"__type": "Vector2", "value": _serialize_vector2(value as Vector2)}
		TYPE_RECT2:
			return {"__type": "Rect2", "value": _serialize_rect2(value as Rect2)}
		TYPE_PACKED_STRING_ARRAY:
			return {"__type": "PackedStringArray", "value": _packed_string_array_to_array(value as PackedStringArray)}
		TYPE_DICTIONARY:
			var result: Dictionary = {}
			for key: Variant in (value as Dictionary).keys():
				result[str(key)] = _encode_value((value as Dictionary)[key])
			return result
		TYPE_ARRAY:
			var result_array: Array = []
			for item: Variant in value as Array:
				result_array.append(_encode_value(item))
			return result_array
		_:
			return value

func _decode_value(value: Variant) -> Variant:
	if value is Dictionary:
		var dictionary: Dictionary = value as Dictionary
		var type_name: String = dictionary.get("__type", "") as String
		match type_name:
			"Vector2":
				return _deserialize_vector2(dictionary.get("value", {}) as Dictionary)
			"Rect2":
				return _deserialize_rect2(dictionary.get("value", {}) as Dictionary)
			"PackedStringArray":
				return _array_to_packed_string_array(dictionary.get("value", []))

		var result: Dictionary = {}
		for key: Variant in dictionary.keys():
			result[str(key)] = _decode_value(dictionary[key])
		return result
	if value is Array:
		var result_array: Array = []
		for item: Variant in value as Array:
			result_array.append(_decode_value(item))
		return result_array
	return value

func _packed_string_array_to_array(value: PackedStringArray) -> Array[String]:
	var result: Array[String] = []
	for item: String in value:
		result.append(item)
	return result

func _array_to_packed_string_array(value: Variant) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	if not value is Array:
		return result
	for item: Variant in value as Array:
		result.append(str(item))
	return result

func _decode_rect2_array(value: Variant) -> Array[Rect2]:
	var result: Array[Rect2] = []
	var decoded: Variant = _decode_value(value)
	if not decoded is Array:
		return result
	for item: Variant in decoded as Array:
		if item is Rect2:
			result.append(item as Rect2)
	return result

func _decode_vector2_array(value: Variant) -> Array[Vector2]:
	var result: Array[Vector2] = []
	var decoded: Variant = _decode_value(value)
	if not decoded is Array:
		return result
	for item: Variant in decoded as Array:
		if item is Vector2:
			result.append(item as Vector2)
	return result

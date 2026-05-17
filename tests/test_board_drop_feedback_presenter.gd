extends SceneTree

var _failed: bool = false

func _init() -> void:
	var catalog: ContentCatalog = ContentCatalog.new()
	_assert_true(catalog.load_default_content(), "Default content should load.")
	var controller: RunController = RunController.new(catalog)
	var state: RunState = _start_run_with_opened_startup(controller)
	var developer: CardInstance = _find_card_by_definition(state, "card.employee.developer")

	var board: BoardView = BoardView.new()
	board.card_view_scene = ResourceLoader.load("res://scenes/presentation/CardView.tscn") as PackedScene
	root.add_child(board)
	board.bind_run(state, catalog)

	var stack_ids: PackedStringArray = PackedStringArray([developer.stack_id])
	board.call("_set_interaction_preview_stack_ids", stack_ids)
	_assert_true(_has_child_name_prefix(board, "InteractionHighlight_"), "Board drop feedback presenter should create board interaction highlights.")

	board.free()
	if _failed:
		quit(1)
		return

	print("Board drop feedback presenter test passed.")
	quit(0)

func _start_run_with_opened_startup(controller: RunController) -> RunState:
	var state: RunState = controller.start_new_run(2010)
	var startup_pack: CardInstance = _find_card_by_definition(state, "card.resource.startup_booster_pack")
	while state.get_card(startup_pack.instance_id) != null:
		_assert_true(controller.open_booster_pack_step(startup_pack.instance_id), "Startup booster should open one card per step.")
	return state

func _find_card_by_definition(state: RunState, definition_id: String) -> CardInstance:
	for card: CardInstance in state.cards.values():
		if card.definition_id == definition_id:
			return card
	_assert_true(false, "Missing card with definition '%s'." % definition_id)
	return null

func _has_child_name_prefix(parent: Node, prefix: String) -> bool:
	for child: Node in parent.get_children():
		if child.name.begins_with(prefix):
			return true
	return false

func _assert_true(value: bool, message: String) -> void:
	if value:
		return
	_failed = true
	push_error(message)

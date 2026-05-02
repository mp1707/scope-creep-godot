class_name CardInstance
extends Resource

@export var instance_id: String = ""
@export var definition_id: String = ""
@export var stack_id: String = ""
@export var parent_card_id: String = ""
@export var attachment_slot: String = ""
@export var position: Vector2 = Vector2.ZERO
@export var state: CardRuntimeState = CardRuntimeState.new()
@export var values: Dictionary = {}
@export var created_at_sprint: int = 0

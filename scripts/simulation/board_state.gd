class_name BoardState
extends Resource

@export var size: Vector2 = Vector2(1920.0, 1080.0)
@export var camera_position: Vector2 = Vector2.ZERO
@export var camera_zoom: Vector2 = Vector2.ONE
@export var reserved_areas: Array[Rect2] = []
@export var spawn_history: Array[Vector2] = []

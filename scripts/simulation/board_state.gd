class_name BoardState
extends Resource

const INITIAL_VIEWPORT_SIZE: Vector2 = Vector2(1920.0, 1080.0)
const DEFAULT_SIZE: Vector2 = INITIAL_VIEWPORT_SIZE * 2.0

@export var size: Vector2 = DEFAULT_SIZE
@export var camera_position: Vector2 = INITIAL_VIEWPORT_SIZE * 0.5
@export var camera_zoom: Vector2 = Vector2.ONE
@export var reserved_areas: Array[Rect2] = []
@export var spawn_history: Array[Vector2] = []

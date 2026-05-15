class_name CardVisualDefinition
extends Resource

@export var visual_role_id: String = ""
@export var use_visual_role: bool = false
@export var override_background_color: bool = true
@export var background_color: Color = Color(0.18, 0.20, 0.24, 1.0)
@export var override_accent_color: bool = true
@export var accent_color: Color = Color(0.42, 0.72, 0.95, 1.0)
@export var override_text_color: bool = true
@export var text_color: Color = Color(0.94, 0.94, 0.90, 1.0)
@export var icon_texture: Texture2D
@export var override_icon_color: bool = true
@export var icon_color: Color = Color(0.06, 0.055, 0.05, 1.0)
@export var icon_size: Vector2 = Vector2(78.0, 78.0)
@export var icon_offset: Vector2 = Vector2.ZERO
@export var icon_recolor_alpha_mask: bool = true
@export var marker_text: String = ""

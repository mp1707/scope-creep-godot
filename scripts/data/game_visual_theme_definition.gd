class_name GameVisualThemeDefinition
extends Resource

@export var id: String = ""

@export var card_paper_texture: Texture2D
@export var card_icon_scribble_texture: Texture2D
@export var card_hairline_color: Color = Color(0.055, 0.052, 0.047, 0.22)
@export var card_text_color: Color = Color(0.075, 0.095, 0.12, 1.0)
@export var card_shadow_color: Color = Color(0.18, 0.15, 0.11, 1.0)
@export var card_drop_target_fill_color: Color = Color(0.055, 0.052, 0.047, 0.08)
@export var card_disabled_modulate: Color = Color(0.68, 0.68, 0.68, 1.0)
@export var card_paid_modulate: Color = Color(0.68, 0.86, 0.68, 1.0)
@export var card_payment_target_modulate: Color = Color(1.0, 0.96, 0.72, 1.0)
@export var interaction_preview_arrow_texture: Texture2D
@export var interaction_preview_arrow_size: Vector2 = Vector2(56.0, 56.0)
@export var interaction_preview_arrow_offset: Vector2 = Vector2(-20.0, -38.0)
@export var stack_drop_corner_texture: Texture2D
@export_range(8.0, 96.0, 1.0, "or_greater") var stack_drop_corner_size: float = 42.0
@export_range(-32.0, 32.0, 1.0) var stack_drop_corner_margin: float = 0.0
@export_range(0.0, 1.0, 0.01) var stack_drop_corner_alpha: float = 0.88

@export var tooltip_background_color: Color = Color(0.18, 0.22, 0.24, 0.98)
@export var tooltip_text_color: Color = Color(0.98, 0.96, 0.88, 1.0)

@export var status_badge_text_color: Color = Color(0.055, 0.052, 0.047, 1.0)
@export var status_badge_color: Color = Color(0.98, 0.91, 0.65, 0.96)
@export var status_badge_alert_color: Color = Color(0.98, 0.64, 0.58, 0.96)
@export var status_badge_paid_color: Color = Color(0.64, 0.86, 0.64, 0.96)

@export var board_background_color: Color = Color(0.982, 0.98, 0.966, 1.0)
@export var board_dot_color: Color = Color(0.075, 0.095, 0.12, 0.12)
@export_range(4.0, 256.0, 1.0, "or_greater") var board_dot_spacing: float = 32.0
@export_range(0.25, 8.0, 0.05, "or_greater") var board_dot_radius: float = 1.1
@export var progress_background_color: Color = Color(0.76, 0.76, 0.72, 1.0)
@export var progress_fill_color: Color = Color(0.18, 0.18, 0.17, 1.0)
@export var progress_border_color: Color = Color(0.18, 0.18, 0.17, 1.0)

@export var hud_text_color: Color = Color(0.055, 0.052, 0.047, 1.0)

@export var shop_preview_fill_color: Color = Color(0.98, 0.88, 0.58, 0.42)
@export var shop_preview_header_color: Color = Color(0.76, 0.60, 0.32, 0.42)
@export var shop_preview_hairline_color: Color = Color(0.055, 0.052, 0.047, 0.22)
@export var shop_preview_hover_color: Color = Color(0.28, 0.56, 0.78, 0.18)
@export var shop_drop_feedback_fill_color: Color = Color(0.055, 0.052, 0.047, 0.08)
@export var shop_preview_text_color: Color = Color(0.055, 0.052, 0.047, 0.78)

@export var card_roles: Array[Resource] = []

func get_card_role(role_id: String) -> Resource:
	if role_id.strip_edges().is_empty():
		return null
	for role: Resource in card_roles:
		if role != null and role.get("id") as String == role_id:
			return role
	return null

func get_card_background_color(visual: CardVisualDefinition) -> Color:
	var role: Resource = _get_visual_role(visual)
	if role != null and not visual.override_background_color:
		return role.get("background_color") as Color
	if visual != null:
		return visual.background_color
	return Color(0.18, 0.20, 0.24, 1.0)

func get_card_accent_color(visual: CardVisualDefinition) -> Color:
	var role: Resource = _get_visual_role(visual)
	if role != null and not visual.override_accent_color:
		return role.get("accent_color") as Color
	if visual != null:
		return visual.accent_color
	return Color(0.42, 0.72, 0.95, 1.0)

func get_card_text_color(visual: CardVisualDefinition) -> Color:
	var role: Resource = _get_visual_role(visual)
	if role != null and not visual.override_text_color:
		return role.get("text_color") as Color
	if visual != null:
		return visual.text_color
	return card_text_color

func get_card_icon_color(visual: CardVisualDefinition) -> Color:
	var role: Resource = _get_visual_role(visual)
	if role != null and not visual.override_icon_color:
		return _derive_card_icon_color(role.get("background_color") as Color, role.get("accent_color") as Color)
	if visual != null and visual.override_icon_color:
		return visual.icon_color
	return _derive_card_icon_color(get_card_background_color(visual), get_card_accent_color(visual))

func get_card_scribble_color(visual: CardVisualDefinition) -> Color:
	return _derive_card_scribble_color(get_card_background_color(visual), get_card_accent_color(visual))

func get_interaction_preview_color(visual: CardVisualDefinition) -> Color:
	return get_card_text_color(visual)

func get_stack_drop_corner_color(visual: CardVisualDefinition) -> Color:
	var derived: Color = get_card_accent_color(visual).lightened(0.12)
	derived.a = stack_drop_corner_alpha
	return derived

func _get_visual_role(visual: CardVisualDefinition) -> Resource:
	if visual == null or not visual.use_visual_role:
		return null
	return get_card_role(visual.visual_role_id)

func _derive_card_scribble_color(background_color: Color, accent_color: Color) -> Color:
	var derived: Color = background_color.lerp(accent_color, 0.72).darkened(0.22)
	derived.a = 0.64
	return derived

func _derive_card_icon_color(background_color: Color, accent_color: Color) -> Color:
	var derived: Color = background_color.lerp(accent_color, 0.96).darkened(0.70)
	derived.a = 1.0
	return derived

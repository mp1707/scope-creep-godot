class_name ProductLifecycleService
extends RefCounted

const SOFTWARE_DEFINITION_ID: String = "card.product.software"
const PRODUCT_STAGE_VALUE: String = "product_stage"
const FEATURE_COUNT_VALUE: String = "feature_count"
const MVP_REQUIRED_FEATURES_VALUE: String = "mvp_required_features"
const LAUNCH_FEATURE_COUNT_VALUE: String = "launch_feature_count"
const PRODUCT_STAGE_MVP: String = "mvp"
const PRODUCT_STAGE_LIVE: String = "live"
const DEFAULT_MVP_REQUIRED_FEATURES: int = 10

func get_software_card(state: RunState) -> CardInstance:
	if state == null:
		return null
	for card: CardInstance in state.cards.values():
		if card.definition_id == SOFTWARE_DEFINITION_ID:
			return card
	return null

func ensure_software_defaults(state: RunState) -> void:
	var software: CardInstance = get_software_card(state)
	if software != null:
		ensure_card_defaults(software)

func ensure_card_defaults(card: CardInstance) -> void:
	if card == null or card.definition_id != SOFTWARE_DEFINITION_ID:
		return
	if not card.values.has(PRODUCT_STAGE_VALUE):
		card.values[PRODUCT_STAGE_VALUE] = PRODUCT_STAGE_MVP
	if not card.values.has(FEATURE_COUNT_VALUE):
		card.values[FEATURE_COUNT_VALUE] = 0
	if not card.values.has(MVP_REQUIRED_FEATURES_VALUE):
		card.values[MVP_REQUIRED_FEATURES_VALUE] = DEFAULT_MVP_REQUIRED_FEATURES
	if not card.values.has(LAUNCH_FEATURE_COUNT_VALUE):
		card.values[LAUNCH_FEATURE_COUNT_VALUE] = 0

func is_launch_ready(state: RunState) -> bool:
	var software: CardInstance = get_software_card(state)
	if software == null:
		return false
	ensure_card_defaults(software)
	if get_product_stage(software) != PRODUCT_STAGE_MVP:
		return false
	return get_feature_count(software) >= get_mvp_required_features(software)

func get_product_stage(software: CardInstance) -> String:
	if software == null:
		return PRODUCT_STAGE_MVP
	ensure_card_defaults(software)
	return software.values.get(PRODUCT_STAGE_VALUE, PRODUCT_STAGE_MVP) as String

func get_feature_count(software: CardInstance) -> int:
	if software == null:
		return 0
	ensure_card_defaults(software)
	return maxi(0, int(software.values.get(FEATURE_COUNT_VALUE, 0)))

func get_mvp_required_features(software: CardInstance) -> int:
	if software == null:
		return DEFAULT_MVP_REQUIRED_FEATURES
	ensure_card_defaults(software)
	return maxi(1, int(software.values.get(MVP_REQUIRED_FEATURES_VALUE, DEFAULT_MVP_REQUIRED_FEATURES)))

func get_status_text(software: CardInstance) -> String:
	if software == null:
		return ""
	ensure_card_defaults(software)
	var feature_count: int = get_feature_count(software)
	var stage: String = get_product_stage(software)
	if stage == PRODUCT_STAGE_LIVE:
		return "Live\n%d Features" % feature_count
	var required_features: int = get_mvp_required_features(software)
	if feature_count >= required_features:
		return "Launchbereit\n%d/%d Features" % [feature_count, required_features]
	return "MVP\n%d/%d Features" % [feature_count, required_features]

func get_tooltip_details(software: CardInstance) -> PackedStringArray:
	var details: PackedStringArray = PackedStringArray()
	if software == null:
		return details
	ensure_card_defaults(software)
	var stage: String = get_product_stage(software)
	var feature_count: int = get_feature_count(software)
	if stage == PRODUCT_STAGE_LIVE:
		details.append("Status: Live")
		details.append("Features: %d" % feature_count)
		return details
	var required_features: int = get_mvp_required_features(software)
	if feature_count >= required_features:
		details.append("Status: Launchbereit")
	else:
		details.append("Status: MVP")
	details.append("Features: %d/%d" % [feature_count, required_features])
	return details

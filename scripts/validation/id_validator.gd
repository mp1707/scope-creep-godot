class_name IdValidator
extends RefCounted

const MIN_SEGMENT_COUNT: int = 3

static func is_valid_domain_id(value: String) -> bool:
	if value.is_empty():
		return false

	var segments: PackedStringArray = value.split(".")
	if segments.size() < MIN_SEGMENT_COUNT:
		return false

	for segment: String in segments:
		if segment.is_empty():
			return false
		if segment != segment.to_snake_case():
			return false
		if not _contains_only_id_characters(segment):
			return false

	return true

static func get_domain_id_error(value: String) -> String:
	if is_valid_domain_id(value):
		return ""
	if value.is_empty():
		return "ID must not be empty."
	if value.split(".").size() < MIN_SEGMENT_COUNT:
		return "ID must use a domain prefix, for example card.employee.developer."
	return "ID segments must be snake_case and contain only lowercase letters, numbers, and underscores."

static func _contains_only_id_characters(value: String) -> bool:
	for index: int in value.length():
		var code: int = value.unicode_at(index)
		var is_number: bool = code >= 48 and code <= 57
		var is_lowercase_letter: bool = code >= 97 and code <= 122
		var is_underscore: bool = code == 95
		if not (is_number or is_lowercase_letter or is_underscore):
			return false
	return true

extends SceneTree

func _init() -> void:
	var validator: ContentValidator = ContentValidator.new()
	var errors: PackedStringArray = validator.validate_content()

	if errors.is_empty():
		print("Content validation passed.")
		quit(0)
		return

	printerr("Content validation failed:")
	for error: String in errors:
		printerr("- %s" % error)
	quit(1)

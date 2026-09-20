extends SceneTree
## Run with --main-pack builds/web/index.pck --script <absolute path to this file>.


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var font: Font = load("res://assets/fonts/NotoSansTC-VF.ttf")
	assert(font != null)
	for character in ["武", "俠", "劇", "情", "選", "擇"]:
		assert(font.has_char(character.unicode_at(0)), "Missing glyph: " + character)
	assert(ProjectSettings.get_setting("gui/theme/custom_font") == "res://assets/fonts/NotoSansTC-VF.ttf")
	var creation: Node = load("res://scenes/character_creation.tscn").instantiate()
	root.add_child(creation)
	await process_frame
	var text_controls: Array[Node] = []
	text_controls.append_array(creation.find_children("*", "Label", true, false))
	text_controls.append_array(creation.find_children("*", "Button", true, false))
	text_controls.append_array(creation.find_children("*", "LineEdit", true, false))
	assert(text_controls.size() >= 5)
	for control: Control in text_controls:
		var ui_font := control.get_theme_font("font")
		assert(ui_font != null and ui_font.has_char("武".unicode_at(0)), "Missing Chinese font on " + control.name)
	creation.queue_free()
	await process_frame
	var courtyard: Node = load("res://scenes/courtyard.tscn").instantiate()
	root.add_child(courtyard)
	await process_frame
	var courtyard_labels := courtyard.find_children("*", "Label", true, false)
	assert(courtyard_labels.size() >= 5)
	for label: Label in courtyard_labels:
		var ui_font := label.get_theme_font("font")
		assert(ui_font != null and ui_font.has_char("武".unicode_at(0)), "Missing Chinese font on " + label.name)
	print("WEB_FONT_TEST: PASS (packaged font, character creation and courtyard UI)")
	quit()

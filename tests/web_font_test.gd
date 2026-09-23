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
	courtyard.queue_free()
	await process_frame
	var dialogue: Node = load("res://scenes/dialogue.tscn").instantiate()
	root.add_child(dialogue)
	await process_frame
	var panel: Control = dialogue.get_node("Panel")
	assert(panel.anchor_right == 1.0 and panel.offset_left == 16.0 and panel.offset_right == -16.0,
		"Dialogue panel stays inset and follows the viewport width")
	assert(is_equal_approx(panel.size.x, root.get_visible_rect().size.x - 32.0),
		"Dialogue panel resolves to the viewport width minus its two margins")
	var body: Label = dialogue.get_node("Panel/Body")
	assert(body.anchor_right == 1.0 and body.offset_right == -24.0,
		"Dialogue body follows the panel width with a stable inner margin")
	assert(is_equal_approx(body.size.x, panel.size.x - body.offset_left - 24.0),
		"Dialogue body uses all available panel width")
	assert(body.custom_maximum_size.x <= 0.0,
		"Dialogue body does not retain a fixed-width cap")
	for label_name in ["Speaker", "Body", "Hint"]:
		var dialogue_label: Label = dialogue.get_node("Panel/" + label_name)
		assert(dialogue_label.get_theme_font("font").resource_path == font.resource_path,
			"Dialogue uses a different font on " + label_name)
	var choice_button: Button = dialogue.get_node("Panel/ChoiceScroll/Choices/Option1")
	assert(choice_button.get_theme_font("font").resource_path == font.resource_path,
		"Dialogue choices use a different font")
	print("WEB_FONT_TEST: PASS (packaged Noto Sans TC in character creation, courtyard and dialogue)")
	quit()

extends Control

var name_input: LineEdit
var preview: TextureRect
var gender := "male"
var gender_buttons: Array[Button] = []
var error_label: Label
var entering := false

func _ready() -> void:
	var background := TextureRect.new()
	background.texture = load("res://assets/environment/courtyard.png")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var shade := ColorRect.new()
	shade.color = Color(0.025, 0.055, 0.05, 0.86)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var card := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.075, 0.12, 0.105, 0.96)
	style.border_color = Color(0.65, 0.59, 0.39)
	style.set_border_width_all(2)
	style.content_margin_left = 36
	style.content_margin_right = 36
	style.content_margin_top = 24
	style.content_margin_bottom = 24
	card.add_theme_stylebox_override("panel", style)
	center.add_child(card)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 40)
	card.add_child(row)
	var preview_center := CenterContainer.new()
	preview_center.custom_minimum_size = Vector2(230, 370)
	row.add_child(preview_center)
	preview = TextureRect.new()
	preview.custom_minimum_size = Vector2(230, 210)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	preview_center.add_child(preview)
	var form := VBoxContainer.new()
	form.custom_minimum_size.x = 340
	form.add_theme_constant_override("separation", 14)
	row.add_child(form)
	var title := Label.new()
	title.text = "初入江湖"
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(0.92, 0.84, 0.61))
	form.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "踏上尋回《獨孤十劍》劍譜之旅。"
	form.add_child(subtitle)
	var name_label := Label.new()
	name_label.text = "主角姓名"
	form.add_child(name_label)
	name_input = LineEdit.new()
	name_input.placeholder_text = "請輸入姓名（最多 12 字）"
	name_input.max_length = 12
	name_input.custom_minimum_size.y = 44
	name_input.text_submitted.connect(_submit_name)
	name_input.text_changed.connect(func(_value: String): error_label.text = "")
	form.add_child(name_input)
	var gender_label := Label.new()
	gender_label.text = "性別"
	form.add_child(gender_label)
	var options := HBoxContainer.new()
	options.add_theme_constant_override("separation", 12)
	form.add_child(options)
	var group := ButtonGroup.new()
	for value in ["male", "female"]:
		var button := Button.new()
		button.text = "男" if value == "male" else "女"
		button.toggle_mode = true
		button.button_group = group
		button.custom_minimum_size = Vector2(164, 44)
		button.pressed.connect(select_gender.bind(value))
		options.add_child(button)
		gender_buttons.append(button)
	error_label = Label.new()
	error_label.custom_minimum_size.y = 24
	error_label.add_theme_color_override("font_color", Color(1.0, 0.65, 0.55))
	form.add_child(error_label)
	var start := Button.new()
	start.text = "踏入江湖"
	start.custom_minimum_size.y = 48
	start.pressed.connect(start_game)
	form.add_child(start)
	select_gender("male")
	name_input.grab_focus()

func select_gender(value: String) -> void:
	gender = value
	gender_buttons[0].button_pressed = value == "male"
	gender_buttons[1].button_pressed = value == "female"
	preview.texture = preload("res://scripts/character_art.gd").standing_portrait(value)

func _submit_name(_value: String) -> void:
	start_game()

func start_game() -> void:
	if entering:
		return
	if name_input.text.strip_edges().is_empty():
		error_label.text = "請先為主角取個名字。"
		name_input.grab_focus()
		return
	entering = true
	WorldState.create_hero(name_input.text, gender)
	var result := get_tree().change_scene_to_file("res://scenes/courtyard.tscn")
	if result != OK:
		entering = false
		error_label.text = "暫時無法進入庭院，請再試一次。"

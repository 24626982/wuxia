extends CanvasLayer

signal started
signal finished(dialogue_id: StringName, effects: Dictionary)
signal cancelled
signal closed(completed: bool, effects: Dictionary)
const Rules = preload("res://scripts/story_rules.gd")
const Art = preload("res://scripts/character_art.gd")
var portrait: TextureRect
var library: Dictionary = {}
var allow_cancel := true

var active: bool = false
var dialogue_id: StringName
var lines: Array = []
var line_index: int = 0
var waiting_for_choice: bool = false
var selected_choice: int = 0
var pending_effects: Dictionary = {}
var context: Dictionary = {}
var current_choices: Array = []

@onready var panel: Control = $Panel
@onready var speaker: Label = $Panel/Speaker
@onready var body: Label = $Panel/Body
@onready var hint: Label = $Panel/Hint
@onready var choices_box: VBoxContainer = $Panel/ChoiceScroll/Choices
@onready var choice_buttons: Array[Button] = [$Panel/ChoiceScroll/Choices/Option1, $Panel/ChoiceScroll/Choices/Option2]


func _ready() -> void:
	portrait = TextureRect.new()
	portrait.position = Vector2(14, 8)
	portrait.size = Vector2(140, 150)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(portrait)
	for index in range(choice_buttons.size()):
		choice_buttons[index].pressed.connect(choose.bind(index))
		choice_buttons[index].focus_entered.connect(_choice_focused.bind(index))


func begin(id: StringName, dialogue_lines: Array, story_context: Dictionary = {}) -> void:
	if active or dialogue_lines.is_empty():
		return
	dialogue_id = id
	lines = dialogue_lines.duplicate(true)
	context = story_context.duplicate(true)
	pending_effects.clear()
	line_index = 0
	active = true
	panel.show()
	started.emit()
	_show_line()


func advance() -> void:
	if not active or waiting_for_choice:
		return
	_apply_action(lines[line_index].get("action", {}))
	line_index += 1
	if line_index >= lines.size():
		active = false
		panel.hide()
		finished.emit(dialogue_id, pending_effects.duplicate(true))
		closed.emit(true, pending_effects.duplicate(true))
	else:
		_show_line()


func cancel() -> void:
	if not active or not allow_cancel:
		return
	active = false
	waiting_for_choice = false
	pending_effects.clear()
	choices_box.hide()
	panel.hide()
	cancelled.emit()
	closed.emit(false, {})


func choose(index: int) -> void:
	if not active or not waiting_for_choice or index < 0 or index >= current_choices.size():
		return
	var option: Dictionary = current_choices[index]
	var effects: Dictionary = option.get("effects", {})
	pending_effects.merge(effects, true)
	context.merge(effects, true)
	var reply: Array = option.get("reply", [])
	reply = reply.duplicate(true)
	if option.has("action"):
		reply.append({"action": option.action})
	lines = lines.slice(0, line_index + 1) + reply.duplicate(true) + lines.slice(line_index + 1)
	waiting_for_choice = false
	choices_box.hide()
	for button in choice_buttons:
		button.release_focus()
	advance()


func _input(event: InputEvent) -> void:
	if not active or event.is_echo():
		return
	if event.is_action_pressed("cancel_dialogue"):
		cancel()
		get_viewport().set_input_as_handled()
		return
	if waiting_for_choice:
		if event.is_action_pressed("choice_1"):
			choose(0)
		elif event.is_action_pressed("choice_2"):
			choose(1)
		elif event.is_action_pressed("choice_up"):
			_focus_choice(posmod(selected_choice - 1, current_choices.size()))
		elif event.is_action_pressed("choice_down"):
			_focus_choice(posmod(selected_choice + 1, current_choices.size()))
		elif event.is_action_pressed("interact") or event.is_action_pressed("confirm_choice"):
			choose(selected_choice)
		else:
			return
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact") or event.is_action_pressed("confirm_choice"):
		advance()
		get_viewport().set_input_as_handled()


func _show_line() -> void:
	var line: Dictionary = lines[line_index]
	if not Rules.matches(context, line.get("when", {})):
		line_index += 1
		if line_index >= lines.size():
			active = false
			panel.hide()
			finished.emit(dialogue_id, pending_effects.duplicate(true))
			closed.emit(true, pending_effects.duplicate(true))
			return
		_show_line()
		return
	if not line.has("text"):
		advance()
		return
	speaker.text = str(line.get("speaker", "旁白")).replace(" · ", "・")
	portrait.texture = Art.portrait(speaker.text)
	portrait.visible = portrait.texture != null
	speaker.offset_left = 166 if portrait.visible else 24
	body.offset_left = speaker.offset_left
	body.text = _resolve_text(line)
	current_choices = []
	for option in line.get("choices", []):
		if Rules.matches(context, option.get("requires", {})):
			current_choices.append(option)
	while choice_buttons.size() < current_choices.size():
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 44)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		choices_box.add_child(button)
		var index := choice_buttons.size()
		button.pressed.connect(choose.bind(index))
		button.focus_entered.connect(_choice_focused.bind(index))
		choice_buttons.append(button)
	waiting_for_choice = not current_choices.is_empty()
	choices_box.visible = waiting_for_choice
	panel.offset_top = 30.0 if waiting_for_choice else 362.0
	body.offset_bottom = 142.0
	portrait.size.y = 150
	$Panel/ChoiceScroll.offset_top = 158
	$Panel/ChoiceScroll.offset_bottom = 448
	$Panel/ChoiceScroll.visible = waiting_for_choice
	hint.offset_top = 462.0 if waiting_for_choice else 169.0
	hint.offset_bottom = hint.offset_top + 24.0
	for index in range(choice_buttons.size()):
		choice_buttons[index].visible = index < current_choices.size()
		choice_buttons[index].release_focus()
	if waiting_for_choice:
		hint.text = "1 / 2 直接選擇   ·   ↑↓ 選擇，E / 空白鍵 / Enter 確認   ·   Esc 取消"
		_focus_choice(0)
	else:
		hint.text = "E / 空白鍵 / Enter 繼續   ·   Esc 關閉（不保留本次選擇）"
		panel.offset_top = 322.0


func _resolve_text(line: Dictionary) -> String:
	for variant in line.get("variants", []):
		if Rules.matches(context, variant.get("when", {})):
			return str(variant["text"])
	return str(line["text"])


func _focus_choice(index: int) -> void:
	_choice_focused(index)
	choice_buttons[index].grab_focus()
	$Panel/ChoiceScroll.ensure_control_visible(choice_buttons[index])

func _apply_action(action: Dictionary) -> void:
	match action.get("type", ""):
		"set":
			pending_effects.merge(action.effects, true)
			context.merge(action.effects, true)
		"enable_interactables":
			for id in action.ids:
				pending_effects["enabled_" + id] = true
				context["enabled_" + id] = true
		"open_dialogue":
			lines = lines.slice(0, line_index + 1) + library.get(action.id, []).duplicate(true) + lines.slice(line_index + 1)


func _choice_focused(index: int) -> void:
	selected_choice = index
	for button_index in range(current_choices.size()):
		choice_buttons[button_index].text = "%s %d. %s" % ["▶" if button_index == index else "  ", button_index + 1, current_choices[button_index]["label"]]

extends CanvasLayer

signal started
signal finished(dialogue_id: StringName, effects: Dictionary)
signal cancelled

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
@onready var choices_box: VBoxContainer = $Panel/Choices
@onready var choice_buttons: Array[Button] = [$Panel/Choices/Option1, $Panel/Choices/Option2]


func _ready() -> void:
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
	_show_line()
	started.emit()


func advance() -> void:
	if not active or waiting_for_choice:
		return
	line_index += 1
	if line_index >= lines.size():
		active = false
		panel.hide()
		finished.emit(dialogue_id, pending_effects.duplicate(true))
	else:
		_show_line()


func cancel() -> void:
	if not active:
		return
	active = false
	waiting_for_choice = false
	pending_effects.clear()
	choices_box.hide()
	panel.hide()
	cancelled.emit()


func choose(index: int) -> void:
	if not active or not waiting_for_choice or index < 0 or index >= current_choices.size():
		return
	var option: Dictionary = current_choices[index]
	var effects: Dictionary = option.get("effects", {})
	pending_effects.merge(effects, true)
	context.merge(effects, true)
	var reply: Array = option.get("reply", [])
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
	speaker.text = str(line["speaker"])
	body.text = _resolve_text(line)
	current_choices = line.get("choices", [])
	waiting_for_choice = not current_choices.is_empty()
	choices_box.visible = waiting_for_choice
	panel.offset_top = 252.0 if waiting_for_choice else 362.0
	body.offset_bottom = 112.0 if waiting_for_choice else 117.0
	hint.offset_top = 242.0 if waiting_for_choice else 129.0
	hint.offset_bottom = hint.offset_top + 24.0
	for index in range(choice_buttons.size()):
		choice_buttons[index].visible = index < current_choices.size()
		choice_buttons[index].release_focus()
	if waiting_for_choice:
		assert(current_choices.size() <= choice_buttons.size(), "Dialogue supports up to two choices per question.")
		hint.text = "1 / 2 直接選擇   ·   ↑↓ 選擇，E / 空白鍵 / Enter 確認   ·   Esc 取消"
		_focus_choice(0)
	else:
		hint.text = "E / 空白鍵 / Enter 繼續   ·   Esc 關閉（不保留本次選擇）"


func _resolve_text(line: Dictionary) -> String:
	for variant in line.get("variants", []):
		var matches: bool = true
		for key in variant["when"]:
			if context.get(key) != variant["when"][key]:
				matches = false
				break
		if matches:
			return str(variant["text"])
	return str(line["text"])


func _focus_choice(index: int) -> void:
	_choice_focused(index)
	choice_buttons[index].grab_focus()


func _choice_focused(index: int) -> void:
	selected_choice = index
	for button_index in range(current_choices.size()):
		choice_buttons[button_index].text = "%s %d. %s" % ["▶" if button_index == index else "  ", button_index + 1, current_choices[button_index]["label"]]

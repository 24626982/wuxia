extends Node2D

const VIEW_SIZE := Vector2(960, 540)
const INTERACT_RADIUS: float = 56.0
const ResidenceStory = preload("res://scripts/residence_story.gd")
@export_enum("courtyard", "residence", "hall", "town", "dormitory") var map_id: String = "courtyard"

var story_stage: int = 0
var story: Dictionary = {}
var story_flags: Dictionary = {}
var nearest_npc: Node2D
var exit_dialogue_shown: bool = false

@onready var player = $Actors/Player
@onready var dialogue = $Dialogue
@onready var objective: Label = $HUD/Objective
@onready var interaction_hint: Label = $HUD/InteractionHint
@onready var journal: Label = $HUD/Journal


func _enter_tree() -> void:
	# Physical keys keep WASD movement consistent across keyboard layouts.
	_bind_action("move_left", [KEY_A, KEY_LEFT])
	_bind_action("move_right", [KEY_D, KEY_RIGHT])
	_bind_action("move_up", [KEY_W, KEY_UP])
	_bind_action("move_down", [KEY_S, KEY_DOWN])
	_bind_action("reset_player", [KEY_R])
	_bind_action("interact", [KEY_E, KEY_SPACE])
	_bind_action("cancel_dialogue", [KEY_ESCAPE])
	_bind_action("choice_1", [KEY_1, KEY_KP_1])
	_bind_action("choice_2", [KEY_2, KEY_KP_2])
	_bind_action("choice_up", [KEY_UP, KEY_W])
	_bind_action("choice_down", [KEY_DOWN, KEY_S])
	_bind_action("confirm_choice", [KEY_ENTER, KEY_KP_ENTER])


func _ready() -> void:
	var background: Sprite2D = $Background
	background.scale = VIEW_SIZE / background.texture.get_size()
	story = JSON.parse_string(FileAccess.get_file_as_string("res://data/prologue.json"))
	var residence_story: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/residence.json"))
	story["dialogues"].merge(residence_story["dialogues"], true)
	var exploration: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/exploration.json"))
	story["dialogues"].merge(exploration["dialogues"], true)
	if WorldState.pending_arrival:
		story_stage = WorldState.story_stage
		story_flags = WorldState.story_flags.duplicate(true)
		player.position = WorldState.arrival
		player.spawn_position = player.position
		WorldState.pending_arrival = false
	dialogue.started.connect(_dialogue_started)
	dialogue.finished.connect(_dialogue_finished)
	dialogue.cancelled.connect(_dialogue_cancelled)
	_update_objective()
	# Re-sample the unchanged background onto native foreground polygons.
	# The roof has no ground collision: only the walls and two pillars are solid.
	for foreground in $GateForeground.get_children():
		var uv := PackedVector2Array()
		for point in foreground.polygon:
			uv.append(point * background.texture.get_size() / VIEW_SIZE)
		foreground.uv = uv


func _physics_process(_delta: float) -> void:
	nearest_npc = _find_nearest_npc()
	interaction_hint.visible = not dialogue.active
	if nearest_npc != null:
		interaction_hint.text = "E / 空白鍵：與 %s 對話" % nearest_npc.get("display_name")
	elif map_id == "courtyard" and player.position.y > 485.0 and story_stage < 3:
		interaction_hint.text = "下山前，先與掌門、阿棠和秦川打聽線索"
	else:
		interaction_hint.text = "靠近有名字的 NPC，按 E / 空白鍵對話"
	if player.position.y < 490.0:
		exit_dialogue_shown = false
	if map_id == "courtyard" and story_stage == 3 and player.position.y >= 502.0 and not dialogue.active and not exit_dialogue_shown:
		exit_dialogue_shown = true
		_open_dialogue("departure")


func _unhandled_input(event: InputEvent) -> void:
	if dialogue.active or event.is_echo():
		return
	if event.is_action_pressed("interact"):
		interact_with_nearest()
		get_viewport().set_input_as_handled()


func _find_nearest_npc() -> Node2D:
	var closest: Node2D = null
	var distance: float = INTERACT_RADIUS
	for actor in $Actors.get_children():
		if not actor.is_in_group("story_npcs") and not actor.is_in_group("clue_spots"):
			continue
		if not actor.is_visible_in_tree():
			continue
		var candidate_distance: float = player.global_position.distance_to(actor.global_position)
		if candidate_distance < distance:
			distance = candidate_distance
			closest = actor
	return closest


func interact_with_nearest() -> void:
	if dialogue.active:
		return
	nearest_npc = _find_nearest_npc()
	if nearest_npc == null:
		return
	var id: StringName = nearest_npc.get("npc_id")
	nearest_npc.face_towards(player.global_position)
	player._set_facing(nearest_npc.global_position - player.global_position)
	if nearest_npc.is_in_group("clue_spots"):
		_open_dialogue(id)
		return
	if map_id == "residence":
		var residence_id: StringName = ResidenceStory.dialogue_for(id, story_flags)
		if not residence_id.is_empty():
			_open_dialogue(residence_id)
		return
	match id:
		"master":
			_open_dialogue("master_start" if story_stage == 0 else "master_repeat")
		"disciple":
			if story_stage == 0:
				_open_dialogue("disciple_early")
			else:
				_open_dialogue("disciple_clue" if story_stage == 1 else "disciple_repeat")
		"guard":
			if story_stage < 2:
				_open_dialogue("guard_early")
			else:
				_open_dialogue("guard_route" if story_stage == 2 else "guard_repeat")


func _open_dialogue(id: StringName) -> void:
	dialogue.begin(id, story["dialogues"][id], story_flags)


func _dialogue_started() -> void:
	player.movement_enabled = false


func _dialogue_finished(id: StringName, effects: Dictionary) -> void:
	player.movement_enabled = true
	if id.begins_with("explore_"):
		story_flags.merge(effects, true)
		_update_objective()
	if id.begins_with("residence_"):
		ResidenceStory.commit(id, effects, story_flags)
		_update_objective()
	var progression := ["master_start", "disciple_clue", "guard_route", "departure"]
	if story_stage < progression.size() and id == progression[story_stage]:
		story_flags.merge(effects, true)
		story_stage += 1
		_update_objective()


func _dialogue_cancelled() -> void:
	player.movement_enabled = true


func _update_objective() -> void:
	if map_id in ["hall", "town", "dormitory"]:
		var titles := {"hall": "議事廳｜查看桌案，南門返回庭院", "town": "山腳城鎮｜自由查訪，北路返回山門", "dormitory": "弟子宿舍｜查看床位，南門返回西院"}
		objective.text = titles[map_id]
		var count := 0
		for key in story_flags:
			if String(key).begins_with("explore_" + map_id + "_"):
				count += 1
		journal.text = "此處已查看 %d / 2 處｜所見未必就是答案" % count
		return
	objective.text = story["objectives"][story_stage]
	if story_stage == 4:
		objective.text = "序章結果｜" + ending_name() + " · 可由左橋前往西院"
	var approach := "先救人" if story_flags.get("approach") == "compassion" else "先追查"
	var clue := "路引竹印" if story_flags.get("clue") == "seal" else "三聲短笛"
	journal.text = "江湖札記：尚未取得線索"
	if story_flags.has("approach"):
		journal.text = "行事：" + approach
	if story_flags.has("clue"):
		journal.text += "  ｜  線索：" + clue
	if story_flags.has("trust_guard"):
		journal.text += "  ｜  " + ("信任秦川" if story_flags["trust_guard"] else "提防秦川")


	if map_id == "residence":
		var count: int = ResidenceStory.testimony_count(story_flags)
		objective.text = "西院疑影｜查訪四人，追查空床主人小滿"
		journal.text = "江湖札記：已核對 %d / 4 人證詞" % count
		if count == 4:
			objective.text = "西院疑影｜回找周伯，核對半張收訖單"
			journal.text = "疑點：鞋印、藥包與折回的燈影"
		if story_flags.get("residence_resolved", false):
			objective.text = "西院調查完成｜下一站：東竹亭驛站（待開放）"
			journal.text = "紙樣：缺角竹印・第三盞燈｜" + ("先確認平安" if story_flags.get("residence_next_lead") == "safety" else "先核對竹印")


func ending_name() -> String:
	if story_flags.get("approach") == "compassion" and story_flags.get("trust_guard", false):
		return "守約尋人"
	if story_flags.get("clue") == "seal":
		return "循證追查"
	return "孤身追影"


func _bind_action(action: StringName, keys: Array) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	for key in keys:
		var event := InputEventKey.new()
		event.physical_keycode = key
		InputMap.action_add_event(action, event)

extends Node2D

const VIEW_SIZE := Vector2(960, 540)
const INTERACT_RADIUS: float = 56.0
const ResidenceStory = preload("res://scripts/residence_story.gd")
const Rules = preload("res://scripts/story_rules.gd")
const Guide = preload("res://scripts/story_guide.gd")
const CharacterArt = preload("res://scripts/character_art.gd")
var guide_task: Dictionary = {}
var interaction_overlay: Node2D
var notebook: CanvasLayer
const ClueJournal = preload("res://scripts/clue_journal.gd")
var director: Node
var spot_requirements: Dictionary = {}
@export_enum("courtyard", "residence", "hall", "town", "dormitory", "bamboo_station", "wind_cliff") var map_id: String = "courtyard"

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
	for chapter in ["dormitory", "town", "bamboo_station", "wind_cliff", "hall_revisit", "finale"]:
		var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/" + chapter + ".json"))
		story.dialogues.merge(data.dialogues, true)
	dialogue.library = story.dialogues
	if WorldState.pending_arrival:
		story_stage = WorldState.story_stage
		story_flags = WorldState.story_flags.duplicate(true)
		player.position = WorldState.arrival
		player.spawn_position = player.position
		WorldState.pending_arrival = false
	dialogue.started.connect(_dialogue_started)
	dialogue.finished.connect(_dialogue_finished)
	dialogue.cancelled.connect(_dialogue_cancelled)
	director = preload("res://scripts/story_director.gd").new()
	add_child(director)
	director.setup(self)
	notebook = preload("res://scripts/clue_notebook.gd").new()
	notebook.world = self
	add_child(notebook)
	_setup_hud()
	_create_story_spots()
	preload("res://scripts/map_presentation.gd").configure(self)
	interaction_overlay = preload("res://scripts/interaction_overlay.gd").new()
	interaction_overlay.world = self
	add_child(interaction_overlay)
	refresh_story_spots()
	_update_objective()
	director.enter_map.call_deferred()
	# Re-sample the unchanged background onto native foreground polygons.
	# The roof has no ground collision: only the walls and two pillars are solid.
	for foreground in $GateForeground.get_children():
		var uv := PackedVector2Array()
		for point in foreground.polygon:
			uv.append(point * background.texture.get_size() / VIEW_SIZE)
		foreground.uv = uv


func _physics_process(_delta: float) -> void:
	if notebook.opened: return
	nearest_npc = _find_nearest_npc()
	interaction_hint.visible = not dialogue.active
	if nearest_npc != null:
		var id := String(nearest_npc.npc_id)
		var verb := "交談"
		if id.begins_with("explore_"): verb = "調查"
		if id in ["third_lamp_at_night", "enter_at_night"]: verb = "等候入夜"
		if id == "interact_tubes": verb = "搜查"
		interaction_hint.text = "[ E / 空白鍵 ]  " + verb + " · " + nearest_npc.display_name
		if nearest_npc.get_meta("locked", false): interaction_hint.text = "[ E / 空白鍵 ]  先詢問石安，獲准後才能調查"
	elif map_id == "courtyard" and player.position.y > 485.0 and story_stage < 3:
		interaction_hint.text = "下山前，先與掌門、阿棠和秦川打聽線索"
	else:
		interaction_hint.text = "金色標記：下一步  ·  對話圈：人物  ·  放大鏡：調查  ·  走入出口即可換圖"
	if player.position.y < 490.0:
		exit_dialogue_shown = false
	if map_id == "courtyard" and story_stage == 3 and player.position.y >= 502.0 and not dialogue.active and not exit_dialogue_shown:
		exit_dialogue_shown = true
		_open_dialogue("departure")


func _unhandled_input(event: InputEvent) -> void:
	if dialogue.active or notebook.opened or event.is_echo():
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
	if dialogue.active or director.busy or notebook.opened:
		return
	nearest_npc = _find_nearest_npc()
	if nearest_npc == null:
		return
	var id: StringName = nearest_npc.get("npc_id")
	ActivityLog.record_interaction(nearest_npc.display_name)
	nearest_npc.face_towards(player.global_position)
	player._set_facing(nearest_npc.global_position - player.global_position)
	if story_stage < 4 and ((map_id == "residence" and String(id) in ResidenceStory.WITNESSES) or String(id) in ["chen_bai", "shi_an", "brother", "third_lamp_at_night", "enter_at_night", "interact_tubes", "yan_cheng", "xiaoman"]):
		_prologue_hint()
		return
	if nearest_npc.get_meta("locked", false):
		if not director.interact("shi_an"):
			dialogue.begin("locked_bed", [{"speaker": "石安・西院弟子", "text": "小滿的東西先別動。周伯知道他的事，先去西院問清楚再來。"}], story_flags)
		return
	if director.interact(String(id)):
		return
	if id == &"xiaoman":
		dialogue.begin("xiaoman_idle", [{"speaker": "小滿・西院弟子", "text": "謝謝你來找我。我哥哥還在鎮上，別讓他一直等。"}], story_flags)
		return
	if id == &"npc_town_tea_b":
		_open_dialogue("npc_town_tea")
		return
	if id == &"yan_cheng":
		director.enter_map()
		if not dialogue.active: dialogue.begin("yan_idle", [{"speaker": "旁白", "text": _next_objective()}], story_flags)
		return
	if String(id) in ["chen_bai", "shi_an", "brother", "third_lamp_at_night", "enter_at_night", "interact_tubes"]:
		dialogue.begin("hint", [{"speaker": "旁白", "text": _next_objective()}], story_flags)
		return
	var echo_targets := {"guard": "qin_chuan_idle", "disciple": "courtyard_water_disciple", "uncle_zhou": "uncle_zhou_idle"}
	if echo_targets.has(String(id)):
		var echo: Array = director.echo_lines(echo_targets[String(id)])
		var idle: bool = (id == &"uncle_zhou" and story_flags.get("residence_resolved", false)) or (id != &"uncle_zhou" and story_stage >= 4)
		if idle and not echo.is_empty():
			dialogue.begin("echo", echo, story_flags)
			return
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
	if story_stage < 4 and id.begins_with("residence_"):
		_prologue_hint()
		return
	var lines: Array = story["dialogues"][id]
	if id == "guard_route":
		lines = lines + story["dialogues"]["departure"]
	dialogue.begin(id, lines, story_flags)


func _prologue_hint() -> void:
	dialogue.begin("prologue_hint", [{"speaker": "旁白", "text": "先回庭院完成掌門交代的查訪，整理線索後再來。\n" + _next_objective()}], story_flags)


func _dialogue_started() -> void:
	player.movement_enabled = false


func _dialogue_finished(id: StringName, effects: Dictionary) -> void:
	player.movement_enabled = true
	if effects.has("_selection"):
		director.selection = int(effects["_selection"])
		effects.erase("_selection")
	story_flags.merge(effects, true)
	if not director.busy:
		ClueJournal.remember_dialogue(story_flags, String(id), dialogue.lines)
	if director != null:
		player.movement_enabled = not director.busy
		refresh_story_spots()
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
		if id == "guard_route": story_stage = 4
		_update_objective()
	_update_objective()


func _dialogue_cancelled() -> void:
	player.movement_enabled = true


func _update_objective() -> void:
	if director != null and not director.busy:
		ClueJournal.collect(story_flags, story_stage, story.dialogues)
	guide_task = Guide.next(story_stage, story_flags)
	objective.text = "下一步｜" + guide_task.title
	journal.text = Guide.instructions(map_id, guide_task)



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

func _next_objective() -> String:
	var task := Guide.next(story_stage, story_flags)
	return task.title + "。" + Guide.instructions(map_id, task)

func _setup_hud() -> void:
	$HUD/Backdrop.position = Vector2(16, 16)
	$HUD/Backdrop.size = Vector2(310, 62)
	$HUD/Title.position = Vector2(28, 22)
	$HUD/Title.add_theme_font_size_override("font_size", 18)
	$HUD/Controls.position = Vector2(28, 51)
	$HUD/Controls.text = "WASD 移動　靠近按 E 互動　R 回入口"
	$HUD/Controls.add_theme_font_size_override("font_size", 12)
	$HUD/ObjectiveBackdrop.position = Vector2(510, 16)
	$HUD/ObjectiveBackdrop.size = Vector2(434, 43)
	$HUD/JournalBackdrop.position = Vector2(510, 59)
	$HUD/JournalBackdrop.size = Vector2(434, 74)
	objective.position = Vector2(524, 25)
	objective.size = Vector2(406, 28)
	objective.add_theme_font_size_override("font_size", 16)
	journal.position = Vector2(524, 63)
	journal.size = Vector2(402, 64)
	journal.add_theme_font_size_override("font_size", 13)
	interaction_hint.position = Vector2(30, 506)
	interaction_hint.size = Vector2(810, 28)
	interaction_hint.add_theme_font_size_override("font_size", 12)


func refresh_story_spots() -> void:
	for actor in $Actors.get_children():
		if not actor.is_in_group("clue_spots"): continue
		var id := String(actor.npc_id)
		actor.visible = Rules.matches(story_flags, spot_requirements.get(id, {}))
		if id in ["explore_dormitory_bed", "explore_dormitory_pouch"]:
			var unlocked: bool = story_flags.has("n1_result") or story_flags.get("enabled_" + id, false)
			actor.set_meta("locked", not unlocked)
			actor.visible = true
			for child in actor.get_children():
				if child is Label: child.text = actor.display_name + ("" if unlocked else " · 先問石安")
		if id == "xiaoman": actor.visible = story_flags.has("n3_result")
		if id == "yan_cheng": actor.visible = story_flags.get("suspect_known", false)

func _create_story_spots() -> void:
	var names := {"explore_hall_ledger": "用度帳冊", "npc_elder_yan": "嚴長老", "npc_town_vendor": "攤販", "npc_town_tea": "茶客", "explore_station_backdoor": "驛站後門", "npc_station_keeper": "驛站掌櫃", "npc_station_keeper_closed": "驛站掌櫃", "npc_herb_elder": "採藥老人", "explore_cliff_rock": "崖邊石塊", "chen_bai": "陳白", "shi_an": "石安", "brother": "小滿的哥哥", "third_lamp_at_night": "第三盞燈・等候入夜", "enter_at_night": "崖邊・等候入夜", "interact_tubes": "搜尋竹管"}
	var entries: Array = director.logic.map_interactables.get(map_id, []).duplicate(true)
	names.merge({"xiaoman": "小滿", "yan_cheng": "嚴承", "npc_town_vendor": "貨攤老闆娘", "npc_town_tea": "茶客甲", "npc_town_tea_b": "茶客乙", "npc_station_keeper": "老夥計", "npc_station_keeper_closed": "老夥計"}, true)
	var extra := {"dormitory": ["chen_bai", "shi_an"], "town": ["brother", "npc_town_tea_b"], "bamboo_station": ["third_lamp_at_night", "xiaoman"], "wind_cliff": ["enter_at_night", "interact_tubes", "yan_cheng"]}
	entries.append_array(extra.get(map_id, []))
	var existing := []
	for actor in $Actors.get_children():
		if actor.is_in_group("clue_spots"): existing.append(String(actor.npc_id))
	var index := 0
	for item in entries:
		var id: String = item if item is String else item.id
		if item is Dictionary: spot_requirements[id] = item.get("requires", {})
		if id in existing: continue
		var marker := Marker2D.new()
		marker.set_script(preload("res://scripts/clue_spot.gd"))
		marker.npc_id = StringName(id)
		marker.display_name = names.get(id, id)
		marker.position = Vector2(180 + (index % 5) * 145, 410)
		if map_id == "hall": marker.position = Vector2(350 + index * 200, 380)
		if map_id == "dormitory": marker.position = Vector2(360 + index * 240, 350)
		if id == "npc_station_keeper_closed": marker.position = Vector2(325, 410)
		marker.add_to_group("clue_spots")
		$Actors.add_child(marker)
		marker.setup_character(id)
		var label := Label.new()
		label.text = "◆ " + marker.display_name
		label.position = Vector2(-68, -32)
		if id.begins_with("npc_") or id in ["chen_bai", "shi_an", "brother"]: label.position.y = -64
		label.add_theme_font_override("font", objective.get_theme_font("font"))
		label.add_theme_color_override("font_outline_color", Color(0.03, 0.05, 0.04))
		label.add_theme_constant_override("outline_size", 4)
		label.add_theme_font_size_override("font_size", 14)
		marker.add_child(label)
		index += 1

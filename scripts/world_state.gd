extends Node
var hero_name := "少俠"
var hero_gender := "male"

func create_hero(new_name: String, gender: String) -> void:
	hero_gender = "female" if gender == "female" else "male"
	hero_name = new_name.strip_edges().left(12)
	if hero_name.is_empty():
		hero_name = "女俠" if hero_gender == "female" else "少俠"
	story_stage = 0
	story_flags.clear()
	arrival = Vector2.ZERO
	pending_arrival = false
	switching = false
	ActivityLog.start_session()

func hero_portrait() -> Texture2D:
	if hero_gender == "female":
		return load("res://assets/characters/hero-female-portrait.png")
	return preload("res://scripts/character_art.gd").texture("hero")

var story_stage := 0
var story_flags: Dictionary = {}
var arrival := Vector2.ZERO
var pending_arrival := false
var switching := false

func travel(world: Node, scene_path: String, spawn: Vector2) -> void:
	if switching or world.dialogue.active or (world.notebook != null and world.notebook.opened) or (world.director != null and world.director.busy):
		return
	switching = true
	story_stage = world.story_stage
	story_flags = world.story_flags.duplicate(true)
	arrival = spawn
	pending_arrival = true
	_change.call_deferred(scene_path)

func _change(path: String) -> void:
	if get_tree().change_scene_to_file(path) != OK:
		pending_arrival = false
		push_error("Cannot load local map: " + path)
	switching = false

extends Node
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

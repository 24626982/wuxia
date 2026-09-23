extends SceneTree

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var state = root.get_node("WorldState")
	var creation = load("res://scenes/character_creation.tscn").instantiate()
	root.add_child(creation)
	await process_frame
	creation.name_input.text = "   "
	creation.start_game()
	_check(not creation.entering and not creation.error_label.text.is_empty(), "Blank name stays on creation screen")
	creation.select_gender("female")
	_check(creation.preview.texture.atlas.resource_path.ends_with("hero-female-portrait.png"), "Female preview uses standing portrait")
	state.create_hero("  林青霜  ", "female")
	_check(state.hero_name == "林青霜" and state.hero_gender == "female", "Name trimmed and gender retained")
	var world = load("res://scenes/courtyard.tscn").instantiate()
	root.add_child(world)
	await process_frame
	var player = world.get_node("Actors/Player")
	_check(player.sprite.texture.resource_path.ends_with("hero-female-directions.png"), "Female map sprite loaded")
	for index in range(4):
		player._set_facing([Vector2.DOWN, Vector2.UP, Vector2.LEFT, Vector2.RIGHT][index])
		_check(player.facing == index, "Female direction " + str(index))
		var bounds: Rect2 = player.female_bounds[index]
		var cell_size: Vector2 = player.sprite.region_rect.size
		_check(absf(bounds.end.y - cell_size.y / 2.0 + player.sprite.offset.y) < 0.1, "Feet aligned in direction " + str(index))
	world.dialogue.begin("hero_test", [{"speaker": "少俠", "text": "我是林青霜。"}])
	_check(world.dialogue.speaker.text == "林青霜", "Dialogue uses chosen name")
	_check(world.dialogue.portrait.texture.resource_path.ends_with("hero-female-portrait.png"), "Dialogue uses female portrait")
	world.dialogue.cancel()
	world.dialogue.begin("ending_exiled", [{"speaker": "旁白", "text": "他們沒說什麼，{hero_pronoun}也沒有。"}])
	_check(world.dialogue.body.text == "他們沒說什麼，她也沒有。", "Female ending pronouns preserve other people")
	world.dialogue.cancel()
	world.queue_free()
	await process_frame
	var next_map = load("res://scenes/town.tscn").instantiate()
	root.add_child(next_map)
	await process_frame
	_check(next_map.player.sprite.texture.resource_path.ends_with("hero-female-directions.png") and state.hero_name == "林青霜", "Identity retained on another map")
	next_map.queue_free()
	creation.queue_free()
	await process_frame
	state.story_stage = 4
	state.story_flags["old_progress"] = true
	state.pending_arrival = true
	state.create_hero("江行", "male")
	_check(state.story_stage == 0 and state.story_flags.is_empty() and not state.pending_arrival, "New hero clears old story and arrival")
	var male = load("res://scenes/player.tscn").instantiate()
	root.add_child(male)
	await process_frame
	_check(male.sprite.texture.resource_path.ends_with("swordsman.png"), "Male sprite preserved")
	male.queue_free()
	await process_frame
	var opening = load("res://scenes/character_creation.tscn").instantiate()
	root.add_child(opening)
	current_scene = opening
	opening.name_input.text = "林青霜"
	opening.select_gender("female")
	opening.start_game()
	await process_frame
	await process_frame
	_check(current_scene.scene_file_path == "res://scenes/courtyard.tscn" and state.hero_name == "林青霜", "Start button enters courtyard with chosen identity")
	current_scene.queue_free()
	await process_frame
	print("CHARACTER_CREATION_TEST: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)

func _check(condition: bool, description: String) -> void:
	print("PASS: " if condition else "FAIL: ", description)
	if not condition:
		failures += 1

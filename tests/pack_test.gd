extends SceneTree
## Run using --main-pack builds/windows/Wuxia.exe --script <absolute script path>.


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var world = load("res://scenes/courtyard.tscn").instantiate()
	root.add_child(world)
	await process_frame
	assert(world.get_node("Actors").get_child_count() == 4)
	assert(world.story.size() > 0)
	var textures: Dictionary = {}
	for actor in world.get_node("Actors").get_children():
		var texture: Texture2D = actor.get_node("Sprite2D").texture
		assert(texture != null)
		if actor.is_in_group("story_npcs"):
			assert(actor.artwork_bounds.has_area())
			texture = actor.directional_texture
			assert(texture != null)
		textures[texture.resource_path] = true
	assert(textures.size() == 4)
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture="):
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(argument.trim_prefix("--capture="))
	var player = world.get_node("Actors/Player")
	player.position = Vector2(480, 242)
	world.interact_with_nearest()
	var dialogue = world.get_node("Dialogue")
	assert(dialogue.active)
	while dialogue.active:
		if dialogue.waiting_for_choice:
			dialogue.choose(0)
		else:
			dialogue.advance()
	assert(world.story_stage == 1)
	assert(world.story_flags.get("approach") == "compassion")
	assert(load("res://scenes/residence.tscn") != null)
	assert(FileAccess.file_exists("res://data/residence.json"))
	var residence = load("res://scenes/residence.tscn").instantiate()
	root.add_child(residence)
	await process_frame
	assert(residence.get_node("Actors").get_child_count() == 6)
	var has_rice_investigation := false
	for actor in residence.get_node("Actors").get_children():
		if "npc_id" in actor and String(actor.npc_id) == "explore_residence_rice":
			has_rice_investigation = true
	assert(has_rice_investigation)
	assert(not residence.has_node("Actors/Master"))
	assert(not residence.has_node("Actors/Disciple"))
	assert(not residence.has_node("Actors/Guard"))
	for actor in residence.get_node("Actors").get_children():
		if actor.is_in_group("story_npcs"):
			assert(actor.frame_bounds.size() == 4)
			assert(actor.directional_texture.resource_path.begins_with("res://assets/characters/"))
			assert(actor.npc_id in [&"shen_he", &"bai_zhi", &"gu_heng", &"uncle_zhou"])
	assert(world.story.dialogues.has("n5_intro") and world.story.dialogues.has("ending_tyrant"))
	assert(world.director.logic.nodes.size() == 5)
	var art = load("res://scripts/character_art.gd")
	for id in art.DIRECTION_FILES:
		assert(art.directions(id).size() == 4, "Missing packaged four-view art: " + id)
	for map in ["hall", "town", "dormitory", "bamboo_station", "wind_cliff"]:
		var added = load("res://scenes/" + map + ".tscn").instantiate()
		root.add_child(added)
		await process_frame
		assert(added.map_id == map)
		assert(added.get_node("Background").texture != null)
		assert(added.get_node("ReturnExit").destination.begins_with("res://scenes/"))
		assert(added.get_node("Actors").get_child_count() >= 3)
		added.queue_free()
		await process_frame
	print("PACK_TEST: PASS (seven native maps, campaign JSON, dialogue)")
	quit()

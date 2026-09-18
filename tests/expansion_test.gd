extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _walk(action: String, frames: int) -> void:
	Input.action_press(action)
	for i in frames:
		await physics_frame
	Input.action_release(action)
	for i in 4:
		await physics_frame

func _run() -> void:
	assert(change_scene_to_file("res://scenes/courtyard.tscn") == OK)
	for i in 5:
		await physics_frame
	current_scene.story_stage = 2
	current_scene.story_flags = {"approach": "compassion", "clue": "seal", "residence_seen_shen_he": true}
	var routes := [
		["courtyard", Vector2(480, 175), "move_up", 26, "hall", "move_down", 44],
		["courtyard", Vector2(480, 490), "move_down", 24, "town", "move_up", 54],
		["residence", Vector2(265, 185), "move_up", 26, "dormitory", "move_down", 44]
	]
	for route in routes:
		if current_scene.map_id != route[0]:
			root.get_node("WorldState").travel(current_scene, "res://scenes/" + route[0] + ".tscn", route[1])
			for i in 6:
				await physics_frame
		current_scene.player.position = route[1]
		await _walk(route[2], route[3])
		assert(current_scene.map_id == route[4], "Entrance failed: " + route[4])
		assert(current_scene.story_stage == 2)
		assert(current_scene.story_flags.get("residence_seen_shen_he"))
		var map = current_scene
		# The new chapter gates the bed and pouch until N1 is resolved.
		if map.map_id == "dormitory":
			map.story_flags.n1_result = "talk"
			map.refresh_story_spots()
		var spawn: Vector2 = map.player.position
		assert(map.player.spawn_position.distance_to(Vector2(480, 130) if route[4] == "town" else Vector2(480, 440)) < 1)
		for actor in map.get_node("Actors").get_children():
			if not actor.is_in_group("clue_spots") or not String(actor.npc_id) in ["explore_hall_record", "explore_hall_lamp", "explore_town_notice", "explore_town_parcel", "explore_dormitory_bed", "explore_dormitory_pouch"]:
				continue
			map.player.position = actor.position + Vector2(0, 32)
			map.interact_with_nearest()
			assert(map.dialogue.active and not map.player.movement_enabled)
			while map.dialogue.active:
				if map.dialogue.waiting_for_choice:
					map.dialogue.choose(1)
				else:
					map.dialogue.advance()
			assert(map.story_flags.get(String(actor.npc_id)) == "verify")
			assert(map.story_stage == 2 and map.player.movement_enabled)
		map.player.position = spawn
		if "--capture" in OS.get_cmdline_user_args():
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://tests/" + route[4] + "_preview.png")
		await _walk(route[5], route[6])
		assert(current_scene.map_id == route[0], "Return failed: " + route[4])
		assert(current_scene.story_stage == 2)
		assert(current_scene.story_flags.get("explore_" + route[4] + "_" + ("record" if route[4] == "hall" else "notice" if route[4] == "town" else "bed")) == "verify")
	# Stage-three departure still happens before the south portal.
	root.get_node("WorldState").travel(current_scene, "res://scenes/courtyard.tscn", Vector2(480, 490))
	for i in 6:
		await physics_frame
	current_scene.story_stage = 3
	await _walk("move_down", 20)
	assert(current_scene.map_id == "courtyard" and current_scene.dialogue.active)
	while current_scene.dialogue.active:
		if current_scene.dialogue.waiting_for_choice:
			current_scene.dialogue.choose(0)
		else:
			current_scene.dialogue.advance()
	assert(current_scene.story_stage == 4)
	await _walk("move_down", 25)
	assert(current_scene.map_id == "town" and current_scene.story_stage == 4)
	print("EXPANSION_TEST: PASS (six-way walking travel, six clue choices, persistent flags, departure)")
	quit()

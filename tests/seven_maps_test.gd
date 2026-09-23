extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _walk(action: String, frames: int) -> void:
	Input.action_press(action)
	for i in frames:
		await physics_frame
	Input.action_release(action)
	for i in 5:
		await physics_frame

func _assert_route_sign_style(world: Node) -> void:
	for child in world.get_children():
		if child is Label and child.name.ends_with("Sign"):
			assert(child.get_theme_color("font_color") == Color(1, 0.93, 0.72, 1))
			assert(child.get_theme_color("font_outline_color") == Color(0.04, 0.06, 0.05, 1))
			assert(child.get_theme_constant("outline_size") == 4)
	if world.map_id == "bamboo_station":
		assert(world.get_node("RouteSign").position == Vector2(390, 175))
		assert(world.get_node("RouteSign").size == Vector2(180, 24))
		assert(world.get_node("TownSign").position == Vector2(390, 440))
		assert(world.get_node("TownSign").size == Vector2(180, 24))
	if world.map_id == "wind_cliff":
		assert(world.get_node("RouteSign").position == Vector2(385, 435))
		assert(world.get_node("RouteSign").size == Vector2(190, 24))

func _run() -> void:
	assert(change_scene_to_file("res://scenes/town.tscn") == OK)
	for i in 5:
		await physics_frame
	_assert_route_sign_style(current_scene)
	current_scene.story_flags = {"residence_resolved": true}
	current_scene.player.position = Vector2(865, 475)
	await _walk("move_right", 25)
	assert(current_scene.map_id == "bamboo_station")
	for mid in ["bamboo_station", "wind_cliff"]:
		assert(current_scene.map_id == mid)
		var world = current_scene
		_assert_route_sign_style(world)
		for actor in world.get_node("Actors").get_children():
			if not actor.is_in_group("clue_spots") or not String(actor.npc_id) in ["explore_bamboo_station_record", "explore_bamboo_station_signal", "explore_wind_cliff_record", "explore_wind_cliff_signal"]:
				continue
			world.player.position = actor.position + Vector2(0, 32)
			world.interact_with_nearest()
			while not world.dialogue.waiting_for_choice:
				world.dialogue.advance()
			world.dialogue.choose(0)
			world.dialogue.cancel()
			assert(not world.story_flags.has(String(actor.npc_id)))
			world.interact_with_nearest()
			while world.dialogue.active:
				if world.dialogue.waiting_for_choice:
					world.dialogue.choose(1)
				else:
					world.dialogue.advance()
			assert(world.story_flags.get(String(actor.npc_id)) == "verify")
		if mid == "bamboo_station":
			world.player.position = Vector2(480, 85)
			await _walk("move_up", 30)
	current_scene.player.position = Vector2(480, 440)
	await _walk("move_down", 40)
	assert(current_scene.map_id == "bamboo_station")
	assert(current_scene.story_flags.get("explore_wind_cliff_signal") == "verify")
	current_scene.player.position = Vector2(480, 440)
	await _walk("move_down", 40)
	assert(current_scene.map_id == "town")
	assert(current_scene.story_flags.get("residence_resolved"))
	print("SEVEN_MAPS_TEST: PASS")
	quit()

extends SceneTree

var failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var scene := load("res://scenes/courtyard.tscn") as PackedScene
	_check(scene != null, "Main scene loads")
	var world := scene.instantiate()
	root.add_child(world)
	# Portal transitions are covered by expansion_test; keep this test in courtyard.
	world.get_node("SouthMountainExit").monitoring = false
	await process_frame
	await physics_frame
	var player := world.get_node("Actors/Player") as CharacterBody2D
	var start := player.position
	var texture_paths: Dictionary = {}
	for actor in world.get_node("Actors").get_children():
		var texture: Texture2D = actor.get_node("Sprite2D").texture
		if actor.is_in_group("story_npcs"):
			texture = actor.directional_texture
		texture_paths[texture.resource_path] = true
		_check(texture.resource_path.begins_with("res://assets/characters/"), "Character texture is local: " + actor.name)
	_check(texture_paths.size() == 4, "Player and all three NPCs have different texture files")
	var actions := ["move_down", "move_up", "move_left", "move_right"]
	var directions := [Vector2.DOWN, Vector2.UP, Vector2.LEFT, Vector2.RIGHT]
	var expected_frames := [0, 1, 2, 3]
	for index in range(actions.size()):
		player.position = start
		await _hold([actions[index]], 12)
		var movement := player.position - start
		_check(movement.dot(directions[index]) > 15.0, "Moves " + actions[index])
		_check(player.get_node("Sprite2D").frame == expected_frames[index], "Faces " + actions[index])
	player.position = start
	await _hold(["move_right"], 12)
	var straight_distance := player.position.distance_to(start)
	player.position = start
	await _hold(["move_right", "move_up"], 12)
	_check(absf(player.position.distance_to(start) - straight_distance) < 3.0, "Diagonal speed is normalized")
	await _tap("reset_player")
	_check(player.position.distance_to(start) < 0.1, "R action resets spawn")
	await _hold(["move_left"], 160)
	_check(player.position.x >= 241.0, "Pond/west boundary blocks movement")
	player.position = start
	await _hold(["move_up"], 160)
	_check(player.position.y >= 166.0, "Temple/north boundary blocks movement")
	player.position = Vector2(350, 310)
	await _hold(["move_down"], 100)
	_check(player.position.y <= 399.0, "South wall blocks movement")
	player.position = start
	await _hold(["move_down"], 100)
	_check(player.position.y > 515.0 and player.position.y <= 534.0, "Gate passage opens to stairs and map bottom remains solid")
	await _hold(["move_up"], 100)
	_check(player.position.y < 350.0, "Gate can be crossed back into courtyard")
	for passage_x in [435, 525]:
		player.position = Vector2(passage_x, 350)
		await _hold(["move_down"], 60)
		_check(player.position.y > 475.0, "Gate opening supports off-center passage at x=" + str(passage_x))
	for stair_x in [465, 495]:
		player.position = Vector2(stair_x, 450)
		await _hold(["move_down"], 40)
		_check(player.position.y > 515.0, "Stairs support off-center passage at x=" + str(stair_x))
	player.position = Vector2(410, 380)
	await _hold(["move_down"], 40)
	_check(player.position.y <= 399.0, "Gate pillar/wall remains solid")
	player.position = Vector2(775, 296)
	await _hold(["move_right"], 45)
	_check(player.position.x <= 804.0, "Training dummy blocks movement")
	player.position = Vector2(900, 250)
	await _hold(["move_right"], 40)
	_check(player.position.x <= 904.0, "East boundary blocks movement")
	await _test_story(world, player)
	player.reset_position()
	if "--capture" in OS.get_cmdline_user_args():
		await _capture("res://tests/preview.png")
		player.position = Vector2(480, 450)
		await _capture("res://tests/gate_preview.png")
		player.position = Vector2(480, 240)
		world.interact_with_nearest()
		await _capture("res://tests/dialogue_preview.png")
	print("MOVEMENT_TEST: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)


func _test_story(world: Node, player: CharacterBody2D) -> void:
	var dialogue = world.get_node("Dialogue")
	_check(world.get_node("Actors").get_child_count() == 4, "Three NPCs added")
	player.position = Vector2(350, 260)
	world.interact_with_nearest()
	_check(not dialogue.active, "Cannot talk outside interaction range")
	player.position = Vector2(578, 330)
	await _tap("interact")
	_check(dialogue.active and dialogue.dialogue_id == "guard_early", "Early guard visit uses hint dialogue through E action")
	while dialogue.active:
		await _tap("interact")
	_check(world.story_stage == 0, "Out-of-order dialogue does not skip quest")
	player.position = Vector2(480, 242)
	await _hold(["move_up"], 30)
	_check(player.position.y >= 221.0, "NPC feet collision is solid")
	world.interact_with_nearest()
	var locked_position := player.position
	await _hold(["move_right"], 12)
	_check(player.position.distance_to(locked_position) < 0.1, "Movement locks while dialogue is open")
	await _tap("reset_player")
	_check(player.position.distance_to(locked_position) < 0.1, "Reset cannot teleport during dialogue")
	await _tap("cancel_dialogue")
	_check(not dialogue.active and world.story_stage == 0 and player.get("movement_enabled"), "Esc cancels without advancing and restores movement")
	_check(player.position.distance_to(locked_position) < 0.1, "Blocked reset does not leak after closing dialogue")
	world.interact_with_nearest()
	while dialogue.active:
		await _tap("interact")
	_check(world.story_stage == 1, "Master dialogue advances to clue objective")
	world.interact_with_nearest()
	_check(dialogue.dialogue_id == "master_repeat", "Completed NPC switches to repeat dialogue")
	dialogue.cancel()
	player.position = Vector2(650, 310)
	world.interact_with_nearest()
	while dialogue.active:
		if dialogue.waiting_for_choice:
			dialogue.choose(0)
		else:
			dialogue.advance()
	_check(world.story_stage == 2, "Disciple clue advances to guard objective")
	player.position = Vector2(578, 330)
	world.interact_with_nearest()
	while dialogue.active:
		if dialogue.waiting_for_choice:
			dialogue.choose(0)
		else:
			dialogue.advance()
	_check(world.story_stage == 4 and player.get("movement_enabled"), "Guard conversation completes prologue without walking downhill")
	_check(world.guide_task.map == "residence" and "左側石橋" in world.journal.text, "Guard completion directs player across west bridge")
	player.reset_position()
	await physics_frame
	_check(world.story_stage == 4, "Reset position preserves quest progress")
	_check(world.get_node("GateForeground/Roof").z_index == 0 and world.get_node("GateForeground").z_index > world.get_node("Actors").z_index, "Roof foreground is above actors")
	var roof: Polygon2D = world.get_node("GateForeground/Roof")
	_check(roof.uv.size() == roof.polygon.size(), "Roof texture UV matches polygon")


func _tap(action: StringName) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event = InputEventAction.new()
	event.action = action
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame


func _capture(path: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)


func _hold(actions: Array, frames: int) -> void:
	for action in actions:
		Input.action_press(action)
	for frame in range(frames):
		await physics_frame
	for action in actions:
		Input.action_release(action)
	await physics_frame


func _check(condition: bool, description: String) -> void:
	print("PASS: " if condition else "FAIL: ", description)
	if not condition:
		failures += 1

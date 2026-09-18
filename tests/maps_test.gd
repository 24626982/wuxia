extends SceneTree
var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _check(value: bool, message: String) -> void:
	print("PASS: " if value else "FAIL: ", message)
	if not value:
		failures += 1

func _hold(action: String, frames: int) -> void:
	Input.action_press(action)
	for frame in range(frames):
		await physics_frame
	Input.action_release(action)
	await physics_frame

func _run() -> void:
	var world = load("res://scenes/courtyard.tscn").instantiate()
	root.add_child(world)
	current_scene = world
	await process_frame
	var player = world.player
	for npc_name in ["Master", "Disciple", "Guard"]:
		var npc = world.get_node("Actors/" + npc_name)
		for index in range(4):
			var direction: Vector2 = [Vector2.DOWN, Vector2.UP, Vector2.LEFT, Vector2.RIGHT][index]
			player.position = npc.position + direction * 35
			world.interact_with_nearest()
			_check(npc.facing == index and npc.sprite.texture is AtlasTexture, npc_name + " faces player direction " + str(index))
			world.dialogue.cancel()
	world.story_stage = 2
	world.story_flags = {"approach":"compassion", "clue":"seal"}
	player.position = Vector2(270, 272)
	await _hold("move_left", 115)
	_check(current_scene.map_id == "residence", "Walking across west bridge loads residence")
	world = current_scene
	_check(world.story_stage == 2 and world.story_flags.get("clue") == "seal", "Map transition preserves quest and choices")
	_check(world.player.position.x > 800, "Arrival is on right bridge outside return trigger")
	world.player.position = Vector2(800, 315)
	await _hold("move_down", 24)
	_check(world.player.position.y <= 339, "Residence pond blocks walking off stone path")
	world.player.position = Vector2(800, 230)
	await _hold("move_up", 24)
	_check(world.player.position.y >= 211, "Residence buildings block walking through walls")
	for fence_x in [360, 460, 570]:
		world.player.position = Vector2(fence_x, 430)
		await _hold("move_down", 40)
		_check(world.player.position.y < 480, "South stone wall blocks the path at x=" + str(fence_x))
	for collider in world.get_node("Obstacles").get_children():
		_check(collider is CollisionPolygon2D and not collider.disabled, "Residence has its own active collision: " + collider.name)
	_check(world.get_node("Actors").get_child_count() == 5, "Residence contains player and four new NPCs")
	_check(not world.has_node("Actors/Master") and not world.has_node("Actors/Disciple") and not world.has_node("Actors/Guard"), "Initial NPC instances are absent from residence")
	world.player.position = Vector2(255, 325)
	world.interact_with_nearest()
	_check(world.dialogue.dialogue_id == "prologue_hint", "Early west courtyard visit directs player back to the prologue")
	world.dialogue.cancel()
	_check(not world.story_flags.has("shen_lead"), "Early visit grants no testimony")
	world.story_stage = 4
	world.interact_with_nearest()
	_check(world.dialogue.dialogue_id == "residence_shen_he", "New character offers residence-specific testimony")
	for step in range(64):
		if not world.dialogue.active:
			break
		if world.dialogue.waiting_for_choice:
			world.dialogue.choose(1)
		else:
			world.dialogue.advance()
	_check(world.story_flags.get("shen_lead") == "marks", "Residence choice commits without skipping courtyard quest")
	world.player.position = Vector2(850, 315)
	await _hold("move_right", 45)
	_check(current_scene.map_id == "courtyard", "Right bridge returns to courtyard")
	world = current_scene
	_check(world.story_stage == 4 and world.story_flags.get("shen_lead") == "marks", "Return preserves both maps' choices")
	_check(world.player.position.x > 240, "Return does not immediately retrigger exit")
	if "--capture" in OS.get_cmdline_user_args():
		world.player.position = Vector2(270, 272)
		await _hold("move_left", 115)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://tests/residence_preview.png")
	print("MAPS_TEST: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)

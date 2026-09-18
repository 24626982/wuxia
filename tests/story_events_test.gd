extends SceneTree
var failures := 0
var world: Node

func _initialize() -> void: run.call_deferred()

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func to_choice() -> void:
	for i in range(100):
		if not world.dialogue.active or world.dialogue.waiting_for_choice: return
		world.dialogue.advance()
	check(false, "Expected choice")

func choose_label(prefix: String) -> void:
	to_choice()
	for i in range(world.dialogue.current_choices.size()):
		if String(world.dialogue.current_choices[i].label).begins_with(prefix):
			world.dialogue.choose(i)
			return
	check(false, "Missing choice " + prefix)

func run() -> void:
	world = load("res://scenes/dormitory.tscn").instantiate()
	root.add_child(world)
	await process_frame
	check(world.get_node("Actors/bed").get_meta("locked", false), "Bed marked as locked before N1")
	world.story_flags.residence_resolved = true
	world.story_stage = 4
	check(world.director.interact("shi_an"), "N1 NPC starts eligible event")
	choose_label("小滿是不是")
	choose_label("小滿是不是")
	choose_label("小滿是不是")
	to_choice()
	check(world.dialogue.current_choices.size() == 2, "Third miss offers fight or leave")
	choose_label("先離開")
	while world.dialogue.active: world.dialogue.advance()
	check(not world.story_flags.has("n1_result"), "Leaving records no result")
	world.director.interact("shi_an")
	choose_label("他的包袱")
	for i in range(4): world.dialogue.advance()
	world.dialogue.cancel()
	check(not world.story_flags.has("n1_result") and not world.story_flags.has("heart_shi_an"), "Cancelled encounter rolls back line actions and result")
	check(world.get_node("Actors/bed").get_meta("locked", false), "Cancel restores interaction gate")
	world.director.interact("shi_an")
	choose_label("小滿是不是")
	choose_label("小滿是不是")
	choose_label("小滿是不是")
	choose_label("出手")
	for i in range(200):
		if not world.dialogue.active: break
		if world.dialogue.waiting_for_choice: world.dialogue.choose(0)
		else: world.dialogue.advance()
	check(world.story_flags.get("n1_result") == "tried_then_fight", "Third-miss fight result survives battle")
	check(not world.get_node("Actors/bed").get_meta("locked", false), "Battle unlocks exploration")
	world.queue_free()
	await process_frame
	# Every new interaction can be reached from its immediate south approach.
	for map in ["hall", "town", "dormitory", "bamboo_station", "wind_cliff"]:
		world = load("res://scenes/" + map + ".tscn").instantiate()
		root.add_child(world)
		await physics_frame
		for spot in world.get_node("Actors").get_children():
			if not spot.is_in_group("clue_spots") or not spot.visible: continue
			world.player.position = spot.position + Vector2(0, 20)
			check(world._find_nearest_npc() == spot, map + " interaction has distinct approach: " + String(spot.npc_id))
			var query := PhysicsPointQueryParameters2D.new()
			query.position = world.player.position
			query.exclude = [world.player.get_rid()]
			check(world.get_world_2d().direct_space_state.intersect_point(query).is_empty(), map + " interaction approach outside walls: " + String(spot.npc_id))
		world.queue_free()
		await process_frame
	# Exercise the real report -> map switch -> courtyard ending handoff.
	check(change_scene_to_file("res://scenes/hall.tscn") == OK, "Load finale map")
	await process_frame
	await process_frame
	world = current_scene
	world.story_stage = 4
	world.story_flags = {"n1_result": "talk", "n2_result": "talk", "n3_result": "talk", "n4_result": "talk", "n5_result": "talk", "revealed": true, "got_manual": true}
	world.director.enter_map()
	for i in range(200):
		if not world.dialogue.active: break
		if world.dialogue.waiting_for_choice: world.dialogue.choose(0)
		else: world.dialogue.advance()
	await process_frame
	await process_frame
	world = current_scene
	check(world.map_id == "courtyard", "Finale returns to courtyard automatically")
	for i in range(200):
		if not world.dialogue.active: break
		if world.dialogue.waiting_for_choice: world.dialogue.choose(0)
		else: world.dialogue.advance()
	check(world.story_flags.get("ending_seen", false), "Automatic ending finishes after scene handoff")
	print("STORY_EVENTS_TEST: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)

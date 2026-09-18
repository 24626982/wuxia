extends SceneTree
const Guide = preload("res://scripts/story_guide.gd")
var failures := 0
var world: Node

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	print("PASS: " if ok else "FAIL: ", message)
	if not ok: failures += 1

func drain() -> void:
	for i in range(300):
		if not world.dialogue.active: return
		if world.dialogue.waiting_for_choice: world.dialogue.choose(0)
		else: world.dialogue.advance()
	check(false, "Conversation terminates")
	world.dialogue.cancel()

func to_choice() -> void:
	for i in range(100):
		if not world.dialogue.active or world.dialogue.waiting_for_choice: return
		world.dialogue.advance()

func bed_choice() -> int:
	for i in range(world.dialogue.current_choices.size()):
		if String(world.dialogue.current_choices[i].label).begins_with("你弟弟是"): return i
	return -1

func run() -> void:
	world = load("res://scenes/residence.tscn").instantiate()
	root.add_child(world)
	await process_frame
	for stage in range(4):
		world.story_stage = stage
		world.story_flags.clear()
		for id in ["shen_he", "bai_zhi", "gu_heng", "uncle_zhou"]:
			for actor in world.get_node("Actors").get_children():
				if actor.get("npc_id") != StringName(id): continue
				world.player.position = actor.position + Vector2(0, 20)
				world.interact_with_nearest()
				drain()
		check(not world.story_flags.has("shen_lead") and not world.story_flags.has("bai_method") and not world.story_flags.has("gu_response") and not world.story_flags.get("residence_resolved", false), "Stage %d cannot acquire west courtyard testimony" % stage)
	world.story_stage = 4
	for id in ["shen_he", "bai_zhi", "gu_heng", "uncle_zhou"]:
		for actor in world.get_node("Actors").get_children():
			if actor.get("npc_id") != StringName(id): continue
			world.player.position = actor.position + Vector2(0, 20)
			world.interact_with_nearest()
			drain()
	check(world.story_flags.get("residence_resolved", false), "Completed prologue unlocks west courtyard inquiry")
	world.queue_free()
	await process_frame
	world = load("res://scenes/dormitory.tscn").instantiate()
	root.add_child(world)
	await process_frame
	world.story_flags.residence_resolved = true
	for stage in range(4):
		world.story_stage = stage
		check(not world.director.interact("shi_an"), "Stage %d cannot start N1 even with old testimony flags" % stage)
		if world.dialogue.active: world.dialogue.cancel()
	world.story_stage = 4
	check(world.director.interact("shi_an"), "Completed prologue unlocks N1")
	world.dialogue.cancel()
	world.queue_free()
	await process_frame
	world = load("res://scenes/town.tscn").instantiate()
	root.add_child(world)
	await process_frame
	world.story_stage = 4
	world.story_flags = {"residence_resolved": true, "n1_result": "talk", "explore_town_notice": "observe"}
	check(world.director.interact("brother"), "Brother remains available before investigating the bed")
	to_choice()
	check(bed_choice() == -1, "Cannot claim to have investigated an unseen bed")
	world.dialogue.cancel()
	for method in ["observe", "verify"]:
		world.story_flags.explore_dormitory_bed = method
		world.director.interact("brother")
		to_choice()
		var index := bed_choice()
		check(index >= 0, "Committed %s investigation unlocks truthful bed testimony" % method)
		if index >= 0: world.dialogue.choose(index)
		drain()
		check(world.story_flags.get("n2_result") == "talk", "Truthful testimony resolves N2")
		world.story_flags.erase("n2_result")
	world.story_flags.erase("explore_dormitory_bed")
	for result in ["fight", "tried_then_fight", "talk"]:
		world.story_flags.n2_result = result
		check(Guide.next(4, world.story_flags).target == "third_lamp_at_night", "Completed N2 (%s) advances guidance without a bed investigation" % result)
	world.story_flags.erase("n2_result")
	check(Guide.next(4, world.story_flags).target == "explore_dormitory_bed", "Unfinished N2 still guides players to the bed")
	world.queue_free()
	await process_frame
	world = load("res://scenes/wind_cliff.tscn").instantiate()
	root.add_child(world)
	await process_frame
	world.story_stage = 4
	world.story_flags = {"n1_result": "talk", "n2_result": "talk", "n3_result": "talk", "n4_result": "talk", "suspect_known": true, "monologue": "rules", "hide_spot": true}
	world._update_objective()
	var before: Dictionary = world.story_flags.duplicate(true)
	world.director.enter_map()
	check(world.dialogue.waiting_for_choice and world.dialogue.current_choices.size() == 2, "Real N5 map entry offers retrieval before confrontation")
	world.dialogue.choose(0)
	check(world.story_flags.get("manual_secured", false) and "先一步" in world.dialogue.body.text, "Retrieval uses the already secured manual introduction")
	world.dialogue.cancel()
	check(world.story_flags == before and not world.director.busy and world.player.movement_enabled, "Cancelling N5 rolls back retrieval and unlocks movement")
	world.director.enter_map()
	check(world.dialogue.waiting_for_choice, "Cancelled N5 can be retried")
	world.dialogue.choose(1)
	check(world.story_flags.get("hide_spot", false) and not world.story_flags.get("manual_secured", false) and "沒有先取走" in world.dialogue.body.text, "Deferring retrieval preserves the clue and shows Yan holding the manual")
	world.dialogue.cancel()
	check(world.story_flags == before, "Cancelling deferred retrieval restores the entry flags")
	world.story_flags.erase("hide_spot")
	world.director.enter_map()
	check(not world.dialogue.waiting_for_choice and not world.story_flags.has("manual_secured"), "Unknown hiding spot starts confrontation without retrieval")
	world.dialogue.cancel()
	world.queue_free()
	await process_frame
	print("STORY_PROGRESSION_TEST: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)

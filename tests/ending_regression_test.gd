extends "res://tests/story_campaign_test.gd"
## Exercise v1.5 N5 tube-choice semantics, cancellation and incomplete ending data.

func enter_cliff(extra: Dictionary = {}) -> void:
	world.story_flags = {"n1_result": "fight", "n2_result": "fight", "n3_result": "fight", "n4_result": "fight", "chen_bai_nails": true, "explore_wind_cliff_record": "observe", "suspect_known": true, "monologue": "rules"}
	world.story_flags.merge(extra, true)
	world._update_objective()
	world.director.entry_seen.clear()
	world.director.enter_map()

func to_choice() -> void:
	for step in range(100):
		if not world.dialogue.active or world.dialogue.waiting_for_choice: return
		world.dialogue.advance()
	check(false, "Choice must appear within step limit")

func run() -> void:
	world = load("res://scenes/wind_cliff.tscn").instantiate()
	root.add_child(world)
	await process_frame
	world.story_stage = 4
	policy = "fight"
	enter_cliff()
	check(world.dialogue.waiting_for_choice, "Unknown hiding spot warns before N5")
	world.dialogue.choose(1)
	check("嚴承從崖邊" in world.dialogue.body.text, "Unknown hiding spot leaves the manual with Yan")
	var before: Dictionary = world.story_flags.duplicate(true)
	before.erase("took_manual_first")
	world.dialogue.cancel()
	check(world.story_flags == before and not world.director.busy, "Cancelling N5 rolls back its transaction")
	world.director.enter_map()
	drain()
	check(world.director.ending_record().id == "ending_exiled", "Fighting without the hiding spot loses the manual")
	enter_cliff({"hide_spot": true})
	check("崖上還沒有人" in world.dialogue.body.text, "Known hiding spot offers the tube choice before confrontation")
	drain()
	check(world.story_flags.get("took_manual_first", false) and world.director.ending_record().id == "ending_tyrant", "Taking the manual before fighting reaches the tyrant ending")
	for missing in ["chen_bai_nails", "explore_wind_cliff_record"]:
		world.story_flags = before.duplicate(true)
		world.story_flags.erase(missing)
		world.director.entry_seen.clear()
		check(not world.director.interact("interact_tubes"), "Missing " + missing + " blocks the separate cliff search")
	# Mutate only the in-memory table, then play the real finale for both fallbacks.
	var original: Array = world.director.logic.endings.table.duplicate(true)
	world.story_flags = before.duplicate(true)
	world.story_flags.n5_result = "fight"
	world.story_flags.got_manual = true
	for remove_route in [false, true]:
		world.director.logic.endings.table = original.filter(func(ending): return ending.route != "fight" if remove_route else ending.id != "ending_tyrant")
		world.story_flags.finale_pending = true
		world.story_flags.erase("ending_seen")
		world.story_flags.erase("ending_title")
		print("Expected diagnostic: No ending for route=fight got_manual=true")
		world.director.run_event({"id": "fallback_test", "sequence": ["@ending"]})
		drain()
		var expected: String = world.director.logic.endings.table[0].title if remove_route else ""
		if not remove_route:
			for ending in original:
				if ending.id == "ending_exiled": expected = ending.title
		check(world.story_flags.get("ending_seen", false) and world.story_flags.get("ending_title") == expected, "Fallback ending plays and records its title")
		check(not world.story_flags.get("finale_pending", false), "Fallback completes pending finale")
	world.director.logic.endings.table = original
	world.queue_free()
	await process_frame
	print("ENDING_REGRESSION_TEST: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)

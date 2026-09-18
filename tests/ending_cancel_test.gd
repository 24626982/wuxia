extends SceneTree
## Esc-cancel stress: aborting any encounter (including the finale) must roll back
## cleanly and leave every ending still reachable on a retry.
const Rules = preload("res://scripts/story_rules.gd")
var failures := 0
var world: Node
var rng := RandomNumberGenerator.new()
var cancel_chance := 0.0
var last_started := true
var seen: Dictionary = {}

func _initialize() -> void:
	run.call_deferred()

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func drain() -> void:
	for step in range(4000):
		var dialogue = world.dialogue
		if not dialogue.active:
			check(not world.director.busy, "Encounter finished without deadlocking")
			check(world.player.movement_enabled, "Movement restored after encounter")
			return
		if rng.randf() < cancel_chance:
			dialogue.cancel()
			continue
		if not dialogue.waiting_for_choice:
			dialogue.advance()
			continue
		dialogue.choose(rng.randi_range(0, dialogue.current_choices.size() - 1))
	check(false, "Story exceeded step limit")
	world.dialogue.cancel()

func fire(id: String) -> bool:
	for entry in world.director.logic.events:
		if entry.get("id") != id: continue
		world.map_id = entry.map
		if not world.director.eligible(entry): return false
		world.director.entry_seen.clear()
		var before = world.dialogue.active
		if entry.get("trigger") == "enter" or id == "act3_chen_bai_nails":
			world.director.enter_map()
		else:
			world.director.interact(entry.get("npc", entry.get("trigger", "")))
		last_started = world.dialogue.active or world.director.busy or before
		drain()
		return true
	check(false, "Missing event " + id)
	return false

## A player who cancels for a while, then commits: the encounter must still pay out.
func resolve(id: String, flag: String) -> bool:
	var wanted := cancel_chance
	for attempt in range(14):
		if world.story_flags.has(flag): break
		cancel_chance = wanted if attempt < 4 else 0.0
		if not fire(id): break
	cancel_chance = wanted
	return world.story_flags.has(flag)

func playthrough() -> void:
	world = load("res://scenes/courtyard.tscn").instantiate()
	root.add_child(world)
	await process_frame
	cancel_chance = 0.0
	for id in ["master_start", "disciple_clue", "guard_route", "residence_shen_he", "residence_bai_zhi", "residence_gu_heng", "residence_uncle_zhou", "residence_uncle_zhou_resolution"]:
		world._open_dialogue(id)
		drain()
	cancel_chance = 0.04
	fire("dorm_chen_bai_first")
	var stage := "n1"
	var ok := resolve("n1", "n1_result")
	if ok:
		cancel_chance = 0.0
		for id in ["explore_dormitory_bed", "explore_dormitory_pouch", "explore_town_notice"]:
			world._open_dialogue(id)
			drain()
		cancel_chance = 0.04
		stage = "n2"
		ok = resolve("n2", "n2_result")
	if ok:
		stage = "n3"
		ok = resolve("n3", "n3_result")
	if ok:
		var wanted := cancel_chance
		for attempt in range(14):
			if world.story_flags.get("chen_bai_nails", false): break
			cancel_chance = wanted if attempt < 4 else 0.0
			fire("act3_chen_bai_nails")
		cancel_chance = wanted
		cancel_chance = 0.0
		world._open_dialogue("explore_wind_cliff_record")
		drain()
		cancel_chance = 0.04
		if rng.randf() < 0.6: fire("cliff_search")
		stage = "n4"
		ok = resolve("n4", "n4_result")
	if ok:
		if rng.randf() < 0.5: fire("cliff_search")
		var hall_wanted := cancel_chance
		for attempt in range(14):
			if world.story_flags.has("revealed"): break
			cancel_chance = hall_wanted if attempt < 4 else 0.0
			fire("hall_revisit")
		cancel_chance = hall_wanted
		stage = "hall/n5"
		ok = world.story_flags.has("revealed") and resolve("n5", "n5_result")
	check(ok, "Stuck at %s (seed %d): %s" % [stage, rng.seed, diagnose(stage)])
	if not ok:
		await finish()
		return
	var record: Dictionary = world.director.ending_record()
	check(not record.is_empty(), "Ending record exists after cancellations")
	# The finale itself: cancel it repeatedly, then let it play out.
	for attempt in range(20):
		if world.story_flags.get("ending_seen", false): break
		cancel_chance = 0.3 if attempt < 4 else 0.0
		check(world.story_flags.get("finale_pending", true), "Cancelled finale keeps finale_pending")
		world.director.run_event({"id": "cancel_finale", "sequence": ["finale_report", "finale_courtyard", "finale_monologue", "@ending"]})
		drain()
	check(world.story_flags.get("ending_seen", false), "Ending still reachable after cancelling the finale")
	check(world.story_flags.get("ending_title", "") == record.get("title", ""), "Ending title matches the record")
	seen[record.get("id", "?")] = int(seen.get(record.get("id", "?"), 0)) + 1
	await finish()

func diagnose(stage: String) -> String:
	var keys := ["n1_result", "n2_result", "n3_result", "n4_result", "n5_result", "residence_resolved", "chen_bai_nails", "revealed", "suspect_known", "monologue", "hide_spot"]
	var shown := {}
	for key in keys: shown[key] = world.story_flags.get(key)
	var blocked := []
	for entry in world.director.logic.events:
		if entry.get("id") != stage.split("/")[-1]: continue
		for key in entry.get("requires", {}):
			if not Rules.matches(world.story_flags, {key: entry.requires[key]}): blocked.append(key)
	return "unmet=%s busy=%s dialogue_active=%s started=%s flags=%s" % [str(blocked), str(world.director.busy), str(world.dialogue.active), str(last_started), str(shown)]

func finish() -> void:
	world.queue_free()
	await process_frame

func run() -> void:
	var runs := 120
	for i in range(runs):
		rng.seed = 1000 + i
		await playthrough()
	print("reached: ", seen)
	print("ENDING_CANCEL_TEST: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures over ", runs, " runs)")
	quit(0 if failures == 0 else 1)

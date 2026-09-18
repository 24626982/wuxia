extends SceneTree
## Randomised full-campaign playthroughs: every ending must be reachable and no
## run may deadlock, crash or land on an empty ending record.
const Rules = preload("res://scripts/story_rules.gd")
var failures := 0
var world: Node
var rng := RandomNumberGenerator.new()
var seen: Dictionary = {}
var stuck: Dictionary = {}

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
			return
		if not dialogue.waiting_for_choice:
			dialogue.advance()
			continue
		check(dialogue.current_choices.size() > 0, "Choice line offers at least one option")
		dialogue.choose(rng.randi_range(0, dialogue.current_choices.size() - 1))
	check(false, "Story exceeded step limit")
	world.dialogue.cancel()

func fire(id: String) -> bool:
	for entry in world.director.logic.events:
		if entry.get("id") != id: continue
		world.map_id = entry.map
		if not world.director.eligible(entry): return false
		world.director.entry_seen.clear()
		if entry.get("trigger") == "enter" or id == "act3_chen_bai_nails":
			world.director.enter_map()
		else:
			world.director.interact(entry.get("npc", entry.get("trigger", "")))
		drain()
		return true
	check(false, "Missing event " + id)
	return false

## Retries an encounter the way a player can: walking away and coming back.
func resolve(id: String, flag: String) -> bool:
	for attempt in range(12):
		if world.story_flags.has(flag): return true
		if not fire(id): break
	if not world.story_flags.has(flag):
		stuck[id] = int(stuck.get(id, 0)) + 1
		return false
	return true

func playthrough() -> void:
	world = load("res://scenes/courtyard.tscn").instantiate()
	root.add_child(world)
	await process_frame
	for id in ["master_start", "disciple_clue", "guard_route", "residence_shen_he", "residence_bai_zhi", "residence_gu_heng", "residence_uncle_zhou", "residence_uncle_zhou_resolution"]:
		world._open_dialogue(id)
		drain()
	if not world.story_flags.get("residence_resolved", false):
		world.story_flags.residence_resolved = true
	fire("dorm_chen_bai_first")
	if not resolve("n1", "n1_result"):
		await finish()
		return
	for id in ["explore_dormitory_bed", "explore_dormitory_pouch", "explore_town_notice"]:
		world._open_dialogue(id)
		drain()
	if not resolve("n2", "n2_result"):
		await finish()
		return
	if not resolve("n3", "n3_result"):
		await finish()
		return
	fire("act3_chen_bai_nails")
	world._open_dialogue("explore_wind_cliff_record")
	drain()
	if not resolve("n4", "n4_result"):
		await finish()
		return
	fire("hall_revisit")
	if not resolve("n5", "n5_result"):
		await finish()
		return
	var record: Dictionary = world.director.ending_record()
	check(not record.is_empty(), "Ending record exists for route=%s got_manual=%s" % [Rules.value(world.story_flags, "route"), world.story_flags.get("got_manual")])
	if record.is_empty():
		await finish()
		return
	world.director.run_event({"id": "fuzz_finale", "sequence": ["finale_report", "finale_courtyard", "finale_monologue", "@ending"]})
	drain()
	check(world.story_flags.get("ending_seen", false), "Finale reaches an ending for " + record.id)
	check(world.story_flags.get("ending_title", "") == record.title, "Ending title recorded for " + record.id)
	seen[record.id] = int(seen.get(record.id, 0)) + 1
	await finish()

func finish() -> void:
	world.queue_free()
	await process_frame

func run() -> void:
	var runs := 200
	for i in range(runs):
		rng.seed = i
		await playthrough()
	print("reached: ", seen)
	print("unresolved encounters: ", stuck)
	for ending in JSON.parse_string(FileAccess.get_file_as_string("res://data/game_logic.json")).endings.table:
		check(seen.has(ending.id), "Unreachable ending: " + ending.id)
	print("ENDING_FUZZ_TEST: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures over ", runs, " runs)")
	quit(0 if failures == 0 else 1)

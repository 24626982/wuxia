extends SceneTree
const Residence = preload("res://scripts/residence_story.gd")
const Guide = preload("res://scripts/story_guide.gd")
const Art = preload("res://scripts/character_art.gd")
var failures := 0

func _initialize() -> void: run.call_deferred()

func check(ok: bool, message: String) -> void:
	print("PASS: " if ok else "FAIL: ", message)
	if not ok: failures += 1

func run() -> void:
	var world = load("res://scenes/residence.tscn").instantiate()
	root.add_child(world)
	await process_frame
	world.story_stage = 4
	world._open_dialogue("residence_uncle_zhou")
	for i in range(100):
		if not world.dialogue.active: break
		if world.dialogue.waiting_for_choice: world.dialogue.choose(0)
		else: world.dialogue.advance()
	check(Residence.testimony_count(world.story_flags) == 0, "Visiting Zhou first must not count as a corroborated witness")
	check(not "1 / 4" in world.journal.text, "HUD does not report Zhou as 1/4 witnesses")
	world.story_flags = {"residence_resolved": true, "n1_result": "fight"}
	world._update_objective()
	check(not "交鋒" in world.journal.text, "Combat count is not shown to the player")
	world.story_stage = 4
	world.story_flags = {"residence_seen_uncle_zhou": true}
	world._update_objective()
	check("沈禾" in world.objective.text and "白芷" in world.journal.text, "Old Zhou flags cannot advance the three-witness guidance")
	for id in Residence.TESTIMONY_IDS:
		world.story_flags["residence_seen_" + id] = true
	world._update_objective()
	check("周伯" in world.objective.text, "Three witnesses guide player back to Zhou")
	check(Residence.dialogue_for(&"uncle_zhou", world.story_flags) == &"residence_uncle_zhou_resolution", "Zhou resolves after the three actual testimonies")
	for map in Guide.MAP_NAMES:
		for destination in Guide.MAP_NAMES:
			if map == destination: continue
			var hop := Guide.next_map(map, destination)
			check(Guide.ROADS[map].has(hop), map + " has a usable route toward " + destination)
	for id in Art.MAIN + Art.SUPPORT + Art.EXISTING.keys():
		var texture: Texture2D = Art.texture(id)
		check(texture != null and texture.get_height() > 0, "Individual character art: " + id)
	for id in world.story.dialogues:
		check_portraits(world.story.dialogues[id])
	world.queue_free()
	await process_frame
	print("GUIDANCE_TEST: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)

func check_portraits(value) -> void:
	if value is Array:
		for item in value: check_portraits(item)
	elif value is Dictionary:
		if value.has("speaker") and not value.speaker in ["旁白", "江湖札記"]:
			check(Art.portrait(value.speaker) != null, "Portrait resolves for " + value.speaker)
		for nested in value.values():
			if nested is Array or nested is Dictionary: check_portraits(nested)

extends SceneTree
## Regressions reported against the real finale data and StoryDirector call path.
var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func check(value: bool, message: String) -> void:
	print("PASS: " if value else "FAIL: ", message)
	if not value:
		failures += 1

func _run() -> void:
	var world = load("res://scenes/courtyard.tscn").instantiate()
	root.add_child(world)
	await process_frame
	var finale_event: Dictionary
	for event in world.director.logic.events:
		if event.get("id") == "finale":
			finale_event = event
			break
	check(finale_event.sequence[0] == "@report", "Real finale event selects the report variant")
	world.story_flags = {"n5_result": "talk", "handed_back": "yan_cheng"}
	world.director.run_event(finale_event)
	check(world.dialogue.dialogue_id == &"finale_report_handed_back", "Real finale event plays Yan's hand-back report")
	world.dialogue.cancel()
	await process_frame

	world.director.aborted = false
	world.director.play("ending_exiled")
	check(world.dialogue.dialogue_id == &"ending_exiled", "StoryDirector preserves the dialogue ID")
	world.dialogue.cancel()
	await process_frame

	var state = root.get_node("WorldState")
	var old_gender: String = state.hero_gender
	state.hero_gender = "female"
	var ending_lines: Array = world.story.dialogues.ending_junzi
	world.dialogue.begin(&"ending_junzi", ending_lines, {})
	check(world.dialogue.body.text.begins_with("她接任"), "Female protagonist uses 她 in protagonist narration")
	for step in range(4):
		world.dialogue.advance()
	check("他那一行" in world.dialogue.body.text, "Another male character keeps 他 in the same ending")
	world.dialogue.cancel()
	state.hero_gender = old_gender

	world.story_flags = {}
	world.director.run_event({"id": "hall_revisit", "sequence": ["hall_revisit_intro"], "effects": {"revealed": true}, "optional": ["hall_revisit_draft"]})
	for step in range(32):
		if world.dialogue.waiting_for_choice:
			break
		world.dialogue.advance()
	world.dialogue.cancel()
	await process_frame
	check(world.story_flags.get("revealed", false), "Cancelling the optional hall menu keeps the completed revisit")
	world.queue_free()
	await process_frame
	print("REPORTED_BUG_REGRESSION_TEST: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)

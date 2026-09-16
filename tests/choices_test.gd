extends SceneTree

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _check(value: bool, message: String) -> void:
	print("PASS: " if value else "FAIL: ", message)
	if not value:
		failures += 1

func _finish(dialogue: Node, option: int) -> void:
	for step in range(64):
		if not dialogue.active:
			return
		if dialogue.waiting_for_choice:
			dialogue.choose(option)
		else:
			dialogue.advance()
	_check(false, "Dialogue terminates within 64 steps")

func _run() -> void:
	var input_world = load("res://scenes/courtyard.tscn").instantiate()
	root.add_child(input_world)
	await process_frame
	var input_dialogue = input_world.get_node("Dialogue")
	input_world._open_dialogue("master_start")
	input_dialogue.advance()
	var down := InputEventAction.new()
	down.action = "choice_down"
	down.pressed = true
	Input.parse_input_event(down)
	await process_frame
	_check(input_dialogue.selected_choice == 1, "Arrow action changes native button focus")
	var confirm := InputEventAction.new()
	confirm.action = "confirm_choice"
	confirm.pressed = true
	Input.parse_input_event(confirm)
	await process_frame
	_check(not input_dialogue.waiting_for_choice and input_dialogue.pending_effects.get("approach") == "justice", "Enter confirms highlighted choice without skipping reply")
	input_dialogue.cancel()
	input_world._open_dialogue("master_start")
	input_dialogue.advance()
	input_dialogue.choice_buttons[0].pressed.emit()
	_check(input_dialogue.pending_effects.get("approach") == "compassion", "Native Button pressed signal selects its own option")
	input_dialogue.cancel()
	input_world.queue_free()
	await process_frame
	for approach in range(2):
		for clue in range(2):
			for trust in range(2):
				var world = load("res://scenes/courtyard.tscn").instantiate()
				root.add_child(world)
				await process_frame
				var dialogue = world.get_node("Dialogue")
				var original := JSON.stringify(world.story)
				world._open_dialogue("master_start")
				for step in range(16):
					if dialogue.waiting_for_choice:
						break
					dialogue.advance()
				_check(dialogue.waiting_for_choice, "Master presents native choices")
				var index: int = dialogue.line_index
				dialogue.advance()
				_check(dialogue.line_index == index, "Choice cannot be skipped by advance")
				dialogue.choose(approach)
				_check(world.story_flags.is_empty(), "Choice remains provisional until conversation ends")
				dialogue.cancel()
				_check(world.story_stage == 0 and world.story_flags.is_empty(), "Cancel rolls back choice and progress")
				world._open_dialogue("master_start")
				_finish(dialogue, approach)
				_check(world.story_stage == 1, "Master completion commits progress")
				_check(world.story_flags.get("approach") == ("compassion" if approach == 0 else "justice"), "Approach is committed")
				world._open_dialogue("disciple_clue")
				_finish(dialogue, clue)
				world._open_dialogue("guard_route")
				_finish(dialogue, trust)
				_check(world.story_flags.get("clue") == ("whistle" if clue == 0 else "seal"), "Clue is committed")
				_check(world.story_flags.get("trust_guard") == (trust == 0), "Trust is committed")
				world._open_dialogue("departure")
				_finish(dialogue, 0)
				var expected := "守約尋人" if approach == 0 and trust == 0 else ("循證追查" if clue == 1 else "孤身追影")
				_check(world.story_stage == 4 and world.ending_name() == expected, "Branch ending: " + expected)
				_check(JSON.stringify(world.story) == original, "Branch replies do not mutate local source story")
				world.queue_free()
				await process_frame
	print("CHOICES_TEST: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)

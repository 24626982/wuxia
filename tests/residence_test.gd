extends SceneTree
const Chapter = preload("res://scripts/residence_story.gd")
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
	_check(false, "Conversation terminates")

func _run() -> void:
	for branch in range(16):
		var world = load("res://scenes/residence.tscn").instantiate()
		root.add_child(world)
		await process_frame
		world.story_stage = 4
		var dialogue = world.dialogue
		var source := JSON.stringify(world.story)
		_check(world.get_node("Actors").get_child_count() == 5, "Exactly four new NPCs")
		var textures: Dictionary = {}
		for npc in world.get_node("Actors").get_children():
			if not npc.is_in_group("story_npcs"):
				continue
			_check(String(npc.npc_id) in Chapter.WITNESSES, "Only new cast IDs appear in residence")
			textures[npc.directional_texture.resource_path] = true
			for direction in range(4):
				var offset: Vector2 = [Vector2.DOWN, Vector2.UP, Vector2.LEFT, Vector2.RIGHT][direction] * 35
				world.player.position = npc.position + offset
				world.interact_with_nearest()
				_check(npc.facing == direction and dialogue.active, "New NPC turns toward nearby player")
				dialogue.cancel()
		_check(textures.size() == 4 and not textures.has("res://assets/characters/swordsman.png"), "Four independent NPC sheets")
		_check(Chapter.testimony_count(world.story_flags) == 0, "Cancelled visits do not count")
		_check(Chapter.dialogue_for(&"uncle_zhou", world.story_flags) == &"residence_uncle_zhou", "Resolution stays locked without testimonies")
		world._open_dialogue("residence_shen_he")
		for step in range(16):
			if dialogue.waiting_for_choice:
				break
			dialogue.advance()
		dialogue.choose(1)
		dialogue.cancel()
		_check(not world.story_flags.has("shen_lead"), "Cancelled selection rolls back")
		# Alternate interview order; both follow-up options remain completable.
		var order: Array = Chapter.TESTIMONY_IDS.duplicate()
		if branch % 2 == 1:
			order.reverse()
		for witness in order:
			world._open_dialogue(Chapter.dialogue_for(StringName(witness), world.story_flags))
			var index: int = Chapter.WITNESSES.find(witness)
			_finish(dialogue, (branch >> mini(index, 2)) & 1)
		_check(Chapter.testimony_count(world.story_flags) == 3 and world.story_stage == 4, "Only the three witnesses count; Zhou verifies their testimony")
		for witness in ["shen_he", "bai_zhi", "gu_heng"]:
			_check(String(Chapter.dialogue_for(StringName(witness), world.story_flags)).ends_with("_repeat"), "Completed witness offers a reminder, not a repeated choice")
		_check(Chapter.dialogue_for(&"uncle_zhou", world.story_flags) == &"residence_uncle_zhou_resolution", "Four completed testimonies unlock comparison")
		world._open_dialogue("residence_uncle_zhou_resolution")
		for step in range(16):
			if dialogue.waiting_for_choice:
				break
			dialogue.advance()
		dialogue.choose((branch >> 3) & 1)
		dialogue.cancel()
		_check(not world.story_flags.get("residence_resolved", false), "Cancel resolution does not complete chapter")
		world._open_dialogue("residence_uncle_zhou_resolution")
		_finish(dialogue, (branch >> 3) & 1)
		_check(world.story_flags.get("residence_resolved", false), "Every branch completes west courtyard inquiry")
		_check(world.story_flags.get("residence_next_lead") == ("seal" if branch < 8 else "safety"), "Next investigation priority is saved")
		_check(Chapter.dialogue_for(&"uncle_zhou", world.story_flags) == &"residence_uncle_zhou_repeat", "Completed caretaker uses reminder dialogue")
		_check(JSON.stringify(world.story) == source, "Local source story stays immutable")
		world.queue_free()
		await process_frame
	print("RESIDENCE_TEST: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)

extends SceneTree
const Journal = preload("res://scripts/clue_journal.gd")
var failures := 0
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func run() -> void:
	var world = load("res://scenes/courtyard.tscn").instantiate()
	root.add_child(world)
	await process_frame
	check(world.story_flags.is_empty(), "No unearned clues at start")
	world.notebook.button.pressed.emit()
	check(world.notebook.opened and not world.player.movement_enabled, "Button opens modal and stops movement")
	world.interact_with_nearest()
	check(not world.dialogue.active, "Notebook blocks world interaction")
	world.notebook.close_book()
	check(world.player.movement_enabled, "Closing restores movement")
	for result in ["talk", "fight", "tried_then_fight"]:
		var flags := {"n1_result": result, "explore_dormitory_bed": "observe"}
		Journal.collect(flags, 0, world.story.dialogues)
		var item: Dictionary = flags._clue_journal.explore_dormitory_bed_observe
		check(Journal.method(result) in item.source, "Correct investigation provenance: " + result)
		check(not flags._clue_journal.has("heart_shi_an"), "No unearned testimony")
		check(not flags._clue_journal.has("pass"), "No prologue spoilers")
	var flags := {"hide_spot": true, "n3_result": "fight", "n4_result": "fight"}
	Journal.collect(flags, 0, world.story.dialogues, "cliff_search")
	var source: String = flags._clue_journal.hide_spot.source
	check("親自搜查" in source, "Search after violence remains a search source")
	flags.n3_result = "talk"
	Journal.collect(flags, 0, world.story.dialogues)
	check(flags._clue_journal.hide_spot.source == source, "First acquisition source is immutable")
	world.story_flags = {"n1_result": "fight", "explore_dormitory_bed": "observe", "ev_seal_sketch": true}
	world.story_stage = 2
	world._update_objective()
	world.notebook.open_book()
	await process_frame
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://tests/clue_notebook_preview.png")
	world.notebook.close_book()
	# Cancelled transaction must not leak discoveries or alter an existing journal.
	var before: Dictionary = world.story_flags.duplicate(true)
	world.story.dialogues.cancel_test = [{"speaker":"旁白", "text":"暫存線索", "action":{"type":"set", "effects":{"chen_bai_nails":true}}}, {"speaker":"旁白", "text":"尚未完成"}]
	world.director.run_event({"id":"cancel_test", "dialogue":"cancel_test"})
	if world.dialogue.active: world.dialogue.cancel()
	check(world.story_flags == before, "Cancelled event restores clues and provenance")
	print("CLUE_JOURNAL_TEST: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)

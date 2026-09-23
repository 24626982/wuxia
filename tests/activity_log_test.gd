extends SceneTree

var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var log = root.get_node("ActivityLog")
	log.start_session()
	log.record_interaction("柳青霄 · 掌門")
	log.record_interaction("床邊藥包")
	var lines: PackedStringArray = log.contents().strip_edges().split("\n")
	_check(lines.size() == 3, "Start plus two interactions are recorded")
	_check(_matches(lines[0], "^\\[\\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}\\] 開始遊戲$"), "Start entry has a minute timestamp")
	_check("與〖柳青霄 掌門〗互動" in lines[1], "NPC role separator is normalised")
	_check("與〖床邊藥包〗互動" in lines[2], "Investigation objects are recorded")
	var world = load("res://scenes/courtyard.tscn").instantiate()
	root.add_child(world)
	await process_frame
	_check(world.notebook.log_button.text == "記錄" and world.notebook.log_button.position.x < world.notebook.button.position.x, "Record button appears left of the clue button")
	_check(world.notebook.save_dialog != null and world.notebook.save_dialog.file_mode == FileDialog.FILE_MODE_SAVE_FILE and world.notebook.save_dialog.access == FileDialog.ACCESS_FILESYSTEM, "Desktop record button uses a filesystem save dialog")
	log.start_session()
	world.player.position = world.get_node("Actors/Master").position
	world.interact_with_nearest()
	_check("與〖柳青霄 掌門〗互動" in log.contents(), "World interaction records the displayed NPC name")
	world.queue_free()
	await process_frame
	print("ACTIVITY_LOG_TEST: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)


func _matches(value: String, pattern: String) -> bool:
	var regex := RegEx.new()
	return regex.compile(pattern) == OK and regex.search(value) != null


func _check(condition: bool, description: String) -> void:
	print("PASS: " if condition else "FAIL: ", description)
	if not condition:
		failures += 1

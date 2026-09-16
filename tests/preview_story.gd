extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _capture(path: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)

func _run() -> void:
	var world = load("res://scenes/courtyard.tscn").instantiate()
	root.add_child(world)
	await _capture("res://tests/style_preview.png")
	world._open_dialogue("master_start")
	var dialogue = world.get_node("Dialogue")
	for step in range(16):
		if dialogue.waiting_for_choice:
			break
		dialogue.advance()
	await _capture("res://tests/choices_preview.png")
	quit()

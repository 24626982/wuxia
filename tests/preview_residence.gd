extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _capture(path: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)

func _run() -> void:
	var world = load("res://scenes/residence.tscn").instantiate()
	root.add_child(world)
	await _capture("res://tests/west_cast_preview.png")
	world.player.position = Vector2(220, 290)
	world.interact_with_nearest()
	for step in range(16):
		if world.dialogue.waiting_for_choice:
			break
		world.dialogue.advance()
	await _capture("res://tests/west_mystery_preview.png")
	quit()

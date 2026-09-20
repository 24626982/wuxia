extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var scene = load("res://scenes/character_creation.tscn").instantiate()
	root.add_child(scene)
	scene.name_input.text = "林青霜"
	for gender in ["male", "female"]:
		scene.select_gender(gender)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://tests/character_creation_" + gender + "_preview.png")
	for path in ["res://assets/characters/hero-female-portrait.png", "res://assets/characters/hero-female-directions.png"]:
		var image: Image = load(path).get_image()
		print(path, " size=", image.get_size(), " alpha=", image.detect_alpha(), " corner=", image.get_pixel(0, 0))
	quit()

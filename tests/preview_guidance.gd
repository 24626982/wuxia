extends SceneTree

func _initialize() -> void: run.call_deferred()

func capture(path: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)

func run() -> void:
	for map in ["courtyard", "residence", "dormitory", "town", "bamboo_station", "wind_cliff", "hall"]:
		var world = load("res://scenes/" + map + ".tscn").instantiate()
		root.add_child(world)
		await process_frame
		world.story_stage = 4
		if not map in ["courtyard", "residence"]: world.story_flags.residence_resolved = true
		if map in ["town", "bamboo_station", "wind_cliff", "hall"]:
			world.story_flags.merge({"n1_result": "talk", "explore_dormitory_bed": "observe"})
		if map in ["bamboo_station", "wind_cliff", "hall"]: world.story_flags.n2_result = "talk"
		if map in ["wind_cliff", "hall"]: world.story_flags.merge({"n3_result": "talk", "chen_bai_nails": true})
		if map == "hall": world.story_flags.n4_result = "talk"
		world.refresh_story_spots()
		world._update_objective()
		await capture("res://tests/" + map + "_guided_preview.png")
		if map == "dormitory":
			world._open_dialogue("dorm_chen_bai_first")
			world.dialogue.advance()
			world.dialogue.advance()
			await capture("res://tests/chen_bai_portrait_preview.png")
			world.dialogue.cancel()
		world.queue_free()
		await process_frame
	quit()

extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	root.get_node("WorldState").create_hero("青霜", "female")
	var player = load("res://scenes/player.tscn").instantiate()
	root.add_child(player)
	var failures := 0
	for direction in [Vector2.LEFT, Vector2.RIGHT]:
		player._set_facing(direction)
		var sprite: Sprite2D = player.sprite
		var cell_size := sprite.texture.get_size() / Vector2(sprite.hframes, sprite.vframes)
		var region := sprite.region_rect if sprite.region_enabled else Rect2(Vector2(sprite.frame % sprite.hframes, floori(sprite.frame / float(sprite.hframes))) * cell_size, cell_size)
		var image := sprite.texture.get_image().get_region(Rect2i(region))
		var groups := 0
		var previous_visible := false
		for y in range(image.get_height()):
			var visible_row := false
			for x in range(image.get_width()):
				if image.get_pixel(x, y).a >= 0.5:
					visible_row = true
					break
			if visible_row and not previous_visible: groups += 1
			previous_visible = visible_row
		print("Direction ", direction, ": separated visible row groups=", groups, " (expected 1)")
		if groups != 1: failures += 1
	player.queue_free()
	await process_frame
	if "--capture" in OS.get_cmdline_user_args():
		var world = load("res://scenes/courtyard.tscn").instantiate()
		root.add_child(world)
		world.player.position = Vector2(480, 320)
		world.player._set_facing(Vector2.LEFT)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://tests/female_left_preview.png")
		world.player._set_facing(Vector2.RIGHT)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://tests/female_right_preview.png")
		world.queue_free()
		await process_frame
	print("FEMALE_FRAME_BLEED_TEST: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)

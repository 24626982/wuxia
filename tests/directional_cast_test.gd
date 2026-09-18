extends SceneTree
const Art = preload("res://scripts/character_art.gd")
const Marker = preload("res://scripts/clue_spot.gd")
var failures := 0

func _initialize() -> void: run.call_deferred()

func check(ok: bool, message: String) -> void:
	print("PASS: " if ok else "FAIL: ", message)
	if not ok: failures += 1

func run() -> void:
	for id in Art.DIRECTION_FILES:
		var actor := Marker.new()
		root.add_child(actor)
		actor.setup_character(id)
		check(actor.frames.size() == 4, "Four unique atlas views for " + id)
		if actor.frames.size() == 4:
			var regions := []
			var source: Texture2D = actor.frames[0].atlas
			check(source.get_image().detect_alpha() != Image.ALPHA_NONE, "Preserved transparent alpha: " + id)
			for index in range(4):
				actor.face_towards(actor.global_position + [Vector2.DOWN, Vector2.UP, Vector2.LEFT, Vector2.RIGHT][index] * 40)
				check(actor.facing == index and actor.character.texture == actor.frames[index], id + " faces direction " + str(index))
				var region: Rect2 = actor.frames[index].region
				check(region.has_area(), id + " nonempty view " + str(index))
				check(not region in regions, id + " distinct view " + str(index))
				regions.append(region)
				check(absf(actor.character.offset.y + actor.character.texture.get_height()) < 0.01, "Sprite feet remain anchored")
		actor.queue_free()
	await process_frame
	print("DIRECTIONAL_CAST_TEST: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)

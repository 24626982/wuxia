extends SceneTree
## Reachability uses the same collision world as the player, with a feet margin.
var failures := 0
const CELL := 10

func _initialize() -> void: run.call_deferred()

func run() -> void:
	for map in ["residence", "hall", "town", "dormitory", "bamboo_station", "wind_cliff"]:
		var world = load("res://scenes/" + map + ".tscn").instantiate()
		root.add_child(world)
		await physics_frame
		var grid := AStarGrid2D.new()
		grid.region = Rect2i(0, 0, 96, 54)
		grid.cell_size = Vector2(CELL, CELL)
		grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
		grid.update()
		var feet := CircleShape2D.new()
		feet.radius = 7.0
		var query := PhysicsShapeQueryParameters2D.new()
		query.shape = feet
		query.exclude = [world.player.get_rid()]
		query.collision_mask = 1
		for y in range(54):
			for x in range(96):
				query.transform.origin = Vector2(x, y) * CELL
				if not world.get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty(): grid.set_point_solid(Vector2i(x, y))
		var start := Vector2i((world.player.position / CELL).round())
		for spot in world.get_node("Actors").get_children():
			if not spot.is_in_group("clue_spots") and not (map == "residence" and spot.get("npc_id") != null): continue
			var reachable := false
			for offset in [Vector2(0, 30), Vector2(30, 0), Vector2(-30, 0), Vector2(0, -30), Vector2(0, 45)]:
				var end := Vector2i(((spot.position + offset) / CELL).round())
				if grid.is_in_boundsv(end) and not grid.is_point_solid(end) and not grid.get_id_path(start, end).is_empty():
					reachable = true
					break
			if not reachable:
				push_error("Cannot walk from entrance to " + map + "/" + String(spot.npc_id))
				failures += 1
		world.queue_free()
		await process_frame
	print("MAP_ACCESS_TEST: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)

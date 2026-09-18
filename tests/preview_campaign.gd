extends SceneTree

func _initialize() -> void: run.call_deferred()

func capture(path: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)

func run() -> void:
	var world = load("res://scenes/wind_cliff.tscn").instantiate()
	root.add_child(world)
	await capture("res://tests/campaign_map_preview.png")
	world.story_flags = {"heart_shi_an": true, "heart_shen_he": true, "heart_brother": true, "heart_xiaoman": true}
	world.director.menu({"speaker": "少俠", "text": "（要怎麼回應？耐心：3）"}, world.director.logic.nodes.n5.talk.heart_stage.choices)
	await capture("res://tests/campaign_choices_preview.png")
	world.dialogue.cancel()
	quit()

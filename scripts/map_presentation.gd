extends RefCounted
## Positions follow painted objects; approach points remain on walkable floor.
const POSITIONS := {
	"residence": {"explore_residence_rice": Vector2(615, 335)},
	"hall": {"explore_hall_ledger": Vector2(350, 380), "npc_elder_yan": Vector2(575, 310)},
	"dormitory": {"chen_bai": Vector2(340, 235), "shi_an": Vector2(590, 300), "explore_dormitory_bed": Vector2(210, 280), "explore_dormitory_pouch": Vector2(820, 290)},
	"town": {"brother": Vector2(405, 340), "npc_town_vendor": Vector2(690, 425), "npc_town_tea": Vector2(545, 330), "npc_town_tea_b": Vector2(605, 395)},
	"bamboo_station": {"explore_bamboo_station_record": Vector2(245, 228), "explore_bamboo_station_signal": Vector2(742, 225), "explore_station_backdoor": Vector2(815, 250), "npc_station_keeper": Vector2(328, 250), "npc_station_keeper_closed": Vector2(328, 250), "third_lamp_at_night": Vector2(700, 270), "xiaoman": Vector2(620, 295)},
	"wind_cliff": {"explore_wind_cliff_record": Vector2(320, 238), "explore_wind_cliff_signal": Vector2(760, 255), "npc_herb_elder": Vector2(260, 345), "explore_cliff_rock": Vector2(650, 295), "enter_at_night": Vector2(550, 355), "interact_tubes": Vector2(365, 207), "yan_cheng": Vector2(500, 250)}
}
const NAMES := {"explore_bamboo_station_record": "桌上的舊印模", "explore_bamboo_station_signal": "第三盞燈的繩結", "third_lamp_at_night": "燈下等候", "enter_at_night": "練劍空地", "interact_tubes": "裂開的竹管", "explore_wind_cliff_record": "竹管傳聲痕跡", "explore_wind_cliff_signal": "避風處的足跡", "explore_dormitory_bed": "小滿的床位", "explore_dormitory_pouch": "床邊藥袋"}

static func configure(world: Node) -> void:
	for actor in world.get_node("Actors").get_children():
		if not actor.is_in_group("clue_spots"): continue
		var id := String(actor.npc_id)
		if POSITIONS.get(world.map_id, {}).has(id): actor.position = POSITIONS[world.map_id][id]
		if NAMES.has(id): actor.display_name = NAMES[id]
		for child in actor.get_children():
			if child is Label:
				child.text = actor.display_name
				var raised_label: bool = actor.get_meta("person", false) or actor.get_meta("large_prop", false)
				child.position = Vector2(-85, -72 if raised_label else -28)
				child.size = Vector2(170, 22)
				child.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				child.add_theme_font_size_override("font_size", 13)
	# Keep the original scene exit signs at their authored positions.

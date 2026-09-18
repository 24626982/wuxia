extends Node2D
## Shared visual language for people, clues and night events.
var world: Node
const GOLD := Color("f5d47d")
const JADE := Color("9de2cd")
const INK := Color("132720")

func _ready() -> void:
	z_index = 15

func _process(_delta: float) -> void:
	visible = not world.dialogue.active
	queue_redraw()

func _draw() -> void:
	if world.guide_task.is_empty(): return
	var font: Font = world.objective.get_theme_font("font")
	for actor in world.get_node("Actors").get_children():
		if not (actor.is_in_group("clue_spots") or actor.is_in_group("story_npcs")) or not actor.visible: continue
		var id := String(actor.npc_id)
		var selected: bool = world.nearest_npc == actor
		var target: bool = world.guide_task.target == id and world.guide_task.map == world.map_id
		var color := GOLD if target else JADE
		var locked: bool = actor.get_meta("locked", false)
		if locked: color = Color("b6b3a3")
		var person: bool = actor.is_in_group("story_npcs") or actor.get_meta("person", false)
		var center: Vector2 = actor.position + Vector2(0, -82 if person else -43)
		if selected:
			draw_arc(actor.position, 21, 0, TAU, 32, GOLD, 2.0, true)
			draw_circle(center, 13, GOLD)
			draw_string(font, center + Vector2(-5, 6), "E", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, INK)
		else:
			draw_circle(center, 10, INK)
			draw_arc(center, 10, 0, TAU, 24, color, 1.4, true)
			if locked:
				draw_rect(Rect2(center + Vector2(-4, -1), Vector2(8, 7)), color)
				draw_arc(center + Vector2(0, -1), 3, PI, TAU, 12, color, 1.5, true)
			elif target:
				draw_string(font, center + Vector2(-3, 5), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, GOLD)
			elif id.begins_with("explore_") or id == "interact_tubes":
				draw_arc(center + Vector2(-1, -1), 4, 0, TAU, 16, color, 1.5, true)
				draw_line(center + Vector2(2, 2), center + Vector2(6, 6), color, 2, true)
			elif id in ["third_lamp_at_night", "enter_at_night"]:
				draw_circle(center, 5, color)
				draw_circle(center + Vector2(3, -2), 4.5, INK)
			else:
				draw_style_box(_bubble(color), Rect2(center - Vector2(6, 4), Vector2(12, 8)))
		if world.story_flags.has(id) and id.begins_with("explore_") and not selected:
			draw_string(font, center + Vector2(14, 5), "已查看", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, JADE)

func _bubble(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(2)
	return style

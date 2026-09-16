extends StaticBody2D

@export var npc_id: StringName
@export var display_name: String = "NPC"
@export var character_texture: Texture2D
@export var display_height: float = 48.0
@export var artwork_bounds: Rect2
@export var directional_texture: Texture2D
@export var frame_bounds: Array[Rect2] = []
var facing: int = 0

@onready var sprite: Sprite2D = $Sprite2D
@onready var name_label: Label = $Name


func _ready() -> void:
	sprite.texture = character_texture
	# Normalise untouched local PNGs by their alpha bounds. No remote requests,
	# raster rewriting, or dependence on UID identifiers is involved.
	var bounds: Rect2 = artwork_bounds
	if not bounds.has_area():
		bounds = character_texture.get_image().get_used_rect()
	if bounds.size.y > 0:
		sprite.scale = Vector2.ONE * display_height / float(bounds.size.y)
		sprite.offset = -Vector2(bounds.position.x + bounds.size.x * 0.5, bounds.end.y)
	name_label.position.y = -display_height - 24.0
	name_label.text = display_name
	if directional_texture != null:
		face_towards(global_position + Vector2.DOWN)

func face_towards(target: Vector2) -> void:
	var direction := target - global_position
	facing = (2 if direction.x < 0 else 3) if absf(direction.x) > absf(direction.y) else (1 if direction.y < 0 else 0)
	if directional_texture == null:
		return
	var size := directional_texture.get_size() / 2.0
	var cell := Rect2(Vector2(facing % 2, floori(facing / 2.0)) * size, size)
	var atlas := AtlasTexture.new()
	atlas.atlas = directional_texture
	atlas.region = cell
	sprite.texture = atlas
	var bounds: Rect2 = frame_bounds[facing] if frame_bounds.size() == 4 else Rect2(directional_texture.get_image().get_region(Rect2i(cell)).get_used_rect())
	if bounds.has_area():
		sprite.scale = Vector2.ONE * display_height / bounds.size.y
		sprite.offset = -Vector2(bounds.position.x + bounds.size.x * 0.5, bounds.end.y)

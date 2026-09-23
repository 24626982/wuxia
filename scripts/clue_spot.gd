extends Marker2D
## Local, native scene interaction marker; deliberately not an NPC.
@export var npc_id: StringName
@export var display_name: String
var facing := 0
var frames: Array[Texture2D] = []
var character: Sprite2D
const Art = preload("res://scripts/character_art.gd")
const PROP_TEXTURES := {
	"explore_residence_rice": preload("res://assets/environment/rice-tub.png"),
}
const PROP_BOUNDS := {
	"explore_residence_rice": Rect2(45, 20, 125, 145),
}

func setup_character(id: String) -> void:
	if PROP_TEXTURES.has(id):
		_setup_prop(id)
		return
	var portrait := Art.texture(id)
	if portrait == null: return
	set_meta("person", true)
	frames = Art.directions(id)
	character = Sprite2D.new()
	character.name = "Character"
	character.centered = false
	character.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(character)
	_set_texture(frames[0] if frames.size() == 4 else portrait)

func _setup_prop(id: String) -> void:
	var texture: Texture2D = PROP_TEXTURES[id]
	var bounds: Rect2 = PROP_BOUNDS[id]
	character = Sprite2D.new()
	character.name = "Prop"
	character.centered = false
	character.texture = texture
	character.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	character.scale = Vector2.ONE * 56.0 / bounds.size.y
	character.offset = -Vector2(bounds.get_center().x, bounds.end.y)
	set_meta("large_prop", true)
	add_child(character)

func face_towards(target: Vector2) -> void:
	if frames.size() != 4: return
	var direction := target - global_position
	facing = (2 if direction.x < 0 else 3) if absf(direction.x) > absf(direction.y) else (1 if direction.y < 0 else 0)
	_set_texture(frames[facing])

func _set_texture(texture: Texture2D) -> void:
	character.texture = texture
	character.scale = Vector2.ONE * 58.0 / texture.get_height()
	character.offset = -Vector2(texture.get_width() * 0.5, texture.get_height())

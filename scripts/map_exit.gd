extends Area2D
@export_file("*.tscn") var destination: String
@export var arrival: Vector2

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	var world := get_parent()
	if body == world.player:
		WorldState.travel(world, destination, arrival)

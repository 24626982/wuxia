extends CharacterBody2D
## Reusable four-direction player. The collision origin is at the character's feet.

@export_group("Movement")
@export var move_speed: float = 135.0

@onready var sprite: Sprite2D = $Sprite2D

var step_time: float = 0.0
var spawn_position: Vector2
var movement_enabled: bool = true


func _ready() -> void:
	spawn_position = position
	_set_facing(Vector2.DOWN)


func _physics_process(delta: float) -> void:
	if not movement_enabled:
		velocity = Vector2.ZERO
		sprite.position.y = 0.0
		return
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * move_speed
	move_and_slide()
	if not direction.is_zero_approx():
		_set_facing(direction)
		step_time += delta * 12.0
		sprite.position.y = -1.0 if sin(step_time) > 0.0 else 0.0
	else:
		step_time = 0.0
		sprite.position.y = 0.0


func _unhandled_input(event: InputEvent) -> void:
	# Handle reset as an event so pressing R during dialogue cannot linger
	# until the first unlocked physics tick and unexpectedly teleport the player.
	if event.is_action_pressed("reset_player") and not event.is_echo():
		if movement_enabled:
			reset_position()
		get_viewport().set_input_as_handled()


func _set_facing(direction: Vector2) -> void:
	if absf(direction.x) > absf(direction.y):
		sprite.frame = 2 if direction.x < 0.0 else 3
		sprite.offset = Vector2(0, -247)
	else:
		sprite.frame = 1 if direction.y < 0.0 else 0
		sprite.offset = Vector2(0, -274)


func reset_position() -> void:
	position = spawn_position
	velocity = Vector2.ZERO
	_set_facing(Vector2.DOWN)

## The hero: 4-direction walking with acceleration, run on Shift/X.
class_name Player
extends CharacterBody2D

const SPEED := 70.0
const RUN_SPEED := 115.0
const ACCEL := 700.0
const DECEL := 900.0

var facing := "down"
var input_locked := false

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var camera: Camera2D = $Camera


func _physics_process(delta: float) -> void:
	var input := Vector2.ZERO if input_locked else Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var speed := RUN_SPEED if Input.is_action_pressed("run") else SPEED
	if input != Vector2.ZERO:
		velocity = velocity.move_toward(input * speed, ACCEL * delta)
		facing = _facing_for(input)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, DECEL * delta)
	move_and_slide()
	var anim := ("walk_" if input != Vector2.ZERO else "idle_") + facing
	if sprite.animation != anim:
		sprite.play(anim)
	sprite.speed_scale = 1.4 if (input != Vector2.ZERO and speed == RUN_SPEED) else 1.0


func _facing_for(v: Vector2) -> String:
	# keep the current facing on exact diagonals so the sprite doesn't flicker
	if absf(v.x) > absf(v.y) + 0.01:
		return "right" if v.x > 0 else "left"
	if absf(v.y) > absf(v.x) + 0.01:
		return "down" if v.y > 0 else "up"
	return facing


func set_camera_limits(map_size_px: Vector2) -> void:
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(map_size_px.x)
	camera.limit_bottom = int(map_size_px.y)


func front_position(distance: float = 12.0) -> Vector2:
	var dir := {"down": Vector2.DOWN, "up": Vector2.UP, "left": Vector2.LEFT, "right": Vector2.RIGHT}[facing] as Vector2
	return global_position + Vector2(0, -6) + dir * distance

## The hero: 4-direction walking with acceleration, run on Shift/X, interact in front.
class_name Player
extends CharacterBody2D

const SPEED := 70.0
const RUN_SPEED := 115.0
const ACCEL := 700.0
const DECEL := 900.0
const DIRS := {"down": Vector2.DOWN, "up": Vector2.UP, "left": Vector2.LEFT, "right": Vector2.RIGHT}

var facing := "down"
var frozen := false   # set by World while traveling

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var camera: Camera2D = $Camera
@onready var interact_area: Area2D = $InteractArea
@onready var hint: Sprite2D = $Hint

var lantern: PointLight2D
var _shake_tween: Tween


func _ready() -> void:
	lantern = Lights.make(Color(1.0, 0.9, 0.7), 70.0, 1.2, true)
	lantern.position = Vector2(0, -8)
	lantern.enabled = false
	add_child(lantern)


func shake(intensity := 2.0, time := 0.25) -> void:
	if _shake_tween:
		_shake_tween.kill()
	_shake_tween = create_tween()
	var steps := 5
	for i in steps:
		var k := 1.0 - float(i) / steps
		_shake_tween.tween_property(camera, "offset", Vector2(randf_range(-1, 1), randf_range(-1, 1)) * intensity * k, time / steps)
	_shake_tween.tween_property(camera, "offset", Vector2.ZERO, time / steps)


func _physics_process(delta: float) -> void:
	var locked := Dialogue.active or frozen
	var input := Vector2.ZERO if locked else Input.get_vector("move_left", "move_right", "move_up", "move_down")
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

	interact_area.position = Vector2(0, -6) + (DIRS[facing] as Vector2) * 10
	var target := _nearest_interactable()
	hint.visible = target != null and not locked
	if target and not locked and Input.is_action_just_pressed("interact"):
		velocity = Vector2.ZERO
		target.interact(self)


func _nearest_interactable() -> Interactable:
	var best: Interactable = null
	var best_d := INF
	for a in interact_area.get_overlapping_areas():
		if a is Interactable:
			var d := global_position.distance_squared_to(a.global_position)
			if d < best_d:
				best_d = d
				best = a
	return best


func _facing_for(v: Vector2) -> String:
	# keep the current facing on exact diagonals so the sprite doesn't flicker
	if absf(v.x) > absf(v.y) + 0.01:
		return "right" if v.x > 0 else "left"
	if absf(v.y) > absf(v.x) + 0.01:
		return "down" if v.y > 0 else "up"
	return facing


func face(dir: Vector2) -> void:
	for name in DIRS:
		if DIRS[name] == dir:
			facing = name
	sprite.play("idle_" + facing)


func set_camera_limits(map_size_px: Vector2) -> void:
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(map_size_px.x)
	camera.limit_bottom = int(map_size_px.y)

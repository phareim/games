## A door/edge: walking into it asks World to travel to `to_map` and arrive at door `to_door`.
## Also the arrival point: the player is placed `exit_dir` from its centre.
class_name Teleporter
extends Area2D

@export var id := ""
@export var to_map := ""
@export var to_door := ""
@export var exit_dir := Vector2.DOWN
@export var cells := Vector2i(1, 1)   # size in tiles; position is the top-left corner


func _init() -> void:
	collision_layer = 0
	collision_mask = 2   # player
	monitorable = false


func _ready() -> void:
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(cells) * MapBuilder.TILE - Vector2(2, 2)
	shape.shape = rect
	shape.position = Vector2(cells) * MapBuilder.TILE / 2.0
	add_child(shape)
	body_entered.connect(_on_body_entered)


func centre() -> Vector2:
	return global_position + Vector2(cells) * MapBuilder.TILE / 2.0


func arrival_position() -> Vector2:
	# feet point just outside the area, on the exit side
	var half := Vector2(cells) * MapBuilder.TILE / 2.0
	var out := exit_dir * (Vector2(absf(exit_dir.x) * half.x, absf(exit_dir.y) * half.y) + Vector2(10, 10))
	return centre() + out + Vector2(0, 6)


func _on_body_entered(body: Node2D) -> void:
	if body is Player and to_map != "":
		var world := get_tree().current_scene
		if world.has_method("travel"):
			world.travel(to_map, to_door)

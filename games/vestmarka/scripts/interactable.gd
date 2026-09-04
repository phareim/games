## Base for things the player can press `interact` on. Area2D on collision layer 4;
## the player's InteractArea (mask 4) finds them. Subclasses build their own children.
class_name Interactable
extends Area2D

@export var pages: Array[String] = []   # default dialog pages ("|" splits in map files)

var solid_rect := Rect2(-7, -8, 14, 10)  # StaticBody2D collider relative to the base point; null size = walk-through


func _init() -> void:
	collision_layer = 4
	collision_mask = 0
	monitoring = false


func _ready() -> void:
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(16, 16)
	shape.shape = rect
	shape.position = Vector2(0, -8)
	add_child(shape)
	if solid_rect.size != Vector2.ZERO:
		var body := StaticBody2D.new()
		body.collision_layer = 1
		body.collision_mask = 0
		var bshape := CollisionShape2D.new()
		var brect := RectangleShape2D.new()
		brect.size = solid_rect.size
		bshape.shape = brect
		bshape.position = solid_rect.position + solid_rect.size / 2.0
		body.add_child(bshape)
		add_child(body)


## Override. Called with the player when `interact` is pressed while in range.
func interact(_player: Player) -> void:
	if not pages.is_empty():
		await Dialogue.say(pages)

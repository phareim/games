## A wooden sign: reads its pages.
class_name Sign
extends Interactable

const TEX := preload("res://assets/tiles/house.png")


func _ready() -> void:
	solid_rect = Rect2(-6, -6, 12, 6)
	super()
	var sprite := Sprite2D.new()
	sprite.texture = TEX
	sprite.region_enabled = true
	sprite.region_rect = Rect2i(112, 48, 16, 16)
	sprite.offset = Vector2(0, -8)
	add_child(sprite)

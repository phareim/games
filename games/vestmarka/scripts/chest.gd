## A treasure chest. Opening sets flag `id` (a "funn"); stays open across sessions.
class_name Chest
extends Interactable

const SMALL := preload("res://assets/ui/chest_small.png")
const BIG := preload("res://assets/ui/chest_big.png")

@export var id := ""
@export var big := false

var sprite: Sprite2D


func _ready() -> void:
	solid_rect = Rect2(-7, -7, 14, 7)
	super()
	sprite = Sprite2D.new()
	sprite.texture = BIG if big else SMALL
	sprite.hframes = 2
	sprite.offset = Vector2(0, -8 if big else -8)
	sprite.frame = 1 if GameState.has_flag(id) else 0
	add_child(sprite)


func interact(_player: Player) -> void:
	if GameState.has_flag(id):
		await Dialogue.say(["Kisten er tom."])
		return
	sprite.frame = 1
	Sfx.play("chest")
	GameState.set_flag(id)
	await Dialogue.say(pages if not pages.is_empty() else ["Du fant noe."])

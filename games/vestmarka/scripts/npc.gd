## A villager: 16x16 sheet (columns = down/up/left/right, rows = frames), faces the player
## when spoken to. `pages_done` is used instead of `pages` once `done_flag` is set;
## `sets_flag` is set after the first conversation.
class_name Npc
extends Interactable

const DIR_COL := {Vector2.DOWN: 0, Vector2.UP: 1, Vector2.LEFT: 2, Vector2.RIGHT: 3}

@export var who := "OldMan"          # folder under assets/npc/
@export var speaker := ""
@export var sets_flag := ""
@export var done_flag := ""
@export var pages_done: Array[String] = []
@export var facing := Vector2.DOWN

var sprite: Sprite2D
var face_tex: Texture2D


func _ready() -> void:
	solid_rect = Rect2(-6, -8, 12, 8)
	super()
	sprite = Sprite2D.new()
	sprite.texture = load("res://assets/npc/%s/sheet.png" % who)
	sprite.hframes = 4
	sprite.vframes = 7
	sprite.offset = Vector2(0, -8)
	add_child(sprite)
	face_tex = load("res://assets/npc/%s/face.png" % who)
	_set_facing(facing)


func _set_facing(dir: Vector2) -> void:
	var col: int = DIR_COL.get(dir, 0)
	sprite.frame = col   # row 0, standing


func interact(player: Player) -> void:
	var to_player := player.global_position - global_position
	var dir := Vector2.DOWN
	if absf(to_player.x) > absf(to_player.y):
		dir = Vector2.RIGHT if to_player.x > 0 else Vector2.LEFT
	else:
		dir = Vector2.DOWN if to_player.y > 0 else Vector2.UP
	_set_facing(dir)
	var lines := pages
	if done_flag != "" and GameState.has_flag(done_flag) and not pages_done.is_empty():
		lines = pages_done
	await Dialogue.say(lines, speaker, face_tex)
	if sets_flag != "":
		GameState.set_flag(sets_flag)
	_set_facing(facing)

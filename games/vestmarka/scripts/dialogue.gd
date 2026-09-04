## Autoload: the dialog box. `await Dialogue.say(["side 1", "side 2"], "Navn", face_texture)`.
## Typewriter text; interact advances (finishes the page first if still typing).
extends CanvasLayer

signal finished
signal _advance

const CHARS_PER_SEC := 45.0
const TEXT_COLOR := Color("3a2a24")

var active := false
var _typing := false

var box: TextureRect
var box_plain: Texture2D = preload("res://assets/ui/dialog_box.png")
var box_face: Texture2D = preload("res://assets/ui/dialog_box_faceset.png")
var face: TextureRect
var name_label: Label
var text: RichTextLabel
var arrow: TextureRect
var font: FontVariation   # the pack's pixel font at its native 9px grid, 2px extra per space


func _ready() -> void:
	layer = 10
	var base: FontFile = load("res://assets/ui/normal_font.ttf")
	base.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	base.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	base.hinting = TextServer.HINTING_NONE
	# Native pixel grid is 2048/9 units: size 9 makes every advance a whole pixel; the
	# space is only 1px wide by design, so add 2.
	font = FontVariation.new()
	font.base_font = base
	font.spacing_space = 2

	box = TextureRect.new()
	box.texture = box_plain
	box.position = Vector2(10, 118)
	box.size = Vector2(300, 58)
	box.visible = false
	add_child(box)

	face = TextureRect.new()
	face.position = Vector2(6, 13)
	face.size = Vector2(38, 38)
	box.add_child(face)

	name_label = Label.new()
	name_label.position = Vector2(8, -1)
	name_label.size = Vector2(62, 12)
	name_label.add_theme_font_override("font", font)
	name_label.add_theme_font_size_override("font_size", 9)
	name_label.add_theme_color_override("font_color", Color("f3e6dc"))
	box.add_child(name_label)

	text = RichTextLabel.new()
	text.bbcode_enabled = false
	text.scroll_active = false
	text.position = Vector2(14, 13)
	text.size = Vector2(276, 42)
	text.add_theme_font_override("normal_font", font)
	text.add_theme_font_size_override("normal_font_size", 9)
	text.add_theme_color_override("default_color", TEXT_COLOR)
	text.add_theme_constant_override("line_separation", 1)
	box.add_child(text)

	arrow = TextureRect.new()
	arrow.texture = preload("res://assets/ui/arrow.png")
	arrow.position = Vector2(282, 42)
	arrow.rotation_degrees = 90
	arrow.pivot_offset = Vector2(6.5, 6.5)
	arrow.visible = false
	box.add_child(arrow)


func say(pages: Array, speaker := "", face_tex: Texture2D = null) -> void:
	active = true
	box.texture = box_face if face_tex else box_plain
	face.visible = face_tex != null
	face.texture = face_tex
	text.position.x = 52 if face_tex else 14
	text.size.x = 240 if face_tex else 276
	name_label.text = speaker
	box.visible = true
	for page in pages:
		text.text = page
		text.visible_characters = 0
		_typing = true
		arrow.visible = false
		var total := text.get_total_character_count()
		var shown := 0.0
		while _typing and shown < total:
			shown += CHARS_PER_SEC * get_process_delta_time()
			text.visible_characters = int(shown)
			await get_tree().process_frame
		text.visible_characters = -1
		_typing = false
		arrow.visible = true
		await _advance
	box.visible = false
	active = false
	finished.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		if _typing:
			_typing = false
		else:
			Sfx.play("accept", -12.0)
			_advance.emit()


func _process(_delta: float) -> void:
	if arrow.visible:
		arrow.position.y = 42 + (1 if fmod(Time.get_ticks_msec() / 400.0, 2.0) < 1.0 else 0)

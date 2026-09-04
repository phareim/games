## Top-left counter: "Funn n/m" for the current map.
extends CanvasLayer

var label: Label
var find_ids: Array = []


func _ready() -> void:
	layer = 5
	var panel := NinePatchRect.new()
	panel.texture = preload("res://assets/ui/panel.png")
	panel.patch_margin_left = 5
	panel.patch_margin_top = 5
	panel.patch_margin_right = 5
	panel.patch_margin_bottom = 5
	panel.position = Vector2(4, 4)
	panel.size = Vector2(58, 15)
	add_child(panel)
	label = Label.new()
	label.position = Vector2(5, 2)
	label.size = Vector2(50, 12)
	label.add_theme_font_override("font", Dialogue.font)
	label.add_theme_font_size_override("font_size", 9)
	label.add_theme_color_override("font_color", Color("f3e6dc"))
	panel.add_child(label)
	GameState.changed.connect(refresh)
	refresh()


func set_finds(ids: Array) -> void:
	find_ids = ids
	refresh()


func refresh() -> void:
	label.text = "Funn %d/%d" % [GameState.count_flags(find_ids), find_ids.size()]

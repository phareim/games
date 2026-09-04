## Full-screen fade used when changing maps.
class_name Transition
extends CanvasLayer

var rect: ColorRect
var tween: Tween


func _ready() -> void:
	layer = 20
	rect = ColorRect.new()
	rect.color = Color.BLACK
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.modulate.a = 0.0
	add_child(rect)


func fade_to(alpha: float, time := 0.35) -> void:
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(rect, "modulate:a", alpha, time)
	await tween.finished

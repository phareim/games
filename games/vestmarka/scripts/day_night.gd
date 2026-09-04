## CanvasModulate that runs a day/night cycle, or holds a fixed tint (caves).
## Only the world canvas is tinted; HUD and dialog live on CanvasLayers and stay bright.
class_name DayNight
extends CanvasModulate

const CYCLE_SECONDS := 360.0     # a full day
const DARK := Color(0.30, 0.32, 0.48)

var mode := "cycle"              # cycle | dark | none
var t := 0.35                    # 0..1, 0 = dawn; start mid-morning
var gradient: Gradient


func _ready() -> void:
	gradient = Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.12, 0.55, 0.68, 0.78, 0.93, 1.0])
	gradient.colors = PackedColorArray([
		Color(0.95, 0.80, 0.72),   # dawn
		Color(1, 1, 1),            # day
		Color(1, 1, 1),
		Color(1.0, 0.78, 0.60),    # dusk
		Color(0.42, 0.46, 0.78),   # night
		Color(0.42, 0.46, 0.78),
		Color(0.95, 0.80, 0.72),
	])
	_apply()


func is_night() -> bool:
	return mode == "dark" or (mode == "cycle" and (t > 0.74 or t < 0.04))


func set_mode(m: String) -> void:
	mode = m
	_apply()


func _process(delta: float) -> void:
	if mode == "cycle":
		t = fmod(t + delta / CYCLE_SECONDS, 1.0)
		_apply()


func _apply() -> void:
	match mode:
		"dark":
			color = DARK
		"none":
			color = Color.WHITE
		_:
			color = gradient.sample(t)

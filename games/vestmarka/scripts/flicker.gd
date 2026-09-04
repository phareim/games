## Torch flicker: small random energy wobble.
extends PointLight2D

var _base := 1.0
var _t := 0.0


func _ready() -> void:
	_base = energy
	_t = randf() * 10.0


func _process(delta: float) -> void:
	_t += delta
	energy = _base * (0.88 + 0.12 * sin(_t * 9.0) * sin(_t * 3.7 + 1.0) + 0.05 * sin(_t * 23.0))

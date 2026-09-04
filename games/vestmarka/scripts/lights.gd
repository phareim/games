## PointLight2D factory with a generated radial texture (no asset needed).
class_name Lights

static var _texture: GradientTexture2D


static func texture() -> GradientTexture2D:
	if _texture == null:
		var g := Gradient.new()
		g.offsets = PackedFloat32Array([0.0, 0.35, 1.0])
		g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.55), Color(1, 1, 1, 0)])
		_texture = GradientTexture2D.new()
		_texture.gradient = g
		_texture.fill = GradientTexture2D.FILL_RADIAL
		_texture.fill_from = Vector2(0.5, 0.5)
		_texture.fill_to = Vector2(0.5, 0.0)
		_texture.width = 128
		_texture.height = 128
	return _texture


static func make(color: Color, radius: float, energy := 1.0, flicker := false) -> PointLight2D:
	var light := PointLight2D.new()
	light.texture = texture()
	light.texture_scale = radius / 64.0
	light.color = color
	light.energy = energy
	light.shadow_enabled = false
	if flicker:
		light.set_script(preload("res://scripts/flicker.gd"))
	return light

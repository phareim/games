## Screen-wide ambient motes that follow the camera: leaves, fireflies, cave dust.
## A small pool of Sprite2D moved by hand — CPUParticles2D per-instance colours render
## black in the Compatibility (WebGL 2) renderer on this build, modulate does not (2026-09-04).
class_name Ambience
extends Node2D

const VIEW := Vector2(340, 200)   # a bit larger than the 320x180 viewport

var kind := ""
var emitting := true
var motes: Array[Dictionary] = []

static var _dot: ImageTexture


static func dot() -> ImageTexture:
	if _dot == null:
		var img := Image.create(3, 3, false, Image.FORMAT_RGBA8)
		img.fill(Color(1, 1, 1, 0))
		for x in 3:
			for y in 3:
				var a := 1.0 if (x == 1 and y == 1) else (0.6 if (x == 1 or y == 1) else 0.0)
				img.set_pixel(x, y, Color(1, 1, 1, a))
		_dot = ImageTexture.create_from_image(img)
	return _dot


static func make(k: String) -> Ambience:
	var p := Ambience.new()
	p.kind = k
	p.z_index = 5
	p.top_level = true   # world coordinates, not the player's
	return p


func _ready() -> void:
	var count: int = {"leaves": 14, "fireflies": 16, "dust": 18}.get(kind, 12)
	for i in count:
		var s := Sprite2D.new()
		s.texture = dot()
		add_child(s)
		motes.append(_spawn(s, true))


func _spawn(s: Sprite2D, anywhere: bool) -> Dictionary:
	var cam := _camera_centre()
	var m := {"s": s, "t": 0.0, "phase": randf() * TAU}
	var rx := randf_range(-VIEW.x / 2, VIEW.x / 2)
	var ry := randf_range(-VIEW.y / 2, VIEW.y / 2)
	match kind:
		"leaves":
			m["life"] = randf_range(4.0, 7.0)
			m["v"] = Vector2(randf_range(6, 16), randf_range(10, 20))
			m["color"] = [Color(0.30, 0.55, 0.15), Color(0.85, 0.60, 0.15), Color(0.75, 0.35, 0.15)][randi() % 3]
			s.scale = Vector2.ONE * randf_range(1.5, 2.5)
			s.position = cam + Vector2(rx, ry if anywhere else -VIEW.y / 2)
		"fireflies":
			m["life"] = randf_range(3.0, 6.0)
			m["v"] = Vector2(randf_range(-6, 6), randf_range(-6, 6))
			m["color"] = Color(1.0, 0.95, 0.55)
			s.scale = Vector2.ONE
			s.position = cam + Vector2(rx, ry)
		_:
			m["life"] = randf_range(5.0, 9.0)
			m["v"] = Vector2(randf_range(-2, 2), randf_range(1, 4))
			m["color"] = Color(0.75, 0.70, 0.62)
			s.scale = Vector2.ONE
			s.position = cam + Vector2(rx, ry)
	s.modulate = m["color"]
	s.modulate.a = 0.0
	return m


func _camera_centre() -> Vector2:
	var cam := get_viewport().get_camera_2d()
	return cam.get_screen_center_position() if cam else global_position


func _process(delta: float) -> void:
	var cam := _camera_centre()
	for i in motes.size():
		var m := motes[i]
		var s: Sprite2D = m["s"]
		m["t"] += delta
		var k: float = m["t"] / m["life"]
		var v: Vector2 = m["v"]
		match kind:
			"leaves":
				s.position += (v + Vector2(sin(m["t"] * 2.0 + m["phase"]) * 8.0, 0)) * delta
				s.rotation += delta * 1.5
				s.modulate.a = sin(k * PI)
			"fireflies":
				s.position += (v + Vector2(sin(m["t"] * 1.3 + m["phase"]), cos(m["t"] * 1.1 + m["phase"])) * 5.0) * delta
				s.modulate.a = maxf(0.0, sin(m["t"] * 3.0 + m["phase"])) * sin(k * PI) * (1.0 if emitting else 0.0)
			_:
				s.position += (v + Vector2(sin(m["t"] * 0.8 + m["phase"]) * 2.0, 0)) * delta
				s.modulate.a = 0.7 * sin(k * PI)
		var off := s.position - cam
		if k >= 1.0 or absf(off.x) > VIEW.x / 2 + 8 or absf(off.y) > VIEW.y / 2 + 8:
			motes[i] = _spawn(s, kind != "leaves")

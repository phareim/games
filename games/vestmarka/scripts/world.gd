## Root scene: owns the map, the player, the HUD and the fade; handles travel between maps.
extends Node2D

const HUD := preload("res://scripts/hud.gd")

@onready var map: MapBuilder = $Map
@onready var player: Player = $Player

var hud: CanvasLayer
var transition: Transition
var day_night: DayNight
var ambience: Ambience
var glow_layer: CanvasLayer
var traveling := false


func _ready() -> void:
	y_sort_enabled = true
	hud = HUD.new()
	add_child(hud)
	transition = Transition.new()
	add_child(transition)
	day_night = DayNight.new()
	add_child(day_night)
	glow_layer = CanvasLayer.new()
	glow_layer.layer = 1
	glow_layer.follow_viewport_enabled = true
	add_child(glow_layer)
	GameState.changed.connect(_check_all_found)
	_apply_url_params()
	_enter_map(map.spawn)


## Dev conveniences on the web build: ?map=grotte starts there, ?reset=1 clears the save.
func _apply_url_params() -> void:
	if not OS.has_feature("web"):
		return
	var q: String = str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('map')||''"))
	if JavaScriptBridge.eval("new URLSearchParams(location.search).has('reset')"):
		GameState.reset()
	if q != "" and FileAccess.file_exists("res://maps/%s.txt" % q):
		map.map_file = "res://maps/%s.txt" % q
	var tm: String = str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('time')||''"))
	if tm != "":
		day_night.t = clampf(float(tm), 0.0, 0.999)


func _enter_map(feet: Vector2) -> void:
	player.global_position = feet
	player.velocity = Vector2.ZERO
	player.set_camera_limits(map.pixel_size())
	player.camera.reset_smoothing()
	hud.set_finds(map.find_ids)
	GameState.current_map = map.map_name()
	Music.play(map.settings.get("music", ""))
	Music.ambient(map.settings.get("ambient", ""))
	day_night.set_mode(map.settings.get("light", "cycle"))
	player.lantern.enabled = day_night.mode == "dark"
	if ambience:
		ambience.queue_free()
		ambience = null
	var fx: String = map.settings.get("fx", "")
	if fx != "":
		ambience = Ambience.make(fx)
		glow_layer.add_child(ambience)   # a follow-viewport layer: unaffected by the night tint
	_check_all_found()


func _process(_delta: float) -> void:
	if ambience:
		if ambience.kind == "fireflies":
			ambience.emitting = day_night.is_night()   # glows stay bright
		else:
			ambience.modulate = day_night.color         # leaves and dust follow the light


## Called by a Teleporter the player walked into.
func travel(to_map: String, at_door: String) -> void:
	if traveling:
		return
	traveling = true
	player.frozen = true
	await transition.fade_to(1.0)
	map.map_file = "res://maps/%s.txt" % to_map
	var door: Teleporter = map.doors.get(at_door)
	var feet := door.arrival_position() if door else map.spawn
	if door:
		player.face(door.exit_dir)
	_enter_map(feet)
	await get_tree().process_frame
	await transition.fade_to(0.0)
	player.frozen = false
	traveling = false


func _check_all_found() -> void:
	if map == null or map.find_ids.is_empty():
		return
	if GameState.count_flags(map.find_ids) == map.find_ids.size():
		GameState.set_flag("alle_funn_" + map.map_name())

## Root scene: owns the map, the player, the HUD and the fade; handles travel between maps.
extends Node2D

const HUD := preload("res://scripts/hud.gd")

@onready var map: MapBuilder = $Map
@onready var player: Player = $Player

var hud: CanvasLayer
var transition: Transition
var traveling := false


func _ready() -> void:
	y_sort_enabled = true
	hud = HUD.new()
	add_child(hud)
	transition = Transition.new()
	add_child(transition)
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


func _enter_map(feet: Vector2) -> void:
	player.global_position = feet
	player.velocity = Vector2.ZERO
	player.set_camera_limits(map.pixel_size())
	player.camera.reset_smoothing()
	hud.set_finds(map.find_ids)
	GameState.current_map = map.map_name()
	Music.play(map.settings.get("music", ""))
	_check_all_found()


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

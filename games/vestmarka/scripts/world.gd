## Root scene: owns the map and the player, places the player at the map's spawn.
extends Node2D

@onready var map: MapBuilder = $Map
@onready var player: Player = $Player


func _ready() -> void:
	y_sort_enabled = true
	player.global_position = map.spawn
	player.set_camera_limits(map.pixel_size())
	player.camera.reset_smoothing()

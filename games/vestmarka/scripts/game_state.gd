## Autoload: flags (chests opened, people met) persisted to user:// (IndexedDB on web).
extends Node

signal changed

const SAVE_PATH := "user://save.json"

var flags: Dictionary = {}
var current_map := "landsby"


func _ready() -> void:
	load_game()


func has_flag(flag: String) -> bool:
	return flags.get(flag, false)


func set_flag(flag: String, value := true) -> void:
	if flags.get(flag, false) == value:
		return
	flags[flag] = value
	changed.emit()
	save_game()


func count_flags(ids: Array) -> int:
	var n := 0
	for id in ids:
		if has_flag(id):
			n += 1
	return n


func save_game() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"flags": flags, "map": current_map}))


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var data = JSON.parse_string(f.get_as_text())
	if data is Dictionary:
		flags = data.get("flags", {})
		current_map = data.get("map", current_map)


func reset() -> void:
	flags = {}
	changed.emit()
	save_game()

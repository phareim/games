## Autoload: one-shot sound effects by name.
extends Node

const STREAMS := {
	"accept": preload("res://assets/audio/sfx/accept.wav"),
	"chest": preload("res://assets/audio/sfx/chest.wav"),
	"travel": preload("res://assets/audio/sfx/travel.wav"),
	"talk": preload("res://assets/audio/sfx/talk.wav"),
	"secret": preload("res://assets/audio/sfx/secret.wav"),
}

var players: Array[AudioStreamPlayer] = []


func _ready() -> void:
	for i in 4:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		players.append(p)


func play(name: String, volume_db := -6.0) -> void:
	if not STREAMS.has(name):
		return
	for p in players:
		if not p.playing:
			p.stream = STREAMS[name]
			p.volume_db = volume_db
			p.play()
			return

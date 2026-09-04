## Autoload: looping map music with a short crossfade.
extends Node

const TRACKS := {
	"village": "res://assets/audio/music/village.ogg",
	"forest": "res://assets/audio/music/forest.ogg",
	"cave": "res://assets/audio/music/cave.ogg",
}
const VOLUME_DB := -10.0
const FADE := 1.2

var current := ""
var a: AudioStreamPlayer
var b: AudioStreamPlayer


func _ready() -> void:
	a = AudioStreamPlayer.new()
	b = AudioStreamPlayer.new()
	add_child(a)
	add_child(b)


func play(name: String) -> void:
	if name == current:
		return
	current = name
	var incoming := b if a.playing else a
	var outgoing := a if incoming == b else b
	if TRACKS.has(name):
		var stream: AudioStream = load(TRACKS[name])
		if stream is AudioStreamOggVorbis:
			stream.loop = true
		incoming.stream = stream
		incoming.volume_db = -40.0
		incoming.play()
		create_tween().tween_property(incoming, "volume_db", VOLUME_DB, FADE)
	if outgoing.playing:
		var t := create_tween()
		t.tween_property(outgoing, "volume_db", -40.0, FADE)
		t.tween_callback(outgoing.stop)

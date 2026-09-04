## Autoload: looping map music with a short crossfade.
extends Node

const TRACKS := {
	"village": "res://assets/audio/music/village.ogg",
	"forest": "res://assets/audio/music/forest.ogg",
	"cave": "res://assets/audio/music/cave.ogg",
}
const VOLUME_DB := -10.0
const FADE := 1.2

const AMBIENT := {
	"wind": "res://assets/audio/sfx/wind.wav",
	"river": "res://assets/audio/sfx/river.wav",
}
const AMBIENT_DB := -16.0

var current := ""
var current_ambient := ""
var a: AudioStreamPlayer
var b: AudioStreamPlayer
var amb: AudioStreamPlayer


func _ready() -> void:
	a = AudioStreamPlayer.new()
	b = AudioStreamPlayer.new()
	amb = AudioStreamPlayer.new()
	add_child(a)
	add_child(b)
	add_child(amb)


func ambient(name: String) -> void:
	if name == current_ambient:
		return
	current_ambient = name
	if amb.playing:
		var t := create_tween()
		t.tween_property(amb, "volume_db", -40.0, FADE)
		t.tween_callback(amb.stop)
		await t.finished
	if AMBIENT.has(name):
		var stream: AudioStream = load(AMBIENT[name])
		if stream is AudioStreamWAV:
			stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
			stream.loop_end = stream.mix_rate * int(stream.get_length())
		amb.stream = stream
		amb.volume_db = -40.0
		amb.play()
		create_tween().tween_property(amb, "volume_db", AMBIENT_DB, FADE)


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

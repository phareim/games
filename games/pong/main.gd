extends Node2D
## Pong — the first game on games.phareim.no. Everything is drawn in _draw();
## no scene tree beyond this node and three generated audio players.

const W := 960.0
const H := 540.0
const PADDLE_W := 14.0
const PADDLE_H := 92.0
const BALL := 12.0
const MARGIN := 36.0
const PLAYER_SPEED := 560.0
const AI_SPEED := 400.0
const SERVE_SPEED := 420.0
const MAX_SPEED := 1100.0
const WIN_SCORE := 7

const INK := Color(0.91, 0.90, 0.87)
const DIM := Color(0.23, 0.25, 0.30)
const ACCENT := Color(0.95, 0.71, 0.20)

var left_y := H / 2.0
var right_y := H / 2.0
var ball_pos := Vector2(W / 2.0, H / 2.0)
var ball_vel := Vector2.ZERO
var score := [0, 0]
var state := "title" # title | play | serve | over
var serve_dir := 1
var touch_y := -1.0
var trail: Array[Vector2] = []
var flash := 0.0
var ai_target := H / 2.0
var ai_retarget := 0.0
var font: Font
var snd_paddle: AudioStreamPlayer
var snd_wall: AudioStreamPlayer
var snd_score: AudioStreamPlayer


func _ready() -> void:
	font = ThemeDB.fallback_font
	snd_paddle = _make_tone(660.0, 0.06)
	snd_wall = _make_tone(330.0, 0.05, 0.25)
	snd_score = _make_tone(180.0, 0.25, 0.3)


func _make_tone(freq: float, dur: float, vol := 0.35) -> AudioStreamPlayer:
	var rate := 22050
	var n := int(rate * dur)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var t := float(i) / rate
		var square := 1.0 if fmod(t * freq, 1.0) < 0.5 else -1.0
		var env := 1.0 - float(i) / n
		data.encode_s16(i * 2, int(square * env * vol * 32000.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.data = data
	var p := AudioStreamPlayer.new()
	p.stream = wav
	add_child(p)
	return p


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		touch_y = event.position.y
		_tap()
	elif event is InputEventScreenDrag:
		touch_y = event.position.y
	elif event is InputEventScreenTouch and not event.pressed:
		touch_y = -1.0
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			_tap()


func _tap() -> void:
	if state == "title" or state == "over":
		score = [0, 0]
		serve_dir = 1
		_serve()


func _serve() -> void:
	state = "serve"
	ball_pos = Vector2(W / 2.0, H / 2.0)
	ball_vel = Vector2.ZERO
	trail.clear()
	await get_tree().create_timer(0.7).timeout
	if state != "serve":
		return
	var angle := randf_range(-0.45, 0.45)
	ball_vel = Vector2(serve_dir, 0).rotated(angle) * SERVE_SPEED
	state = "play"


func _process(dt: float) -> void:
	_update_player(dt)
	if state == "play":
		_update_ai(dt)
		_update_ball(dt)
	flash = maxf(flash - dt * 3.0, 0.0)
	queue_redraw()


func _update_player(dt: float) -> void:
	var dir := 0.0
	if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W):
		dir -= 1.0
	if Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S):
		dir += 1.0
	if dir != 0.0:
		left_y += dir * PLAYER_SPEED * dt
	elif touch_y >= 0.0:
		left_y = move_toward(left_y, touch_y, PLAYER_SPEED * 1.6 * dt)
	left_y = clampf(left_y, PADDLE_H / 2.0, H - PADDLE_H / 2.0)


func _update_ai(dt: float) -> void:
	ai_retarget -= dt
	if ai_retarget <= 0.0:
		ai_retarget = 0.12
		if ball_vel.x > 0.0:
			# Predict where the ball crosses the paddle plane, with some sloppiness.
			var t := (W - MARGIN - PADDLE_W - ball_pos.x) / ball_vel.x
			var y := ball_pos.y + ball_vel.y * t
			while y < 0.0 or y > H:
				y = -y if y < 0.0 else 2.0 * H - y
			ai_target = y + randf_range(-28.0, 28.0)
		else:
			ai_target = lerpf(right_y, H / 2.0, 0.3)
	right_y = move_toward(right_y, ai_target, AI_SPEED * dt)
	right_y = clampf(right_y, PADDLE_H / 2.0, H - PADDLE_H / 2.0)


func _update_ball(dt: float) -> void:
	ball_pos += ball_vel * dt
	trail.push_front(ball_pos)
	if trail.size() > 10:
		trail.pop_back()

	var r := BALL / 2.0
	if ball_pos.y - r <= 0.0 and ball_vel.y < 0.0:
		ball_pos.y = r
		ball_vel.y = -ball_vel.y
		snd_wall.play()
	elif ball_pos.y + r >= H and ball_vel.y > 0.0:
		ball_pos.y = H - r
		ball_vel.y = -ball_vel.y
		snd_wall.play()

	var left_rect := _paddle_rect(true)
	var right_rect := _paddle_rect(false)
	var ball_rect := Rect2(ball_pos - Vector2(r, r), Vector2(BALL, BALL))
	if ball_vel.x < 0.0 and ball_rect.intersects(left_rect):
		_bounce(left_rect, 1)
	elif ball_vel.x > 0.0 and ball_rect.intersects(right_rect):
		_bounce(right_rect, -1)

	if ball_pos.x < -BALL * 2.0:
		_point(1)
	elif ball_pos.x > W + BALL * 2.0:
		_point(0)


func _bounce(paddle: Rect2, dir: int) -> void:
	var rel := (ball_pos.y - paddle.get_center().y) / (PADDLE_H / 2.0)
	rel = clampf(rel, -1.0, 1.0)
	var speed := minf(ball_vel.length() * 1.06, MAX_SPEED)
	var angle := rel * 0.95
	ball_vel = Vector2(dir, 0).rotated(angle) * speed
	if dir > 0:
		ball_pos.x = paddle.end.x + BALL / 2.0
	else:
		ball_pos.x = paddle.position.x - BALL / 2.0
	flash = 1.0
	snd_paddle.play()


func _point(who: int) -> void:
	score[who] += 1
	serve_dir = -1 if who == 0 else 1
	snd_score.play()
	if score[who] >= WIN_SCORE:
		state = "over"
		ball_vel = Vector2.ZERO
	else:
		_serve()


func _paddle_rect(left: bool) -> Rect2:
	var x := MARGIN if left else W - MARGIN - PADDLE_W
	var y := left_y if left else right_y
	return Rect2(x, y - PADDLE_H / 2.0, PADDLE_W, PADDLE_H)


func _draw() -> void:
	# Court
	draw_dashed_line(Vector2(W / 2.0, 0), Vector2(W / 2.0, H), DIM, 3.0, 14.0)
	# Score
	var big := 64
	draw_string(font, Vector2(W / 2.0 - 140.0, 84.0), str(score[0]), HORIZONTAL_ALIGNMENT_CENTER, 120, big, DIM.lerp(INK, 0.6))
	draw_string(font, Vector2(W / 2.0 + 20.0, 84.0), str(score[1]), HORIZONTAL_ALIGNMENT_CENTER, 120, big, DIM.lerp(INK, 0.6))
	# Paddles
	draw_rect(_paddle_rect(true), INK)
	draw_rect(_paddle_rect(false), INK)
	# Ball + trail
	if state == "play":
		for i in trail.size():
			var a := 0.35 * (1.0 - float(i) / trail.size())
			draw_circle(trail[i], BALL / 2.0 * (1.0 - float(i) / trail.size() * 0.5), Color(ACCENT, a))
		draw_circle(ball_pos, BALL / 2.0, ACCENT.lerp(INK, flash))
	elif state == "serve":
		draw_circle(ball_pos, BALL / 2.0, Color(ACCENT, 0.5))
	# Text
	match state:
		"title":
			_center_text("PONG", 96.0, 220.0, INK)
			_center_text("Piltaster eller W/S · trykk for å styre på mobil", 22.0, 300.0, DIM.lerp(INK, 0.5))
			_center_text("Mellomrom eller trykk for å starte · først til %d" % WIN_SCORE, 22.0, 334.0, ACCENT)
		"over":
			var msg := "Du vant" if score[0] > score[1] else "Maskinen vant"
			_center_text(msg, 72.0, 240.0, INK)
			_center_text("Trykk for å spille igjen", 22.0, 300.0, ACCENT)


func _center_text(text: String, size: float, y: float, color: Color) -> void:
	draw_string(font, Vector2(0, y), text, HORIZONTAL_ALIGNMENT_CENTER, W, int(size), color)

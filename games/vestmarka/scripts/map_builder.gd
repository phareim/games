## Builds a map from an ASCII text file: terrain into a TileMapLayer (autotiled),
## props into Y-sorted sprites. Runs in the editor too (@tool) so maps show on the Mac.
@tool
class_name MapBuilder
extends Node2D

const TILE := 16
const TILESET: TileSet = preload("res://assets/tiles/tileset.tres")
const GRASS := 0
const DIRT := 1
const WATER := 2
const CLIFF := 3
const TERRAIN_CHARS := {":": DIRT, "~": WATER, "#": CLIFF}

@export_file("*.txt") var map_file: String = "res://maps/landsby.txt":
	set(v):
		map_file = v
		if is_inside_tree():
			build()

var size := Vector2i.ZERO          # in tiles
var spawn := Vector2(8 * TILE, 8 * TILE)
var ground: TileMapLayer
var props: Node2D


func _ready() -> void:
	build()


func pixel_size() -> Vector2:
	return Vector2(size) * TILE


func build() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	ground = TileMapLayer.new()
	ground.name = "Ground"
	ground.tile_set = TILESET
	ground.z_index = -1
	add_child(ground)
	props = Node2D.new()
	props.name = "Props"
	props.y_sort_enabled = true
	add_child(props)

	var t0 := Time.get_ticks_msec()
	var rows := _read_rows(map_file)
	if rows.is_empty():
		push_warning("MapBuilder: empty map %s" % map_file)
		return
	size = Vector2i(rows[0].length(), rows.size())
	var by_terrain := {GRASS: [], DIRT: [], WATER: [], CLIFF: []}
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			var ch := row[x]
			var cell := Vector2i(x, y)
			var terrain: int = TERRAIN_CHARS.get(ch, GRASS)
			by_terrain[terrain].append(cell)
			if ch == "@":
				spawn = Vector2(cell) * TILE + Vector2(TILE / 2.0, TILE)
			elif Props.CATALOGUE.has(ch):
				_add_prop(ch, cell)
	# Grass is painted directly (the terrain solver is far too slow for thousands of
	# cells in wasm); only the blobs go through set_cells_terrain_connect.
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(map_file)
	for cell in by_terrain[GRASS]:
		ground.set_cell(cell, 0, _grass_variant(rng))
	for terrain in [DIRT, WATER, CLIFF]:
		if not by_terrain[terrain].is_empty():
			ground.set_cells_terrain_connect(by_terrain[terrain], 0, terrain, false)
	print("MapBuilder: %s %dx%d built in %d ms" % [map_file.get_file(), size.x, size.y, Time.get_ticks_msec() - t0])


const GRASS_VARIANTS := [Vector2i(1, 12), Vector2i(2, 12), Vector2i(3, 12), Vector2i(4, 12), Vector2i(2, 11), Vector2i(3, 11)]


func _grass_variant(rng: RandomNumberGenerator) -> Vector2i:
	if rng.randf() < 0.12:
		return GRASS_VARIANTS[rng.randi_range(0, GRASS_VARIANTS.size() - 1)]
	return Vector2i(0, 12)


func _read_rows(path: String) -> Array[String]:
	var rows: Array[String] = []
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("MapBuilder: cannot open %s" % path)
		return rows
	var width := 0
	while not f.eof_reached():
		var line := f.get_line()
		if line.begins_with("//") or (line.is_empty() and rows.is_empty()):
			continue
		if line.is_empty():
			break
		rows.append(line)
		width = max(width, line.length())
	for i in rows.size():
		rows[i] = rows[i].rpad(width, ".")
	return rows


func _add_prop(ch: String, cell: Vector2i) -> void:
	var def: Dictionary = Props.CATALOGUE[ch]
	var region: Rect2i = def["region"]
	var root := Node2D.new()
	root.position = Vector2(cell) * TILE + Vector2(TILE / 2.0, TILE)
	var sprite := Sprite2D.new()
	sprite.texture = load(def["tex"])
	sprite.region_enabled = true
	sprite.region_rect = region
	sprite.offset = Vector2(0, -region.size.y / 2.0)
	root.add_child(sprite)
	if def.has("body"):
		var body := StaticBody2D.new()
		body.collision_layer = 1
		body.collision_mask = 0
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		var r: Rect2 = def["body"]
		rect.size = r.size
		shape.shape = rect
		shape.position = r.position + r.size / 2.0
		body.add_child(shape)
		root.add_child(body)
	props.add_child(root)

## Builds a map from an ASCII text file: terrain into a TileMapLayer (autotiled),
## props/NPCs/chests/doors into Y-sorted nodes. Runs in the editor too (@tool).
##
## File format: grid rows first (one char per tile, `//` = comment), a blank line, then
## object lines `type x y key=value key="quoted value"`. Types: map (music=, base=grass|cave),
## sign, chest, npc, door, prop. See CLAUDE.md for the character legend.
@tool
class_name MapBuilder
extends Node2D

const TILE := 16
const TILESET: TileSet = preload("res://assets/tiles/tileset.tres")
const GROUND := 0
const DIRT := 1
const WATER := 2
const CLIFF := 3
const HOLE := 4
const DARK := 5
const TERRAIN_CHARS := {":": DIRT, "~": WATER, "#": CLIFF, "x": HOLE, "d": DARK}
const BASE_TILES := {  # base kind -> [plain, variants...] in source 0 (floor.png)
	"grass": [Vector2i(0, 12), Vector2i(1, 12), Vector2i(2, 12), Vector2i(3, 12), Vector2i(4, 12), Vector2i(2, 11), Vector2i(3, 11)],
	"cave": [Vector2i(11, 19), Vector2i(12, 19), Vector2i(13, 19), Vector2i(14, 19), Vector2i(15, 19)],
}
const DIR_NAMES := {"down": Vector2.DOWN, "up": Vector2.UP, "left": Vector2.LEFT, "right": Vector2.RIGHT}

@export_file("*.txt") var map_file: String = "res://maps/landsby.txt":
	set(v):
		map_file = v
		if is_inside_tree():
			build()

var size := Vector2i.ZERO          # in tiles
var spawn := Vector2(8 * TILE, 8 * TILE)
var find_ids: Array = []           # chest ids on this map (for the HUD)
var settings := {}                 # from the `map` object line: music, base
var doors := {}                    # id -> Teleporter
var ground: TileMapLayer
var props: Node2D


func _ready() -> void:
	build()


func pixel_size() -> Vector2:
	return Vector2(size) * TILE


func map_name() -> String:
	return map_file.get_file().get_basename()


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
	find_ids = []
	settings = {}
	doors = {}
	var objects: Array[String] = []
	var rows := _read_rows(map_file, objects)
	if rows.is_empty():
		push_warning("MapBuilder: empty map %s" % map_file)
		return
	for line in objects:       # `map` line first so the base kind is known
		if line.begins_with("map "):
			settings = _kv(_tokenize(line).slice(1))
	var base: Array = BASE_TILES.get(settings.get("base", "grass"), BASE_TILES["grass"])

	size = Vector2i(rows[0].length(), rows.size())
	var by_terrain := {}
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			var ch := row[x]
			var cell := Vector2i(x, y)
			var terrain: int = TERRAIN_CHARS.get(ch, GROUND)
			if not by_terrain.has(terrain):
				by_terrain[terrain] = []
			by_terrain[terrain].append(cell)
			if ch == "@":
				spawn = cell_base(cell)
			elif Props.CATALOGUE.has(ch):
				add_prop(ch, cell)
	# Base tiles are painted directly (the terrain solver is far too slow for thousands of
	# cells in wasm); only the blobs go through set_cells_terrain_connect.
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(map_file)
	for cell in by_terrain.get(GROUND, []):
		ground.set_cell(cell, 0, _variant(base, rng))
	for terrain in by_terrain:
		if terrain != GROUND:
			ground.set_cells_terrain_connect(by_terrain[terrain], 0, terrain, false)
	for line in objects:
		if not line.begins_with("map "):
			_add_object(line)
	print("MapBuilder: %s %dx%d built in %d ms" % [map_file.get_file(), size.x, size.y, Time.get_ticks_msec() - t0])


func _variant(base: Array, rng: RandomNumberGenerator) -> Vector2i:
	if base.size() > 1 and rng.randf() < 0.12:
		return base[rng.randi_range(1, base.size() - 1)]
	return base[0]


func _read_rows(path: String, objects: Array[String]) -> Array[String]:
	var rows: Array[String] = []
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("MapBuilder: cannot open %s" % path)
		return rows
	var width := 0
	var in_grid := true
	while not f.eof_reached():
		var line := f.get_line()
		if line.begins_with("//") or (line.is_empty() and rows.is_empty()):
			continue
		if line.is_empty():
			in_grid = false
			continue
		if in_grid:
			rows.append(line)
			width = max(width, line.length())
		else:
			objects.append(line.strip_edges())
	for i in rows.size():
		rows[i] = rows[i].rpad(width, ".")
	return rows


func cell_base(cell: Vector2i) -> Vector2:
	return Vector2(cell) * TILE + Vector2(TILE / 2.0, TILE)


func add_prop(kind: String, cell: Vector2i) -> void:
	var def: Dictionary = Props.CATALOGUE[kind]
	var region: Rect2i = def["region"]
	var root := Node2D.new()
	root.position = cell_base(cell)
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


## `sign 13 21 text="Hei|Side to"`, `chest 17 13 id=kiste_dam text="..."`,
## `npc 26 18 who=OldMan name="Halvor" text="..." done=flag text_done="..." sets=flag face=down`,
## `door 59 20 id=ost to=skog at=vest dir=left h=2`, `prop 40 14 kind=house_a`
func _add_object(line: String) -> void:
	var tokens := _tokenize(line)
	if tokens.size() < 3:
		return
	var kind: String = tokens[0]
	var cell := Vector2i(int(tokens[1]), int(tokens[2]))
	var kv := _kv(tokens.slice(3))
	match kind:
		"prop":
			if Props.CATALOGUE.has(kv.get("kind", "")):
				add_prop(kv["kind"], cell)
			return
		"door":
			var door := Teleporter.new()
			door.id = kv.get("id", "")
			door.to_map = kv.get("to", "")
			door.to_door = kv.get("at", "")
			door.exit_dir = DIR_NAMES.get(kv.get("dir", "down"), Vector2.DOWN)
			door.cells = Vector2i(int(kv.get("w", "1")), int(kv.get("h", "1")))
			door.position = Vector2(cell) * TILE
			props.add_child(door)
			doors[door.id] = door
			return
	var node: Interactable
	match kind:
		"sign":
			node = Sign.new()
		"chest":
			node = Chest.new()
			node.id = kv.get("id", "kiste_%d_%d" % [cell.x, cell.y])
			node.big = kv.get("big", "0") == "1"
			find_ids.append(node.id)
		"npc":
			node = Npc.new()
			node.who = kv.get("who", "Villager")
			node.speaker = kv.get("name", "")
			node.sets_flag = kv.get("sets", "")
			node.done_flag = kv.get("done", "")
			node.pages_done = _pages(kv.get("text_done", ""))
			node.facing = DIR_NAMES.get(kv.get("face", "down"), Vector2.DOWN)
		_:
			push_warning("MapBuilder: unknown object '%s'" % kind)
			return
	node.pages = _pages(kv.get("text", ""))
	node.position = cell_base(cell)
	props.add_child(node)


func _kv(tokens: Array) -> Dictionary:
	var kv := {}
	for t in tokens:
		var eq: int = t.find("=")
		if eq > 0:
			kv[t.substr(0, eq)] = t.substr(eq + 1)
	return kv


func _pages(text: String) -> Array[String]:
	var out: Array[String] = []
	if text.is_empty():
		return out
	for p in text.split("|"):
		out.append(p.strip_edges())
	return out


func _tokenize(line: String) -> Array[String]:
	var out: Array[String] = []
	var cur := ""
	var quoted := false
	for ch in line:
		if ch == '"':
			quoted = not quoted
		elif ch == " " and not quoted:
			if cur != "":
				out.append(cur)
			cur = ""
		else:
			cur += ch
	if cur != "":
		out.append(cur)
	return out

#!/usr/bin/env python3
"""Generate assets/tiles/tileset.tres and assets/hero/hero_frames.tres from the PNGs.

Terrain peering bits are derived by sampling pixel colours along each tile's edges and
corners (green = grass, anything else = the block's foreground terrain), so the blob
layouts in the Ninja Adventure sheets never have to be transcribed by hand.
Run from anywhere: python3 games/vestmarka/tools/gen_resources.py
"""
import colorsys, os, sys
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
T = 16

# terrain ids in terrain set 0
GRASS, DIRT, WATER, CLIFF, HOLE, DARK = 0, 1, 2, 3, 4, 5
TERRAIN_NAMES = ["ground", "dirt", "water", "cliff", "hole", "dark"]
TERRAIN_COLORS = ["Color(0.4,0.7,0.2,1)", "Color(0.7,0.45,0.3,1)", "Color(0.3,0.6,0.9,1)", "Color(0.6,0.6,0.55,1)",
                  "Color(0.1,0.1,0.12,1)", "Color(0.35,0.25,0.2,1)"]

# atlas sources: id -> (file, ext id)
SOURCES = [("floor.png", "floor"), ("water.png", "water"), ("relief.png", "relief"),
           ("nature.png", "nature"), ("house.png", "house"), ("hole.png", "hole")]

SIDES = {  # name -> pixel window (x0,y0,x1,y1) inclusive, inside a 16x16 tile
    "top_side": (5, 0, 10, 1), "bottom_side": (5, 14, 10, 15),
    "left_side": (0, 5, 1, 10), "right_side": (14, 5, 15, 10),
    "top_left_corner": (0, 0, 2, 2), "top_right_corner": (13, 0, 15, 2),
    "bottom_left_corner": (0, 13, 2, 15), "bottom_right_corner": (13, 13, 15, 15),
}
BIT_ORDER = ["right_side", "bottom_right_corner", "bottom_side", "bottom_left_corner",
             "left_side", "top_left_corner", "top_side", "top_right_corner"]


def is_grass(px):
    r, g, b, a = px
    if a < 128:
        return None
    h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
    return 0.16 < h < 0.45 and s > 0.3 and v > 0.25


def classify(im, tx, ty, fg):
    """Return (terrain, bits, bbox) for tile (tx,ty). bits: name -> terrain id."""
    bits = {}
    for name, (x0, y0, x1, y1) in SIDES.items():
        votes = [is_grass(im.getpixel((tx * T + x, ty * T + y))) for x in range(x0, x1 + 1) for y in range(y0, y1 + 1)]
        votes = [v for v in votes if v is not None]
        grass = sum(votes) > len(votes) / 2 if votes else True
        bits[name] = GRASS if grass else fg
    centre = [is_grass(im.getpixel((tx * T + x, ty * T + y))) for x in range(6, 10) for y in range(6, 10)]
    centre = [v for v in centre if v is not None]
    terrain = GRASS if (centre and sum(centre) > len(centre) / 2) else fg
    # bbox of foreground pixels (for collision)
    xs, ys = [], []
    for x in range(T):
        for y in range(T):
            g = is_grass(im.getpixel((tx * T + x, ty * T + y)))
            if g is False:
                xs.append(x); ys.append(y)
    bbox = (min(xs), min(ys), max(xs) + 1, max(ys) + 1) if xs else None
    return terrain, bits, bbox


def bits_from_ascii(rows, fg):
    """'.:.' '.:.' '.:.' -> peering dict; '.' = grass, anything else = fg."""
    t = lambda c: GRASS if c == "." else fg
    return {"top_left_corner": t(rows[0][0]), "top_side": t(rows[0][1]), "top_right_corner": t(rows[0][2]),
            "left_side": t(rows[1][0]), "right_side": t(rows[1][2]),
            "bottom_left_corner": t(rows[2][0]), "bottom_side": t(rows[2][1]), "bottom_right_corner": t(rows[2][2])}




# The pixel-boy blob block layout (relative to the block origin) and the peering bits of the
# part we trust: the 3x3 outer set, the two strips, the single, and the four single-inner-corner
# tiles. The remaining tiles (diagonals, multi-corner combos) duplicated the plain tile when
# sampled and filled ponds with "hole" tiles; Godot approximates the missing combos.
# "." = background (terrain 0), "x" = the block's terrain. Verified against pixel sampling.
BLOB_BITS = {
    (0, 0): ("...", ".xx", ".xx"), (1, 0): ("...", "xxx", "xxx"), (2, 0): ("...", "xx.", "xx."),
    (0, 1): (".xx", ".xx", ".xx"), (1, 1): ("xxx", "xxx", "xxx"), (2, 1): ("xx.", "xx.", "xx."),
    (0, 2): (".xx", ".xx", "..."), (1, 2): ("xxx", "xxx", "..."), (2, 2): ("xx.", "xx.", "..."),
    (3, 0): ("...", ".x.", ".x."), (3, 1): (".x.", ".x.", ".x."), (3, 2): (".x.", ".x.", "..."),
    (0, 3): ("...", ".xx", "..."), (1, 3): ("...", "xxx", "..."), (2, 3): ("...", "xx.", "..."),
    (3, 3): ("...", ".x.", "..."),
    (5, 1): ("xxx", "xxx", "xx."), (6, 1): ("xxx", "xxx", ".xx"),
    (5, 2): ("xx.", "xxx", "xxx"), (6, 2): (".xx", "xxx", "xxx"),
}
BLOB_CELLS = list(BLOB_BITS.keys())


def blob_tiles(source_tiles, origin, terrain, skip=(), collide=None, im=None):
    """Emit one blob block at `origin` (atlas coords of the 3x3's top-left) with terrain bits.
    collide: None | "full" | "bbox" (bbox of non-background pixels, needs `im`)."""
    for (rx, ry), rows in BLOB_BITS.items():
        if (rx, ry) in skip:
            continue
        tx, ty = origin[0] + rx, origin[1] + ry
        poly = None
        if collide == "full":
            poly = rect_poly(0, 0, 16, 16)
        elif collide == "bbox":
            _, _, bbox = classify(im, tx, ty, terrain)
            poly = rect_poly(*bbox) if bbox else None
        source_tiles += tile_lines(tx, ty, terrain, bits_from_ascii(rows, terrain), poly=poly)


def rect_poly(x0, y0, x1, y1):
    """Tile-local rect (0..16) -> PackedVector2Array centred on the tile."""
    return f"PackedVector2Array({x0-8}, {y0-8}, {x1-8}, {y0-8}, {x1-8}, {y1-8}, {x0-8}, {y1-8})"


def tile_lines(tx, ty, terrain=None, bits=None, prob=None, poly=None, size=None):
    p = f"{tx}:{ty}"
    out = []
    if size:
        out.append(f"{p}/size_in_atlas = Vector2i({size[0]}, {size[1]})")
    out.append(f"{p}/0 = 0")
    if prob is not None:
        out.append(f"{p}/0/probability = {prob}")
    if terrain is not None:
        out.append(f"{p}/0/terrain_set = 0")
        out.append(f"{p}/0/terrain = {terrain}")
        for name in BIT_ORDER:
            out.append(f"{p}/0/terrains_peering_bit/{name} = {bits[name]}")
    if poly:
        out.append(f"{p}/0/physics_layer_0/linear_velocity = Vector2(0, 0)")
        out.append(f"{p}/0/physics_layer_0/angular_velocity = 0.0")
        out.append(f"{p}/0/physics_layer_0/polygon_0/points = {poly}")
    return out


def ascii_bits(bits, terrain):
    ch = ".:~#"
    b = {k: ch[v] for k, v in bits.items()}
    return [f"{b['top_left_corner']}{b['top_side']}{b['top_right_corner']}",
            f"{b['left_side']}{ch[terrain]}{b['right_side']}",
            f"{b['bottom_left_corner']}{b['bottom_side']}{b['bottom_right_corner']}"]


def gen_tileset(debug):
    tiles = {i: [] for i in range(len(SOURCES))}
    imgs = {i: Image.open(os.path.join(ROOT, "assets/tiles", f)).convert("RGBA") for i, (f, _) in enumerate(SOURCES)}

    # --- floor.png (source 0): plain grass + details, dirt blob -----------------------
    im = imgs[0]
    allgrass = {n: GRASS for n in SIDES}
    tiles[0] += tile_lines(0, 12, GRASS, allgrass, prob=1.0)
    for tx in (1, 2, 3, 4):
        tiles[0] += tile_lines(tx, 12, GRASS, allgrass, prob=0.06)
    for tx in (2, 3):
        tiles[0] += tile_lines(tx, 11, GRASS, allgrass, prob=0.04)
    blob_tiles(tiles[0], (0, 7), DIRT)
    # bare dirt decor (X mark, stone) as plain dirt variants
    for tx in (0, 1):
        tiles[0] += tile_lines(tx, 11, DIRT, {n: DIRT for n in SIDES}, prob=0.05)
    # cave: tan base (ground terrain, other sheet region) + dark-dirt blob
    tiles[0] += tile_lines(11, 19, GRASS, allgrass, prob=1.0)
    for tx in (12, 13, 14, 15):
        tiles[0] += tile_lines(tx, 19, GRASS, allgrass, prob=0.06)
    blob_tiles(tiles[0], (11, 14), DARK)

    # --- water.png (source 1): water-on-grass blob, with collision on the wet part ------
    blob_tiles(tiles[1], (0, 6), WATER, skip=[(3, 3)], collide="bbox", im=imgs[1])  # (3,3) is sand there

    # --- hole.png (source 5): the void beyond cave floors, solid ------------------------
    blob_tiles(tiles[5], (0, 0), HOLE, collide="full")

    # --- relief.png (source 2): cliff plateau, sides-only set, hand-listed ------------
    G, C = GRASS, CLIFF
    def cb(t, r, b, l, tl=None, tr=None, br=None, bl=None):
        # corners default to cliff only when both adjacent sides are cliff
        return {"top_side": t, "right_side": r, "bottom_side": b, "left_side": l,
                "top_left_corner": C if (tl if tl is not None else (t == C and l == C)) else G,
                "top_right_corner": C if (tr if tr is not None else (t == C and r == C)) else G,
                "bottom_right_corner": C if (br if br is not None else (b == C and r == C)) else G,
                "bottom_left_corner": C if (bl if bl is not None else (b == C and l == C)) else G}
    full = rect_poly(0, 0, 16, 16)
    cliff = {
        (1, 0): cb(G, C, C, G), (2, 0): cb(G, C, C, C), (3, 0): cb(G, G, C, C),
        (1, 1): cb(C, C, C, G), (2, 1): cb(C, C, C, C), (3, 1): cb(C, G, C, C),
        (1, 2): cb(C, C, G, G), (2, 2): cb(C, C, G, C), (3, 2): cb(C, G, G, C),
        (0, 0): cb(G, G, C, G), (0, 1): cb(C, G, C, G), (0, 2): cb(C, G, G, G),
        # inner corners (plateau interior with one grass corner), row 3-4
        (0, 3): cb(C, C, C, C, bl=False), (1, 3): cb(C, C, C, C, br=False),
        (0, 4): cb(C, C, C, C, tl=False), (1, 4): cb(C, C, C, C, tr=False),
    }
    for (tx, ty), bits in cliff.items():
        tiles[2] += tile_lines(tx, ty, CLIFF, bits, poly=full)

    # --- nature.png (source 3): props as multi-cell tiles (used by props, no terrain) ---
    # (kept minimal: props are placed as sprites by map_builder; the atlas is here so the
    #  editor can paint them too)
    for (tx, ty, w, h) in [(0, 0, 2, 2), (2, 0, 2, 2), (4, 0, 2, 2), (0, 2, 3, 3), (3, 2, 3, 3),
                           (6, 2, 3, 3), (9, 2, 3, 3), (12, 2, 3, 3), (15, 2, 3, 3)]:
        tiles[3] += tile_lines(tx, ty, size=(w, h))
    for tx in range(0, 12):
        tiles[3] += tile_lines(tx, 10)
        tiles[3] += tile_lines(tx, 11)

    # --- write .tres ------------------------------------------------------------------
    n_ext = len(SOURCES)
    out = [f'[gd_resource type="TileSet" load_steps={n_ext * 2 + 1} format=3]', ""]
    for i, (f, eid) in enumerate(SOURCES):
        out.append(f'[ext_resource type="Texture2D" path="res://assets/tiles/{f}" id="{eid}"]')
    out.append("")
    for i, (f, eid) in enumerate(SOURCES):
        out.append(f'[sub_resource type="TileSetAtlasSource" id="src{i}"]')
        out.append(f'texture = ExtResource("{eid}")')
        out.append("texture_region_size = Vector2i(16, 16)")
        out += tiles[i]
        out.append("")
    out.append("[resource]")
    out.append("tile_size = Vector2i(16, 16)")
    out.append("physics_layer_0/collision_layer = 1")
    out.append("physics_layer_0/collision_mask = 0")
    out.append("terrain_set_0/mode = 0")
    for i, name in enumerate(TERRAIN_NAMES):
        out.append(f'terrain_set_0/terrain_{i}/name = "{name}"')
        out.append(f"terrain_set_0/terrain_{i}/color = {TERRAIN_COLORS[i]}")
    for i in range(len(SOURCES)):
        out.append(f'sources/{i} = SubResource("src{i}")')
    path = os.path.join(ROOT, "assets/tiles/tileset.tres")
    open(path, "w").write("\n".join(out) + "\n")
    print("wrote", path, len(out), "lines")


def gen_hero_frames():
    """SpriteFrames from the NinjaGreen Separate sheets: columns = down/up/left/right, rows = frames."""
    DIRS = ["down", "up", "left", "right"]
    anims = {  # name -> (file, fps, loop)
        "idle": ("idle.png", 4, True), "walk": ("walk.png", 8, True), "roll": ("roll.png", 12, False),
        "push": ("push.png", 6, True), "swim": ("swim.png", 6, True), "attack": ("attack.png", 12, False),
    }
    ext, subs, frames = [], [], []
    for name, (f, fps, loop) in anims.items():
        im = Image.open(os.path.join(ROOT, "assets/hero", f))
        cols, rows = im.size[0] // 32, im.size[1] // 32
        ext.append(f'[ext_resource type="Texture2D" path="res://assets/hero/{f}" id="{name}"]')
        for d in range(min(cols, 4)):
            ids = []
            for r in range(rows):
                sid = f"{name}_{DIRS[d]}_{r}"
                subs.append(f'[sub_resource type="AtlasTexture" id="{sid}"]\natlas = ExtResource("{name}")\nregion = Rect2({d*32}, {r*32}, 32, 32)\n')
                ids.append(sid)
            fl = ", ".join('{\n"duration": 1.0,\n"texture": SubResource("%s")\n}' % i for i in ids)
            frames.append('{\n"frames": [%s],\n"loop": %s,\n"name": &"%s_%s",\n"speed": %s.0\n}' % (fl, "true" if loop else "false", name, DIRS[d], fps))
    out = [f'[gd_resource type="SpriteFrames" load_steps={len(ext)+len(subs)+1} format=3]', ""] + ext + [""] + subs + ["[resource]", "animations = [" + ", ".join(frames) + "]"]
    path = os.path.join(ROOT, "assets/hero/hero_frames.tres")
    open(path, "w").write("\n".join(out) + "\n")
    print("wrote", path)


if __name__ == "__main__":
    gen_tileset(debug="--debug" in sys.argv)
    gen_hero_frames()

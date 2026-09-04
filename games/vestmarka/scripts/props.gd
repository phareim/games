## Prop catalogue: one map character (or `prop ... kind=`) -> how to draw and collide it.
## Props are Sprite2D + StaticBody2D built by MapBuilder, positioned at the bottom
## centre of the sprite so Y-sorting against the player works.
class_name Props

const NATURE := "res://assets/tiles/nature.png"
const HOUSE := "res://assets/tiles/house.png"
const DUNGEON := "res://assets/tiles/dungeon.png"
const ELEMENT := "res://assets/tiles/element.png"

## region: Rect2i in the sheet (pixels). body: Rect2 collider relative to the base
## point (0,0 = bottom centre of the sprite); omit for walk-through props.
## light: [color, radius px, energy, flicker?] adds a PointLight2D (at light_offset from the base).
const CATALOGUE := {
	# map characters
	"T": {"tex": NATURE, "region": Rect2i(0, 0, 32, 32), "body": Rect2(-6, -8, 12, 8)},       # round tree
	"P": {"tex": NATURE, "region": Rect2i(32, 0, 32, 32), "body": Rect2(-6, -8, 12, 8)},      # pine
	"D": {"tex": NATURE, "region": Rect2i(64, 0, 32, 32), "body": Rect2(-6, -8, 12, 8)},      # autumn tree
	"G": {"tex": NATURE, "region": Rect2i(48, 32, 48, 48), "body": Rect2(-10, -10, 20, 10)},  # big green tree
	"Y": {"tex": NATURE, "region": Rect2i(240, 32, 48, 48), "body": Rect2(-10, -10, 20, 10)}, # big yellow tree
	"K": {"tex": NATURE, "region": Rect2i(144, 32, 48, 48), "body": Rect2(-10, -10, 20, 10)}, # big pink tree
	"W": {"tex": NATURE, "region": Rect2i(96, 32, 48, 48), "body": Rect2(-10, -10, 20, 10)},  # big white tree
	"N": {"tex": NATURE, "region": Rect2i(0, 32, 48, 48), "body": Rect2(-10, -10, 20, 10)},   # big pine
	"B": {"tex": NATURE, "region": Rect2i(0, 160, 16, 16), "body": Rect2(-6, -8, 12, 8)},     # bush
	"b": {"tex": NATURE, "region": Rect2i(16, 160, 16, 16), "body": Rect2(-6, -8, 12, 8)},    # round bush
	"g": {"tex": NATURE, "region": Rect2i(32, 160, 16, 16)},                                  # grass tuft
	"h": {"tex": NATURE, "region": Rect2i(64, 160, 16, 16)},                                  # tall grass
	"f": {"tex": NATURE, "region": Rect2i(0, 176, 16, 16)},                                   # sunflower
	"F": {"tex": NATURE, "region": Rect2i(48, 176, 16, 16)},                                  # red flower
	"w": {"tex": NATURE, "region": Rect2i(96, 176, 16, 16)},                                  # white flower
	"s": {"tex": NATURE, "region": Rect2i(0, 128, 32, 32), "body": Rect2(-10, -10, 20, 10)},  # stump
	"R": {"tex": NATURE, "region": Rect2i(240, 160, 28, 44), "body": Rect2(-12, -10, 24, 10)}, # big brown rock
	"r": {"tex": NATURE, "region": Rect2i(272, 208, 16, 16), "body": Rect2(-6, -6, 12, 6)},   # small rock
	"S": {"tex": NATURE, "region": Rect2i(240, 224, 28, 44), "body": Rect2(-12, -10, 24, 10)}, # big grey rock
	"c": {"tex": DUNGEON, "region": Rect2i(128, 48, 16, 16), "body": Rect2(-6, -6, 12, 6), "light": [Color(0.55, 0.85, 1.0), 44.0, 1.1]},   # crystal
	"t": {"tex": DUNGEON, "region": Rect2i(32, 32, 16, 16), "body": Rect2(-5, -5, 10, 5), "light": [Color(1.0, 0.72, 0.4), 60.0, 1.4, true]},    # torch bowl
	"q": {"tex": DUNGEON, "region": Rect2i(48, 48, 16, 16), "body": Rect2(-5, -5, 10, 5)},    # eye statue
	"o": {"tex": DUNGEON, "region": Rect2i(0, 32, 16, 16), "body": Rect2(-7, -7, 14, 7), "light": [Color(0.5, 0.7, 1.0), 40.0, 1.0]},     # blue crystal block
	# `prop x y kind=...` objects (multi-tile)
	"house_a": {"light": [Color(1.0, 0.8, 0.5), 36.0, 0.9, true], "light_offset": Vector2(0, -12), "tex": HOUSE, "region": Rect2i(0, 0, 80, 48), "body": Rect2(-40, -30, 80, 30)},
	"house_b": {"light": [Color(1.0, 0.8, 0.5), 36.0, 0.9, true], "light_offset": Vector2(0, -12), "tex": HOUSE, "region": Rect2i(80, 0, 80, 48), "body": Rect2(-40, -30, 80, 30)},
	"house_c": {"light": [Color(1.0, 0.8, 0.5), 36.0, 0.9, true], "light_offset": Vector2(0, -12), "tex": HOUSE, "region": Rect2i(160, 0, 80, 48), "body": Rect2(-40, -30, 80, 30)},
	"house_red": {"light": [Color(1.0, 0.8, 0.5), 36.0, 0.9, true], "light_offset": Vector2(0, -12), "tex": HOUSE, "region": Rect2i(240, 0, 80, 48), "body": Rect2(-40, -30, 80, 30)},
	"shop": {"tex": HOUSE, "region": Rect2i(320, 0, 64, 48), "body": Rect2(-32, -30, 64, 30)},
	"cave_mouth": {"light": [Color(0.6, 0.7, 1.0), 30.0, 0.8], "light_offset": Vector2(0, -10), "tex": HOUSE, "region": Rect2i(0, 128, 32, 32), "body": Rect2(-16, -14, 32, 6)},
	"well": {"tex": HOUSE, "region": Rect2i(464, 208, 32, 32), "body": Rect2(-12, -12, 24, 12)},
	"torii": {"tex": HOUSE, "region": Rect2i(16, 80, 32, 32)},
	"fence_h": {"tex": HOUSE, "region": Rect2i(144, 128, 48, 16), "body": Rect2(-24, -8, 48, 8)},
	"sign": {"tex": HOUSE, "region": Rect2i(112, 48, 16, 16), "body": Rect2(-6, -6, 12, 6)},
}

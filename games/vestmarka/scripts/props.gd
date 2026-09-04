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
	"R": {"tex": NATURE, "region": Rect2i(208, 160, 48, 48), "body": Rect2(-16, -14, 32, 14)},# big brown rock
	"r": {"tex": NATURE, "region": Rect2i(192, 208, 16, 16), "body": Rect2(-6, -6, 12, 6)},   # small rock
	"S": {"tex": NATURE, "region": Rect2i(208, 224, 48, 48), "body": Rect2(-16, -14, 32, 14)},# big grey rock
	"c": {"tex": DUNGEON, "region": Rect2i(128, 48, 16, 16), "body": Rect2(-6, -6, 12, 6)},   # crystal
	"t": {"tex": DUNGEON, "region": Rect2i(32, 32, 16, 16), "body": Rect2(-5, -5, 10, 5)},    # torch bowl
	"q": {"tex": DUNGEON, "region": Rect2i(48, 48, 16, 16), "body": Rect2(-5, -5, 10, 5)},    # eye statue
	"o": {"tex": DUNGEON, "region": Rect2i(0, 32, 16, 16), "body": Rect2(-7, -7, 14, 7)},     # blue crystal block
	# `prop x y kind=...` objects (multi-tile)
	"house_a": {"tex": HOUSE, "region": Rect2i(0, 0, 80, 48), "body": Rect2(-40, -30, 80, 30)},
	"house_b": {"tex": HOUSE, "region": Rect2i(80, 0, 80, 48), "body": Rect2(-40, -30, 80, 30)},
	"house_c": {"tex": HOUSE, "region": Rect2i(160, 0, 80, 48), "body": Rect2(-40, -30, 80, 30)},
	"house_red": {"tex": HOUSE, "region": Rect2i(240, 0, 80, 48), "body": Rect2(-40, -30, 80, 30)},
	"shop": {"tex": HOUSE, "region": Rect2i(320, 0, 64, 48), "body": Rect2(-32, -30, 64, 30)},
	"cave_mouth": {"tex": HOUSE, "region": Rect2i(0, 128, 32, 32), "body": Rect2(-16, -14, 32, 6)},
	"well": {"tex": HOUSE, "region": Rect2i(464, 208, 32, 32), "body": Rect2(-12, -12, 24, 12)},
	"torii": {"tex": HOUSE, "region": Rect2i(16, 80, 32, 32)},
	"fence_h": {"tex": HOUSE, "region": Rect2i(144, 128, 48, 16), "body": Rect2(-24, -8, 48, 8)},
	"sign": {"tex": HOUSE, "region": Rect2i(112, 48, 16, 16), "body": Rect2(-6, -6, 12, 6)},
}

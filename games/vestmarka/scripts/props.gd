## Prop catalogue: one map character -> how to draw and collide it.
## Props are Sprite2D + StaticBody2D built by MapBuilder, positioned at the bottom
## centre of the sprite so Y-sorting against the player works.
class_name Props

const NATURE := "res://assets/tiles/nature.png"

## region: Rect2i in the sheet (pixels). body: Rect2 collider relative to the base
## point (0,0 = bottom centre of the sprite); omit for walk-through props.
const CATALOGUE := {
	"T": {"tex": NATURE, "region": Rect2i(0, 0, 32, 32), "body": Rect2(-6, -8, 12, 8)},       # round tree
	"P": {"tex": NATURE, "region": Rect2i(32, 0, 32, 32), "body": Rect2(-6, -8, 12, 8)},      # pine
	"D": {"tex": NATURE, "region": Rect2i(64, 0, 32, 32), "body": Rect2(-6, -8, 12, 8)},      # dead tree
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
}

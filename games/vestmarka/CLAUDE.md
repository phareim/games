# Vestmarka — top-down explore-and-discover RPG (Godot 4.7, web)

Live: https://games.phareim.no/vestmarka/ · Started 2026-09-04 · Art: Ninja Adventure (pixel-boy, CC0), see
`CREDITS.md`. Aesthetic goal: SNES Zelda, modernised through light and motion, not resolution.

## Rendering

320x180 viewport, `canvas_items` stretch with integer scale (3x at 960x540, 4x at 1280x720), nearest
filtering, pixel snap. `gl_compatibility` (WebGL 2). Tiles 16x16; hero frames 32x32.

## Maps are text (`maps/*.txt`)

One character per tile; `//` lines are comments; short rows are padded with grass. `MapBuilder`
(`scripts/map_builder.gd`, `@tool`) paints grass directly, autotiles the blobs with
`set_cells_terrain_connect` (never grass: the solver is far too slow for thousands of cells in
wasm — a 60x40 map went from a browser hang to 250 ms), and instantiates props as Y-sorted
sprites with `StaticBody2D` colliders.

| char | meaning | | char | meaning |
|---|---|---|---|---|
| `.` | grass (random detail variants) | | `T` `P` `D` | round tree / pine / dead tree (2x2) |
| `:` | dirt path (terrain 1) | | `G` `Y` `K` `W` `N` | big trees 3x3 (green/yellow/pink/white/pine) |
| `~` | water (terrain 2, collides on the wet part) | | `B` `b` | bush / round bush |
| `#` | cliff plateau (terrain 3, solid) | | `g` `h` `f` `F` `w` | grass tufts, flowers (walk-through) |
| `@` | player spawn | | `s` `R` `S` `r` | stump, big brown/grey rock, small rock |

Prop definitions (sheet region + collider) live in `scripts/props.gd`. Props are placed at the
cell's bottom centre; a 2x2 tree therefore occupies its cell and the one above.

## Generated resources — do not hand-edit

`tools/gen_resources.py` (Python + Pillow) writes `assets/tiles/tileset.tres` and
`assets/hero/hero_frames.tres`. Terrain peering bits come from sampling the tile edges/corners
(green = grass, else the block's terrain); the strips are listed by hand; only the trusted
subset of each pixel-boy blob block is used (`BLOB_CELLS`) because the diagonal/multi-corner
tiles sample as duplicates of the plain tile and filled ponds with holes (2026-09-04).
Cliff bits are hand-listed (`cliff` dict). Re-run after touching the PNGs or the lists.
Assets themselves come from `bin/import-ninja-assets` (repo root), which extracts exactly
the files used from the two zips in `~/tmp/godot/`.

## Hero and camera

`scenes/player.tscn` + `scripts/player.gd`: `CharacterBody2D` (floating), collider 10x6 at the
feet, `AnimatedSprite2D` offset -10 so the 32px frame stands on the tile row. Animations are
`<walk|idle|roll|push|swim|attack>_<down|up|left|right>`; columns in the sheets are directions
(down, up, left, right), rows are frames. Speed 70, run 115 (Shift/X). Camera child with
smoothing; `World` sets its limits from the map size.

## Verify

```
godot --headless --path games/vestmarka --quit-after 60      # script errors, "MapBuilder: ... built in N ms"
bin/export vestmarka                                          # .pck ~10 MB (music is most of it)
python3 -m http.server 8765 --directory dist &                # local serving
bin/screenshot vestmarka --url http://localhost:8765/vestmarka/ --keys ArrowRight:1600,ArrowUp:1400
```
`--keys` holds keys in sequence (Puppeteer) so the screenshot shows the hero after walking.
Export must include `maps/*.txt` (`include_filter` in `export_presets.cfg`) — plain text is not a
resource and was silently dropped the first time.

## Roadmap (plan of 2026-09-04)

1. ✅ Walk around: map from text, autotiles, props, hero, camera, collisions.
2. Discover: interactables, dialog box (pack UI + font), signs, chests, NPCs, `GameState` with flags
   saved to `user://` (IndexedDB on web), "funn n/m" HUD.
3. Areas: teleporters with fade, forest and cave maps, house interiors, music per map, SFX.
4. Polish: day/night `CanvasModulate`, `PointLight2D` torches, water ripples, `CPUParticles2D`.
Later: touch controls, enemies, more biomes, swap to a bought tileset (same 16px grid).

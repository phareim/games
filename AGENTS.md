# games — games.phareim.no: the arcade front page and Godot web exports

Monorepo for small games and interactive pieces built in **Godot 4**, exported to web and
served as static files by nginx on Sleeper. Created 2026-09-04.

## Layout

- `games/<name>/` — one Godot project per game (`project.godot`, `export_presets.cfg` with a
  `Web` preset, scenes, scripts). Projects are text; Claude edits `.gd`/`.tscn` directly.
  Visual scene work happens in the Godot editor on the Mac, shared via git.
- `bin/export [name ...]` — headless import + export to `dist/<name>/` and gzip-precompress
  `.wasm/.pck/.js/.html`. No args = every game. ~15 s per small game on Sleeper.
- `bin/deploy` — export all, then rsync `dist/` + `site/` to `/var/www/games`.
- `site/` — the front page, **Phareim Arcade** (2026-09-24): an overview of the games on
  phareim.no in the Neon Dreams look (the games' own design system, skill `neon-dreams-design`).
  Plain HTML/CSS in `index.html`, no framework, no build. See "Front page" below.
- `dist/` — build output, gitignored.
- `bin/import-ninja-assets` — copies the exact Ninja Adventure (CC0) files `vestmarka` uses from the
  zips in `~/tmp/godot/` (not in git, 126 MB) into `games/vestmarka/assets/`.

## Front page (`site/`)

- **What it lists** (verified 2026-09-24): the nine live game themes on phareim.no, each linked to
  `https://phareim.no/?theme=<id>`. Adventures as two wide features: Neon Shrine (`zelda`),
  Another Shore (`anotherworld`). The arcade as seven cabinets: Galaga, Breakout, R-Type, Space
  Invaders, Star Fox, OutRun, Tetris. A "back room" strip: Hall of Fame (`leaderboard`) and Hangar
  (`hangar`). Hero and footer link to `https://phareim.no` as "the portal" (phareim.no opens on a
  walkable neon town with an arcade hall, since 2026-09-24). Pitches and controls come from
  `~/github/phareim.no/docs/games/*.md` and each game's own title-screen hints; copy is English.
- **Godot games are deployed but not listed** (Petter's decision, 2026-09-24): `/vestmarka/` and
  `/pong/` still come from `dist/` on every deploy; the page just doesn't link them.
- **Look**: Neon Dreams tokens inline in `index.html` (cyan = interface, pink = call to action,
  gold = reward only; violet-black ground, dark only). Fonts self-hosted in `site/fonts/`: Space
  Grotesk 300/400 (prose), Space Mono 400/700 (machine text), Orbitron 900 (titles), OFL, see
  `fonts/OFL.txt`. Backdrop: `js/backdrop.js` draws the games' horizon on a fixed canvas with a
  heartbeat; `js/neonHorizon.js` + `js/mountainTerrain.js` are verbatim copies from
  `phareim.no/themes/base/` (re-copy when the games' backdrop changes). `prefers-reduced-motion`
  draws one still frame and stops the blink. Layout: cabinets are a centred flex row of 4/3/2/1
  columns at ≥1240/980/600 px; nothing scrolls sideways down to 360 px.
- **Screenshots**: `site/shots/<theme-id>.webp` (1280×800 features, 960×600 cabinets, 960×540
  back room; whole folder ~0.4 MB). Captured from the live site with puppeteer-core + snap
  Chromium at 1280×800, site chrome hidden by injected CSS (`.theme-pager, .radio-widget,
  .esc-hold`); action games were started with Enter and flown for a few seconds. Opening
  `?theme=leaderboard` or `?theme=hangar` in a fresh browser **creates a player on the live
  Hall of Fame and orders an avatar painting**, so reuse those two shots instead of retaking them.
- **Add a game**: capture `shots/<id>.webp`, copy an `<article class="cab">` (score game) or
  `<article class="feature">` (long game with saves) in `index.html`, set title, one tag line,
  a two-line pitch, KEYS and TOUCH lines from the game's own hints, and the `?theme=<id>` link on
  the `▶ Play` link (it is stretched over the whole cabinet). Update the counts in the hero and
  section intros.

## Games (Godot, unlisted)

- **pong** — the first export, one scene.
- **vestmarka** — top-down RPG, maps as text, generated tileset; see `games/vestmarka/AGENTS.md`.

## Toolchain (verified 2026-09-04)

- Godot **4.7.2** headless binary: `~/opt/godot/godot` (symlink → `godot-4.7.2`; also on PATH as
  `godot` via `~/.local/bin`). No GPU needed; the editor GUI does not run here.
- Web export templates only (the full 1.2 GB `.tpz` is not kept):
  `~/.local/share/godot/export_templates/4.7.2.stable/web_*.zip`.
  Upgrading Godot = new binary + matching `web_*` templates from the release `.tpz`.
- Default preset is **single-threaded** (`variant/thread_support=false`) — no COOP/COEP headers
  needed, works on Safari/iOS. Threaded builds need the two headers commented out in the nginx site.
- Renderer `gl_compatibility` (WebGL 2). Keep it for web.

## Serving and deploy

- nginx site `/etc/nginx/sites-available/games` → root `/var/www/games`, `gzip_static on`,
  `Cache-Control: no-cache` (exports reuse file names), TLS via certbot. DNS: A record
  `games` → Sleeper, dns-only (not proxied), like sleeper/api/pilot.
- **Deploy on push to main**: GitHub webhook on `phareim/games` → `sleeper.phareim.no/deploy`
  (the `sleeper-deploy` hook, port 3026) runs `bin/deploy`. Manual: `bin/deploy`.
- Sizes: an empty Godot 4.7 web export is ~40 MB `.wasm` (10 MB gzipped). This is why the
  site lives on nginx here and not on Cloudflare Pages (25 MiB per-file limit).

## New game checklist

1. `cp -r games/pong games/<name>`, rename in `project.godot`, fix `export_path` in
   `export_presets.cfg` (`../../dist/<name>/index.html`), delete `.godot/`.
2. `bin/export <name>` → check `dist/<name>/index.wasm` exists.
3. Smoke-test logic headless: `godot --headless --path games/<name> --quit-after 120`
   (script errors print here; rendering is a dummy).
4. The front page does not list Godot games (2026-09-24); link it there only if Petter asks. Commit, push — the webhook deploys.
5. `bin/screenshot <name>` (Puppeteer + snap Chromium with SwiftShader; `--click x,y` to get past the title, `--url` for a local server, `--keys ArrowRight:1500,ArrowUp:800` to hold keys in sequence before the shot; waits for `domcontentloaded` because Godot's shell never reaches `networkidle0` on bigger games, 2026-09-04) writes `dist/screens/<name>.png` and prints console errors. Read the PNG. Snap Chromium can only write inside non-hidden paths under `~`. Dependabot alert #1 (extract-zip, no fix) is dismissed as not used — puppeteer-core never downloads a browser here (2026-09-04).

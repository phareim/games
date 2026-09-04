# games — Godot web exports on games.phareim.no

Monorepo for small games and interactive pieces built in **Godot 4**, exported to web and
served as static files by nginx on Sleeper. Created 2026-09-04.

## Layout

- `games/<name>/` — one Godot project per game (`project.godot`, `export_presets.cfg` with a
  `Web` preset, scenes, scripts). Projects are text; Claude edits `.gd`/`.tscn` directly.
  Visual scene work happens in the Godot editor on the Mac, shared via git.
- `bin/export [name ...]` — headless import + export to `dist/<name>/` and gzip-precompress
  `.wasm/.pck/.js/.html`. No args = every game. ~15 s per small game on Sleeper.
- `bin/deploy` — export all, then rsync `dist/` + `site/` to `/var/www/games`.
- `site/` — the landing page (`index.html`) in the **Tufte Viz** look (warm/midnight paper,
  ET Book from `site/fonts/`, hairline rules, crimson only on hover; tokens copied inline from the
  `tufte-viz` skill, 2026-09-04). No framework, no build. **Add an `<li>` per new game** with name,
  date and a one-line note; keep the accent for hover only.
- `dist/` — build output, gitignored.
- `bin/import-ninja-assets` — copies the exact Ninja Adventure (CC0) files `vestmarka` uses from the
  zips in `~/tmp/godot/` (not in git, 126 MB) into `games/vestmarka/assets/`.

## Games

- **pong** — the first export, one scene.
- **vestmarka** — top-down RPG, maps as text, generated tileset; see `games/vestmarka/CLAUDE.md`.

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
4. Add a row in `site/index.html`. Commit, push — the webhook deploys.
5. `bin/screenshot <name>` (Puppeteer + snap Chromium with SwiftShader; `--click x,y` to get past the title, `--url` for a local server, `--keys ArrowRight:1500,ArrowUp:800` to hold keys in sequence before the shot; waits for `domcontentloaded` because Godot's shell never reaches `networkidle0` on bigger games, 2026-09-04) writes `dist/screens/<name>.png` and prints console errors. Read the PNG. Snap Chromium can only write inside non-hidden paths under `~`. Dependabot alert #1 (extract-zip, no fix) is dismissed as not used — puppeteer-core never downloads a browser here (2026-09-04).

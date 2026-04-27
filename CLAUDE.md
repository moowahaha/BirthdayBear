# CLAUDE.md

Notes for Claude Code sessions on this repo. Read this before making changes.

## What this is

A static, single-file HTML5 canvas game ("Birthday Bear") — a Lemmings-style puzzle where the player places wooden blocks to guide pixel-art characters (the "Lilians") to a birthday cake while a parachuting cat ("Skittles") descends to eat it. Built as a personal birthday gift, deployed to Google Cloud Run. **Not a framework project** — no build step, no package.json, no node_modules. The whole game is `index.html`.

## Repository shape

- `index.html` — markup + `<canvas>` + ~1500 lines of vanilla JS in one IIFE. All gameplay, rendering, audio, input, and level data live here.
- `assets/` — PNG sprites, MP3 music, splash image. Some folders contain spaces (e.g. `assets/splash screen/`) — handle as quoted paths in shell, fine in URLs.
- `Dockerfile` + `nginx.conf` — container for Cloud Run. nginx listens on `8080` (Cloud Run's default `$PORT`), with 1y immutable cache for assets and `no-cache` for `index.html`. Dockerfile also runs `chmod -R a+rX` on the served tree so any asset added with restrictive perms (a real bug we hit with `cake.png`) doesn't 403.
- `Makefile` — `make build`, `make serve`, `make deploy PROJECT=...`. Targets the host's `gcloud` CLI directly (no Docker wrapper around it).
- Ignore files: `.gitignore`, `.dockerignore`, `.gcloudignore` — keep these in sync if you add new build artifacts.

There are no tests. There is no linter. Diagnostic warnings from the IDE about unresolved `bearSprites.stand` etc. are false positives — the IDE can't follow the dynamic property keys.

## Game architecture (inside `index.html`)

- Canvas is `320x240` (true 4:3 internal resolution), scaled fluidly via JS to fill the visible viewport.
- Tile grid: `20 x 15` columns/rows, `TILE = 16`px each. Levels are authored at 16-char widths and **runtime-padded to 20** in `loadLevel`, so existing 16-char layouts still work — only the bonus crazy level is authored at the full 20.
- Levels are stored as an array of strings (typically 15 long, 16 chars each) in `LEVELS[]`. Glyphs: `.` empty, `#` solid, `S` spawn, `G` goal (also solid). Anything else is undefined.
- Player-placed blocks live in a `Set<string>` of `'col,row'` keys (`userBlocks`). Clicking a placed block calls `spawnExplosion` and removes it.
- `levelState` machine: `'splash' | 'playing' | 'won' | 'failed' | 'skittlesAte' | 'gameover'`. `splash` is the initial state on every page load. There's no longer a separate `crazyPrompt` — winning the penultimate level routes straight to `gameover` and the gameover screen itself offers crazy mode (left tap) vs play again (right tap).
- After clearing crazy mode, `crazyCleared` flips to `true` and the gameover screen drops the `CRAZY MODE` button (showing only `PLAY AGAIN`). Reset on `resetToSplash()`.
- Lilians (still called `bears` / `bearSprites` in code — historical naming, do not rename without good reason) are simple objects in `bears[]` with `x, y, vy, facing, onGround, alive, saved, dying, anim`. Speed is `0.256` px/frame. Direction is randomized at spawn.
- Multi-spawn: `spawnPositions[]` holds every `'S'` tile. `spawnWave()` emits one Lilian per door per tick — single-door levels behave as before, crazy mode emits 5 simultaneously every 70 frames.
- Per-level bear count: `def.bears` overrides the default `1 + idx`. Crazy mode uses `bears: 25`.
- Cake landing detection: if the **foot tile** of a Lilian is `G`, they're saved. `G` is solid for collision so they walk onto it like any other tile.
- One death = instant level fail (no waiting for the rest of the spawn queue).
- **Skittles**: parachuting cat in `assets/skittles/`. Toggles between two poses every 1–3 s. Descends linearly from above the cake to the cake's top edge (her bottom = cake top is the contact frame). Duration: **35 s on regular levels, 30 s on crazy mode** (set in `loadLevel` based on `idx === LEVELS.length - 1`). Reaches the cake → `explodeCake()` + state `skittlesAte`.
- **Cake explosion**: `explodeCake()` fires both on Skittles arrival (failure) and on the last-Lilian save (celebration). Sets `cakeExploded = true` so `drawCake` suppresses the sprite + flame.

## Things that look like bugs but aren't

- **Sprite display widths differ between frames.** The walk-1/walk-2/stand/jump PNGs have different canvas widths (293, 268, 280, 328) but the same height. `drawBear` derives display width from each sprite's natural aspect ratio at a fixed `H_D = 14`. Don't force a uniform width or the figure will jitter between frames.
- **`Cmd+R` is allowed to refresh the page.** The keydown handler bails out early if any modifier (`metaKey`, `ctrlKey`, `altKey`) is held — otherwise plain `R` would `preventDefault()` the browser's refresh shortcut and just restart the level instead. Don't undo this guard.
- **Hidden file `assets/splash screen/splash screen.png`** has spaces in the path. The `<img>` and `Image()` resolve it correctly because the browser percent-encodes spaces. Don't rename without updating `index.html`.
- **`startMusic()` only calls `play()` if paused.** Calling `play()` on an already-playing element causes overlapping playback in some browsers. The current implementation (`currentTime = 0` always; `play()` only when paused) was the result of two prior bug reports — don't "simplify" it back.
- **Music routes through Web Audio** via `MediaElementAudioSourceNode → GainNode → destination`. Without that, iOS Safari ignores `HTMLAudioElement.volume` and the track plays at full level on mobile. The `MUSIC_GAIN` constant (currently `0.04`) is the source of truth for volume.
- **`pageshow` listener with `event.persisted`** resets state to splash if the page is restored from bfcache. Without this, browser back/forward (and refresh in Safari) skips the splash screen.
- **Mobile centering**: the wrap div is `position: fixed; top:0; left:0; width:100%; height:100%`. We measure `wrap.clientWidth/clientHeight` (visible viewport) instead of `window.innerHeight` (which on iOS includes the URL-bar area and pushes the canvas below visible center). Don't change to `100vh` without verifying mobile layout.
- **Skittles' `endY` accounts for both her sprite height and the cake sprite height** — `goal.row * TILE - CAKE_DRAW_H + 1 - SKITTLES_DRAW_H` — so the explosion fires the moment her feet contact the cake's top edge, not when she's fully descended past it.
- **Level `LEVELS[]` map strings can be 16 or 20 chars wide.** `loadLevel` pads short rows to 20 with `.`s. The crazy level (`LEVELS[7]`) is the only one authored at the full 20. Levels rely on specific column positions for solvability — verify by tracing if you change platform layouts.
- **Win check is guarded with `levelState === 'playing'`** to prevent it from overriding a `skittlesAte` state set earlier in the same frame.

## Audio

Three mechanisms, **don't mix them up**:

- **SFX** — Web Audio `OscillatorNode`s constructed on demand in `beep()` (and `weeSfx()` for the slide-whistle on falling). Tiny one-shot blips. Volumes around `0.04`–`0.08` gain.
- **Background music** — single `Audio` element loaded from `assets/music/Birthday Cartridge.mp3`, `loop=true`, routed through Web Audio `GainNode` so iOS respects volume. Restarts at 0 on each `loadLevel` via `startMusic()`. First user gesture starts it (autoplay policy).
- **Mute button** — top-left HTML button, toggles via `applyMute()`. Sets `music.muted` AND zeros `musicGain.gain`. Persisted to `localStorage[birthday-bear-muted]`. Currently affects music only, not SFX.

## Visuals worth noting

- **Sky background** is a vertical 6-band gradient from `#5c94fc` → `#a8d8fc`.
- **Clouds** drift slowly across the upper area; wrap when they leave the right edge.
- **Sun mascot** in top-right corner: toggles between `sun_1` and `sun_2` every 3–5 seconds. Switches to `sun_stunned` for 1.5s when a Lilian dies. Stays still when stunned (don't add jitter — that was reverted on user feedback).
- **Tiles** render grass-on-top + soil-below. Grass cap is suppressed if the tile directly above is also solid (so stacked platforms look right).
- **Cake flame** is a 4-phase pixel animation drawn over the cake sprite — not part of the PNG. Suppressed when `cakeExploded`.
- **Cake explosion** is 36 pink/yellow/white particles + sub-bass thud SFX.
- **Splash screen** uses `assets/splash screen/splash screen.png`, instructions in the 5x5 pixel font (`PLACE BLOCKS TO SAVE THE WANDERING LILIANS / STEER THEM TO THE CAKE / ...BEFORE SKITTLES EATS IT!`), blinking `TAP TO START`, dynamic copyright year.
- **HAPPY BIRTHDAY screen** (`gameover`): bouncing rainbow text, custom message lines (`GO BEAR! 12 YEARS A CHAMPION` / `LOVE YOU!!`), two button-style tap zones for `CRAZY MODE` and `PLAY AGAIN`. After crazy is cleared, only the centered `PLAY AGAIN` button is shown.
- **Skittles** is drawn from `assets/skittles/skittles-1.png` and `skittles-2.png` (parachuting cat) at 28 px tall, alternating between the two every 1–3 seconds.
- **HUD**: shows `LVL N` (or `CRAZY` for the bonus level) on the left, `SAVED X/Y` next to it, sun on the right with `Xn` lost-counter beneath it when applicable.

## Deployment

- **Project:** `sudoku-elf-1775657065`. Same project as the user's other Cloud Run games (`sudoku-elf`, `bunny-bear`).
- **Region:** `us-central1`.
- **Service:** `birthday-bear`. URL: `https://birthday-bear-505037978186.us-central1.run.app`.
- **Custom domain:** `birthday.hardisty.me`, mapped via `gcloud beta run domain-mappings`. CNAME at Squarespace points to `ghs.googlehosted.com.`. SSL auto-provisioned by Google.
- **Deploy command:** `make deploy PROJECT=sudoku-elf-1775657065`.

If asked about deployment, do not invent regions or project IDs — these are the canonical values.

## Working style preferences

- The user iterates rapidly with small visual / gameplay tweaks. Default to surgical edits over rewrites.
- **No emojis** in code or files unless explicitly requested.
- **Don't add framework dependencies** (React, build tools, etc.). The single-file simplicity is a feature.
- **Confirm before deploying.** `make deploy` creates billable cloud resources — even though they scale to zero, ask before pushing unsolicited changes to production.
- **Levels are tuned by hand.** Trace bear paths through changes mentally before claiming a level is solvable. The user notices when a level "feels" wrong even if it's technically beatable.
- **Don't show keyboard hints in-game** (e.g. "PRESS R" / "PRESS SPACE"). Mobile users have no keyboard, so on-screen prompts say "TAP" only. Keyboard shortcuts (R, Space, Enter, Y, N) still work for desktop convenience.

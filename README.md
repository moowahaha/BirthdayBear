# Birthday Bear

A Lemmings-style pixel-art puzzle game built for the browser. Place blocks to guide each Lilian safely to the cake — before Skittles eats it.

**Live:** <https://birthday.hardisty.me> (or the Cloud Run URL: <https://birthday-bear-505037978186.us-central1.run.app>)

## Playing

- The Lilians spawn from a portal and walk in a random direction.
- They reverse when they bump into a wall and fall when they walk off an edge (with a cute "wee!").
- Click / tap an empty tile to **place** a wooden block. Click / tap a placed block to **destroy** it (with a satisfying explosion).
- Get every Lilian onto the cake's platform to clear the level. The cake explodes in celebration when the last one arrives.
- One Lilian falls — level over.
- **Skittles**, a parachuting cat, descends from the sky on each level. If she reaches the cake before all Lilians are saved, she eats it and the level is over.

There are seven regular levels, each adding one more Lilian to wrangle. Beat the last one to see the birthday message — and a chance to take on **Crazy Mode**: 5 doors, 25 Lilians, very hard. Crazy mode keeps Skittles' descent at 30 s instead of the usual 35 s.

### Controls

| Action | Touch / Mouse |
|---|---|
| Place / destroy block | Click / tap a tile |
| Begin / advance / retry | Tap (or Space / Enter on desktop) |
| Toggle music mute | Top-left **MUTE** button |

(Holding modifier keys never hijacks the game — `Cmd+R` / `Ctrl+R` refresh the browser as expected.)

## Tech stack

- Single static `index.html` — vanilla JavaScript, HTML5 Canvas, Web Audio for SFX, `<audio>` element routed through a `GainNode` for music
- Pixel-art assets in `assets/` (Lilian sprites, cake, sun, splash, Skittles, music)
- Served from an `nginx:alpine` container on Google Cloud Run
- Custom domain via Squarespace DNS → CNAME → `ghs.googlehosted.com`

No build step, no framework, no dependencies.

## Local preview

```bash
make build   # build the docker image
make serve   # run at http://localhost:8080
```

Or just open `index.html` directly in a browser — no server required for development.

## Deployment

```bash
make deploy PROJECT=sudoku-elf-1775657065
```

That runs `gcloud run deploy --source .`, which uploads the source, builds the container with Cloud Build, pushes to Artifact Registry, and rolls out a new Cloud Run revision. The first build takes a couple of minutes; subsequent builds are faster thanks to layer caching.

### Custom domain status

```bash
gcloud beta run domain-mappings describe \
  --domain=birthday.hardisty.me \
  --region=us-central1 \
  --project=sudoku-elf-1775657065
```

Look for `CertificateProvisioned: True`.

## Project structure

```
.
├── index.html          # The whole game (markup + canvas + JS)
├── assets/
│   ├── bear/           # Lilian sprites: stand, walk-1, walk-2, jump
│   ├── cake/           # Goal sprite
│   ├── sun/            # Sky mascot: sun_1, sun_2, sun_stunned
│   ├── skittles/       # Parachuting cat, two poses
│   ├── splash screen/  # Title-screen artwork
│   └── music/          # Looping background music
├── Dockerfile          # nginx:alpine + nginx.conf + static files (chmods world-readable)
├── nginx.conf          # listen 8080, cache headers
├── Makefile            # build / serve / deploy targets
├── CLAUDE.md           # operating notes for future Claude Code sessions
└── .gitignore .dockerignore .gcloudignore
```

## Credits

- Game design and code: Steve Hardisty
- Built with Claude Code as a birthday gift

(c) 2026 Stephen Hardisty

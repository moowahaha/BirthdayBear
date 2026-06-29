# Birthday Bear

A Mebobox game — a Lemmings-style puzzle: place blocks to steer the wandering Lilians to the cake
before Skittles eats it.

This repo is the **source** of the game. It is published to the **Mebobox Library** through the
Mebobox Creator Hub — there is no `manifest.json` here any more; the game's details are entered in
the UI when you upload it.

## Publishing to the Library

1. Sign in at **mebobox.com/library** → **Creator Hub** → **Upload a game**.
2. **Source** (step *Upload*): either upload a **zip of this repo**, or point the Library at this
   public GitHub repository (and pick a branch/tag).
3. **Details** to enter (step *Information*):

   | Field        | Value |
   |--------------|-------|
   | **Name**     | Birthday Bear |
   | **Description** | A Lemmings-style puzzle: place blocks to steer the wandering Lilians to the cake before Skittles eats it. Arrows move, Space places or removes a block. |
   | **Players**  | Single-player |
   | **Cover art** | `assets/cover-art.png` — upload this as the cover in the modal (optional, ≤2 MB) |

4. Tick the consent checkboxes and submit. The Library runs its automatic checks and notifies you of
   the result; on success the game is playable on a Mebobox by its 6-letter code.

## The game

- **Entry point:** `index.html` (the Mebobox loads this).
- Uses the **Mebobox SDK** (`mebobox.min.js`) for the controller; also runs standalone in a
  plain browser for development. Controls: D-pad / arrows to move, A / Space to place or remove a
  block, B to retry.
- **Licence:** Apache-2.0 — see [`LICENSE`](./LICENSE).

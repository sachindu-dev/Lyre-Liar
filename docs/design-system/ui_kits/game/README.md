# Lyre & Liar — Game UI Kit

Hi-fi recreation of the Lyre & Liar game client UI, modeled directly from the Godot `.tscn` scene files and `.gd` scripts. Renders the 360×640 mobile-first viewport with portrait scaling, click-through navigation between menu states, and the full set of in-game overlays.

## Surfaces recreated

1. **Main menu screen 1** — Single Player / Multiplayer / Quit. Title block + brass rule + tagline.
2. **Main menu screen 2** — Map select (Day / Night / Forest).
3. **Main menu screen 3** — Multiplayer options (server address, room code, Host / Join).
4. **In-game HUD** — pause button top-left, countdown timer top-right (single-player only), mobile controls bottom (joystick + JUMP).
5. **Paused overlay** — `PAUSED` + Resume / Main Menu / Quit.
6. **You Died overlay** — Restart / Quit on the crimson wash.
7. **Too Late overlay** — single-player timeout, Restart / Quit on black.
8. **Level Complete overlay** — stats + Replay / Next Level / Main Menu on forest wash.

## How to use this kit

- Open `index.html` in a browser. It opens on the main menu.
- Click any button to advance state. The state machine mirrors `main_menu.gd` exactly.
- Tap the pause `II` button in-game to surface the pause overlay.
- A debug bar at the top right lets you jump straight to Died / Timeout / Complete overlays for art review.

## Components

| File | Purpose |
| --- | --- |
| `App.jsx` | Root state machine — mirrors `main_menu.gd::_update_ui_state`; owns screen/overlay state and the single-player countdown. |
| `Primitives.jsx` | All small shared UI primitives — portrait shell, title block, buttons, the `LineEdit`s, and status line. |
| `MainMenu.jsx` | Composes the three menu screens (initial / map-select / multiplayer). |
| `GameView.jsx` | In-game canvas with parallax background, mobile controls, and HUD (joystick + JUMP + pause + timer). |
| `Overlays.jsx` | All four overlay states — Paused / Died / Timeout / Complete — on a shared centered frame. |

## Notes & limitations

- The actual game has live sprite animation, parallax, and a 16-player networked world. This kit shows the **menu chrome and overlays only**, with a single still parallax frame standing in for the in-game playfield.
- Fonts are substituted (see root `README.md`). Set `--font-display`, `--font-ui`, `--font-mono` to the engine default to revert.
- Logo is the Godot placeholder — flagged.

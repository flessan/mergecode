# Asset Credits

All artwork is stored locally in this repository; the game needs no internet connection at runtime.

## Downloaded artwork — Kenney UI Pack (CC0)

- **Asset:** UI Pack by Kenney Vleugels — approximately 430 interface elements in the complete pack; this project integrates a curated 82-PNG subset needed for its buttons, panels, progress bars, and board slots.
- **Official source:** https://kenney.nl/assets/ui-pack
- **Download mirror used by this workspace:** https://github.com/ereborstudios/kenney-ui-pack (the repository redistributes Kenney's UI Pack and includes Kenney's original `license.txt`; the downloaded pack itself is unchanged apart from selecting the subset used here).
- **Creator/publisher:** Kenney Vleugels / Kenney (www.kenney.nl)
- **License:** Creative Commons CC0 — http://creativecommons.org/publicdomain/zero/1.0/
- **Attribution requirement:** Credit is appreciated but not mandatory under CC0. This credit is retained voluntarily, and Kenney's original license file is preserved at `assets/ui/Kenney/license.txt`.
- **Local files:** `assets/ui/Kenney/*.png` (blue, green, red, yellow, and grey buttons/panels/circles/sliders/status marks) plus `assets/ui/Kenney/license.txt`.
- **Used for:** nine-sliced game buttons throughout the HUD, menus, generator dock, customer orders, and popups; shared grey panels; XP, generator-energy, and mission progress bars; warm board-slot styling.

## Downloaded artwork — Game-Icons (CC BY 3.0)

- **Source:** https://game-icons.net — files fetched from the official GitHub mirror `game-icons/icons` (https://github.com/game-icons/icons)
- **Creators:** Lorc, Delapouite and other game-icons.net contributors (per-file author is the filename prefix, e.g. `lorc_*.svg`, `delapouite_*.svg`)
- **License:** Creative Commons Attribution 3.0 (CC BY 3.0) — https://creativecommons.org/licenses/by/3.0/
- **Processing:** the files as downloaded contain a baked-in black background square; the copies in this repo have that background path removed so the white silhouettes can be tinted/rendered over the game's coloured tiles (a recolouring the licence permits).
- **Attribution requirement:** credit to game-icons.net is required; this file and the in-game Catalog/Help credits satisfy it. Icons may be recoloured (the game renders the black silhouettes tinted over coloured tiles).
- **Used for:** item illustrations (every item in `data/items.json` references one via its `icon` field), and interface icons (coin, energy, shop, crafting, catalog, missions, settings, check, lock, gift, close).

| File | Used as |
|---|---|
| `assets/sprites/game_icons/delapouite_beehive.svg` | Open Source Ecosystem |
| `assets/sprites/game_icons/delapouite_book-pile.svg` | Notepad Draft |
| `assets/sprites/game_icons/delapouite_bookshelf.svg` | Library Bundle |
| `assets/sprites/game_icons/delapouite_cardboard-box-closed.svg` | pnpm Workspace |
| `assets/sprites/game_icons/delapouite_cardboard-box.svg` | npm Package |
| `assets/sprites/game_icons/delapouite_cargo-crate.svg` | Cargo Crate |
| `assets/sprites/game_icons/delapouite_cargo-ship.svg` | Docker Container |
| `assets/sprites/game_icons/delapouite_chart.svg` | CSV Table, Data Science Toolkit |
| `assets/sprites/game_icons/delapouite_check-mark.svg` | ui_check |
| `assets/sprites/game_icons/delapouite_checklist.svg` | Shell Command |
| `assets/sprites/game_icons/delapouite_clockwise-rotation.svg` | CI Pipeline |
| `assets/sprites/game_icons/delapouite_cloud-upload.svg` | SaaS Platform |
| `assets/sprites/game_icons/delapouite_cobra.svg` | Python Script |
| `assets/sprites/game_icons/delapouite_cube.svg` | Unity Project, JavaScript Module |
| `assets/sprites/game_icons/delapouite_database.svg` | SQLite Database |
| `assets/sprites/game_icons/delapouite_desk.svg` | Developer Workstation |
| `assets/sprites/game_icons/delapouite_diamond-trophy.svg` | ui_missions |
| `assets/sprites/game_icons/delapouite_elephant.svg` | PostgreSQL Database |
| `assets/sprites/game_icons/delapouite_energy-tank.svg` | Redis Cache |
| `assets/sprites/game_icons/delapouite_factory-arm.svg` | Automated Software Factory |
| `assets/sprites/game_icons/delapouite_factory.svg` | Data Center |
| `assets/sprites/game_icons/delapouite_files.svg` | Text Record, Text Draft |
| `assets/sprites/game_icons/delapouite_gamepad.svg` | Cross-Platform Game |
| `assets/sprites/game_icons/delapouite_gear-stick.svg` | ui_settings |
| `assets/sprites/game_icons/delapouite_globe-ring.svg` | Global Web Portal, Professional Website |
| `assets/sprites/game_icons/delapouite_hills.svg` | 2D Game Scene |
| `assets/sprites/game_icons/delapouite_home-garage.svg` | Custom Dev Environment |
| `assets/sprites/game_icons/delapouite_joystick.svg` | Indie Game Release |
| `assets/sprites/game_icons/delapouite_keyboard.svg` | Neovim Config |
| `assets/sprites/game_icons/delapouite_laptop.svg` | VS Code Workspace, Pro Workstation Build |
| `assets/sprites/game_icons/delapouite_paint-roller.svg` | Styled Web Page |
| `assets/sprites/game_icons/delapouite_present.svg` | ui_gift |
| `assets/sprites/game_icons/delapouite_puzzle.svg` | Dependency |
| `assets/sprites/game_icons/delapouite_server-rack.svg` | Server Rack, Full-Stack Platform |
| `assets/sprites/game_icons/delapouite_shopping-cart.svg` | E-Commerce Platform, ui_shop |
| `assets/sprites/game_icons/delapouite_smartphone.svg` | Mobile App |
| `assets/sprites/game_icons/delapouite_toolbox.svg` | Developer SDK |
| `assets/sprites/game_icons/delapouite_warehouse.svg` | Data Warehouse |
| `assets/sprites/game_icons/lorc_atomic-slashes.svg` | React Component |
| `assets/sprites/game_icons/lorc_battle-gear.svg` | C++ Engine |
| `assets/sprites/game_icons/lorc_book-aura.svg` | JetBrains IDE Suite |
| `assets/sprites/game_icons/lorc_book-cover.svg` | ui_catalog, HTML Page |
| `assets/sprites/game_icons/lorc_cartwheel.svg` | Python Wheel |
| `assets/sprites/game_icons/lorc_castle.svg` | Integrated Dev Studio, Unreal Project |
| `assets/sprites/game_icons/lorc_cat.svg` | Pixel Sprite |
| `assets/sprites/game_icons/lorc_circuitry.svg` | Circuit Trace |
| `assets/sprites/game_icons/lorc_claw-hammer.svg` | ui_craft |
| `assets/sprites/game_icons/lorc_cloud-ring.svg` | Cloud API |
| `assets/sprites/game_icons/lorc_cloudy-fork.svg` | Git Repository |
| `assets/sprites/game_icons/lorc_coffee-mug.svg` | Java Application |
| `assets/sprites/game_icons/lorc_crab.svg` | Rust Crate |
| `assets/sprites/game_icons/lorc_cross-mark.svg` | ui_close |
| `assets/sprites/game_icons/lorc_crown-coin.svg` | ui_coin |
| `assets/sprites/game_icons/lorc_crown.svg` | Universal Registry |
| `assets/sprites/game_icons/lorc_crystal-ball.svg` | Virtual Universe |
| `assets/sprites/game_icons/lorc_cubeforce.svg` | Laravel Site |
| `assets/sprites/game_icons/lorc_dragon-head.svg` | AAA Game World |
| `assets/sprites/game_icons/lorc_fire-dash.svg` | Svelte App |
| `assets/sprites/game_icons/lorc_flat-star.svg` | ui_star |
| `assets/sprites/game_icons/lorc_fluffy-cloud.svg` | Distributed Data Cloud |
| `assets/sprites/game_icons/lorc_focused-lightning.svg` | Zed Project, ui_energy |
| `assets/sprites/game_icons/lorc_gear-hammer.svg` | CMake Build |
| `assets/sprites/game_icons/lorc_gears.svg` | DevOps Suite |
| `assets/sprites/game_icons/lorc_globe.svg` | Polyglot Runtime |
| `assets/sprites/game_icons/lorc_magnifying-glass.svg` | Search Index |
| `assets/sprites/game_icons/lorc_microchip.svg` | Dev Board |
| `assets/sprites/game_icons/lorc_ouroboros.svg` | DevOps Platform |
| `assets/sprites/game_icons/lorc_padlock.svg` | ui_lock |
| `assets/sprites/game_icons/lorc_peaks.svg` | Vue Application |
| `assets/sprites/game_icons/lorc_processor.svg` | Single-Board PC, Supercomputer |
| `assets/sprites/game_icons/lorc_quill-ink.svg` | Hello Script |
| `assets/sprites/game_icons/lorc_radar-sweep.svg` | Sensor Kit |
| `assets/sprites/game_icons/lorc_robot-golem.svg` | Godot Project |
| `assets/sprites/game_icons/lorc_rocket-flight.svg` | Release Pipeline |
| `assets/sprites/game_icons/lorc_rocket.svg` | Go Program |

## Original artwork — Merge Code project (CC0 / public domain)

Created for this project with `tools/generate_artwork.py` (run it to regenerate). No third-party material.

| File pattern | Used as |
|---|---|
| `assets/sprites/customers/*.svg` | 8 customer portraits (one per customer in `data/customers.json`) |
| `assets/sprites/generators/*.svg` | 8 generator machines (one per generator in `data/generators.json`) |
| `assets/backgrounds/workshop.svg` | Main menu + game screen environment |
| `assets/backgrounds/board_surface.svg` | Merge board workbench surface |
| `assets/sprites/effects/starburst.svg` | Merge reward burst effect |
| `icon.svg` | Project icon (pre-existing) |

## Not used

- No Merge Shop / Roblox artwork, no third-party software logos. Real product names in item data are text references only, with source URLs and software licences kept in `data/items.json` (`source_url`, `software_license`) separate from artwork licensing.

# Merge Code

A 2D merge-management game built with **Godot 4.7 / GDScript** (Compatibility renderer). Start with a small dev workshop, generate technology items, merge them into higher tiers, craft software products, fulfil customer orders, and grow into a complete software ecosystem.

Single-player, fully offline, saves locally. One shared project targets Web, Linux, Windows, macOS, Android and iOS.

## How to run (for testers)

1. Open the project in Godot 4.7.2 (Project Manager → Import → select `project.godot`).
2. Press **Play** (F5). The main scene is `scenes/main_menu.tscn`.
3. **New Game** → tap a generator on the left → drag two identical items together to merge.
4. Deliver customer orders on the right for coins/XP; spend coins on upgrades, generators, board expansion, crafting and the shop.
5. Progress autosaves to a local file; **Continue** resumes it.

## Presentation

Image-driven, board-first casual layout (not a dashboard): the merge board sits centre-screen on a workbench surface, customers wait in a top strip with original character portraits and wanted-item icons, generators are illustrated machines in an adaptive dock (vertical on wide screens, horizontal on narrow/portrait), and Crafting/Shop/Collection/Missions live in a bottom nav with viewport-sized overlays. Interface artwork: Kenney UI Pack (CC0) nine-sliced buttons, panels, board slots, and progress bars. Item artwork: white-silhouette illustrations from Game-Icons (CC BY 3.0) tinted over chain-coloured tiles with rarity frames and tier pips; customers/generators/backgrounds are original SVG artwork. Full attribution in `assets/ASSET_CREDITS.md`; regenerate originals with `python3 tools/generate_artwork.py`. The gameplay screen is a board-first composition, not a stack of dashboard panels: a compact top HUD (coins/level), a slim customer carousel, the merge board in the largest central area, a compact generator dock (beside the board on wide screens, a short carousel beneath it in portrait, and as a side dock with customers as a left rail on short landscape phones), icon-first bottom navigation, and a selected-item panel that only appears as a floating overlay while an item is selected. The board is its own clipped scrolling viewport: cell size is derived from its measured width (7/6/5/4 columns by available width), it prefers shrinking cells to show every visible row while they stay usable, and only scrolls vertically when the grid genuinely cannot fit - cells can never overflow outside the board area. Changing columns only repositions the same cell indices, so saved item positions, capacity and expansion are identical on every device.

## What's implemented

- Main menu (Continue / New Game with overwrite confirm / How to Play / sound / Quit)
- 7×7 merge board (starts 7×4, expandable), drag-and-drop move / swap / merge, drop highlighting, merge animation, invalid-merge feedback
- 74 data-driven items: 8 merge chains × 8 tiers (languages, editors/IDEs, web frameworks, dev tools, databases, packages, game engines, hardware) + 10 crafted products
- 8 generators with energy, regeneration, levels, unlock costs and tier-2 bonus chance
- Customer orders (8 customer profiles, difficulty scaling, deliver/dismiss)
- Crafting with recipe discovery, collection catalog, missions/achievements, item shop
- Coins, XP, player levels with level-up bonuses, item selling, board expansion
- Local JSON save/load preserving board positions, currencies, generators, orders, discovery and stats, with graceful handling of missing fields
- Procedural sound effects (no audio assets), mute toggle
- Source URL / software-license metadata kept separate from original placeholder artwork licensing

## Project layout

- `scenes/` — `main_menu.tscn`, `game.tscn` (thin scene shells; UI is built in code)
- `scripts/` — gameplay + UI scripts; `scripts/autoload/` — `ItemDB`, `GameState`, `SaveManager`, `SoundManager`
- `data/` — `items.json`, `recipes.json`, `generators.json`, `customers.json`, `missions.json`
- `docs/` — GDD, architecture, content guide, building notes

See `docs/CONTENT_GUIDE.md` to add items without touching gameplay code.

# Architecture

Modular but deliberately small. Scenes are thin shells (`scenes/main_menu.tscn`, `scenes/game.tscn`); UI is constructed in code so layout logic stays testable and data-driven.

## Autoloads (in dependency order)
| Autoload | Responsibility |
|---|---|
| `ItemDB` autoload (`scripts/autoload/item_database.gd`, class `ItemDatabase`) | Loads/indexes all `data/*.json`; item/chain/recipe/generator/customer/mission lookups. |
| `GameState` autoload (`scripts/autoload/game_state.gd`, class `GameStateStore`) | Coins, XP/levels, discovery, generator states, orders, stats, missions. Emits signals (`coins_changed`, `xp_changed`, `leveled_up`, `orders_changed`, …); serialises via `to_dict`/`from_dict` with defaults for missing fields. |
| `SaveManager` autoload (`scripts/autoload/save_manager.gd`, class `SaveGame`) | Reads/writes `user://mergecode_save.json` (works on web/mobile/desktop); `load_existing` is set by the main menu. |
| `SoundManager` autoload (`scripts/autoload/sound_manager.gd`, class `SoundFx`) | Procedural WAV tone effects; no audio assets; honours `GameState.sound_enabled`. |

## Gameplay/UI scripts
- `scripts/board.gd` + `board_cell.gd` + `item_tile.gd` — grid, placement state (`cell -> item_id`), move/swap/merge rules, drop preview highlighting, merge pop/float feedback, board (de)serialisation. Uses Godot's native `_get_drag_data`/`_can_drop_data`/`_drop_data` (mouse + touch).
- `scripts/generator_card.gd` — produce (energy), unlock, upgrade UI; energy regen is ticked from `main.gd._process`.
- `scripts/order_card.gd` — requirement checklist vs live board counts, deliver/dismiss.
- `scripts/popup_panel.gd` — Crafting, Catalog, Missions, Shop, Help modals; every button acts on `Board`/`GameState` directly.
- `scripts/main.gd` — board-first adaptive layout (HUD, customer strip, generator dock that re-parents between side/bottom on resize, bottom nav), selection/sell bar, toasts, autosave (10 s, dirty-flagged), level-up handling.
- Artwork: `assets/ui/Kenney/` (Kenney UI Pack CC0 buttons/panels/progress/slots, selected PNG subset with Kenney's original `license.txt`), `assets/sprites/game_icons/` (Game-Icons CC BY 3.0 silhouettes, background square stripped, referenced per-item via the `icon` field in `data/items.json`), original SVG customers/generators/backgrounds from `tools/generate_artwork.py`; see `assets/ASSET_CREDITS.md`.
- Responsive UI follows the official Godot UI Containers guidance (https://docs.godotengine.org/en/stable/tutorials/ui/gui_containers.html): Margin/VBox/HBox/Grid/Scroll/Center/Panel containers, expand/shrink size flags, adaptive GridContainer columns, and viewport breakpoint re-parenting for the generator dock.
- `scripts/ui_style.gd` — shared rounded styles/colours (no neon/cyberpunk palette).

Gameplay code accesses the autoloads through their class-name static instances (`ItemDatabase.instance`, `GameStateStore.instance`, `SaveGame.instance`, `SoundFx.instance`, assigned in `_enter_tree`) rather than the autoload singleton names. This keeps script parsing independent of the editor's autoload-registration timing (e.g. after pulling new files into an already-open editor). Note the game popup class is `MergePopupPanel` because `PopupPanel` is a native Godot class.

## Data flow
`ItemDB` (static content) → `GameState` (mutable run state) → UI (signal-driven refresh) → `SaveManager` (board serialised by `Board.serialize()`, everything else by `GameState.to_dict()`).

## Future multiplayer readiness
All mutable state is centralised in `GameState` with a dictionary serialisation boundary, so a server-authoritative adapter could slot behind `GameState`/`SaveManager` later. No networking is implemented now.

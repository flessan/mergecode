# Architecture

Modular but deliberately small. Scenes are thin shells (`scenes/main_menu.tscn`, `scenes/game.tscn`); UI is constructed in code so layout logic stays testable and data-driven.

## Autoloads (in dependency order)
| Autoload | Responsibility |
|---|---|
| `ItemDB` (`scripts/autoload/item_database.gd`) | Loads/indexes all `data/*.json`; item/chain/recipe/generator/customer/mission lookups. |
| `GameState` (`scripts/autoload/game_state.gd`) | Coins, XP/levels, discovery, generator states, orders, stats, missions. Emits signals (`coins_changed`, `xp_changed`, `leveled_up`, `orders_changed`, …); serialises via `to_dict`/`from_dict` with defaults for missing fields. |
| `SaveManager` (`scripts/autoload/save_manager.gd`) | Reads/writes `user://mergecode_save.json` (works on web/mobile/desktop); `load_existing` is set by the main menu. |
| `SoundManager` (`scripts/autoload/sound_manager.gd`) | Procedural WAV tone effects; no audio assets; honours `GameState.sound_enabled`. |

## Gameplay/UI scripts
- `scripts/board.gd` + `board_cell.gd` + `item_tile.gd` — grid, placement state (`cell -> item_id`), move/swap/merge rules, drop preview highlighting, merge pop/float feedback, board (de)serialisation. Uses Godot's native `_get_drag_data`/`_can_drop_data`/`_drop_data` (mouse + touch).
- `scripts/generator_card.gd` — produce (energy), unlock, upgrade UI; energy regen is ticked from `main.gd._process`.
- `scripts/order_card.gd` — requirement checklist vs live board counts, deliver/dismiss.
- `scripts/popup_panel.gd` — Crafting, Catalog, Missions, Shop, Help modals; every button acts on `Board`/`GameState` directly.
- `scripts/main.gd` — HUD, layout, selection/sell panel, toasts, autosave (10 s, dirty-flagged), level-up handling.
- `scripts/ui_style.gd` — shared rounded styles/colours (no neon/cyberpunk palette).

## Data flow
`ItemDB` (static content) → `GameState` (mutable run state) → UI (signal-driven refresh) → `SaveManager` (board serialised by `Board.serialize()`, everything else by `GameState.to_dict()`).

## Future multiplayer readiness
All mutable state is centralised in `GameState` with a dictionary serialisation boundary, so a server-authoritative adapter could slot behind `GameState`/`SaveManager` later. No networking is implemented now.

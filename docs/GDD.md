# Merge Code — Game Design Document (short form)

**Genre:** 2D merge-management, single-player, offline. **Engine:** Godot 4.7, GDScript, Compatibility renderer.

## Core loop
Generate items → place on board → merge two identical items into the next tier → discover chains → craft combined products → fulfil customer orders → earn coins/XP → upgrade generators, unlock new categories, expand the board → repeat at higher tiers.

## Systems
- **Board:** 7 columns, starts at 4 rows (28 cells), expandable to 7 rows for scaling coin cost. Drag to move/swap/merge; identical max-tier drops are rejected with feedback; target highlighting (green = valid, red = invalid).
- **Items:** definition (JSON) vs instance (board cell). 8 chains × 8 tiers + crafted products. Rarity rises with tier; sell value grows exponentially.
- **Generators:** one per chain; energy pool regenerates over time; upgrades add energy, speed regen and (Lv3+) grant a chance to produce tier-2 items. Later generators unlock by player level + coin cost.
- **Orders:** 3 active customers; requirements drawn from discovered items so they stay achievable; difficulty (1–3 items) scales with player level; rewards = item value based coins + XP.
- **Crafting:** two-ingredient recipes producing software products; recipes reveal once an ingredient/result is discovered.
- **Progression:** XP levels (threshold 80 + 40/level), level-up coin bonus, missions/achievements, collection catalog, item shop (convenience pricing, tiers gated by generator level).
- **Economy sinks:** generator unlocks/upgrades, board expansion, shop purchases. **Sources:** orders, selling, missions, level-ups.

## Visual direction
Warm paper-like background, white rounded cards, one accent colour per item category, abbreviation tiles as original placeholder artwork (no third-party logos, no emoji icons). Desktop + touch friendly via native Control drag-and-drop.

## Scope notes
First release is single-player only; state lives in autoloads behind signals so a future backend could replace `SaveManager` without touching gameplay. No external APIs are used at runtime.

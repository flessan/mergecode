# Content Guide — adding content without code changes

All content lives in `data/*.json`. Gameplay code reads it through `ItemDB`.

## Add an item (`data/items.json`)
```json
{
  "id": "language_9", "name": "Quantum Runtime", "short": "QR",
  "category": "Languages", "chain_id": "language", "tier": 9,
  "rarity": "Legendary", "rarity_color": "E8A33D", "color": "4A90D9",
  "description": "…", "sell_value": 3000,
  "merge_to": "", "generator_id": "code_notebook",
  "source_url": "https://…", "software_license": "…",
  "artwork_license": "Original placeholder artwork (coloured tile + abbreviation); no third-party logo used."
}
```
Rules:
- `id` is unique and stable (saves reference it). Chain tiers use `<chain>_<tier>`; set the previous tier's `merge_to` to the new id.
- `short` is the 1–4 character tile abbreviation — artwork is an original coloured tile + abbreviation. **Do not** add third-party logos unless their artwork licence clearly allows reuse.
- Keep `software_license` (the software's licence) separate from `artwork_license` (the tile art). Preserve `source_url` for real products/projects, open-source or proprietary alike.

## Add a chain + generator
Add the chain's items, then a generator entry in `data/generators.json` (`chain_id`, `unlock_level`, `unlock_cost`, `max_energy`, `regen_seconds`, `base_upgrade_cost`). It appears automatically in the generator list, shop and order pools.

## Add a crafting recipe (`data/recipes.json`)
`{"id": "recipe_x", "result_id": "<item id>", "ingredient_ids": ["<id>", "<id>"], "name": "…"}` — result items should use `"chain_id": "crafted"`, `"tier": 0`.

## Add customers / missions
Append to `data/customers.json` (name, role, colour, initials, bio) or `data/missions.json` (`stat` must be one of `merges`, `orders_delivered`, `crafts`, `coins_earned`, `generated`, `items_sold`, `discovered_count`).

extends Node
class_name GameStateStore
## NOTE: this script is also registered as an autoload in project.godot, which
## instantiates it. Gameplay code accesses it via GameStateStore.instance (set in
## _enter_tree) instead of the autoload singleton name, so identifier
## resolution never depends on editor autoload-registration timing.

static var instance: GameStateStore

func _enter_tree() -> void:
	instance = self
## Central single-player state: economy, progression, discovery, statistics,
## generator states and customer orders. Emits signals; UI listens, never polls
## for currency changes. Serialised by SaveManager through to_dict/from_dict.

signal coins_changed(amount: int)
signal xp_changed(xp: int, xp_needed: int, level: int)
signal leveled_up(new_level: int)
signal item_discovered(item_id: String)
signal orders_changed
signal stats_changed

const STARTING_COINS := 60
const MAX_ORDERS := 3
const BOARD_START_CELLS := 28   # 7 x 4
const BOARD_MAX_CELLS := 49     # 7 x 7

var coins: int = STARTING_COINS
var total_xp: int = 0
var level: int = 1
var xp_into_level: int = 0

var discovered: Dictionary = {}          # item_id -> true
var crafted_recipes: Dictionary = {}     # recipe_id -> true
var claimed_missions: Dictionary = {}    # mission_id -> true
var board_cells_unlocked: int = BOARD_START_CELLS

# generator_id -> {unlocked:bool, level:int, energy:float}
var generator_states: Dictionary = {}
# Array of order Dictionaries: {customer_id, requirements:{item_id:count}, reward_coins, reward_xp, difficulty}
var orders: Array = []

var stats: Dictionary = {
	"merges": 0, "orders_delivered": 0, "crafts": 0,
	"coins_earned": 0, "generated": 0, "items_sold": 0,
}

var sound_enabled: bool = true
var has_save: bool = false   # set by SaveManager at boot

func _ready() -> void:
	reset_new_game(false)

func xp_needed_for(level_value: int) -> int:
	return 80 + (level_value - 1) * 40

func reset_new_game(emit_signals_now: bool = true) -> void:
	coins = STARTING_COINS
	total_xp = 0
	level = 1
	xp_into_level = 0
	discovered.clear()
	crafted_recipes.clear()
	claimed_missions.clear()
	board_cells_unlocked = BOARD_START_CELLS
	generator_states.clear()
	for gen_id in ItemDatabase.instance.generator_order:
		var def: Dictionary = ItemDatabase.instance.generators[gen_id]
		var starts_open := int(def.get("unlock_level", 1)) <= 1 and int(def.get("unlock_cost", 0)) <= 0
		generator_states[gen_id] = {
			"unlocked": starts_open, "level": 1,
			"energy": float(def.get("max_energy", 6)),
		}
	orders.clear()
	stats = {"merges": 0, "orders_delivered": 0, "crafts": 0, "coins_earned": 0, "generated": 0, "items_sold": 0}
	while orders.size() < MAX_ORDERS:
		orders.append(make_order())
	if emit_signals_now:
		_emit_all()

func _emit_all() -> void:
	coins_changed.emit(coins)
	xp_changed.emit(xp_into_level, xp_needed_for(level), level)
	orders_changed.emit()
	stats_changed.emit()

# --- Economy ---------------------------------------------------------------

func add_coins(amount: int) -> void:
	coins += amount
	if amount > 0:
		stats["coins_earned"] = int(stats.get("coins_earned", 0)) + amount
		stats_changed.emit()
	coins_changed.emit(coins)

func spend_coins(amount: int) -> bool:
	if coins < amount:
		return false
	coins -= amount
	coins_changed.emit(coins)
	return true

func add_xp(amount: int) -> void:
	total_xp += amount
	xp_into_level += amount
	while xp_into_level >= xp_needed_for(level):
		xp_into_level -= xp_needed_for(level)
		level += 1
		add_coins(50 + level * 10)  # level-up coin bonus
		leveled_up.emit(level)
	xp_changed.emit(xp_into_level, xp_needed_for(level), level)

func bump_stat(key: String, by: int = 1) -> void:
	stats[key] = int(stats.get(key, 0)) + by
	stats_changed.emit()

func stat_value(key: String) -> int:
	if key == "discovered_count":
		return discovered.size()
	return int(stats.get(key, 0))

# --- Discovery -------------------------------------------------------------

func discover(item_id: String) -> bool:
	if item_id == "" or discovered.has(item_id):
		return false
	discovered[item_id] = true
	item_discovered.emit(item_id)
	stats_changed.emit()
	return true

func is_discovered(item_id: String) -> bool:
	return discovered.has(item_id)

# --- Generators ------------------------------------------------------------

func generator_state(gen_id: String) -> Dictionary:
	return generator_states.get(gen_id, {"unlocked": false, "level": 1, "energy": 0.0})

func generator_max_energy(gen_id: String) -> int:
	var def: Dictionary = ItemDatabase.instance.generators.get(gen_id, {})
	var lvl := int(generator_state(gen_id).get("level", 1))
	return int(def.get("max_energy", 6)) + (lvl - 1)

func generator_regen_seconds(gen_id: String) -> float:
	var def: Dictionary = ItemDatabase.instance.generators.get(gen_id, {})
	var lvl := int(generator_state(gen_id).get("level", 1))
	return maxf(1.5, float(def.get("regen_seconds", 4.0)) - float(lvl - 1) * 0.25)

func generator_upgrade_cost(gen_id: String) -> int:
	var def: Dictionary = ItemDatabase.instance.generators.get(gen_id, {})
	var lvl := int(generator_state(gen_id).get("level", 1))
	return int(def.get("base_upgrade_cost", 100)) * lvl

## Chance (0..1) that a generator produces its chain's tier-2 item instead of tier-1.
func generator_bonus_chance(gen_id: String) -> float:
	var lvl := int(generator_state(gen_id).get("level", 1))
	return clampf(float(lvl - 2) * 0.08, 0.0, 0.4) if lvl >= 3 else 0.0

# --- Board expansion ---------------------------------------------------------

func board_expansion_cost() -> int:
	var expansions := int(float(board_cells_unlocked - BOARD_START_CELLS) / 7.0)
	return 250 * (expansions + 1) * (expansions + 1)

# --- Orders ------------------------------------------------------------------

func make_order() -> Dictionary:
	var customer := ItemDatabase.instance.random_customer()
	# Candidate items: discovered chain items of tier 1..(2+level), so orders
	# stay achievable; fall back to starter items on a fresh game.
	var candidates: Array = []
	for item_id in discovered.keys():
		var def := ItemDatabase.instance.get_item(str(item_id))
		if str(def.get("chain_id", "")) != "crafted" and int(def.get("tier", 0)) >= 1:
			candidates.append(str(item_id))
	if candidates.is_empty():
		candidates = ["language_1", "editor_1"]
	var req_count := 1
	var roll := randf()
	if level >= 3 and roll > 0.55:
		req_count = 2
	if level >= 6 and roll > 0.85:
		req_count = 3
	var requirements: Dictionary = {}
	var reward_coins := 0
	var reward_xp := 0
	for i in req_count:
		var pick := str(candidates[randi() % candidates.size()])
		requirements[pick] = int(requirements.get(pick, 0)) + 1
		var def := ItemDatabase.instance.get_item(pick)
		reward_coins += int(def.get("sell_value", 5)) * 3 + 8
		reward_xp += 6 + int(def.get("tier", 1)) * 4
	return {
		"customer_id": str(customer.get("id", "")), "customer_name": str(customer.get("name", "Customer")),
		"customer_role": str(customer.get("role", "Client")), "customer_color": str(customer.get("color", "4A90D9")),
		"customer_initials": str(customer.get("initials", "?")),
		"requirements": requirements, "reward_coins": reward_coins, "reward_xp": reward_xp,
		"difficulty": req_count,
	}

func replace_order(index: int) -> void:
	if index >= 0 and index < orders.size():
		orders[index] = make_order()
		orders_changed.emit()

func complete_order(index: int) -> void:
	if index < 0 or index >= orders.size():
		return
	var order: Dictionary = orders[index]
	add_coins(int(order.get("reward_coins", 0)))
	add_xp(int(order.get("reward_xp", 0)))
	bump_stat("orders_delivered")
	orders[index] = make_order()
	orders_changed.emit()

# --- Serialisation -----------------------------------------------------------

func to_dict(board_items: Array) -> Dictionary:
	return {
		"version": 1, "coins": coins, "total_xp": total_xp, "level": level,
		"xp_into_level": xp_into_level, "discovered": discovered.keys(),
		"crafted_recipes": crafted_recipes.keys(), "claimed_missions": claimed_missions.keys(),
		"board_cells_unlocked": board_cells_unlocked,
		"generator_states": generator_states, "orders": orders, "stats": stats,
		"board_items": board_items, "sound_enabled": sound_enabled,
	}

func from_dict(data: Dictionary) -> void:
	coins = int(data.get("coins", STARTING_COINS))
	total_xp = int(data.get("total_xp", 0))
	level = maxi(1, int(data.get("level", 1)))
	xp_into_level = int(data.get("xp_into_level", 0))
	discovered.clear()
	for item_id in data.get("discovered", []):
		discovered[str(item_id)] = true
	crafted_recipes.clear()
	for rid in data.get("crafted_recipes", []):
		crafted_recipes[str(rid)] = true
	claimed_missions.clear()
	for mid in data.get("claimed_missions", []):
		claimed_missions[str(mid)] = true
	board_cells_unlocked = clampi(int(data.get("board_cells_unlocked", BOARD_START_CELLS)), BOARD_START_CELLS, BOARD_MAX_CELLS)
	generator_states.clear()
	var saved_gens: Dictionary = data.get("generator_states", {})
	for gen_id in ItemDatabase.instance.generator_order:
		if saved_gens.has(gen_id) and typeof(saved_gens[gen_id]) == TYPE_DICTIONARY:
			var s: Dictionary = saved_gens[gen_id]
			generator_states[gen_id] = {"unlocked": bool(s.get("unlocked", false)), "level": maxi(1, int(s.get("level", 1))), "energy": float(s.get("energy", 0.0))}
		else:  # graceful fallback for saves missing newer generators
			var def: Dictionary = ItemDatabase.instance.generators[gen_id]
			generator_states[gen_id] = {"unlocked": int(def.get("unlock_level", 1)) <= 1 and int(def.get("unlock_cost", 0)) <= 0, "level": 1, "energy": float(def.get("max_energy", 6))}
	orders.clear()
	for entry in data.get("saved_orders", data.get("orders", [])):
		if typeof(entry) == TYPE_DICTIONARY and entry.has("requirements"):
			orders.append(entry)
	while orders.size() < MAX_ORDERS:
		orders.append(make_order())
	var saved_stats: Dictionary = data.get("stats", {})
	stats = {"merges": 0, "orders_delivered": 0, "crafts": 0, "coins_earned": 0, "generated": 0, "items_sold": 0}
	for key in stats.keys():
		stats[key] = int(saved_stats.get(key, 0))
	sound_enabled = bool(data.get("sound_enabled", true))
	_emit_all()

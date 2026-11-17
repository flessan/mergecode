extends Node
class_name ItemDatabase
## NOTE: this script is also registered as an autoload in project.godot, which
## instantiates it. Gameplay code accesses it via ItemDatabase.instance (set in
## _enter_tree) instead of the autoload singleton name, so identifier
## resolution never depends on editor autoload-registration timing.

static var instance: ItemDatabase

func _enter_tree() -> void:
	instance = self
## Loads and indexes all data-driven content from res://data/*.json.
## Adding content = editing JSON, no gameplay code changes needed.

var items: Dictionary = {}        # id -> definition Dictionary
var item_order: Array = []         # ids in file order
var chains: Dictionary = {}        # chain_id -> Array of ids sorted by tier
var recipes: Array = []
var generators: Dictionary = {}
var generator_order: Array = []
var customers: Array = []
var missions: Array = []

func _ready() -> void:
	_load_items()
	_load_list("res://data/recipes.json", "recipes", recipes)
	_load_generators()
	_load_list("res://data/customers.json", "customers", customers)
	_load_list("res://data/missions.json", "missions", missions)

func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_warning("Missing data file: " + path)
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Invalid JSON in " + path)
		return {}
	return parsed

func _load_items() -> void:
	var data := _read_json("res://data/items.json")
	for entry in data.get("items", []):
		if typeof(entry) != TYPE_DICTIONARY or not entry.has("id"):
			continue
		items[entry["id"]] = entry
		item_order.append(entry["id"])
		var chain_id := str(entry.get("chain_id", ""))
		if not chains.has(chain_id):
			chains[chain_id] = []
		chains[chain_id].append(entry["id"])
	for chain_id in chains:
		var ids: Array = chains[chain_id]
		ids.sort_custom(func(a: String, b: String) -> bool: return int(items[a].get("tier", 0)) < int(items[b].get("tier", 0)))

func _load_generators() -> void:
	var data := _read_json("res://data/generators.json")
	for entry in data.get("generators", []):
		if typeof(entry) == TYPE_DICTIONARY and entry.has("id"):
			generators[entry["id"]] = entry
			generator_order.append(entry["id"])

func _load_list(path: String, key: String, target: Array) -> void:
	var data := _read_json(path)
	for entry in data.get(key, []):
		if typeof(entry) == TYPE_DICTIONARY:
			target.append(entry)

func get_item(item_id: String) -> Dictionary:
	return items.get(item_id, {})

func item_name(item_id: String) -> String:
	return str(get_item(item_id).get("name", item_id))

func chain_start_item(chain_id: String) -> String:
	var ids: Array = chains.get(chain_id, [])
	return str(ids[0]) if ids.size() > 0 else ""

func customer_by_id(customer_id: String) -> Dictionary:
	for c in customers:
		if str(c.get("id", "")) == customer_id:
			return c
	return {}

func random_customer() -> Dictionary:
	if customers.is_empty():
		return {"name": "Customer", "role": "Client", "color": "4A90D9", "initials": "?"}
	return customers[randi() % customers.size()]

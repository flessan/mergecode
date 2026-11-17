extends Node
## Local JSON save file in user:// (works on desktop, mobile and web exports).

const SAVE_PATH := "user://mergecode_save.json"

## Set by the main menu: true = Continue (load), false = New Game (fresh state).
var load_existing: bool = true

func _ready() -> void:
	GameState.has_save = FileAccess.file_exists(SAVE_PATH)

func save_game(board_items: Array) -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_warning("Could not open save file for writing")
		return
	f.store_string(JSON.stringify(GameState.to_dict(board_items)))
	GameState.has_save = true

func load_game() -> Array:
	## Returns saved board items ([{cell:int, item_id:String}]), [] if none/invalid.
	if not FileAccess.file_exists(SAVE_PATH):
		return []
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return []
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Save file corrupted; starting fresh state")
		return []
	GameState.from_dict(parsed)
	var board_items: Array = []
	for entry in parsed.get("board_items", []):
		if typeof(entry) == TYPE_DICTIONARY and entry.has("cell") and entry.has("item_id"):
			board_items.append({"cell": int(entry["cell"]), "item_id": str(entry["item_id"])})
	return board_items

func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	GameState.has_save = false

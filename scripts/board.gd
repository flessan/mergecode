class_name Board
extends GridContainer
## 7-column merge board. Owns item placement state (cell_index -> item_id),
## move / swap / merge rules, drop highlighting and merge feedback.

signal board_changed
signal item_selected(tile: ItemTile)
signal merge_performed(cell: int, new_item_id: String)
signal invalid_action(message: String)

const COLUMNS := 7
const TILE_SCENE_HINT := "item_tile"

var cells_items: Dictionary = {}   # int cell -> String item_id
var _cells: Array = []              # BoardCell nodes by index
var _tiles: Dictionary = {}         # int cell -> ItemTile
var _highlighted_cell: int = -1
var _selected_cell: int = -1
var _cell_px: int = 92

func _ready() -> void:
	columns = COLUMNS
	add_theme_constant_override("h_separation", 8)
	add_theme_constant_override("v_separation", 8)
	_build_cells()

func _build_cells() -> void:
	for i in GameStateStore.instance.BOARD_MAX_CELLS:
		var cell := BoardCell.new()
		cell.setup(i, self, i >= GameStateStore.instance.board_cells_unlocked)
		add_child(cell)
		_cells.append(cell)

func visible_rows() -> int:
	return int(ceil(float(GameStateStore.instance.board_cells_unlocked) / float(COLUMNS)))

func refresh_locks() -> void:
	var shown := visible_rows() * COLUMNS
	for i in _cells.size():
		_cells[i].set_locked(i >= GameStateStore.instance.board_cells_unlocked)
		# Fully locked rows stay hidden until expansion reveals them, so the
		# board always fits its surface without shrinking cells to nothing.
		_cells[i].visible = i < shown

func set_cell_size(px: int) -> void:
	_cell_px = px
	for cell in _cells:
		cell.set_cell_size(px)
	for c in _tiles:
		_tiles[c].set_compact(px < 64)

# --- Selection (Board owns it: Board owns the tile instances) ----------------

func selected_cell() -> int:
	return _selected_cell

func set_selected_cell(cell: int) -> void:
	_selected_cell = cell
	for c in _tiles:
		_tiles[c].set_selected(int(c) == cell)

func spawn_burst(cell: int) -> void:
	if cell < 0 or cell >= _cells.size():
		return
	var burst := UiStyle.icon_rect("res://assets/sprites/effects/starburst.svg", Vector2(30, 30), Color.WHITE)
	burst.set_anchors_preset(Control.PRESET_CENTER)
	_cells[cell].add_child(burst)
	burst.scale = Vector2(0.3, 0.3)
	burst.pivot_offset = Vector2(15, 15)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(burst, "scale", Vector2(2.6, 2.6), 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(burst, "modulate:a", 0.0, 0.5)
	tween.chain().tween_callback(burst.queue_free)

# --- Queries ---------------------------------------------------------------

func is_unlocked(cell: int) -> bool:
	return cell >= 0 and cell < GameStateStore.instance.board_cells_unlocked

func find_empty_cell() -> int:
	for i in GameStateStore.instance.board_cells_unlocked:
		if not cells_items.has(i):
			return i
	return -1

func item_count(item_id: String) -> int:
	var n := 0
	for value in cells_items.values():
		if str(value) == item_id:
			n += 1
	return n

func has_requirements(requirements: Dictionary) -> bool:
	for item_id in requirements:
		if item_count(str(item_id)) < int(requirements[item_id]):
			return false
	return true

# --- Mutation ----------------------------------------------------------------

func place_item(item_id: String, cell: int = -1, animate: bool = true) -> bool:
	var target := cell
	if target < 0 or cells_items.has(target) or not is_unlocked(target):
		target = find_empty_cell()
	if target < 0:
		return false
	cells_items[target] = item_id
	GameStateStore.instance.discover(item_id)
	_spawn_tile(target, animate)
	board_changed.emit()
	return true

func remove_at(cell: int) -> void:
	if not cells_items.has(cell):
		return
	if cell == _selected_cell:
		_selected_cell = -1
	cells_items.erase(cell)
	if _tiles.has(cell):
		_tiles[cell].queue_free()
		_tiles.erase(cell)
	board_changed.emit()

func consume_item(item_id: String) -> bool:
	for cell in cells_items:
		if str(cells_items[cell]) == item_id:
			remove_at(int(cell))
			return true
	return false

func consume_requirements(requirements: Dictionary) -> bool:
	if not has_requirements(requirements):
		return false
	for item_id in requirements:
		for i in int(requirements[item_id]):
			consume_item(str(item_id))
	return true

func _spawn_tile(cell: int, animate: bool) -> void:
	var tile := ItemTile.new()
	tile.setup(str(cells_items[cell]), cell)
	tile.set_anchors_preset(Control.PRESET_FULL_RECT)
	_cells[cell].add_child(tile)
	_tiles[cell] = tile
	tile.set_compact(_cell_px < 64)
	tile.tile_clicked.connect(_on_tile_clicked)
	if animate:
		tile.pop_animation()

func _on_tile_clicked(tile: ItemTile) -> void:
	set_selected_cell(tile.cell_index)
	item_selected.emit(tile)

func clear_highlights() -> void:
	if _highlighted_cell >= 0 and _tiles.has(_highlighted_cell):
		_tiles[_highlighted_cell].set_highlight(false, false)
	_highlighted_cell = -1

func preview_drop(from_cell: int, to_cell: int) -> void:
	clear_highlights()
	if from_cell < 0 or from_cell == to_cell or not _tiles.has(to_cell):
		return
	_highlighted_cell = to_cell
	var from_id := str(cells_items.get(from_cell, ""))
	var to_id := str(cells_items.get(to_cell, ""))
	var ok := true
	if from_id == to_id and str(ItemDatabase.instance.get_item(from_id).get("merge_to", "")) == "":
		ok = false  # identical but already max tier / crafted
	_tiles[to_cell].set_highlight(true, ok)

func drop_on_cell(from_cell: int, to_cell: int) -> void:
	clear_highlights()
	if from_cell < 0 or to_cell < 0 or from_cell == to_cell:
		return
	if not cells_items.has(from_cell) or not is_unlocked(to_cell):
		return
	var from_id := str(cells_items[from_cell])
	if not cells_items.has(to_cell):
		# Plain move.
		cells_items.erase(from_cell)
		cells_items[to_cell] = from_id
		_rebuild_tile(from_cell)
		_spawn_tile(to_cell, false)
		if _selected_cell == from_cell:
			set_selected_cell(to_cell)
		SoundFx.instance.play("click")
		board_changed.emit()
		return
	var to_id := str(cells_items[to_cell])
	if from_id == to_id:
		var next_id := str(ItemDatabase.instance.get_item(from_id).get("merge_to", ""))
		if next_id == "":
			invalid_action.emit("That item is already at its highest tier.")
			SoundFx.instance.play("error")
			return
		# Merge: consume both, produce next tier at target cell.
		cells_items.erase(from_cell)
		_rebuild_tile(from_cell)
		cells_items[to_cell] = next_id
		_rebuild_tile(to_cell)
		_spawn_tile(to_cell, true)
		GameStateStore.instance.discover(next_id)
		GameStateStore.instance.bump_stat("merges")
		GameStateStore.instance.add_xp(2 + int(ItemDatabase.instance.get_item(next_id).get("tier", 1)))
		SoundFx.instance.play("merge")
		merge_performed.emit(to_cell, next_id)
		spawn_burst(to_cell)
		if _selected_cell == from_cell or _selected_cell == to_cell:
			set_selected_cell(to_cell)
		_float_text(to_cell, "Merged!")
		board_changed.emit()
	else:
		# Swap positions.
		cells_items[from_cell] = to_id
		cells_items[to_cell] = from_id
		_rebuild_tile(from_cell)
		_rebuild_tile(to_cell)
		_spawn_tile(from_cell, false)
		_spawn_tile(to_cell, false)
		if _selected_cell == from_cell:
			set_selected_cell(to_cell)
		elif _selected_cell == to_cell:
			set_selected_cell(from_cell)
		SoundFx.instance.play("click")
		board_changed.emit()

func _rebuild_tile(cell: int) -> void:
	if _tiles.has(cell):
		_tiles[cell].queue_free()
		_tiles.erase(cell)

func _float_text(cell: int, text: String) -> void:
	if cell < 0 or cell >= _cells.size():
		return
	var l := UiStyle.label(text, 14, UiStyle.ACCENT)
	l.position = Vector2(8, 2)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cells[cell].add_child(l)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(l, "position:y", -18.0, 0.7)
	tween.tween_property(l, "modulate:a", 0.0, 0.7)
	tween.chain().tween_callback(l.queue_free)

# --- Serialisation -------------------------------------------------------------

func serialize() -> Array:
	var out: Array = []
	for cell in cells_items:
		out.append({"cell": int(cell), "item_id": str(cells_items[cell])})
	return out

func load_items(saved: Array) -> void:
	cells_items.clear()
	for cell in _tiles:
		_tiles[cell].queue_free()
	_tiles.clear()
	for entry in saved:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var cell := int(entry.get("cell", -1))
		var item_id := str(entry.get("item_id", ""))
		if cell >= 0 and cell < GameStateStore.instance.BOARD_MAX_CELLS and ItemDatabase.instance.items.has(item_id) and not cells_items.has(cell):
			cells_items[cell] = item_id
			GameStateStore.instance.discover(item_id)
	for cell in cells_items:
		_spawn_tile(int(cell), false)
	refresh_locks()
	board_changed.emit()

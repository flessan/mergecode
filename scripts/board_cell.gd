class_name BoardCell
extends PanelContainer
## One board slot: recessed empty slot, lock icon for locked slots.
## Drop target for board item drags; forwards to the Board.

var cell_index: int = -1
var board: Node = null
var locked: bool = false

func setup(p_index: int, p_board: Node, p_locked: bool) -> void:
	cell_index = p_index
	board = p_board
	locked = p_locked
	custom_minimum_size = Vector2(92, 92)
	_refresh()

func set_locked(value: bool) -> void:
	locked = value
	_refresh()

func set_cell_size(px: int) -> void:
	custom_minimum_size = Vector2(px, px)

func _refresh() -> void:
	add_theme_stylebox_override("panel", UiStyle.Kenney_slot_style(locked))
	for child in get_children():
		if child.name == "LockBox":
			child.queue_free()
	if locked:
		var vb := VBoxContainer.new()
		vb.name = "LockBox"
		vb.alignment = BoxContainer.ALIGNMENT_CENTER
		vb.mouse_filter = MOUSE_FILTER_IGNORE
		add_child(vb)
		var lock := UiStyle.icon_rect("res://assets/sprites/game_icons/lorc_padlock.svg", Vector2(26, 26), Color(1, 1, 1, 0.75))
		lock.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		vb.add_child(lock)
		var l := UiStyle.label("Locked", 10, Color(1, 1, 1, 0.75))
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.mouse_filter = MOUSE_FILTER_IGNORE
		vb.add_child(l)

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if locked or typeof(data) != TYPE_DICTIONARY or str(data.get("type", "")) != "board_item":
		return false
	if board and board.has_method("preview_drop"):
		board.preview_drop(int(data.get("from_cell", -1)), cell_index)
	return true

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if board and typeof(data) == TYPE_DICTIONARY:
		board.drop_on_cell(int(data.get("from_cell", -1)), cell_index)

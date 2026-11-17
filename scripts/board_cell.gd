class_name BoardCell
extends PanelContainer
## One board slot. Drop target for BoardItem drags; forwards to the Board.

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

func _refresh() -> void:
	add_theme_stylebox_override("panel", UiStyle.panel_style(UiStyle.CELL_LOCKED if locked else UiStyle.CELL_EMPTY, 12, Color(0, 0, 0, 0.05)))
	for child in get_children():
		if child is Label:
			child.queue_free()
	if locked:
		var l := UiStyle.label("Locked", 11, UiStyle.MUTED)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.mouse_filter = MOUSE_FILTER_IGNORE
		add_child(l)

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if locked or typeof(data) != TYPE_DICTIONARY or str(data.get("type", "")) != "board_item":
		return false
	if board and board.has_method("preview_drop"):
		board.preview_drop(int(data.get("from_cell", -1)), cell_index)
	return true

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if board and typeof(data) == TYPE_DICTIONARY:
		board.drop_on_cell(int(data.get("from_cell", -1)), cell_index)
